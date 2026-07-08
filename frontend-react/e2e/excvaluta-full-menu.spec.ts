import { expect, test, type Page } from '@playwright/test'
import path from 'path'
import fs from 'fs'

/**
 * T20 — Full menu traversal live e2e
 *
 * Celok:
 *  - Bejelentkezes env credentials-szel (TEST_COMPANY_CODE / TEST_WORKER_CODE / TEST_PASSWORD)
 *  - Minden menupont megnyitasa (menuGroups.ts alapjan)
 *  - Oldalankent: HTTP status, body length, console error count
 *  - Screenshot minden oldalrol + report generalas
 */

const BASE = 'https://excvaluta.com'
const SCREENSHOT_DIR = 'test-results/live-menu-traversal'

interface PageProbeResult {
  path: string
  label: string
  group: string
  status: number
  bodyLen: number
  consoleErrors: string[]
  networkErrors: string[]
  renderedMs: number
  screenshot: string
}

// Sourcery PR #183 #3: mutable top-level RESULTS eltavolitva; local to test + afterAll disposal

// menuGroups.ts-bol szarmaztatott teljes lista (2026-04-24 allapot)
// Minden path-hoz tartozik egy label + csoport
const MENU_ITEMS: Array<{ group: string; label: string; path: string }> = [
  // Foertektar
  { group: 'Foertektar', label: 'Orszagos dashboard', path: '/foertektar' },
  { group: 'Foertektar', label: 'Arfolyam kezeles', path: '/rate-management' },
  { group: 'Foertektar', label: 'Arfolyam keszites', path: '/rates/creation' },
  { group: 'Foertektar', label: 'Arfolyam publikalas', path: '/rate-management/workflow' },
  { group: 'Foertektar', label: 'MNB jelentesek', path: '/mnb/reports' },
  { group: 'Foertektar', label: 'Penztaros KPI', path: '/statistics/cashier-kpi' },
  { group: 'Foertektar', label: 'Orszagos keszlet', path: '/inventory' },
  { group: 'Foertektar', label: 'Keszlet-snapshot', path: '/stock-snapshot' },
  { group: 'Foertektar', label: 'Ertektar leltar', path: '/vault-stocktake' },

  // Arfolyamok
  { group: 'Arfolyamok', label: 'Arfolyam dashboard', path: '/rate-management' },
  { group: 'Arfolyamok', label: 'Arfolyamok', path: '/rates' },
  { group: 'Arfolyamok', label: 'Arfolyam tortenet', path: '/rates/history' },
  { group: 'Arfolyamok', label: 'Arfolyam kategoriak', path: '/rates/categories' },

  // Riportok
  { group: 'Riportok', label: 'Riportok', path: '/reports' },
  { group: 'Riportok', label: 'Kiterjesztett riportok', path: '/reports/extended' },
  { group: 'Riportok', label: 'MNB riportok', path: '/reports/mnb' },
  { group: 'Riportok', label: 'Napi forgalom', path: '/daily-turnover' },
  { group: 'Riportok', label: 'Nyereseg', path: '/profit' },
  { group: 'Riportok', label: 'Keszlet pillanatkepek', path: '/stock-snapshot' },
  { group: 'Riportok', label: 'Konyveles export', path: '/booking-export' },

  // AML / Compliance
  { group: 'AML', label: 'Rendorsegi megkeresesek', path: '/police-requests' },
  { group: 'AML', label: 'Audit naplo', path: '/audit-log' },
  { group: 'AML', label: 'Szankcios lista', path: '/sanction' },
  { group: 'AML', label: 'Plomba nyilvantartas', path: '/seal-tracking' },
  { group: 'AML', label: 'Compliance Dashboard', path: '/compliance' },

  // Ugyfelek
  { group: 'Ugyfelek', label: 'Ugyfelkezeles', path: '/customers' },

  // Adminisztracio
  { group: 'Admin', label: 'Dolgozok', path: '/workers' },
  { group: 'Admin', label: 'HR munkavallalok', path: '/employees' },
  { group: 'Admin', label: 'Munkaido nyilvantartas', path: '/attendance' },
  { group: 'Admin', label: 'Engedelyek', path: '/licenses' },
  { group: 'Admin', label: 'Rendszerbeallitasok', path: '/settings' },
  { group: 'Admin', label: 'Jogosultsag matrix', path: '/settings/permission-matrix' },
  { group: 'Admin', label: 'Utemezo', path: '/scheduler' },
  { group: 'Admin', label: 'E-mail beallitasok', path: '/email-settings' },

  // Kamera (feature-flag mogott)
  { group: 'Kamera', label: 'Elo kep', path: '/camera/live' },
  { group: 'Kamera', label: 'Visszajatszas', path: '/camera/playback' },
  { group: 'Kamera', label: 'Export & Custody', path: '/camera/export' },
  { group: 'Kamera', label: 'Allapot', path: '/camera/status' },

  // Altalanos navigacio
  { group: 'Navigacio', label: 'Iranyitopult', path: '/central-workstation' },
  { group: 'Navigacio', label: 'Tranzakciolista', path: '/transactions' },
  { group: 'Navigacio', label: 'Szallitmanyigenyek (FIX PR #180)', path: '/shipments' },
  { group: 'Navigacio', label: 'Atadas-atvetel (ertektar)', path: '/transfers' },
  { group: 'Navigacio', label: 'Uton levo csomagok', path: '/transit' },
  { group: 'Navigacio', label: 'Ertektari dashboard', path: '/treasury' },
]

