import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const branchId = '11111111-1111-1111-1111-111111111111'

const worker = {
  id: 77,
  workerCode: 'ADMIN',
  firstName: 'Admin',
  lastName: 'Teszt',
  fullName: 'Admin Teszt',
  role: 'ADMIN',
  branchId,
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

    if (path.endsWith('/synchronization/should-sync') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ shouldSync: true, pendingCount: 3 }),
      })
    }

    if (path.endsWith('/data-collection/status') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'dc-1',
            branchId,
            collectionDate: '2026-06-18',
            status: 'COMPLETED',
            transactionCount: 12,
          },
        ]),
      })
    }

    if (path.endsWith(`/sync/status/${branchId}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          branchId,
          status: 'ONLINE',
          lastSuccessfulSyncAt: '2026-06-18T09:00:00',
          pendingUpload: 2,
          pendingDownload: 1,
        }),
      })
    }

    if (path.endsWith(`/sync/history/${branchId}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          content: [
            {
              id: 'sync-1',
              syncType: 'FULL',
              status: 'COMPLETED',
              startedAt: '2026-06-18T08:30:00',
              recordsSynced: 44,
            },
          ],
        }),
      })
    }

    if (path.endsWith(`/ftp-sync/history/${branchId}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'ftp-1',
            direction: 'UPLOAD',
            fileName: 'daily_20260618.xml',
            status: 'SUCCESS',
            fileSizeBytes: 2048,
            startedAt: '2026-06-18T09:15:00',
          },
        ]),
      })
    }

    if (path.endsWith(`/ftp-sync/rates/${branchId}`) && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, fileName: 'rates.dat' }),
      })
    }

    if (path.endsWith(`/ftp-sync/daily-report/${branchId}`) && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, fileName: 'daily.xml' }),
      })
    }

    if (path.endsWith(`/ftp-sync/transactions/${branchId}`) && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, fileName: 'transactions.xml' }),
      })
    }

    if (
      path.match(/\/api\/v1\/sync\/(rates|transactions|inventory|full)\/[^/]+$/) &&
      method === 'POST'
    ) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ status: 'COMPLETED', recordsSynced: 3 }),
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

test('szinkron admin panel mobil nézetben backend status és history endpointokat hív', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  const statusRequest = page.waitForRequest(
    (request) => request.method() === 'GET' && request.url().includes(`/sync/status/${branchId}`),
  )
  const historyRequest = page.waitForRequest(
    (request) => request.method() === 'GET' && request.url().includes(`/sync/history/${branchId}`),
  )
  const ftpHistoryRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' && request.url().includes(`/ftp-sync/history/${branchId}`),
  )

  await page.goto('/synchronization', { waitUntil: 'domcontentloaded' })
  await statusRequest
  await historyRequest
  await ftpHistoryRequest

  await expect(page.getByTestId('branch-sync-panel')).toContainText('ONLINE')
  await expect(page.getByTestId('branch-sync-panel')).toContainText('44 rekord')
  await expect(page.getByTestId('branch-sync-actions')).toContainText('Branch sync műveletek')
  await expect(page.getByTestId('ftp-sync-history')).toContainText('daily_20260618.xml')

  const ratesRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && request.url().includes(`/ftp-sync/rates/${branchId}`),
  )
  await page.getByTestId('ftp-sync-rates').click()
  await ratesRequest

  const dailyReportRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && request.url().includes(`/ftp-sync/daily-report/${branchId}`),
  )
  await page.getByTestId('ftp-sync-daily-report').click()
  await dailyReportRequest

  const transactionsRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && request.url().includes(`/ftp-sync/transactions/${branchId}`),
  )
  await page.getByTestId('ftp-sync-transactions').click()
  await transactionsRequest

  const syncRatesRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes(`/sync/rates/${branchId}`),
  )
  await page.getByTestId('branch-sync-rates').click()
  await syncRatesRequest

  const syncTransactionsRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && request.url().includes(`/sync/transactions/${branchId}`),
  )
  await page.getByTestId('branch-sync-transactions').click()
  await syncTransactionsRequest

  const syncInventoryRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && request.url().includes(`/sync/inventory/${branchId}`),
  )
  await page.getByTestId('branch-sync-inventory').click()
  await syncInventoryRequest

  const syncFullRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes(`/sync/full/${branchId}`),
  )
  await page.getByTestId('branch-sync-full').click()
  await syncFullRequest

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
