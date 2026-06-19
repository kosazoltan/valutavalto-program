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

async function mockAnonymousReportApis(page: Page) {
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

    if (path.endsWith('/anonymous-reports') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'report-1',
            reportType: 'COMPLAINT',
            subject: 'Lista szerinti tárgy',
            description: 'Lista szerinti rövid leírás',
            reportedAt: '2026-06-19T08:00:00.000Z',
            status: 'NEW',
          },
        ]),
      })
    }

    if (path.endsWith('/anonymous-reports/report-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'report-1',
          reportType: 'COMPLAINT',
          subject: 'Backend részletes tárgy',
          description: 'Backendből betöltött részletes leírás',
          reportedAt: '2026-06-19T08:00:00.000Z',
          status: 'NEW',
          assignedToName: 'Felelős dolgozó',
        }),
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

test('névtelen bejelentés részletei a backend detail endpointból nyílnak', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockAnonymousReportApis(page)
  await login(page)

  await page.goto('/anonymous-reports', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Lista szerinti tárgy')).toBeVisible()

  const detailRequest = page.waitForRequest(request =>
    request.method() === 'GET' && request.url().endsWith('/api/v1/anonymous-reports/report-1')
  )
  await page.getByRole('button', { name: /Részletek/i }).click()
  await detailRequest

  await expect(page.getByText('Backendből betöltött részletes leírás')).toBeVisible()
  await expect(page.getByText('Felelős dolgozó')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
