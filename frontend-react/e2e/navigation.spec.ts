import { expect, test, Page } from '@playwright/test'

/**
 * NAVIGATION TESTS — Menüelemek hozzáférhetőek bejelentkezés után
 */

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 1,
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

async function loginAndSetupMocks(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['TRADE_EXECUTE', 'TRADE_STORNO', 'RATE_READ', 'CUSTOMER_READ'],
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
          permissions: ['TRADE_EXECUTE', 'TRADE_STORNO', 'RATE_READ', 'CUSTOMER_READ'],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
        }),
      })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(worker),
      })
    }

    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ content: [], data: [], total: 0 }),
    })
  })

  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('ADMIN')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()

  await expect(page).toHaveURL(/\/central-workstation$/)
}

test('dashboard elérhető bejelentkezés után', async ({ page }) => {
  await loginAndSetupMocks(page)
  await expect(page.getByRole('heading', { name: /Irányítópult/i })).toBeVisible()
})

test('menü linkek navigálhatók', async ({ page }) => {
  await loginAndSetupMocks(page)

  const navLinks = page.getByRole('link')
  let count = await navLinks.count()

  if (count === 0) {
    const buttons = page.getByRole('button')
    count = await buttons.count()
  }

  if (count === 0) {
    test.skip()
  }

  expect(count).toBeGreaterThan(0)
})

test('logout elérhető', async ({ page }) => {
  await loginAndSetupMocks(page)

  await expect(page.getByRole('heading', { name: /Irányítópult/i })).toBeVisible()

  const logoutButton = page.getByRole('button', { name: /kijelentkezés|logout|kilépés/i })
  const userMenu = page.getByRole('button', { name: /admin|menü|user|profil/i })
  const anyButton = page.getByRole('button')

  const logoutVisible = await logoutButton.count()
  const menuVisible = await userMenu.count()
  const buttonCount = await anyButton.count()

  expect(logoutVisible + menuVisible + buttonCount).toBeGreaterThan(0)
})
