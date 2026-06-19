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

    if (path.endsWith('/exchange-rate-display') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'display-1',
            displayName: 'Pénztári árfolyam kijelző',
            currencyIds: '[1,2]',
            refreshInterval: 30,
            isActive: true,
          },
        ]),
      })
    }

    if (path.endsWith('/exchange-rate-display/display-1/current-rates') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          displayId: 'display-1',
          displayName: 'Pénztári árfolyam kijelző',
          refreshInterval: 30,
          generatedAt: '2026-06-18T10:00:00',
          rates: [
            {
              currencyId: 1,
              currencyCode: 'EUR',
              currencyName: 'Euró',
              baseBuyRate: 390,
              baseSellRate: 402.5,
            },
          ],
        }),
      })
    }

    if (path.endsWith('/exchange-rate-display/display-1/update') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ok: true }),
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

test('/exchange-rate-display a backend current-rates objektumot előnézetként rendereli és string currencyIds-t ment', async ({ page }) => {
  await page.setViewportSize({ width: 1366, height: 768 })
  await mockApis(page)
  await login(page)

  await page.goto('/exchange-rate-display', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Pénztári árfolyam kijelző')).toBeVisible()

  await page.getByTitle('Előnézet').click()
  await expect(page.getByText(/KIJELZŐ ELŐNÉZET|Kijelző előnézet/i)).toBeVisible()
  await expect(page.getByText('EUR')).toBeVisible()
  await expect(page.getByText('390.00')).toBeVisible()
  await expect(page.getByText('402.50')).toBeVisible()

  await page.getByTitle('Szerkesztés').click()
  const currencyInput = page.getByPlaceholder('1,2,3,4')
  await expect(currencyInput).toHaveValue('1,2')
  await currencyInput.fill('1,3')

  const updateRequest = page.waitForRequest(request =>
    request.method() === 'POST'
    && request.url().includes('/exchange-rate-display/display-1/update')
    && request.postDataJSON()?.currencyIds === '[1,3]'
  )
  await page.getByRole('button', { name: 'Mentés' }).click()
  await updateRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
