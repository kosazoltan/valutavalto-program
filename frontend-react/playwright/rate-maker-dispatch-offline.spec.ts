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

type PublishBehavior = 'business-400' | 'network-error'

async function fulfillJson(route: Route, body: unknown, status = 200) {
  await route.fulfill({ status, contentType: 'application/json', body: JSON.stringify(body) })
}

async function mockApis(page: Page, publishBehavior: PublishBehavior) {
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
    if (path.endsWith('/local-rate-maker/packages/publish') && method === 'POST') {
      if (publishBehavior === 'network-error') return route.abort('connectionrefused')
      return fulfillJson(route, { message: 'Spread-szabály sértés (RateSpreadGate)' }, 400)
    }

    return fulfillJson(route, {})
  })
}

async function loginAndOpenMain(page: Page, publishBehavior: PublishBehavior) {
  await page.setViewportSize({ width: 1440, height: 900 })
  await mockApis(page, publishBehavior)
  await page.goto('/login')
  await page.getByTestId('login-company-code').fill('EBC')
  await page.getByTestId('login-worker-code').fill('ADMIN')
  await page.getByTestId('login-password').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/rates\/main$/)
  await expect(page.getByText('Online (kp. szerver)')).toBeVisible()
}

test('FK09: rate-maker 400-as publish után Online marad, toastot mutat és azonnal újrapróbálható', async ({
  page,
}) => {
  const consoleErrors: string[] = []
  page.on('console', (message) => {
    if (message.type() === 'error') consoleErrors.push(message.text())
  })
  page.on('dialog', (dialog) => void dialog.accept())
  await loginAndOpenMain(page, 'business-400')

  const dispatchButton = page.getByTestId('dispatch-rates-button')
  await dispatchButton.click()

  await expect(page.getByText('Online (kp. szerver)')).toBeVisible()
  await expect(page.getByText('Offline — helyi cache')).toHaveCount(0)
  await expect(page.getByText(/Spread-szabály sértés \(RateSpreadGate\)/)).toBeVisible()
  await expect(dispatchButton).toBeEnabled()

  const toastMessage = page.getByText(/Spread-szabály sértés \(RateSpreadGate\)/)
  const toastContainer = toastMessage.locator('xpath=../..')
  await expect
    .poll(() => toastContainer.evaluate((element) => getComputedStyle(element).transform))
    .toBe('none')
  const [indicatorClipped, buttonClipped, toastClipped, toastBox] = await Promise.all([
    page
      .getByText('Online (kp. szerver)')
      .evaluate((element) =>
        element instanceof HTMLElement
          ? element.scrollWidth > element.clientWidth + 1 ||
            element.scrollHeight > element.clientHeight + 1
          : false,
      ),
    dispatchButton.evaluate(
      (element) =>
        element.scrollWidth > element.clientWidth + 1 ||
        element.scrollHeight > element.clientHeight + 1,
    ),
    toastContainer.evaluate(
      (element) =>
        element.scrollWidth > element.clientWidth + 1 ||
        element.scrollHeight > element.clientHeight + 1,
    ),
    toastContainer.boundingBox(),
  ])
  const viewport = page.viewportSize()
  const layoutHealth = await page.evaluate(() => ({
    viewportOverflow:
      document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  }))
  await page.screenshot({ path: 'test-results/fk09-online-after-400.png' })
  expect(layoutHealth).toEqual({
    viewportOverflow: false,
  })
  expect({ indicatorClipped, buttonClipped, toastClipped }).toEqual({
    indicatorClipped: false,
    buttonClipped: false,
    toastClipped: false,
  })
  expect(toastBox).not.toBeNull()
  expect(viewport).not.toBeNull()
  expect(toastBox!.x).toBeGreaterThanOrEqual(0)
  expect(toastBox!.x + toastBox!.width).toBeLessThanOrEqual(viewport!.width)

  const unexpectedConsoleErrors = consoleErrors.filter(
    (message) =>
      !message.includes('400') &&
      !message.includes('packages/publish') &&
      !message.includes('Failed to load resource'),
  )
  expect(unexpectedConsoleErrors).toEqual([])
})

test('FK09: rate-maker kapcsolatmegszakadás után Offline állapotba vált', async ({ page }) => {
  page.on('dialog', (dialog) => void dialog.accept())
  await loginAndOpenMain(page, 'network-error')

  await page.getByTestId('dispatch-rates-button').click()

  await expect(page.getByText('Offline — helyi cache')).toBeVisible()
})
