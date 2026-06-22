import { expect, test, type Page } from '@playwright/test'

// FK-040 — Országos készlet (CashierStocksPage) mód-függő nézet vizuális ellenőrzése (FR-6).
// Full (főértéktár) módban a felső táblázatos részlet REJTVE (csak összesítő sáv + kártyák); ertektar
// módban a felső táblázat is látszik. A böngészős dev szerver alapból 'full'; az ertektar nézetet a
// session app-mode override (vv_session_app_mode = 'ertektar') váltja ki — a useAppMode ezt elsőbbséggel olvassa.

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 7,
  workerCode: 'FOERT1',
  firstName: 'Fő',
  lastName: 'Értéktáros',
  fullName: 'Fő Értéktáros',
  role: 'foertektar',
  branchId: 'branch-szeged-vault',
  branchCode: 'BR-SZEGED-V',
  branchName: 'Szeged Értéktár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const CURRENCIES = [
  { id: 1, code: 'HUF', name: 'Magyar forint', decimals: 0, displayOrder: 0, active: true },
  { id: 2, code: 'EUR', name: 'Euró', decimals: 2, displayOrder: 8, active: true },
  { id: 3, code: 'USD', name: 'US dollár', decimals: 2, displayOrder: 21, active: true },
]
const STOCK = [
  {
    id: 's1',
    branchId: 'branch-tisza',
    branchName: 'Tisza Sarok',
    currencyCode: 'EUR',
    currentBalance: 40674,
  },
  {
    id: 's2',
    branchId: 'branch-tisza',
    branchName: 'Tisza Sarok',
    currencyCode: 'USD',
    currentBalance: 35858,
  },
  {
    id: 's3',
    branchId: 'branch-szeged-vault',
    branchName: 'Szeged Értéktár',
    currencyCode: 'HUF',
    currentBalance: 165000000,
  },
]
const BRANCHES = [
  {
    id: 'branch-tisza',
    name: 'Tisza Sarok',
    region: 'SZEGED',
    isVault: false,
    vaultTerritoryId: 1,
  },
  {
    id: 'branch-szeged-vault',
    name: 'Szeged Értéktár',
    region: 'SZEGED',
    isVault: true,
    vaultTerritoryId: 1,
  },
]

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'foertektar',
    permissions: ['READ'],
    roles: ['foertektar'],
  })
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
        worker,
        activeRole: 'foertektar',
        permissions: ['READ'],
        roles: ['foertektar'],
        roleSelectionRequired: false,
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') return json({ token })
    if (path.endsWith('/workers/me') && method === 'GET') return json(worker)
    if (path.endsWith('/inventory/stock')) return json(STOCK)
    if (path.endsWith('/inventory/vault-stock')) return json([])
    if (path.endsWith('/inventory-movements/movement-log')) return json([])
    if (path.endsWith('/currencies')) return json(CURRENCIES)
    if (path.endsWith('/branches/my-territory')) return json(BRANCHES)
    if (path.endsWith('/branches')) return json(BRANCHES)
    if (path.endsWith('/exchange-rates')) return json([])
    return json([])
  })
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('FOERT1')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await page.waitForURL((url) => !url.pathname.endsWith('/login'))
}

test('FK-040: full (főértéktár) módban a felső táblázat REJTVE, csak az összesítő sáv + kártyák (Chromium)', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1920, height: 1080 })
  await mockApis(page)
  page.on('dialog', (dialog) => void dialog.accept())
  await login(page)

  await page.goto('/cashier-stocks', { waitUntil: 'domcontentloaded' })

  // A kártyás Országos készlet nézet betölt (FR-3).
  await expect(page.getByTestId('branch-card').first()).toBeVisible()
  // FR-1: a felső táblázatos részlet (fejléc + Körzet összesen legördülő) NEM látszik full módban.
  await expect(page.getByText('Részletes pénztári készlet')).toHaveCount(0)
  await expect(page.getByText('Körzet összesen')).toHaveCount(0)
  // FR-2: az összesítő sáv látszik.
  await expect(page.getByTestId('inventory-summary-bar')).toBeVisible()

  await page.screenshot({ path: 'test-results/fk040-orszagos-keszlet-full.png', fullPage: false })
})

test('FK-040: ertektar módban a felső táblázat is LÁTSZIK (regresszió, Chromium)', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1920, height: 1080 })
  await mockApis(page)
  page.on('dialog', (dialog) => void dialog.accept())
  await login(page)

  // Session app-mode override → useAppMode 'ertektar'-t ad vissza (böngészőben is, elsőbbséggel).
  await page.evaluate(() => sessionStorage.setItem('vv_session_app_mode', 'ertektar'))
  await page.goto('/cashier-stocks', { waitUntil: 'domcontentloaded' })

  // A felső táblázatos részlet (fejléc + Pénztár legördülő) látszik ertektar módban.
  await expect(page.getByText('Részletes pénztári készlet')).toBeVisible()
  await expect(page.getByRole('combobox')).toBeVisible()
  await expect(page.getByRole('option', { name: 'Körzet összesen' })).toHaveCount(1)
  await expect(page.getByTestId('inventory-summary-bar')).toBeVisible()
  await expect(page.getByTestId('branch-card').first()).toBeVisible()

  await page.screenshot({
    path: 'test-results/fk040-orszagos-keszlet-ertektar.png',
    fullPage: false,
  })
})
