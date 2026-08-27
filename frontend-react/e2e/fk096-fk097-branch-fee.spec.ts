import { expect, test, type Page } from '@playwright/test'

// ─────────────────────────────────────────────────────────────────────────────
// FK-096 + FK-097 — iroda-szintű kezelési díj: publikálás→tranzakció-képernyő,
// offline cache-first díjmező, pénztáros read-only nézet.
//
// Minták:
//  - pos-handling-fee-report.spec.ts: hand-built JWT (createJwt), blanket
//    page.route('**/api/v1/**') mock.
//  - fk071-offline-sync-visibility.spec.ts: window.electronAPI stub technika
//    (addInitScript) a renderer-szerződés böngészős teszteléséhez.
//
// A 30 mp-es szinkron-ciklust NEM valódi időzítővel szimuláljuk (a terv szerint
// az interval a sync-engine start(intervalMs) argumentuma) — a spec a végpont-
// szerződést assertálja: publikálás után a /branch-fee-config/own az új értéket
// adja, a tranzakció-képernyő pedig azt jeleníti meg.
// ─────────────────────────────────────────────────────────────────────────────

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const foertektarWorker = {
  id: 77,
  workerCode: 'FOERT1',
  firstName: 'Főértéktáros',
  lastName: 'Teszt',
  fullName: 'Teszt Főértéktáros',
  role: 'FOERTEKTAR',
  branchId: 'branch-1',
  branchCode: '001',
  branchName: 'Fő utca',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const penztarWorker = {
  id: 9,
  workerCode: 'PENZT1',
  firstName: 'Pénztáros',
  lastName: 'Teszt',
  fullName: 'Teszt Pénztáros',
  role: 'PENZTAR',
  branchId: 'branch-1',
  branchCode: '001',
  branchName: 'Fő utca',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

// A kiinduló LIVE konfig (V383-seed jellegű): PER_MILLE 3‰, sapka nélkül, version 0.
// Publikálás után 5‰ lesz — ezt látja a tranzakció-képernyő a /own-on keresztül.
const feeState = {
  draftRate: null as number | null,
  liveRate: 3,
  version: 0,
  published: false,
}

const EUR_RATE = {
  currencyId: 1,
  currencyCode: 'EUR',
  currencyName: 'Euró',
  baseBuyRate: 391.5,
  baseSellRate: 398.5,
  active: true,
  officialRate: 395,
}

function branchRow() {
  return {
    branchId: 'branch-1',
    branchCode: '001',
    branchName: 'Fő utca',
    region: 'BUDAPEST',
    liveFeeMode: 'PER_MILLE',
    livePerMilleRate: feeState.liveRate,
    livePerMilleCap: null,
    hasDraft: feeState.draftRate != null,
    draftFeeMode: feeState.draftRate != null ? 'PER_MILLE' : null,
    draftPerMilleRate: feeState.draftRate,
    draftPerMilleCap: null,
    version: feeState.version,
  }
}

function ownLive() {
  return {
    branchId: 'branch-1',
    branchCode: '001',
    feeMode: 'PER_MILLE',
    perMilleRate: feeState.liveRate,
    perMilleCap: null,
    validFrom: '2026-08-26',
    brackets: [],
  }
}

function jwtFor(role: string) {
  return createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: role,
    permissions: ['READ', 'WRITE'],
    roles: [role],
  })
}

async function login(page: Page, workerCode: string) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill(workerCode)
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await page.waitForURL((url) => !url.pathname.endsWith('/login'))
}

/** EUR vétel rögzítése a tranzakció-képernyőn: 100 EUR × 391.5 = 39 150 HUF. */
async function fillEurBuy(page: Page) {
  const currencyInput = page.getByTestId('currency-input-0')
  await expect(currencyInput).toBeVisible()
  await currencyInput.fill('EUR')
  await page.getByPlaceholder('0').first().fill('100')
}

// ── (a) online: Főértéktáros publikálási folyamat ────────────────────────────

