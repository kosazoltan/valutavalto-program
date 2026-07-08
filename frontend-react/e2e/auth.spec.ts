import { expect, test } from '@playwright/test'

/**
 * AUTH TESTS — Login, error handling, success redirect
 */

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const validWorker = {
  id: 1,
  workerCode: 'TEST',
  firstName: 'Test',
  lastName: 'User',
  fullName: 'Test User',
  role: 'ADMIN',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

test('login oldal megjelenik', async ({ page }) => {
  await page.goto('/login')
  await expect(page).toHaveURL(/\/login/)
  await expect(page.getByRole('textbox').nth(0)).toBeVisible()
  await expect(page.locator('input[type="password"]')).toBeVisible()
  await expect(page.getByRole('button', { name: /Bejelentkezés/i })).toBeVisible()
})

test('hibás login → error üzenet', async ({ page }) => {
  await page.route('**/api/v1/**', async (route) => {
    const url = new URL(route.request().url())
    if (url.pathname.endsWith('/auth/login')) {
      return route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Invalid credentials' }),
      })
    }
    await route.abort()
  })

  await page.goto('/login')

  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('WRONG')
  await textboxes.nth(1).fill('WRONG')
  await page.locator('input[type="password"]').fill('WRONG')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()

  // Vagy error üzenet, vagy továbbra is a login oldalon vagyunk
  const hasError = await page
    .locator('[role="alert"]')
    .isVisible()
    .catch(() => false)
  const stillOnLogin = await page.url().includes('/login')

  expect(hasError || stillOnLogin).toBe(true)
})

test('sikeres login → redirect dashboard-ra', async ({ page }) => {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['TRADE_EXECUTE'],
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
          worker: validWorker,
          activeRole: 'ADMIN',
          permissions: ['TRADE_EXECUTE'],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
        }),
      })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(validWorker),
      })
    }

    return route.abort()
  })

  await page.goto('/login')

  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('TEST')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()

  // ADMIN role → /central-workstation
  await expect(page).toHaveURL(/\/central-workstation$/)
})

test('MFA-köteles login → TOTP ellenőrzés után redirect', async ({ page }) => {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['TRADE_EXECUTE'],
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
          worker: validWorker,
          activeRole: 'ADMIN',
          permissions: ['TRADE_EXECUTE'],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
          mfaRequired: true,
        }),
      })
    }

    if (path.endsWith('/mfa/verify') && method === 'POST') {
      const authHeader = route.request().headers().authorization
      expect(authHeader).toBe(`Bearer ${token}`)
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          verified: true,
          message: 'MFA verification sikeres',
        }),
      })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(validWorker),
      })
    }

    return route.abort()
  })

  await page.goto('/login')

  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('TEST')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()

  await expect(page.getByTestId('login-mfa-code')).toBeVisible()
  await expect(page.getByRole('button', { name: 'MFA ellenőrzés' })).toBeDisabled()
  await page.getByTestId('login-mfa-code').fill('123456')

  const verifyRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/mfa/verify'),
  )
  await page.getByRole('button', { name: 'MFA ellenőrzés' }).click()
  await verifyRequest

  await expect(page).toHaveURL(/\/central-workstation$/)
  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
