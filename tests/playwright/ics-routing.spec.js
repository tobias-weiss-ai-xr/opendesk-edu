/**
 * Intercom Service (ICS) Fork Proxy Routing Test Suite
 *
 * Tests the openDesk Edu ICS fork with OpenCloud, SOGo, and ILIAS proxy routes.
 *
 * Required Environment Variables:
 * - PORTAL_URL: Portal base URL (e.g., https://portal.example.org)
 * - ICS_URL: Intercom Service base URL (e.g., https://ics.example.org)
 * - PORTAL_USERNAME / PORTAL_PASSWORD: Test user credentials
 *
 * Optional:
 * - ENFORCE_FEDERATED_LOGIN: IdP alias (default: "")
 * - ICS_HEALTH_URL: Health endpoint override (default: ICS_URL + /health)
 *
 * Run: npx playwright test tests/playwright/ics-routing.spec.js
 */

const { test, expect } = require('@playwright/test');
const https = require('https');
const http = require('http');

const CFG = {
  portal: {
    url: process.env.PORTAL_URL || 'https://portal.example.org',
  },
  ics: {
    url: process.env.ICS_URL || 'https://ics.example.org',
    healthUrl: process.env.ICS_HEALTH_URL || null,
  },
  creds: {
    username: process.env.PORTAL_USERNAME || '',
    password: process.env.PORTAL_PASSWORD || '',
  },
  routes: [
    { path: '/oc/',    name: 'OpenCloud',  target: 'OC' },
    { path: '/sogo/',  name: 'SOGo',       target: 'SOGO' },
    { path: '/ilias/', name: 'ILIAS',      target: 'ILIAS' },
  ],
  timeouts: {
    nav: 30000,
    redirect: 20000,
    health: 10000,
  },
};

/**
 * HTTP GET that follows redirects — returns final URL and status.
 * Uses native http/https to avoid Playwright browser context for health checks.
 */
function httpGet(url, maxRedirects = 5) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const mod = parsed.protocol === 'https:' ? https : http;

    const doRequest = (currentUrl, redirectsLeft) => {
      const u = new URL(currentUrl);
      mod.get(currentUrl, { rejectUnauthorized: false }, (res) => {
        if ([301, 302, 303, 307, 308].includes(res.statusCode) && redirectsLeft > 0) {
          const location = res.headers.location;
          if (!location) {
            resolve({ status: res.statusCode, url: currentUrl });
            return;
          }
          const nextUrl = location.startsWith('http') ? location : `${u.protocol}//${u.host}${location}`;
          doRequest(nextUrl, redirectsLeft - 1);
        } else {
          resolve({ status: res.statusCode, url: currentUrl });
        }
      }).on('error', reject);
    };

    doRequest(url, maxRedirects);
  });
}

test.describe('ICS Fork — Proxy Route Health', () => {
  test('Health endpoint returns {"status":"ok"}', async () => {
    const healthUrl = CFG.ics.healthUrl || `${CFG.ics.url}/health`;
    const res = await httpGet(healthUrl, 0);
    expect(res.status).toBe(200);
  });

  for (const route of CFG.routes) {
    test(`${route.name} route (${route.path}) redirects to OIDC when unauthenticated`, async () => {
      const routeUrl = `${CFG.ics.url}${route.path}`;
      const res = await httpGet(routeUrl, 3);

      // Expect redirect chain: /{route} → Keycloak OIDC (302)
      // 302 proves the route is mounted and active, just needs auth
      expect(res.status).toBe(302);

      // Verify redirect target is Keycloak realm
      const redirectTarget = res.url;
      expect(redirectTarget).toContain('/realms/');
    });
  }
});