async function mockAdminApis(page: Page) {
  const token = jwtFor('FOERTEKTAR')
  await page.route('**/api/v1/**', async (route) => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const method = route.request().method()
    const json = (body: unknown) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(body) })

    if (path.endsWith('/auth/login') && method === 'POST') {
      return json({
        token,
        tokenType: 'Bearer',
        expiresAt: new Date(Date.now() + 3600_000).toISOString(),
        worker: foertektarWorker,
        activeRole: 'FOERTEKTAR',
        permissions: ['READ', 'WRITE'],
        roles: ['FOERTEKTAR'],
        roleSelectionRequired: false,
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') return json({ token })
    if (path.endsWith('/workers/me') && method === 'GET') return json(foertektarWorker)
    if (path.endsWith('/features') && method === 'GET') return json({})

    // FK-096 branch-fee-config végpontok (D11: expectedVersion a törzsben).
    // ITEM 5 (R2-WU-9): a draft (:draft POST) és publish (:publish POST) handlerek a
    // VALÓS controller-választ adják vissza — R2-D8 óta a BranchFeeConfigController
    // saveDraft/publish SOR-alakú BranchFeeConfigRowDto-t ad (branchId/branchCode/
    // branchName/region/live*/hasDraft/draft*/version), pontosan azt, amit a branchRow()
    // épít. A korábbi round-1 mock ezzel már kontrakt-helyes volt; a round-2-ben a
    // backend igazodott hozzá (nincs DTO-only válasz többé).
    if (path.endsWith('/branch-fee-config') && method === 'GET') {
      return json({
        summary: {
          totalBranches: 1,
          configuredBranches: 1,
          bracketBranches: 0,
          perMilleBranches: 1,
        },
        rows: [branchRow()],
      })
    }
    if (path.endsWith('/branch-fee-config/own') && method === 'GET') return json(ownLive())
    if (path.endsWith('/branch-fee-config/branch-1/draft') && method === 'POST') {
      const body = route.request().postDataJSON() as { perMilleRate: number | null }
      feeState.draftRate = body.perMilleRate
      return json(branchRow())
    }
    if (path.endsWith('/branch-fee-config/branch-1/publish') && method === 'POST') {
      feeState.liveRate = feeState.draftRate ?? feeState.liveRate
      feeState.draftRate = null
      feeState.version += 1
      feeState.published = true
      return json(branchRow())
    }
    if (path.endsWith('/handling-fee-bracket') && method === 'GET') {
      return json({ live: [], draft: [] })
    }
    if (path.endsWith('/exchange-rates') && method === 'GET') return json([EUR_RATE])
    if (path.endsWith('/daily-sessions/is-open') && method === 'GET') return json(true)
    if (path.endsWith('/transactions/cashier-rate-quota') && method === 'GET') {
      return json({ limit: 5, used: 0, remaining: 5, minAmountHuf: 400000 })
    }
    if (path.endsWith('/cash-balances') && method === 'GET') {
      return json([{ currencyCode: 'HUF', currentBalance: 20_000_000 }])
    }
    if (path.endsWith('/discount-threshold/apply') && method === 'GET') {
      const originalFee = Number(url.searchParams.get('originalFee') ?? 0)
      return json({
        originalFee,
        adjustedFee: originalFee,
        discountCode: '',
        discountName: 'Nincs automatikus kedvezmény',
      })
    }
    return json({})
  })
}

test('(a) FK-096/097 online: Mentés nem érinti a LIVE-ot, Küldés publikál, a tranzakció-képernyő az új értéket látja', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1366, height: 900 })
  await mockAdminApis(page)
  await login(page, 'FOERT1')

  await page.goto('/handling-fee-config', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Kezelési költség beállítások' })).toBeVisible()

  const row = page.getByRole('row', { name: '001' })
  await expect(row).toContainText('Ezrelékes')
  await expect(row).toContainText('3 ‰')
  await expect(row).not.toContainText('✎ van')

  // Iroda-sor megnyitása → szerkesztő modal. A modal konténere egyedi (fixed z-40) —
  // az admin nézet közös sáv-szerkesztője (CommonBracketEditor) ugyanezeket a
  // gombfeliratokat használja, ezért minden vezérlőt a modalra scope-olunk.
  await row.click()
  const modal = page.locator('div.fixed.inset-0.z-40')
  await expect(modal.getByText('Kezelési díj — 001 (Fő utca)')).toBeVisible()

  // Mentés (piszkozat) 5‰-re → POST .../draft megfigyelhető, a LIVE oszlop VÁLTOZATLAN (FR-8).
  const draftRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' &&
      new URL(request.url()).pathname.endsWith('/branch-fee-config/branch-1/draft'),
  )
  await modal.getByLabel('Ezrelék mértéke').fill('5')
  await modal.getByRole('button', { name: 'Mentés (piszkozat)' }).click()
  const draftBody = (await draftRequest).postDataJSON() as Record<string, unknown>
  expect(draftBody.feeMode).toBe('PER_MILLE')
  expect(draftBody.perMilleRate).toBe(5)
  await expect(row).toContainText('✎ van')
  await expect(row).toContainText('3 ‰') // LIVE változatlan

  // A piszkozat-mentés után a modal bezárul (onChanged → setSelected(null)) —
  // a publikáláshoz újra megnyitjuk a sort.
  await row.click()
  await expect(modal.getByText('Kezelési díj — 001 (Fő utca)')).toBeVisible()

  // Küldés + megerősítés → POST .../publish expectedVersion: 0-val (B2: 0 legitim).
  const publishRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' &&
      new URL(request.url()).pathname.endsWith('/branch-fee-config/branch-1/publish'),
  )
  await modal.getByRole('button', { name: 'Küldés', exact: true }).click()
  await page.getByRole('alertdialog').getByRole('button', { name: 'Küldés megerősítése' }).click()
  const publishBody = (await publishRequest).postDataJSON() as Record<string, unknown>
  expect(publishBody).toEqual({ expectedVersion: 0 })

  // ITEM 5 (R2-WU-9): a LIVE oszlop frissülése a publish VÁLASZÁBÓL történik —
  // bármiféle navigáció/újratöltés ELŐTT bizonyítjuk, hogy nem refetch menti meg.
  await expect(row).toContainText('5 ‰')

  // Publikálás után a LIVE oszlop az új értéket mutatja, a piszkozat-jelölő eltűnik.
  await expect(row).toContainText('5 ‰')
  await expect(row).not.toContainText('✎ van')
  expect(feeState.published).toBe(true)

  // A tranzakció-képernyő a /branch-fee-config/own-on keresztül az ÚJ értéket látja:
  // 39 150 HUF × 5‰ = round(195.75) = 196 → 5 Ft-os kerekítéssel 195; a mező ZÁRT.
  await page.goto('/transactions/cashier', { waitUntil: 'domcontentloaded' })
  await fillEurBuy(page)
  await page.keyboard.press('F9')
  await expect(page.getByText('Kezelési díj / Kedvezmény')).toBeVisible()
  const feeInput = page.getByRole('spinbutton').first()
  await expect(feeInput).toBeDisabled()
  await expect(feeInput).toHaveValue('195')
})

