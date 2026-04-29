#!/usr/bin/env node
// CSD Demo Attack Test: Keylogger
// Enables the keylogger toggle, types slowly into fields, verifies keystroke exfiltration.

const { chromium } = require('playwright');
const path = require('node:path');
const fs = require('node:fs');
const PROFILE_DIR = `/tmp/pw-profile-${path.basename(__filename, '.js')}-${process.pid}`;
process.on('exit', () => {
  try {
    fs.rmSync(PROFILE_DIR, { recursive: true, force: true });
  } catch {}
});

const TARGET_FQDN = process.argv[2];
if (!TARGET_FQDN) {
  console.error('Usage: 03-keylogger.js <TARGET_FQDN>');
  process.exit(1);
}

const BASE_URL = `${process.env.TARGET_PROTOCOL || 'http'}://${TARGET_FQDN}`;

(async () => {
  let browser;
  try {
    // 1. Clear exfil log
    await fetch(`${BASE_URL}/csd-demo/exfil/clear`, { method: 'POST' });

    browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
    const context = await browser.newContext({ ignoreHTTPSErrors: true });
    const page = await context.newPage();

    // Intercept /exfil requests and rewrite to /csd-demo/exfil (nginx proxy prefix fix)
    await page.route('**/exfil**', (route) => {
      const url = new URL(route.request().url());
      if (!url.pathname.startsWith('/csd-demo/')) {
        url.pathname = `/csd-demo${url.pathname}`;
        route.continue({ url: url.toString() });
      } else {
        route.continue();
      }
    });

    // 2. Navigate to /csd-demo/
    await page.goto(`${BASE_URL}/csd-demo/`, { waitUntil: 'networkidle' });

    // 3. Check the keylogger toggle
    await page.check('#toggleKeylogger');

    // 4. Use page.type() with delay to simulate real typing
    const testEmail = 'victim@example.com';
    const testCC = '4000123456789010';
    const testSSN = '111-22-3333';

    await page.click('[name="email"]');
    await page.type('[name="email"]', testEmail, { delay: 80 });

    await page.click('[name="ccNumber"]');
    await page.type('[name="ccNumber"]', testCC, { delay: 80 });

    await page.click('[name="ssn"]');
    await page.type('[name="ssn"]', testSSN, { delay: 80 });

    // 5. Wait 3s (keylogger has 1.5s buffer, need time for flush)
    await page.waitForTimeout(3000);

    // 6. Fetch exfil log, filter for type=keylogger
    const res = await fetch(`${BASE_URL}/csd-demo/exfil/log`);
    const log = await res.json();
    const keyloggerEntries = log.filter((e) => e.attack_type === 'keylogger');

    // 7. Verify keystroke data was captured
    if (keyloggerEntries.length === 0) {
      console.log('FAIL: No keylogger exfiltration entries found in log');
      process.exit(1);
    }

    const allData = keyloggerEntries.map((e) => JSON.stringify(e.data || e)).join(' ');
    console.log(`Captured ${keyloggerEntries.length} keylogger entries`);

    // Check if keystrokes from typed fields appear in captured data
    const hasEmailKeys = allData.includes('victim') || allData.includes('example');
    const hasCCKeys = allData.includes('4000') || allData.includes('9010');
    const hasSSNKeys = allData.includes('111') || allData.includes('3333');

    console.log('Keystroke summary:');
    console.log(`  - Email keystrokes captured: ${hasEmailKeys}`);
    console.log(`  - CC keystrokes captured: ${hasCCKeys}`);
    console.log(`  - SSN keystrokes captured: ${hasSSNKeys}`);

    if (hasEmailKeys || hasCCKeys || hasSSNKeys) {
      console.log('PASS: Keylogger captured keystroke data');
      console.log(`  - Total keylogger entries: ${keyloggerEntries.length}`);
      keyloggerEntries.forEach((entry, i) => {
        const preview = JSON.stringify(entry.payload || entry).substring(0, 120);
        console.log(`  - Entry ${i}: ${preview}...`);
      });
    } else {
      console.log('FAIL: Keylogger entries found but no matching keystroke data');
      console.log('  Raw entries:', JSON.stringify(keyloggerEntries, null, 2));
      process.exit(1);
    }

    await browser.close();
    fs.rmSync(PROFILE_DIR, { recursive: true, force: true });
  } catch (err) {
    console.error('FAIL: Unexpected error:', err.message);
    if (browser) await browser.close();
    fs.rmSync(PROFILE_DIR, { recursive: true, force: true });
    process.exit(1);
  }
})();
