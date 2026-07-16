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

const overview = {
  generatedAt: '2026-07-16T10:00:00.000Z',
  currencies: [
    {
      currencyId: 1,
      currencyCode: 'EUR',
      currencyName: 'Euró',
      displayOrder: 1,
      currentBuyRate: 395,
      currentSellRate: 420,
      officialRate: 400,
      limit1Amount: 50000,
      limit1BuyRate: null,
      limit1SellRate: null,
      limit2Amount: 300000,
      limit2BuyRate: null,
      limit2SellRate: null,
      limit3Amount: 1000000,
      limit3BuyRate: null,
      limit3SellRate: null,
      buyMarginPercent: null,
      sellMarginPercent: null,
      spreadPercent: null,
      middleRate: 400,
      lastUpdated: null,
      hasRate: true,
    },
  ],
}

function workgroup(protectionEnabled: boolean) {
  return {
    id: 'wg-1',
    code: 'WG01',
    name: 'Budapest központ',
    legacyGroupNumber: 1,
    active: true,
    branches: [],
    limit1Boundary: 50000,
    limit2Boundary: 300000,
    limit3Boundary: 1000000,
    tileColor: 'sky',
    protectionEnabled,
  }
}

async function mockApis(page: Page, protectionEnabled: boolean) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['RATE_READ', 'RATE_WRITE'],
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
          permissions: ['RATE_READ', 'RATE_WRITE'],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
        }),
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
    }
    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(worker),
      })
    }
    if (path.endsWith('/arfolyam-internet-links') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
    }
    if (path.endsWith('/local-rate-maker/bootstrap') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ overview, workgroups: [workgroup(protectionEnabled)] }),
      })
    }
    if (path.endsWith('/local-rate-maker/sheet') && method === 'GET') {
      return route.fulfill({ status: 204 })
    }
    if (path.endsWith('/local-rate-maker/sheet') && method === 'PUT') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ version: 1 }),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
  })
}

async function loginAndOpenEditor(page: Page, protectionEnabled: boolean) {
  await page.setViewportSize({ width: 1440, height: 900 })
  await mockApis(page, protectionEnabled)
  await page.goto('/login')
  await page.getByTestId('login-company-code').fill('EBC')
  await page.getByTestId('login-worker-code').fill('ADMIN')
  await page.getByTestId('login-password').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/rates\/main$/)

  await page.getByRole('button', { name: /CSOPORTOK KARBANTARTÁSA/i }).click()
  await expect(page).toHaveURL(/\/rates\/creation$/)
  await page.getByRole('button', { name: /Budapest központ.*árfolyamlap megnyitása/i }).click()
  await expect(page.locator('tbody tr').filter({ hasText: 'EUR' })).toBeVisible()
}

async function commitInvalidBuy(page: Page) {
  const eurRow = page.locator('tbody tr').filter({ hasText: 'EUR' })
  const buyInput = eurRow.locator('input').nth(1)
  await buyInput.dblclick()
  await buyInput.fill('405')
  await buyInput.press('Tab')
  await expect(buyInput).toHaveValue('405,00')
  return eurRow
}

test('védett csoportban az L > J commit azonnal piros rácshibát és Ellenőrzés-jelzést ad', async ({
  page,
}) => {
  await loginAndOpenEditor(page, true)
  const eurRow = await commitInvalidBuy(page)

  const protectionError = eurRow.getByText(
    '1-es csoport EUR L vétel nem lehet magasabb az elszámolónál (405 > 400).',
  )
  await expect(protectionError).toBeVisible()
  await expect(protectionError).toHaveClass(/text-red-600/)

  const layoutHealth = await protectionError.evaluate((element) => ({
    viewportOverflow:
      document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
    clipped:
      element.scrollWidth > element.clientWidth + 1 ||
      element.scrollHeight > element.clientHeight + 1,
  }))
  expect(layoutHealth).toEqual({ viewportOverflow: false, clipped: false })

  await page.getByRole('button', { name: 'Ellenőrzés', exact: true }).click()
  await expect(page.getByText(/1 valutánál eltérés\/hiba/)).toBeVisible()
})

test('kikapcsolt védelemnél ugyanaz az L > J commit nem jelenít meg védelmi hibát', async ({
  page,
}) => {
  await loginAndOpenEditor(page, false)
  const eurRow = await commitInvalidBuy(page)

  await expect(eurRow.getByText(/nem lehet magasabb az elszámolónál/)).toHaveCount(0)
  await page.getByRole('button', { name: 'Ellenőrzés', exact: true }).click()
  await expect(page.getByText(/A kliens-ellenőrzés rendben/)).toBeVisible()
})
