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
  branchId: 'branch-own',
  branchCode: 'SZEGED',
  branchName: 'Szeged Értéktár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const pendingTransfer = {
  id: 7,
  transferNumber: 'AT-LIST-007',
  fromBranchCode: 'BR001',
  fromBranchName: 'Budapesti értéktár',
  toBranchCode: 'SZEGED',
  toBranchName: 'Szeged Értéktár',
  fromWorkerName: 'Lista Béla',
  transferDate: '2026-06-19',
  transferTime: '10:00:00',
  currencyCode: 'EUR',
  amount: 100,
  hufValue: 39000,
  status: 'PENDING',
  statusDisplay: 'Átvételre vár',
  isPending: true,
  isCompleted: false,
  direction: 'U',
  transferType: 'CURRENCY',
  transferTypeDisplay: 'Deviza',
}

const detailedTransfer = {
  ...pendingTransfer,
  transferNumber: 'AT-BACKEND-007',
  fromWorkerName: 'Backend Anna',
  amount: 125.5,
  hufValue: 48945,
}

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['READ', 'WRITE', 'TRANSFER_WRITE'],
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
          permissions: ['READ', 'WRITE', 'TRANSFER_WRITE'],
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

    if (path.endsWith('/transfers/outgoing') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
    }

    if (path.endsWith('/transfers/incoming') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
    }

    if (path.endsWith('/transfers/pending') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([pendingTransfer]) })
    }

    if (path.endsWith('/transfers/pending/count') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(1) })
    }

    if (path.endsWith('/transfers/7') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(detailedTransfer) })
    }

    if (path.endsWith('/currencies') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 1, code: 'EUR', name: 'Euró', active: true, decimals: 2 }]),
      })
    }

    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'branch-own', code: 'SZEGED', name: 'Szeged Értéktár', isVault: true, branchTypeCode: 'VAULT' },
          { id: 'branch-source', code: 'BR001', name: 'Budapesti értéktár', isVault: true, branchTypeCode: 'VAULT' },
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

test('átadás átvétel mobil nézetben backend detail endpointból frissíti a modalt', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/transfers', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('AT-LIST-007')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/v1/transfers/7'
  )
  await page.getByRole('button', { name: 'Átvétel', exact: true }).click()
  await detailRequest

  await expect(page.getByText('AT-BACKEND-007')).toBeVisible()
  await expect(page.getByText('Backend Anna')).toBeVisible()
  await expect(page.getByLabel('Átvett összeg')).toHaveValue('125,5')

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
