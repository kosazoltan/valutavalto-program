import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright config for LIVE UI E2E tests
 * Target: http://127.0.0.1:3000 (running Electron dev server)
 */

export default defineConfig({
  testDir: './e2e',
  testMatch: '**/live-ui-e2e.spec.ts',
  fullyParallel: false,
  forbidOnly: false,
  retries: 0,
  workers: 1,
  reporter: [['list']],

  use: {
    baseURL: 'http://127.0.0.1:3000',
    trace: 'on',
    screenshot: 'on',
    video: 'off',
    headless: true,
    ignoreHTTPSErrors: true,
  },

  projects: [
    {
      name: 'chromium-live',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 800 },
      },
    },
  ],

  timeout: 60000,
  expect: { timeout: 15000 },
});
