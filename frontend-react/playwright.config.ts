import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  testMatch: ['**/*.spec.ts'],
  // Audit-iter3 P0 (Frontend E2E CI gyokerok-fix, 2026-04-27):
  // a default CI Frontend E2E-bol KIZARJUK a live production teszteket
  // (excvaluta-live + excvaluta-full-menu), mert azoknak kulon
  // `playwright.live.config.ts` + `playwright-live.yml` workflow-juk van.
  // A CF bot-detection / CDN cache CI runner IP-jen 0 input-renderelést okoz
  // (lokalisan 3/3 input + JS errors=0, CI-en bodyText=0). A live monitoring
  // teszt szerint nem PR gate.
  testIgnore: [
    '../penztar-client/**',
    '**/excvaluta-live.spec.ts',
    '**/excvaluta-full-menu.spec.ts',
  ],
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI
    ? [['list'], ['html', { open: 'never' }]]
    : 'list',
  use: {
    baseURL: 'http://127.0.0.1:3000',
    trace: 'on-first-retry',
  },
  webServer: {
    command: 'npm run dev -- --host 127.0.0.1',
    url: 'http://127.0.0.1:3000/login',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
      },
    },
  ],
})