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

    if (path.endsWith('/documents') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([]),
      })
    }

    if (path.endsWith('/document-scanner/devices') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          devices: [],
          mode: 'UPLOAD_BRIDGE',
          message: 'Hardver szkenner lista kliens oldalon érhető el.',
        }),
      })
    }

    if ((path.endsWith('/document-scanner/scan') || path.endsWith('/document-scanner/upload')) && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'scan-1',
          documentType: 'OTHER',
          fileName: 'scan.pdf',
          mimeType: 'application/pdf',
          fileSizeBytes: 4,
          scannedAt: '2026-06-18T10:00:00',
        }),
      })
    }

    if (path.endsWith('/scanned-documents/customer/12') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'scanned-1',
            documentType: 'ID_CARD',
            fileName: 'szemelyi.pdf',
            mimeType: 'application/pdf',
            fileSizeBytes: 4096,
            scannedAt: '2026-06-18T10:00:00',
            notes: 'Teszt okmány',
          },
        ]),
      })
    }

    if (path.endsWith('/scanned-documents/upload') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'scanned-2',
          documentType: 'OTHER',
          fileName: 'uj.pdf',
          mimeType: 'application/pdf',
          fileSizeBytes: 4,
          scannedAt: '2026-06-18T10:05:00',
        }),
      })
    }

    if (path.endsWith('/scanned-documents/scanned-1') && method === 'DELETE') {
      return route.fulfill({ status: 204, body: '' })
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

test('Dokumentumtár scanner panel a scan és upload backend végpontokat hívja', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/documents', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('UPLOAD_BRIDGE')).toBeVisible()

  const scanRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/document-scanner/scan')
  )
  await page.getByTestId('scanner-scan-input').setInputFiles({
    name: 'scan.pdf',
    mimeType: 'application/pdf',
    buffer: Buffer.from('scan'),
  })
  await scanRequest

  const uploadRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/document-scanner/upload')
  )
  await page.getByTestId('scanner-upload-input').setInputFiles({
    name: 'upload.png',
    mimeType: 'image/png',
    buffer: Buffer.from('upload'),
  })
  await uploadRequest

  await page.getByLabel('Azonosító').fill('12')
  const scannedListRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/scanned-documents/customer/12')
  )
  await page.getByRole('button', { name: /Lista/i }).click()
  await scannedListRequest
  await expect(page.getByText('szemelyi.pdf')).toBeVisible()

  const canonicalUploadRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/scanned-documents/upload')
  )
  await page.getByTestId('scanned-documents-upload-input').setInputFiles({
    name: 'uj.pdf',
    mimeType: 'application/pdf',
    buffer: Buffer.from('scan'),
  })
  await canonicalUploadRequest

  page.once('dialog', dialog => dialog.accept())
  const deleteRequest = page.waitForRequest(request =>
    request.method() === 'DELETE' && request.url().includes('/scanned-documents/scanned-1')
  )
  await page.getByTestId('scanned-documents-panel').getByRole('button', { name: /Törlés/i }).click()
  await deleteRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
