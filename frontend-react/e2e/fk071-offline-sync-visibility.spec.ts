/**
 * FK-071 — Offline szinkron-hiba láthatósága — RED-fázis E2E specifikáció
 * (implementáció nélkül; a jelenlegi kód mellett buknia kell).
 *
 * Lefedett követelmények (route-szintű, implementáció-független rögzítés):
 *  - FR-3: "Újraküldés" gomb a hibás pending soron → azonnali, explicit retry a
 *          lokális tétel-azonosítóval, kliens-újraindítás nélkül; siker után a
 *          hibaüzenet eltűnik.
 *  - FR-4: a 👁 (Megtekintés) gomb a tranzakció TÉNYLEGES adatait mutatja
 *          read-only nézetben, nem üres, új felviteli űrlapot.
 *  - FR-6 (kiegészítő ellenőrzés): a megjelenített hibaüzenet-részlet nem
 *          tartalmaz nyers PII-t (e-mail-cím).
 *
 * Az Electron-oldali IPC-t böngészőben egy window.electronAPI stub pótolja
 * (addInitScript), a renderer-szerződést tesztelve:
 *   retryPendingTransaction(lokálisId) → Promise<{ success, error? }>.
 * A stub a GREEN-fázisban szükség szerint bővíthető (teszt-környezeti állvány,
 * nem assertion) — az assertök nem gyengíthetők.
 */
import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 77,
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

const listTransaction = {
  id: 101,
  receiptNumber: 'TX-LIST-001',
  transactionType: 'BUY',
  status: 'COMPLETED',
  transactionDate: '2026-07-29',
  transactionTime: '09:00:00',
  currencyId: 1,
  currencyCode: 'EUR',
  currencyAmount: 100,
  exchangeRate: 400,
  hufAmount: 40000,
  roundedHufAmount: 40000,
  handlingFee: 0,
  discountAmount: 0,
  discountPercent: 0,
  customerName: 'Lista Ügyfél',
  printed: false,
  branchId: 'branch-1',
  workerId: 77,
  createdAt: '2026-07-29T09:00:00',
}

// A helyi (Electron SQLite) hibás pending sor — lokális id: 42, megjelenített
// id: -(1_000_000 + 42) = -1000042 (TransactionListPage PENDING_TX_ID_OFFSET).
const PENDING_DISPLAY_ID = -1000042
const PII_EMAIL = 'kovacs.bela@example.com'
const SYNC_ERROR_WITH_PII = `HTTP 400 — Érvénytelen címzett email: ${PII_EMAIL}`

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['READ', 'WRITE'],
    roles: ['ADMIN'],
  })

  await page.route('**/api/v1/**', async (route) => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const method = route.request().method()

    if (path.endsWith('/auth/login') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          token,
          tokenType: 'Bearer',
          expiresAt: new Date(Date.now() + 3600_000).toISOString(),
          worker,
          activeRole: 'ADMIN',
          permissions: ['READ', 'WRITE'],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
        }),
      })
    }

    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ token }),
      })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(worker),
      })
    }

    if (path.endsWith('/features') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ camera: true, yearOpeningScheduler: true, navIntegration: true }),
      })
    }

    // FR-4: a megtekintett tranzakció lekérése bizonylatszám/id alapján
    // (a transactionApi.getById a /transactions/receipt/{receiptNumber}
    // endpointot hívja — mindkét útvonal-változatot kiszolgáljuk).
    if (
      (path.endsWith('/transactions/receipt/TX-LIST-001') ||
        path.endsWith('/transactions/TX-LIST-001')) &&
      method === 'GET'
    ) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(listTransaction),
      })
    }

    if (path.endsWith('/transactions') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          content: [listTransaction],
          totalElements: 1,
          totalPages: 1,
          size: 25,
          number: 0,
        }),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
  })
}

/**
 * window.electronAPI stub a renderer-szerződés teszteléséhez böngészőben.
 * A retry-hívásokat a window.__fk071RetryCalls tömbben rögzíti; sikeres retry
 * után a pending sor "szinkronizálttá" válik (a következő lekérés üres listát ad).
 */
