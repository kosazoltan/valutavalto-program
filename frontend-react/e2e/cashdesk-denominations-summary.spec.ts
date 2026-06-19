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
  branchId: 'cashdesk-1',
  branchCode: 'SZEGED',
  branchName: 'Szeged pénztár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

async function mockDenominationApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['READ', 'WRITE'],
    roles: ['ADMIN'],
  })

  await page.route('**/api/v1/**', async route => {
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
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ token }) })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(worker) })
    }

    const bodies: Record<string, unknown> = {
      '/api/v1/currencies': [
        { id: 1, code: 'EUR', name: 'Euró', decimals: 2, active: true },
      ],
      '/api/v1/denominations/currency/1': [
        { id: 10, currencyId: 1, currencyCode: 'EUR', faceValue: 50, denominationType: 'BANKNOTE', active: true },
        { id: 11, currencyId: 1, currencyCode: 'EUR', faceValue: 20, denominationType: 'BANKNOTE', active: true },
      ],
      '/api/v1/denominations': [
        { id: 10, currencyId: 1, currencyCode: 'EUR', faceValue: 50, denominationType: 'BANKNOTE', quantity: 0, active: true },
        { id: 11, currencyId: 1, currencyCode: 'EUR', faceValue: 20, denominationType: 'BANKNOTE', quantity: 0, active: true },
      ],
      '/api/v1/denominations/code/EUR': [
        { id: 10, currencyId: 1, currencyCode: 'EUR', faceValue: 50, denominationType: 'BANKNOTE', quantity: 0, active: true },
        { id: 11, currencyId: 1, currencyCode: 'EUR', faceValue: 20, denominationType: 'BANKNOTE', quantity: 0, active: true },
      ],
      '/api/v1/denominations/alerts/low-stock': [
        { id: 11, currencyId: 1, currencyCode: 'EUR', faceValue: 20, denominationType: 'BANKNOTE', quantity: 1, active: true },
      ],
      '/api/v1/denominations/summary/1': {
        currencyId: 1,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        totalValue: 120,
        banknoteCount: 2,
        coinCount: 0,
        denominationCount: 2,
      },
      '/api/v1/cash-desks/cashdesk-1/denominations': [
        { denominationId: '10', currencyCode: 'EUR', quantity: 2, totalValue: 100 },
        { denominationId: '11', currencyCode: 'EUR', quantity: 1, totalValue: 20 },
      ],
      '/api/v1/cash-desks/cashdesk-1/denominations/currency/1': [
        { denominationId: '10', currencyCode: 'EUR', quantity: 2, totalValue: 100 },
        { denominationId: '11', currencyCode: 'EUR', quantity: 1, totalValue: 20 },
      ],
      '/api/v1/cash-desks/cashdesk-1/denominations/currency/1/total': 120,
      '/api/v1/admin/denomination/optimizations': [],
      '/api/v1/admin/denomination/rules': [],
    }

    const body = bodies[path]
    if (body !== undefined) {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(body) })
    }

    if (path.endsWith('/denominations/optimal-change') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ 50: 2, 20: 1, 10: 1 }),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
  })
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('ADMIN')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/central-workstation$/)
}

test('címletezés mobil viewporton használja az összes címlet és total endpointokat', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockDenominationApis(page)
  await login(page)

  const allRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/cash-desks/cashdesk-1/denominations'
  )
  const totalRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/cash-desks/cashdesk-1/denominations/currency/1/total'
  )
  const lowStockRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/denominations/alerts/low-stock'
  )
  const codeRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/denominations/code/EUR'
  )
  await page.goto('/cashdesk/denominations', { waitUntil: 'domcontentloaded' })
  await allRequest
  await totalRequest
  await lowStockRequest
  await codeRequest

  await expect(page.getByText('Mentett:')).toBeVisible()
  await expect(page.getByText('120,00', { exact: true }).first()).toBeVisible()
  await expect(page.getByText('Sorok:')).toBeVisible()
  await expect(page.getByText('Alacsony készlet:')).toBeVisible()
  await expect(page.getByText('Kód ellenőrzés:')).toBeVisible()
  await expect(page.getByText('50 EUR')).toBeVisible()

  const optimalRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/denominations/optimal-change'
    && new URL(request.url()).searchParams.get('amount') === '130'
  )
  await page.getByPlaceholder('Összeg EUR').fill('130')
  await page.getByRole('button', { name: /Optimális visszajáró/ }).click()
  await optimalRequest
  await expect(page.getByText(/50,00 x 2/)).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
