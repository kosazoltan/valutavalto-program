import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 88,
  workerCode: 'FOERTEKTAR',
  firstName: 'Érték',
  lastName: 'Táros',
  fullName: 'Érték Táros',
  role: 'foertektar',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

async function mockApis(page: Page) {
  const correctionDecisions: string[] = []
  const transferDecisions: string[] = []
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'foertektar',
    permissions: ['READ', 'WRITE'],
    roles: ['foertektar'],
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
          activeRole: 'foertektar',
          permissions: ['READ', 'WRITE'],
          roles: ['foertektar'],
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

    if (path.endsWith('/own-companies/active') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 'company-1', name: 'Exclusive Best Change Zrt.' }]),
      })
    }

    if (path.endsWith('/ertektar/transfers/pending') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 21, transferNumber: 'ATT-2026-0001', currencyCode: 'EUR', amount: 1000, status: 'REQUESTED', requiresSupervisor: true, createdAt: '2026-06-19T08:00:00' },
        ]),
      })
    }

    if (path.endsWith('/ertektar/transfers') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 21, transferNumber: 'ATT-2026-0001', currencyCode: 'EUR', amount: 1000, status: 'REQUESTED', requiresSupervisor: true, createdAt: '2026-06-19T08:00:00' },
          { id: 22, transferNumber: 'ATT-2026-0002', currencyCode: 'USD', amount: 500, status: 'IN_PROGRESS', requiresSupervisor: true, createdAt: '2026-06-19T09:00:00' },
        ]),
      })
    }

    const transferDecision = path.match(/\/ertektar\/transfers\/(\d+)\/(supervisor-approve|complete|reject)$/)
    if (transferDecision && method === 'POST') {
      transferDecisions.push(`${transferDecision[1]}:${transferDecision[2]}`)
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: Number(transferDecision[1]),
          status: transferDecision[2] === 'reject'
            ? 'REJECTED'
            : transferDecision[2] === 'complete'
              ? 'COMPLETED'
              : 'IN_PROGRESS',
        }),
      })
    }

    if (path.endsWith('/ertektar/receipts/by-type') && method === 'GET') {
      const type = url.searchParams.get('type')
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(type === 'B'
          ? [{ id: 31, receiptNumber: 'BIZ-2026-0001', receiptType: 'B', status: 'DRAFT', createdAt: '2026-06-19T08:00:00', lines: [{ currencyCode: 'EUR', amount: 100 }] }]
          : []),
      })
    }

    if (path.endsWith('/ertektar/receipts') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 31, receiptNumber: 'BIZ-2026-0001', receiptType: 'B', status: 'DRAFT', createdAt: '2026-06-19T08:00:00', lines: [{ currencyCode: 'EUR', amount: 100 }] },
        ]),
      })
    }

    if (path.endsWith('/ertektar/corrections/pending') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 41, entityType: 'VAULT', entityId: 'BUD01', currencyCode: 'CHF', oldQuantity: 10, newQuantity: 12, difference: 2, reason: 'Leltár eltérés', status: 'PENDING', createdAt: '2026-06-19T08:00:00' },
        ]),
      })
    }

    if (path.endsWith('/ertektar/corrections') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 41, entityType: 'VAULT', entityId: 'BUD01', currencyCode: 'CHF', oldQuantity: 10, newQuantity: 12, difference: 2, reason: 'Leltár eltérés', status: 'PENDING', createdAt: '2026-06-19T08:00:00' },
        ]),
      })
    }

    const correctionDecision = path.match(/\/ertektar\/corrections\/(\d+)\/(approve|reject)$/)
    if (correctionDecision && method === 'POST') {
      correctionDecisions.push(`${correctionDecision[1]}:${correctionDecision[2]}`)
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: Number(correctionDecision[1]),
          status: correctionDecision[2] === 'approve' ? 'APPROVED' : 'REJECTED',
        }),
      })
    }

    if (method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
  })

  return { correctionDecisions, transferDecisions }
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('FOERTEKTAR')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/central-workstation$/)
}

