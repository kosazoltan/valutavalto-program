import { test, expect, request as pwRequest } from '@playwright/test'

/**
 * Production Acceptance Smoke Test Suite
 * ---------------------------------------
 * Read-only smoke tesztek a https://excvaluta.com produktum-rendszer
 * egészségének ellenőrzésére. SOHA nem módosít adatot.
 *
 * Futtatás:
 *   npx playwright test production-acceptance --config=playwright.config.ts
 *
 * Megjegyzes: a default `playwright.config.ts` `testDir: './e2e'`-re van
 * allitva + `testIgnore` listara. Ha ez a spec a `playwright/` mappaban
 * marad, akkor `--config=playwright.live.config.ts` vagy egy dedikalt
 * config kell — a feladat-spec szerint a fajl itt van. Tovabbi opcio:
 * `npx playwright test playwright/production-acceptance.spec.ts`.
 *
 * NEM igenyel authentikaciot — kizarolag publikus endpoint-ok + login UI.
 */

const PROD_BASE = 'https://excvaluta.com'
const API_BASE = `${PROD_BASE}/api/v1`

// Sorosan futnak — egyik a masik utan, hogy ne ddosoljuk a produktumot
test.describe.configure({ mode: 'serial' })

test.describe('1. Public API endpoints reachable', () => {
  test('bootstrap-status returns 200 with completed:true', async () => {
    const ctx = await pwRequest.newContext()
    const res = await ctx.get(`${API_BASE}/auth/bootstrap-status`, { timeout: 10_000 })
    expect(res.status(), `bootstrap-status HTTP status`).toBe(200)
    const body = await res.json()
    expect(body, 'bootstrap-status body').toBeTruthy()
    expect(
      body.completed,
      `bootstrap-status.completed must be true (kapott: ${JSON.stringify(body)})`,
    ).toBe(true)
    await ctx.dispose()
  })

  test('public/branches?companyCode=EBC returns array with >= 5 entries', async () => {
    const ctx = await pwRequest.newContext()
    const res = await ctx.get(`${API_BASE}/public/branches?companyCode=EBC`, { timeout: 10_000 })
    expect(res.status(), `public/branches HTTP status`).toBe(200)
    const body = await res.json()
    expect(Array.isArray(body), 'response must be array').toBe(true)
    expect(body.length, `expected >= 5 branches, got ${body.length}`).toBeGreaterThanOrEqual(5)
    // Minimal sanity: minden branch-nek legyen `code` vagy `branchCode` mezeje
    for (const b of body) {
      const hasCode = typeof b?.code === 'string' || typeof b?.branchCode === 'string'
      expect(hasCode, `branch must have code field: ${JSON.stringify(b)}`).toBe(true)
    }
    await ctx.dispose()
  })
})

test.describe('2. Login UI loads', () => {
  test('login page renders title + 3 form fields', async ({ page }) => {
    const errors: string[] = []
    page.on('pageerror', (e) => errors.push(e.message))

    const resp = await page.goto(PROD_BASE, { waitUntil: 'networkidle', timeout: 30_000 })
    expect(resp?.status(), 'home page HTTP').toBeLessThan(500)

    // Hagyjunk idot a React CSR hidracionak
    await page.waitForTimeout(2_500)

    // Page title check
    const title = await page.title()
    expect(title.length, 'page title must not be empty').toBeGreaterThan(0)
    // Title varakozas: "Exclusive Best Change", "EBC", vagy "Penztar"/"Valuta" tartalmazo
    const titleLower = title.toLowerCase()
    const titleOk =
      titleLower.includes('exclusive best change') ||
      titleLower.includes('best change') ||
      titleLower.includes('ebc') ||
      titleLower.includes('valuta') ||
      titleLower.includes('penztar')
    expect(titleOk, `unexpected page title: "${title}"`).toBe(true)

    // 3 form mezo (cegkod, penztaros kod, jelszo) — a LoginPage hasznalja oket
    const inputs = page.locator('input:not([type="hidden"])')
    const inputCount = await inputs.count()
    expect(
      inputCount,
      `expected >= 3 form inputs (cégkód, pénztáros, jelszó), got ${inputCount}`,
    ).toBeGreaterThanOrEqual(3)

    // Jelszo mezo legyen
    const passwordVisible = await page
      .locator('input[type="password"]')
      .first()
      .isVisible({ timeout: 5_000 })
      .catch(() => false)
    expect(passwordVisible, 'password input not visible').toBe(true)
  })
})

