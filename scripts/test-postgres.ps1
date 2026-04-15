param(
  [string]$EnvFile = "$PSScriptRoot\..\.env",
  [string]$PsqlExe = ""
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  Write-Error "[FAIL] $Message"
  exit 1
}

$dotenv = Join-Path $PSScriptRoot 'load-dotenv.ps1'
if (!(Test-Path -LiteralPath $dotenv)) {
  Fail "Missing script: $dotenv"
}

& $dotenv -EnvFile $EnvFile

$dbHost = $env:DEV_DROPS_DB_HOST
$dbPort = $env:DEV_DROPS_DB_PORT
$dbName = $env:DEV_DROPS_DB_NAME
$dbUser = $env:DEV_DROPS_DB_USER
$dbPass = $env:DEV_DROPS_DB_PASSWORD

if ([string]::IsNullOrWhiteSpace($dbHost)) { Fail 'DEV_DROPS_DB_HOST missing in .env' }
if ([string]::IsNullOrWhiteSpace($dbPort)) { $dbPort = '5432' }
if ([string]::IsNullOrWhiteSpace($dbName)) { Fail 'DEV_DROPS_DB_NAME missing in .env' }
if ([string]::IsNullOrWhiteSpace($dbUser)) { Fail 'DEV_DROPS_DB_USER missing in .env' }

function Resolve-Psql([string]$Explicit) {
  if ($Explicit -and (Test-Path -LiteralPath $Explicit)) { return $Explicit }

  $cmd = Get-Command psql.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $roots = @('C:\\Program Files\\PostgreSQL', 'C:\\Program Files (x86)\\PostgreSQL')
  $candidates = @()
  foreach ($root in $roots) {
    if (Test-Path $root) {
      foreach ($dir in (Get-ChildItem $root -Directory -ErrorAction SilentlyContinue)) {
        $psql = Join-Path $dir.FullName 'bin\\psql.exe'
        if (Test-Path $psql) {
          $candidates += $psql
        }
      }
    }
  }

  if ($candidates.Count -eq 0) { return $null }

  # Prefer highest version folder when possible
  return ($candidates | Sort-Object { $_ } -Descending | Select-Object -First 1)
}

$psql = Resolve-Psql -Explicit $PsqlExe
if (-not $psql) {
  Fail 'psql.exe not found. Install PostgreSQL client tools or point -PsqlExe to psql.exe.'
}

# Acquire password safely
if ([string]::IsNullOrWhiteSpace($dbPass) -or $dbPass -eq 'change-me' -or $dbPass -match '^\$\{.+\}$') {
  $secure = Read-Host -AsSecureString ("PostgreSQL password for user '" + $dbUser + "'")
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $dbPass = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

if ([string]::IsNullOrWhiteSpace($dbPass)) {
  Fail 'Empty password. Set DEV_DROPS_DB_PASSWORD in .env or enter it when prompted.'
}

$env:PGPASSWORD = $dbPass

try {
  Write-Host ("OK: using psql=" + $psql)
  Write-Host ("OK: connecting to " + $dbHost + ":" + $dbPort + "/" + $dbName + " as " + $dbUser)

  $baseArgs = @('-v','ON_ERROR_STOP=1','-h', $dbHost, '-p', $dbPort, '-U', $dbUser, '-d', $dbName)

  $out1 = & $psql @baseArgs -tAc "select 1" 2>&1
  if ($LASTEXITCODE -ne 0) { throw $out1 }
  Write-Host ("OK: select 1 -> " + ($out1 | Select-Object -First 1))

  $out2 = & $psql @baseArgs -tAc "select table_name from information_schema.tables where table_schema='public' and table_name in ('drops','usuarios') order by table_name" 2>&1
  if ($LASTEXITCODE -ne 0) { throw $out2 }

  $tables = @($out2 | Where-Object { $_ -and $_.Trim().Length -gt 0 })
  if ($tables.Count -eq 0) {
    Write-Host 'WARN: tables drops/usuarios not found yet (Hibernate creates them on first successful app start).' 
  } else {
    Write-Host ('OK: tables found: ' + ($tables -join ', '))
  }

  Write-Host 'OK: PostgreSQL connectivity looks good.'
} finally {
  Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