test('értéktári dashboard mobil nézetben lekéri és megjeleníti a read-only ledger listákat', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  const requests = [
    '/api/v1/ertektar/transfers',
    '/api/v1/ertektar/transfers/pending',
    '/api/v1/ertektar/receipts',
    '/api/v1/ertektar/receipts/by-type',
    '/api/v1/ertektar/corrections',
    '/api/v1/ertektar/corrections/pending',
  ].map(expectedPath => page.waitForRequest(request => {
    const url = new URL(request.url())
    return request.method() === 'GET' && url.pathname === expectedPath
  }))

  await page.goto('/treasury', { waitUntil: 'domcontentloaded' })
  await Promise.all(requests)

  const ledger = page.getByTestId('ertektar-readonly-ledger')
  await expect(ledger).toBeVisible()
  await expect(ledger.getByText('ATT-2026-0001')).toBeVisible()
  await expect(ledger.getByText('ATT-2026-0002')).toBeVisible()
  await expect(ledger.getByText('BIZ-2026-0001')).toBeVisible()
  await expect(ledger.getByText('VAULT BUD01')).toBeVisible()
  await expect(page.getByRole('button', { name: 'Áttétel #21 supervisor jóváhagyás' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Áttétel #22 végrehajtás' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Készletkorrekció #41 jóváhagyás' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Készletkorrekció #41 elutasítás' })).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})

test('értéktári készletkorrekció gombok POST approve/reject backend szerződést hívnak', async ({ page }) => {
  const apiCalls = await mockApis(page)
  await login(page)
  page.on('dialog', dialog => dialog.accept())

  await page.goto('/treasury', { waitUntil: 'domcontentloaded' })

  const ledger = page.getByTestId('ertektar-readonly-ledger')
  await expect(ledger).toBeVisible()
  await expect(page.getByRole('button', { name: 'Készletkorrekció #41 jóváhagyás' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Készletkorrekció #41 elutasítás' })).toBeVisible()

  const approveRequest = page.waitForRequest(request =>
    request.method() === 'POST'
    && new URL(request.url()).pathname === '/api/v1/ertektar/corrections/41/approve'
  )
  await page.getByRole('button', { name: 'Készletkorrekció #41 jóváhagyás' }).click()
  await approveRequest

  const rejectRequest = page.waitForRequest(request =>
    request.method() === 'POST'
    && new URL(request.url()).pathname === '/api/v1/ertektar/corrections/41/reject'
  )
  await page.getByRole('button', { name: 'Készletkorrekció #41 elutasítás' }).click()
  await rejectRequest

  expect(apiCalls.correctionDecisions).toEqual(['41:approve', '41:reject'])

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})

test('értéktári áttétel gombok POST supervisor/complete/reject backend szerződést hívnak', async ({ page }) => {
  const apiCalls = await mockApis(page)
  await login(page)
  page.on('dialog', dialog => dialog.accept())

  await page.goto('/treasury', { waitUntil: 'domcontentloaded' })

  await expect(page.getByRole('button', { name: 'Áttétel #21 supervisor jóváhagyás' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Áttétel #22 végrehajtás' })).toBeVisible()
  await expect(page.getByRole('button', { name: 'Áttétel #21 elutasítás' })).toBeVisible()

  const approveRequest = page.waitForRequest(request =>
    request.method() === 'POST'
    && new URL(request.url()).pathname === '/api/v1/ertektar/transfers/21/supervisor-approve'
  )
  await page.getByRole('button', { name: 'Áttétel #21 supervisor jóváhagyás' }).click()
  await approveRequest

  const completeRequest = page.waitForRequest(request =>
    request.method() === 'POST'
    && new URL(request.url()).pathname === '/api/v1/ertektar/transfers/22/complete'
  )
  await page.getByRole('button', { name: 'Áttétel #22 végrehajtás' }).click()
  await completeRequest

  const rejectRequest = page.waitForRequest(request =>
    request.method() === 'POST'
    && new URL(request.url()).pathname === '/api/v1/ertektar/transfers/21/reject'
  )
  await page.getByRole('button', { name: 'Áttétel #21 elutasítás' }).click()
  await rejectRequest

  expect(apiCalls.transferDecisions).toEqual(['21:supervisor-approve', '22:complete', '21:reject'])

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
