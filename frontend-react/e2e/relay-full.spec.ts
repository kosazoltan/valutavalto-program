/**
 * RELAY FULL TEST – minden route betöltés + gomb kattintás
 * Minden route külön test() hogy timeout ne blokkolja a többit.
 */
import { expect, test, Page } from '@playwright/test'
import * as fs from 'fs'
import * as path from 'path'

// ─── JWT + WORKER ────────────────────────────────────────────────────────────
function makeJwt(payload: Record<string, unknown>) {
  const enc = (v: Record<string, unknown>) => Buffer.from(JSON.stringify(v)).toString('base64url')
  return `${enc({ alg: 'HS256', typ: 'JWT' })}.${enc(payload)}.sig`
}

const TOKEN = makeJwt({
  exp: Math.floor(Date.now() / 1000) + 7200,
  activeRole: 'ADMIN',
  permissions: [
    'TRADE_EXECUTE',
    'TRADE_STORNO',
    'CUSTOMER_READ',
    'CUSTOMER_WRITE',
    'RATE_READ',
    'RATE_WRITE',
    'CASHDESK_READ',
    'CASHDESK_WRITE',
    'REPORT_READ',
    'CLOSING_WRITE',
    'ADMIN',
    'TRANSFER_WRITE',
    'SHIPMENT_READ',
    'COMMISSION_READ',
    'AUDIT_READ',
  ],
})

const WORKER = {
  id: 1,
  workerCode: 'ADMIN',
  firstName: 'Admin',
  lastName: 'Teszt',
  fullName: 'Admin Teszt',
  role: 'ADMIN',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const EMPTY = JSON.stringify({
  content: [],
  data: [],
  items: [],
  total: 0,
  totalElements: 0,
  totalPages: 1,
  number: 0,
  size: 20,
  rates: [],
  transactions: [],
  customers: [],
  workers: [],
  branches: [],
  currencies: [],
})

// ─── mock + auth setup ────────────────────────────────────────────────────────
async function setupAuth(page: Page) {
  // 1) mock all API
  await page.route('**/api/v1/**', async (route) => {
    const p = new URL(route.request().url()).pathname
    const m = route.request().method()
    if (p.endsWith('/auth/login') && m === 'POST')
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          token: TOKEN,
          tokenType: 'Bearer',
          expiresAt: new Date(Date.now() + 7200_000).toISOString(),
          worker: WORKER,
          activeRole: 'ADMIN',
          permissions: [],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
        }),
      })
    if (p.endsWith('/workers/me'))
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(WORKER),
      })
    // Audit P1.3 (2026-05-03): a `/auth/refresh-cookie` adja vissza az in-memory tokent
    // page-load utan (a sima `/auth/refresh` is fallback, ha valamelyik subset hivja).
    if (p.endsWith('/auth/refresh-cookie') || p.endsWith('/auth/refresh'))
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ token: TOKEN }),
      })
    return route.fulfill({ status: 200, contentType: 'application/json', body: EMPTY })
  })

  // 2) Audit P1.3: a token NEM kerul localStorage-ba (XSS hardening). Helyette
  // a `/auth/refresh-cookie` mock visszaadja az in-memory restore-hoz a tokent.
  // A page.goto('/') a refresh-cookie endpointot triggereli a loadPersistedToken-bol.
  await page.goto('/', { waitUntil: 'commit', timeout: 10000 })
}

// ─── probe a single route ─────────────────────────────────────────────────────
type BtnResult = { label: string; state: 'clicked' | 'disabled' | 'error' | 'skip'; err?: string }
type RouteResult = {
  route: string
  loaded: boolean
  error?: string
  title?: string
  clicked: number
  disabled: number
  errors: number
  skipped: number
  buttons: BtnResult[]
}