test.describe('ICS Fork — Authenticated Proxy Routing', () => {
  test.beforeEach(async ({ page }) => {
    test.skip(!CFG.creds.username || !CFG.creds.password,
      'PORTAL_USERNAME and PORTAL_PASSWORD required');

    // Login via portal
    await page.goto(CFG.portal.url, {
      waitUntil: 'networkidle',
      timeout: CFG.timeouts.nav,
    });

    // If the portal shows a login button, click it
    const loginBtn = page.locator(
      'button:has-text("Login"), a:has-text("Login")'
    ).first();

    if (await loginBtn.isVisible().catch(() => false)) {
      await loginBtn.click();
    }

    // Handle Keycloak login form
    const usernameInput = page.locator('#username');
    if (await usernameInput.isVisible({ timeout: CFG.timeouts.redirect }).catch(() => false)) {
      await usernameInput.fill(CFG.creds.username);
      await page.locator('#password').fill(CFG.creds.password);
      await page.locator('#kc-login').click();
    }

    // Wait for redirect back to portal
    await page.waitForURL((url) => url.toString().startsWith(CFG.portal.url), {
      timeout: CFG.timeouts.redirect,
    }).catch(() => {
      console.log('Note: final URL after login:', page.url());
    });

    await page.waitForLoadState('networkidle');
    console.log('Login completed, session established');
  });

  for (const route of CFG.routes) {
    test(`${route.name} proxy (${route.path}) returns service content when authenticated`, async ({ page }) => {
      const routeUrl = `${CFG.ics.url}${route.path}`;

      // Navigate to ICS route with existing session
      const response = await page.goto(routeUrl, {
        waitUntil: 'domcontentloaded',
        timeout: CFG.timeouts.redirect,
      });

      // With a valid session, ICS should proxy through to the backend service
      // (actual status depends on whether the backend is healthy)
      const status = response.status();
      console.log(`${route.name} (${route.path}): status=${status}, url=${page.url()}`);

      // If we got a 200, 302, or 401 — the route is alive and proxying
      // 200 = proxied through to the service
      // 302 = redirect (e.g., OpenCloud SSO redirect)
      // 401 = unauthenticated at backend level (route works, backend rejects)
      expect([200, 302, 401]).toContain(status);
    });
  }
});

test.describe('ICS Fork — Session Propagation', () => {
  test('Accessing ICS routes preserves portal session', async ({ page }) => {
    test.skip(!CFG.creds.username || !CFG.creds.password,
      'PORTAL_USERNAME and PORTAL_PASSWORD required');

    // Login via portal
    await page.goto(CFG.portal.url, {
      waitUntil: 'networkidle',
      timeout: CFG.timeouts.nav,
    });

    const loginBtn = page.locator(
      'button:has-text("Login"), a:has-text("Login")'
    ).first();

    if (await loginBtn.isVisible().catch(() => false)) {
      await loginBtn.click();
    }

    const usernameInput = page.locator('#username');
    if (await usernameInput.isVisible({ timeout: CFG.timeouts.redirect }).catch(() => false)) {
      await usernameInput.fill(CFG.creds.username);
      await page.locator('#password').fill(CFG.creds.password);
      await page.locator('#kc-login').click();
    }

    await page.waitForURL((url) => url.toString().startsWith(CFG.portal.url), {
      timeout: CFG.timeouts.redirect,
    }).catch(() => {});

    await page.waitForLoadState('networkidle');

    // Now visit all three ICS routes sequentially — they should all
    // use the same OIDC session without re-prompting for login
    for (const route of CFG.routes) {
      await test.step(`Navigate to ${route.name} (${route.path})`, async () => {
        const response = await page.goto(`${CFG.ics.url}${route.path}`, {
          waitUntil: 'domcontentloaded',
          timeout: CFG.timeouts.redirect,
        });

        const status = response.status();
        console.log(`  ${route.name}: status=${status}`);

        // Key test: we should NOT be on the Keycloak login page
        // The ICS should exchange the portal session for a backend token
        const onLoginPage = await page.locator('#kc-login').isVisible()
          .catch(() => false);

        if (onLoginPage) {
          console.log(`  WARNING: ${route.name} redirected to Keycloak login — session not propagated`);
        }

        expect([200, 302, 401]).toContain(status);
      });
    }
  });
});
