import { test, expect, type Page, type ElectronApplication } from '@playwright/test'
import { _electron as electron } from 'playwright'
import path from 'node:path'
import fs from 'node:fs'

const SCREENSHOT_DIR = path.join(__dirname, '..', 'playwright-artifacts', 'electron-e2e')
const MAIN_JS = path.join(__dirname, '..', 'dist-electron', 'main.js')
const PROJECT_ROOT = path.join(__dirname, '..')
const ELECTRON_EXE = path.join(PROJECT_ROOT, 'node_modules', 'electron', 'dist', 'electron.exe')
const USER_DATA = path.join(__dirname, '..', '.e2e-userdata')
const BASE_URL = 'app://localhost'

const COMPANY = 'EBC'
const WORKER = 'KOSA'
const PASSWORD = '1234'

let electronApp: ElectronApplication
let page: Page
let screenshotIndex = 0

async function nav(route: string) {
  // Always use client-side navigation (pushState + popstate) to avoid full page reload.
  // A full reload wipes in-memory Zustand auth state and requires async token restore.
  // The app may load via app:// OR via dev server (http://127.0.0.1:3000) depending
  // on environment — pushState works in both cases.
  await page.evaluate((r: string) => {
    window.history.pushState({}, '', r)
    window.dispatchEvent(new PopStateEvent('popstate', { state: {} }))
  }, route)
  // Small wait for React to render the new route
  await page.waitForTimeout(500)
}

async function screenshot(name: string) {
  screenshotIndex++
  const filename = `${String(screenshotIndex).padStart(2, '0')}-${name}.png`
  await page.screenshot({ path: path.join(SCREENSHOT_DIR, filename), fullPage: true })
  return filename
}

async function waitForNoSpinner(timeout = 20_000) {
  await page.waitForFunction(() => {
    const spinners = document.querySelectorAll('.animate-spin, [data-testid="loading"]')
    const body = document.body?.textContent ?? ''
    const isLoading =
      body.includes('Oldal betöltése') ||
      body.includes('Betöltés...') ||
      body.includes('Munkamenet ellenőrzése')
    return spinners.length === 0 && !isLoading
  }, { timeout }).catch(() => {})
  await page.waitForTimeout(500)
}

test.beforeAll(async () => {
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true })

  if (fs.existsSync(USER_DATA)) {
    fs.rmSync(USER_DATA, { recursive: true, force: true })
  }

  // Launch REAL Electron with built-in frontend (production-like, app:// protocol)
  // IMPORTANT: Use executablePath to the real Electron binary + args[0] = absolute main.js path.
  // Without executablePath, Playwright uses the bundled Electron which runs default_app.asar,
  // causing __dirname to resolve to the asar context instead of our dist-electron/ directory.
  electronApp = await electron.launch({
    executablePath: ELECTRON_EXE,
    args: [MAIN_JS],
    env: {
      ...process.env,
      NODE_ENV: 'production',
      ELECTRON_FORCE_PACKAGED: '1',
      ELECTRON_DEV_USER_DATA: USER_DATA,
    },
  })

  page = await electronApp.firstWindow()
  await page.waitForLoadState('domcontentloaded')
  // Wait until app is no longer in "restoring" state (async token load)
  await page.waitForFunction(() => {
    const body = document.body?.textContent ?? ''
    return !body.includes('Betöltés...')
  }, { timeout: 15_000 }).catch(() => {})
  await page.waitForTimeout(1000)
})

test.afterAll(async () => {
  if (electronApp) {
    await electronApp.close()
  }
})

