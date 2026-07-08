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

    if (path.endsWith('/rate-history') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 1,
            currencyCode: 'EUR',
            buyRate: '391.50',
            sellRate: '398.50',
            effectiveFrom: '2026-06-18T08:00:00',
          },
        ]),
      })
    }

    if (path.endsWith('/exchange-rates/code/EUR') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 10,
          currencyId: 1,
          currencyCode: 'EUR',
          currencyName: 'Euró',
          validDate: '2026-06-18',
          validTime: '09:00:00',
          baseBuyRate: 391.5,
          baseSellRate: 398.5,
          active: true,
          createdAt: '2026-06-18T09:00:00',
        }),
      })
    }

    if (path.endsWith('/exchange-rates/buy-rate') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(392.1),
      })
    }

    if (path.endsWith('/exchange-rates/sell-rate') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(399.2),
      })
    }

    if (path.endsWith('/exchange-rates/history') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 11,
            currencyId: 1,
            currencyCode: 'EUR',
            currencyName: 'Euró',
            validDate: '2026-06-17',
            validTime: '09:00:00',
            baseBuyRate: 390.5,
            baseSellRate: 397.5,
            active: true,
            createdAt: '2026-06-17T09:00:00',
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

test('árfolyam történet mobil nézetben canonical exchange-rate read endpointokat használ', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/rates/history', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('article').getByText('391.50')).toBeVisible()

  const codeRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/exchange-rates/code/EUR',
  )
  const buyRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/exchange-rates/buy-rate',
  )
  const sellRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/exchange-rates/sell-rate',
  )
  const historyRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/exchange-rates/history',
  )

  await page.getByLabel('Árfolyam ellenőrzés valuta').fill('EUR')
  await page.getByLabel('Árfolyam ellenőrzés HUF összeg').fill('100000')
  await page.getByRole('button', { name: 'Árfolyam ellenőrzés' }).click()

  await codeRequest
  await buyRequest
  await sellRequest
  await historyRequest

  await expect(page.getByText('392.1')).toBeVisible()
  await expect(page.getByText('399.2')).toBeVisible()
  await expect(page.getByText('Előzmény találatok: 1')).toBeVisible()

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
