import { defineConfig } from '@playwright/test'

/**
 * Playwright config for REAL Electron app E2E tests
 * Uses _electron.launch() — tests the actual Electron binary, not a browser
 */
export default defineConfig({
  testDir: './e2e',
  testMatch: 'electron-full-e2e.spec.ts',
  fullyParallel: false,
  retries: 0,
  workers: 1,
  reporter: [['list']],
  timeout: 120_000,
  expect: { timeout: 15_000 },
  use: {
    trace: 'on-first-retry',
  },
})