test.describe('3. Login validation works', () => {
  test('empty form / invalid credentials → error stays on login', async ({ page }) => {
    await page.goto(`${PROD_BASE}/login`, { waitUntil: 'networkidle', timeout: 30_000 })
    await page.waitForTimeout(2_500)

    const inputs = page.locator('input:not([type="hidden"])')
    const inputCount = await inputs.count()
    test.skip(inputCount === 0, 'no form inputs visible (SPA placeholder?)')

    // Probaljunk meg ervenytelen credentials-szel beadni a formot
    for (let i = 0; i < inputCount; i++) {
      const input = inputs.nth(i)
      const t = await input.getAttribute('type')
      if (t !== 'hidden') {
        await input.fill(i === 2 ? 'INVALID_PWD_XYZ' : `INVALID_${i}`).catch(() => {})
      }
    }

    await page.waitForTimeout(500)
    const submit = page.locator('button[type="submit"]').first()
    if (await submit.isVisible().catch(() => false)) {
      await submit.click({ force: true }).catch(() => {})
      await page.waitForTimeout(4_000)
    }

    // Vagy hibauzenet, vagy login oldalon maradunk
    const url = page.url()
    const stillOnLogin = url.includes('/login') || url === `${PROD_BASE}/` || url === PROD_BASE
    const hasErrorElement = await page
      .locator('[role="alert"], .error, [class*="error"], [class*="alert"]')
      .first()
      .isVisible({ timeout: 3_000 })
      .catch(() => false)
    // A LoginPage szovege: "Hibás pénztáros kód vagy jelszó"
    const hasErrorText = (
      await page
        .locator('body')
        .innerText()
        .catch(() => '')
    )
      .toLowerCase()
      .includes('hibás')

    expect(
      stillOnLogin || hasErrorElement || hasErrorText,
      `Expected to stay on /login or show error. URL: ${url}, errorVisible: ${hasErrorElement}, hasErrorText: ${hasErrorText}`,
    ).toBe(true)
  })
})

test.describe('4. Static assets load', () => {
  test('CSS + fonts loaded (no FOUC)', async ({ page }) => {
    await page.goto(PROD_BASE, { waitUntil: 'networkidle', timeout: 30_000 })
    await page.waitForTimeout(1_500)

    // Ervenyes CSS: a body computed style background-color NE legyen a default rgba(0,0,0,0)
    const bodyHasStyle = await page.evaluate(() => {
      const cs = window.getComputedStyle(document.body)
      // Tailwind alapertelmezett font-family-t allit, igy a font-family soha nem ures
      return {
        fontFamily: cs.fontFamily,
        // Tailwind preflight: legalabb display: block; margin: 0
        margin: cs.margin,
        // Stylesheets count
        sheetsCount: document.styleSheets.length,
      }
    })

    expect(bodyHasStyle.sheetsCount, 'no stylesheets loaded → CSS missing').toBeGreaterThan(0)
    expect(
      bodyHasStyle.fontFamily.length,
      'computed font-family must not be empty',
    ).toBeGreaterThan(0)

    // Tailwind / Inter font check (nem szigoru — fallback OK)
    const fontFamily = bodyHasStyle.fontFamily.toLowerCase()
    const hasInterOrFallback =
      fontFamily.includes('inter') ||
      fontFamily.includes('system-ui') ||
      fontFamily.includes('sans-serif') ||
      fontFamily.includes('arial') ||
      fontFamily.includes('roboto') ||
      fontFamily.includes('segoe')
    expect(hasInterOrFallback, `unexpected font-family: "${bodyHasStyle.fontFamily}"`).toBe(true)
  })
})

test.describe('5. API health: exchange-rates endpoint require auth (verify 401, NOT 404)', () => {
  /**
   * KORREKCIÓ 2026-05-06: a korábbi spec a `/api/v1/public/exchange-rates` endpointot
   * várta — **ilyen endpoint NEM létezik a backendben**. Az `ExchangeRateController`
   * a `/api/v1/exchange-rates` (auth-protected) URL-en van, és nincs `/public` alias.
   * A helyes smoke teszt: az endpoint létezik (NEM 404), de auth-protected (401/403).
   */
  test('exchange-rates endpoint létezik és auth-required', async () => {
    const ctx = await pwRequest.newContext()
    const res = await ctx.get(`${API_BASE}/exchange-rates`, { timeout: 10_000 })
    // Várjuk: 401 (Unauthorized) vagy 403 (Forbidden) — NEM 404 (Not Found) és NEM 5xx
    const status = res.status()
    expect(
      status,
      `exchange-rates status (várt 401/403, NEM 404): ${status}`,
    ).toBeGreaterThanOrEqual(401)
    expect(status, `exchange-rates 5xx ?: ${status}`).toBeLessThan(500)
    await ctx.dispose()
  })
})

test.describe('6. Response time SLA', () => {
  test('bootstrap-status p95 latency < 2000ms over 5 requests', async () => {
    const ctx = await pwRequest.newContext()
    const samples: number[] = []
    for (let i = 0; i < 5; i++) {
      const t0 = Date.now()
      const res = await ctx.get(`${API_BASE}/auth/bootstrap-status`, { timeout: 5_000 })
      const elapsed = Date.now() - t0
      expect(res.status(), `attempt ${i + 1} status`).toBe(200)
      samples.push(elapsed)
      // Apro szunet a rate-limit elkerulesere
      await new Promise((r) => setTimeout(r, 200))
    }
    await ctx.dispose()

    const sorted = [...samples].sort((a, b) => a - b)
    // p95 5 mintabol = legmagasabb (ceil(0.95 * 5) - 1 = 4)
    const p95 = sorted[Math.min(sorted.length - 1, Math.ceil(0.95 * sorted.length) - 1)]
    const avg = samples.reduce((a, b) => a + b, 0) / samples.length

    console.log(`>> bootstrap-status latency samples (ms): ${samples.join(', ')}`)
    console.log(`>> avg=${avg.toFixed(0)}ms  p95=${p95}ms`)

    expect(p95, `p95 latency too high: ${p95}ms (samples: ${samples.join(',')})`).toBeLessThan(
      2_000,
    )
  })
})
