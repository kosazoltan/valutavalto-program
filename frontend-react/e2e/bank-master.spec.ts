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

async function mockBankMasterApis(page: Page) {
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

    if (path.endsWith('/ertektar/bank-transactions') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
    }

    if (path.endsWith('/currencies') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
    }

    if (path.endsWith('/banks') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 'bank-1', name: 'Raiffeisen Bank', regionCode: '20' }]),
      })
    }

    if (path.endsWith('/banks') && method === 'POST') {
      expect(await route.request().postDataJSON()).toEqual({ name: 'Teszt Bank', regionCode: '30' })
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ id: 'bank-2', name: 'Teszt Bank', regionCode: '30' }),
      })
    }

    if (path.endsWith('/banks/bank-1') && method === 'DELETE') {
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

test('bank-törzs kezelő a backend bank CRUD végpontokat hívja mobil viewporton', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  page.on('dialog', dialog => void dialog.accept())
  await mockBankMasterApis(page)
  await login(page)

  await page.goto('/treasury/bank', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Bank-törzs')).toBeVisible()
  await expect(page.getByText('Raiffeisen Bank')).toBeVisible()

  const createRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().endsWith('/api/v1/banks')
  )
  await page.getByLabel(/Bank neve/i).fill('Teszt Bank')
  await page.getByLabel(/Területkód/i).fill('30')
  await page.getByRole('button', { name: /Felvétel/i }).click()
  await createRequest

  const deleteRequest = page.waitForRequest(request =>
    request.method() === 'DELETE' && request.url().endsWith('/api/v1/banks/bank-1')
  )
  await page.getByTitle('Deaktiválás').click()
  await deleteRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
