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

async function mockContributionApis(page: Page) {
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

    if (path.endsWith('/contributions') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'contribution-1',
            workerFullName: 'Teszt Elek',
            branchName: 'Budapest 01',
            periodStart: '2026-06-01',
            periodEnd: '2026-06-30',
            contributionTypeName: 'Jutalék',
            baseAmount: 100000,
            calculatedAmount: 12000,
            currencyCode: 'HUF',
            statusName: 'Jóváhagyva',
            calculationDate: '2026-06-19',
          },
        ]),
      })
    }

    if (path.endsWith('/contributions/contribution-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'contribution-1',
          workerFullName: 'Teszt Elek',
          branchName: 'Budapest 01',
          periodStart: '2026-06-01',
          periodEnd: '2026-06-30',
          contributionTypeName: 'Jutalék',
          baseAmount: 100000,
          calculatedAmount: 12000,
          currencyCode: 'HUF',
          statusName: 'Jóváhagyva',
          transactionCount: 7,
          totalVolume: 100000,
          calculationDate: '2026-06-19',
          calculationDetails: 'Backend részletszámítás',
        }),
      })
    }

    if (path.endsWith('/contributions/calculate') && method === 'POST') {
      return route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'contribution-2',
            workerFullName: 'Számolt Sára',
            branchName: 'Budapest 01',
            periodStart: url.searchParams.get('periodStart'),
            periodEnd: url.searchParams.get('periodEnd'),
            contributionTypeName: 'Járulék',
            baseAmount: 200000,
            calculatedAmount: 24000,
            currencyCode: 'HUF',
            statusName: 'Számított',
            calculationDate: '2026-06-19',
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

test('járulék részlet mobil viewporton backend getById hívásból jelenik meg', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockContributionApis(page)
  await login(page)

  await page.goto('/contributions', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Teszt Elek')).toBeVisible()

  const detailRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/contributions/contribution-1',
  )
  await page.getByRole('button', { name: 'Részletek' }).click()
  await detailRequest

  await expect(page.getByTestId('contribution-detail-panel')).toContainText(
    'Backend részletszámítás',
  )

  const calculateRequest = page.waitForRequest((request) => {
    const url = new URL(request.url())
    return (
      request.method() === 'POST' &&
      url.pathname === '/api/v1/contributions/calculate' &&
      url.searchParams.get('branchId') === 'branch-1' &&
      url.searchParams.get('periodStart') === '2026-06-01' &&
      url.searchParams.get('periodEnd') === '2026-06-30'
    )
  })
  const dates = page.locator('input[type="date"]')
  await dates.nth(0).fill('2026-06-01')
  await dates.nth(1).fill('2026-06-30')
  await page.getByRole('button', { name: /Időszaki számítás/i }).click()
  await calculateRequest
  await expect(page.getByText('Számolt Sára')).toBeVisible()

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
