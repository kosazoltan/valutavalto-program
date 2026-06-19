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

async function mockTransactionApis(page: Page) {
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

    if (path.endsWith('/transactions') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          content: [
            {
              id: 42,
              receiptNumber: 'E001000042',
              transactionType: 'BUY',
              status: 'COMPLETED',
              transactionDate: '2026-06-18',
              transactionTime: '10:00:00',
              currencyId: 1,
              currencyCode: 'EUR',
              currencyAmount: 500,
              exchangeRate: 391.5,
              hufAmount: 195750,
              roundedHufAmount: 195750,
              handlingFee: 0,
              discountAmount: 0,
              discountPercent: 0,
              customerName: 'Teszt Elek',
              printed: false,
              branchId: 'branch-1',
              workerId: 77,
              createdAt: '2026-06-18T10:00:00',
            },
          ],
          totalElements: 1,
          totalPages: 1,
          size: 25,
          number: 0,
        }),
      })
    }

    if (path.endsWith('/receipts/transaction/42/pdf') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/pdf',
        body: Buffer.from('%PDF-1.4\n%teszt\n'),
      })
    }

    if (path.endsWith('/receipts/transaction/42/escpos') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/octet-stream',
        body: Buffer.from('ESC/POS'),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ content: [], data: [], total: 0 }) })
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

test('tranzakció lista bizonylat PDF és ESC/POS letöltése backend receipt endpointokat hív', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockTransactionApis(page)
  await login(page)

  await page.goto('/transactions', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('E001000042')).toBeVisible()

  const pdfRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/receipts/transaction/42/pdf')
  )
  await page.getByTestId('receipt-pdf-tx-42').click()
  await pdfRequest

  const escposRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/receipts/transaction/42/escpos')
  )
  await page.getByTestId('receipt-escpos-tx-42').click()
  await escposRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
