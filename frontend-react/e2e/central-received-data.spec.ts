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

    if (path.endsWith('/central/transfer-reconciliation/run') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          startDate: url.searchParams.get('startDate') ?? '2026-06-18',
          endDate: url.searchParams.get('endDate') ?? '2026-06-18',
          totalRows: 3,
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
            {
              transferId: 3,
              transferNumber: 'AT0003',
              date: '2026-06-18',
              fromBranchCode: 'BR011',
              fromBranchName: 'Pécs',
              toBranchCode: 'BR020',
              toBranchName: 'Szeged Értéktár',
              currencyCode: 'HUF',
              sentAmount: 10000,
              receivedAmount: null,
              status: 'FOLYAMATBAN',
              discrepancyNote: 'Fogadó megerősítésére vár',
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

test('beérkezett adatok oldal valós renderben hívja a reconciliation backend szerződést', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/central/received-data', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Beérkezett adatok áttekintése' })).toBeVisible()
  await expect(page.getByText('Válasszon intervallumot')).toBeVisible()

  const reconciliationRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && request.url().includes('/central/transfer-reconciliation/run'),
  )
  await page.getByRole('button', { name: /Ellenőrzés/i }).click()
  await reconciliationRequest

  await expect(page.getByTestId('central-received-data-status')).toHaveCount(0)
  const resultTable = page.locator('tbody')
  await expect(resultTable.getByText('EGYEZIK')).toBeVisible()
  await expect(resultTable.getByText('ELTÉRÉS')).toBeVisible()
  await expect(resultTable.getByText('FOLYAMATBAN')).toBeVisible()
  await expect(page.getByTestId('recon-row-AT0003')).not.toHaveClass(/bg-red-50/)

  await page.getByRole('combobox').selectOption('pending')
  await expect(page.getByTestId('recon-status-pending-AT0003')).toBeVisible()
  await expect(page.getByTestId('recon-status-match-AT0001')).toHaveCount(0)
  await expect(page.getByTestId('recon-status-mismatch-AT0002')).toHaveCount(0)

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
