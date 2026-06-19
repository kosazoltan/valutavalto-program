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

async function mockNotificationApis(page: Page) {
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

    if (path.endsWith('/notifications') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'notification-1',
            title: 'Teszt értesítés',
            message: 'Teszt üzenet',
            type: 'INFO',
            isRead: false,
            createdAt: '2026-06-18T10:00:00',
          },
        ]),
      })
    }

    if (path.endsWith('/notifications/unread-count') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ count: 1 }) })
    }

    if (path.endsWith('/notifications/send') && method === 'POST') {
      expect(await route.request().postDataJSON()).toEqual({
        workerId: 12,
        title: 'Mobil teszt',
        message: 'Backend szerződés teszt',
        type: 'INFO',
      })
      return route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify({ id: 'notification-2' }),
      })
    }

    if (path.endsWith('/notifications') && method === 'POST') {
      expect(await route.request().postDataJSON()).toEqual({
        userId: '12',
        title: 'In-app teszt',
        message: 'Canonical backend szerződés teszt',
        type: 'INFO',
      })
      return route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify({ id: 'notification-3' }),
      })
    }

    if (path.endsWith('/notifications/notification-1/read') && method === 'PUT') {
      return route.fulfill({ status: 204 })
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

test('értesítés küldés workerId payloadot küld a backendnek', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockNotificationApis(page)
  await login(page)

  await page.goto('/notifications', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('1 Olvasatlan')).toBeVisible()
  const readRequest = page.waitForRequest(request =>
    request.method() === 'PUT' && request.url().includes('/notifications/notification-1/read')
  )
  await page.getByRole('button', { name: 'Olvasott', exact: true }).click()
  await readRequest

  await page.getByRole('button', { name: /Új értesítés/i }).click()

  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('Mobil teszt')
  await textboxes.nth(1).fill('Backend szerződés teszt')
  await textboxes.nth(2).fill('12')

  const sendRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/notifications/send')
  )
  await page.getByRole('button', { name: /^Küldés$/i }).click()
  await sendRequest

  await page.getByRole('button', { name: /Új értesítés/i }).click()
  await textboxes.nth(0).fill('In-app teszt')
  await textboxes.nth(1).fill('Canonical backend szerződés teszt')
  await textboxes.nth(2).fill('12')
  await page.getByTestId('notification-channel').selectOption('in-app')

  const inAppRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().endsWith('/api/v1/notifications')
  )
  await page.getByRole('button', { name: /^Küldés$/i }).click()
  await inAppRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
