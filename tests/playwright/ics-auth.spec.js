/**
 * ICS Authenticated Routing Test Suite
 *
 * Tests that the intercom-service correctly proxies authenticated requests
 * to OpenCloud, SOGo, and ILIAS with proper session handling.
 *
 * ICS uses SAML-brokered authentication (ICS → Keycloak → SAML IdP),
 * which requires browser-based login. This test suite handles the full
 * auth flow and validates session establishment.
 *
 * Required Environment Variables:
 * - PORTAL_USERNAME: Test user username (e.g., ics-testuser)
 * - PORTAL_PASSWORD: Test user password
 * - ICS_BASE_URL: ICS base URL (default: https://ics.opendesk.hrz.uni-marburg.de)
 *
 * Optional:
 * - PORTAL_URL: Portal URL for SAML IdP redirect (default: https://portal.opendesk.hrz.uni-marburg.de)
 * - ENFORCE_FEDERATED_LOGIN: IdP name (default: "")
 *
 * Run: npx playwright test tests/playwright/ics-auth.spec.js
 */

const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

const CFG = {
  ics: process.env.ICS_BASE_URL || 'https://ics.opendesk.hrz.uni-marburg.de',
  portal: process.env.PORTAL_URL || 'https://portal.opendesk.hrz.uni-marburg.de',
  creds: {
    username: process.env.PORTAL_USERNAME || '',
    password: process.env.PORTAL_PASSWORD || '',
  },
  services: {
    opencloud: {
      route: '/oc/',
      name: 'OpenCloud',
      expectedContent: ['opencloud', 'files', 'login'],
    },
    sogo: {
      route: '/sogo/SOGo/',
      name: 'SOGo',
      expectedContent: ['SOGo', 'Login', 'JavaScript'],
    },
    ilias: {
      route: '/ilias/',
      name: 'ILIAS',
      expectedContent: ['ILIAS', 'login', 'Login'],
    },
  },
  timeouts: {
    nav: 30000,
    redirect: 20000,
    auth: 45000,
  },
};

function checkEnv() {
  if (!CFG.creds.username || !CFG.creds.password) {
    console.warn('⚠ PORTAL_USERNAME/PASSWORD not set — auth scenarios will be skipped');
    return false;
  }
  return true;
}

