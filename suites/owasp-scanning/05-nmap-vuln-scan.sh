#!/bin/bash
set -uo pipefail

########################################################################
# 05-nmap-vuln-scan.sh — Nmap Vulnerability Scripts
#
# Runs Nmap with vulnerability detection, HTTP enumeration, and SSL
# scanning scripts against the target.
########################################################################

TARGET="${1:?Usage: $0 <target-host>}"
BASE="${TARGET_PROTOCOL:-http}://${TARGET}"

echo "========================================"
echo " Nmap Vulnerability Scan"
echo "========================================"
echo "[*] Target: ${TARGET}"
echo "[*] Base URL: ${BASE}"
echo ""

########################################################################
# Phase 1: Vulnerability scripts on port 80
########################################################################
echo "[*] Phase 1: Vulnerability scripts (port 80)"
echo "----------------------------------------"
nmap -sV --script=vuln -p 80 "${TARGET}" 2>&1 || true

########################################################################
# Phase 2: All HTTP scripts on port 80
########################################################################
echo ""
echo "[*] Phase 2: HTTP enumeration scripts (port 80)"
echo "----------------------------------------"
nmap -sV --script=http-* -p 80 "${TARGET}" 2>&1 || true

########################################################################
# Phase 3: SSL scripts on port 443 (if HTTPS target)
########################################################################
if [[ "${TARGET_PROTOCOL:-http}" == "https" ]]; then
    echo ""
    echo "[*] Phase 3: SSL/TLS scripts (port 443)"
    echo "----------------------------------------"
    nmap --script=ssl-* -p 443 "${TARGET}" 2>&1 || true
else
    echo ""
    echo "[*] Phase 3: SSL scan skipped (target protocol is not HTTPS)"
    echo "    Set TARGET_PROTOCOL=https to enable SSL scanning."
    # Still try port 443 in case it is open
    echo "[*] Checking if port 443 is open anyway..."
    nmap -p 443 "${TARGET}" 2>&1 || true
    PORT_443_OPEN=$(nmap -p 443 "${TARGET}" 2>/dev/null | grep -c "443/tcp.*open" || echo "0")
    if [[ "${PORT_443_OPEN}" -gt 0 ]]; then
        echo "[*] Port 443 is open. Running SSL scripts..."
        nmap --script=ssl-* -p 443 "${TARGET}" 2>&1 || true
    fi
fi

########################################################################
# Phase 4: Parse and summarize
########################################################################
echo ""
echo "========================================"
echo " Nmap Scan Summary"
echo "========================================"
echo "[*] Review the output above for:"
echo "    - CVE references (VULNERABLE markers)"
echo "    - HTTP enumeration findings (directories, methods, headers)"
echo "    - SSL/TLS weaknesses (if applicable)"
echo ""
echo "[*] Nmap vulnerability scan finished."
