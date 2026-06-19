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
  branchId: '11111111-1111-1111-1111-111111111111',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const trade = {
  id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  fromBranchId: '11111111-1111-1111-1111-111111111111',
  fromBranchName: 'Budapest 01',
  toBranchId: '22222222-2222-2222-2222-222222222222',
  toBranchName: 'Szeged 01',
  currencyCode: 'EUR',
  amount: 1000,
  rate: 394.5,
  status: 'PROPOSED',
  proposedBy: 77,
  proposedAt: '2026-06-19T08:00:00',
  notes: 'Mobil trade',
}

async function mockTradeApis(page: Page) {
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

    if (path === '/api/v1/trades/pending' && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([trade]) })
    }

    if (path === '/api/v1/trades/history' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ content: [{ ...trade, status: 'COMPLETED' }], totalElements: 1, totalPages: 1, size: 20, number: 0 }),
      })
    }

    if (path === '/api/v1/trades/propose' && method === 'POST') {
      return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify(trade) })
    }

    if (path === `/api/v1/trades/${trade.id}/accept` && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ ...trade, status: 'ACCEPTED' }) })
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

test('irodaközi trade mobil nézet beköti a trades backend szerződést', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockTradeApis(page)
  await login(page)

  await page.goto('/trades', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Irodaközi trade' })).toBeVisible()
  await expect(page.getByText('Mobil trade').first()).toBeVisible()

  await page.getByLabel('Cél iroda UUID').fill('22222222-2222-2222-2222-222222222222')
  await page.getByLabel('Valuta').fill('USD')
  await page.getByLabel('Összeg').fill('2500')
  await page.getByLabel('Árfolyam').fill('351.25')
  await page.getByLabel('Megjegyzés').fill('Mobil ajánlat')
  const proposeRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().endsWith('/api/v1/trades/propose')
  )
  await page.getByRole('button', { name: /Ajánlat létrehozása/i }).click()
  await proposeRequest

  const acceptRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().endsWith(`/api/v1/trades/${trade.id}/accept`)
  )
  await page.getByRole('button', { name: /Elfogadás/i }).first().click()
  await acceptRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
