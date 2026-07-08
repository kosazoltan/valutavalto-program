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

    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'branch-123', code: 'SZEGED', name: 'Szeged Értéktár', active: true },
        ]),
      })
    }

    if (path.endsWith('/reports/average-rate/pivot') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          periodStart: '2026-06-01',
          periodEnd: '2026-06-30',
          columnGroups: [{ groupCode: 'SZEGED', groupName: 'SZEGED', groupType: 'REGION' }],
          currencyRows: [
            {
              currencyCode: 'EUR',
              values: {
                SZEGED: {
                  buyAvgRate: 401.25,
                  buySumAmount: 1500,
                  sellAvgRate: 0,
                  sellSumAmount: 0,
                },
              },
            },
          ],
        }),
      })
    }

    if (path.endsWith('/reports/average-rate') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            periodStart: '2026-06-01',
            periodEnd: '2026-06-30',
            branchId: null,
            branchCode: null,
            currencyId: 1,
            currencyCode: 'EUR',
            transactionType: 'BUY',
            transactionCount: 3,
            totalCurrencyAmount: 1500,
            totalHufAmount: 601875,
            weightedAverageRate: 401.25,
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

test('átlag árfolyam mobil nézetben base riport endpointból is renderel soros összesítőt', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/average-rate', { waitUntil: 'domcontentloaded' })

  const lineReportRequest = page.waitForRequest((request) => {
    const url = new URL(request.url())
    return (
      request.method() === 'GET' &&
      url.pathname === '/api/v1/reports/average-rate' &&
      url.searchParams.get('from') !== null &&
      url.searchParams.get('to') !== null
    )
  })

  await page.getByRole('button', { name: /Lekérdezés/i }).click()
  await lineReportRequest

  const summary = page.getByTestId('average-rate-line-summary')
  await expect(summary).toContainText('Soros súlyozott összesítő')
  await expect(summary).toContainText('EUR')
  await expect(summary).toContainText('Vétel')
  await expect(summary).toContainText('401,2500')
  await expect(summary).toContainText('601 875')

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
