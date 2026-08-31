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
  branchCode: 'SZEK',
  branchName: 'Szekszárd Értéktár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

async function mockInventoryApis(page: Page) {
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

    if (
      path.match(/\/api\/v1\/inventory\/(bank-withdraw|bank-deposit|transfer|correction)$/) &&
      method === 'POST'
    ) {
      return route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify({ id: 90, status: 'PENDING', currencyCode: 'EUR', amount: 250 }),
      })
    }

    if (path.endsWith('/inventory/regeneration/run') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ discrepancyCount: 2, correctedCount: 2 }),
      })
    }

    if (path.match(/\/api\/v1\/inventory\/\d+\/(approve|receive|cancel)$/) && method === 'POST') {
      return route.fulfill({
        status: path.endsWith('/cancel') ? 204 : 200,
        contentType: 'application/json',
        body: path.endsWith('/cancel') ? '' : JSON.stringify({ id: 77, status: 'APPROVED' }),
      })
    }

    const bodyByPath: Record<string, unknown> = {
      // FKH-043: a "Mobil készlet-riportok" panel rejtve; a currency mock a flag-visszakapcsoláshoz marad.
      // töltődik; e nélkül a lista üres és a "Művelet rögzítése" gomb disabled marad.
      '/api/v1/currencies': [
        { id: 978, code: 'EUR', name: 'Euró', decimals: 2, active: true, displayOrder: 1 },
        {
          id: 840,
          code: 'USD',
          name: 'Amerikai dollár',
          decimals: 2,
          active: true,
          displayOrder: 2,
        },
      ],
      '/api/v1/inventory/vault-stock': [
        {
          currencyCode: 'HUF',
          currencyName: 'Magyar forint',
          opening: 800,
          received: 0,
          issued: 0,
          closing: 700,
        },
        {
          currencyCode: 'EUR',
          currencyName: 'Euró',
          opening: 300,
          received: 0,
          issued: 0,
          closing: 500,
        },
      ],
      '/api/v1/inventory/stock/11111111-1111-1111-1111-111111111111': [
        {
          branchId: '11111111-1111-1111-1111-111111111111',
          branchName: 'Szekszárd Értéktár',
          currencyId: 978,
          currencyCode: 'EUR',
          currencyName: 'Euró',
          currentBalance: 1200,
          openingBalance: 1000,
        },
      ],
      '/api/v1/inventory/matrix': {
        matrix: { '11111111-1111-1111-1111-111111111111': { EUR: 1200, HUF: 700 } },
      },
      '/api/v1/inventory/movements': {
        content: [
          {
            id: 77,
            fromBranchName: 'Központ',
            toBranchName: 'Szekszárd Értéktár',
            currencyCode: 'EUR',
            amount: 300,
            movementType: 'BRANCH_TRANSFER',
            movementTypeDisplay: 'Átadás',
            status: 'PENDING',
            statusDisplay: 'Függőben',
          },
          {
            id: 78,
            fromBranchName: 'Bank',
            toBranchName: 'Szekszárd Értéktár',
            currencyCode: 'USD',
            amount: 400,
            movementType: 'BANK_WITHDRAW',
            movementTypeDisplay: 'Bankból kivét',
            status: 'IN_TRANSIT',
            statusDisplay: 'Szállítás alatt',
          },
        ],
      },
      '/api/v1/inventory-movements/movement-log': [
        {
          id: 77,
          fromBranchName: 'Központ',
          toBranchName: 'Szekszárd Értéktár',
          currencyCode: 'EUR',
          amount: 300,
        },
      ],
      '/api/v1/inventory-movements/daily-balance': {
        currencyCode: 'EUR',
        closingBalance: 1200,
        totalIn: 300,
        totalOut: 100,
      },
      '/api/v1/inventory/regeneration/last': {
        discrepancyCount: 1,
        correctedCount: 1,
        regeneratedAt: '2026-06-18T08:00:00',
      },
      '/api/v1/banknote-inventory/branch/11111111-1111-1111-1111-111111111111': [
        {
          id: 1,
          currencyId: 978,
          currencyCode: 'EUR',
          faceValue: 50,
          quantity: 3,
          totalValue: 150,
          minQuantity: 5,
          maxQuantity: 100,
          lowStock: true,
          overStock: false,
        },
      ],
      '/api/v1/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/low-stock': [
        { id: 1, currencyId: 978, currencyCode: 'EUR', faceValue: 50, quantity: 3, lowStock: true },
      ],
      '/api/v1/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/over-stock': [],
    }

    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(bodyByPath[path] ?? []),
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

test('FKH-043: /inventory mobil viewporton NEM mutatja a Mobil készlet-riportok panelt, a záró HUF kártyát igen', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockInventoryApis(page)
  await login(page)

  await page.goto('/inventory', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Értéktári záró HUF készlet')).toBeVisible()
  await expect(page.getByTestId('inventory-operation-panel')).toHaveCount(0)
  await expect(page.getByText('Mobil készlet-riportok')).toHaveCount(0)

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
