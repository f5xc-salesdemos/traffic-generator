#!/bin/bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/opt/traffic-generator/config.env}"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  set -a && source "$CONFIG_FILE" && set +a
fi

TARGET_FQDN="${TARGET_FQDN:?TARGET_FQDN is required. Set it in config.env or export it.}"
TARGET_PROTOCOL="${TARGET_PROTOCOL:-http}"
TARGET_ORIGIN_IP="${TARGET_ORIGIN_IP:-}"
CRAPI_PORT="${CRAPI_PORT:-8888}"
export TARGET_FQDN TARGET_PROTOCOL TARGET_ORIGIN_IP CRAPI_PORT
SUITE="${1:?Usage: runner.sh <suite-name> [--dry-run]}"
DRY_RUN="${2:-}"

SUITES_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_DIR="${SUITES_DIR}/${SUITE}"
RESULTS_DIR="/opt/traffic-generator/results/$(date +%Y%m%d-%H%M%S)-${SUITE}"

if [[ ! -d "$SUITE_DIR" ]]; then
  echo "ERROR: Suite '${SUITE}' not found."
  echo "Available suites:"
  find "$SUITES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort
  exit 1
fi

mkdir -p "$RESULTS_DIR"
STARTED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "{\"suite\":\"${SUITE}\",\"target\":\"${TARGET_FQDN}\",\"started\":\"${STARTED}\",\"status\":\"running\"}" \
  > "$RESULTS_DIR/meta.json"

PASSED=0
FAILED=0
SKIPPED=0

for script in "$SUITE_DIR"/[0-9]*; do
  [[ -f "$script" ]] || continue
  [[ -x "$script" ]] || { echo "SKIP: $(basename "$script") (not executable)"; SKIPPED=$((SKIPPED+1)); continue; }

  script_name=$(basename "$script")
  echo "=== ${script_name} ==="

  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "[DRY-RUN] Would execute: $script $TARGET_FQDN"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  if "$script" "$TARGET_FQDN" 2>&1 | tee "$RESULTS_DIR/${script_name}.log"; then
    PASSED=$((PASSED+1))
  else
    echo "WARN: ${script_name} exited with code $?"
    FAILED=$((FAILED+1))
  fi
  echo ""
done

echo "{\"suite\":\"${SUITE}\",\"target\":\"${TARGET_FQDN}\",\"started\":\"${STARTED}\",\"completed\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"status\":\"completed\",\"passed\":${PASSED},\"failed\":${FAILED},\"skipped\":${SKIPPED}}" \
  > "$RESULTS_DIR/meta.json"

echo "=== Suite Complete ==="
echo "Passed: ${PASSED} | Failed: ${FAILED} | Skipped: ${SKIPPED}"
echo "Results: ${RESULTS_DIR}"
