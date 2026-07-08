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

async function mockTreasuryApis(page: Page) {
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

    if (
      path.match(
        /\/api\/v1\/ertektar\/(collections|distribution|bank-transactions)\/\d+\/status$/,
      ) &&
      method === 'PATCH'
    ) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ id: 11, status: url.searchParams.get('status') ?? 'COMPLETED' }),
      })
    }

    const bodies: Record<string, unknown> = {
      '/api/v1/transactions/daily-turnover': {
        totalBuyCount: 8,
        totalSellCount: 9,
        totalBuyHuf: 800000,
        totalSellHuf: 900000,
        totalHandlingFees: 25000,
      },
      '/api/v1/cash-balances/company': [
        {
          id: 1,
          branchId: 'branch-1',
          branchName: 'Szeged',
          currencyId: 1,
          currencyCode: 'EUR',
          currentBalance: 100,
          openingBalance: 0,
        },
      ],
      '/api/v1/cash-balances/company-position': {
        companyId: 'company-1',
        timestamp: '2026-06-19T08:00:00',
        currencyPositions: [
          { currencyCode: 'EUR', totalBalance: 100, branchCount: 1, hufValue: 40000 },
        ],
        grandTotalHuf: 1235000,
      },
      '/api/v1/cash-balances/company-totals': [
        {
          currencyId: 1,
          currencyCode: 'EUR',
          currencyName: 'Euró',
          totalBalance: 1000,
          branchCount: 2,
        },
        {
          currencyId: 2,
          currencyCode: 'USD',
          currencyName: 'Dollár',
          totalBalance: 500,
          branchCount: 1,
        },
      ],
      '/api/v1/cash-balances/alerts/low': [
        {
          id: 3,
          branchId: 'branch-2',
          branchName: 'Pécs',
          currencyId: 1,
          currencyCode: 'EUR',
          currentBalance: 2,
          openingBalance: 0,
        },
      ],
      '/api/v1/cash-balances/alerts/high': [
        {
          id: 4,
          branchId: 'branch-1',
          branchName: 'Szeged',
          currencyId: 2,
          currencyCode: 'USD',
          currentBalance: 9999,
          openingBalance: 0,
        },
      ],
      '/api/v1/treasury/dashboard': {
        totalProfit: 25000,
        totalTransactionCount: 17,
        branchCount: 2,
        currencyTotals: {},
      },
      '/api/v1/treasury/branch-comparison': [
        {
          branchId: 'branch-1',
          branchCode: 'SZEGED',
          branchName: 'Szeged',
          totalProfit: 25000,
          transactionCount: 17,
        },
      ],
      '/api/v1/treasury/submission-status': [
        { branchId: 'branch-1', branchCode: 'SZEGED', branchName: 'Szeged', submitted: true },
        { branchId: 'branch-2', branchCode: 'PECS', branchName: 'Pécs', submitted: false },
      ],
      '/api/v1/treasury/bank-flow': [
        {
          currencyCode: 'EUR',
          currencyName: 'Euró',
          totalWithdraw: 2000000,
          totalDeposit: 500000,
          netFlow: 1500000,
        },
      ],
      '/api/v1/treasury/branch-group-summary': [
        {
          id: 'group-1',
          code: 'DEL',
          name: 'Dél',
          totalProfit: 25000,
          transactionCount: 17,
          branchCount: 2,
        },
      ],
      '/api/v1/treasury/company-summary': [
        {
          id: 'company-1',
          code: 'EBC',
          name: 'EBC',
          totalProfit: 50000,
          transactionCount: 30,
          branchCount: 2,
        },
      ],
      '/api/v1/ertektar/branches': {
        'branch-1': {
          branchId: 'branch-1',
          isOnline: true,
          dailyTransactionCount: 12,
          dailyVolumeHuf: 1200000,
          openAlerts: 0,
        },
        'branch-2': {
          branchId: 'branch-2',
          isOnline: false,
          dailyTransactionCount: 3,
          dailyVolumeHuf: 250000,
          openAlerts: 1,
        },
      },
      '/api/v1/ertektar/reports/consolidated': {
        dateFrom: '2026-06-01',
        dateTo: '2026-06-19',
        branches: [
          {
            branchCode: 'SZEGED',
            branchName: 'Szeged',
            totalTransactions: 17,
            totalHufTurnover: 1700000,
            totalFees: 25000,
          },
        ],
        totals: {
          totalTransactions: 17,
          totalSellCount: 8,
          totalBuyCount: 9,
          totalHufTurnover: 1700000,
          totalFees: 25000,
        },
      },
      '/api/v1/ertektar/collections': [
        {
          id: 11,
          sourceBranchCode: 'SZEGED',
          sourceBranchName: 'Szeged',
          currencyCode: 'EUR',
          amount: 1200,
          status: 'REQUESTED',
        },
      ],
      '/api/v1/ertektar/distribution': [
        {
          id: 12,
          status: 'IN_PROGRESS',
          lines: [
            {
              targetBranchCode: 'PECS',
              targetBranchName: 'Pécs',
              currencyCode: 'USD',
              amount: 500,
            },
          ],
        },
      ],
      '/api/v1/ertektar/bank-transactions': [
        {
          id: 13,
          transactionType: 'BUY',
          currencyCode: 'CHF',
          amount: 300,
          exchangeRate: 410,
          hufAmount: 123000,
          bankName: 'Raiffeisen',
          status: 'REQUESTED',
          createdAt: '2026-06-19T08:00:00',
        },
      ],
      '/api/v1/daily-sessions/history': [],
    }

    const body = bodies[path]
    if (body !== undefined) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(body),
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

