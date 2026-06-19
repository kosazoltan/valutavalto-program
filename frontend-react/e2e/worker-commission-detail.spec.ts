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

    if (path.endsWith('/worker-commissions/11111111-1111-1111-1111-111111111111') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: '11111111-1111-1111-1111-111111111111',
          workerId: '77',
          workerName: 'Backend Béla',
          branchId: 'branch-123',
          branchName: 'Szeged Értéktár',
          periodStart: '2026-06-01',
          periodEnd: '2026-06-30',
          transactionCount: 12,
          totalTransactionAmount: 1500000,
          commissionRate: 0.0125,
          commissionAmount: 18750,
          currencyCode: 'HUF',
          statusDid: 'APPROVED',
          statusName: 'Jóváhagyva',
          calculationDate: '2026-06-30',
          approvedByName: 'Vezető Vera',
        }),
      })
    }

    if (path.endsWith('/worker-commissions') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: '11111111-1111-1111-1111-111111111111',
            workerId: '77',
            workerName: 'Lista Lajos',
            branchId: 'branch-123',
            branchName: 'Szeged Értéktár',
            periodStart: '2026-06-01',
            periodEnd: '2026-06-30',
            transactionCount: 8,
            totalTransactionAmount: 800000,
            commissionRate: 0.01,
            commissionAmount: 8000,
            currencyCode: 'HUF',
            statusDid: 'CALCULATED',
            statusName: 'Számított',
            calculationDate: '2026-06-29',
          },
        ]),
      })
    }

    if (path.endsWith('/worker-commissions/calculate') && method === 'POST') {
      return route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: '22222222-2222-2222-2222-222222222222',
            workerId: '88',
            workerName: 'Számolt Sára',
            branchId: 'branch-123',
            branchName: 'Szeged Értéktár',
            periodStart: url.searchParams.get('periodStart'),
            periodEnd: url.searchParams.get('periodEnd'),
            transactionCount: 9,
            totalTransactionAmount: 900000,
            commissionRate: 0.01,
            commissionAmount: 9000,
            currencyCode: 'HUF',
            statusDid: 'CALCULATED',
            statusName: 'Számított',
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

test('dolgozói jutalék részletek mobil nézetben backend detail endpointból nyílnak', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/commissions', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('article').filter({ hasText: 'Lista Lajos' })).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/worker-commissions/11111111-1111-1111-1111-111111111111'
  )
  await page.getByRole('button', { name: /^Részletek$/i }).click()
  await detailRequest

  const detail = page.getByTestId('worker-commission-detail')
  await expect(detail).toContainText('Backend Béla')
  await expect(detail).toContainText('18 750 HUF')
  await expect(detail).toContainText('Vezető Vera')

  const calculateRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'POST'
      && url.pathname === '/api/v1/worker-commissions/calculate'
      && url.searchParams.get('branchId') === 'branch-123'
      && url.searchParams.get('periodStart') === '2026-06-01'
      && url.searchParams.get('periodEnd') === '2026-06-30'
  })
  const dates = page.locator('input[type="date"]')
  await dates.nth(0).fill('2026-06-01')
  await dates.nth(1).fill('2026-06-30')
  await page.getByRole('button', { name: /Időszaki számítás/i }).click()
  await calculateRequest
  await expect(page.getByRole('article').filter({ hasText: 'Számolt Sára' })).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
