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

    if (path === '/api/v1/employees' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 42,
            lastName: 'Teszt',
            firstName: 'Elek',
            organizationUnit: 'Szeged',
            jobTitle: 'Valutapénztáros',
            feorCode: '4211',
            employmentStartDate: '2026-01-01',
            active: true,
          },
        ]),
      })
    }

    if (path === '/api/v1/employees/feor-codes' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 1, code: '4211', title: 'Banki pénztáros' }]),
      })
    }

    if (path === '/api/v1/employees/42' && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ id: 42, workerId: 77 }) })
    }

    if (path === '/api/v1/workers/77' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ id: 77, workerCode: 'BORSI', fullName: 'Borsi Teszt', companyCode: 'EBC' }),
      })
    }

    if (path === '/api/v1/auth/worker-setup-token' && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          companyCode: 'EBC',
          workerCode: 'BORSI',
          workerName: 'Borsi Teszt',
          token: 'setup-token-123',
          expiresAt: '2026-06-21T10:00:00Z',
        }),
      })
    }

    if (path === '/api/v1/employees/42/occupational-health' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 1, status: 'Érvényes', examDate: '2026-06-18', result: 'Alkalmas' }]),
      })
    }

    if (path === '/api/v1/employees/42/vacations' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 2, year: 2026, vacationDays: 20, takenVacation: 4 }]),
      })
    }

    if (path === '/api/v1/employees/42/children' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 3, name: 'Teszt Gyermek', birthDate: '2020-01-01' }]),
      })
    }

    if (path === '/api/v1/worker-management/42/attendance' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ content: [{ id: 'att-1', loginAt: '2026-06-18T08:00:00', logoutAt: null }] }),
      })
    }

    if (path === '/api/v1/workers/42/roles' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(['penztaros']),
      })
    }

    if (path === '/api/v1/workers/42/roles/foertektar' && method === 'POST') {
      return route.fulfill({ status: 201, contentType: 'application/json', body: JSON.stringify({}) })
    }

    if (path === '/api/v1/workers/42/roles/penztaros' && method === 'DELETE') {
      return route.fulfill({ status: 204, body: '' })
    }

    if (path === '/api/v1/workers/42/unlock-login' && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ remainingSeconds: 30 }),
      })
    }

    if (path.startsWith('/api/v1/worker-management/42/') && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ id: 'ok' }) })
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

test('dolgozókezelő modal valós Chromium nézetben backend műveleteket indít', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  const feorRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/employees/feor-codes'
  )
  await page.goto('/employees', { waitUntil: 'domcontentloaded' })
  await feorRequest
  await expect(page.getByTestId('employee-feor-summary')).toContainText('FEOR referencia kódok: 1')
  const mobileCard = page.getByTestId('employee-mobile-card')
  await expect(mobileCard.getByText('Teszt Elek')).toBeVisible()
  await expect(mobileCard).toContainText('FEOR: 4211')
  await mobileCard.getByTitle('Al-nyilvántartások').click()
  await expect(page.getByText('Vezetői dolgozókezelés')).toBeVisible()
  await expect(page.getByText('2026-06-18 08:00')).toBeVisible()
  await expect(page.getByTestId('worker-role-list')).toContainText('penztaros')

  await page.getByTestId('worker-break-reason').fill('Ebédszünet')
  const startBreak = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/worker-management/42/break-start')
  )
  await page.getByTestId('worker-break-start').click()
  await startBreak

  const endBreak = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/worker-management/42/break-end')
  )
  await page.getByTestId('worker-break-end').click()
  await endBreak

  await page.getByTestId('worker-new-password').fill('Teszt1234')
  const resetPassword = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/worker-management/42/reset-password')
  )
  await page.getByTestId('worker-reset-password').click()
  await resetPassword

  const setupToken = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/auth/worker-setup-token')
  )
  await page.getByTestId('worker-setup-token-issue').click()
  const setupTokenRequest = await setupToken
  expect(setupTokenRequest.postDataJSON()).toEqual({ companyCode: 'EBC', workerCode: 'BORSI' })
  await expect(page.getByTestId('worker-setup-token-result')).toContainText('setup-token-123')

  await page.getByTestId('worker-role-code').fill('foertektar')
  const addRole = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/workers/42/roles/foertektar')
  )
  await page.getByTestId('worker-role-add').click()
  await addRole

  const removeRole = page.waitForRequest(request =>
    request.method() === 'DELETE' && request.url().includes('/workers/42/roles/penztaros')
  )
  await page.getByTestId('worker-role-remove-penztaros').click()
  await removeRole

  const unlockLogin = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/workers/42/unlock-login')
  )
  await page.getByTestId('worker-unlock-login').click()
  await unlockLogin

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
