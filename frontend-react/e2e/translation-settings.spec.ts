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

async function mockTranslationApis(page: Page) {
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

    if (path.endsWith('/own-companies/active') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([{ id: 'company-1', name: 'EBC Zrt.' }]) })
    }

    if (path === '/api/v1/translations/hu/UI' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ 'settings.title': 'Beállítások' }),
      })
    }

    if (path === '/api/v1/translations/hu' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ 'common.save': 'Mentés', 'common.cancel': 'Mégse' }),
      })
    }

    if (path === '/api/v1/translations' && method === 'POST') {
      const body = JSON.parse(route.request().postData() || '{}') as Record<string, unknown>
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ id: 1, ...body }),
      })
    }

    if (path === '/api/v1/translations/import' && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ imported: 1, languageCode: 'hu' }),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ content: [], data: [] }) })
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

test('fordítás beállítás mobil viewporton kezeli a translations backend szerződést', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockTranslationApis(page)
  await login(page)

  await page.goto('/settings', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: /Fordítások/i }).click()
  await expect(page.getByRole('heading', { name: 'Fordítások' })).toBeVisible()

  const languageRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().endsWith('/api/v1/translations/hu')
  )
  await page.getByRole('button', { name: 'Nyelv' }).click()
  await languageRequest
  await expect(page.getByText('common.save').first()).toBeVisible()

  const moduleRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().endsWith('/api/v1/translations/hu/UI')
  )
  await page.getByRole('button', { name: 'Modul' }).click()
  await moduleRequest
  await expect(page.getByText('settings.title').first()).toBeVisible()

  await page.getByRole('textbox', { name: 'Fordítás', exact: true }).fill('Mentés most')
  const saveRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().endsWith('/api/v1/translations')
  )
  await page.getByRole('button', { name: 'Fordítás mentése' }).click()
  await saveRequest
  await expect(page.getByText('Mentés most').first()).toBeVisible()

  await page.getByLabel('Fordítás JSON import').fill('{"settings.title":"Beállítások"}')
  const importRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().endsWith('/api/v1/translations/import')
  )
  await page.getByRole('button', { name: 'Import' }).click()
  await importRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
