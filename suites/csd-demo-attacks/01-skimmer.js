#!/usr/bin/env node
// CSD Demo Attack Test: Card Skimmer
// Enables the card skimmer toggle, fills checkout form, verifies exfiltrated card data.

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const PROFILE_DIR = `/tmp/pw-profile-${path.basename(__filename, '.js')}-${process.pid}`;
process.on('exit', () => { try { fs.rmSync(PROFILE_DIR, { recursive: true, force: true }); } catch {} });

const TARGET_FQDN = process.argv[2];
if (!TARGET_FQDN) {
  console.error('Usage: 01-skimmer.js <TARGET_FQDN>');
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

    // 3. Check the skimmer toggle checkbox
    await page.check('#toggleSkimmer');

    // 4. Fill CC fields
    await page.fill('[name="ccName"]', 'John Doe');
    await page.fill('[name="ccNumber"]', '4111111111111111');
    await page.fill('[name="ccExpiry"]', '12/28');
    await page.fill('[name="ccCvv"]', '123');

    // 5. Fill other required fields with test data
    await page.fill('[name="firstName"]', 'John');
    await page.fill('[name="lastName"]', 'Doe');
    await page.fill('[name="email"]', 'john.doe@example.com');
    await page.fill('[name="phone"]', '555-123-4567');
    await page.fill('[name="address"]', '123 Main St');
    await page.fill('[name="city"]', 'Anytown');
    await page.fill('[name="state"]', 'CA');
    await page.fill('[name="zip"]', '90210');
    await page.fill('[name="ssn"]', '123-45-6789');

    // 6. Submit the form (click "Place Order" button, not the panel toggle)
    await page.click('button:has-text("Place Order")');

    // 7. Wait 2s for exfil to complete
    await page.waitForTimeout(2000);

    // 8. Fetch exfil log, filter for type=skimmer
    const res = await fetch(`${BASE_URL}/csd-demo/exfil/log`);
    const log = await res.json();
    const skimmerEntries = log.filter(e => e.attack_type === 'skimmer');

    // 9. Verify captured card data matches what was entered
    if (skimmerEntries.length === 0) {
      console.log('FAIL: No skimmer exfiltration entries found in log');
      process.exit(1);
    }

    const captured = skimmerEntries[0];
    const data = captured.payload || captured;
    console.log('Captured skimmer data:', JSON.stringify(data, null, 2));

    const hasCardNumber = JSON.stringify(data).includes('4111111111111111');
    const hasCardName = JSON.stringify(data).includes('John Doe');

    if (hasCardNumber && hasCardName) {
      console.log('PASS: Card skimmer captured correct card data');
      console.log(`  - Card Name: John Doe`);
      console.log(`  - Card Number: 4111111111111111`);
      console.log(`  - Entries found: ${skimmerEntries.length}`);
    } else {
      console.log('FAIL: Skimmer data does not match expected card details');
      console.log(`  - hasCardNumber: ${hasCardNumber}`);
      console.log(`  - hasCardName: ${hasCardName}`);
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
