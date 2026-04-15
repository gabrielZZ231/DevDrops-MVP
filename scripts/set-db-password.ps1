param(
  [string]$EnvFile = "$PSScriptRoot\..\.env"
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  Write-Error "[FAIL] $Message"
  exit 1
}

if (!(Test-Path -LiteralPath $EnvFile)) {
  Fail "Missing .env file: $EnvFile"
}

$secure = Read-Host -AsSecureString "PostgreSQL password (will be written to .env)"
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
  $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

if ([string]::IsNullOrWhiteSpace($plain)) {
  Fail "Empty password provided."
}

$lines = Get-Content -LiteralPath $EnvFile
$found = $false
$out = New-Object System.Collections.Generic.List[string]

foreach ($line in $lines) {
  if ($line -match '^[\s]*DEV_DROPS_DB_PASSWORD[\s]*=') {
    $out.Add('DEV_DROPS_DB_PASSWORD=' + $plain)
    $found = $true
  } else {
    $out.Add($line)
  }
}

if (-not $found) {
  # Keep a trailing newline-ish feel
  $out.Add('')
  $out.Add('DEV_DROPS_DB_PASSWORD=' + $plain)
}

# Write as UTF-8 (Windows PowerShell writes with BOM; acceptable for .env)
Set-Content -LiteralPath $EnvFile -Value $out -Encoding UTF8

Write-Host "OK: DEV_DROPS_DB_PASSWORD updated in .env"