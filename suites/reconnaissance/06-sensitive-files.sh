#!/bin/bash
# Sensitive file and endpoint discovery
# Tools: curl
# Targets: All apps — probing for backup files, config leaks, debug endpoints, admin panels, API docs
# Estimated duration: 1-2 minutes
set -uo pipefail

TARGET="${1:?Usage: 06-sensitive-files.sh <TARGET_FQDN>}"
BASE="${TARGET_PROTOCOL:-http}://${TARGET}"

echo "[*] Sensitive file discovery against ${TARGET}"
echo ""

# --- Full list of sensitive paths to probe ---
PATHS=(
  # Backup and temp files
  "/.bak"
  "/backup.sql"
  "/backup.zip"
  "/backup.tar.gz"
  "/db.sql"
  "/dump.sql"
  "/database.sql.gz"
  "/.old"
  "/.swp"
  "/.DS_Store"

  # Git and VCS
  "/.git/config"
  "/.git/HEAD"
  "/.gitignore"
  "/.svn/entries"
  "/.hg/hgrc"

  # Config and environment files
  "/.env"
  "/.env.local"
  "/.env.production"
  "/web.config"
  "/wp-config.php"
  "/config.php"
  "/configuration.php"
  "/settings.py"
  "/application.yml"
  "/appsettings.json"

  # Debug and diagnostic endpoints
  "/debug"
  "/trace"
  "/actuator"
  "/actuator/health"
  "/actuator/env"
  "/actuator/beans"
  "/metrics"
  "/info"
  "/health"
  "/status"
  "/.well-known/security.txt"
  "/.well-known/openid-configuration"
  "/server-status"
  "/server-info"
  "/phpinfo.php"
  "/elmah.axd"

  # Admin panels
  "/admin"
  "/admin.php"
  "/administrator"
  "/wp-admin"
  "/wp-login.php"
  "/manager/html"
  "/phpmyadmin"
  "/adminer.php"

  # API documentation
  "/swagger"
  "/swagger.json"
  "/swagger-ui.html"
  "/api-docs"
  "/openapi.json"
  "/graphql"
  "/graphiql"
  "/v1/docs"
  "/redoc"
)

# --- Counters ---
found_200=0
found_403=0
found_other=0

echo "[+] Probing ${#PATHS[@]} sensitive paths..."
echo ""

for path in "${PATHS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}${path}" \
    --max-time 5) || code="ERR"

  case "$code" in
    200)
      echo "  [FOUND]   ${path} -> HTTP ${code}"
      ((found_200++)) || true
      ;;
    403)
      echo "  [FORBID]  ${path} -> HTTP ${code}"
      ((found_403++)) || true
      ;;
    *)
      echo "  [${code}]     ${path}"
      ((found_other++)) || true
      ;;
  esac
done

echo ""
echo "[*] Sensitive file discovery complete"
echo "    200 (Found):     ${found_200}"
echo "    403 (Forbidden): ${found_403}"
echo "    Other:           ${found_other}"
echo "    Total probed:    ${#PATHS[@]}"
