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

    if (path === '/api/v1/customers/code/U000001' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 1,
          customerCode: 'U000001',
          name: 'Backend Kód Ügyfél',
          birthDate: '1985-03-15',
          nationality: 'Magyar',
          documentType: 'Személyi ig.',
          documentNumber: '123456AB',
          phone: '+36301234567',
          isCompany: false,
          active: true,
          isVip: false,
          transactionCount: 0,
          createdAt: '2026-06-19T08:00:00',
        }),
      })
    }

    if (path === '/api/v1/customers/search' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 3,
            customerCode: 'U000003',
            name: 'Backend Név Ügyfél',
            birthDate: '1981-04-10',
            nationality: 'Magyar',
            documentType: 'Személyi ig.',
            documentNumber: 'NEV123',
            phone: '+36302223333',
            isCompany: false,
            active: true,
            isVip: false,
            transactionCount: 3,
            createdAt: '2026-06-19T08:00:00',
          },
        ]),
      })
    }

    if (path === '/api/v1/customers/vip' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 4,
            customerCode: 'U000004',
            name: 'VIP Ügyfél',
            birthDate: '1970-01-01',
            nationality: 'Magyar',
            documentType: 'Útlevél',
            documentNumber: 'VIP123',
            phone: '+36304445555',
            isCompany: false,
            active: true,
            isVip: true,
            transactionCount: 14,
            createdAt: '2026-06-19T08:00:00',
          },
        ]),
      })
    }

    if (path === '/api/v1/customers/frequent' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { customerId: 5, customerName: 'Gyakori Ügyfél', transactionCount: 9, totalVolumeHuf: 2200000, rank: 1 },
        ]),
      })
    }

    if (path === '/api/v1/customers/top' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { customerId: 6, customerName: 'Top Ügyfél', transactionCount: 11, totalVolumeHuf: 5400000, rank: 1 },
        ]),
      })
    }

    if (path === '/api/v1/customers/active' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 2,
            customerCode: 'U000002',
            name: 'Lista Ügyfél',
            birthDate: '1990-07-22',
            nationality: 'Magyar',
            documentType: 'Útlevél',
            documentNumber: 'AB1234567',
            phone: '+36309876543',
            isCompany: false,
            active: true,
            isVip: false,
            transactionCount: 0,
            createdAt: '2026-06-19T08:00:00',
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

test('ügyfél lista mobil nézetben ügyfélkód alapján backend detail lookupot használ', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  const vipRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/customers/vip'
  )
  const frequentRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/customers/frequent'
  )
  const topRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/customers/top'
  )
  await page.goto('/customers', { waitUntil: 'domcontentloaded' })
  await Promise.all([vipRequest, frequentRequest, topRequest])
  await expect(page.getByRole('heading', { name: 'Ügyfelek' })).toBeVisible()
  await expect(page.getByText('Lista Ügyfél')).toBeVisible()
  await expect(page.getByTestId('customer-highlight-panel')).toBeVisible()
  await expect(page.getByText('VIP Ügyfél')).toBeVisible()
  await expect(page.getByText('Gyakori Ügyfél')).toBeVisible()
  await expect(page.getByText('Top Ügyfél')).toBeVisible()

  const codeRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/customers/code/U000001'
  )
  await page.getByPlaceholder('Ügyfélkód pontos keresése...').fill('U000001')
  await page.getByRole('button', { name: 'Ügyfélkód keresés' }).click()
  await codeRequest

  await expect(page.getByText('Backend Kód Ügyfél')).toBeVisible()
  await expect(page.getByText('U000001')).toBeVisible()

  const nameRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/customers/search'
  )
  await page.getByPlaceholder('Keresés név vagy okmányszám alapján...').fill('Backend')
  await page.getByRole('button', { name: 'Név szerinti keresés' }).click()
  await nameRequest
  await expect(page.getByText('Backend Név Ügyfél')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
