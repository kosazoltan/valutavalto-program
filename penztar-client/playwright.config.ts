import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright config for penztar-client E2E tests
 * Focus: Electron bootstrap auth + API integration tests
 *
 * Note: These are API-level tests (no browser UI)
 * - Uses Playwright request context
 * - Tests .env PENZTAR_BOOTSTRAP_* credentials
 * - Validates auth + cache endpoints
 */

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['list'], process.env.CI ? ['html', { open: 'never' }] : undefined].filter(
    Boolean,
  ) as any,

  use: {
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'api-tests',
      use: {
        ...devices['Desktop Chrome'],
      },
    },
  ],

  // Timeout: 30s per test (API calls only, no browser wait)
  timeout: 30000,
  expect: { timeout: 10000 },
});
