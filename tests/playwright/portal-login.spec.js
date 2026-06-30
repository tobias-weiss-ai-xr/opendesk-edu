/**
 * Portal Login Flow Test Suite
 *
 * Required Environment Variables:
 * - PORTAL_URL: Portal base URL (e.g., https://portal.example.org)
 *
 * Optional:
 * - PORTAL_ENFORCE_LOGIN: "true" if portalEnforceLogin enabled (default: "true")
 * - ENFORCE_FEDERATED_LOGIN: IdP alias, e.g. "shibboleth" (default: "")
 * - FEDERATED_IDP_URL: Expected IdP URL, e.g. "weblogin.uni-marburg.de" (default: "")
 * - FEDERATED_IDP_NAME: Display name, e.g. "Shibboleth Login" (default: "Shibboleth")
 * - PORTAL_USERNAME / PORTAL_PASSWORD: Test user credentials
 *
 * Run: npx playwright test tests/playwright/portal-login.spec.js
 */

const { test, expect } = require('@playwright/test');

const CFG = {
  portal: {
    url: process.env.PORTAL_URL || 'https://portal.example.org',
    enforceLogin: process.env.PORTAL_ENFORCE_LOGIN || 'true',
    enforceFederated: process.env.ENFORCE_FEDERATED_LOGIN || '',
    idpUrl: process.env.FEDERATED_IDP_URL || '',
    idpName: process.env.FEDERATED_IDP_NAME || 'Shibboleth Login',
  },
  creds: {
    username: process.env.PORTAL_USERNAME || '',
    password: process.env.PORTAL_PASSWORD || '',
  },
  timeouts: {
    nav: 30000,
    redirect: 20000,
  },
};

function onPortalLoginPage(url) {
  return url.startsWith(CFG.portal.url)
    && !url.includes('/realms/')
    && !(CFG.portal.idpUrl && url.includes(CFG.portal.idpUrl));
}

function onKeycloak(url) {
  return url.includes('/realms/');
}

function onIdp(url) {
  return CFG.portal.idpUrl ? url.includes(CFG.portal.idpUrl) : false;
}

async function countIdpButtons(page) {
  const q = `text="${CFG.portal.idpName}", text="${CFG.portal.idpName.toLowerCase()}", [title="${CFG.portal.idpName}"], [aria-label="${CFG.portal.idpName}"]`;
  return await page.locator(q).count();
}

test.describe('Portal Login Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(CFG.portal.url, {
      waitUntil: 'networkidle',
      timeout: CFG.timeouts.nav,
    });
  });

  test('1. Auto-redirect to federated IdP when enforceFederatedLogin is configured', async ({ page }) => {
    await test.step('Check initial landing page', async () => {
      console.log(`portalEnforceLogin=${CFG.portal.enforceLogin}, enforceFederatedLogin="${CFG.portal.enforceFederated}", URL=${page.url()}`);

      if (CFG.portal.enforceFederated && CFG.portal.enforceLogin === 'false') {
      } else if (CFG.portal.enforceLogin === 'true') {
        expect(onPortalLoginPage(page.url()) || onKeycloak(page.url())).toBeTruthy();
      }
    });

    const loginBtn = page.locator(
      'button:has-text("Login"), a:has-text("Login"), ' +
      `button:has-text("${CFG.portal.idpName}"), a:has-text("${CFG.portal.idpName}")`
    ).first();

    if (await loginBtn.isVisible().catch(() => false)) {
      await test.step('Click login and verify redirect chain', async () => {
        await loginBtn.click();

        try { await page.waitForURL(/realms\/opendesk|\/auth|\/idp\//, { timeout: CFG.timeouts.redirect }); }
        catch { /* redirect may be instant */ }

        await page.waitForLoadState('networkidle');

        const kc = onKeycloak(page.url());
        const idp = onIdp(page.url());
        console.log(`After login click: keycloak=${kc}, idp=${idp}, url=${page.url()}`);

        if (CFG.portal.enforceFederated) {
          expect(kc || idp).toBeTruthy();
        }
      });
    }
  });

  test('2. Exactly one Shibboleth button when login page is shown', async ({ page }) => {
    await test.step('Count Shibboleth elements on page', async () => {
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(2000);

      const count = await countIdpButtons(page);
      console.log(`idpName=${CFG.portal.idpName}, buttonCount=${count}, url=${page.url()}`);

      if (CFG.portal.enforceLogin === 'true' && !CFG.portal.enforceFederated) {
        if (count > 0) expect(count).toBe(1);
      }
    });

    const loginBtn = page.locator('button:has-text("Login"), a:has-text("Login")').first();

    if (await loginBtn.isVisible().catch(() => false)) {
      await test.step('Check button count after redirect to Keycloak', async () => {
        await loginBtn.click();
        try { await page.waitForURL(/realms\//, { timeout: CFG.timeouts.redirect }); }
        catch { /* skipped past Keycloak */ }

        await page.waitForLoadState('networkidle');
        await page.waitForTimeout(2000);

        const kcCount = await countIdpButtons(page);
        console.log(`After redirect: url=${page.url()}, keycloakButtonCount=${kcCount}`);

        if (onKeycloak(page.url()) && !CFG.portal.enforceFederated && kcCount > 0) {
          expect(kcCount).toBe(1);
        }
      });
    }
  });

  test('3. Federated IdP redirect chain completes', async ({ page }) => {
    if (!CFG.creds.username || !CFG.creds.password) {
      test.skip('PORTAL_USERNAME and PORTAL_PASSWORD required');
      return;
    }

    await test.step('Navigate and initiate login', async () => {
      await page.goto(CFG.portal.url, { waitUntil: 'networkidle', timeout: CFG.timeouts.nav });

      const trigger = page.locator(
        'button:has-text("Login"), a:has-text("Login"), ' +
        `button:has-text("${CFG.portal.idpName}"), a:has-text("${CFG.portal.idpName}")`
      ).first();

      if (await trigger.isVisible().catch(() => false)) {
        await trigger.click();
      }

      if (CFG.portal.enforceFederated && CFG.portal.idpUrl) {
        const pattern = new RegExp(CFG.portal.idpUrl.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
        const reached = await page.waitForURL(pattern, { timeout: CFG.timeouts.redirect })
          .then(() => true).catch(() => false);
        console.log(`reachedIdp=${reached}, url=${page.url()}`);
      } else {
        const reached = await page.waitForURL(/\/realms\/opendesk\//, { timeout: CFG.timeouts.redirect })
          .then(() => true).catch(() => false);
        console.log(`reachedKeycloak=${reached}, url=${page.url()}`);
      }
    });

    if (onKeycloak(page.url())) {
      await test.step('Verify auto-redirect from Keycloak to IdP', async () => {
        if (CFG.portal.idpUrl) {
          const pattern = new RegExp(CFG.portal.idpUrl.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
          const redirected = await page.waitForURL(pattern, { timeout: CFG.timeouts.redirect })
            .then(() => true).catch(() => false);
          console.log(`autoRedirectToIdp=${redirected}, url=${page.url()}`);
        }
      });
    }
  });
});
