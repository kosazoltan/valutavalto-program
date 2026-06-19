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
  branchId: '11111111-1111-1111-1111-111111111111',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

async function mockApis(page: Page) {
  let draftCreated = false
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['RATE_READ', 'RATE_WRITE'],
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
          permissions: ['RATE_READ', 'RATE_WRITE'],
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

    if (path.endsWith('/exchange-rate-master/status/DRAFT') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(draftCreated ? [{
          id: 'draft-1',
          companyId: 'company-1',
          currencyId: 1,
          currencyCode: 'EUR',
          baseBuyRate: 390.5,
          baseSellRate: 399.5,
          officialRate: 394,
          status: 'DRAFT',
          createdAt: '2026-06-18T08:00:00',
        }] : []),
      })
    }

    if (path.endsWith('/exchange-rate-master') && method === 'POST') {
      draftCreated = true
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'draft-1',
          companyId: 'company-1',
          currencyId: 1,
          currencyCode: 'EUR',
          baseBuyRate: 390.5,
          baseSellRate: 399.5,
          officialRate: 394,
          status: 'DRAFT',
          createdAt: '2026-06-18T08:00:00',
        }),
      })
    }

    if (path.endsWith('/exchange-rate-master/status/PUBLISHED') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{
          id: 'rate-1',
          companyId: 'company-1',
          currencyId: 1,
          currencyCode: 'EUR',
          baseBuyRate: 390,
          baseSellRate: 399,
          officialRate: 394,
          status: 'PUBLISHED',
          createdAt: '2026-06-18T08:00:00',
        }]),
      })
    }

    if (path.endsWith('/exchange-rate-master/rate-1/distribution') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{
          id: 'dist-1',
          masterRateId: 'rate-1',
          branchId: 'branch-1',
          branchCode: 'BUD01',
          branchName: 'Budapest 01',
          status: 'DISTRIBUTED',
        }]),
      })
    }

    if (path.endsWith('/exchange-rate-master/distribution/dist-1/acknowledge') && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
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

test('rate master workflow vázlat-létrehozás backend szerződésre köt mobil viewporton', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/rate-management/workflow', { waitUntil: 'domcontentloaded' })
  await page.getByLabel('Valuta ID').fill('1')
  await page.getByLabel('Vételi árfolyam').fill('390,5')
  await page.getByLabel('Eladási árfolyam').fill('399,5')
  await page.getByLabel('MNB árfolyam').fill('394')

  const createRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().endsWith('/api/v1/exchange-rate-master')
  )
  await page.getByRole('button', { name: 'Vázlat létrehozása' }).click()
  const request = await createRequest
  expect(request.postDataJSON()).toMatchObject({
    currencyId: 1,
    baseBuyRate: 390.5,
    baseSellRate: 399.5,
    officialRate: 394,
  })
  await expect(page.getByText('EUR')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})

test('rate master workflow elosztás-visszaigazolás backend szerződésre köt mobil viewporton', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/rate-management/workflow', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: /Publikálva/i }).click()
  await expect(page.getByText('EUR')).toBeVisible()
  await page.getByRole('button', { name: 'Elosztás' }).click()
  await expect(page.getByText('BUD01')).toBeVisible()

  const ackRequest = page.waitForRequest(request =>
    request.method() === 'POST' && request.url().includes('/exchange-rate-master/distribution/dist-1/acknowledge')
  )
  await page.getByTestId('exchange-rate-distribution-ack-dist-1').click()
  await ackRequest

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