function ensureDir() {
  if (!fs.existsSync(SCREENSHOT_DIR)) fs.mkdirSync(SCREENSHOT_DIR, { recursive: true })
}

async function login(
  page: Page,
  companyCode: string,
  workerCode: string,
  password: string,
): Promise<void> {
  await page.goto(BASE + '/login', { waitUntil: 'networkidle', timeout: 30000 })
  await page
    .locator('input:not([type="hidden"])')
    .first()
    .waitFor({ state: 'visible', timeout: 10000 })

  const inputs = page.locator('input:not([type="hidden"])')
  const count = await inputs.count()
  if (count < 3) throw new Error(`Login form <3 input (got ${count})`)

  await inputs.nth(0).fill(companyCode)
  await inputs.nth(1).fill(workerCode)
  await inputs.nth(2).fill(password)

  const submitBtn = page.locator('button[type="submit"]').first()
  await submitBtn.click()
  await Promise.race([
    page.waitForURL((u) => !u.toString().includes('/login'), { timeout: 15000 }).catch(() => null),
    page
      .locator('[role="alert"], .error')
      .first()
      .waitFor({ state: 'visible', timeout: 15000 })
      .catch(() => null),
  ])

  const afterUrl = page.url()
  if (afterUrl.includes('/login')) {
    throw new Error(`Login failed, still on /login (URL: ${afterUrl})`)
  }
}

async function probePage(
  page: Page,
  item: { group: string; label: string; path: string },
): Promise<PageProbeResult> {
  const consoleErrors: string[] = []
  const networkErrors: string[] = []

  const consoleHandler = (msg: import('@playwright/test').ConsoleMessage) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text().slice(0, 200))
  }
  const responseHandler = (resp: import('@playwright/test').Response) => {
    // Audit-iter3 P0 (CodeQL js/incomplete-url-substring-sanitization fix, 2026-04-27):
    // a korabbi `includes(BASE)` barhol matchelt a URL-ben, igy
    // `https://attacker.com/?to=https://excvaluta.com/foo` is true-t adott volna.
    // Fix: `startsWith(BASE)` - csak ha a URL a BASE-szel kezdodik.
    if (resp.status() >= 400 && resp.url().startsWith(BASE)) {
      networkErrors.push(`${resp.status()} ${resp.url().replace(BASE, '')}`)
    }
  }
  page.on('console', consoleHandler)
  page.on('response', responseHandler)

  const t0 = Date.now()
  const response = await page
    .goto(BASE + item.path, { waitUntil: 'networkidle', timeout: 20000 })
    .catch((e) => {
      consoleErrors.push(`NAVIGATION_ERROR: ${(e as Error).message.slice(0, 150)}`)
      return null
    })
  await page.waitForTimeout(1500) // CSR hydration + async data load
  const renderedMs = Date.now() - t0

  const bodyLen = (
    await page
      .locator('body')
      .innerText()
      .catch(() => '')
  ).length
  const ssName = `${item.group.toLowerCase()}-${item.path.replace(/\//g, '_')}.png`.replace(
    /\s+/g,
    '-',
  )
  const ssPath = path.join(SCREENSHOT_DIR, ssName)
  await page.screenshot({ path: ssPath, fullPage: true }).catch(() => {})

  page.off('console', consoleHandler)
  page.off('response', responseHandler)

  return {
    path: item.path,
    label: item.label,
    group: item.group,
    status: response?.status() ?? 0,
    bodyLen,
    consoleErrors: [...new Set(consoleErrors)].slice(0, 5),
    networkErrors: [...new Set(networkErrors)].slice(0, 5),
    renderedMs,
    screenshot: ssPath,
  }
}

