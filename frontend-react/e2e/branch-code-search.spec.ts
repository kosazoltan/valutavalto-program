import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 1,
  workerCode: 'FOERT01',
  firstName: 'Fő',
  lastName: 'Értéktáros',
  fullName: 'Fő Értéktáros',
  role: 'ADMIN',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const branch = {
  id: 'b-1',
  code: 'BR027',
  name: 'Szeged Tesco',
  shortName: 'Tesco',
  address: '6723 Szeged, Rókusi krt. 42.',
  city: 'Szeged',
  email: 'szeged@ebc.hu',
  phone: '06701112233',
  region: 'SZEGED',
  isActive: true,
  isVault: false,
  hasAfa: true,
  hasWu: false,
  hasMg: false,
  hasPos: true,
}

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: [],
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
          permissions: [],
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

    if (path === '/api/v1/branches/code/BR027' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...branch, name: 'Backend kód találat' }),
      })
    }

    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([branch]) })
    }

    if (path.endsWith('/admin/branches') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: branch.id, workerCount: 3, lastSyncAt: null, syncStatus: 'SYNCED' }]),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
  })
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('FOERT01')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/central-workstation$/, { timeout: 15000 })
}

test('pénztár törzs mobil nézetben backend kód szerinti keresést használ', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/admin/branches', { waitUntil: 'domcontentloaded' })
  await expect(page).toHaveURL(/\/admin\/branches$/, { timeout: 15000 })
  await expect(page.getByTestId('branch-mobile-card').getByText('Szeged Tesco')).toBeVisible()

  const codeRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/branches/code/BR027'
  )
  await page.getByRole('textbox', { name: 'Pontos pénztárkód' }).fill('BR027')
  await page.getByRole('button', { name: 'Kód keresés' }).click()
  await codeRequest

  await expect(page.getByTestId('branch-code-result')).toContainText('Backend kód találat')

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
