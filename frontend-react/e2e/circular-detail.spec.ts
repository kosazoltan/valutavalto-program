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
  branchId: 'branch-123',
  branchCode: 'SZEGED',
  branchName: 'Szeged Értéktár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const listCircular = {
  id: 1,
  title: 'Lista körlevél',
  content: 'Lista tartalom',
  createdByName: 'Központ',
  circularType: 'GENERAL',
  priority: 'NORMAL',
  registrationNumber: 'KOR-2026-010',
  createdAt: '2026-06-19T08:00:00',
  acknowledgmentCount: 0,
}

const detailCircular = {
  ...listCircular,
  title: 'Backend részlet körlevél',
  content: 'Backend részletből érkezett teljes körlevél tartalom.',
  acknowledgmentCount: 2,
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

    if (path.endsWith('/circulars/types') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ type: 'GENERAL', description: 'Általános' }]),
      })
    }

    if (path.endsWith('/circulars/my-unacknowledged') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
    }

    if (path.endsWith('/circulars/unacknowledged') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
    }

    if (path.endsWith('/circulars/active') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([listCircular]) })
    }

    if (path.endsWith('/circulars/1/acknowledgment-status') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ circularId: 1, title: detailCircular.title, totalAcknowledged: 2 }),
      })
    }

    if (path.endsWith('/circulars/1/acknowledgment-breakdown') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ CASHIER: 1, MANAGER: 1 }),
      })
    }

    if (path.endsWith('/circulars/1') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(detailCircular) })
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

test('körlevél részlet mobil nézetben backend detail és nyugtázási endpointokból nyílik', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/circulars', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Lista körlevél')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/circulars/1'
  )
  const statusRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/circulars/1/acknowledgment-status'
  )
  const breakdownRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/circulars/1/acknowledgment-breakdown'
  )

  await page.getByRole('button', { name: 'Megtekint' }).click()
  await detailRequest
  await statusRequest
  await breakdownRequest

  await expect(page.getByRole('heading', { name: 'Backend részlet körlevél' })).toBeVisible()
  await expect(page.getByText('Backend részletből érkezett teljes körlevél tartalom.')).toBeVisible()
  await expect(page.getByTestId('circular-acknowledgment-summary')).toContainText('Összes nyugtázás: 2')
  await expect(page.getByTestId('circular-acknowledgment-summary')).toContainText('CASHIER')
  await expect(page.getByTestId('circular-acknowledgment-summary')).toContainText('MANAGER')

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
