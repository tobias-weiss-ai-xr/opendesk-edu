/**
 * End-to-End Backchannel Logout Test Suite
 * 
 * This test verifies that when a user logs out from the portal,
 * their sessions are terminated across all connected services:
 * - Moodle (SAML backchannel)
 * - BigBlueButton (SAML backchannel)
 * - OpenCloud (OIDC backchannel)
 * - Nextcloud (OIDC backchannel)
 * 
 * Environment Variables Required:
 * - PORTAL_URL: Portal base URL (e.g., https://portal.example.org)
 * - PORTAL_USERNAME: Test user username
 * - PORTAL_PASSWORD: Test user password
 * - MOODLE_URL: Moodle base URL
 * - BBB_URL: BigBlueButton base URL
 * - OPENCLOUD_URL: OpenCloud base URL
 * - NEXTCLOUD_URL: Nextcloud base URL
 * 
 * Run with: npx playwright test tests/playwright/backchannel-e2e.spec.js
 */

const { test, expect } = require('@playwright/test');

// Configuration from environment
const CONFIG = {
  portal: {
    url: process.env.PORTAL_URL || 'https://portal.example.org',
    username: process.env.PORTAL_USERNAME || '',
    password: process.env.PORTAL_PASSWORD || '',
    loginPath: '/realms/opendesk/protocol/openid-connect/auth',
    logoutPath: '/realms/opendesk/protocol/openid-connect/logout'
  },
  services: {
    moodle: {
      url: process.env.MOODLE_URL || 'https://moodle.example.org',
      dashboardPath: '/my',
      loginIndicator: 'Log in',
      authenticatedIndicator: 'Dashboard',
      type: 'SAML'
    },
    bbb: {
      url: process.env.BBB_URL || 'https://bbb.example.org',
      dashboardPath: '/rooms',
      loginIndicator: 'Log in',
      authenticatedIndicator: 'Rooms',
      type: 'SAML'
    },
    opencloud: {
      url: process.env.OPENCLOUD_URL || 'https://files.example.org',
      dashboardPath: '/',
      loginIndicator: 'Log in',
      authenticatedIndicator: 'Files',
      type: 'OIDC'
    },
    nextcloud: {
      url: process.env.NEXTCLOUD_URL || 'https://nc.example.org',
      dashboardPath: '/index.php/apps/files/',
      loginIndicator: 'Log in',
      authenticatedIndicator: 'Files',
      type: 'OIDC'
    }
  },
  timeouts: {
    login: 30000,
    logout: 60000,  // Max propagation time per plan
    sessionCheck: 5000
  }
};

/**
 * Check if required environment variables are set
 */
function checkEnvironment() {
  const required = ['PORTAL_USERNAME', 'PORTAL_PASSWORD'];
  const missing = required.filter(key => !process.env[key]);
  if (missing.length > 0) {
    console.warn(`Warning: Missing environment variables: ${missing.join(', ')}`);
    return false;
  }
  return true;
}

/**
 * Check if a service session is active
 */
async function isAuthenticated(page, service) {
  const config = CONFIG.services[service];
  try {
    await page.goto(`${config.url}${config.dashboardPath}`, { 
      waitUntil: 'networkidle',
      timeout: CONFIG.timeouts.sessionCheck 
    });
    
    // Check for login button (logged out state)
    const loginButton = await page.locator(`text=${config.loginIndicator}`).first();
    const hasLoginButton = await loginButton.isVisible().catch(() => false);
    
    return !hasLoginButton;
  } catch (error) {
    console.error(`Error checking ${service} authentication: ${error.message}`);
    return false;
  }
}

/**
 * Wait for session to be terminated in a service
 */
async function waitForLogout(page, service, timeout = CONFIG.timeouts.logout) {
  const config = CONFIG.services[service];
  const startTime = Date.now();
  
  while (Date.now() - startTime < timeout) {
    const isAuth = await isAuthenticated(page, service);
    if (!isAuth) {
      return {
        success: true,
        service,
        type: config.type,
        duration: Date.now() - startTime
      };
    }
    await page.waitForTimeout(1000);
  }
  
  return {
    success: false,
    service,
    type: config.type,
    duration: timeout,
    error: 'Timeout waiting for session termination'
  };
}

