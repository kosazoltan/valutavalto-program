import { expect, test, Page } from '@playwright/test'

/**
 * TRANSACTION TESTS — Tranzakciós oldal betöltés, form elemek láthatók
 */

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 1,
  workerCode: 'CASHIER',
  firstName: 'Cashier',
  lastName: 'Teszt',
  fullName: 'Cashier Teszt',
  role: 'CASHIER',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

async function loginForTransaction(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'CASHIER',
    permissions: ['TRADE_EXECUTE', 'TRADE_STORNO'],
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
          activeRole: 'CASHIER',
          permissions: ['TRADE_EXECUTE', 'TRADE_STORNO'],
          roles: ['CASHIER'],
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

    if (path.endsWith('/exchange-rates') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 1,
            currencyId: 1,
            currencyCode: 'EUR',
            currencyName: 'Euró',
            baseBuyRate: 391.5,
            baseSellRate: 398.5,
            active: true,
            createdAt: new Date().toISOString(),
            validDate: '2026-04-02',
            validTime: '10:00',
          },
        ]),
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
  await textboxes.nth(1).fill('CASHIER')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()

  await expect(page).toHaveURL(/\/(dashboard|cashier)$/)
}

test('tranzakciós oldal betöltődik', async ({ page }) => {
  await loginForTransaction(page)

  await page.goto('/transactions/new', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: /Új tranzakció/i })).toBeVisible()

  const inputs = page.locator('input')
  expect(await inputs.count()).toBeGreaterThanOrEqual(2)
})

test('tranzakciós form elemei láthatók és interaktívak', async ({ page }) => {
  await loginForTransaction(page)

  await page.goto('/transactions/new', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: /Új tranzakció/i })).toBeVisible()

  const buttons = page.getByRole('button')
  const buttonCount = await buttons.count()
  expect(buttonCount).toBeGreaterThan(0)

  const amountInputs = page.getByPlaceholder('0,00')
  await expect(amountInputs.nth(0)).toBeVisible()
  await expect(amountInputs.nth(1)).toBeVisible()
})
