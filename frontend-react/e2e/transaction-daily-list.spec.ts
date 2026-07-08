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
  transactionDate: '2026-06-17',
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
  createdAt: '2026-06-17T09:00:00',
}

const dailyTransaction = {
  ...listTransaction,
  id: 202,
  receiptNumber: 'TX-DAILY-001',
  transactionDate: '2026-06-19',
  transactionTime: '10:15:00',
  customerName: 'Mai Ügyfél',
}

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

    if (path.endsWith('/transactions/daily') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([dailyTransaction]),
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

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('ADMIN')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/central-workstation$/)
}

test('tranzakció lista mobil nézetben backend napi tranzakciókat kér', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/transactions', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('TX-LIST-001')).toBeVisible()

  const dailyRequest = page.waitForRequest((request) => {
    const url = new URL(request.url())
    return request.method() === 'GET' && url.pathname === '/api/v1/transactions/daily'
  })
  await page.getByRole('button', { name: /Mai tranzakciók/i }).click()
  await dailyRequest

  await expect(page.getByText('TX-DAILY-001')).toBeVisible()
  await expect(page.getByText('Mai Ügyfél')).toBeVisible()
  await expect(page.getByText('TX-LIST-001')).not.toBeVisible()

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
