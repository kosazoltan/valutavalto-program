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

    if (path.endsWith('/vault-stocktake/session-1/summary') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          sessionId: 'session-1',
          sessionName: 'Napi értéktár leltár',
          status: 'OPEN',
          totalItems: 12,
          countedItems: 10,
          discrepancyItems: 2,
          totalDiscrepancyHuf: -40000,
          discrepancies: [],
        }),
      })
    }

    if (path.endsWith('/vault-stocktake/session-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'session-1',
          companyId: 'company-1',
          branchId: 'branch-1',
          territoryId: null,
          sessionName: 'Napi értéktár leltár',
          status: 'OPEN',
          startedAt: '2026-06-18T08:00:00',
          completedAt: null,
          startedBy: 'ADMIN',
          reviewedBy: null,
          approvedBy: null,
          note: null,
          discrepancyTotalHuf: 0,
          items: [
            {
              id: 'item-1',
              sessionId: 'session-1',
              currencyId: 1,
              currencyCode: 'EUR',
              faceValue: 100,
              expectedQuantity: 2,
              actualQuantity: 1,
              discrepancy: -1,
              discrepancyValue: -40000,
              countedBy: 'ADMIN',
              countedAt: '2026-06-18T08:30:00',
              note: null,
            },
          ],
        }),
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

test('értéktár leltár detail mobil nézetben backend summary endpointot használ', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  const summaryRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/vault-stocktake/session-1/summary'
  )
  await page.goto('/vault-stocktake/session-1', { waitUntil: 'domcontentloaded' })
  await summaryRequest

  await expect(page.getByRole('heading', { name: 'Napi értéktár leltár' })).toBeVisible()
  await expect(page.getByLabel('Backend összesítő')).toBeVisible()
  await expect(page.getByText('Összesített eltérés (HUF)')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
