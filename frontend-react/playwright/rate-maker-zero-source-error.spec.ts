import { expect, test, type Page, type Route } from '@playwright/test'

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

const currency = {
  id: 1,
  code: 'EUR',
  name: 'Euró',
  symbol: '€',
  decimals: 2,
  displayOrder: 1,
  active: true,
}

const overview = {
  generatedAt: '2026-07-17T10:00:00.000Z',
  currencies: [
    {
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      displayOrder: 1,
      currentBuyRate: 395,
      currentSellRate: 405,
      officialRate: 400,
      limit1Amount: 50000,
      limit1BuyRate: 396,
      limit1SellRate: 404,
      limit2Amount: 300000,
      limit2BuyRate: 397,
      limit2SellRate: 403,
      limit3Amount: 1000000,
      limit3BuyRate: 398,
      limit3SellRate: 402,
      buyMarginPercent: null,
      sellMarginPercent: null,
      spreadPercent: null,
      middleRate: 400,
      lastUpdated: null,
      hasRate: true,
    },
  ],
}

const workgroup = {
  id: 'wg-1',
  code: 'WG01',
  name: 'Budapest központ',
  legacyGroupNumber: 1,
  active: true,
  branches: [],
  limit1Boundary: 50000,
  limit2Boundary: 300000,
  limit3Boundary: 1000000,
  tileColor: 'sky',
  protectionEnabled: false,
}

const masterRate = {
  id: 'rate-1',
  companyId: 'company-1',
  currencyId: 1,
  currencyCode: 'EUR',
  baseBuyRate: 395,
  baseSellRate: 405,
  officialRate: 400,
  status: 'PUBLISHED',
  createdAt: '2026-07-17T10:00:00.000Z',
  isActive: true,
}

async function fulfillJson(route: Route, body: unknown, status = 200) {
  await route.fulfill({ status, contentType: 'application/json', body: JSON.stringify(body) })
}

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['RATE_READ', 'RATE_WRITE'],
    roles: ['ADMIN'],
  })

  await page.route('**/api/v1/**', async (route) => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const method = route.request().method()

    if (path.endsWith('/auth/login') && method === 'POST') {
      return fulfillJson(route, {
        token,
        tokenType: 'Bearer',
        expiresAt: new Date(Date.now() + 3600_000).toISOString(),
        worker,
        activeRole: 'ADMIN',
        permissions: ['RATE_READ', 'RATE_WRITE'],
        roles: ['ADMIN'],
        roleSelectionRequired: false,
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') {
      return fulfillJson(route, {})
    }
    if (path.endsWith('/workers/me') && method === 'GET') return fulfillJson(route, worker)
    if (path.endsWith('/currencies/all') && method === 'GET') {
      return fulfillJson(route, [currency])
    }
    if (path.endsWith('/exchange-rate-master/active') && method === 'GET') {
      return fulfillJson(route, [masterRate])
    }
    if (path.endsWith('/exchange-rates') && method === 'GET') return fulfillJson(route, [])
    if (path.endsWith('/arfolyam-internet-links') && method === 'GET') {
      return fulfillJson(route, [])
    }
    if (path.endsWith('/local-rate-maker/bootstrap') && method === 'GET') {
      return fulfillJson(route, { overview, workgroups: [workgroup] })
    }
    if (path.endsWith('/local-rate-maker/sheet') && method === 'GET') {
      return route.fulfill({ status: 204 })
    }
    if (path.endsWith('/local-rate-maker/sheet') && method === 'PUT') {
      return fulfillJson(route, { version: 1 })
    }

    return fulfillJson(route, {})
  })
}

async function loginAndOpenMain(page: Page) {
  await page.setViewportSize({ width: 1440, height: 900 })
  await mockApis(page)
  const baseUrl = process.env.PLAYWRIGHT_RATE_MAKER_BASE_URL ?? 'http://127.0.0.1:3102'
  await page.goto(`${baseUrl}/login`)
  await page.getByTestId('login-company-code').fill('EBC')
  await page.getByTestId('login-worker-code').fill('ADMIN')
  await page.getByTestId('login-password').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/rates\/main$/)
}

test('FK10: 0-s forrásérték képlethibája látható a munkacsoport-cellán', async ({ page }) => {
  const pageErrors: string[] = []
  page.on('pageerror', (error) => pageErrors.push(error.message))
  await loginAndOpenMain(page)

  const initialLoad = page.waitForResponse(
    (response) =>
      response.url().endsWith('/api/v1/local-rate-maker/bootstrap') &&
      response.request().method() === 'GET',
  )
  await page.getByRole('button', { name: 'CSOPORTOK KARBANTARTÁSA' }).click()
  await expect(page).toHaveURL(/\/rates\/creation$/)
  await initialLoad

  const refreshButton = page.getByTitle('Frissítés')
  const workgroupTile = page.getByRole('button', {
    name: /Budapest központ.*árfolyamlap megnyitása/i,
  })
  await expect(refreshButton).toBeEnabled()
  await expect(workgroupTile).toBeVisible()

  // A Főlap mentése a mockolt 405-ös értéket visszaírhatja; a vizsgált 0-s állapotot rögzítjük,
  // a kezdeti betöltés után, majd a publikus Frissítés úton újratöltjük a képletkontextust.
  await page.evaluate(() => {
    const rows = JSON.parse(localStorage.getItem('arfolyamkeszito.mainSheet.v1') ?? '[]') as Array<{
      weakMultiSell?: number
    }>
    if (rows[0]) rows[0].weakMultiSell = 0
    localStorage.setItem('arfolyamkeszito.mainSheet.v1', JSON.stringify(rows))
    localStorage.setItem(
      'arfolyamkeszito.workgroupSheet.formulas.v1.wg-1',
      JSON.stringify({ '1.sellRate': 'F' }),
    )
  })
  const refreshed = page.waitForResponse(
    (response) =>
      response.url().endsWith('/api/v1/local-rate-maker/bootstrap') &&
      response.request().method() === 'GET',
  )
  await refreshButton.click()
  await refreshed
  await expect(refreshButton).toBeEnabled()
  await workgroupTile.click()

  const cell = page.locator('input[title*="HIBA: Nincs érték a 0-s lap F oszlopában"]')
  await expect(cell).toBeVisible()
  await expect(cell).not.toHaveValue('')
  expect(pageErrors).toEqual([])
})
