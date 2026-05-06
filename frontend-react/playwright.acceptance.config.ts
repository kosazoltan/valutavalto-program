import { defineConfig, devices } from '@playwright/test'

/**
 * One-off Playwright config for the production-acceptance smoke spec.
 * Targets https://excvaluta.com directly — no local webServer.
 */
export default defineConfig({
  testDir: './playwright',
  testMatch: ['**/production-acceptance.spec.ts'],
  fullyParallel: false,
  retries: 1,
  reporter: [['list']],
  use: {
    baseURL: 'https://excvaluta.com',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'off',
    actionTimeout: 15000,
    navigationTimeout: 30000,
    ignoreHTTPSErrors: false,
  },
  timeout: 45000,
  expect: { timeout: 10000 },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
})