test.describe.serial('Electron E2E — teljes rendszerteszt (beépített frontend)', () => {

  test('01 — Login', async () => {
    await waitForNoSpinner()
    await screenshot('login-page')

    await page.locator('[data-testid="login-company-code"]').fill(COMPANY)
    await page.locator('[data-testid="login-worker-code"]').fill(WORKER)
    await page.locator('[data-testid="login-password"]').fill(PASSWORD)
    await screenshot('login-filled')

    await page.locator('[data-testid="login-submit"]').click()

    await page.waitForURL(/dashboard/, { timeout: 15_000 })
    await waitForNoSpinner()
    await screenshot('dashboard')

    await expect(page).toHaveURL(/dashboard/)
  })

  test('02 — EUR VÉTEL', async () => {
    await nav('/transactions/new')
    await waitForNoSpinner()
    await screenshot('tx-new-page')

    await page.locator('[data-testid="currency-EUR"]').click()
    await page.waitForTimeout(300)

    await page.locator('[data-testid="tx-type-buy"]').click()
    await page.waitForTimeout(300)

    const foreignAmount = page.locator('[data-testid="tx-foreign-amount"]')
    await foreignAmount.click()
    await foreignAmount.fill('100')
    await page.waitForTimeout(500)

    const hufValue = await page.locator('[data-testid="tx-huf-amount"]').inputValue()
    console.log('EUR VÉTEL: 100 EUR =', hufValue, 'HUF')

    await screenshot('tx-buy-before-save')

    await page.locator('[data-testid="tx-save-print"]').click()
    await page.waitForTimeout(3000)

    await screenshot('tx-buy-after-save')

    const bodyText = await page.textContent('body') ?? ''
    console.log('EUR VÉTEL result: bizonylat=', bodyText.includes('BIZONYLAT'), 'success=', bodyText.includes('sikeresen'))

    const closeBtn = page.locator('button:has-text("Bezárás"), button:has-text("×")')
    if (await closeBtn.first().isVisible({ timeout: 2000 }).catch(() => false)) {
      await closeBtn.first().click()
      await page.waitForTimeout(500)
    }
  })

  test('03 — EUR ELADÁS', async () => {
    await nav('/transactions/new')
    await waitForNoSpinner()

    await page.locator('[data-testid="currency-EUR"]').click()
    await page.waitForTimeout(300)
    await page.locator('[data-testid="tx-type-sell"]').click()
    await page.waitForTimeout(300)

    const foreignAmount = page.locator('[data-testid="tx-foreign-amount"]')
    await foreignAmount.click()
    await foreignAmount.fill('100')
    await page.waitForTimeout(500)

    const hufValue = await page.locator('[data-testid="tx-huf-amount"]').inputValue()
    console.log('EUR ELADÁS: 100 EUR =', hufValue, 'HUF')

    await screenshot('tx-sell-before-save')

    await page.locator('[data-testid="tx-save-print"]').click()
    await page.waitForTimeout(3000)

    await screenshot('tx-sell-after-save')

    const bodyText = await page.textContent('body') ?? ''
    console.log('EUR ELADÁS result: bizonylat=', bodyText.includes('BIZONYLAT'), 'success=', bodyText.includes('sikeresen'))

    const closeBtn = page.locator('button:has-text("Bezárás"), button:has-text("×")')
    if (await closeBtn.first().isVisible({ timeout: 2000 }).catch(() => false)) {
      await closeBtn.first().click()
      await page.waitForTimeout(500)
    }
  })

  test('04 — Tranzakciólista', async () => {
    await nav('/transactions')
    await waitForNoSpinner()
    await page.waitForTimeout(1000)
    await screenshot('transaction-list')

    const rows = page.locator('table tbody tr')
    const rowCount = await rows.count()
    console.log('Tranzakciólista:', rowCount, 'sor')
  })

  test('05 — Átadás-átvétel', async () => {
    await nav('/transfers')
    await waitForNoSpinner()
    await page.waitForTimeout(1000)
    await screenshot('transfers-page')

    const newBtn = page.locator('button:has-text("Új átadás"), button:has-text("átadás")')
    if (await newBtn.first().isVisible({ timeout: 3000 }).catch(() => false)) {
      await newBtn.first().click()
      await page.waitForTimeout(1000)
      await screenshot('transfers-new-form')
    }
  })

  test('06 — Pénztár', async () => {
    await nav('/cashdesk')
    await waitForNoSpinner()
    await screenshot('cashdesk')
  })

  test('07 — Ügyfelek', async () => {
    await nav('/customers')
    await waitForNoSpinner()
    await screenshot('customers')
  })

  test('08 — Árfolyamok', async () => {
    await nav('/rates')
    await waitForNoSpinner()
    await screenshot('rates')
    await expect(page.locator('text=EUR').first()).toBeVisible({ timeout: 5000 })
  })

  test('09 — Riportok', async () => {
    await nav('/reports')
    await waitForNoSpinner()
    await screenshot('reports')
  })

  test('10 — Értéktár', async () => {
    await nav('/treasury')
    await waitForNoSpinner()
    await screenshot('treasury')
  })

  test('11 — Audit Log', async () => {
    await nav('/audit-log')
    await waitForNoSpinner()
    await screenshot('audit-log')
  })

  test('12 — Beállítások', async () => {
    await nav('/settings')
    await waitForNoSpinner()
    await screenshot('settings')
  })

  test('13 — Sidebar teljes bejárás', async () => {
    const routes = [
      '/dashboard',
      '/transactions',
      '/transactions/new',
      '/customers',
      '/rates',
      '/cashdesk',
      '/reports',
      '/treasury',
      '/transfers',
      '/audit-log',
      '/settings',
    ]

    for (const route of routes) {
      await nav(route)
      await waitForNoSpinner()
      await page.waitForTimeout(500)

      const url = page.url()
      const bodyText = await page.textContent('body') ?? ''
      const has404 = bodyText.includes('404')
      console.log(route, '→ url=', url, '404=', has404)
      await screenshot('sidebar' + route.replace(/\//g, '-'))
    }
  })
})
