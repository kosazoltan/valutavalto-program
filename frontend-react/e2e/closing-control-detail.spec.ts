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

const branchId = '11111111-1111-1111-1111-111111111111'

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

    if (path.endsWith('/closing-control/status') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            branchId,
            branchCode: 'BR010',
            branchName: 'Lista Szekszárd',
            branchCity: 'Szekszárd',
            controlDate: '2026-06-19',
            dailyClosingDone: false,
            eveningClosingDone: false,
            navClosingDone: false,
            alertLevel: 'NONE',
          },
        ]),
      })
    }

    if (path.endsWith(`/closing-control/branch/${branchId}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          branchId,
          branchCode: 'BR010',
          branchName: 'Backend Szekszárd',
          branchCity: 'Szekszárd',
          controlDate: '2026-06-19',
          dailyClosingDone: true,
          eveningClosingDone: false,
          navClosingDone: true,
          lastTransactionAt: '2026-06-19T18:40:00',
          alertLevel: 'WARNING',
          notes: 'Backend detail megjegyzés',
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

test('zárásfelügyelet részletei mobil nézetben lekérik a backend branch detail endpointot', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/central/closing-control', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('BR010')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === `/api/v1/closing-control/branch/${branchId}`
  )
  await page.getByRole('button', { name: /Részletek lekérése/i }).click()
  await detailRequest

  await expect(page.getByText('Backend Szekszárd, Szekszárd')).toBeVisible()
  await expect(page.getByText('Napi zárás: rendben')).toBeVisible()
  await expect(page.getByText('Esti zárás: hiányzik')).toBeVisible()
  await expect(page.getByText('NAV zárás: rendben')).toBeVisible()
  await expect(page.getByText(/Backend detail megjegyzés/)).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
