import { expect, test, type Page } from '@playwright/test'

// FK-041: read-only (értéktár) árfolyam-nézet — a TERÜLET munkacsoportonkénti árfolyam-variánsai.
// A főértéktáros a területen belül a pénztáraknak ELTÉRŐ árfolyamot/kedvezményt ad (munkacsoportokba
// sorolva); az értéktáros itt valutánként látja az összes variánst a pénztárnevekkel a címsorban,
// alap vétel/eladás + kedvezmény-sávokkal.
//
// Render-feltétel: canEdit = appMode==='full' && hasCanonicalRole(['foertektar','ugyvezeto']).
// Az ERTEKTAR a saját Electron ertektar-módjában (appMode!=='full') látja → canEdit=false. A böngészős
// dev szerver 'full' (Szerver) módban fut és elutasítja az ERTEKTAR szerepkört, ezért itt egy
// Szerver-módban ÉRVÉNYES, de NEM-szerkesztő szerepkörrel (irodavezeto) váltjuk ki ugyanazt a
// canEdit=false render-útvonalat — a territory-tábla DOM-ja azonos azzal, amit az értéktáros lát.
// (Az 'arfolyam_nezo'-t FK-041/II óta a RatesPage guard átirányítja, ezért NEM jó proxinak ide.)

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

// 'irodavezeto': Szerver-módban ÉRVÉNYES szerepkör (SERVER_ALLOWED_CANONICAL_ROLES), de NEM szerkesztő
// (nem foertektar/ugyvezeto) és NEM árfolyam néző → canEdit=false, nincs redirect → territory nézet renderel.
const worker = {
  id: 88,
  workerCode: 'IRV1',
  firstName: 'Iroda',
  lastName: 'Vezető',
  fullName: 'Iroda Vezető',
  role: 'irodavezeto',
  branchId: 'branch-szeged',
  branchCode: 'BR-SZEGED',
  branchName: 'Tisza Sarok',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const eurUsd = (buy1: number, sell1: number, buy2: number, sell2: number, withBands: boolean) => [
  {
    currencyId: 1,
    currencyCode: 'EUR',
    currencyName: 'Euró',
    hasRate: true,
    baseBuyRate: buy1,
    baseSellRate: sell1,
    officialRate: 352.68,
    limit1Amount: withBands ? 50000 : null,
    limit1BuyRate: withBands ? buy1 + 0.5 : null,
    limit1SellRate: withBands ? sell1 - 0.5 : null,
    limit2Amount: withBands ? 300000 : null,
    limit2BuyRate: withBands ? buy1 + 1 : null,
    limit2SellRate: withBands ? sell1 - 1 : null,
    limit3Amount: null,
    limit3BuyRate: null,
    limit3SellRate: null,
    validTime: '15:12',
  },
  {
    currencyId: 2,
    currencyCode: 'USD',
    currencyName: 'US dollár',
    hasRate: true,
    baseBuyRate: buy2,
    baseSellRate: sell2,
    officialRate: 307.56,
    limit1Amount: null,
    limit1BuyRate: null,
    limit1SellRate: null,
    limit2Amount: null,
    limit2BuyRate: null,
    limit2SellRate: null,
    limit3Amount: null,
    limit3BuyRate: null,
    limit3SellRate: null,
    validTime: '15:12',
  },
]

const territoryGroups = [
  {
    workgroupId: 'wg-belvaros',
    workgroupCode: 'WG01',
    workgroupName: 'Belváros',
    tileColor: 'blue',
    branchNames: ['Árkád', 'Tisza Sarok'],
    limit1Boundary: 50000,
    limit2Boundary: 300000,
    limit3Boundary: 1000000,
    currencies: eurUsd(343.0, 362.99, 299.0, 315.5, true),
  },
  {
    workgroupId: 'wg-plazak',
    workgroupCode: 'WG02',
    workgroupName: 'Plázák',
    tileColor: 'amber',
    branchNames: ['Móra', 'Szentes Tesco', 'Tesco'],
    limit1Boundary: 50000,
    limit2Boundary: 300000,
    limit3Boundary: 1000000,
    currencies: eurUsd(341.5, 364.5, 297.5, 317.0, false),
  },
]

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'irodavezeto',
    permissions: ['READ'],
    roles: ['irodavezeto'],
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
          activeRole: 'irodavezeto',
          permissions: ['READ'],
          roles: ['irodavezeto'],
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
    // FK-041: a területi munkacsoport-árfolyamok — a catch-all handlerben kezeljük, hogy ne kelljen
    // route-precedenciára hagyatkozni.
    if (path.endsWith('/rate-creation/territory-workgroup-rates') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(territoryGroups),
      })
    }
    // currencies, exchange-rates és minden egyéb → üres lista (a territory nézet ezektől független)
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
  })
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('IRV1')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  // Bejelentkezés után elnavigál a /login-ról (a cél role-függő — nem kötjük konkrét útvonalhoz).
  await page.waitForURL((url) => !url.pathname.endsWith('/login'))
}

test('FK-041: read-only értéktár — territory munkacsoport-árfolyam nézet (Chromium)', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 900 })

  await mockApis(page)
  page.on('dialog', (dialog) => void dialog.accept())
  await login(page)

  await page.goto('/rates', { waitUntil: 'domcontentloaded' })

  const table = page.getByTestId('rates-territory-table')
  await expect(table).toBeVisible()

  // Munkacsoport-variánsok a címsorban + a hozzájuk tartozó pénztárnevek.
  await expect(table.getByText('Belváros')).toBeVisible()
  await expect(table.getByText('Plázák')).toBeVisible()
  await expect(table.getByText(/Tisza Sarok/)).toBeVisible()
  await expect(table.getByText(/Tesco/)).toBeVisible()

  // Valuták + a két variáns ELTÉRŐ alap árfolyama. (exact, mert az „EUR" substringként az „Euró"-ban is benne van.)
  await expect(table.getByText('EUR', { exact: true })).toBeVisible()
  await expect(table.getByText('USD', { exact: true })).toBeVisible()
  await expect(table.getByText(/343[.,]00/).first()).toBeVisible()
  await expect(table.getByText(/341[.,]50/).first()).toBeVisible()

  // Szerkesztő-eszközök NEM jelennek meg a read-only nézetben.
  await expect(page.getByText('Árfolyam kalkulátor')).toHaveCount(0)
  await expect(page.getByTestId('rate-polling-control-panel')).toHaveCount(0)

  // Vizuális bizonyíték a validációhoz.
  await page.screenshot({ path: 'test-results/fk041-territory-rates.png', fullPage: false })
})
