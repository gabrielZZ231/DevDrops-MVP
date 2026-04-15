#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

if grep -RIn --include='*.xhtml' -E '<h:(head|body)\b' src/main/webapp 1>/dev/null; then
  fail "Found <h:head> or <h:body> in .xhtml (JSF 2.x tags). Use plain <head>/<body> + <f:view>."
fi

if grep -RIn --include='*.java' -E '\bTypedQuery\b' src/main/java 1>/dev/null; then
  fail "Found TypedQuery usage (JPA 2.x). Use Query + casts."
fi

if grep -RIn --include='*.java' -E 'createQuery\s*\(\s*"[^"]*"\s*,\s*[^\)]+\.class\s*\)' src/main/java 1>/dev/null; then
  fail "Found createQuery(String, Class) usage (JPA 2.x). Use createQuery(String) instead."
fi

if grep -RIn --include='*.java' -E '->' src/main/java 1>/dev/null; then
  fail "Found '->' in Java sources (lambda; Java 8+)."
fi

echo "[OK] Legacy compatibility checks passed."
