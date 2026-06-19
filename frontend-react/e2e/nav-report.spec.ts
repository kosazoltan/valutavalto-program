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

    if (path.endsWith('/nav-reports/daily') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          date: '2026-06-18',
          reportableTransactionCount: 1,
          totalAmountHuf: 2_500_000,
          transactions: [],
        }),
      })
    }

    if (path.endsWith('/nav-reports/reportable') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            transactionId: 101,
            receiptNumber: 'NAV-001',
            transactionType: 'BUY',
            transactionDate: '2026-06-18',
            transactionTime: '10:15:00',
            currencyCode: 'EUR',
            currencyAmount: 6000,
            exchangeRate: 410,
            hufAmount: 2_460_000,
            customerId: 'customer-1',
            customerName: 'Teszt Ügyfél',
            customerAddress: 'Szeged',
            customerDocumentNumber: 'AB123456',
          },
        ]),
      })
    }

    if (path.endsWith('/nav/closings') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          content: [
            {
              id: 'closing-1',
              closingDate: '2026-06-18',
              totalRevenue: 1_250_000,
              status: 'OPEN',
            },
          ],
        }),
      })
    }

    if (path.endsWith('/nav/closings/closing-1/summary') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          totalRevenue: 1_250_000,
          handlingFeeTotal: 50_000,
          vatAmount: 13_500,
          transactionCount: 3,
        }),
      })
    }

    if (path.endsWith('/nav/closings/ptgszlah/monthly') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/xml',
        body: '<ptgszlah type="monthly" />',
      })
    }

    if (path.endsWith('/nav/closings/ptgszlah/custom') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/xml',
        body: '<ptgszlah type="custom" />',
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

test('NAV riport oldal a reportable backend listavégpontot is hívja', async ({ page }) => {
  await page.setViewportSize({ width: 1366, height: 768 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/nav', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: /NAV adatszolgáltatás/i })).toBeVisible()
  await page.locator('input[type="date"]').fill('2026-06-18')

  const reportableRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/nav-reports/reportable')
  )
  await page.getByRole('button', { name: /Lekérdezés/i }).click()
  await reportableRequest
  await expect(page.getByText('NAV-001')).toBeVisible()
  await expect(page.getByTestId('nav-closing-panel')).toBeVisible()
  await expect(page.getByText('OPEN')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})

test('NAV riport mobil nézetben is kezeli a zárás összesítőt és XML exportokat', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/nav', { waitUntil: 'domcontentloaded' })
  await page.locator('input[type="date"]').fill('2026-06-18')

  const closingsRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/nav/closings?')
  )
  await page.getByRole('button', { name: /Lekérdezés/i }).click()
  await closingsRequest

  await expect(page.getByTestId('nav-closing-panel')).toBeVisible()
  await expect(page.getByText('NAV zárások')).toBeVisible()

  const summaryRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/nav/closings/closing-1/summary')
  )
  await page.getByRole('button', { name: /Zárás összesítő/i }).click()
  await summaryRequest
  await expect(page.getByText('Összes bevétel')).toBeVisible()

  const monthlyExport = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/nav/closings/ptgszlah/monthly')
  )
  await page.getByRole('button', { name: /PTGSZLAH havi XML/i }).click()
  await monthlyExport

  const customExport = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/nav/closings/ptgszlah/custom')
  )
  await page.getByRole('button', { name: /PTGSZLAH napi XML/i }).click()
  await customExport

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
