#!/usr/bin/env node
// CSD Demo Attack Test: Formjacker
// Enables the formjacker toggle, fills checkout form, verifies exfiltrated form data.

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const PROFILE_DIR = `/tmp/pw-profile-${path.basename(__filename, '.js')}-${process.pid}`;
process.on('exit', () => { try { fs.rmSync(PROFILE_DIR, { recursive: true, force: true }); } catch {} });

const TARGET_FQDN = process.argv[2];
if (!TARGET_FQDN) {
  console.error('Usage: 02-formjacker.js <TARGET_FQDN>');
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
        url.pathname = '/csd-demo' + url.pathname;
        route.continue({ url: url.toString() });
      } else {
        route.continue();
      }
    });

    // 2. Navigate to /csd-demo/
    await page.goto(`${BASE_URL}/csd-demo/`, { waitUntil: 'networkidle' });

    // 3. Check the formjacker toggle
    await page.check('#toggleFormjacker');

    // 4. Fill all form fields
    await page.fill('[name="firstName"]', 'Jane');
    await page.fill('[name="lastName"]', 'Smith');
    await page.fill('[name="email"]', 'jane.smith@example.com');
    await page.fill('[name="phone"]', '555-987-6543');
    await page.fill('[name="address"]', '456 Oak Ave');
    await page.fill('[name="city"]', 'Springfield');
    await page.fill('[name="state"]', 'IL');
    await page.fill('[name="zip"]', '62704');
    await page.fill('[name="ssn"]', '987-65-4321');
    await page.fill('[name="ccName"]', 'Jane Smith');
    await page.fill('[name="ccNumber"]', '5500000000000004');
    await page.fill('[name="ccExpiry"]', '06/27');
    await page.fill('[name="ccCvv"]', '456');

    // 5. Submit the form
    await page.click('button:has-text("Place Order")');

    // 6. Wait 2s for exfil to complete
    await page.waitForTimeout(2000);

    // 7. Fetch exfil log, filter for type=formjacker
    const res = await fetch(`${BASE_URL}/csd-demo/exfil/log`);
    const log = await res.json();
    const formjackerEntries = log.filter(e => e.attack_type === 'formjacker');

    // 8. Verify form data was captured
    if (formjackerEntries.length === 0) {
      console.log('FAIL: No formjacker exfiltration entries found in log');
      process.exit(1);
    }

    const captured = formjackerEntries[0];
    const data = captured.payload || captured;
    const dataStr = decodeURIComponent(JSON.stringify(data));
    console.log('Captured formjacker data:', dataStr);

    const hasEmail = dataStr.includes('jane.smith@example.com');
    const hasCC = dataStr.includes('5500000000000004');
    const hasName = dataStr.includes('Jane') && dataStr.includes('Smith');

    if (hasEmail && hasCC && hasName) {
      console.log('PASS: Formjacker captured complete form data');
      console.log(`  - Name: Jane Smith`);
      console.log(`  - Email: jane.smith@example.com`);
      console.log(`  - CC: 5500000000000004`);
      console.log(`  - Entries found: ${formjackerEntries.length}`);
    } else {
      console.log('FAIL: Formjacker data does not match expected form details');
      console.log(`  - hasEmail: ${hasEmail}`);
      console.log(`  - hasCC: ${hasCC}`);
      console.log(`  - hasName: ${hasName}`);
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
