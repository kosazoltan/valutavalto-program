import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const shipment = {
  id: 'shipment-1',
  requestNumber: 'SH-001',
  fromBranchId: 'branch-1',
  fromBranchName: 'Szeged Értéktár',
  toBranchId: 'branch-2',
  toBranchName: 'Belváros',
  status: 'APPROVED',
  deliveryDate: '2026-06-18',
  requestedById: 77,
  requestedBy: 'Teszt Dolgozó',
  createdAt: '2026-06-18T10:00:00',
  carrierName: 'Teszt Szállító',
  sealNumber: 'PL-123',
  items: [{ id: 'item-1', currencyId: 1, currencyCode: 'EUR', requestedAmount: 1000 }],
}

const draftShipment = {
  ...shipment,
  status: 'DRAFT',
  deliveryDate: '2026-06-20',
  notes: 'Eredeti megjegyzés',
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

async function mockShipmentApis(page: Page, activeShipment = shipment) {
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

    if (path.endsWith('/shipments') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([activeShipment]) })
    }

    if (path.endsWith('/shipments/shipment-1') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(activeShipment) })
    }

    if (path.endsWith('/shipments/shipment-1') && method === 'PUT') {
      const body = JSON.parse(route.request().postData() || '{}') as Record<string, unknown>
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...activeShipment, ...body, status: 'DRAFT' }),
      })
    }

    if (path.endsWith('/shipments/shipment-1/deliver') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...shipment, status: 'DELIVERED' }),
      })
    }

    if (path.endsWith('/shipments/shipment-1/cancel') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...shipment, status: 'CANCELLED' }),
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

test('szállítmány lista detail, deliver és cancel backend workflow-t hív', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockShipmentApis(page)
  page.on('dialog', dialog => void dialog.accept())
  await login(page)

  await page.goto('/shipments', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('SH-001')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/shipments/shipment-1')
  )
  await page.getByTitle('Részletek').click()
  await detailRequest
  await expect(page.getByTestId('shipment-detail-panel')).toContainText('PL-123')

  const deliverRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/shipments/shipment-1/deliver')
  )
  await page.getByTitle('Kézbesítés').click()
  await deliverRequest

  const cancelRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/shipments/shipment-1/cancel')
  )
  await page.getByTitle('Visszavonás').click()
  await cancelRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})

test('szállítmány DRAFT szerkesztés mobilnézetben PUT /shipments/{id} backendhez kötött', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockShipmentApis(page, draftShipment)
  await login(page)

  await page.goto('/shipments', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('SH-001')).toBeVisible()
  await page.getByTitle('Részletek').click()
  await expect(page.getByTestId('shipment-detail-panel')).toContainText('PL-123')
  await page.getByTestId('shipment-start-edit').click()

  await page.getByTestId('shipment-edit-carrier').fill('Új Szállító')
  await page.getByTestId('shipment-edit-seal').fill('PL-999')
  await page.getByTestId('shipment-edit-notes').fill('Módosított megjegyzés')

  const updateRequest = page.waitForRequest(request =>
    request.method() === 'PUT' && request.url().includes('/shipments/shipment-1')
  )
  await page.getByTestId('shipment-save-edit').click()
  const request = await updateRequest
  expect(request.postDataJSON()).toMatchObject({
    fromBranchId: 'branch-1',
    toBranchId: 'branch-2',
    deliveryDate: '2026-06-20',
    carrierName: 'Új Szállító',
    sealNumber: 'PL-999',
    notes: 'Módosított megjegyzés',
  })

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
