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

    if (path.endsWith('/features') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ camera: true, yearOpeningScheduler: true, navIntegration: true }),
      })
    }

    if (path.endsWith('/own-companies/active') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 'company-1', name: 'Exclusive Best Change Zrt.' }]),
      })
    }

    if (path.endsWith('/users/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: '77',
          workerId: '77',
          username: 'ADMIN',
          name: 'Admin Teszt',
          email: 'admin@example.com',
          role: 'ADMIN',
          roles: ['ADMIN'],
          isActive: true,
          defaultBranchName: 'Budapest 01',
          lastLoginAt: '2026-06-19T10:00:00',
          createdAt: '2026-06-18T10:00:00',
        }),
      })
    }

    if (path.endsWith('/users/me/password') && method === 'PUT') {
      const body = route.request().postDataJSON() as { oldPassword?: string; newPassword?: string }
      if (body.oldPassword !== 'old-password' || body.newPassword !== 'NewPass123') {
        return route.fulfill({
          status: 400,
          contentType: 'application/json',
          body: JSON.stringify({ message: 'Unexpected password payload' }),
        })
      }
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

test('beállítások mobil nézetben saját user profilt kér a backendből', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/settings', { waitUntil: 'domcontentloaded' })

  const userMeRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'GET' && url.pathname === '/api/v1/users/me'
  })
  await page.getByRole('button', { name: /Biztonság/i }).click()
  await userMeRequest

  const profile = page.getByTestId('own-user-profile')
  await expect(profile).toBeVisible()
  await expect(profile.getByText('ADMIN').first()).toBeVisible()
  await expect(profile.getByText('admin@example.com')).toBeVisible()
  await expect(profile.getByText('Budapest 01')).toBeVisible()

  const updatePasswordRequest = page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'PUT' && url.pathname === '/api/v1/users/me/password'
  })
  await page.getByLabel('Jelenlegi jelszó').fill('old-password')
  await page.getByLabel('Új jelszó', { exact: true }).fill('NewPass123')
  await page.getByLabel('Új jelszó ismét').fill('NewPass123')
  await page.getByRole('button', { name: 'Jelszó módosítása' }).click()
  await updatePasswordRequest
  await expect(page.getByText('Saját jelszó módosítva.')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
