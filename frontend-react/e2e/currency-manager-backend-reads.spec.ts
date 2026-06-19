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

const eurCurrency = {
  id: 1,
  code: 'EUR',
  name: 'Euró',
  symbol: 'EUR',
  decimals: 2,
  displayOrder: 1,
  active: true,
}

const usdCurrency = {
  id: 2,
  code: 'USD',
  name: 'Amerikai dollár',
  symbol: 'USD',
  decimals: 2,
  displayOrder: 2,
  active: true,
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

    if (path.endsWith('/currencies/search') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([eurCurrency]) })
    }

    if (path.endsWith('/currencies/code/EUR') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...eurCurrency, name: 'Backend EUR detail' }),
      })
    }

    if ((path.endsWith('/currencies/all') || path.endsWith('/currencies')) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([eurCurrency, usdCurrency]),
      })
    }

    if (
      (path.endsWith('/exchange-rate-master/active')
        || path.endsWith('/exchange-rates')
        || path.endsWith('/arfolyam-internet-links'))
      && method === 'GET'
    ) {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
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
  await expect(page).toHaveURL(/\/rates\/main$/)
}

test('Valutakezelő mobil nézetben backend keresést és kód szerinti detailt használ', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.getByTestId('open-currency-manager').click()
  await expect(page.getByText('Valutakezelő (V238)')).toBeVisible()

  const searchRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/currencies/search'
    && new URL(request.url()).searchParams.get('q') === 'eur'
  )
  await page.getByTestId('currency-manager-search').fill('eur')
  await page.getByTestId('currency-manager-search-submit').click()
  await searchRequest
  await expect(page.getByText('Euró')).toBeVisible()
  await expect(page.getByText('Amerikai dollár')).toHaveCount(0)

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/currencies/code/EUR'
  )
  await page.getByTestId('detail-EUR').click()
  await detailRequest
  await expect(page.getByTestId('currency-manager-detail')).toContainText('Backend EUR detail')

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
