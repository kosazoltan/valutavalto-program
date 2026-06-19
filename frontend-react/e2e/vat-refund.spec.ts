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

const vatRecord = {
  id: 1,
  companyId: 'company-1',
  voucherType: 'AK',
  serialNumber: 'VAT-001',
  transactionDate: '2026-06-19',
  transactionTime: '09:00:00',
  grossAmount: 12700,
  vatAmount: 2700,
  vatPercentage: 27,
  customerName: 'Lista Ügyfél',
  isReversed: false,
  createdAt: '2026-06-19T09:00:00',
}

async function mockVatRefundApis(page: Page) {
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

    if (path === '/api/v1/vat-refund' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([vatRecord]),
      })
    }

    if (path === '/api/v1/vat-refund/daily' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ ...vatRecord, id: 2, serialNumber: 'VAT-DAILY' }]),
      })
    }

    if (path === '/api/v1/vat-refund/1' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...vatRecord, customerName: 'Részlet Ügyfél' }),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ content: [], data: [] }) })
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

test('ÁFA-visszatérítés mobil nézet használja a daily és detail backend szerződést', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockVatRefundApis(page)
  await login(page)

  await page.goto('/treasury/vat', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('VAT-001').first()).toBeVisible()

  const dailyRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/api/v1/vat-refund/daily')
  )
  await page.getByRole('button', { name: 'Mai nap' }).click()
  await dailyRequest
  await expect(page.getByText('VAT-DAILY').first()).toBeVisible()

  await page.goto('/treasury/vat', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('VAT-001').first()).toBeVisible()
  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().endsWith('/api/v1/vat-refund/1')
  )
  await page.locator('button[aria-label="Részletek VAT-001"]').first().click()
  await detailRequest
  await expect(page.getByText('Részlet Ügyfél')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
