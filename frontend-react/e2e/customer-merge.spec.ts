import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 7,
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

async function mockCustomerApis(page: Page) {
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

    if (path === '/api/v1/customers/42' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 42,
          customerCode: 'C-42',
          name: 'Elsődleges Ügyfél',
          active: true,
          isVip: false,
          isPep: false,
          transactionCount: 3,
          createdAt: '2026-06-18T10:00:00',
        }),
      })
    }

    if (path === '/api/v1/customers/merge' && method === 'POST') {
      const body = route.request().postDataJSON() as { primaryId: number; duplicateId: number }
      expect(body).toEqual({ primaryId: 42, duplicateId: 99 })
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 42,
          customerCode: 'C-42',
          name: 'Elsődleges Ügyfél',
          active: true,
          isVip: false,
          isPep: false,
          transactionCount: 8,
          createdAt: '2026-06-18T10:00:00',
          updatedAt: '2026-06-18T12:00:00',
        }),
      })
    }

    if (path === '/api/v1/customers/42/stats' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          customerId: 42,
          customerName: 'Elsődleges Ügyfél',
          totalTransactions: 3,
          totalVolumeHuf: 1250000,
          averageAmount: 416667,
          firstVisit: '2026-01-05',
          lastVisit: '2026-06-18',
          preferredCurrency: 'EUR',
        }),
      })
    }

    if (path === '/api/v1/customers/42/history' && method === 'GET') {
      const filtered = url.searchParams.get('from') === '2026-06-10'
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          customerId: 42,
          customerName: 'Elsődleges Ügyfél',
          totalTransactions: filtered ? 1 : 2,
          totalVolumeHuf: filtered ? 500000 : 850000,
          averageAmount: filtered ? 500000 : 425000,
          firstVisit: filtered ? '2026-06-10' : '2026-06-01',
          lastVisit: filtered ? '2026-06-10' : '2026-06-18',
          preferredCurrency: filtered ? 'CHF' : 'USD',
        }),
      })
    }

    const bodyByPath: Record<string, unknown> = {
      '/api/v1/customer-control/42/restrictions': [],
      '/api/v1/customer-control/42/annual-total': 0,
      '/api/v1/customer-control/42/screening-log': [],
      '/api/v1/aml/customer-risk/42': {
        customerId: '42',
        customerName: 'Elsődleges Ügyfél',
        riskLevel: 'LOW',
        last30DaysTotal: 0,
        last30DaysTransactionCount: 0,
        dailyTotal: 0,
        dailyTransactionCount: 0,
        annualTotal: 0,
        structuringDetected: false,
        highFrequency: false,
        highVolume: false,
      },
      '/api/v1/aml/structuring-check/42': { customerId: '42', structuringDetected: false },
      '/api/v1/customers/42/versions': [],
    }

    const body = bodyByPath[path] ?? { content: [], data: [], total: 0 }
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(body) })
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

test('ügyfél-összevonási panel renderel és a backend szerződést hívja', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockCustomerApis(page)
  await login(page)

  const statsRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/customers/42/stats'
  )
  const historyRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/customers/42/history'
  )
  await page.goto('/customers/42', { waitUntil: 'domcontentloaded' })
  await Promise.all([statsRequest, historyRequest])
  await expect(page.getByTestId('customer-backend-stats')).toContainText('1 250 000 Ft')
  await expect(page.getByTestId('customer-history-stats')).toContainText('850 000 Ft')
  await expect(page.getByTestId('customer-history-stats')).toContainText('USD')

  const filteredHistoryRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'GET'
      && url.pathname === '/api/v1/customers/42/history'
      && url.searchParams.get('from') === '2026-06-10'
      && url.searchParams.get('to') === '2026-06-19'
  })
  await page.getByTestId('customer-history-from').fill('2026-06-10')
  await page.getByTestId('customer-history-to').fill('2026-06-19')
  await page.getByRole('button', { name: 'Időszak frissítése' }).click()
  await filteredHistoryRequest
  await expect(page.getByTestId('customer-history-stats')).toContainText('500 000 Ft')
  await expect(page.getByTestId('customer-history-stats')).toContainText('CHF')

  await expect(page.getByTestId('customer-merge-panel')).toBeVisible()
  await expect(page.getByText('Ügyfél duplikátum összevonás')).toBeVisible()
  await expect(page.getByTestId('duplicate-customer-id-input')).toBeVisible()

  page.once('dialog', async dialog => {
    expect(dialog.message()).toContain('duplikált ügyfél inaktív lesz')
    await dialog.accept()
  })

  await page.getByTestId('duplicate-customer-id-input').fill('99')
  await page.getByRole('button', { name: /Ügyfelek összevonása/i }).click()
  await expect(page.getByText('8', { exact: true })).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
