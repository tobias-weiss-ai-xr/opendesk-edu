// openDesk E2E Tests - Layer 4

const { test, expect } = require('@playwright/test');

test.describe('Critical User Journeys', () => {
  
  test('OpenCloud OIDC Login', async ({ page, context }) => {
    await page.goto('https://opencloud.opendesk.hrz.uni-marburg.de/');
    
    await expect(page).toHaveURL(/id\.opendesk\.hrz\.uni-marburg\.de/);
    
    await expect(page.locator('html')).toContainText('Sign in');
  });

  test('Nextcloud OIDC Login', async ({ page }) => {
    const response = await page.goto('https://files.opendesk.hrz.uni-marburg.de/');
    expect(response?.status()).toBeLessThan(500);
    
    if (response?.status() === 302) {
      await expect(page).toHaveURL(/id\.opendesk\.hrz\.uni-marburg\.de/);
    }
  });

  test('Keycloak Login Page Renders', async ({ page }) => {
    await page.goto('https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/auth');
    
    await expect(page.locator('#kc-form-login')).toBeVisible();
    await expect(page.locator('input[name="username"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
  });

  test('Portal Navigation Loads', async ({ page }) => {
    await page.goto('https://portal.opendesk.hrz.uni-marburg.de/');
    const response = page.response();
    expect(response?.status()).toBeLessThan(500);
  });

  test('OX App Suite Login', async ({ page }) => {
    await page.goto('https://webmail.opendesk.hrz.uni-marburg.de/');
    
    const response = page.response();
    expect(response?.status()).toBeLessThan(500);
    
    await expect(page.locator('.ox-appsuite')).toBeVisible({ timeout: 5000 }).catch(() => {
      expect(page).toHaveURL(/id\.opendesk\.hrz\.uni-marburg\.de/);
    });
  });

});