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

async function mockBankOrderApis(page: Page) {
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

    if (path.endsWith('/bank-orders') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ content: [], totalElements: 0, totalPages: 0, number: 0, size: 100 }),
      })
    }

    if (path.endsWith('/western-union/daily-limit') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          businessDate: '2026-06-19',
          currencyCode: 'USD',
          dailyLimit: 10000,
          usedAmount: 1000,
          remainingAmount: 9000,
          usagePercent: 10,
          resetAt: '2026-06-20T00:00:00',
        }),
      })
    }

    if (path.endsWith('/western-union/daily-limit/use') && method === 'POST') {
      expect(await route.request().postDataJSON()).toEqual({
        amountUsd: 250,
        businessDate: '2026-06-19',
      })
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          businessDate: '2026-06-19',
          currencyCode: 'USD',
          dailyLimit: 10000,
          usedAmount: 1250,
          remainingAmount: 8750,
          usagePercent: 12.5,
        }),
      })
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

test('banki rendelések WU napi keret fallback mobil viewporton backend POST-ot hív', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  page.on('dialog', dialog => void dialog.accept())
  await mockBankOrderApis(page)
  await login(page)

  await page.goto('/bank-orders', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Western Union napi keret' })).toBeVisible()
  await expect(page.getByText(/9[\s\u00a0]?000 USD maradt/)).toBeVisible()

  await page.getByLabel(/Kézi fallback felhasználás/i).fill('250')
  const limitUseRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/western-union/daily-limit/use')
  )
  await page.getByRole('button', { name: /Keret felhasználás/i }).click()
  await limitUseRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
