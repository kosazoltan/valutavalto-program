import { defineConfig, devices } from '@playwright/test'

/**
 * Playwright config for LIVE E2E tests against https://excvaluta.com
 * No local webServer needed — hits production directly.
 */
export default defineConfig({
  testDir: './e2e',
  // AI review fix (Codex P2 #249, 2026-04-28): a full-menu spec is itt fusson,
  // mert a default playwright.config.ts testIgnore-ban van. Anelkul SEMMILYEN
  // CI workflow nem futtatja a `excvaluta-full-menu.spec.ts`-t.
  testMatch: ['**/excvaluta-live.spec.ts', '**/excvaluta-full-menu.spec.ts'],
  fullyParallel: false,
  retries: 1,
  reporter: [
    ['list'],
    ['html', { open: 'never', outputFolder: 'playwright-report-live' }],
  ],
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
      name: 'chromium-live',
      use: {
        ...devices['Desktop Chrome'],
        headless: true,
      },
    },
  ],
  outputDir: 'test-results/live-screenshots',
})
