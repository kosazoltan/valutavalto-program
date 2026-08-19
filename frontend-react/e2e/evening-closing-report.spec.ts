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

const checklist = {
  id: 'checklist-1',
  branchId: 'branch-1',
  branchName: 'Budapest 01',
  closingDate: '2026-06-18',
  item1: false,
  item2: false,
  item3: false,
  item4: false,
  item5: false,
  item6: false,
  item7: false,
  item8: false,
  item9: false,
}

const report = {
  branchId: 1,
  date: '2026-06-18',
  totalTransactionCount: 7,
  buyCount: 4,
  sellCount: 2,
  reversalCount: 1,
  conversionCount: 0,
  totalBuyHuf: 120000,
  totalSellHuf: 90000,
  totalHandlingFees: 1500,
  netTurnover: -30000,
  currencyBreakdown: {
    EUR: 80000,
    USD: 40000,
  },
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

    if (path.endsWith('/features') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ camera: true, yearOpeningScheduler: true, navIntegration: true }),
      })
    }

    if (path.endsWith('/vault-closing-checklist') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(checklist),
      })
    }

    if (path.endsWith('/evening-closing/branch-1/2026-06-18/report') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(report),
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

test('esti zárás mobil nézetben a napi jelentés backend endpointot hívja', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/evening-closing', { waitUntil: 'domcontentloaded' })
  await page.locator('input[type="date"]').fill('2026-06-18')

  const reportRequest = page.waitForRequest((request) => {
    const url = new URL(request.url())
    return (
      request.method() === 'GET' &&
      url.pathname === '/api/v1/evening-closing/branch-1/2026-06-18/report'
    )
  })
  await page.getByRole('button', { name: 'Napi jelentés', exact: true }).click()
  await reportRequest

  const reportPanel = page.getByTestId('evening-closing-report-panel')
  await expect(reportPanel).toBeVisible()
  await expect(reportPanel.getByText('EUR')).toBeVisible()
  await expect(reportPanel.getByText('USD')).toBeVisible()
  await expect(reportPanel.getByText(/Sztornó: 1/)).toBeVisible()

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
