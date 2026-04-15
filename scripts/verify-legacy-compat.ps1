$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
  Write-Error "[FAIL] $Message"
  exit 1
}

$xhtml = Get-ChildItem -Path "src/main/webapp" -Recurse -Filter "*.xhtml" -ErrorAction SilentlyContinue
foreach ($f in $xhtml) {
  $content = Get-Content -LiteralPath $f.FullName -Raw
  if ($content -match '<h:(head|body)\b') {
    Fail "Found <h:head> or <h:body> in $($f.FullName). Use plain <head>/<body> + <f:view>."
  }
}

$java = Get-ChildItem -Path "src/main/java" -Recurse -Filter "*.java" -ErrorAction SilentlyContinue
foreach ($f in $java) {
  $content = Get-Content -LiteralPath $f.FullName -Raw
  if ($content -match '\bTypedQuery\b') {
    Fail "Found TypedQuery usage in $($f.FullName) (JPA 2.x)."
  }
  if ($content -match 'createQuery\s*\(\s*"[^"]*"\s*,\s*[^\)]+\.class\s*\)') {
    Fail "Found createQuery(String, Class) usage in $($f.FullName) (JPA 2.x)."
  }
  if ($content -match '->') {
    Fail "Found '->' in $($f.FullName) (lambda; Java 8+)."
  }
}

Write-Host "[OK] Legacy compatibility checks passed."
