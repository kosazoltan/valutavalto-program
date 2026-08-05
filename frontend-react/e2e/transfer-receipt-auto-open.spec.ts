import { expect, test, type Page } from '@playwright/test'

/**
 * Transfer-flow egységesítés (Tomi, 2026-08-05): sikeres átadás-létrehozás után
 * a szállítólevél-előnézet (TransferReceiptModal) AUTOMATIKUSAN megnyílik —
 * a Cashier/Shipment mintára —, kézi "Nyomtatás" gombnyomás nélkül. Teljes
 * képernyős render-ellenőrzés: a modal látható, a gombjai a viewporton belül
 * vannak, nincs vízszintes overflow.
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
  branchCode: 'SZEGED',
  branchName: 'Szeged Értéktár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const createdTransfer = {
  id: 42,
  transferNumber: 'AT105000042',
  fromBranchCode: 'SZEGED',
  fromBranchName: 'Szeged Értéktár',
  toBranchCode: 'BR001',
  toBranchName: 'Budapesti értéktár',
  fromWorkerName: 'Admin Teszt',
  transferDate: '2026-08-05',
  transferTime: '10:00:00',
  currencyCode: 'EUR',
  amount: 100,
  hufValue: 39150,
  status: 'PENDING',
  direction: 'F',
  transferType: 'CURRENCY',
  carrierName: 'Teszt Szállító Kft',
  sealNumber: 'PL-12345',
}

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['READ', 'WRITE', 'TRANSFER_WRITE'],
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
          permissions: ['READ', 'WRITE', 'TRANSFER_WRITE'],
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

    if (path.endsWith('/transfers') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(createdTransfer),
      })
    }

    if (
      (path.endsWith('/transfers/outgoing') || path.endsWith('/transfers/incoming')) &&
      method === 'GET'
    ) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([]),
      })
    }

    if (path.endsWith('/transfers/pending') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([]),
      })
    }

    if (path.endsWith('/transfers/pending/count') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(0),
      })
    }

    if (path.endsWith('/currencies') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 1, code: 'EUR', name: 'Euró', active: true, decimals: 2 }]),
      })
    }

    if (path.endsWith('/cash-balances') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ currencyCode: 'EUR', currentBalance: 100000 }]),
      })
    }

    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'branch-own',
            code: 'SZEGED',
            name: 'Szeged Értéktár',
            isVault: true,
            branchTypeCode: 'VAULT',
            region: 'DD',
            vaultTerritoryId: 1,
          },
          {
            id: 'branch-target',
            code: 'BR001',
            name: 'Budapesti értéktár',
            isVault: true,
            branchTypeCode: 'VAULT',
            region: 'DD',
            vaultTerritoryId: 1,
          },
        ]),
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

test('sikeres átadás után a szállítólevél-előnézet automatikusan megnyílik, teljes képernyőn helyesen renderelve', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 800 })
  await mockApis(page)
  await login(page)

  await page.goto('/transfers/new', { waitUntil: 'domcontentloaded' })
  await expect(page.getByLabel('Cél iroda')).toBeVisible()

  await page.getByLabel('Cél iroda').selectOption('branch-target')
  await page.getByLabel('Valuta 1').selectOption('1')
  await page.getByPlaceholder('0').first().fill('100')
  await page.getByPlaceholder('Szállító neve...').fill('Teszt Szállító Kft')
  await page.getByPlaceholder('Plombaszám...').fill('PL-12345')

  const createRequest = page.waitForRequest(
    (request) =>
      request.method() === 'POST' && new URL(request.url()).pathname === '/api/v1/transfers',
  )
  await page.getByRole('button', { name: 'Átadás létrehozása' }).click()
  await createRequest

  // Siker-banner + AUTOMATIKUSAN megnyíló előnézet-modal (kézi gombnyomás nélkül)
  await expect(page.getByText('Átadás létrehozva: AT105000042')).toBeVisible()
  const cancelButton = page.getByText('Mégse (ESC)')
  await expect(cancelButton).toBeVisible()

  // A bizonylat-szám megjelenik az előnézeten
  await expect(page.getByText('AT105000042').nth(1)).toBeVisible()

  // Render-minőség: a modal gombjai a viewporton belül vannak, nincs levágás.
  // Codex MEDIUM (PR #1561): a primer "Nyomtatás" akciógomb is ellenőrizve — a
  // siker-banner azonos feliratú gombja miatt a modal-overlay-re szűkítünk.
  const modalOverlay = page.locator('div.fixed.inset-0')
  const printButton = modalOverlay.getByRole('button', { name: 'Nyomtatás', exact: true })
  await expect(printButton).toBeVisible()
  const printBox = await printButton.boundingBox()
  expect(printBox).not.toBeNull()
  expect(printBox!.y).toBeGreaterThanOrEqual(0)
  expect(printBox!.x).toBeGreaterThanOrEqual(0)
  expect(printBox!.y + printBox!.height).toBeLessThanOrEqual(800)
  expect(printBox!.x + printBox!.width).toBeLessThanOrEqual(1280)

  const cancelBox = await cancelButton.boundingBox()
  expect(cancelBox).not.toBeNull()
  expect(cancelBox!.y).toBeGreaterThanOrEqual(0)
  expect(cancelBox!.x).toBeGreaterThanOrEqual(0)
  expect(cancelBox!.y + cancelBox!.height).toBeLessThanOrEqual(800)
  expect(cancelBox!.x + cancelBox!.width).toBeLessThanOrEqual(1280)

  // Nincs vízszintes overflow / váratlan scrollbar
  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)

  // A modal ESC-kel zárható — a flow nem ragad be
  await page.keyboard.press('Escape')
  await expect(page.getByText('Mégse (ESC)')).toHaveCount(0)
})
