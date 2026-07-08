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

async function mockMobileApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['READ', 'WRITE'],
    roles: ['ADMIN'],
  })

  await page.route('**/api/v1/**', async (route) => {
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
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ token }),
      })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(worker),
      })
    }

    if (
      path.match(/\/api\/v1\/transfer-documents\/[^/]+\/(pickup|deliver|confirm)$/) &&
      method === 'PUT'
    ) {
      const action = path.split('/').at(-1)
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 101,
          documentNumber: 'ATD-101',
          sourceType: 'BRANCH',
          sourceId: 'SZEGED',
          destinationType: 'BRANCH',
          destinationId: 'BUD01',
          currencyCode: 'EUR',
          quantity: 500,
          status:
            action === 'pickup' ? 'PICKED_UP' : action === 'deliver' ? 'DELIVERED' : 'CONFIRMED',
        }),
      })
    }

    if (path.endsWith('/scanned-documents/upload') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'scan-new',
          customerId: 42,
          documentType: 'ID_CARD',
          fileName: 'mobil-id.jpg',
          mimeType: 'image/jpeg',
          fileSizeBytes: 12,
          scannedAt: '2026-06-18T10:05:00',
        }),
      })
    }

    if (
      path.match(
        /\/api\/v1\/ertektar\/(collections|distribution|bank-transactions)\/\d+\/status$/,
      ) &&
      method === 'PATCH'
    ) {
      const parts = path.split('/')
      const id = Number(parts.at(-2))
      const status = url.searchParams.get('status') ?? 'IN_PROGRESS'
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ id, status }),
      })
    }

    if (path.endsWith('/supervisor/authenticate') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ authenticated: true }),
      })
    }

    if (
      (path.endsWith('/supervisor/override-rate') || path.endsWith('/supervisor/override-fee')) &&
      method === 'POST'
    ) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ok: true }),
      })
    }

    if (path.endsWith('/year-opening/execute') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ targetYear: url.searchParams.get('targetYear'), status: 'DONE' }),
      })
    }

    const bodyByPath: Record<string, unknown> = {
      '/api/v1/dashboard/summary': {
        todayVolume: 12_500_000,
        activeBranches: 9,
        openTransactions: 47,
        alertCount: 2,
      },
      '/api/v1/cash-balances/position': {
        branchId: 'branch-1',
        timestamp: '2026-06-18T10:00:00',
        items: [
          {
            currencyId: 1,
            currencyCode: 'EUR',
            currencyName: 'Euró',
            currentBalance: 500,
            openingBalance: 700,
            dailyChange: -200,
            buyRate: 390,
            sellRate: 399,
            midRate: 394.5,
            hufValue: 197250,
            openingHufValue: 276150,
            dailyChangeHuf: -78900,
            minBalance: 600,
            maxBalance: 4000,
            isLowBalance: true,
            isHighBalance: false,
            lastTransactionAt: '2026-06-18T09:45:00',
          },
        ],
        totalHufValue: 5_000_000,
        totalOpeningHufValue: 4_500_000,
        totalDailyChangeHuf: 500_000,
        currencyCount: 4,
        lowBalanceAlerts: 1,
        highBalanceAlerts: 0,
      },
      '/api/v1/exchange-rates': [
        {
          id: 1,
          currencyCode: 'EUR',
          currencyName: 'Euró',
          baseBuyRate: 390,
          baseSellRate: 399,
          active: true,
          createdAt: '2026-06-18T08:00:00',
        },
      ],
      '/api/v1/stornos/approvals/pending': [
        {
          id: 'approval-1',
          transactionId: 'tx-1',
          workerId: '12',
          branchId: 'branch-1',
          approvalStatusCode: 'PENDING',
          requestReason: 'Hibás bizonylat',
          workerName: 'Pénztáros Teszt',
          receiptNumber: 'V0001',
        },
      ],
      '/api/v1/synchronization/should-sync': { shouldSync: true, pendingCount: 3 },
      '/api/v1/data-collection/status': [
        {
          id: 'dc-1',
          branchId: 'branch-online',
          collectionDate: '2026-06-18',
          status: 'COMPLETED',
          collectionType: 'DAILY',
          transactionCount: 12,
        },
      ],
      '/api/v1/diagnostics/errors/summary': {
        totalAllTime: 15,
        last24h: 1,
        last7d: 4,
        last30d: 9,
        componentBreakdown7d: [],
        versionBreakdown7d: [],
        generatedAt: '2026-06-18T10:00:00',
      },
      '/api/v1/monitoring/dashboard': {
        'branch-online': {
          branchId: 'branch-online',
          lastHeartbeat: '2026-06-18T10:00:00',
          isOnline: true,
          dailyTransactionCount: 12,
          dailyVolumeHuf: 1_200_000,
          openAlerts: 0,
        },
        'branch-offline': {
          branchId: 'branch-offline',
          lastHeartbeat: '2026-06-18T09:45:00',
          isOnline: false,
          dailyTransactionCount: 3,
          dailyVolumeHuf: 250_000,
          openAlerts: 1,
        },
      },
      '/api/v1/monitoring/online': [
        {
          branchId: 'branch-online',
          isOnline: true,
          dailyTransactionCount: 12,
          dailyVolumeHuf: 1_200_000,
          openAlerts: 0,
        },
      ],
      '/api/v1/monitoring/offline': [
        {
          branchId: 'branch-offline',
          lastHeartbeat: '2026-06-18T09:45:00',
          isOnline: false,
          dailyTransactionCount: 3,
          dailyVolumeHuf: 250_000,
          openAlerts: 1,
        },
      ],
      '/api/v1/supervisor/params': [{ id: 'param-1', key: 'SUPERVISOR_LIMIT', value: '100000' }],
      '/api/v1/sync/restore/status': {
        branchId: 'branch-1',
        totalTransactions: 128,
        earliestDate: '2026-01-01',
        latestDate: '2026-06-18',
        restoreAvailable: true,
      },
      '/api/v1/year-opening/status': { lastExecutionYear: 2025, canExecute: true, status: 'READY' },
      '/api/v1/western-union/balance': [
        { id: 'wu-1', branchId: 'branch-1', usdBalance: 1500, hufBalance: 540000 },
      ],
      '/api/v1/western-union/daily-report': {
        date: '2026-06-18',
        sendCount: 2,
        receiveCount: 1,
        totalFees: 3500,
      },
      '/api/v1/reports/daily/submission-status': [
        {
          branchId: 'branch-online',
          branchCode: 'BUD01',
          branchName: 'Budapest 01',
          submitted: true,
        },
        {
          branchId: 'branch-offline',
          branchCode: 'SZEGED',
          branchName: 'Szeged Értéktár',
          submitted: false,
        },
      ],
      '/api/v1/rate-approvals/pending': [
        {
          id: 'rate-approval-1',
          branchId: 'branch-1',
          branchName: 'Szeged Értéktár',
          currencyCode: 'EUR',
          newBuyRate: 392,
          newSellRate: 401,
          status: 'PENDING',
          requestedAt: '2026-06-18T09:30:00',
          reason: 'Piaci korrekció',
        },
      ],
      '/api/v1/rate-approvals/history': [
        {
          id: 'rate-approval-history-1',
          branchId: 'branch-1',
          currencyCode: 'USD',
          status: 'APPROVED',
          requestedAt: '2026-06-18T08:30:00',
        },
      ],
      '/api/v1/camera/status': [
        { cameraId: 'cam-1', cameraName: 'Pénztár kamera', recording: true, connected: true },
        { cameraId: 'cam-2', cameraName: 'Bejárat kamera', recording: false, connected: false },
      ],
      '/api/v1/camera/admin/storage-stats': {
        totalUsageBytes: 1_073_741_824,
        availableSpaceBytes: 10_737_418_240,
        totalRecordings: 24,
        oldestDate: '2026-06-01',
        newestDate: '2026-06-18',
      },
      '/api/v1/camera/admin/upload-status': { pendingUploads: 2 },
      '/api/v1/pos-terminal': [
        {
          id: 'pos-1',
          terminalId: 'TERM-1',
          terminalName: 'OTP POS 1',
          branchId: 'branch-1',
          branchName: 'Budapest 01',
          isActive: true,
          lastTransactionAt: '2026-06-18T09:45:00',
        },
      ],
      '/api/v1/pos-terminal-stub/status': {
        terminalId: 'TERM-1',
        connected: true,
        active: true,
        reachable: true,
        terminalName: 'OTP POS 1',
        terminalType: 'OTP',
        message: 'Elérhető',
      },
      '/api/v1/cash-register/devices': [
        {
          id: 'device-1',
          branchId: 'branch-1',
          code: 'PENZTAR-1',
          name: 'Pénztárgép 1',
          appMode: 'PENZTAR',
          appVersion: 'v2.28.11',
          lastSeenAt: new Date().toISOString(),
          isActive: true,
        },
      ],
      '/api/v1/cash-register/events/branch-1': [
        {
          id: 'event-1',
          eventType: 'RECEIPT',
          status: 'OK',
          receiptNumber: 'NAV-1',
          occurredAt: '2026-06-18T10:00:00',
        },
      ],
      '/api/v1/cash-register/receipt-gaps/branch-1': ['Hiányzó sorszám: NAV-2'],
      '/api/v1/nav/closings': {
        content: [
          {
            id: 'nav-closing-1',
            branchId: 'branch-1',
            closingDate: '2026-06-18',
            closingType: 'DAILY',
            totalRevenue: 1250000,
            totalExpense: 200000,
            status: 'OPEN',
          },
        ],
      },
      '/api/v1/western-union-stub/rates': [
        {
          sourceCurrency: 'USD',
          targetCurrency: 'HUF',
          rate: 360.25,
          fee: 5,
        },
      ],
      '/api/v1/western-union-stub/status/1234567890': {
        mtcn: '1234567890',
        status: 'AVAILABLE',
        message: 'Teszt WU státusz',
        amountUsd: 100,
        destinationCountry: 'HU',
      },
      '/api/v1/transfer-documents': [
        {
          id: 101,
          documentNumber: 'ATD-101',
          sourceType: 'BRANCH',
          sourceId: 'SZEGED',
          destinationType: 'BRANCH',
          destinationId: 'BUD01',
          currencyCode: 'EUR',
          quantity: 500,
          status: 'PENDING',
          createdAt: '2026-06-18T10:00:00',
        },
      ],
      '/api/v1/ertektar/collections': [
        {
          id: 11,
          sourceBranchCode: 'SZEGED',
          sourceBranchName: 'Szeged Értéktár',
          currencyCode: 'EUR',
          amount: 1200,
          status: 'REQUESTED',
          requestedAt: '2026-06-18T10:00:00',
        },
      ],
      '/api/v1/ertektar/distribution': [
        {
          id: 12,
          status: 'IN_PROGRESS',
          note: 'Mobil szétosztás',
          createdAt: '2026-06-18T10:00:00',
          lines: [
            {
              targetBranchCode: 'PECS',
              targetBranchName: 'Pécs',
              currencyCode: 'USD',
              amount: 300,
            },
          ],
        },
      ],
      '/api/v1/ertektar/bank-transactions': [
        {
          id: 13,
          transactionType: 'BUY',
          currencyCode: 'CHF',
          amount: 500,
          exchangeRate: 410,
          hufAmount: 205000,
          bankName: 'Raiffeisen',
          status: 'REQUESTED',
          createdAt: '2026-06-18T10:00:00',
        },
      ],
      '/api/v1/notifications/unread': [
        {
          id: 'notification-1',
          title: 'Mobil riasztás',
          message: 'Hiányzó napi jelentés',
          type: 'WARNING',
          isRead: false,
          createdAt: '2026-06-18T10:00:00',
        },
      ],
      '/api/v1/notifications/unread-count': { count: 1 },
      '/api/v1/scanned-documents/customer/42': [
        {
          id: 'scan-1',
          customerId: 42,
          documentType: 'ID_CARD',
          fileName: 'id-card.jpg',
          mimeType: 'image/jpeg',
          fileSizeBytes: 12,
          scannedAt: '2026-06-18T10:05:00',
        },
      ],
      '/api/v1/customers': [
        {
          id: 42,
          name: 'Teszt Elek',
          documentNumber: 'AB123456',
          active: true,
        },
      ],
    }

    const body = bodyByPath[path] ?? { content: [], data: [], total: 0 }
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(body),
    })
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