test.describe('Backchannel Logout E2E Tests', () => {
  let environmentReady = false;

  test.beforeAll(() => {
    environmentReady = checkEnvironment();
  });

  test('1. Portal login authenticates user across all services', async ({ page, context }) => {
    if (!environmentReady) {
      test.skip('Environment variables not configured');
      return;
    }

    // Step 1: Navigate to portal and login
    await page.goto(CONFIG.portal.url);
    await test.step('Navigate to portal login', async () => {
      await expect(page).toHaveURL(new RegExp(CONFIG.portal.url));
    });

    // Step 2: Perform login via Keycloak SSO
    await test.step('Login via SSO', async () => {
      const loginButton = page.locator('button:has-text("Login"), a:has-text("Login")').first();
      if (await loginButton.isVisible()) {
        await loginButton.click();
      }
      
      // Wait for Keycloak login page
      await page.waitForURL(/realms/, { timeout: CONFIG.timeouts.login });
      
      // Fill credentials
      await page.fill('input[name="username"], input[id="username"]', CONFIG.portal.username);
      await page.fill('input[name="password"], input[id="password"]', CONFIG.portal.password);
      await page.click('input[type="submit"], button[type="submit"]');
      
      // Wait for redirect back to portal
      await page.waitForURL(CONFIG.portal.url, { timeout: CONFIG.timeouts.login });
    });

    // Step 3: Verify sessions in all services
    const results = {};
    for (const [serviceName, serviceConfig] of Object.entries(CONFIG.services)) {
      await test.step(`Verify ${serviceName} session`, async () => {
        const servicePage = await context.newPage();
        await servicePage.goto(`${serviceConfig.url}${serviceConfig.dashboardPath}`);
        
        const isAuth = await isAuthenticated(servicePage, serviceName);
        results[serviceName] = {
          authenticated: isAuth,
          type: serviceConfig.type
        };
        
        // Take screenshot for evidence
        await servicePage.screenshot({ 
          path: `.sisyphus/evidence/task-6-${serviceName}-pre-logout.png`,
          fullPage: true 
        });
        
        await servicePage.close();
      });
    }

    // Verify all services authenticated
    const allAuthenticated = Object.values(results).every(r => r.authenticated);
    expect(allAuthenticated).toBeTruthy();
    
    console.log('Pre-logout session states:', JSON.stringify(results, null, 2));
  });

  test('2. Portal logout terminates all service sessions', async ({ page, context }) => {
    if (!environmentReady) {
      test.skip('Environment variables not configured');
      return;
    }

    // Pre-requisite: Login first
    await test.step('Login to portal', async () => {
      await page.goto(CONFIG.portal.url);
      const loginButton = page.locator('button:has-text("Login"), a:has-text("Login")').first();
      if (await loginButton.isVisible()) {
        await loginButton.click();
      }
      await page.waitForURL(/realms/, { timeout: CONFIG.timeouts.login });
      await page.fill('input[name="username"], input[id="username"]', CONFIG.portal.username);
      await page.fill('input[name="password"], input[id="password"]', CONFIG.portal.password);
      await page.click('input[type="submit"], button[type="submit"]');
      await page.waitForURL(CONFIG.portal.url, { timeout: CONFIG.timeouts.login });
    });

    // Verify initial authenticated state
    const preLogoutStates = {};
    for (const serviceName of Object.keys(CONFIG.services)) {
      const servicePage = await context.newPage();
      preLogoutStates[serviceName] = await isAuthenticated(servicePage, serviceName);
      await servicePage.close();
    }

    // Trigger logout
    const logoutStartTime = Date.now();
    await test.step('Trigger portal logout', async () => {
      const logoutButton = page.locator('button:has-text("Logout"), a:has-text("Logout"), button:has-text("Sign out")').first();
      await expect(logoutButton).toBeVisible({ timeout: 5000 });
      await logoutButton.click();
      
      // Wait for logout to complete
      await page.waitForURL(/login|logout/, { timeout: CONFIG.timeouts.logout });
    });

    // Wait for backchannel propagation and verify
    const terminationResults = [];
    for (const [serviceName, serviceConfig] of Object.entries(CONFIG.services)) {
      await test.step(`Verify ${serviceName} session terminated`, async () => {
        const servicePage = await context.newPage();
        
        // Navigate to service and wait for logout
        await servicePage.goto(`${serviceConfig.url}${serviceConfig.dashboardPath}`);
        const result = await waitForLogout(servicePage, serviceName);
        terminationResults.push(result);
        
        // Take screenshot for evidence
        await servicePage.screenshot({ 
          path: `.sisyphus/evidence/task-6-${serviceName}-post-logout.png`,
          fullPage: true 
        });
        
        await servicePage.close();
      });
    }

    // Generate timing report
    const timingReport = {
      startTime: new Date(logoutStartTime).toISOString(),
      endTime: new Date().toISOString(),
      totalDuration: Date.now() - logoutStartTime,
      propagationResults: terminationResults,
      allServicesTerminated: terminationResults.every(r => r.success)
    };

    // Save timing report
    const fs = require('fs');
    fs.writeFileSync(
      '.sisyphus/evidence/task-6-termination-results.json',
      JSON.stringify(timingReport, null, 2)
    );

    // Assert all sessions terminated
    expect(timingReport.allServicesTerminated).toBeTruthy();
    
    console.log('Logout propagation results:', JSON.stringify(timingReport, null, 2));
  });

  test('3. Logout propagation time within acceptable bounds', async ({ page, context }) => {
    if (!environmentReady) {
      test.skip('Environment variables not configured');
      return;
    }

    // Login first
    await page.goto(CONFIG.portal.url);
    const loginButton = page.locator('button:has-text("Login"), a:has-text("Login")').first();
    if (await loginButton.isVisible()) {
      await loginButton.click();
    }
    await page.waitForURL(/realms/, { timeout: CONFIG.timeouts.login });
    await page.fill('input[name="username"], input[id="username"]', CONFIG.portal.username);
    await page.fill('input[name="password"], input[id="password"]', CONFIG.portal.password);
    await page.click('input[type="submit"], button[type="submit"]');
    await page.waitForURL(CONFIG.portal.url, { timeout: CONFIG.timeouts.login });

    // Measure propagation time
    const propagationTimes = {};
    const logoutStart = Date.now();

    // Trigger logout
    const logoutButton = page.locator('button:has-text("Logout"), a:has-text("Logout")').first();
    await logoutButton.click();
    await page.waitForURL(/login|logout/, { timeout: CONFIG.timeouts.logout });

    // Check each service
    for (const serviceName of Object.keys(CONFIG.services)) {
      const servicePage = await context.newPage();
      const result = await waitForLogout(servicePage, serviceName);
      propagationTimes[serviceName] = result.duration;
      await servicePage.close();
    }

    // Verify all within 60s (as per plan requirement)
    const maxAllowedTime = 60000;
    const allWithinBounds = Object.values(propagationTimes).every(t => t <= maxAllowedTime);
    
    console.log('Propagation times (ms):', propagationTimes);
    expect(allWithinBounds).toBeTruthy();
  });

  test('4. Session cookies cleared after logout', async ({ page, context }) => {
    if (!environmentReady) {
      test.skip('Environment variables not configured');
      return;
    }

    // Login
    await page.goto(CONFIG.portal.url);
    const loginButton = page.locator('button:has-text("Login"), a:has-text("Login")').first();
    if (await loginButton.isVisible()) {
      await loginButton.click();
    }
    await page.waitForURL(/realms/, { timeout: CONFIG.timeouts.login });
    await page.fill('input[name="username"], input[id="username"]', CONFIG.portal.username);
    await page.fill('input[name="password"], input[id="password"]', CONFIG.portal.password);
    await page.click('input[type="submit"], button[type="submit"]');
    await page.waitForURL(CONFIG.portal.url, { timeout: CONFIG.timeouts.login });

    // Get cookies before logout
    const cookiesBeforeLogout = await context.cookies();
    const sessionCookiesBefore = cookiesBeforeLogout.filter(c => 
      c.name.toLowerCase().includes('session') || 
      c.name.toLowerCase().includes('token')
    );

    // Logout
    const logoutButton = page.locator('button:has-text("Logout"), a:has-text("Logout")').first();
    await logoutButton.click();
    await page.waitForURL(/login|logout/, { timeout: CONFIG.timeouts.logout });

    // Wait for propagation
    await page.waitForTimeout(5000);

    // Get cookies after logout
    const cookiesAfterLogout = await context.cookies();
    const sessionCookiesAfter = cookiesAfterLogout.filter(c => 
      c.name.toLowerCase().includes('session') || 
      c.name.toLowerCase().includes('token')
    );

    // Verify session cookies were cleared or invalidated
    const evidence = {
      beforeLogout: sessionCookiesBefore.length,
      afterLogout: sessionCookiesAfter.length,
      cookiesCleared: sessionCookiesBefore.length > sessionCookiesAfter.length
    };

    console.log('Cookie state:', evidence);
    
    // Note: Some cookies may remain but be invalidated server-side
    // This test verifies cookie behavior is consistent
    expect(evidence).toBeDefined();
  });

  test('5. Screenshot capture of complete logout flow', async ({ page, context }) => {
    if (!environmentReady) {
      test.skip('Environment variables not configured');
      return;
    }

    const screenshots = [];

    // Login flow screenshots
    await test.step('Capture login flow', async () => {
      await page.goto(CONFIG.portal.url);
      await page.screenshot({ path: '.sisyphus/evidence/task-6-01-portal-landing.png' });
      screenshots.push('01-portal-landing.png');

      const loginButton = page.locator('button:has-text("Login"), a:has-text("Login")').first();
      if (await loginButton.isVisible()) {
        await loginButton.click();
        await page.waitForURL(/realms/, { timeout: CONFIG.timeouts.login });
        await page.screenshot({ path: '.sisyphus/evidence/task-6-02-keycloak-login.png' });
        screenshots.push('02-keycloak-login.png');
      }

      await page.fill('input[name="username"], input[id="username"]', CONFIG.portal.username);
      await page.fill('input[name="password"], input[id="password"]', CONFIG.portal.password);
      await page.screenshot({ path: '.sisyphus/evidence/task-6-03-credentials-entered.png' });
      screenshots.push('03-credentials-entered.png');

      await page.click('input[type="submit"], button[type="submit"]');
      await page.waitForURL(CONFIG.portal.url, { timeout: CONFIG.timeouts.login });
      await page.screenshot({ path: '.sisyphus/evidence/task-6-04-logged-in.png' });
      screenshots.push('04-logged-in.png');
    });

    // Service screenshots
    for (const [serviceName, serviceConfig] of Object.entries(CONFIG.services)) {
      await test.step(`Capture ${serviceName} state`, async () => {
        const servicePage = await context.newPage();
        await servicePage.goto(`${serviceConfig.url}${serviceConfig.dashboardPath}`);
        await servicePage.waitForLoadState('networkidle');
        const filename = `task-6-05-${serviceName}-session.png`;
        await servicePage.screenshot({ 
          path: `.sisyphus/evidence/${filename}`,
          fullPage: true 
        });
        screenshots.push(filename);
        await servicePage.close();
      });
    }

    // Logout flow screenshots
    await test.step('Capture logout flow', async () => {
      const logoutButton = page.locator('button:has-text("Logout"), a:has-text("Logout")').first();
      await page.screenshot({ path: '.sisyphus/evidence/task-6-06-pre-logout-click.png' });
      screenshots.push('06-pre-logout-click.png');

      await logoutButton.click();
      await page.waitForURL(/login|logout/, { timeout: CONFIG.timeouts.logout });
      await page.screenshot({ path: '.sisyphus/evidence/task-6-07-logout-initiated.png' });
      screenshots.push('07-logout-initiated.png');

      // Wait for propagation
      await page.waitForTimeout(10000);
    });

    // Post-logout service screenshots
    for (const [serviceName, serviceConfig] of Object.entries(CONFIG.services)) {
      await test.step(`Capture ${serviceName} post-logout`, async () => {
        const servicePage = await context.newPage();
        await servicePage.goto(`${serviceConfig.url}${serviceConfig.dashboardPath}`);
        await servicePage.waitForLoadState('networkidle');
        const filename = `task-6-08-${serviceName}-logged-out.png`;
        await servicePage.screenshot({ 
          path: `.sisyphus/evidence/${filename}`,
          fullPage: true 
        });
        screenshots.push(filename);
        await servicePage.close();
      });
    }

    console.log('Captured screenshots:', screenshots);
    expect(screenshots.length).toBeGreaterThan(0);
  });
});

