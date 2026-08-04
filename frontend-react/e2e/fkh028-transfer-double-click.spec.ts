import { expect, test, type Page } from '@playwright/test'

/**
 * FKH-028 Fázis 1 (DoD 4): dupla-kattintás védelem az Átadás létrehozása gombon.
 * A készlet-ellenőrző hívást lassítjuk, hogy a védtelen ablak (ha van) determinisztikusan
 * nyitva legyen — két gyors kattintásból pontosan EGY POST /api/v1/transfers mehet ki.
 */

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
  branchId: 'branch-own',
  branchCode: 'BR076',
  branchName: 'Pécsi értéktár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const branches = [
  {
    id: 'branch-own',
    code: 'BR076',
    name: 'Pécsi értéktár',
    isVault: true,
    branchTypeCode: 'VAULT',
    region: 'DD',
    vaultTerritoryId: 1,
    isActive: true,
  },
  {
    id: 'branch-target',
    code: 'BR001',
    name: 'Budapesti értéktár',
    isVault: true,
    branchTypeCode: 'VAULT',
    region: 'DD',
    vaultTerritoryId: 1,
    isActive: true,
  },
]

async function mockTransferApis(page: Page, state: { createCalls: number }) {
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

    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(branches),
      })
    }

    if (path.endsWith('/currencies') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 1, code: 'EUR', name: 'Euró', decimals: 2, active: true },
          { id: 2, code: 'HUF', name: 'Forint', decimals: 0, active: true },
        ]),
      })
    }

    if (path.endsWith('/cash-balances') && method === 'GET') {
      // Lassított készlet-ellenőrzés: a védtelen ablak determinisztikusan nyitva.
      await new Promise((resolve) => setTimeout(resolve, 700))
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ currencyCode: 'EUR', currentBalance: 100000 }]),
      })
    }

    if (path.endsWith('/exchange-rates') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([]),
      })
    }

    if (path.endsWith('/transfers') && method === 'POST') {
      state.createCalls += 1
      return route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify({
          id: state.createCalls,
          transferNumber: `AT-00000${8 + state.createCalls}`,
          toBranchCode: 'BR001',
          toBranchName: 'Budapesti értéktár',
          fromWorkerName: 'Admin Teszt',
          transferDate: '2026-08-04',
          transferTime: '10:00:00',
          currencyCode: 'EUR',
          amount: 100,
          carrierName: 'Teszt Szállító Kft',
          sealNumber: 'PL-12345',
        }),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
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

test('FKH-028: két gyors kattintás az Átadás létrehozása gombon → pontosan egy POST /transfers', async ({
  page,
}) => {
  const state = { createCalls: 0 }
  await mockTransferApis(page, state)
  await login(page)

  await page.goto('/transfers/new', { waitUntil: 'domcontentloaded' })

  await page.getByLabel('Cél iroda').selectOption('branch-target')
  await page.getByLabel('Valuta 1').selectOption('1')
  await page.getByPlaceholder('0').first().fill('100')
  await page.getByPlaceholder('Szállító neve...').fill('Teszt Szállító Kft')
  await page.getByPlaceholder('Plombaszám...').fill('PL-12345')

  const submit = page.getByRole('button', { name: /Átadás létrehozása/ })
  // Két gyors kattintás — a második a lassított készlet-ellenőrzés ablakában érkezik.
  // A force + noWaitAfter kihagyja az actionability-várakozást: ha a gomb már letiltott
  // (elvárt új viselkedés), a kattintás hatástalan; ha nem (mai hibás állapot), a második
  // kérés is elmegy — ezt fogja meg a POST-számláló.
  await submit.click({ noWaitAfter: true })
  await submit.click({ force: true, noWaitAfter: true })

  // A sikeres rögzítés visszajelzése megjelenik…
  await expect(page.getByText(/Átadás létrehozva/)).toBeVisible({ timeout: 10000 })
  // …és pontosan EGY create-kérés ment ki.
  expect(state.createCalls).toBe(1)
})
