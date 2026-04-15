param(
  [string]$JbossHome = "",
  [string]$EnvFile = "$PSScriptRoot\..\.env",
  [switch]$PromptPassword
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  Write-Error "[FAIL] $Message"
  exit 1
}

function Load-DotEnv([string]$Path) {
  if (!(Test-Path -LiteralPath $Path)) {
    Fail "Missing .env file at: $Path"
  }

  $lines = Get-Content -LiteralPath $Path
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

    if ($name -match '(^JBOSS_HOME$|_HOME$)') {
      $value = $value.Replace('\\', '\')
    }

    if ($name.Length -eq 0) { continue }

    Set-Item -Path ("Env:" + $name) -Value $value
  }
}

Load-DotEnv -Path $EnvFile

if ([string]::IsNullOrWhiteSpace($JbossHome)) {
  $JbossHome = $env:JBOSS_HOME
}

if ([string]::IsNullOrWhiteSpace($JbossHome)) {
  Fail "JBOSS_HOME not provided. Set it in .env or pass -JbossHome."
}

$deploy = Join-Path $JbossHome 'server\default\deploy'
$lib = Join-Path $JbossHome 'server\default\lib'

if (!(Test-Path $deploy)) { Fail ("Deploy dir not found: " + $deploy) }
if (!(Test-Path $lib)) { Fail ("Lib dir not found: " + $lib) }

$dbHost = $env:DEV_DROPS_DB_HOST
$dbPort = $env:DEV_DROPS_DB_PORT
$dbName = $env:DEV_DROPS_DB_NAME
$dbUser = $env:DEV_DROPS_DB_USER
$dbPass = $env:DEV_DROPS_DB_PASSWORD

if ([string]::IsNullOrWhiteSpace($dbHost)) { Fail "DEV_DROPS_DB_HOST missing in .env" }
if ([string]::IsNullOrWhiteSpace($dbPort)) { $dbPort = '5432' }
if ([string]::IsNullOrWhiteSpace($dbName)) { Fail "DEV_DROPS_DB_NAME missing in .env" }
if ([string]::IsNullOrWhiteSpace($dbUser)) { Fail "DEV_DROPS_DB_USER missing in .env" }

if ($PromptPassword -or [string]::IsNullOrWhiteSpace($dbPass) -or $dbPass -eq 'change-me' -or $dbPass -match '^\$\{.+\}$') {
  $secure = Read-Host -AsSecureString ("PostgreSQL password for user '" + $dbUser + "' (used for JBoss datasource)")
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $dbPass = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

if ([string]::IsNullOrWhiteSpace($dbPass)) { Fail "DEV_DROPS_DB_PASSWORD missing in .env (or empty password entered)." }

if ($dbPass -eq 'change-me') {
  Fail "DEV_DROPS_DB_PASSWORD is still 'change-me'. Set the real password in .env."
}
if ($dbPass -match '^\$\{.+\}$') {
  Fail "DEV_DROPS_DB_PASSWORD looks like an unresolved placeholder ({...). Set the real password in .env."
}

$connectionUrl = "jdbc:postgresql://${dbHost}:${dbPort}/${dbName}"

function XmlEscape([string]$s) {
  if ($null -eq $s) { return '' }
  return [System.Security.SecurityElement]::Escape($s)
}

$dsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<datasources>
  <local-tx-datasource>
    <jndi-name>DevDropsDS</jndi-name>
    <connection-url>$(XmlEscape $connectionUrl)</connection-url>
    <driver-class>org.postgresql.Driver</driver-class>
    <user-name>$(XmlEscape $dbUser)</user-name>
    <password>$(XmlEscape $dbPass)</password>

    <exception-sorter-class-name>org.jboss.resource.adapter.jdbc.vendor.PostgreSQLExceptionSorter</exception-sorter-class-name>

    <metadata>
      <type-mapping>PostgreSQL</type-mapping>
    </metadata>
  </local-tx-datasource>
</datasources>
"@

$tmp = Join-Path $env:TEMP ("devdrops-ds-" + [Guid]::NewGuid().ToString('N') + ".xml")
Set-Content -LiteralPath $tmp -Value $dsXml -Encoding UTF8

$dsDst = Join-Path $deploy 'devdrops-postgres-ds.xml'
Copy-Item -Force $tmp $dsDst
Remove-Item -Force $tmp -ErrorAction SilentlyContinue

$pgSrc = Join-Path $env:USERPROFILE '.m2\repository\org\postgresql\postgresql\42.2.27.jre7\postgresql-42.2.27.jre7.jar'
$pgDst = Join-Path $lib 'postgresql-42.2.27.jre7.jar'
if (!(Test-Path $pgSrc)) { Fail ("PostgreSQL driver not found in ~/.m2: " + $pgSrc) }
Copy-Item -Force $pgSrc $pgDst

$faceletsSrc = Join-Path $env:USERPROFILE '.m2\repository\com\sun\facelets\jsf-facelets\1.1.15.B1\jsf-facelets-1.1.15.B1.jar'
$faceletsDst = Join-Path $lib 'jsf-facelets-1.1.15.B1.jar'
if (!(Test-Path $faceletsSrc)) { Fail "Facelets 1.1.15.B1 not found in ~/.m2. Run: mvn install:install-file ..." }
Copy-Item -Force $faceletsSrc $faceletsDst

Write-Host ("OK: DS=" + $dsDst)
Write-Host ("OK: PG=" + $pgDst)
Write-Host ("OK: Facelets=" + $faceletsDst)
