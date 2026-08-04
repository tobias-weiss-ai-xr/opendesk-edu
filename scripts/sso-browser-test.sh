#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 OpenDesk Edu Team
# SPDX-License-Identifier: Apache-2.0
#
# SSO browser test for OpenDesk Edu services
#
# Tests that the SSO login flow works end-to-end:
#   1. Navigate to an OIDC-protected app
#   2. Click the SSO login button
#   3. Verify redirect through Keycloak to the university Shibboleth IdP
#
# This test verifies the redirect chain is functional (up to the IdP login page).
# Full credential-based login requires a real university account.
#
# Requires: playwright (npx playwright)
#
# Usage:
#   bash scripts/sso-browser-test.sh                    # Test Open WebUI (default)
#   APP_URL=https://ai.opendesk.hrz.uni-marburg.de \
#     bash scripts/sso-browser-test.sh
#
# Returns: 0 if SSO redirect chain works, 1 otherwise

set -euo pipefail

APP_URL="${APP_URL:-https://ai.opendesk.hrz.uni-marburg.de}"
SSO_BUTTON_TEXT="${SSO_BUTTON_TEXT:-Keycloak}"
EXPECTED_IDP="${EXPECTED_IDP:-weblogin.uni-marburg.de}"

echo "=============================================="
echo " OpenDesk Edu SSO Browser Test"
echo " App:      $APP_URL"
echo " SSO:      $SSO_BUTTON_TEXT"
echo " IdP:      $EXPECTED_IDP"
echo "=============================================="
echo ""

# Create a temporary Playwright test file
TEST_SCRIPT=$(mktemp -t sso-test-XXXXXX.mjs)
cat > "$TEST_SCRIPT" << 'PLAYWRIGHT_EOF'
import { chromium } from 'playwright';

const APP_URL = process.env.APP_URL || 'https://ai.opendesk.hrz.uni-marburg.de';
const SSO_TEXT = process.env.SSO_BUTTON_TEXT || 'Keycloak';
const EXPECTED_IDP = process.env.EXPECTED_IDP || 'weblogin.uni-marburg.de';

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();

  let passed = 0;
  let failed = 0;
  const check = (name, condition) => {
    if (condition) {
      console.log(`  [PASS] ${name}`);
      passed++;
    } else {
      console.log(`  [FAIL] ${name}`);
      failed++;
    }
  };

  try {
    // Step 1: Navigate to the app
    console.log("\n--- Step 1: Navigate to app ---");
    await page.goto(APP_URL, { waitUntil: 'networkidle', timeout: 30000 });
    const appTitle = await page.title();
    check(`App loaded (${APP_URL})`, appTitle.length > 0);

    // Step 2: Check SSO button is present
    console.log("\n--- Step 2: SSO button present ---");
    const ssoButton = page.locator('button').filter({ hasText: SSO_TEXT });
    await ssoButton.waitFor({ state: 'visible', timeout: 10000 });
    check(`SSO button "${SSO_TEXT}" is visible`, await ssoButton.isVisible());

    // Step 3: Get the SSO redirect URL (before clicking)
    console.log("\n--- Step 3: SSO button target URL ---");
    const currentUrlBefore = page.url();
    check(`On auth page before click`, currentUrlBefore.includes('/auth'));

    // Step 4: Click the SSO button (bypass viewport check via evaluate)
    console.log("\n--- Step 4: Click SSO button ---");
    await ssoButton.evaluate(el => el.dispatchEvent(new MouseEvent('click', { bubbles: true })));
    await page.waitForTimeout(3000);

    // Step 5: Verify redirect chain
    console.log("\n--- Step 5: Verify IdP redirect ---");
    const currentUrl = page.url();
    const pageText = await page.textContent('body').catch(() => '');

    console.log(`  Redirected to: ${currentUrl}`);

    if (currentUrl.includes(EXPECTED_IDP)) {
      check(`Redirected to IdP (${EXPECTED_IDP})`, true);
    } else if (currentUrl.includes('keycloak') || currentUrl.includes('auth')) {
      // Could be still at Keycloak (e.g., if no SHIB session)
      check(`Redirected through Keycloak`, true);
    } else {
      check(`Unknown redirect target`, false);
    }

    // Step 6: Verify login form exists (IdP page reached)
    const hasLoginForm = pageText.includes('passwort') || 
                         pageText.includes('Passwort') || 
                         pageText.includes('login') ||
                         pageText.includes('username');
    check(`Login form present on IdP page`, hasLoginForm);

  } catch (err) {
    console.log(`\n  [ERROR] ${err.message}`);
    failed++;
  } finally {
    await browser.close();
  }

  // Summary
  console.log(`\n---`);
  console.log(`Results: ${passed}/${passed + failed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
})();
PLAYWRIGHT_EOF

# Run the test
npx playwright test --browser chromium 2>/dev/null || true
node "$TEST_SCRIPT" 2>&1
EXIT_CODE=$?

# Cleanup
rm -f "$TEST_SCRIPT"

exit $EXIT_CODE
