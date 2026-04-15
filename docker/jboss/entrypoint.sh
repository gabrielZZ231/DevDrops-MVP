#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  DEV_DROPS_DB_HOST
  DEV_DROPS_DB_NAME
  DEV_DROPS_DB_USER
  DEV_DROPS_DB_PASSWORD
)

for v in "${required_vars[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    echo "[FAIL] Missing required env var: ${v}" >&2
    exit 1
  fi
done

DEV_DROPS_DB_PORT="${DEV_DROPS_DB_PORT:-5432}"

ds_file="${JBOSS_HOME}/server/default/deploy/devdrops-postgres-ds.xml"
cat > "${ds_file}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<datasources>
  <local-tx-datasource>
    <jndi-name>DevDropsDS</jndi-name>
    <connection-url>jdbc:postgresql://${DEV_DROPS_DB_HOST}:${DEV_DROPS_DB_PORT}/${DEV_DROPS_DB_NAME}</connection-url>
    <driver-class>org.postgresql.Driver</driver-class>
    <user-name>${DEV_DROPS_DB_USER}</user-name>
    <password>${DEV_DROPS_DB_PASSWORD}</password>
    <exception-sorter-class-name>org.jboss.resource.adapter.jdbc.vendor.PostgreSQLExceptionSorter</exception-sorter-class-name>
    <metadata>
      <type-mapping>PostgreSQL</type-mapping>
    </metadata>
  </local-tx-datasource>
</datasources>
EOF

echo "[OK] Datasource generated at ${ds_file}"
exec "${JBOSS_HOME}/bin/run.sh" -c default -b 0.0.0.0
