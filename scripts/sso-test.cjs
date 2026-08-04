#!/usr/bin/env node
// SPDX-FileCopyrightText: 2026 OpenDesk Edu Team
// SPDX-License-Identifier: Apache-2.0
//
// SSO Browser Test for OpenDesk Edu
//
// Verifies the SSO login redirect chain:
//   1. Navigate to an OIDC-protected app (Open WebUI)
//   2. Check SSO button is present
//   3. Click SSO button
//   4. Verify redirect through Keycloak to the university Shibboleth IdP
//
// Usage:
//   node scripts/sso-test.cjs
//   SSO_APP_URL=https://ai.opendesk.hrz.uni-marburg.de node scripts/sso-test.cjs
//
// Requires: playwright (npm install -g playwright)
//
// Returns: 0 = SSO chain verified, 1 = test failed

const { chromium } = require('playwright');

const APP_URL = process.env.SSO_APP_URL || 'https://ai.opendesk.hrz.uni-marburg.de';
const SSO_TEXT = process.env.SSO_TEXT || 'Keycloak';
const IDP_DOMAIN = process.env.IDP_DOMAIN || 'weblogin.uni-marburg.de';

let passed = 0;
let failed = 0;

function check(name, ok) {
  const mark = ok ? 'PASS' : 'FAIL';
  console.log(`  [${mark}] ${name}`);
  if (ok) passed++; else failed++;
}

(async () => {
  console.log('==============================================');
  console.log(' OpenDesk Edu SSO Browser Test');
  console.log(` App: ${APP_URL}`);
  console.log(` IdP: ${IDP_DOMAIN}`);
  console.log('==============================================\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();

  try {
    // Step 1: Load the app
    console.log('--- Step 1: App loads ---');
    await page.goto(APP_URL, { waitUntil: 'networkidle', timeout: 45000 });
    const title = await page.title();
    check(`App loads with title "${title}"`, title.length > 0);

    // Step 2: SSO button is visible
    console.log('\n--- Step 2: SSO button present ---');
    const ssoBtn = page.locator('button').filter({ hasText: SSO_TEXT });
    await ssoBtn.waitFor({ state: 'visible', timeout: 15000 });
    check(`SSO button "${SSO_TEXT}" visible`, await ssoBtn.isVisible());

    // Step 3: Verify we're on an auth page
    console.log('\n--- Step 3: Auth page context ---');
    const preUrl = page.url();
    check(`Page URL contains /auth (${preUrl})`, preUrl.includes('/auth'));

    // Step 4: Click SSO and follow redirect
    console.log('\n--- Step 4: Click SSO & follow redirect ---');
    await ssoBtn.evaluate(el => el.dispatchEvent(new MouseEvent('click', { bubbles: true })));
    // Wait for redirect chain: Open WebUI -> Keycloak -> Shibboleth IdP
    await page.waitForTimeout(2000);
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(5000);

    const finalUrl = page.url();
    console.log(`  Final URL: ${finalUrl}`);

    // Step 5: Verify we reached an external IdP
    console.log('\n--- Step 5: IdP reachability ---');
    const atIdp = finalUrl.includes(IDP_DOMAIN);
    const atKeycloak = finalUrl.includes('/auth/realms/') || finalUrl.includes('opendesk');
    check(`Redirected to IdP domain "${IDP_DOMAIN}"`, atIdp);
    if (!atIdp) {
      console.log(`  NOTE: Redirect ended at unexpected domain.` +
        ` This is OK if SSO config changed.`);
    }

    // Step 6: IdP login form is rendered
    console.log('\n--- Step 6: Login page rendered ---');
    const bodyText = await page.locator('body').innerText().catch(() => '');
    const hasForm = /passwort|password|anmelden|login|benutzername|username/i.test(bodyText);
    check('Login page form detected on IdP', hasForm && atIdp);
    if (!hasForm && !atIdp) {
      // If we didn't reach the IdP, save debug info
      console.log(`  DEBUG body text (first 200 chars): ${bodyText.slice(0, 200)}`);
    }

  } catch (err) {
    console.log(`\n  [ERROR] ${err.message}`);
    failed++;
  } finally {
    await browser.close();
  }

  // Summary
  console.log(`\n==============================================`);
  console.log(` Results: ${passed}/${passed + failed} passed, ${failed} failed`);
  console.log(`==============================================`);
  process.exit(failed > 0 ? 1 : 0);
})();
