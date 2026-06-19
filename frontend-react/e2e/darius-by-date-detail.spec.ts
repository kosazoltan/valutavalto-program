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

const dailyReport = {
  id: 'darius-1',
  reportDate: '2026-06-19',
  status: 'GENERATED',
  companyId: 'company-1',
  totalBuyHuf: 100000,
  totalSellHuf: 50000,
  totalHandlingFeeHuf: 1200,
  transactionCount: 3,
  branchCount: 1,
  payloadHash: 'abcdef1234567890abcdef',
  retryCount: 0,
  maxRetries: 3,
  lines: [
    {
      id: 'line-1',
      branchId: 'branch-1',
      branchCode: 'BUD01',
      currencyCode: 'EUR',
      buyCount: 2,
      buyCurrencyAmount: 100,
      buyHufAmount: 40000,
      sellCount: 1,
      sellCurrencyAmount: 50,
      sellHufAmount: 20000,
      avgBuyRate: 400,
      avgSellRate: 410,
      handlingFeeHuf: 1200,
    },
  ],
}

const reportSummary = {
  ...dailyReport,
  payloadHash: undefined,
  lines: undefined,
}

async function mockApis(page: Page) {
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

    if (path.endsWith('/darius/range') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([reportSummary]) })
    }

    if (path.endsWith('/darius/darius-1') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(dailyReport) })
    }

    if (path.endsWith('/darius/by-date') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(dailyReport) })
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

test('DARIUS napi lekérdezés mobil nézetben a backend by-date endpointot használja', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/darius', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('button', { name: /Napi lekérdezés/i })).toBeVisible()

  await page.locator('input[type="date"]').nth(2).fill('2026-06-19')
  const detailRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'GET'
      && url.pathname === '/api/v1/darius/by-date'
      && url.searchParams.get('date') === '2026-06-19'
  })
  await page.getByRole('button', { name: /Napi lekérdezés/i }).click()
  await detailRequest

  await expect(page.getByText('EUR')).toBeVisible()
  await expect(page.getByText('BUD01')).toBeVisible()
  await expect(page.getByText(/abcdef1234567890/)).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})

test('DARIUS listaelem mobil nézetben a backend detail endpointot használja', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/darius', { waitUntil: 'domcontentloaded' })
  await expect(page.getByTestId('darius-report-darius-1')).toBeVisible()

  const detailRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'GET'
      && url.pathname === '/api/v1/darius/darius-1'
  })
  await page.getByTestId('darius-report-darius-1').click()
  await detailRequest

  await expect(page.getByText('EUR')).toBeVisible()
  await expect(page.getByText('BUD01')).toBeVisible()
  await expect(page.getByText(/abcdef1234567890/)).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