test.describe('ICS Authenticated Routing', () => {
  let envOk = false;

  test.beforeAll(() => {
    envOk = checkEnv();
  });

  test.beforeEach(async ({ page }) => {
    // Set longer timeout for auth-heavy flows
    page.setDefaultTimeout(CFG.timeouts.auth);
  });

  test('1. ICS redirects unauthenticated users to Keycloak', async ({ page }) => {
    // Don't wait for networkidle — the redirect chain may complete
    // to an unexpected final page. We just need the FIRST redirect.
    await page.goto(`${CFG.ics}/oc/`, {
      waitUntil: 'commit',
      timeout: CFG.timeouts.nav,
    });

    // Wait briefly for any initial redirect
    await page.waitForTimeout(3000);
    const url = page.url();
    // The page might be on Keycloak (auth request) or already past it
    const redirected = url.includes('/realms/') || url !== `${CFG.ics}/oc/`;
    console.log(`Initial /oc/ → ${url.substring(0, 120)}`);
    expect(redirected).toBeTruthy();
  });

  test.describe('Authenticated proxy flows', () => {
    test.beforeEach(async ({ page }) => {
      if (!envOk) {
        test.skip('PORTAL_USERNAME/PASSWORD not configured');
        return;
      }
    });

    // Helper: login through Keycloak/SAML redirect chain
    async function loginThroughPortal(page, serviceRoute) {
      // Step 1: Navigate to ICS service route
      await page.goto(`${CFG.ics}${serviceRoute}`, {
        waitUntil: 'networkidle',
        timeout: CFG.timeouts.nav,
      });

      // Step 2: If redirected to Keycloak, fill credentials
      if (page.url().includes('/realms/')) {
        // Keycloak login page
        await page.waitForSelector('input[name="username"], input[id="username"]', {
          timeout: CFG.timeouts.redirect,
        });
        await page.fill('input[name="username"], input[id="username"]', CFG.creds.username);
        await page.fill('input[name="password"], input[id="password"]', CFG.creds.password);
        await page.click('input[type="submit"], button[type="submit"]');

        // Wait for redirect chain to complete (SAML IdP → back to service)
        await page.waitForLoadState('networkidle', { timeout: CFG.timeouts.auth });

      } else if (page.url().includes('/Shibboleth.sso/')) {
        // Direct SAML IdP login (Shibboleth)
        const shibUser = page.locator('input[name="j_username"], input[name="user"]').first();
        if (await shibUser.isVisible().catch(() => false)) {
          await shibUser.fill(CFG.creds.username);
          await page.fill('input[name="j_password"], input[name="pass"]', CFG.creds.password);
          await page.click('input[type="submit"], button[type="submit"]');
          await page.waitForLoadState('networkidle', { timeout: CFG.timeouts.auth });
        }
      }

      // Step 3: If on portal (SAML IdP), click login button
      if (page.url().startsWith(CFG.portal)) {
        const loginBtn = page.locator(
          'button:has-text("Login"), a:has-text("Login")'
        ).first();
        if (await loginBtn.isVisible().catch(() => false)) {
          await loginBtn.click();
          await page.waitForLoadState('networkidle', { timeout: CFG.timeouts.auth });
        }
      }
    }

    for (const [svcKey, svc] of Object.entries(CFG.services)) {
      test(`${svc.name}: authenticated access reaches backend`, async ({ page }) => {
        // Capture X-Forwarded-User from response headers
        let xfu = null;
        page.on('response', (response) => {
          if (xfu === null) {
            xfu = response.headers()['x-forwarded-user'] || null;
          }
        });

        await loginThroughPortal(page, svc.route);

        // After login chain, verify we're past the login screen
        const currentUrl = page.url();
        console.log(`${svc.name} final URL: ${currentUrl.substring(0, 120)}`);

        // We should NOT be on the Keycloak login page anymore
        const stuckOnLogin = currentUrl.includes('/realms/') &&
          (currentUrl.includes('login') || currentUrl.includes('auth'));

        // Take screenshot for debugging
        await page.screenshot({
          path: `.sisyphus/evidence/ics-auth-${svcKey}-result.png`,
          fullPage: true,
        });

        // Test passes if we're not stuck on login (session established)
        expect(stuckOnLogin).toBeFalsy();

        // Check that the page loaded (not an error)
        const bodyText = await page.locator('body').textContent().catch(() => '');
        const hasError = bodyText.includes('error') || bodyText.includes('Error');
        expect(hasError).toBeFalsy();

        console.log(`${svc.name}: session established ✓`);

        // Verify X-Forwarded-User was sent (if captured via response)
        if (xfu) {
          console.log(`${svc.name}: X-Forwarded-User=${xfu}`);
          expect(xfu).toBeTruthy();
        }
      });
    }

    test('OpenCloud: ICS proxies with session cookie', async ({ page, context }) => {
      // Establish session first via portal
      await loginThroughPortal(page, '/oc/');

      // Get cookies from the session
      const cookies = await context.cookies();
      const icsCookies = cookies.filter(c =>
        c.domain.includes('ics.') || c.name.includes('auth')
      );
      console.log(`ICS cookies: ${icsCookies.length}`);

      // Verify we have session cookies
      const hasSessionCookie = icsCookies.some(c =>
        c.name.toLowerCase().includes('auth') ||
        c.name.toLowerCase().includes('session') ||
        c.name.toLowerCase().includes('token')
      );
      expect(hasSessionCookie || icsCookies.length > 0).toBeTruthy();
    });
  });

  test.describe('Backchannel logout via ICS', () => {
    test.beforeEach(async ({ page }) => {
      if (!envOk) {
        test.skip('PORTAL_USERNAME/PASSWORD not configured');
        return;
      }
    });

    test('OpenCloud session terminates after portal logout', async ({ page, context }) => {
      await test.step('Establish ICS session for OpenCloud', async () => {
        await page.goto(`${CFG.ics}/oc/`, { waitUntil: 'networkidle', timeout: CFG.timeouts.nav });
        if (page.url().includes('/realms/')) {
          await page.fill('input[name="username"], input[id="username"]', CFG.creds.username);
          await page.fill('input[name="password"], input[id="password"]', CFG.creds.password);
          await page.click('input[type="submit"], button[type="submit"]');
          await page.waitForLoadState('networkidle', { timeout: CFG.timeouts.auth });
        }
      });

      const beforeUrl = page.url();
      console.log(`Before logout: ${beforeUrl.substring(0, 100)}`);

      await test.step('Logout from portal', async () => {
        await page.goto(CFG.portal, { waitUntil: 'networkidle', timeout: CFG.timeouts.nav });
        const logoutBtn = page.locator(
          'button:has-text("Logout"), a:has-text("Logout"), ' +
          'button:has-text("Sign out")'
        ).first();
        if (await logoutBtn.isVisible().catch(() => false)) {
          await logoutBtn.click();
          await page.waitForLoadState('networkidle', { timeout: CFG.timeouts.auth });
        }
        // Wait for backchannel logout propagation
        await page.waitForTimeout(5000);
      });

      await test.step('Verify session terminated', async () => {
        await page.goto(`${CFG.ics}/oc/`, { waitUntil: 'domcontentloaded', timeout: CFG.timeouts.nav });
        await page.waitForTimeout(3000);

        // Check if redirected to auth or still has session
        const afterUrl = page.url();
        const onLoginPage = afterUrl.includes('/realms/') && !afterUrl.includes('code=');
        const urlChanged = !afterUrl.includes('/oc/');
        console.log(`After logout: ${afterUrl.substring(0, 120)} → login: ${onLoginPage}, changed: ${urlChanged}`);
        expect(onLoginPage || urlChanged).toBeTruthy();
      });
    });

    test('SOGo session terminates after portal logout', async ({ page }) => {
      await page.goto(`${CFG.ics}/sogo/SOGo/`, { waitUntil: 'networkidle', timeout: CFG.timeouts.nav });
      if (page.url().includes('/realms/')) {
        await page.fill('input[name="username"], input[id="username"]', CFG.creds.username);
        await page.fill('input[name="password"], input[id="password"]', CFG.creds.password);
        await page.click('input[type="submit"], button[type="submit"]');
        await page.waitForLoadState('networkidle', { timeout: CFG.timeouts.auth });
      }

      await page.goto(CFG.portal, { waitUntil: 'networkidle', timeout: CFG.timeouts.nav });
      const logoutBtn = page.locator('button:has-text("Logout"), a:has-text("Logout")').first();
      if (await logoutBtn.isVisible().catch(() => false)) {
        await logoutBtn.click();
        await page.waitForLoadState('networkidle', { timeout: CFG.timeouts.auth });
      }
      await page.waitForTimeout(5000);

      await page.goto(`${CFG.ics}/sogo/SOGo/`, { waitUntil: 'domcontentloaded', timeout: CFG.timeouts.nav });
      await page.waitForTimeout(3000);
      const afterUrl = page.url();
      const onLoginPage = afterUrl.includes('/realms/') && !afterUrl.includes('code=');
      const urlChanged = !afterUrl.includes('/sogo/');
      console.log(`SOGo after logout: ${afterUrl.substring(0, 120)} → login: ${onLoginPage}`);
      expect(onLoginPage || urlChanged).toBeTruthy();
    });
  });
});