test('értéktári dashboard mobil viewporton használja az ErtektarController riport és branch endpointjait', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockTreasuryApis(page)
  await login(page)

  const branchesRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/ertektar/branches',
  )
  const consolidatedRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/ertektar/reports/consolidated',
  )
  const companyTotalsRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/cash-balances/company-totals',
  )
  const lowAlertsRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/cash-balances/alerts/low',
  )
  const highAlertsRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/cash-balances/alerts/high',
  )
  await page.goto('/treasury', { waitUntil: 'domcontentloaded' })
  await branchesRequest
  await consolidatedRequest
  await companyTotalsRequest
  await lowAlertsRequest
  await highAlertsRequest

  await expect(page.getByText('Értéktári pénztár monitoring')).toBeVisible()
  await expect(page.getByText('1/2 online')).toBeVisible()
  await expect(page.getByText('1 offline, 1 riasztás')).toBeVisible()
  await expect(page.getByText('Értéktári konszolidált riport')).toBeVisible()
  await expect(page.getByText('1.7M Ft / 1 iroda')).toBeVisible()
  await expect(page.getByText('Készlet riasztások')).toBeVisible()
  await expect(page.getByText('2 jelzés')).toBeVisible()
  await expect(page.getByText('1 alacsony, 1 magas')).toBeVisible()
  await expect(page.getByText('Valutánkénti készlet')).toBeVisible()
  await expect(page.getByText(/EUR\s+1\s*000/)).toBeVisible()
  await expect(page.getByTestId('ertektar-status-control')).toBeVisible()
  await expect(page.getByText('Értéktári státusz kontroll')).toBeVisible()
  page.on('dialog', (dialog) => dialog.accept())
  const collectionStatusRequest = page.waitForRequest(
    (request) =>
      request.method() === 'PATCH' &&
      new URL(request.url()).pathname === '/api/v1/ertektar/collections/11/status' &&
      new URL(request.url()).searchParams.get('status') === 'COMPLETED',
  )
  await page.getByRole('button', { name: 'Begyűjtés #11 státusz COMPLETED' }).click()
  await collectionStatusRequest

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
