import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 77,
  workerCode: 'FOERTEKTAR',
  firstName: 'Főértéktáros',
  lastName: 'Teszt',
  fullName: 'Főértéktáros Teszt',
  role: 'FOERTEKTAR',
  branchId: 'branch-123',
  branchCode: 'SZEGED',
  branchName: 'Szeged Iroda',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const GROUPS = [
  { groupCode: 'BEKESCSABA', groupName: 'BEKESCSABA', groupType: 'REGION' },
  { groupCode: 'DEBRECEN', groupName: 'DEBRECEN', groupType: 'REGION' },
  { groupCode: 'GYOR', groupName: 'GYOR', groupType: 'REGION' },
  { groupCode: 'MISKOLC', groupName: 'MISKOLC', groupType: 'REGION' },
  { groupCode: 'PECS', groupName: 'PECS', groupType: 'REGION' },
  { groupCode: 'SZEGED', groupName: 'SZEGED', groupType: 'REGION' },
  { groupCode: 'SZOLNOK', groupName: 'SZOLNOK', groupType: 'REGION' },
  { groupCode: 'BUDAPEST', groupName: 'BUDAPEST', groupType: 'REGION' },
  { groupCode: 'total', groupName: 'EXCLUSIVE BEST CHANGE ZRT', groupType: 'TOTAL' },
] as const

// 30 valuta-sor (>= 15): 1280×720-nál biztos függőleges túlcsordulás kell a sticky
// thead-méréshez (scrollTop = 400 csak akkor éri el a ragadást, ha a tartalom elég hosszú).
const CURRENCIES = [
  'EUR',
  'USD',
  'GBP',
  'CHF',
  'JPY',
  'SEK',
  'NOK',
  'DKK',
  'PLN',
  'CZK',
  'RON',
  'BGN',
  'RSD',
  'UAH',
  'TRY',
  'CAD',
  'AUD',
  'NZD',
  'ILS',
  'MDL',
  'MKD',
  'BAM',
  'ISK',
  'INR',
  'CNY',
  'KRW',
  'MXN',
  'BRL',
  'ZAR',
  'HRK',
]

function buildPivot() {
  const currencyRows = CURRENCIES.map((currencyCode, index) => {
    const values: Record<string, unknown> = {}
    for (const group of GROUPS) {
      values[group.groupCode] = {
        buyAvgRate: 400 + index,
        buySumAmount: 1000 * (index + 1),
        sellAvgRate: 410 + index,
        sellSumAmount: 800 * (index + 1),
      }
    }
    return { currencyCode, values }
  })
  return {
    periodStart: '2026-06-01',
    periodEnd: '2026-06-30',
    columnGroups: GROUPS.map((g) => ({ ...g })),
    currencyRows,
  }
}

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'FOERTEKTAR',
    permissions: ['READ'],
    roles: ['FOERTEKTAR'],
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
          activeRole: 'FOERTEKTAR',
          permissions: ['READ'],
          roles: ['FOERTEKTAR'],
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

    if (
      path.endsWith('/branches') &&
      method === 'GET' &&
      url.searchParams.get('activeOnly') === 'true'
    ) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'branch-123', code: 'SZEGED', name: 'Szeged Iroda', active: true, isVault: false },
          { id: 'branch-999', code: 'VAULT', name: 'Központi értéktár', active: true, isVault: true },
        ]),
      })
    }

    if (path.endsWith('/reports/average-rate/pivot') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(buildPivot()),
      })
    }

    if (path.endsWith('/reports/average-rate') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([]),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
  })
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('FOERTEKTAR')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/central-workstation$/)
}

test('FK-094 átlag árfolyam sticky VALUTA oszlop és fejléc görgetés közben is a helyén marad', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 720 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/average-rate', { waitUntil: 'domcontentloaded' })

  // FK-094 FR-1/2: a látható export-tájékoztató lekérdezés nélkül is megjelenik.
  await expect(page.getByTestId('average-rate-export-notice')).toBeVisible()

  // FK-094 FR-3/4: az értéktári fiók nem szerepel az Iroda listában.
  await expect(page.getByRole('option', { name: /Központi értéktár/ })).toHaveCount(0)

  await page.getByRole('button', { name: /Lekérdezés/i }).click()
  await expect(page.getByTestId('pivot-table')).toBeVisible()

  // Vízszintes sticky: a VALUTA oszlop képernyő-pozíciója két különböző görgetési
  // ponton is azonos — ha a ragadás működik, a ragasztott pozíció nem mozdul el.
  // (Egyetlen mérés a scrollLeft=0 állapothoz képest hamis eltérést adna: a táblázat
  // természetes bal széle 13 px-szel beljebb van, mint a ragadt pozíció.)
  const valutaTh = page.getByRole('columnheader', { name: 'Valuta' })
  await page.evaluate(() => {
    document.querySelector('.app-print-content')!.scrollLeft = 200
  })
  await expect
    .poll(async () =>
      page.evaluate(() => document.querySelector('.app-print-content')!.scrollLeft),
    )
    .toBeGreaterThan(0)
  const xAt200 = (await valutaTh.boundingBox())!.x
  await page.evaluate(() => {
    document.querySelector('.app-print-content')!.scrollLeft = 800
  })
  await expect
    .poll(async () =>
      page.evaluate(() => document.querySelector('.app-print-content')!.scrollLeft),
    )
    .toBe(800)
  const xAt800 = (await valutaTh.boundingBox())!.x
  expect(Math.abs(xAt800 - xAt200)).toBeLessThanOrEqual(1)

  // Függőleges sticky: a kétsoros fejléc a konténer tetején ragad görgetésnél.
  // A konténer p-3 paddinggal bír, ezért a ragadt thead a content-box tetején áll meg
  // (containerTop + paddingTop); a puszta containerTop-hoz mérés hamis hibát adna.
  await page.evaluate(() => {
    const container = document.querySelector('.app-print-content')!
    container.scrollLeft = 0
    container.scrollTop = 400
  })
  await expect
    .poll(async () =>
      page.evaluate(() => document.querySelector('.app-print-content')!.scrollTop),
    )
    .toBeGreaterThan(0)
  const theadTop = (await page.getByTestId('pivot-table').locator('thead').boundingBox())!.y
  const containerTopInfo = await page.evaluate(() => {
    const container = document.querySelector('.app-print-content')!
    const rect = container.getBoundingClientRect()
    return { top: rect.top, paddingTop: parseFloat(getComputedStyle(container).paddingTop) }
  })
  expect(Math.abs(theadTop - (containerTopInfo.top + containerTopInfo.paddingTop))).toBeLessThanOrEqual(2)

  // Nincs oldal-szintű vízszintes túlcsordulás (a görgetés a konténeren belül marad).
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(overflow).toBe(false)
})
