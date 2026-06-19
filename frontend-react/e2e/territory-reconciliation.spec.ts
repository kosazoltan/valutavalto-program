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

async function mockTerritoryApis(page: Page) {
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

    if (path === '/api/v1/territories' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 20,
            companyId: 'company-1',
            name: 'Szeged terület',
            baseCapital: 1000000,
            baseCapitalApprovedAt: '2026-06-01',
            active: true,
          },
        ]),
      })
    }

    if (path === '/api/v1/territories' && method === 'POST') {
      return route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 21,
          companyId: 'company-1',
          name: 'Új terület',
          baseCapital: 250000,
          baseCapitalApprovedAt: '2026-06-18',
          active: true,
        }),
      })
    }

    if (path === '/api/v1/territories/20' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 20,
          companyId: 'company-1',
          name: 'Szeged terület',
          baseCapital: 1000000,
          baseCapitalApprovedAt: '2026-06-01',
          active: true,
        }),
      })
    }

    if (path === '/api/v1/territories/21' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 21,
          companyId: 'company-1',
          name: 'Új terület',
          baseCapital: 250000,
          baseCapitalApprovedAt: '2026-06-18',
          active: true,
        }),
      })
    }

    if (path.match(/\/api\/v1\/territories\/\d+\/profit$/) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          totalProfit: 123000,
          transactionCount: 12,
          sellCount: 7,
          buyCount: 5,
          profitByCurrency: { EUR: 80000, USD: 43000 },
        }),
      })
    }

    if (path === '/api/v1/reports/territory-reconciliation' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          territoryId: 20,
          fromDate: '2026-06-01',
          toDate: '2026-06-30',
          territoryRealizedMargin: 100000,
          territoryRevaluation: 23000,
          territoryTotalProfit: 123000,
          reconciliationOk: true,
          cashiers: [
            {
              branchId: 'branch-1',
              branchCode: 'SZEGED',
              branchName: 'Szeged Értéktár',
              realizedMargin: 100000,
              allocatedRevaluation: 23000,
              totalProfit: 123000,
            },
          ],
          currencyRevaluations: [
            {
              currencyCode: 'EUR',
              vaultHeldQty: 500,
              weightedAvgCost: 390,
              mnbRate: 394,
              revaluation: 2000,
            },
          ],
        }),
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

test('területi elszámolás mobil viewporton kezeli a territories backend szerződést', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockTerritoryApis(page)
  await login(page)

  await page.goto('/reports/territory-reconciliation', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Területi reconciliation')).toBeVisible()
  await expect(page.getByLabel('Terület')).toHaveValue('20')
  await expect(page.getByText('Terület neve')).toBeVisible()
  await expect(page.getByText('1 000 000 Ft')).toBeVisible()
  await expect(page.getByText('Területi WAC profit összesítő')).toBeVisible()

  await page.getByLabel('Hónap').fill('2026-06')
  const reportRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/reports/territory-reconciliation')
  )
  const profitRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/territories/20/profit')
  )
  await page.getByRole('button', { name: 'Lekérdez' }).click()
  await reportRequest
  await profitRequest
  await expect(page.getByText('Reconciliation OK: Σ pénztár összhaszon = terület összhaszon')).toBeVisible()
  await expect(page.getByText('SZEGED - Szeged Értéktár').first()).toBeVisible()

  await page.getByLabel('Név').fill('Új terület')
  await page.getByLabel('Alaptőke').fill('250000')
  await page.getByLabel('Jóváhagyás dátuma').fill('2026-06-18')
  const createRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().endsWith('/api/v1/territories')
  )
  await page.getByRole('button', { name: 'Terület létrehozása' }).click()
  await createRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
