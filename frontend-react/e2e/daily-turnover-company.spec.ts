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
  lastName: 'Ellenor',
  fullName: 'Admin Ellenor',
  role: 'admin',
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
    activeRole: 'admin',
    permissions: ['READ', 'WRITE'],
    roles: ['admin'],
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
          activeRole: 'admin',
          permissions: ['READ', 'WRITE'],
          roles: ['admin'],
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

    if (path.endsWith('/features') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ camera: true, yearOpeningScheduler: true, navIntegration: true }),
      })
    }

    if (path.endsWith('/turnover/company') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          period: 'Cég összesen',
          totalBuy: 3,
          totalSell: 0,
          byCurrency: [
            {
              currencyCode: 'EUR',
              officialRate: null,
              buyVolume: 1000,
              buyHuf: 400000,
              sellVolume: 500,
              sellHuf: 200000,
            },
          ],
        }),
      })
    }

    if (method === 'GET') {
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
  await expect(page).toHaveURL(/\/central-workstation$/)
}

test('napi forgalom oldalon a cég időszak mód a /turnover/company backend szerződést hívja', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/daily-turnover', { waitUntil: 'domcontentloaded' })
  await page.getByRole('combobox', { name: 'Egység' }).selectOption('company')
  await page.getByRole('combobox', { name: 'Év' }).selectOption('2026')
  await page.getByRole('combobox', { name: 'Hónap' }).selectOption('6')
  await page.getByLabel('Nap (tól)').fill('1')
  await page.getByLabel('Nap (ig)').fill('18')

  const companyTurnoverRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'GET'
      && url.pathname === '/api/v1/turnover/company'
      && url.searchParams.get('from') === '2026-06-01'
      && url.searchParams.get('to') === '2026-06-18'
  })
  await page.getByRole('button', { name: /Időszak rendben/i }).click()
  await companyTurnoverRequest

  await expect(page.getByText('Cég összesen')).toBeVisible()
  await expect(page.getByRole('cell', { name: 'EUR' })).toBeVisible()
  await expect(page.getByText('3').first()).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
