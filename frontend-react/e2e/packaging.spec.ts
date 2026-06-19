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

const branches = [{ id: 'branch-1', code: 'BUD01', name: 'Budapest 01', isActive: true }]
const currencies = [{ id: 1, code: 'EUR', name: 'Euró', decimals: 2, active: true }]
const record = {
  id: 'pack-1',
  branchId: 'branch-1',
  currencyCode: 'EUR',
  packagingDate: '2026-06-18',
  bundleCount: 2,
  denomination: 100,
  bundleSize: 100,
  notes: 'Teszt rekord',
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

    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(branches) })
    }

    if (path.endsWith('/currencies') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(currencies) })
    }

    if (path.endsWith('/packaging') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([record]) })
    }

    if (path.endsWith('/packaging') && method === 'POST') {
      const body = JSON.parse(route.request().postData() || '{}') as Record<string, unknown>
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...record, ...body, id: 'pack-2' }),
      })
    }

    if (path.endsWith('/packaging/pack-1') && method === 'DELETE') {
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

test('göngyöleg oldal mobilnézetben listáz, rögzít és töröl backend API-val', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  page.on('dialog', dialog => void dialog.accept())
  await login(page)

  await page.goto('/packaging', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Göngyöleg nyilvántartás')).toBeVisible()
  await expect(page.getByText('Teszt rekord')).toBeVisible()

  await page.getByTestId('packaging-denomination').fill('200')
  await page.getByTestId('packaging-bundle-count').fill('3')
  await page.getByTestId('packaging-notes').fill('Új rekord')

  const createRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/packaging')
  )
  await page.getByTestId('packaging-create').click()
  expect((await createRequest).postDataJSON()).toMatchObject({
    branchId: 'branch-1',
    currencyCode: 'EUR',
    denomination: 200,
    bundleCount: 3,
    bundleSize: 100,
    notes: 'Új rekord',
  })

  const deleteRequest = page.waitForRequest(request =>
    request.method() === 'DELETE' && request.url().includes('/packaging/pack-1')
  )
  await page.getByTitle('Törlés').click()
  await deleteRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
