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
        body: JSON.stringify({}),
      })
    }

    if (path.endsWith('/fees/types') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'fee-type-1',
            code: 'HANDLING',
            name: 'Kezelési díj',
            calculationMethod: 'FIXED',
            isActive: true,
          },
        ]),
      })
    }

    if (path.endsWith('/fees/rates') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'fee-rate-1',
            feeTypeId: 'fee-type-1',
            feeTypeName: 'Kezelési díj',
            currencyCode: 'EUR',
            rate: 1.5,
            validFrom: '2026-01-01',
            isActive: true,
          },
        ]),
      })
    }

    if (path.endsWith('/fees/discounts') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'fee-discount-1',
            code: 'VIP',
            name: 'VIP kedvezmény',
            discountType: 'PERCENT',
            discountValue: 10,
            validFrom: '2026-01-01',
            isActive: true,
          },
        ]),
      })
    }

    if (path.endsWith('/fees/types/fee-type-1') && method === 'DELETE') {
      return route.fulfill({ status: 204, body: '' })
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

test('Díjkezelés mobil nézetben törli a díjtípust backend végponton', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/fees', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: /Díjkezelés|fees\.dijkezeles/i })).toBeVisible()
  await expect(page.getByText('Kezelési díj')).toBeVisible()

  const deleteRequest = page.waitForRequest(
    (request) =>
      request.method() === 'DELETE' &&
      new URL(request.url()).pathname === '/api/v1/fees/types/fee-type-1',
  )
  page.once('dialog', (dialog) => dialog.accept())
  await page.getByRole('button', { name: /Törlés/i }).click()
  await deleteRequest

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
