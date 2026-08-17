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

    if (path.endsWith('/central/received-data/status') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          reportDate:
            url.searchParams.get('endDate') ?? url.searchParams.get('date') ?? '2026-06-18',
          totalBranches: 3,
          receivedReports: 2,
          submittedReports: 2,
          missingReports: 1,
          warningClosings: 1,
          criticalClosings: 1,
          totalTransactions: 12,
          totalBuyHuf: 1000000,
          totalSellHuf: 800000,
          totalFeeHuf: 12000,
          totalProfit: 22000,
          generatedAt: '2026-06-18T10:00:00',
          rows: [],
        }),
      })
    }

    if (path.endsWith('/central/transfer-reconciliation/run') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          startDate: url.searchParams.get('startDate') ?? '2026-06-18',
          endDate: url.searchParams.get('endDate') ?? '2026-06-18',
          totalRows: 2,
          matchedRows: 1,
          discrepancyRows: 1,
          notifiedBranches: 1,
          generatedAt: '2026-06-18T10:00:00',
          rows: [
            {
              transferId: 1,
              transferNumber: 'AT0001',
              date: '2026-06-18',
              fromBranchCode: 'BR009',
              fromBranchName: 'Dombóvár',
              toBranchCode: 'BR020',
              toBranchName: 'Szeged Értéktár',
              currencyCode: 'EUR',
              sentAmount: 5000,
              receivedAmount: 5000,
              status: 'EGYEZIK',
              discrepancyNote: null,
            },
            {
              transferId: 2,
              transferNumber: 'AT0002',
              date: '2026-06-18',
              fromBranchCode: 'BR010',
              fromBranchName: 'Szekszárd',
              toBranchCode: 'BR020',
              toBranchName: 'Szeged Értéktár',
              currencyCode: 'USD',
              sentAmount: 3000,
              receivedAmount: 2900,
              status: 'ELTERES',
              discrepancyNote: 'Eltérő összeg: küldött 3000, fogadott 2900',
            },
          ],
        }),
      })
    }

    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ content: [], data: [], total: 0 }),
    })
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

test('beérkezett adatok oldal valós renderben hívja a status és reconciliation backend szerződést', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/central/received-data', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Beérkezett adatok áttekintése' })).toBeVisible()
  await expect(page.getByText('Válasszon intervallumot')).toBeVisible()

  const receivedDataRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' && request.url().includes('/central/received-data/status'),
  )
  const reconciliationRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && request.url().includes('/central/transfer-reconciliation/run'),
  )
  await page.getByRole('button', { name: /Ellenőrzés/i }).click()
  await receivedDataRequest
  await reconciliationRequest

  const statusPanel = page.getByTestId('central-received-data-status')
  await expect(statusPanel.getByText('Beérkezett jelentés')).toBeVisible()
  await expect(statusPanel.getByText('Hiányzó jelentés')).toBeVisible()
  await expect(statusPanel.getByText('Kritikus zárás')).toBeVisible()
  const resultTable = page.locator('tbody')
  await expect(resultTable.getByText('EGYEZIK')).toBeVisible()
  await expect(resultTable.getByText('ELTÉRÉS')).toBeVisible()

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
