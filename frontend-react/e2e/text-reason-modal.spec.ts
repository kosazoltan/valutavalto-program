import { expect, test, type Page } from '@playwright/test'

// FKH-027: a natív window.prompt() kiváltása a közös TextReasonModal-lal.
// Ez a spec a valós böngészős render-lefedés a két C-csoportos képernyőre
// (CashDeskBreakPage kétlépcsős kérdés + AuthorizationSection suspend/revoke).
// Amit a jsdom-os unit teszt NEM tud ellenőrizni, és itt igen:
// viewport-overflow, váratlan vízszintes scrollbar, a modal kilógása,
// levágott cím-szöveg, cím/input és gomb/gomb átfedés — 1280x800 és 390x844 felbontáson.

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
  branchId: 'cashdesk-1',
  branchCode: 'SZEGED',
  branchName: 'Szeged pénztár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const activeAuthorization = {
  id: 'auth-001',
  representativeId: 'rep-1',
  authorizationTypeDid: 'CURRENCY_EXCHANGE',
  startDate: '2024-01-01',
  expiryDate: '2027-01-01',
  statusDid: 'ACTIVE',
  maxAmount: 500000,
  maxTransactionCount: 10,
  usedTransactionCount: 2,
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
    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'cashdesk-1', code: 'SZEGED', name: 'Szeged pénztár', isActive: true },
        ]),
      })
    }

    // --- CashDeskBreakPage: aktív szünet NÉLKÜL, hogy a "Szünet indítása" gomb látszódjon
    if (path.endsWith('/cash-desks') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 'cashdesk-1', name: 'Szeged pénztár', isActive: true }]),
      })
    }
    if (path.endsWith('/cash-desk-breaks') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: '[]' })
    }
    if (path.includes('/cash-desk-breaks/active/')) {
      return route.fulfill({ status: 200, contentType: 'application/json', body: 'null' })
    }

    // --- RepresentativeDetailPage / AuthorizationSection: ACTIVE meghatalmazás,
    //     így a Felfüggesztés ÉS a Visszavonás gomb is renderelődik
    if (path.endsWith('/authorized-representatives/rep-1/authorizations') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([activeAuthorization]),
      })
    }
    if (path.endsWith('/authorized-representatives/rep-1') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'rep-1',
          customerId: 'cust-1',
          firstName: 'Kis',
          lastName: 'Béla',
          fullName: 'Kis Béla',
          isActive: true,
        }),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
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

/**
 * Csapdába ejti a natív window.prompt()-ot: ha bármelyik oldal mégis meghívná,
 * a számláló nő és a teszt bukik. (Electronban a natív prompt silent no-op,
 * ezért kell a modal — pont ezt a regressziót őrizzük.)
 */
async function trapNativePrompt(page: Page): Promise<() => number> {
  let calls = 0
  await page.exposeFunction('__nativePromptCalled', () => {
    calls += 1
  })
  await page.addInitScript(() => {
    window.prompt = (() => {
      ;(window as unknown as { __nativePromptCalled: () => void }).__nativePromptCalled()
      return null
    }) as typeof window.prompt
  })
  return () => calls
}

/** A modal layout-egészsége: nincs overflow, kilógás, levágott szöveg vagy átfedés. */
async function assertModalLayoutHealthy(page: Page, label: string) {
  const dialog = page.getByRole('alertdialog')
  await expect(dialog).toBeVisible()

  // 1) nincs vízszintes viewport-overflow / váratlan scrollbar
  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow, `${label}: vízszintes viewport-overflow`).toBe(false)

  // 2) a modal doboza a viewporton belül van
  const box = await dialog.locator('> div').boundingBox()
  const viewport = page.viewportSize()!
  expect(box, `${label}: nem található a modal doboza`).not.toBeNull()
  expect(box!.x, `${label}: a modal balra kilóg`).toBeGreaterThanOrEqual(0)
  expect(box!.y, `${label}: a modal felfelé kilóg`).toBeGreaterThanOrEqual(0)
  expect(box!.x + box!.width, `${label}: a modal jobbra kilóg`).toBeLessThanOrEqual(
    viewport.width + 1,
  )
  expect(box!.y + box!.height, `${label}: a modal lefelé kilóg`).toBeLessThanOrEqual(
    viewport.height + 1,
  )

  // 3) a cím nincs levágva
  const title = await dialog.locator('h2').evaluate((el) => ({
    text: el.textContent,
    clippedX: el.scrollWidth > el.clientWidth + 1,
    clippedY: el.scrollHeight > el.clientHeight + 1,
  }))
  expect(title.clippedX, `${label}: a cím vízszintesen levágva ("${title.text}")`).toBe(false)
  expect(title.clippedY, `${label}: a cím függőlegesen levágva ("${title.text}")`).toBe(false)

  // 4) a cím és a beviteli mező nem fed át
  const titleBox = await dialog.locator('h2').boundingBox()
  const inputBox = await dialog.locator('input').boundingBox()
  expect(titleBox!.y + titleBox!.height, `${label}: a cím és az input átfed`).toBeLessThanOrEqual(
    inputBox!.y + 1,
  )

  // 5) a Mégse és az OK gomb nem fed át
  const cancelBox = await dialog.getByRole('button', { name: 'Mégse' }).boundingBox()
  const okBox = await dialog.getByRole('button', { name: 'OK' }).boundingBox()
  expect(
    cancelBox!.x + cancelBox!.width,
    `${label}: a Mégse és az OK gomb átfed`,
  ).toBeLessThanOrEqual(okBox!.x + 1)
}

