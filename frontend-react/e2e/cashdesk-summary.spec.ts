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
  branchCode: 'SZEGED',
  branchName: 'Szeged',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const eurBalance = {
  id: 1,
  branchId: 'branch-1',
  branchName: 'Szeged',
  currencyId: 1,
  currencyCode: 'EUR',
  currencyName: 'Euró',
  currentBalance: 1200,
  openingBalance: 1000,
  dailyChange: 200,
  minBalance: 100,
  maxBalance: 5000,
  createdAt: '2026-06-19T08:00:00',
}

async function mockCashDeskApis(page: Page) {
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

    const bodies: Record<string, unknown> = {
      '/api/v1/cash-balances': [
        eurBalance,
        {
          id: 2,
          branchId: 'branch-1',
          branchName: 'Szeged',
          currencyId: 2,
          currencyCode: 'HUF',
          currencyName: 'Magyar forint',
          currentBalance: 250000,
          openingBalance: 200000,
          dailyChange: 50000,
          minBalance: 10000,
          maxBalance: 1000000,
          createdAt: '2026-06-19T08:00:00',
        },
      ],
      '/api/v1/cash-balances/summary': {
        totalCurrencies: 2,
        hufBalance: 250000,
        lowBalanceAlerts: 1,
        highBalanceAlerts: 0,
        balances: [],
      },
      '/api/v1/cash-balances/currency/1': eurBalance,
      '/api/v1/cash-balances/code/EUR': eurBalance,
      // FK-075 FR-5/FR-6: a Mai statisztika új, dedikált végpontja
      '/api/v1/cash-balances/today-stats': {
        transactions: 3,
        buyTotal: 100000,
        sellTotal: 90000,
        handlingFee: 2500,
      },
      '/api/v1/daily-sessions/current': {
        status: 'OPEN',
        openedAt: '2026-06-19T08:00:00',
        openedByWorkerName: 'Admin Teszt',
        transactionCount: 3,
        buyTurnoverHuf: 100000,
        sellTurnoverHuf: 90000,
        handlingFeeTotal: 2500,
      },
    }

    const body = bodies[path]
    if (body !== undefined) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(body),
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

test('pénztár mobil viewporton használja a cash balance summary és detail végpontokat', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockCashDeskApis(page)
  await login(page)

  const summaryRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/cash-balances/summary',
  )
  await page.goto('/cashdesk', { waitUntil: 'domcontentloaded' })
  await summaryRequest

  await expect(page.getByText('HUF készlet')).toBeVisible()
  await expect(page.getByText(/250\s*000\s+Ft/)).toBeVisible()
  // FK-075 FR-9: új H1 cím; FR-2: a jelzés-csempék eltávolítva
  await expect(
    page.getByRole('heading', { name: 'Pillanatnyi pénztárállás' }),
  ).toBeVisible()
  await expect(page.getByText('Alacsony jelzés')).toHaveCount(0)
  // FK-075 FR-6: "Beszedett kezelési díj" csempe a Mai statisztika panelben
  await expect(page.getByText('Beszedett kezelési díj')).toBeVisible()

  const byIdRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/cash-balances/currency/1',
  )
  const byCodeRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/cash-balances/code/EUR',
  )
  // FK-075 FR-3: nincs külön info-gomb, a teljes táblázat-sor kattintható
  await page.getByRole('row', { name: /EUR/ }).click()
  await byIdRequest
  await byCodeRequest

  await expect(page.getByText('EUR pénzkészlet részletek')).toBeVisible()
  await expect(page.getByText('ID és kód egyezik')).toBeVisible()
  // FK-075 FR-4: a részletek panelből a "Limit" mező eltávolítva
  await expect(page.getByText('Limit')).toHaveCount(0)

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
