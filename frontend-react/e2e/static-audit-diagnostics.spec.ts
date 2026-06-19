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

async function mockDiagnosticsApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['READ', 'WRITE'],
    roles: ['ADMIN'],
  })

  await page.route('**/api/static-audit', async route => {
    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { name: 'DB connection', pass: true, detail: 'OK' },
        { name: 'spring.mail.password', pass: false, detail: 'MISSING' },
      ]),
    })
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
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ token }),
      })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(worker) })
    }

    if (path.endsWith('/diagnostics/audit/recent') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'audit-1',
            ts: '2026-06-19T08:00:00',
            eventType: 'LOGIN',
            entityType: 'Worker',
            entityId: 'worker-1',
            userName: 'Admin Teszt',
            traceId: 'trace-1',
          },
        ]),
      })
    }

    if (path.endsWith('/diagnostics/audit/recent-errors') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'audit-error-1',
            ts: '2026-06-19T08:02:00',
            eventType: 'CLIENT_ERROR',
            action: 'ERROR',
            entityType: 'client_log',
            entityId: 'client-1',
            userName: 'Admin Teszt',
            traceId: 'trace-error-1',
          },
        ]),
      })
    }

    if (path.endsWith('/diagnostics/audit/error-codes') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          version: '1',
          totalCodes: 1,
          codes: [
            {
              code: 'VV-TECH-002',
              name: 'Technikai hiba',
              category: 'TECH',
              level: 'ERROR',
              userImpact: 'Admin vizsgalat szukseges',
            },
          ],
        }),
      })
    }

    if (path.endsWith('/diagnostics/health') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ok: true, totalReportedErrors: 12 }),
      })
    }

    if (path.endsWith('/diagnostics/audit/hash-chain-verify') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ checkedCount: 10, intact: true, message: 'OK' }),
      })
    }

    if (path.endsWith('/diagnostics/audit/entity/Worker/worker-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'entity-audit-1',
            ts: '2026-06-19T08:03:00',
            eventType: 'ENTITY_UPDATED',
            entityType: 'Worker',
            entityId: 'worker-1',
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

test('static audit admin panel mobil viewporton /api/static-audit endpointot hív', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockDiagnosticsApis(page)
  await login(page)

  await page.goto('/admin/audit-diagnostics', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Audit Diagnosztika (V234)')).toBeVisible()
  await expect(page.getByTestId('diagnostics-health-panel')).toBeVisible()
  await expect(page.getByText('Diagnostics ingest')).toBeVisible()
  await expect(page.getByText('DB-ben rögzített klienshibák')).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Static audit' })).toBeVisible()

  await page.getByPlaceholder('Static audit admin token').fill('token-1')
  const staticAuditRequest = page.waitForRequest(request =>
    request.method() === 'GET' && new URL(request.url()).pathname === '/api/static-audit'
  )
  await page.getByRole('button', { name: 'Static audit futtatasa' }).click()
  await staticAuditRequest

  await expect(page.getByText('DB connection')).toBeVisible()
  await expect(page.getByText('spring.mail.password')).toBeVisible()
  await expect(page.getByText('MISSING')).toBeVisible()

  await page.getByPlaceholder('entityType').fill('Worker')
  await page.getByPlaceholder('entityId').fill('worker-1')
  const entityChainRequest = page.waitForRequest(request =>
    request.method() === 'GET'
    && new URL(request.url()).pathname === '/api/v1/diagnostics/audit/entity/Worker/worker-1'
  )
  await page.getByRole('button', { name: 'Audit-lanc' }).click()
  await entityChainRequest
  await expect(page.getByTestId('entity-chain-results')).toContainText('ENTITY_UPDATED')

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
