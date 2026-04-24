import { defineConfig, devices } from '@playwright/test'

/**
 * Playwright config for T20 full menu traversal live e2e (excvaluta.com).
 * Csak a full-menu spec-et futtatja, hosszabb timeout + no retry.
 */
export default defineConfig({
  testDir: './e2e',
  testMatch: '**/excvaluta-full-menu.spec.ts',
  fullyParallel: false,
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: 'https://excvaluta.com',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'off',
    actionTimeout: 20000,
    navigationTimeout: 30000,
    ignoreHTTPSErrors: false,
  },
  timeout: 300000, // 5 perc a teljes menu traversalra
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
  outputDir: 'test-results/live-menu-traversal',
})