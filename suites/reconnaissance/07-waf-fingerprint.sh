#!/bin/bash
# WAF detection and bypass testing
# Tools: curl
# Targets: All apps — testing WAF trigger payloads, encoding bypasses, header tricks
# Estimated duration: 1-2 minutes
set -uo pipefail

TARGET="${1:?Usage: 07-waf-fingerprint.sh <TARGET_FQDN>}"
BASE="${TARGET_PROTOCOL:-http}://${TARGET}"

echo "[*] WAF detection and bypass suite against ${TARGET}"
echo ""

# --- Helper ---
waf_test() {
  local label="$1"
  shift
  code=$(curl -sk -o /dev/null -w "%{http_code}" "$@" --max-time 10) || code="ERR"
  if [[ "$code" == "403" ]]; then
    echo "  [BLOCKED] ${label} -> HTTP ${code}"
  else
    echo "  [${code}]    ${label}"
  fi
}

# === Section 1: Known WAF trigger payloads ===
echo "[+] Section 1: WAF trigger payloads (expect blocks)"

waf_test "Basic SQLi in query" \
  "${BASE}/httpbin/get?id=' OR 1=1--"

waf_test "XSS script tag in query" \
  "${BASE}/httpbin/get?q=<script>alert(1)</script>"

waf_test "Command injection in query" \
  "${BASE}/httpbin/get?cmd=;cat /etc/passwd"

waf_test "Path traversal in query" \
  "${BASE}/httpbin/get?file=../../../etc/passwd"

echo ""

# === Section 2: Encoding bypass attempts ===
echo "[+] Section 2: Encoding bypass techniques"

waf_test "URL-encoded SQLi (%27%20OR%201%3D1--)" \
  "${BASE}/httpbin/get?id=%27%20OR%201%3D1--"

waf_test "Double URL-encoded SQLi (%2527%2520OR)" \
  "${BASE}/httpbin/get?id=%2527%2520OR%25201%253D1--"

waf_test "Unicode SQLi (fullwidth quote)" \
  "${BASE}/httpbin/get?id=%EF%BC%87%20OR%201=1--"

waf_test "Hex-encoded XSS (0x3c736372697074)" \
  "${BASE}/httpbin/get?q=%3C%73%63%72%69%70%74%3E%61%6C%65%72%74%28%31%29%3C%2F%73%63%72%69%70%74%3E"

waf_test "Case-mixed XSS (<ScRiPt>)" \
  "${BASE}/httpbin/get?q=<ScRiPt>alert(1)</ScRiPt>"

echo ""

# === Section 3: HTTP parameter pollution ===
echo "[+] Section 3: HTTP parameter pollution"

waf_test "HPP: id=1&id=' OR 1=1" \
  "${BASE}/httpbin/get?id=1&id=%27%20OR%201%3D1"

waf_test "HPP: q=safe&q=<script>alert(1)</script>" \
  "${BASE}/httpbin/get?q=safe&q=<script>alert(1)</script>"

echo ""

# === Section 4: Header-based bypass attempts ===
echo "[+] Section 4: Header-based bypasses"

waf_test "X-Forwarded-For: 127.0.0.1 with SQLi" \
  -H "X-Forwarded-For: 127.0.0.1" \
  "${BASE}/httpbin/get?id=' OR 1=1--"

waf_test "X-Original-URL: /admin" \
  -H "X-Original-URL: /admin" \
  "${BASE}/httpbin/get"

waf_test "X-Rewrite-URL: /admin" \
  -H "X-Rewrite-URL: /admin" \
  "${BASE}/httpbin/get"

echo ""

# === Section 5: Polyglot payloads ===
echo "[+] Section 5: Polyglot payloads (multi-rule triggers)"

waf_test "SQLi+XSS polyglot" \
  "${BASE}/httpbin/get?q='><script>alert(1)</script>-- OR 1=1"

waf_test "Full polyglot (SQLi+XSS+CMDi+traversal)" \
  "${BASE}/httpbin/get?q=' OR 1=1--><script>alert(1)</script>;cat /etc/passwd;../../etc/shadow"

echo ""
echo "[*] WAF detection and bypass suite complete (15 test cases)"
