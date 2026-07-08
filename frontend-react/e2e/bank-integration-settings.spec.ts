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

const raiffeisenConfig = {
  id: 'config-1',
  providerName: 'RAIFFEISEN',
  mode: 'HTML_SCRAPING_FALLBACK',
  endpointUrl: 'https://raiffeisen.example/rates',
  authType: 'NONE',
  clientId: 'client-1',
  clientSecretConfigured: true,
  mtlsCertificateAlias: 'cert-1',
  updateFrequency: '0 0 8 * * MON-FRI',
  enabled: true,
  lastRunTimestamp: '2026-06-18T08:00:00',
  lastRunStatus: 'SUCCESS',
  lastRunMessage: 'OK',
  updatedAt: '2026-06-18T08:05:00',
}

async function mockBankIntegrationApis(page: Page) {
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

    if (path.endsWith('/own-companies/active') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 'company-1', name: 'EBC Zrt.' }]),
      })
    }

    if (path.endsWith('/admin/bank-integration/status') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          mnb: {
            rateCount: 23,
            lastFetchSuccess: true,
            lastFetchDate: '2026-06-18',
            schedulerActive: true,
          },
          raiffeisen: {
            schedulerActive: true,
            scheduledTime: '08:00 CET (munkanapokon)',
            enabled: true,
            mode: 'HTML_SCRAPING_FALLBACK',
            endpointConfigured: true,
            lastRunStatus: 'SUCCESS',
            lastRunTimestamp: '2026-06-18T08:00:00',
            lastRunMessage: 'OK',
          },
          darius: {
            currentMonth: '2026-06',
            periodStart: '2026-06-01',
            periodEnd: '2026-06-30',
            pendingReportsCount: 1,
            failedReportsCount: 0,
            submittedReportsCount: 18,
            lastSubmittedAt: '2026-06-18T10:00:00',
            transportMode: 'MANAGED_OUTBOX',
          },
          checkedAt: '2026-06-18T10:30:00',
        }),
      })
    }

    if (path === '/api/v1/bank-api-config' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([raiffeisenConfig]),
      })
    }

    if (path === '/api/v1/bank-api-config/RAIFFEISEN' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(raiffeisenConfig),
      })
    }

    if (path === '/api/v1/bank-api-config/RAIFFEISEN' && method === 'PUT') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          ...raiffeisenConfig,
          mode: 'REST_PRIMARY_WITH_HTML_FALLBACK',
          endpointUrl: 'https://raiffeisen.example/rest',
          authType: 'OAUTH2_CLIENT_CREDENTIALS',
        }),
      })
    }

    if (path === '/api/v1/bank-api-config/raiffeisen/fetch-now' && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          savedRates: 12,
          config: {
            ...raiffeisenConfig,
            lastRunStatus: 'SUCCESS',
            lastRunMessage: 'Raiffeisen árfolyamok cache-elve: 12/12',
          },
        }),
      })
    }

    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ content: [], data: [] }),
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

test('bank integráció beállítás mobil viewporton kezeli a bank-api-config szerződést', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockBankIntegrationApis(page)
  await login(page)

  await page.goto('/settings', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: /Bank integráció/i }).click()

  await expect(page.getByText('Bank API integráció állapota')).toBeVisible()
  await expect(page.getByText('Bank API konfiguráció')).toBeVisible()
  await expect(page.getByLabel('Endpoint URL')).toHaveValue('https://raiffeisen.example/rates')
  await expect(page.getByPlaceholder('Már beállítva')).toHaveValue('')

  await page.getByLabel('Mód').selectOption('REST_PRIMARY_WITH_HTML_FALLBACK')
  await page.getByLabel('Auth típus').selectOption('OAUTH2_CLIENT_CREDENTIALS')
  await page.getByLabel('Endpoint URL').fill('https://raiffeisen.example/rest')
  await page.getByLabel('Client secret').fill('new-secret-value')
  const saveRequest = page.waitForRequest(
    (request) =>
      request.method() === 'PUT' && request.url().endsWith('/api/v1/bank-api-config/RAIFFEISEN'),
  )
  await page.getByRole('button', { name: 'Mentés' }).click()
  await saveRequest

  const fetchRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' &&
      request.url().endsWith('/api/v1/bank-api-config/raiffeisen/fetch-now'),
  )
  await page.getByRole('button', { name: 'Raiffeisen kézi fetch' }).click()
  await fetchRequest

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
