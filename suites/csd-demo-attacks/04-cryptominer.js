#!/usr/bin/env node
// CSD Demo Attack Test: Cryptominer
// Enables the cryptominer toggle, waits for mining beacon, verifies exfiltration.

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
  console.error('Usage: 04-cryptominer.js <TARGET_FQDN>');
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

    // Capture CPU baseline before enabling miner
    const cpuBefore = await page.evaluate(() => {
      const start = performance.now();
      let _sum = 0;
      for (let i = 0; i < 1000000; i++) _sum += Math.sqrt(i);
      return performance.now() - start;
    });

    // 3. Check the cryptominer toggle
    await page.check('#toggleCryptominer');

    // 4. Wait 3s (miner starts immediately, need time for beacon)
    await page.waitForTimeout(3000);

    // Measure CPU after miner is running
    const cpuAfter = await page.evaluate(() => {
      const start = performance.now();
      let _sum = 0;
      for (let i = 0; i < 1000000; i++) _sum += Math.sqrt(i);
      return performance.now() - start;
    });

    // 5. Fetch exfil log, filter for type=cryptominer
    const res = await fetch(`${BASE_URL}/csd-demo/exfil/log`);
    const log = await res.json();
    const minerEntries = log.filter((e) => e.attack_type === 'cryptominer');

    // 6. Verify mining beacon was sent
    if (minerEntries.length === 0) {
      console.log('FAIL: No cryptominer exfiltration entries found in log');
      process.exit(1);
    }

    console.log(`Captured ${minerEntries.length} cryptominer entries`);
    console.log('Mining beacon data:', JSON.stringify(minerEntries[0].data || minerEntries[0], null, 2));

    // 7. CPU impact measurement
    const cpuImpact = (((cpuAfter - cpuBefore) / cpuBefore) * 100).toFixed(1);
    console.log(`CPU impact measurement:`);
    console.log(`  - Baseline: ${cpuBefore.toFixed(2)}ms`);
    console.log(`  - With miner: ${cpuAfter.toFixed(2)}ms`);
    console.log(`  - Impact: ${cpuImpact}% ${cpuAfter > cpuBefore ? 'slower' : 'faster'}`);

    // 8. Print PASS/FAIL
    console.log('PASS: Cryptominer beacon detected');
    console.log(`  - Beacon entries: ${minerEntries.length}`);

    await browser.close();
    fs.rmSync(PROFILE_DIR, { recursive: true, force: true });
  } catch (err) {
    console.error('FAIL: Unexpected error:', err.message);
    if (browser) await browser.close();
    fs.rmSync(PROFILE_DIR, { recursive: true, force: true });
    process.exit(1);
  }
})();