test('CashDeskBreakPage: a két kérdés modálként, szigorúan sorosan jelenik meg', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 800 })
  await mockApis(page)
  await login(page)
  const nativePromptCalls = await trapNativePrompt(page)

  await page.goto('/cashdesk/breaks', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: /Szünet indítása/ }).click()

  // 1. kérdés: a szünet típusa
  await expect(
    page.getByRole('heading', { name: 'Szünet típusa (pl: LUNCH, BREAK):' }),
  ).toBeVisible()
  await expect(page.getByRole('alertdialog')).toHaveCount(1)
  await assertModalLayoutHealthy(page, '1. kérdés (típus)')

  // 2. kérdés: az ok — csak az első lezárása UTÁN, és sosem egyszerre az elsővel
  await page.getByRole('alertdialog').locator('input').fill('LUNCH')
  await page.getByRole('alertdialog').getByRole('button', { name: 'OK' }).click()
  await expect(page.getByRole('heading', { name: 'Ok (opcionális):' })).toBeVisible()
  await expect(page.getByRole('alertdialog')).toHaveCount(1)
  await expect(
    page.getByRole('heading', { name: 'Szünet típusa (pl: LUNCH, BREAK):' }),
  ).toHaveCount(0)
  await assertModalLayoutHealthy(page, '2. kérdés (ok)')

  await page.getByRole('alertdialog').getByRole('button', { name: 'Mégse' }).click()
  await expect(page.getByRole('alertdialog')).toHaveCount(0)

  expect(nativePromptCalls(), 'natív window.prompt hívás történt').toBe(0)
})

test('CashDeskBreakPage: a modal mobil viewporton (390px) sem lóg ki', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)
  const nativePromptCalls = await trapNativePrompt(page)

  await page.goto('/cashdesk/breaks', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: /Szünet indítása/ }).click()

  await assertModalLayoutHealthy(page, 'mobil 390x844 (típus)')
  expect(nativePromptCalls(), 'natív window.prompt hívás történt').toBe(0)
})

test('AuthorizationSection: a felfüggesztés és a visszavonás oka modálként jelenik meg', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 800 })
  await mockApis(page)
  await login(page)
  const nativePromptCalls = await trapNativePrompt(page)

  await page.goto('/customers/cust-1/representatives/rep-1', { waitUntil: 'domcontentloaded' })

  await page.getByTitle('Felfüggesztés').click()
  await expect(page.getByRole('heading', { name: 'Felfüggesztés oka:' })).toBeVisible()
  await assertModalLayoutHealthy(page, 'Felfüggesztés oka')
  await page.getByRole('alertdialog').getByRole('button', { name: 'Mégse' }).click()
  await expect(page.getByRole('alertdialog')).toHaveCount(0)

  await page.getByTitle('Visszavonás').click()
  await expect(page.getByRole('heading', { name: 'Visszavonás oka:' })).toBeVisible()
  await assertModalLayoutHealthy(page, 'Visszavonás oka')

  expect(nativePromptCalls(), 'natív window.prompt hívás történt').toBe(0)
})

test('AuthorizationSection: a modal mobil viewporton (390px) sem lóg ki', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)
  const nativePromptCalls = await trapNativePrompt(page)

  await page.goto('/customers/cust-1/representatives/rep-1', { waitUntil: 'domcontentloaded' })
  await page.getByTitle('Felfüggesztés').click()

  await assertModalLayoutHealthy(page, 'mobil 390x844 (Felfüggesztés oka)')
  expect(nativePromptCalls(), 'natív window.prompt hívás történt').toBe(0)
})
