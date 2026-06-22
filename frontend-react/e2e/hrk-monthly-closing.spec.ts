import { expect, test, type Page } from '@playwright/test'

// FK-040 (2026-06-22): a HRK (horvát kuna) pénztár-bank készletmozgás 2025-01-01 óta nem
// forgalmazott, ezért a havi zárás aktív UI-jából kivezettük (HRK havi + HRK napi napló panelek).
// Ez a spec korábban a HRK panel MEGLÉTÉT várta — most regressziós őrré alakítva: a valós havi
// zárás renderel, az elavult HRK szekciók NEM jelennek meg, és a /hrk/* végpontok nem hívódnak.

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

    if (path.endsWith('/closing/monthly/branch-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'closing-1', yearMonth: '2026-06', branchName: 'Budapest 01', status: 'OPEN' },
        ]),
      })
    }

    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ content: [], data: [], total: 0 }),
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

test('havi zárás mobilnézetben az elavult HRK szekciók nélkül renderel (FK-040)', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })

  // FK-040 regressziós őr: a /hrk/* végpontokat NEM szabad hívni a havi zárásból.
  let hrkEndpointCalled = false

  await mockApis(page)
  // A /hrk/** guardot a mockApis catch-all UTÁN regisztráljuk: a Playwright a legutoljára
  // regisztrált egyező route-ot használja, így ez kapja meg a /hrk/* hívásokat (ha lennének).
  await page.route('**/api/v1/hrk/**', async (route) => {
    hrkEndpointCalled = true
    await route.fulfill({ status: 404, contentType: 'application/json', body: '{}' })
  })
  page.on('dialog', (dialog) => void dialog.accept())
  await login(page)

  await page.goto('/closing/monthly', { waitUntil: 'domcontentloaded' })

  // A valós havi zárás renderel (akciópanel + a lezárt hónapok lista sora).
  await expect(page.getByTestId('monthly-closing-action-panel')).toBeVisible()
  // A '2026-06' a lista-sor egyedi szovege (a fejléc telephely-neve viszont tobbszor szerepel,
  // ezert azt strict-mode-ban nem hasznaljuk).
  await expect(page.getByText('2026-06')).toBeVisible()

  // Az elavult HRK szekciók NEM jelennek meg.
  await expect(page.getByTestId('hrk-monthly-panel')).toHaveCount(0)
  await expect(page.getByTestId('hrk-daily-movement-form')).toHaveCount(0)
  await expect(page.getByText('HRK havi készletmozgás')).toHaveCount(0)
  await expect(page.getByText('HRK napi napló')).toHaveCount(0)

  // A HRK backend végpontokat nem hívta meg az oldal.
  expect(hrkEndpointCalled).toBe(false)

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
