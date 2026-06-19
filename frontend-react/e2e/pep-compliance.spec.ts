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

    if (path.endsWith('/aml/summary') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          date: '2026-06-19',
          totalReports: 1,
          pendingReports: 1,
          submittedReports: 0,
          flaggedReports: 0,
          standardChecks: 1,
          enhancedChecks: 1,
          suspiciousChecks: 0,
          thresholdChecks: 1,
          totalAmountHuf: 5100000,
        }),
      })
    }

    if ((path.endsWith('/aml/pending') || path.endsWith('/aml/overdue') || path.endsWith('/aml/rolling-window-audit')) && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
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

test('/pep a valós AML compliance UI-t rendereli mobil viewporton', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/pep', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Compliance Dashboard')).toBeVisible()
  await expect(page.getByText('Kézi AML tranzakció-ellenőrzés')).toBeVisible()
  await expect(page.getByText(/nincs külön \/pep backend CRUD API/i)).toHaveCount(0)

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
