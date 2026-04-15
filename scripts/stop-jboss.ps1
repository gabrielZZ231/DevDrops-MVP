param(
  [string]$EnvFile = "$PSScriptRoot\..\.env",
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

function LoadDotEnv([string]$Path) {
  $dotenv = Join-Path $PSScriptRoot 'load-dotenv.ps1'
  if (Test-Path -LiteralPath $dotenv) {
    & $dotenv -EnvFile $Path
  }
}

LoadDotEnv -Path $EnvFile

$jbossHome = $env:JBOSS_HOME
$pattern = if ([string]::IsNullOrWhiteSpace($jbossHome)) { 'org\.jboss\.Main' } else { [regex]::Escape($jbossHome) }

$procs = Get-CimInstance Win32_Process -Filter "Name='java.exe' OR Name='javaw.exe'" |
  Where-Object { $_.CommandLine -and $_.CommandLine -match 'org\.jboss\.Main' -and $_.CommandLine -match $pattern }

if (-not $procs) {
  Write-Host 'OK: no JBoss java.exe process found.'
  exit 0
}

foreach ($p in $procs) {
  Write-Host ("Stopping JBoss PID=" + $p.ProcessId)
  if ($Force) {
    Stop-Process -Id $p.ProcessId -Force
  } else {
    Stop-Process -Id $p.ProcessId
  }
}

Write-Host 'OK: stop signal sent.'
