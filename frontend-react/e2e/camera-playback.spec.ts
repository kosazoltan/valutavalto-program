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

async function mockCameraPlaybackApis(page: Page) {
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

    if (path.endsWith('/features') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ camera: true, yearOpeningScheduler: true, navIntegration: true }),
      })
    }

    if (path.endsWith('/branches') && method === 'GET' && url.searchParams.get('activeOnly') === 'true') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: '11111111-1111-1111-1111-111111111111', code: 'BUD01', name: 'Budapest 01' },
        ]),
      })
    }

    if (path.endsWith('/camera/recordings') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'rec-1',
            branchId: url.searchParams.get('branchId'),
            cameraId: 'CAM-01',
            startTime: '2026-06-18T08:00:00',
            endTime: '2026-06-18T08:10:00',
            fileSizeBytes: 1024,
            uploadedToServer: true,
            expiresAt: '2026-08-01',
            status: 'COMPLETED',
            linkedTransactions: 1,
          },
        ]),
      })
    }

    if (path.endsWith('/camera/recordings/rec-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'rec-1',
          branchId: '11111111-1111-1111-1111-111111111111',
          cameraId: 'CAM-01',
          startTime: '2026-06-18T08:00:00',
          endTime: '2026-06-18T08:10:00',
          fileSizeBytes: 1024,
          uploadedToServer: true,
          expiresAt: '2026-08-01',
          status: 'COMPLETED',
          linkedTransactions: 1,
        }),
      })
    }

    if (path.endsWith('/camera/recordings/by-receipt/V0001') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'link-receipt-1',
            recording: {
              id: 'rec-1',
              branchId: '11111111-1111-1111-1111-111111111111',
              cameraId: 'CAM-01',
              startTime: '2026-06-18T08:00:00',
              endTime: '2026-06-18T08:10:00',
              fileSizeBytes: 1024,
              uploadedToServer: true,
              expiresAt: '2026-08-01',
              status: 'COMPLETED',
              linkedTransactions: 1,
            },
            transactionId: 123,
            receiptNumber: 'V0001',
            transactionTime: '2026-06-18T08:05:00',
            frameOffsetSeconds: 300,
          },
        ]),
      })
    }

    if (path.endsWith('/camera/recordings/by-transaction/123') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'link-transaction-1',
            recording: {
              id: 'rec-1',
              branchId: '11111111-1111-1111-1111-111111111111',
              cameraId: 'CAM-01',
              startTime: '2026-06-18T08:00:00',
              endTime: '2026-06-18T08:10:00',
              fileSizeBytes: 1024,
              uploadedToServer: true,
              expiresAt: '2026-08-01',
              status: 'COMPLETED',
              linkedTransactions: 1,
            },
            transactionId: 123,
            receiptNumber: 'V0001',
            transactionTime: '2026-06-18T08:05:00',
            frameOffsetSeconds: 300,
          },
        ]),
      })
    }

    if (path.endsWith('/camera/admin/access-logs/rec-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'log-1', workerId: 77, action: 'VIEW', createdAt: '2026-06-18T08:11:00' },
          { id: 'log-2', workerId: 78, action: 'VIEW', createdAt: '2026-06-18T08:12:00' },
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

test('kamera visszajátszás branch-csel keres és felvétel részletet tölt mobil viewporton', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockCameraPlaybackApis(page)
  await login(page)

  await page.goto('/camera/playback', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Felvétel visszajátszás')).toBeVisible()
  await page.getByTestId('camera-playback-branch').selectOption('11111111-1111-1111-1111-111111111111')
  await page.getByLabel('Kezdő dátum').fill('2026-06-18')
  await page.getByLabel('Záró dátum').fill('2026-06-18')

  const recordingsRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && request.url().includes('/camera/recordings')
    && request.url().includes('branchId=11111111-1111-1111-1111-111111111111')
  )
  await page.getByRole('button', { name: 'Keresés', exact: true }).click()
  await recordingsRequest
  await expect(page.getByTestId('camera-server-recording-rec-1')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/camera/recordings/rec-1')
  )
  const accessLogRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/camera/admin/access-logs/rec-1')
  )
  await page.getByTestId('camera-server-recording-rec-1').click()
  await detailRequest
  await accessLogRequest
  await expect(page.getByText('Felvétel részletek')).toBeVisible()
  await expect(page.getByTestId('camera-access-log-count')).toHaveText('2')

  const receiptRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/camera/recordings/by-receipt/V0001')
  )
  await page.getByLabel('Bizonylatszám').fill('V0001')
  await page.getByRole('button', { name: 'Bizonylat keresés' }).click()
  await receiptRequest
  await expect(page.getByTestId('camera-linked-recording-link-receipt-1')).toBeVisible()

  const transactionRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().includes('/camera/recordings/by-transaction/123')
  )
  await page.getByLabel('Tranzakció ID').fill('123')
  await page.getByRole('button', { name: 'Tranzakció keresés' }).click()
  await transactionRequest
  await expect(page.getByTestId('camera-linked-recording-link-transaction-1')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
