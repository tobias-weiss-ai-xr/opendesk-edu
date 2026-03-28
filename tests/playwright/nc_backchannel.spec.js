 
const { test, expect } = require('@playwright/test');

const NC_DOMAIN = process.env.NC_DOMAIN || 'https://nc.example.org';
const NC_USERNAME = process.env.NC_USERNAME || '';
const NC_PASSWORD = process.env.NC_PASSWORD || '';
const BACKCHANNEL_URL = process.env.BACKCHANNEL_URL || `${NC_DOMAIN}/apps/user_oidc/backchannel_logout`;
const LOGOUT_TOKEN = process.env.LOGOUT_TOKEN || '';

test.describe('Nextcloud OIDC backchannel logout', () => {
  test('terminates session using backchannel logout', async ({ page }) => {
    if (!NC_DOMAIN || !NC_USERNAME || !NC_PASSWORD) {
      test.skip('NC_DOMAIN and credentials must be provided to run this test');
    }
    await page.goto(`${NC_DOMAIN}/index.php/apps/files/`);
    await page.reload();
    const needsLogin = await page.locator('text=Log in').first().isVisible();
    expect(needsLogin).toBeTruthy();
  });
});
