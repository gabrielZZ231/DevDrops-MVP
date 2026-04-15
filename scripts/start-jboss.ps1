param(
  [string]$EnvFile = "$PSScriptRoot\..\.env",
  [string]$JbossHome = "",
  [string]$Jdk7Home = "",
  [switch]$Debug,
  [switch]$NoProvision
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  # Keep output clean (no PowerShell error stack) while still failing fast
  Write-Host "[FAIL] $Message" -ForegroundColor Red
  exit 1
}

# Load .env into process environment
$dotenv = Join-Path $PSScriptRoot 'load-dotenv.ps1'
if (!(Test-Path -LiteralPath $dotenv)) {
  Fail "Missing script: $dotenv"
}

& $dotenv -EnvFile $EnvFile

if ([string]::IsNullOrWhiteSpace($JbossHome)) {
  $JbossHome = $env:JBOSS_HOME
}
if ([string]::IsNullOrWhiteSpace($Jdk7Home)) {
  $Jdk7Home = $env:JDK7_HOME
}

if ([string]::IsNullOrWhiteSpace($JbossHome)) {
  Fail "JBOSS_HOME missing. Configure it in .env or pass -JbossHome."
}
if ([string]::IsNullOrWhiteSpace($Jdk7Home)) {
  Fail "JDK7_HOME missing. Configure it in .env or pass -Jdk7Home (JBoss 5.1 requires Java 7)."
}

# Prevent "double start" which causes BindException + cascaded deployment errors
$jbossProcs = Get-CimInstance Win32_Process -Filter "Name='java.exe' OR Name='javaw.exe'" |
  Where-Object { $_.CommandLine -and $_.CommandLine -match 'org\.jboss\.Main' -and $_.CommandLine -match [regex]::Escape($JbossHome) }

if ($jbossProcs) {
  $pids = ($jbossProcs | Select-Object -ExpandProperty ProcessId | Sort-Object -Unique) -join ', '
  Fail "JBoss already appears to be running (PID(s): $pids). Stop it first: .\\scripts\\stop-jboss.ps1 -Force"
}

if (-not $NoProvision) {
  $provision = Join-Path $PSScriptRoot 'provision-jboss.ps1'
  if (!(Test-Path -LiteralPath $provision)) {
    Fail "Missing script: $provision"
  }

  Write-Host 'OK: provisioning JBoss (datasource + libs) from .env'
  & $provision -EnvFile $EnvFile -JbossHome $JbossHome
}

$runBat = Join-Path $JbossHome 'bin\run.bat'
if (!(Test-Path -LiteralPath $runBat)) {
  Fail "run.bat not found: $runBat"
}

$javaExe = Join-Path $Jdk7Home 'bin\java.exe'
if (!(Test-Path -LiteralPath $javaExe)) {
  Fail "JDK7_HOME invalido (java.exe nao encontrado): $javaExe"
}

$env:JAVA_HOME = $Jdk7Home
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

Write-Host "OK: JBOSS_HOME=$JbossHome"
Write-Host "OK: JAVA_HOME=$env:JAVA_HOME"
Write-Host "OK: server.log=$(Join-Path $JbossHome 'server\default\log\server.log')"

if ($Debug) {
  & $runBat -c default --debug
} else {
  & $runBat -c default
}