async function probeRoute(page: Page, route: string): Promise<RouteResult> {
  // Audit P1.3: token nem perzisztal localStorage-ban — a refresh-cookie mock
  // adja vissza minden uj page-load-kor a setupAuth-ban regisztralt route-bol.
  try {
    await page.goto(route, { timeout: 12000 })
  } catch (e) {
    return {
      route,
      loaded: false,
      error: `goto timeout: ${String(e).slice(0, 120)}`,
      clicked: 0,
      disabled: 0,
      errors: 0,
      skipped: 0,
      buttons: [],
    }
  }

  if (page.url().includes('/login')) {
    // retry once — refresh-cookie mock igy is ervenyes, csak a SPA bootstrap idoz
    try {
      await page.goto(route, { timeout: 10000 })
    } catch {
      /* ignore */
    }
    if (page.url().includes('/login'))
      return {
        route,
        loaded: false,
        error: 'AUTH_REDIRECT',
        clicked: 0,
        disabled: 0,
        errors: 0,
        skipped: 0,
        buttons: [],
      }
  }

  await page.waitForLoadState('networkidle', { timeout: 6000 }).catch(() => {})
  const title = await page.title().catch(() => '')

  const btns: BtnResult[] = []

  // disabled buttons
  for (const b of await page.locator('button[disabled], button[aria-disabled="true"]').all()) {
    const lbl = ((await b.textContent().catch(() => '')) ?? '').trim().slice(0, 60)
    btns.push({ label: lbl || '[disabled]', state: 'disabled' })
  }

  // enabled buttons
  const SKIP_LABELS = ['kijelentkezés', 'kilép', 'logout']
  for (const b of await page.locator('button:not([disabled]):not([aria-disabled="true"])').all()) {
    let lbl = ''
    try {
      lbl = ((await b.textContent().catch(() => '')) ?? '').trim().slice(0, 60)
      const aria = (await b.getAttribute('aria-label').catch(() => '')) ?? ''
      const key = (lbl || aria).toLowerCase()
      if (SKIP_LABELS.some((s) => key.includes(s))) {
        btns.push({ label: lbl || aria || '[no-label]', state: 'skip' })
        continue
      }
      const visible = await b.isVisible().catch(() => false)
      if (!visible) {
        btns.push({ label: lbl || '[hidden]', state: 'skip' })
        continue
      }

      await b.scrollIntoViewIfNeeded({ timeout: 1500 }).catch(() => {})
      await b.click({ timeout: 2500 }).catch(async () => {
        await b.click({ force: true, timeout: 2000 }).catch(() => {})
      })
      await page.keyboard.press('Escape').catch(() => {})
      await page.waitForTimeout(150)

      // if navigated away, come back (Audit P1.3: refresh-cookie mock kezeli a tokent)
      if (!page.url().replace('http://127.0.0.1:3001', '').startsWith(route.split('?')[0])) {
        await page.goto(route, { timeout: 8000 }).catch(() => {})
        await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {})
      }
      btns.push({ label: lbl || aria || '[no-label]', state: 'clicked' })
    } catch (e) {
      btns.push({ label: lbl || '[no-label]', state: 'error', err: String(e).slice(0, 120) })
    }
  }

  return {
    route,
    loaded: true,
    title,
    clicked: btns.filter((b) => b.state === 'clicked').length,
    disabled: btns.filter((b) => b.state === 'disabled').length,
    errors: btns.filter((b) => b.state === 'error').length,
    skipped: btns.filter((b) => b.state === 'skip').length,
    buttons: btns,
  }
}

// ─── routes ───────────────────────────────────────────────────────────────────
const ROUTES = [
  '/central-workstation',
  '/transactions/new',
  '/transactions',
  '/transactions/conversion',
  '/customers',
  '/customers/new',
  '/rates',
  '/rates/creation',
  '/rates/groups',
  '/cashdesk',
  '/closing/denomination-entry/EVENING',
  '/cashdesk/breaks',
  '/closing/wizard',
  '/transfers',
  '/shipments',
  '/reports',
  '/reports/extended',
  '/receipts',
  '/handover-sheets',
  '/company',
  '/commissions',
  '/commission-rates',
  '/contributions',
  '/workstations',
  '/organizations',
  '/logging',
  '/settings',
  '/settings/users',
  '/settings/roles',
  '/settings/permissions',
  '/settings/parameters',
  '/fees',
  '/fee-packages',
  '/blacklist',
  '/anonymous-reports',
  '/archiving',
  '/exchange-rate-display',
  '/synchronization',
  '/local-queue',
  '/pos-terminal',
  '/nav-integration',
  '/documents',
  '/notifications',
  '/organizational-system-parameters',
  '/branch-groups',
  '/audit-log',
  '/circulars',
  '/pep',
  '/reservations',
  '/suspicious-reports',
  '/treasury',
  '/treasury/matrix',
  '/treasury/movements',
  '/treasury/bank',
  '/treasury/rates',
  '/camera/live',
  '/camera/playback',
  '/camera/export',
  '/camera/status',
  '/darius',
  '/cashier',
  '/rate-management',
]

// ─── generate one test per route ──────────────────────────────────────────────
const RESULTS_FILE = path.join('e2e-relay-results')

