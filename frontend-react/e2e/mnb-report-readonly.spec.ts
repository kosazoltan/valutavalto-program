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

const reportId = '22222222-2222-2222-2222-222222222222'

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

    if (path.endsWith(`/mnb/reports/${reportId}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: reportId,
          reportType: 'DAILY',
          reportDate: '2026-06-18',
          status: 'DRAFT',
          totalBuyHuf: 120000,
          totalSellHuf: 80000,
          totalTransactions: 7,
          rejectionReason: 'Backend detail reason',
          lines: [{ id: 'line-1', currencyCode: 'EUR', buyAmount: 100, sellAmount: 50 }],
        }),
      })
    }

    if (path.endsWith('/mnb/reports/daily') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          date: '2026-06-18',
          totalBuyHuf: 120000,
          totalSellHuf: 80000,
          totalTransactions: 7,
          currencyLines: [],
        }),
      })
    }

    if (path.endsWith('/mnb/reports/monthly') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          month: url.searchParams.get('month'),
          totalBuyHuf: 620000,
          totalSellHuf: 480000,
          totalTransactions: 37,
          workingDays: 20,
          currencyLines: [],
        }),
      })
    }

    if (path.endsWith('/mnb/reports/validate') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(['Nincs hiányzó árfolyam']),
      })
    }

    if (path.endsWith('/mnb/reports/daily/xml') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/xml',
        headers: {
          'content-disposition': `attachment; filename=mnb_daily_${url.searchParams.get('date')}.xml`,
        },
        body: '<mnb><date>2026-06-18</date></mnb>',
      })
    }

    if (path.endsWith('/mnb/reports') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: reportId,
            reportType: 'DAILY',
            reportDate: '2026-06-18',
            status: 'DRAFT',
            totalTransactions: 7,
            submittedAt: null,
          },
        ]),
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

test('mnb riport oldal mobil nézetben read-only backend endpointokat használ', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/mnb', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('cell', { name: '2026-06-18', exact: true })).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === `/api/v1/mnb/reports/${reportId}`
  )
  await page.getByRole('button', { name: /Részletek/i }).click()
  await detailRequest
  await expect(page.getByText('Backend detail reason')).toBeVisible()

  await page.locator('#mnb-report-date').fill('2026-06-18')
  const dailyRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/mnb/reports/daily'
  )
  const monthlyRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'GET'
      && url.pathname === '/api/v1/mnb/reports/monthly'
      && url.searchParams.get('month') === '2026-06'
  })
  const validateRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/mnb/reports/validate'
  )
  await page.getByRole('button', { name: /Read-only ellenőrzés/i }).click()
  await Promise.all([dailyRequest, monthlyRequest, validateRequest])

  await expect(page.getByText('Nincs hiányzó árfolyam')).toBeVisible()
  await expect(page.getByText('37')).toBeVisible()

  const dailyXmlRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'GET'
      && url.pathname === '/api/v1/mnb/reports/daily/xml'
      && url.searchParams.get('date') === '2026-06-18'
  })
  await page.getByRole('button', { name: /Napi XML/i }).click()
  await dailyXmlRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