// ── (b) offline: electronAPI stub + abortált branch-fee-config útvonalak ─────

async function installOfflineElectronStub(page: Page) {
  await page.addInitScript(() => {
    const cachedFeeRow = {
      branch_id: 'branch-1',
      branch_code: '001',
      company_id: 'company-1',
      fee_mode: 'PER_MILLE',
      per_mille_rate: 3,
      per_mille_cap: null,
      bracket_json: null,
      valid_from: '2026-08-26',
      synced_at: '2026-08-26T19:00:00Z',
    }
    const cachedRates = [
      {
        currency_code: 'EUR',
        buy_rate: 391.5,
        sell_rate: 398.5,
        unit: 1,
        updated_at: new Date().toISOString(),
        official_rate: 395,
      },
    ]
    ;(window as unknown as { electronAPI: unknown }).electronAPI = {
      getConfig: async (key: string) => window.localStorage.getItem(`__fk097cfg_${key}`),
      setConfig: async (key: string, value: string) => {
        window.localStorage.setItem(`__fk097cfg_${key}`, String(value))
      },
      deleteConfig: async (key: string) => {
        window.localStorage.removeItem(`__fk097cfg_${key}`)
      },
      secureStoreToken: async (token: string) => {
        window.localStorage.setItem('__fk097tok', token)
      },
      secureLoadToken: async () => window.localStorage.getItem('__fk097tok'),
      secureClearToken: async () => {
        window.localStorage.removeItem('__fk097tok')
      },
      getSyncStatus: async () => JSON.stringify({ isRunning: false }),
      getPendingTransactionCount: async () => 0,
      getPendingTransactions: async () => [],
      getPendingConversions: async () => [],
      savePendingTransaction: async () => ({ success: true }),
      getCachedRates: async () => cachedRates,
      getCachedHandlingFeeConfig: async () => cachedFeeRow,
    }
  })
}

async function mockOfflineApis(page: Page) {
  const token = jwtFor('PENZTAR')
  await page.route('**/api/v1/**', async (route) => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const method = route.request().method()
    const json = (body: unknown) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(body) })

    // FK-097 FR-6: a díj-konfig MINDEN szerver-útvonala halott — a cache-ből kell élni.
    if (path.includes('/branch-fee-config')) return route.abort()

    if (path.endsWith('/auth/login') && method === 'POST') {
      return json({
        token,
        tokenType: 'Bearer',
        expiresAt: new Date(Date.now() + 3600_000).toISOString(),
        worker: penztarWorker,
        activeRole: 'PENZTAR',
        permissions: ['READ', 'WRITE'],
        roles: ['PENZTAR'],
        roleSelectionRequired: false,
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') return json({ token })
    if (path.endsWith('/workers/me') && method === 'GET') return json(penztarWorker)
    if (path.endsWith('/features') && method === 'GET') return json({})
    if (path.endsWith('/daily-sessions/is-open') && method === 'GET') return json(true)
    if (path.endsWith('/daily-sessions/current') && method === 'GET') {
      return json({ id: 'session-1', openedAt: new Date().toISOString() })
    }
    // A branch-fee-config kivételével minden más endpoint is elérhetetlen (offline).
    return route.abort()
  })
}

