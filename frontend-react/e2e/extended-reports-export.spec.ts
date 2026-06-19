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

    if (path.endsWith('/reports/period/csv') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'text/csv; charset=UTF-8',
        body: '\ufeffDatum;Tranzakcio\n2026-06-18;3\n',
      })
    }

    if (path.endsWith('/reports/period') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          startDate: '2026-06-01',
          endDate: '2026-06-18',
          totalTransactionCount: 3,
          totalBuyHuf: 100000,
          totalSellHuf: 50000,
          totalHandlingFees: 1500,
          dailyBreakdown: [],
        }),
      })
    }

    if (path.endsWith('/reports/transfers') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          startDate: '2026-06-01',
          endDate: '2026-06-18',
          transferCount: 2,
          totalAmountHuf: 750000,
        }),
      })
    }

    if (path.endsWith('/reports/cash-status') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          branchId: 'branch-1',
          branchName: 'Budapest 01',
          reportTime: '2026-06-18T10:00:00',
          balances: [],
          totalHufEquivalent: 250000,
          lowBalanceAlerts: [],
          highBalanceAlerts: [],
        }),
      })
    }

    if (path.endsWith('/reports/today-summary') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          reportDate: '2026-06-18',
          branchId: 'branch-1',
          branchName: 'Budapest 01',
          sessionStatus: 'OPEN',
          openingBalanceHuf: 100000,
          transactionCount: 7,
          buyCount: 4,
          sellCount: 3,
          reversalCount: 1,
          totalBuyHuf: 120000,
          totalSellHuf: 80000,
          totalHandlingFees: 1500,
          currencyTurnovers: [],
        }),
      })
    }

    if (/\/reports\/currency\/1$/.test(path) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          currencyId: 1,
          currencyCode: 'EUR',
          currencyName: 'Euró',
          startDate: '2026-06-01',
          endDate: '2026-06-18',
          totalBuyCount: 2,
          totalSellCount: 1,
          totalBuyAmount: 300,
          totalSellAmount: 120,
          totalBuyHuf: 120000,
          totalSellHuf: 48000,
          averageBuyRate: 400,
          averageSellRate: 405,
        }),
      })
    }

    if (/\/reports\/daily\/[^/]+\/\d{4}-\d{2}-\d{2}\/full$/.test(path) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          reportDate: '2026-06-18',
          branchId: 'branch-1',
          branchName: 'Budapest 01',
          transactionCount: 4,
          closingBalanceHuf: 250000,
        }),
      })
    }

    if (/\/reports\/daily\/[^/]+\/\d{4}-\d{2}-\d{2}\/pdf$/.test(path) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/pdf',
        body: '%PDF-1.4\n% daily report\n',
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

test('kibővített riportok CSV exportja valós Chromium nézetből backend csv endpointot hív', async ({ page }) => {
  await page.setViewportSize({ width: 1366, height: 768 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/extended', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: /Bővített Riportok/i })).toBeVisible()

  await page.getByRole('combobox').selectOption('period-turnover')
  await page.locator('input[type="date"]').nth(0).fill('2026-06-01')
  await page.locator('input[type="date"]').nth(1).fill('2026-06-18')

  const csvRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/reports/period/csv')
  )
  await page.getByRole('button', { name: /CSV export/i }).click()
  await csvRequest

  await page.getByRole('combobox').selectOption('transfer-summary')
  const transferReportRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/reports/transfers')
  )
  await page.getByRole('button', { name: /Riport generálása/i }).click()
  await transferReportRequest
  await expect(page.getByText('transferCount')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})

test('napi zárás teljes riport és PDF export mobil nézetből backend endpointot hív', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/extended', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: /Bővített Riportok/i })).toBeVisible()

  await page.getByRole('combobox').selectOption('daily-full')
  await page.getByTestId('daily-report-branch-id').fill('branch-1')
  await page.getByTestId('daily-report-date').fill('2026-06-18')

  const dailyFullRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/reports/daily/branch-1/2026-06-18/full')
  )
  await page.getByRole('button', { name: /Riport generálása/i }).click()
  await dailyFullRequest
  await expect(page.getByText('Budapest 01')).toBeVisible()

  const pdfRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/reports/daily/branch-1/2026-06-18/pdf')
  )
  await page.getByRole('button', { name: /PDF export/i }).click()
  await pdfRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})

test('kibővített riportok mobil nézetben cash, today és currency read endpointokat hív', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/extended', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: /Bővített Riportok/i })).toBeVisible()

  await page.getByRole('combobox').selectOption('cash-status')
  const cashStatusRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/reports/cash-status')
  )
  await page.getByRole('button', { name: /Riport generálása/i }).click()
  await cashStatusRequest
  await expect(page.getByText('totalHufEquivalent')).toBeVisible()

  await page.getByRole('combobox').selectOption('today-summary')
  const todaySummaryRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/reports/today-summary')
  )
  await page.getByRole('button', { name: /Riport generálása/i }).click()
  await todaySummaryRequest
  await expect(page.getByText('transactionCount')).toBeVisible()

  await page.getByRole('combobox').selectOption('currency-report')
  await page.getByTestId('currency-report-id').fill('1')
  await page.locator('input[type="date"]').nth(0).fill('2026-06-01')
  await page.locator('input[type="date"]').nth(1).fill('2026-06-18')
  const currencyReportRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/reports/currency/1')
  )
  await page.getByRole('button', { name: /Riport generálása/i }).click()
  await currencyReportRequest
  await expect(page.getByText('EUR')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
