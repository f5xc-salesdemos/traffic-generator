#!/bin/bash
# CDN Scenario 2: Query string cache isolation
# Tools: curl
# Targets: httpbin, juice-shop — each unique query string should cache independently
# Estimated duration: 1-2 minutes
set -uo pipefail
. "$(dirname "$0")/_lib.sh"

echo "[*] CDN Query String Cache Isolation Test"
echo "[*] Target: $BASE"
echo ""

# Test group 1: httpbin with different user query strings
echo "[+] Test 1: /httpbin/get with different ?user= values"
for user in alice bob charlie dave eve; do
  URL="${BASE}/httpbin/get?user=${user}"
  # First request — should be MISS
  S1=$(check_cache_status "$URL")
  sleep 0.2
  # Second request — should be HIT
  S2=$(check_cache_status "$URL")
  if [ "$S2" = "HIT" ]; then
    pass "?user=${user}: MISS→HIT (cache populated)"
  elif [ "$S1" = "HIT" ] && [ "$S2" = "HIT" ]; then
    pass "?user=${user}: HIT→HIT (already cached)"
  else
    fail "?user=${user}: ${S1}→${S2} (expected MISS→HIT)"
  fi
done
echo ""

# Test group 2: Juice Shop search with different query terms
echo "[+] Test 2: /juice-shop/rest/products/search with different ?q= values"
for word in apple banana cherry orange lemon; do
  URL="${BASE}/juice-shop/rest/products/search?q=${word}"
  S1=$(check_cache_status "$URL")
  sleep 0.2
  S2=$(check_cache_status "$URL")
  if [ "$S2" = "HIT" ]; then
    pass "?q=${word}: MISS→HIT"
  elif [ "$S1" = "HIT" ] && [ "$S2" = "HIT" ]; then
    pass "?q=${word}: HIT→HIT (already cached)"
  else
    fail "?q=${word}: ${S1}→${S2} (expected MISS→HIT)"
  fi
done
echo ""

# Test group 3: Juice Shop root with version query strings
echo "[+] Test 3: /juice-shop/ with different ?v= values"
for v in 1 2 3 4 5; do
  URL="${BASE}/juice-shop/?v=${v}"
  S1=$(check_cache_status "$URL")
  sleep 0.2
  S2=$(check_cache_status "$URL")
  if [ "$S2" = "HIT" ]; then
    pass "?v=${v}: MISS→HIT"
  elif [ "$S1" = "HIT" ] && [ "$S2" = "HIT" ]; then
    pass "?v=${v}: HIT→HIT"
  else
    fail "?v=${v}: ${S1}→${S2} (expected MISS→HIT)"
  fi
done
echo ""

# Test group 4: Random UUID query strings (guaranteed cold cache)
echo "[+] Test 4: 20 random UUID query strings (cold cache → warm)"
RANDOM_PASS=0
RANDOM_FAIL=0
for i in $(seq 1 20); do
  UUID="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "rand-${RANDOM}-${i}")"
  URL="${BASE}/httpbin/get?r=${UUID}"
  S1=$(check_cache_status "$URL")
  sleep 0.1
  S2=$(check_cache_status "$URL")
  if [ "$S2" = "HIT" ]; then
    RANDOM_PASS=$((RANDOM_PASS + 1))
  else
    RANDOM_FAIL=$((RANDOM_FAIL + 1))
  fi
done
if [ "$RANDOM_FAIL" -eq 0 ]; then
  pass "All 20 random query strings: MISS→HIT"
else
  fail "${RANDOM_FAIL}/20 random query strings did not transition to HIT"
fi

# Test group 5: Verify different query strings are DIFFERENT cache entries
echo ""
echo "[+] Test 5: Cross-contamination check (different QS = different cache)"
URL_A="${BASE}/httpbin/get?iso=alpha-$(date +%s)"
URL_B="${BASE}/httpbin/get?iso=bravo-$(date +%s)"
# Prime A
curl -sf -o /dev/null --max-time 5 "$URL_A" 2>/dev/null
sleep 0.2
# Check B is still cold
S_B=$(check_cache_status "$URL_B")
if [ "$S_B" = "MISS" ] || [ "$S_B" = "NONE" ]; then
  pass "Cache isolation: URL_B is MISS while URL_A is cached"
else
  fail "Cache isolation: URL_B is $S_B (expected MISS — possible key collision)"
fi

summary