async function installElectronApiStub(page: Page) {
  await page.addInitScript(
    ({ syncError }) => {
      // FKH-031 NFR-1: a pending sor `created_at`-ja SZÁNDÉKOSAN relatív (2 órája),
      // nem fix dátum. A 7 napos üzleti retry-ablakon (BUSINESS_RETRY_WINDOW_MS)
      // kívül eső tétel felirata már "Kézi beavatkozás kell", nem "Feltöltés hibás",
      // ezért egy hardkódolt dátum egy hét után magától megbuktatta ezt a tesztet
      // (2026-07-29-es fixture → 2026-08-09-i futás = 11 nap). Ez a teszt az FR-3
      // újraküldés-gombot méri, nem az ablak lejáratát: a friss időbélyeg tartja a
      // sort a RETRYING ágon. Az ablak lejáratának fedezete a
      // TransactionListPage.fk071.test.tsx unit tesztjeiben van, ahol az idő mockolt.
      const createdAtMs = Date.now() - 2 * 60 * 60 * 1000
      const createdAtIso = new Date(createdAtMs).toISOString()
      const pendingRow = {
        id: 42,
        type: 'BUY',
        currency_code: 'EUR',
        foreign_amount: 120,
        huf_amount: 48000,
        rounded_huf_amount: 48000,
        rate: 400,
        handling_fee: null,
        discount_percent: null,
        customer_name: null,
        local_reference_number: 'V03500042',
        idempotency_key: 'ikey-42',
        created_at: createdAtIso.replace('T', ' ').slice(0, 19),
        synced: 0,
        sync_error: syncError,
        sync_attempts: 1,
        last_attempt_at: new Date(createdAtMs + 30_000).toISOString(),
      }
      const state = { retriedSuccessfully: false }
      const retryCalls: number[] = []
      ;(window as unknown as { __fk071RetryCalls: number[] }).__fk071RetryCalls = retryCalls
      // A config/token tárolás localStorage-ra épül, hogy a page.goto (teljes
      // reload) utáni session-visszaállítás is működjön Electron-módban.
      ;(window as unknown as { electronAPI: unknown }).electronAPI = {
        getConfig: async (key: string) => window.localStorage.getItem(`__fk071cfg_${key}`),
        setConfig: async (key: string, value: string) => {
          window.localStorage.setItem(`__fk071cfg_${key}`, String(value))
        },
        deleteConfig: async (key: string) => {
          window.localStorage.removeItem(`__fk071cfg_${key}`)
        },
        secureStoreToken: async (token: string) => {
          window.localStorage.setItem('__fk071tok', token)
        },
        secureLoadToken: async () => window.localStorage.getItem('__fk071tok'),
        secureClearToken: async () => {
          window.localStorage.removeItem('__fk071tok')
        },
        getSyncStatus: async () => JSON.stringify({ isRunning: false }),
        getPendingTransactionCount: async () => (state.retriedSuccessfully ? 0 : 1),
        getPendingTransactions: async () => (state.retriedSuccessfully ? [] : [pendingRow]),
        getPendingConversions: async () => [],
        retryPendingTransaction: async (localId: number) => {
          retryCalls.push(localId)
          state.retriedSuccessfully = true
          return { success: true, error: null }
        },
      }
    },
    { syncError: SYNC_ERROR_WITH_PII },
  )
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('ADMIN')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  // Electron-módban (electronAPI stub jelenlétében) a default route eltérhet
  // (/dashboard), böngésző-módban /central-workstation — mindkettő érvényes login.
  await expect(page).toHaveURL(/\/(central-workstation|dashboard)$/)
}

