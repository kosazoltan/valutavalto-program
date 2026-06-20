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

const terminal = {
  id: '11111111-1111-1111-1111-111111111111',
  terminalId: 'TERM-1',
  terminalName: 'Fő kassza POS',
  branchId: 'branch-1',
  branchName: 'Szeged Értéktár',
  isActive: true,
  lastTransactionAt: '2026-06-18T08:00:00Z',
  connectionType: 'SERIAL',
  comPort: 'COM3',
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

    if (path.endsWith(`/pos-terminal/${terminal.id}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          ...terminal,
          connectionType: 'TCP',
          ipAddress: '10.0.0.15',
          comPort: null,
        }),
      })
    }

    if (path.endsWith('/pos-terminal') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([terminal]),
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

for (const viewport of [
  { name: 'desktop', width: 1280, height: 800 },
  { name: 'mobil', width: 390, height: 844 },
]) {
  test(`POS terminál részletek ${viewport.name} nézetben a backend detail endpointot használják`, async ({ page }) => {
    await page.setViewportSize({ width: viewport.width, height: viewport.height })
    await mockApis(page)
    await login(page)

    await page.goto('/pos-terminal', { waitUntil: 'domcontentloaded' })
    await expect(page.locator('button:visible', { hasText: 'Részletek' }).first()).toBeVisible()

    const detailRequest = page.waitForRequest(request =>
      request.method() === 'GET'
      && new URL(request.url()).pathname === `/api/v1/pos-terminal/${terminal.id}`
    )
    await page.locator('button:visible', { hasText: 'Részletek' }).first().click()
    await detailRequest

    await expect(page.getByTestId('pos-terminal-detail-panel')).toBeVisible()
    await expect(page.getByText('10.0.0.15')).toBeVisible()
    await expect(page.getByText('TCP')).toBeVisible()

    const horizontalOverflow = await page.evaluate(() =>
      document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
    )
    expect(horizontalOverflow).toBe(false)
  })
}
