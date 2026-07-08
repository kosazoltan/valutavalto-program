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

    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'cashdesk-1', code: 'C1', name: 'Küldő pénztár', isActive: true },
          { id: 'cashdesk-2', code: 'C2', name: 'Fogadó pénztár', isActive: true },
        ]),
      })
    }

    if (path.endsWith('/handover-sheets') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'sheet-1',
            sheetNumber: 'HL-001',
            fromCashDeskId: 'cashdesk-1',
            fromCashDeskName: 'Lista küldő',
            toCashDeskId: 'cashdesk-2',
            toCashDeskName: 'Lista fogadó',
            transferDate: '2026-06-19',
            amounts: {},
            status: 'DRAFT',
          },
        ]),
      })
    }

    if (path.endsWith('/handover-sheets/sheet-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'sheet-1',
          sheetNumber: 'HL-001-DETAIL',
          fromCashDeskId: 'cashdesk-1',
          fromCashDeskName: 'Backend küldő',
          toCashDeskId: 'cashdesk-2',
          toCashDeskName: 'Backend fogadó',
          transferDate: '2026-06-20',
          amounts: { EUR: 100 },
          status: 'READY',
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

test('átadó lap részletei valós renderben lekérik a backend detail endpointot', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/handover-sheets', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('HL-001')).toBeVisible()

  const detailRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/handover-sheets/sheet-1',
  )
  await page.getByRole('button', { name: /Részletek/i }).click()
  await detailRequest

  await expect(page.getByText('HL-001-DETAIL')).toBeVisible()
  await expect(page.getByText('Backend küldő').first()).toBeVisible()
  await expect(page.getByText('Backend fogadó').first()).toBeVisible()
  await expect(page.getByText('READY')).toBeVisible()

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
