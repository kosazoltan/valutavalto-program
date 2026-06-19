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

const hrkSummary = {
  branchId: 'branch-1',
  yearMonth: '2026-06',
  totalTransactions: 2,
  totalHandoverHuf: 100000,
  totalReceiveHuf: 250000,
  netHuf: 150000,
  currencyBreakdown: [
    {
      currencyCode: 'EUR',
      handoverCount: 1,
      handoverAmount: 250,
      handoverHuf: 100000,
      receiveCount: 1,
      receiveAmount: 500,
      receiveHuf: 250000,
      netAmount: 250,
      netHuf: 150000,
    },
  ],
}

const hrkJournal = [
  {
    id: 'hrk-tx-1',
    branchId: 'branch-1',
    type: 'HANDOVER',
    currencyCode: 'EUR',
    amount: 250,
    hufAmount: 100000,
    bankAccountNumber: '11700000-00000000',
    reference: 'HRK-2026-001',
    note: 'Teszt átadás',
    status: 'COMPLETED',
    workerId: 77,
    createdAt: '2026-06-18T10:00:00',
    completedAt: '2026-06-18T10:05:00',
  },
]

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

    if (path.endsWith('/closing/monthly/branch-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'closing-1', yearMonth: '2026-06', branchName: 'Budapest 01', status: 'OPEN' },
        ]),
      })
    }

    if (path.endsWith('/hrk/monthly/summary') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(hrkSummary) })
    }

    if (path.endsWith('/hrk/monthly/close') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...hrkSummary, totalTransactions: 3 }),
      })
    }

    if (path.endsWith('/hrk/journal') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(hrkJournal) })
    }

    if (path.endsWith('/hrk/close-daily') && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(hrkJournal) })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ content: [], data: [], total: 0 }) })
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

test('havi zárás HRK panel mobilnézetben lekéri és zárja a HRK havi összesítőt', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  page.on('dialog', dialog => void dialog.accept())
  await login(page)

  await page.goto('/closing/monthly', { waitUntil: 'domcontentloaded' })
  await expect(page.getByTestId('hrk-monthly-panel')).toBeVisible()
  await expect(page.getByText('HRK havi készletmozgás')).toBeVisible()
  await expect(page.getByText('HRK napi napló')).toBeVisible()
  await expect(page.getByText('EUR').first()).toBeVisible()
  await expect(page.getByText('HRK-2026-001')).toBeVisible()
  await expect(page.getByText('150 000 Ft').first()).toBeVisible()

  const closeRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/hrk/monthly/close')
  )
  await page.getByRole('button', { name: /HRK havi zárás/i }).click()
  await closeRequest

  const dailyCloseRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/hrk/close-daily')
  )
  await page.getByRole('button', { name: /HRK napi zárás/i }).click()
  await dailyCloseRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
