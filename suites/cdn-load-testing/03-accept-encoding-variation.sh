#!/bin/bash
# CDN Scenario 3: Accept-Encoding variation (Vary fragmentation test)
# Tools: curl
# Targets: Cacheable endpoints — verify all encoding variants return HIT from single cache entry
# Estimated duration: 1 minute
set -uo pipefail
. "$(dirname "$0")/_lib.sh"

echo "[*] CDN Accept-Encoding Variation Test (Vary fragmentation)"
echo "[*] Target: $BASE"
echo ""

CACHEABLE_ENDPOINTS=(
  "/juice-shop/"
  "/httpbin/get"
  "/whoami/"
  "/health"
)

ENCODING_VARIANTS=(
  "gzip"
  "br"
  "gzip, deflate"
  "gzip, deflate, br"
  "identity"
)

for ep in "${CACHEABLE_ENDPOINTS[@]}"; do
  URL="${BASE}${ep}"
  echo "[+] Testing: $ep"

  # Step 1: Prime cache with first encoding
  echo "    Priming cache with Accept-Encoding: gzip"
  curl -sf -o /dev/null --max-time 5 -H "Accept-Encoding: gzip" "$URL" 2>/dev/null
  sleep 0.3
  # Verify it cached
  PRIME_STATUS=$(curl -sf -o /dev/null -D - --max-time 5 -H "Accept-Encoding: gzip" "$URL" 2>/dev/null | grep -i "X-Cache-Status" | awk '{print $2}' | tr -d '\r')
  echo "    Prime status: ${PRIME_STATUS:-NONE}"

  # Step 2: Test all encoding variants
  ALL_HIT=true
  for enc in "${ENCODING_VARIANTS[@]}"; do
    STATUS=$(curl -sf -o /dev/null -D - --max-time 5 -H "Accept-Encoding: $enc" "$URL" 2>/dev/null | grep -i "X-Cache-Status" | awk '{print $2}' | tr -d '\r')
    STATUS="${STATUS:-NONE}"
    if [ "$STATUS" = "HIT" ] || [ "$STATUS" = "STALE" ]; then
      echo "    Accept-Encoding: ${enc} → $STATUS"
    else
      echo "    Accept-Encoding: ${enc} → $STATUS *** FRAGMENTATION ***"
      ALL_HIT=false
    fi
    sleep 0.1
  done

  # Step 3: Test with no Accept-Encoding header at all
  STATUS_NONE=$(curl -sf -o /dev/null -D - --max-time 5 -H "Accept-Encoding:" "$URL" 2>/dev/null | grep -i "X-Cache-Status" | awk '{print $2}' | tr -d '\r')
  STATUS_NONE="${STATUS_NONE:-NONE}"
  if [ "$STATUS_NONE" = "HIT" ] || [ "$STATUS_NONE" = "STALE" ]; then
    echo "    Accept-Encoding: (none) → $STATUS_NONE"
  else
    echo "    Accept-Encoding: (none) → $STATUS_NONE *** FRAGMENTATION ***"
    ALL_HIT=false
  fi

  if [ "$ALL_HIT" = true ]; then
    pass "$ep — all encoding variants served from single cache entry"
  else
    fail "$ep — Vary fragmentation detected (some variants cache separately)"
  fi
  echo ""
done

summary
