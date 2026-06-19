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

    if (path.endsWith('/hrk/monthly/summary') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          branchId: 'branch-1',
          yearMonth: '2026-06',
          totalTransactions: 0,
          totalHandoverHuf: 0,
          totalReceiveHuf: 0,
          netHuf: 0,
          currencyBreakdown: [],
        }),
      })
    }

    if (path.endsWith('/hrk/journal') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
    }

    if (path.endsWith('/closing/monthly/branch-1/2026-06') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 1,
          branchId: 'branch-1',
          branchName: 'Backend Budapest 01',
          yearMonth: '2026-06',
          closedAt: '2026-06-30T18:00:00',
          closedByWorkerId: 77,
          closedByWorkerName: 'Backend Záró',
          totalBuyHuf: 1000000,
          totalSellHuf: 750000,
          totalHandlingFee: 12000,
          transactionCount: 42,
          currencyBreakdown: '{"EUR":{"buy":1000}}',
          createdAt: '2026-06-30T18:01:00',
        }),
      })
    }

    if (path.endsWith('/closing/monthly/branch-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'closing-1',
            yearMonth: '2026-06',
            branchName: 'Budapest 01',
            status: 'OPEN',
            closedAt: null,
            closedByName: null,
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

test('havi zárás részletei mobil nézetben lekérik a backend report endpointot', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/closing/monthly', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Budapest 01')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/closing/monthly/branch-1/2026-06'
  )
  await page.getByRole('button', { name: /Részletek/i }).click()
  await detailRequest

  await expect(page.getByTestId('monthly-closing-report-panel')).toBeVisible()
  await expect(page.getByText('Backend Budapest 01')).toBeVisible()
  await expect(page.getByText('Backend Záró')).toBeVisible()
  await expect(page.getByText('12 000 Ft')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
