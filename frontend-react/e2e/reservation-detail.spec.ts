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
  branchId: '11111111-1111-1111-1111-111111111111',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const reservation = {
  id: 42,
  customerId: 7,
  customerName: 'Teszt Ügyfél',
  branchId: worker.branchId,
  branchName: 'Budapest 01',
  currencyCode: 'EUR',
  reservedAmount: 1000,
  exchangeRate: 385.5,
  depositAmount: 19275,
  status: 'ACTIVE',
  expiresAt: '2099-01-01T10:00:00',
  createdAt: '2026-05-22T08:00:00',
  fulfilledAt: null,
  cancelledAt: null,
  receiptNumber: 'B000042',
  cancellationReason: null,
  refundAmount: null,
  notes: 'Backend részlet megjegyzés',
  expired: false,
}

async function mockReservationApis(page: Page) {
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

    if (path.endsWith('/reservations/reserved-stock') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ currencyCode: 'EUR', reservedAmount: 1000, activeCount: 1 }]),
      })
    }

    if (path.endsWith('/reservations/active') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([reservation]),
      })
    }

    if (path.endsWith('/reservations/42') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(reservation),
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

test('foglaló részlet mobil viewporton backend getById hívásból jelenik meg', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockReservationApis(page)
  await login(page)

  await page.goto('/reservations', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('B000042')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/reservations/42'
  )
  await page.getByRole('button', { name: 'Részletek' }).click()
  await detailRequest

  await expect(page.getByTestId('reservation-detail-panel')).toContainText('Backend részlet megjegyzés')

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
