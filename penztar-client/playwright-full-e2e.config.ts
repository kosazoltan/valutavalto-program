import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright config for FULL E2E tests
 * Target: http://127.0.0.1:3000 (running Electron dev server)
 */

export default defineConfig({
  testDir: './e2e',
  testMatch: '**/full-e2e.spec.ts',
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
      name: 'chromium-full-e2e',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 800 },
      },
    },
  ],

  timeout: 90000,
  expect: { timeout: 15000 },
  outputDir: './playwright-artifacts/full-e2e',
});
