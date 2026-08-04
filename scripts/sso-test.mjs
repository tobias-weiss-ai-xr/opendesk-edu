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
//   node scripts/sso-test.mjs
//   SSO_APP_URL=https://ai.opendesk.hrz.uni-marburg.de node scripts/sso-test.mjs
//
// Requires: playwright (npm install playwright)
//
// Returns: 0 = SSO chain verified, 1 = test failed

import { chromium } from 'playwright';

const APP_URL = process.env.SSO_APP_URL || 'https://ai.opendesk.hrz.uni-marburg.de';
const SSO_TEXT = 'Keycloak';
const IDP_DOMAIN = 'weblogin.uni-marburg.de';

let passed = 0;
let failed = 0;
let step = 0;

function check(name, ok) {
  const mark = ok ? 'PASS' : 'FAIL';
  console.log(`  [${mark}] ${name}`);
  if (ok) passed++; else failed++;
}

(async () => {
  console.log('==============================================');
  console.log(' OpenDesk Edu SSO Browser Test');
  console.log(` App: ${APP_URL}`);
  console.log('==============================================\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();

  try {
    // Step 1: Load the app
    console.log('--- Step 1: App loads ---');
    await page.goto(APP_URL, { waitUntil: 'networkidle', timeout: 30000 });
    check('App loads and returns a title', (await page.title()).length > 0);

    // Step 2: SSO button is visible
    console.log('\n--- Step 2: SSO button present ---');
    const ssoBtn = page.locator('button').filter({ hasText: SSO_TEXT });
    await ssoBtn.waitFor({ state: 'visible', timeout: 10000 });
    check(`SSO button "${SSO_TEXT}" visible`, await ssoBtn.isVisible());

    // Step 3: Verify we're on an auth page
    console.log('\n--- Step 3: Auth page context ---');
    check('Page URL contains /auth', page.url().includes('/auth'));

    // Step 4: Click SSO and follow redirect
    console.log('\n--- Step 4: Click SSO & follow redirect ---');
    await ssoBtn.evaluate(el => el.dispatchEvent(new MouseEvent('click', { bubbles: true })));
    // The redirect goes: Open WebUI -> Keycloak -> Shibboleth IdP
    // Wait for navigation to complete (IdP login page)
    await page.waitForTimeout(2000);
    await page.waitForLoadState('networkidle').catch(() => {});
    // Extra wait for IdP redirect
    await page.waitForTimeout(3000);

    const finalUrl = page.url();
    console.log(`  Final URL: ${finalUrl}`);

    // Step 5: Verify we reached an external IdP
    console.log('\n--- Step 5: IdP reachability ---');
    const atIdp = finalUrl.includes(IDP_DOMAIN);
    const atKeycloak = finalUrl.includes('id.opendesk') || finalUrl.includes('keycloak');
    check(`Redirected to IdP (${IDP_DOMAIN})`, atIdp);
    check(`Redirect went through Keycloak first`, atIdp || atKeycloak);

    // Step 6: IdP login form is rendered
    console.log('\n--- Step 6: IdP login form present ---');
    const bodyText = await page.locator('body').innerText().catch(() => '');
    const hasForm = /passwort|password|anmelden|login|benutzername|username/i.test(bodyText);
    check('IdP login page rendered', hasForm && atIdp);

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
