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

const permissionId = '11111111-1111-1111-1111-111111111111'

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

    if (path.endsWith('/permissions/module/TRANSACTION') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: permissionId,
            code: 'TRANSACTION_CREATE',
            name: 'Tranzakció létrehozás',
            description: 'Backend module result',
            module: 'TRANSACTION',
            isSystemPermission: true,
            isActive: true,
            createdAt: '2026-06-01T00:00:00',
          },
        ]),
      })
    }

    if (path.endsWith('/permissions') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: permissionId,
            code: 'TRANSACTION_CREATE',
            name: 'Tranzakció létrehozás',
            description: 'Lista tranzakció',
            module: 'TRANSACTION',
            isSystemPermission: true,
            isActive: true,
            createdAt: '2026-06-01T00:00:00',
          },
          {
            id: 'permission-2',
            code: 'REPORT_READ',
            name: 'Riport olvasás',
            description: 'Lista riport',
            module: 'REPORT',
            isSystemPermission: true,
            isActive: true,
            createdAt: '2026-06-01T00:00:00',
          },
        ]),
      })
    }

    if (path === `/api/v1/permissions/${permissionId}` && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: permissionId,
          code: 'TRANSACTION_CREATE',
          name: 'Backend Detail Jogosultság',
          description: 'Backend detail result',
          module: 'TRANSACTION',
          isSystemPermission: true,
          isActive: true,
          createdAt: '2026-06-01T00:00:00',
        }),
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

test('jogosultság oldal mobil nézetben backend modul- és detail endpointot használ', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/settings/permissions', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('cell', { name: 'TRANSACTION_CREATE', exact: true })).toBeVisible()

  const moduleRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/permissions/module/TRANSACTION'
  )
  await page.locator('#permission-module-filter').selectOption('TRANSACTION')
  await moduleRequest

  await expect(page.getByText('Backend module result')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === `/api/v1/permissions/${permissionId}`
  )
  await page.getByRole('button', { name: 'Szerkesztés' }).click()
  await detailRequest

  await expect(page.getByRole('heading', { name: 'Jogosultság szerkesztése' })).toBeVisible()
  const modalInputs = page.locator('.fixed.inset-0 input')
  await expect(modalInputs.nth(1)).toHaveValue('Backend Detail Jogosultság')
  await expect(page.locator('.fixed.inset-0 textarea')).toHaveValue('Backend detail result')

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