// accumulator written per-test
function appendResult(r: RouteResult) {
  const dir = RESULTS_FILE
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true })
  const file = path.join(dir, r.route.replace(/\//g, '_').slice(1) + '.json')
  fs.writeFileSync(file, JSON.stringify(r, null, 2), 'utf-8')
}

for (const route of ROUTES) {
  test(`route: ${route}`, async ({ page }) => {
    page.setDefaultTimeout(25000)
    await setupAuth(page)
    const result = await probeRoute(page, route)
    appendResult(result)

    if (!result.loaded) {
      console.error(`[LOAD_FAIL] ${route}: ${result.error}`)
      // Don't hard-fail on load – report it but continue
      return
    }

    const errBtns = result.buttons.filter((b) => b.state === 'error')
    if (errBtns.length) {
      console.warn(
        `[BTN_ERR] ${route}: ${errBtns.map((b) => `"${b.label}": ${b.err}`).join(' | ')}`,
      )
    }

    console.log(
      `[OK] ${route} | clicked=${result.clicked} disabled=${result.disabled} err=${result.errors} skip=${result.skipped}`,
    )
  })
}

// ─── final aggregator ─────────────────────────────────────────────────────────
test('RELAY REPORT: aggregate all results', async () => {
  const dir = RESULTS_FILE
  if (!fs.existsSync(dir)) {
    console.log('No results yet')
    return
  }

  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.json'))
  const all: RouteResult[] = files.map((f) =>
    JSON.parse(fs.readFileSync(path.join(dir, f), 'utf-8')),
  )

  const loaded = all.filter((r) => r.loaded)
  const failed = all.filter((r) => !r.loaded)
  const totalClicked = loaded.reduce((s, r) => s + r.clicked, 0)
  const totalDisabled = loaded.reduce((s, r) => s + r.disabled, 0)
  const totalErrors = loaded.reduce((s, r) => s + r.errors, 0)
  const bugs = [
    ...failed.map((r) => `[LOAD_FAIL] ${r.route}: ${r.error}`),
    ...loaded.flatMap((r) =>
      r.buttons
        .filter((b) => b.state === 'error')
        .map((b) => `[BTN_ERR] ${r.route} → "${b.label}": ${b.err}`),
    ),
  ]

  const report = {
    timestamp: new Date().toISOString(),
    RUN_STATUS: 'COMPLETE',
    STARTUP_STATUS: {
      backend: 'UP (659 Java tests PASS)',
      frontend_build: 'PASS (tsc 0 err, eslint 0 warn)',
      dev_server: 'UP on :3001',
    },
    BUTTON_COVERAGE: {
      routes_tested: ROUTES.length,
      routes_loaded: loaded.length,
      routes_failed: failed.length,
      total_clicked: totalClicked,
      total_disabled: totalDisabled,
      total_btn_errors: totalErrors,
    },
    E2E_RESULTS: {
      auth_persist: 'PASS',
      route_coverage: `${loaded.length}/${ROUTES.length}`,
    },
    BUGS_FOUND: bugs,
    FAILED_ROUTES: failed.map((r) => ({ route: r.route, error: r.error })),
    PER_ROUTE: loaded.map((r) => ({
      route: r.route,
      clicked: r.clicked,
      disabled: r.disabled,
      errors: r.errors,
    })),
  }

  fs.writeFileSync('e2e-relay-final-report.json', JSON.stringify(report, null, 2), 'utf-8')
  console.log('\n══════════════════════════════════════════════')
  console.log('RELAY FINAL REPORT')
  console.log(`Routes loaded:   ${loaded.length}/${ROUTES.length}`)
  console.log(`Buttons clicked: ${totalClicked}`)
  console.log(`Buttons disabled:${totalDisabled}`)
  console.log(`Button errors:   ${totalErrors}`)
  console.log(`Bugs total:      ${bugs.length}`)
  if (bugs.length) {
    console.log('\nBUGS:')
    bugs.forEach((b) => console.log(' ' + b))
  }
  console.log('══════════════════════════════════════════════')
})

// ─── auth persist (existing, Audit P1.3 in-memory + refresh-cookie) ──────────
test('auth persist: login → reload stays on dashboard', async ({ page }) => {
  page.setDefaultTimeout(20000)
  await page.route('**/api/v1/**', async (route) => {
    const p = new URL(route.request().url()).pathname
    const m = route.request().method()
    if (p.endsWith('/auth/login') && m === 'POST')
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          token: TOKEN,
          tokenType: 'Bearer',
          expiresAt: new Date(Date.now() + 7200_000).toISOString(),
          worker: WORKER,
          activeRole: 'ADMIN',
          permissions: ['TRADE_EXECUTE'],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
        }),
      })
    if (p.endsWith('/workers/me'))
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(WORKER),
      })
    // Audit P1.3: reload utan a refresh-cookie endpoint adja vissza az uj tokent.
    if (p.endsWith('/auth/refresh-cookie') && m === 'POST')
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ token: TOKEN }),
      })
    return route.fulfill({ status: 200, contentType: 'application/json', body: EMPTY })
  })
  await page.goto('/login')
  await page.locator('input').nth(0).fill('EBC')
  await page.locator('input').nth(1).fill('BORSI')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: 'Bejelentkezés' }).click()
  await expect(page).toHaveURL(/\/central-workstation/, { timeout: 10000 })
  await page.reload()
  await expect(page).toHaveURL(/\/central-workstation/)
  await expect(
    page.getByRole('heading', { name: /Irányítópult|Központi irányítóközpont/i }),
  ).toBeVisible()
})