test('(b) FK-097 offline: feltöltött cache mellett a díjmező írásvédett és a cache-ből számol', async ({
  page,
}) => {
  const feeConfigRequests: string[] = []
  page.on('request', (request) => {
    if (request.url().includes('/branch-fee-config')) feeConfigRequests.push(request.url())
  })

  await page.setViewportSize({ width: 1366, height: 900 })
  // Böngészőben a useAppMode alapból 'full' — a session-override kapcsol pénztár módra
  // (cashier-stocks-mode.spec.ts minta), hogy a CashierTransactionPage lokál módban fusson.
  await page.addInitScript(() => sessionStorage.setItem('vv_session_app_mode', 'penztar'))
  await installOfflineElectronStub(page)
  await mockOfflineApis(page)
  await login(page, 'PENZT1')

  await page.goto('/transactions/cashier', { waitUntil: 'domcontentloaded' })
  await fillEurBuy(page)

  // 39 150 HUF × 3‰ = round(117.45) = 117 → 5 Ft-os kerekítéssel 115 Ft.
  await page.keyboard.press('F9')
  await expect(page.getByText('Kezelési díj / Kedvezmény')).toBeVisible()
  const feeInput = page.getByRole('spinbutton').first()
  await expect(feeInput).toBeDisabled()
  await expect(feeInput).toHaveValue('115')
  await expect(
    page.getByText('A díjat a program számolja a Kezelési költség beállítások szerint'),
  ).toBeVisible()

  // A díj-konfig végpontjai egyszer sem voltak sikeresek — a konfig a cache-ből jött.
  expect(feeConfigRequests).toEqual([])
})

// ── (c) pénztáros read-only nézet (FR-096-14) ────────────────────────────────

async function mockCashierApis(page: Page) {
  const token = jwtFor('PENZTAR')
  await page.route('**/api/v1/**', async (route) => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const method = route.request().method()
    const json = (body: unknown) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(body) })

    if (path.endsWith('/auth/login') && method === 'POST') {
      return json({
        token,
        tokenType: 'Bearer',
        expiresAt: new Date(Date.now() + 3600_000).toISOString(),
        worker: penztarWorker,
        activeRole: 'PENZTAR',
        permissions: ['READ'],
        roles: ['PENZTAR'],
        roleSelectionRequired: false,
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') return json({ token })
    if (path.endsWith('/workers/me') && method === 'GET') return json(penztarWorker)
    if (path.endsWith('/features') && method === 'GET') return json({})
    if (path.endsWith('/branch-fee-config/own') && method === 'GET') return json(ownLive())
    if (path.endsWith('/daily-sessions/is-open') && method === 'GET') return json(true)
    if (path.endsWith('/daily-sessions/current') && method === 'GET') {
      return json({ id: 'session-1', openedAt: new Date().toISOString() })
    }
    return json([])
  })
}

test('(c) FK-096 FR-14: pénztárosként csak a saját-iroda kártya látszik, szerkesztő vezérlők nélkül', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1366, height: 900 })
  await page.addInitScript(() => sessionStorage.setItem('vv_session_app_mode', 'penztar'))
  await mockCashierApis(page)
  await login(page, 'PENZT1')

  await page.goto('/handling-fee-config', { waitUntil: 'domcontentloaded' })

  // Csak a saját-iroda read-only kártya jelenik meg (élő HTTP, pitfall #15).
  await expect(page.getByText('Kezelési díj — 001 iroda (read-only)')).toBeVisible()
  await expect(page.getByText('Ezrelékes')).toBeVisible()
  await expect(page.getByText('3 ‰')).toBeVisible()

  // Az admin nézet elemei NINCSENEK jelen: nincs iroda-tábla, összefoglaló kártyák,
  // régió-szűrő, közös sáv-szerkesztő, sem mentés/küldés vezérlő.
  await expect(page.getByRole('columnheader', { name: 'Kód' })).toHaveCount(0)
  await expect(page.getByText('Összes pénztár')).toHaveCount(0)
  await expect(page.getByLabel('Terület')).toHaveCount(0)
  await expect(page.getByRole('button', { name: 'Mentés (piszkozat)' })).toHaveCount(0)
  await expect(page.getByRole('button', { name: 'Küldés', exact: true })).toHaveCount(0)
  await expect(page.getByRole('radio', { name: 'Sávos (közös sávok)' })).toHaveCount(0)
})
