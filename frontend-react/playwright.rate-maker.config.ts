import { defineConfig, devices } from '@playwright/test'

const e2ePort = Number(process.env.PLAYWRIGHT_RATE_MAKER_PORT ?? 3102)
const baseURL = `http://127.0.0.1:${e2ePort}`

export default defineConfig({
  testDir: './playwright',
  testMatch: [
    '**/rate-maker-protection.spec.ts',
    '**/rate-maker-dispatch-offline.spec.ts',
    '**/rate-maker-zero-source-error.spec.ts',
  ],
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: 'list',
  timeout: 45_000,
  expect: { timeout: 10_000 },
  use: {
    baseURL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: `npm run dev -- --host 127.0.0.1 --port ${e2ePort} --strictPort`,
    url: `${baseURL}/login`,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: { VITE_APP_FLAVOR: 'rate-maker' },
  },
  projects: [
    {
      name: 'chromium-rate-maker',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
})
