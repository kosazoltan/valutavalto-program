import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 77,
  workerCode: 'FOERTEKTAR',
  firstName: 'Főértéktáros',
  lastName: 'Teszt',
  fullName: 'Főértéktáros Teszt',
  role: 'FOERTEKTAR',
  branchId: 'branch-1',
  branchCode: '001',
  branchName: 'Fő utca',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const summary = {
  startDate: '2026-07-01',
  endDate: '2026-07-02',
  totalNetAmount: 93000,
  totalFeeAmount: 3800,
  rows: [
    { date: '2026-07-01', netAmount: 73000, feeAmount: 3000 },
    { date: '2026-07-02', netAmount: 20000, feeAmount: 800 },
  ],
}

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'FOERTEKTAR',
    permissions: ['READ'],
    roles: ['FOERTEKTAR'],
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
          activeRole: 'FOERTEKTAR',
          permissions: ['READ'],
          roles: ['FOERTEKTAR'],
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
      path.endsWith('/branches') &&
      method === 'GET' &&
      url.searchParams.get('activeOnly') === 'true'
    ) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'branch-1', code: '001', bankCode: 'K&H', name: 'Fő utca' },
          { id: 'branch-2', code: '002', bankCode: 'OTP', name: 'Mellék utca' },
        ]),
      })
    }

    if (path.endsWith('/handling-fees/pos-daily-summary/csv') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'text/csv; charset=UTF-8',
        body: 'Dátum,POS nettó (Ft),POS KK (Ft)\n2026-07-01,73000,3000\n',
      })
    }

    if (path.endsWith('/handling-fees/pos-daily-summary') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(summary),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
  })
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

test('FK-059 POS report navigation, filters, table, and CSV parameter parity', async ({ page }) => {
  await page.setViewportSize({ width: 1366, height: 768 })
  await mockApis(page)
  await login(page)

  await expect(page.getByText('Riportok', { exact: true }).first()).toBeVisible()
  await page.getByRole('link', { name: 'Kezelési díj — POS' }).click()
  await expect(page).toHaveURL(/\/reports\/pos-handling-fee$/)
  await expect(page.getByRole('heading', { name: 'Kezelési díj — POS riport' })).toBeVisible()
  await expect(page.getByRole('option', { name: '— Minden iroda —' })).toBeAttached()

  await page.getByLabel('Tól').fill('2026-07-01')
  await page.getByLabel('Ig').fill('2026-07-02')
  await page.getByLabel('Iroda').selectOption('branch-1')

  const branchRequestPromise = page.waitForRequest((request) => {
    const url = new URL(request.url())
    return (
      request.method() === 'GET' &&
      url.pathname.endsWith('/handling-fees/pos-daily-summary') &&
      url.searchParams.get('branchId') === 'branch-1' &&
      url.searchParams.get('startDate') === '2026-07-01' &&
      url.searchParams.get('endDate') === '2026-07-02'
    )
  })
  await page.getByRole('button', { name: 'Lekérdezés' }).click()
  const branchRequest = await branchRequestPromise
  const branchParams = new URL(branchRequest.url()).searchParams

  await expect(page.getByRole('columnheader', { name: 'Dátum' })).toBeVisible()
  await expect(page.getByRole('columnheader', { name: 'POS nettó (Ft)' })).toBeVisible()
  await expect(page.getByRole('columnheader', { name: 'POS KK (Ft)' })).toBeVisible()
  await expect(page.getByText('2026. 07. 01.')).toBeVisible()
  await expect(page.getByText('2026. 07. 02.')).toBeVisible()
  await expect(page.getByText('73 000 Ft')).toBeVisible()

  await page.getByLabel('Iroda').selectOption('__ALL__')
  const allOfficeRequestPromise = page.waitForRequest((request) => {
    const url = new URL(request.url())
    return (
      request.method() === 'GET' &&
      url.pathname.endsWith('/handling-fees/pos-daily-summary') &&
      !url.searchParams.has('branchId') &&
      url.searchParams.get('startDate') === '2026-07-01' &&
      url.searchParams.get('endDate') === '2026-07-02'
    )
  })
  await page.getByRole('button', { name: 'Lekérdezés' }).click()
  const allOfficeRequest = await allOfficeRequestPromise
  const allOfficeParams = new URL(allOfficeRequest.url()).searchParams

  const csvRequestPromise = page.waitForRequest((request) =>
    new URL(request.url()).pathname.endsWith('/handling-fees/pos-daily-summary/csv'),
  )
  await page.getByRole('button', { name: 'CSV' }).click()
  const csvRequest = await csvRequestPromise
  const csvParams = new URL(csvRequest.url()).searchParams

  expect(csvParams.get('startDate')).toBe(allOfficeParams.get('startDate'))
  expect(csvParams.get('endDate')).toBe(allOfficeParams.get('endDate'))
  expect(csvParams.has('branchId')).toBe(false)
  expect(branchParams.get('branchId')).toBe('branch-1')

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
  await expect(page.getByRole('table')).toBeVisible()
  await expect(page.getByRole('button', { name: 'Lekérdezés' })).toBeInViewport()
  await expect(page.getByRole('button', { name: 'CSV' })).toBeInViewport()
})
