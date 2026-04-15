param(
  [string]$EnvFile = (Join-Path (Split-Path -Parent $PSScriptRoot) '.env')
)

$ErrorActionPreference = 'Stop'

if (!(Test-Path -LiteralPath $EnvFile)) {
  throw "Missing .env file: $EnvFile"
}

$lines = Get-Content -LiteralPath $EnvFile
foreach ($line in $lines) {
  $t = $line.Trim()
  if ($t.Length -eq 0) { continue }
  if ($t.StartsWith('#')) { continue }

  $eq = $t.IndexOf('=')
  if ($eq -lt 1) { continue }

  $name = $t.Substring(0, $eq).Trim()
  $value = $t.Substring($eq + 1).Trim()

  if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
    $value = $value.Substring(1, $value.Length - 2)
  }

  # Common on Windows: users write C:\\path\\to\\dir in .env.
  # Normalize *_HOME variables to use single backslashes.
  if ($name -match '(^JBOSS_HOME$|_HOME$)') {
    $value = $value.Replace('\\', '\')
  }

  if ($name.Length -eq 0) { continue }

  Set-Item -Path ("Env:" + $name) -Value $value
}