test('mobil munkanézet valós Chromium viewporton nem folyik ki', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockMobileApis(page)
  page.on('dialog', (dialog) => dialog.accept())
  await login(page)

  await page.goto('/mobile', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Mobil munkanézet')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav-cashier')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav-field')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav-camera')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav-vault')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav-approval')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav-customer')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav-management')).toBeVisible()
  await expect(page.getByTestId('mobile-bottom-nav-integrations')).toBeVisible()
  const bottomNavLayout = await page.getByTestId('mobile-bottom-nav').evaluate((nav) => {
    const rect = nav.getBoundingClientRect()
    const buttons = Array.from(nav.querySelectorAll('button')).map((button) => {
      const buttonRect = button.getBoundingClientRect()
      return {
        width: buttonRect.width,
        height: buttonRect.height,
        textFits: button.scrollWidth <= button.clientWidth + 1,
      }
    })
    return {
      left: rect.left,
      right: rect.right,
      bottom: rect.bottom,
      viewportWidth: window.innerWidth,
      viewportHeight: window.innerHeight,
      buttons,
    }
  })
  expect(bottomNavLayout.left).toBeGreaterThanOrEqual(0)
  expect(bottomNavLayout.right).toBeLessThanOrEqual(bottomNavLayout.viewportWidth + 1)
  expect(bottomNavLayout.bottom).toBeLessThanOrEqual(bottomNavLayout.viewportHeight + 1)
  expect(
    bottomNavLayout.buttons.every(
      (button) => button.width >= 44 && button.height >= 44 && button.textFits,
    ),
  ).toBe(true)
  await expect(page.getByRole('button', { name: /Pénztár/i }).first()).toBeVisible()
  await expect(page.getByRole('button', { name: /Riasztás és státusz/i })).toBeVisible()
  await expect(page.getByRole('button', { name: /Jóváhagyás/i })).toBeVisible()
  await expect(page.getByRole('button', { name: /Ügyfél és AML/i })).toBeVisible()
  await expect(page.getByRole('button', { name: /Terepi kontroll/i })).toBeVisible()
  await expect(page.getByRole('button', { name: /Kamera/i }).first()).toBeVisible()
  await expect(page.getByRole('button', { name: /Eszközök/i }).first()).toBeVisible()
  await expect(page.getByTestId('mobile-work-area-cashier')).toBeVisible()
  await expect(page.getByText('Pénztári készletfigyelő')).toBeVisible()
  await expect(page.getByText('Alacsony')).toBeVisible()

  await page.getByTestId('mobile-bottom-nav-field').click()
  await expect(page.getByTestId('mobile-work-area-field')).toBeVisible()
  await expect(page.getByText('Mobil átadási bizonylatok')).toBeVisible()
  await expect(page.getByText('ATD-101')).toBeVisible()
  await page.getByTestId('mobile-transfer-pin-101').fill('1234')
  const pickupRequest = page.waitForRequest(
    (request) =>
      request.method() === 'PUT' && request.url().includes('/transfer-documents/101/pickup'),
  )
  await page.getByTestId('mobile-transfer-pickup-101').click()
  await pickupRequest

  await page.getByTestId('mobile-bottom-nav-vault').click()
  await expect(page.getByTestId('mobile-work-area-vault')).toBeVisible()
  await expect(page.getByText('Értéktári mobil státusz')).toBeVisible()
  await expect(page.getByText('Begyűjtés #11')).toBeVisible()
  const ertektarStatusRequest = page.waitForRequest(
    (request) =>
      request.method() === 'PATCH' &&
      request.url().includes('/ertektar/collections/11/status') &&
      request.url().includes('status=COMPLETED'),
  )
  await page.getByRole('button', { name: 'Begyűjtés #11 mobil státusz COMPLETED' }).click()
  await ertektarStatusRequest

  await page.getByTestId('mobile-bottom-nav-camera').click()
  const cameraArea = page.getByTestId('mobile-work-area-camera')
  await expect(cameraArea).toBeVisible()
  await expect(cameraArea.getByText('Kamera mobil státusz')).toBeVisible()
  await expect(cameraArea.getByText('Pénztár kamera')).toBeVisible()
  await expect(cameraArea.getByText('Bejárat kamera')).toBeVisible()
  await expect(cameraArea.getByText('Offline')).toBeVisible()
  await expect(page.getByRole('link', { name: /Élő kép/i })).toHaveAttribute('href', '/camera/live')

  await page.getByTestId('mobile-bottom-nav-approval').click()
  await expect(page.getByTestId('mobile-work-area-approval')).toBeVisible()
  const rateApprovalRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' &&
      request.url().includes('/rate-approvals/rate-approval-1/approve'),
  )
  await page
    .getByRole('button', { name: /Árfolyam engedélyezés/i })
    .first()
    .click()
  await rateApprovalRequest

  await page.getByTestId('mobile-bottom-nav-customer').click()
  await expect(page.getByTestId('mobile-work-area-customer')).toBeVisible()
  await expect(page.getByPlaceholder('Név vagy okmányszám...')).toBeVisible()
  await page.getByPlaceholder('Név vagy okmányszám...').fill('AB123456')
  await page.getByRole('button', { name: 'Ügyfél keresése' }).click()
  await expect(page.getByText('Teszt Elek')).toBeVisible()
  await expect(page.getByText('Telefonos okmányfeltöltés')).toBeVisible()
  await page.getByRole('button', { name: 'Lista' }).click()
  await expect(page.getByText('id-card.jpg')).toBeVisible()
  const uploadRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/scanned-documents/upload'),
  )
  await page.getByTestId('mobile-document-upload-input').setInputFiles({
    name: 'mobil-id.jpg',
    mimeType: 'image/jpeg',
    buffer: Buffer.from('mobil'),
  })
  await uploadRequest

  await page.getByTestId('mobile-bottom-nav-management').click()
  await expect(page.getByTestId('mobile-work-area-management')).toBeVisible()
  await expect(page.getByTestId('mobile-sync-actions-panel')).toBeVisible()
  const mobileSyncRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/sync/full/branch-1'),
  )
  await page.getByTestId('mobile-sync-full').click()
  await mobileSyncRequest
  await expect(page.getByTestId('mobile-year-opening-panel')).toBeVisible()
  const yearOpeningRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' &&
      request.url().includes('/year-opening/execute') &&
      request.url().includes('targetYear=2027'),
  )
  await page.getByLabel('Cél év').fill('2027')
  await page
    .getByTestId('mobile-year-opening-panel')
    .getByRole('button', { name: /Futtatás/i })
    .click()
  await yearOpeningRequest
  await expect(page.getByTestId('mobile-supervisor-override-panel')).toBeVisible()
  const supervisorAuthRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/supervisor/authenticate'),
  )
  await page.getByLabel('Supervisor jelszó').fill('titkos')
  await page.getByRole('button', { name: 'Supervisor ellenőrzés' }).click()
  await supervisorAuthRequest
  const supervisorRateRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/supervisor/override-rate'),
  )
  await page.getByLabel('Vételi').fill('395.5')
  await page.getByLabel('Eladási').fill('401.25')
  await page
    .getByRole('textbox', { name: 'Indoklás', exact: true })
    .fill('Mobil piaci felülbírálás')
  await page.getByRole('button', { name: 'Árfolyam felülbírálás küldése' }).click()
  await supervisorRateRequest
  const supervisorFeeRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/supervisor/override-fee'),
  )
  await page.getByLabel('Tranzakció ID').fill('987')
  await page.getByLabel('Új díj').fill('750')
  await page.getByLabel('Díj indoklás').fill('Mobil díj korrekció')
  await page.getByRole('button', { name: 'Díj felülbírálás küldése' }).click()
  await supervisorFeeRequest
  await expect(page.getByText('Mobil értesítések')).toBeVisible()
  const notificationRequest = page.waitForRequest(
    (request) =>
      request.method() === 'PUT' && request.url().includes('/notifications/notification-1/read'),
  )
  await page.getByRole('button', { name: 'Olvasott', exact: true }).click()
  await notificationRequest

  await page.getByTestId('mobile-bottom-nav-integrations').click()
  const integrationsArea = page.getByTestId('mobile-work-area-integrations')
  await expect(integrationsArea).toBeVisible()
  await expect(integrationsArea.getByText('POS mobil runtime')).toBeVisible()
  await expect(integrationsArea.getByText('OTP POS 1')).toBeVisible()
  await expect(integrationsArea.getByText('Pénztárgép mobil állapot')).toBeVisible()
  await expect(integrationsArea.getByText('Pénztárgép 1')).toBeVisible()
  await expect(integrationsArea.getByText('NAV zárás mobil lista')).toBeVisible()
  await expect(integrationsArea.getByText('WU adapter mobil státusz')).toBeVisible()
  const wuStatusRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' && request.url().includes('/western-union-stub/status/1234567890'),
  )
  await integrationsArea.getByLabel('WU MTCN státusz').fill('1234567890')
  await integrationsArea.getByRole('button', { name: /Státusz/i }).click()
  await wuStatusRequest
  await expect(integrationsArea.getByText(/1234567890 - AVAILABLE/)).toBeVisible()

  for (const tabName of ['Terep', 'Kamera', 'Jóváhagyás', 'Ügyfél', 'Vezetés', 'Eszközök']) {
    await page.getByRole('tab', { name: new RegExp(tabName) }).click()
    await expect(page.getByRole('tabpanel')).toBeVisible()
  }

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
