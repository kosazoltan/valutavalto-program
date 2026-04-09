import { expect, test } from '@playwright/test'

const worker = {
  id: 1,
  workerCode: 'BORSI',
  firstName: 'Borsi',
  lastName: 'Teszt',
  fullName: 'Borsi Teszt',
  role: 'ADMIN',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')

  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

test('a webes login reload utan is bent tartja a sessiont', async ({ page }) => {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['TRADE_EXECUTE'],
  })

  let workersMeRequests = 0

  await page.route('**/api/v1/**', async route => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const method = route.request().method()

    if (path === '/api/v1/auth/login' && method === 'POST') {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          token,
          tokenType: 'Bearer',
          expiresAt: new Date(Date.now() + 3600_000).toISOString(),
          worker,
          activeRole: 'ADMIN',
          permissions: ['TRADE_EXECUTE'],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
        }),
      })
      return
    }

    if (path === '/api/v1/workers/me' && method === 'GET') {
      workersMeRequests += 1
      const authHeader = route.request().headers().authorization

      await route.fulfill({
        status: authHeader === `Bearer ${token}` ? 200 : 401,
        contentType: 'application/json',
        body: JSON.stringify(worker),
      })
      return
    }

    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: '{}',
    })
  })

  await page.goto('/login')

  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('BORSI')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: 'Bejelentkezés' }).click()

  await expect(page).toHaveURL(/\/dashboard$/)
  await expect(page.locator('main, h1, h2, [role="heading"]').first()).toBeVisible()
  await expect.poll(async () => page.evaluate(() => localStorage.getItem('auth_token'))).toBe(token)

  await page.reload()

  await expect(page).toHaveURL(/\/dashboard$/)
  await expect(page.locator('main, h1, h2, [role="heading"]').first()).toBeVisible()
  await expect.poll(async () => page.evaluate(() => localStorage.getItem('auth_token'))).toBe(token)
  expect(workersMeRequests).toBeGreaterThanOrEqual(1)
})