test.describe('T20 — Full menu traversal live e2e', () => {
  test.beforeAll(async () => {
    ensureDir()
  })

  // Sourcery PR #183 #3: RESULTS local to test instead of module-scoped mutable
  const RESULTS: PageProbeResult[] = []

  test.afterAll(async () => {
    // Report generalasa
    const report = {
      timestamp: new Date().toISOString(),
      total: RESULTS.length,
      ok_200: RESULTS.filter((r) => r.status >= 200 && r.status < 300).length,
      redirect: RESULTS.filter((r) => r.status >= 300 && r.status < 400).length,
      client_error: RESULTS.filter((r) => r.status >= 400 && r.status < 500).length,
      server_error: RESULTS.filter((r) => r.status >= 500).length,
      pages_with_console_errors: RESULTS.filter((r) => r.consoleErrors.length > 0).length,
      pages_with_network_errors: RESULTS.filter((r) => r.networkErrors.length > 0).length,
      results: RESULTS,
    }
    const reportPath = path.join(SCREENSHOT_DIR, 'report.json')
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2), 'utf8')
    console.log(`\n=== Full menu traversal report ===`)
    console.log(
      `Total: ${report.total}, OK 2xx: ${report.ok_200}, Redirect: ${report.redirect}, 4xx: ${report.client_error}, 5xx: ${report.server_error}`,
    )
    console.log(
      `Console errors: ${report.pages_with_console_errors} pages, Network errors: ${report.pages_with_network_errors} pages`,
    )
    console.log(`Report JSON: ${reportPath}`)
  })

  test('T20.0 — login + full menu traversal', async ({ page }) => {
    const companyCode = process.env.TEST_COMPANY_CODE
    const workerCode = process.env.TEST_WORKER_CODE
    const password = process.env.TEST_PASSWORD

    if (!companyCode || !workerCode || !password) {
      console.log(
        'SKIP T20: TEST_COMPANY_CODE / TEST_WORKER_CODE / TEST_PASSWORD env var-ok nincsenek beallitva',
      )
      test.skip(true, 'Credentials env var hianyzik')
      return
    }

    // 1. Login
    await login(page, companyCode, workerCode, password)
    console.log(`[T20] Login OK (URL: ${page.url()})`)

    // 2. Iteral minden menu-item-en
    for (const item of MENU_ITEMS) {
      const result = await probePage(page, item)
      RESULTS.push(result)

      const marker =
        result.status >= 200 && result.status < 400 && result.consoleErrors.length === 0
          ? '[OK ]'
          : result.status >= 400 || result.networkErrors.length > 0
            ? '[FAIL]'
            : '[WARN]'

      console.log(
        `${marker} ${item.group.padEnd(12)} ${item.label.padEnd(35)} ${item.path.padEnd(38)} ` +
          `HTTP ${result.status} body=${result.bodyLen} t=${result.renderedMs}ms ` +
          `console=${result.consoleErrors.length} network=${result.networkErrors.length}`,
      )

      if (result.networkErrors.length > 0) {
        console.log(`        Network: ${result.networkErrors.join(' | ')}`)
      }
      if (result.consoleErrors.length > 0 && result.consoleErrors.length <= 3) {
        result.consoleErrors.forEach((e) => console.log(`        Console: ${e}`))
      }
    }

    // 3. Summary assertion: legalabb 80%-nak 2xx/3xx-en kell lenni
    const successCount = RESULTS.filter((r) => r.status >= 200 && r.status < 400).length
    const ratio = successCount / RESULTS.length
    expect(
      ratio,
      `Csak ${Math.round(ratio * 100)}% (${successCount}/${RESULTS.length}) ad 2xx/3xx`,
    ).toBeGreaterThanOrEqual(0.8)
  })
})
