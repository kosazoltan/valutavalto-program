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

    if (path === '/api/v1/roles' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'role-admin',
            code: 'ADMIN',
            name: 'ADMIN',
            description: 'Admin role',
            roleType: 'SYSTEM',
            isSystemRole: true,
            isActive: true,
            permissions: [],
          },
        ]),
      })
    }

    if (path === '/api/v1/users/1' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: '1',
          workerId: '42',
          username: 'admin.teszt',
          name: 'Backend Detail Felhasználó',
          email: 'detail@example.com',
          isActive: true,
          roles: ['ADMIN'],
          defaultBranchId: 'branch-1',
          defaultBranchName: 'Szeged Értéktár',
          createdAt: '2026-06-19T08:00:00',
        }),
      })
    }

    if (path === '/api/v1/users' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: '1',
            workerId: '42',
            username: 'admin.teszt',
            name: 'Lista Felhasználó',
            email: 'lista@example.com',
            isActive: true,
            roles: ['ADMIN'],
            defaultBranchName: 'Budapest',
            createdAt: '2026-06-19T08:00:00',
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

test('felhasználó admin mobil nézetben backend detailből nyit szerkesztést', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/settings/users', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Felhasználók' })).toBeVisible()
  await expect(page.getByText('Lista Felhasználó')).toBeVisible()

  const detailRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/users/1',
  )
  await page.getByRole('button', { name: 'Szerkesztés' }).click()
  await detailRequest

  await expect(page.getByRole('heading', { name: 'Felhasználó szerkesztése' })).toBeVisible()
  const modalInputs = page.locator('.fixed.inset-0 input')
  await expect(modalInputs.nth(1)).toHaveValue('Backend Detail Felhasználó')
  await expect(modalInputs.nth(2)).toHaveValue('detail@example.com')

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
