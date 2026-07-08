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

const workstationId = '33333333-3333-3333-3333-333333333333'

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

    if (path.endsWith(`/workstations/${workstationId}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: workstationId,
          code: 'WST-1',
          name: 'Backend detail workstation',
          branchId: 'branch-1',
          machineName: 'BACKEND-PC',
          ipAddress: '10.0.0.11',
          macAddress: 'AA:BB:CC:DD:EE:FF',
          workstationType: 'CASHIER',
          softwareVersion: '2.28.11',
          isOnline: true,
          isActive: true,
        }),
      })
    }

    if (path.endsWith('/workstations/active') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: workstationId,
            code: 'WST-1',
            name: 'Aktív munkaállomás',
            workstationType: 'CASHIER',
            isOnline: true,
            isActive: true,
          },
        ]),
      })
    }

    if (path.endsWith('/workstations') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: workstationId,
            code: 'WST-1',
            name: 'Lista munkaállomás',
            branchId: 'branch-1',
            machineName: 'LIST-PC',
            ipAddress: '10.0.0.10',
            macAddress: '00:11:22:33:44:55',
            workstationType: 'CASHIER',
            softwareVersion: '2.28.11',
            isOnline: true,
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

test('munkaállomások oldal mobil nézetben active listát és backend detailt használ', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/workstations', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('cell', { name: 'WST-1', exact: true })).toBeVisible()
  await expect(page.getByText('Aktív munkaállomás')).toBeVisible()

  const detailRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === `/api/v1/workstations/${workstationId}`,
  )
  await page.getByRole('button', { name: /Szerk/i }).click()
  await detailRequest

  await expect(page.locator('input').nth(2)).toHaveValue('Backend detail workstation')
  await expect(page.locator('input').nth(3)).toHaveValue('BACKEND-PC')

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