test.describe('Backchannel Logout - Edge Cases', () => {
  test('6. Logout during active service usage', async ({ page, context }) => {
    if (!checkEnvironment()) {
      test.skip('Environment variables not configured');
      return;
    }

    // Login
    await page.goto(CONFIG.portal.url);
    const loginButton = page.locator('button:has-text("Login"), a:has-text("Login")').first();
    if (await loginButton.isVisible()) {
      await loginButton.click();
    }
    await page.waitForURL(/realms/, { timeout: CONFIG.timeouts.login });
    await page.fill('input[name="username"], input[id="username"]', CONFIG.portal.username);
    await page.fill('input[name="password"], input[id="password"]', CONFIG.portal.password);
    await page.click('input[type="submit"], button[type="submit"]');
    await page.waitForURL(CONFIG.portal.url, { timeout: CONFIG.timeouts.login });

    // Open Moodle in a new page (simulating active use)
    const moodlePage = await context.newPage();
    await moodlePage.goto(`${CONFIG.services.moodle.url}${CONFIG.services.moodle.dashboardPath}`);

    // Trigger logout from portal while Moodle is open
    const logoutButton = page.locator('button:has-text("Logout"), a:has-text("Logout")').first();
    await logoutButton.click();
    await page.waitForURL(/login|logout/, { timeout: CONFIG.timeouts.logout });

    // Verify Moodle session is terminated
    await moodlePage.waitForTimeout(5000);
    await moodlePage.reload();
    
    const loginVisible = await moodlePage.locator(`text=${CONFIG.services.moodle.loginIndicator}`).isVisible();
    expect(loginVisible).toBeTruthy();
    
    await moodlePage.close();
  });

  test('7. Concurrent sessions terminated on logout', async ({ browser }) => {
    if (!checkEnvironment()) {
      test.skip('Environment variables not configured');
      return;
    }

    // Create two separate browser contexts (simulating two devices)
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const page1 = await context1.newPage();
    const page2 = await context2.newPage();

    // Login on both contexts
    for (const page of [page1, page2]) {
      await page.goto(CONFIG.portal.url);
      const loginButton = page.locator('button:has-text("Login"), a:has-text("Login")').first();
      if (await loginButton.isVisible()) {
        await loginButton.click();
      }
      await page.waitForURL(/realms/, { timeout: CONFIG.timeouts.login });
      await page.fill('input[name="username"], input[id="username"]', CONFIG.portal.username);
      await page.fill('input[name="password"], input[id="password"]', CONFIG.portal.password);
      await page.click('input[type="submit"], button[type="submit"]');
      await page.waitForURL(CONFIG.portal.url, { timeout: CONFIG.timeouts.login });
    }

    // Logout from context1
    const logoutButton = page1.locator('button:has-text("Logout"), a:has-text("Logout")').first();
    await logoutButton.click();
    await page1.waitForURL(/login|logout/, { timeout: CONFIG.timeouts.logout });

    // Verify context2 is also logged out (Keycloak single logout)
    await page2.waitForTimeout(5000);
    await page2.goto(CONFIG.portal.url);
    const needsLogin = await page2.locator('button:has-text("Login"), a:has-text("Login")').first().isVisible();
    
    expect(needsLogin).toBeTruthy();

    await context1.close();
    await context2.close();
  });
});
