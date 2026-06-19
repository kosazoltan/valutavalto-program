import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const wizardId = '11111111-1111-1111-1111-111111111111'

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

async function mockClosingApis(page: Page) {
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

    if (path.endsWith('/daily-sessions/validate-closing') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          validationDate: '2026-06-18',
          errorCode: 0,
          errorMessage: 'OK',
          allValid: true,
          currencyDenominationOk: true,
          handlingFeeDenominationOk: true,
          westernUnionDenominationOk: true,
          vatDenominationOk: true,
          ecommerceDenominationOk: true,
        }),
      })
    }

    if (path.endsWith('/closing-wizard/start') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: wizardId,
          branchId: 'branch-1',
          status: 'IN_PROGRESS',
          closingType: 'DAILY',
          steps: [{ stepNumber: 1, stepName: 'Címletezés', completed: true, status: 'OK' }],
        }),
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/denominations`) && method === 'POST') {
      expect(await route.request().postDataJSON()).toEqual({ HUF: { 20000: 5 } })
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ total: 100000 }) })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/differences`) && method === 'POST') {
      expect(await route.request().postDataJSON()).toEqual({ HUF: 100000 })
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { currencyCode: 'HUF', expected: 100000, actual: 100000, difference: 0, status: 'OK' },
        ]),
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/navigate`) && method === 'POST') {
      const targetStep = Number(url.searchParams.get('targetStep') ?? '2')
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: wizardId,
          branchId: 'branch-1',
          status: 'IN_PROGRESS',
          closingType: 'DAILY',
          steps: [{ stepNumber: targetStep, stepName: `Step ${targetStep}`, completed: true, status: 'OK' }],
        }),
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/report`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          wizardId,
          branchName: 'Budapest 01',
          closingDate: '2026-06-18',
          closingType: 'DAILY',
          transactionCount: 3,
          inventory: [{ currencyCode: 'HUF', openingBalance: 100000, currentBalance: 100000, dailyChange: 0 }],
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

test('zárási eltérés ellenőrzés mobil viewporton backend differences POST után renderel', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockClosingApis(page)
  await login(page)

  await page.goto('/closing/wizard', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i }).click()

  const firstDenomination = page.getByRole('spinbutton').first()
  await firstDenomination.fill('5')
  await page.getByRole('button', { name: /Cimletezés rogzitese/i }).click()

  await expect(page.getByText('Eltérés ellenőrzés')).toBeVisible()
  await expect(page.getByTestId('closing-differences-table')).toContainText('HUF')
  await expect(page.getByTestId('closing-differences-table')).toContainText('Nincs eltérés')
  await expect(page.getByText('Zárási riport előnézet')).toBeVisible()

  const horizontalOverflow = await page.evaluate(() =>
    document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
  )
  expect(horizontalOverflow).toBe(false)
})