test('FR-4: a 👁 gomb a tranzakció tényleges adatait mutatja read-only nézetben, nem üres űrlapot', async ({
  page,
}) => {
  await mockApis(page)
  await login(page)

  await page.goto('/transactions', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('TX-LIST-001')).toBeVisible()

  // Döntés 2 kiegészítés: web-módban (nincs electronAPI) a COMPLETED sor
  // felirata "Teljesítve" marad, a "Feltöltve" nem jelenhet meg.
  await expect(page.getByText('Teljesítve').first()).toBeVisible()
  await expect(page.getByText('Feltöltve')).toHaveCount(0)

  // A nézetnek a TÉNYLEGES tranzakciót kell betöltenie a :id alapján — erre a
  // requestre horgonyzunk, hogy a React Router lazy-átmenet alatt még látható
  // régi listaoldal ne adhasson hamis zöldet. (Ma ez a request el sem indul.)
  const getByIdRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      /^\/api\/v1\/transactions\/(receipt\/)?TX-LIST-001$/.test(new URL(request.url()).pathname),
    { timeout: 10_000 },
  )

  await page.getByTestId('view-tx-101').click()
  await expect(page).toHaveURL(/\/transactions\/TX-LIST-001$/)
  await getByIdRequest

  // NEM az üres, új tranzakció felviteli űrlap nyílik meg…
  await expect(page.getByText('Billentyűzet használat:')).toHaveCount(0) // felviteli űrlap súgó-doboza
  await expect(page.getByTestId('tx-foreign-amount')).toHaveCount(0) // szerkeszthető összeg-mező
  await expect(page.getByTestId('tx-save-print')).toHaveCount(0) // mentés/rögzítés akció

  // …hanem a tranzakció tényleges adatai láthatók.
  await expect(page.getByText('TX-LIST-001')).toBeVisible() // bizonylatszám
  await expect(page.getByText('EUR').first()).toBeVisible() // deviza
  await expect(page.getByText(/400/).first()).toBeVisible() // árfolyam
  await expect(page.getByText(/2026[-. ]?07[-. ]?29/).first()).toBeVisible() // dátum
  await expect(page.getByText('Lista Ügyfél')).toBeVisible() // ügyfél
})

test('FR-3 + FR-6: Újraküldés gomb a hibás pending soron — explicit retry, siker után eltűnő hibaüzenet, PII nélküli részlet', async ({
  page,
}) => {
  await installElectronApiStub(page)
  await mockApis(page)
  await login(page)

  await page.goto('/transactions', { waitUntil: 'domcontentloaded' })

  // A hibás pending sor látszik a listában.
  await expect(page.getByText('V03500042')).toBeVisible()
  await expect(page.getByText('Feltöltés hibás')).toBeVisible()

  // Döntés 2 kiegészítés: Electron-módban (electronAPI stub aktív) a COMPLETED
  // szerver-sor felirata "Feltöltve".
  await expect(page.getByText('Feltöltve').first()).toBeVisible()
  await expect(page.getByText('Teljesítve')).toHaveCount(0)

  // FR-6: a megjelenített hibaüzenet-részlet nem tartalmaz nyers e-mail-címet.
  const detail = page.getByTestId(`sync-error-detail-${PENDING_DISPLAY_ID}`)
  await expect(detail).toBeVisible()
  const detailContent = await detail.evaluate(
    (el) =>
      `${el.textContent ?? ''} ${el.getAttribute('title') ?? ''} ${el.getAttribute('aria-label') ?? ''}`,
  )
  expect(detailContent).toContain('Érvénytelen címzett email')
  expect(detailContent).not.toContain(PII_EMAIL)

  // FR-3: explicit újraküldés — kliens-újraindítás nélkül, ugyanarra a tételre.
  await page.getByTestId(`retry-tx-${PENDING_DISPLAY_ID}`).click()

  await expect
    .poll(async () =>
      page.evaluate(() => (window as unknown as { __fk071RetryCalls: number[] }).__fk071RetryCalls),
    )
    .toEqual([42])

  // Sikeres újraküldés után a hibaüzenet eltűnik (a sor már nem "Feltöltés hibás").
  await expect(page.getByText('Feltöltés hibás')).toHaveCount(0)
})
