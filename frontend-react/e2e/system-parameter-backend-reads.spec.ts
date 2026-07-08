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

const baseParameter = {
  id: 'param-1',
  parameterKey: 'RATE_SPREAD_EUR',
  parameterValue: '4',
  parameterType: 'NUMBER',
  category: 'RATE',
  description: 'EUR spread',
  isActive: true,
  updatedAt: '2026-06-18T10:00:00',
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

    if (path.endsWith('/system-parameters/active') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([baseParameter]),
      })
    }

    if (path.endsWith('/system-params') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([baseParameter]),
      })
    }

    if (path.endsWith('/system-parameters/category/RATE') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ ...baseParameter, parameterKey: 'CATEGORY_RATE_SPREAD_EUR' }]),
      })
    }

    if (path.endsWith('/system-parameters/key/RATE_SPREAD_EUR') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(baseParameter),
      })
    }

    if (path.endsWith('/system-parameters/value/RATE_SPREAD_EUR') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify('4'),
      })
    }

    if (path.endsWith('/system-parameters') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([baseParameter]),
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

test('rendszerparaméter oldal mobil nézetben backend read endpointokat használ', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  const activeRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/system-parameters/active',
  )
  const managedRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/system-params',
  )

  await page.goto('/settings/parameters', { waitUntil: 'domcontentloaded' })
  await activeRequest
  await managedRequest
  await expect(page.getByRole('cell', { name: 'RATE_SPREAD_EUR', exact: true })).toBeVisible()

  const categoryRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/system-parameters/category/RATE',
  )
  await page.locator('#system-parameter-category').selectOption('RATE')
  await categoryRequest
  await expect(
    page.getByRole('cell', { name: 'CATEGORY_RATE_SPREAD_EUR', exact: true }),
  ).toBeVisible()

  const keyRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/system-parameters/key/RATE_SPREAD_EUR',
  )
  const valueRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/system-parameters/value/RATE_SPREAD_EUR',
  )
  await page.locator('#system-parameter-key-lookup').fill('RATE_SPREAD_EUR')
  await page.getByRole('button', { name: /Lekérdezés/i }).click()
  await keyRequest
  await valueRequest

  await expect(page.getByText('Kulcs:')).toBeVisible()
  await expect(page.getByText('Érték:')).toBeVisible()

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
