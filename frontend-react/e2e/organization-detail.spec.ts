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

const organizationId = '11111111-1111-1111-1111-111111111111'

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

    if (path.endsWith(`/organizations/${organizationId}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: organizationId,
          code: 'ROOT',
          name: 'Backend root részlet',
          description: 'Backend detail description',
          isActive: true,
        }),
      })
    }

    if (path.endsWith('/organizations/active') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: organizationId, code: 'ROOT', name: 'Aktív root', isActive: true }]),
      })
    }

    if (path.endsWith('/organizations/root') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: organizationId, code: 'ROOT', name: 'Gyökér root', isActive: true }]),
      })
    }

    if (path.endsWith('/organizations') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: organizationId,
            code: 'ROOT',
            name: 'Lista root',
            description: 'Lista verzió',
            isActive: true,
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

test('szervezet oldal mobil nézetben aktív/root listákat és backend detailt használ', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/organizations', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('cell', { name: 'ROOT', exact: true })).toBeVisible()
  await expect(page.getByText('Aktív szervezet')).toBeVisible()
  await expect(page.getByText('Gyökér szervezet')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === `/api/v1/organizations/${organizationId}`
  )
  await page.getByRole('button', { name: /Szerk/i }).click()
  await detailRequest

  await expect(page.locator('input').nth(2)).toHaveValue('Backend root részlet')
  await expect(page.locator('textarea')).toHaveValue('Backend detail description')

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
