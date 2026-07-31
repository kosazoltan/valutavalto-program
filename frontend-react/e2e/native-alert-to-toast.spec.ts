import { expect, test, type Page } from '@playwright/test'

// B-csoport: a natív window.alert() kiváltása a közös toast-tal (components/ui/toaster).
// Ez a spec a valós böngészős render-lefedés a két toast-variánsra:
//   - toast.error CÍM + RÉSZLET  → BankOrderPage handleApprove catch-ág (#1)
//   - toast.warning EGY ARGUMENTUM → RatesPage saveEdit validáció (#4)
// Amit a jsdom-os unit teszt NEM tud ellenőrizni, és itt igen: a toast tényleg
// renderelődik-e, a pontos megjelenő szöveg, viewport-túlcsordulás/levágás, és hogy
// natív window.alert() egyáltalán nem fut — 1280x800 és 390x844 felbontáson.
//
// Megjegyzés a RatesPage mobil-lefedéshez (méréssel igazolva, 390x844): a kártyás variánsban
// van „Szerkesztés" gomb, de a „Mentés" és a „Jóváhagyás kérés" gomb a `hidden md:block`
// szerkesztő táblában él (RatesPage.tsx:1845) — mobilon a DOM-ban ott van, de NEM látható
// (visible count = 0). A validációs toast így 390px-en a UI-ból nem váltható ki; ez az oldal
// meglévő tulajdonsága (mobil szerkesztés zsákutca), nem ennek a körnek a scope-ja. Ezért a
// warning-variáns 1280x800-on fut, a mobil viewportot pedig a BankOrderPage error-variánsa fedi.

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

const pendingBankOrder = {
  id: 'order-1',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  currencyId: 2,
  currencyCode: 'EUR',
  amount: '1000',
  status: 'PENDING',
  urgency: 'NORMAL',
  requestedByWorkerId: 77,
  requestedByWorkerName: 'Lista kérő',
  requestedAt: '2026-06-19T08:00:00.000Z',
}

// A vételi (399,00) >= eladási (398,50) → a szerkesztő mentéskor a validációs toastot adja.
const invalidEurRate = {
  id: 1,
  currencyCode: 'EUR',
  currencyName: 'Euró',
  baseBuyRate: 399,
  baseSellRate: 398.5,
  officialRate: 391.25,
  validTime: '10:30',
  currencyId: 1,
  createdAt: '2026-07-31T08:00:00.000Z',
}

const eurCurrency = { id: 1, code: 'EUR', name: 'Euró', decimals: 2, displayOrder: 8, active: true }

const APPROVE_ERROR_TITLE = 'Hiba a jóváhagyásnál'
const APPROVE_ERROR_DETAIL = 'Request failed with status code 500'
const RATE_VALIDATION_TEXT = 'A vételi árfolyamnak kisebbnek kell lennie az eladásinál!'

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

    if (path.endsWith('/bank-orders') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          content: [pendingBankOrder],
          totalElements: 1,
          totalPages: 1,
          number: 0,
          size: 100,
        }),
      })
    }

    // A jóváhagyás SZÁNDÉKOSAN hibára fut → a catch-ág toast.error-ja jelenik meg.
    if (path.endsWith('/bank-orders/order-1/approve') && method === 'POST') {
      return route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ message: 'Backend hiba' }),
      })
    }

    if (path.endsWith('/exchange-rates') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([invalidEurRate]),
      })
    }

    if (path.endsWith('/currencies') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([eurCurrency]),
      })
    }

    return route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ content: [], data: [] }),
    })
  })
}

/**
 * Csapdába ejti a natív window.alert()-et: ha bármelyik oldal mégis meghívná, a számláló
 * nő és a teszt bukik. A window.confirm determinisztikusan `true` — a megerősítő dialógusok
 * (A-csoport) cseréje NEM ennek a körnek a tárgya, itt csak átengedjük a guardot.
 */
async function trapNativeAlert(page: Page): Promise<() => number> {
  let calls = 0
  await page.exposeFunction('__nativeAlertCalled', () => {
    calls += 1
  })
  await page.addInitScript(() => {
    window.alert = (() => {
      ;(window as unknown as { __nativeAlertCalled: () => void }).__nativeAlertCalled()
    }) as typeof window.alert
    window.confirm = (() => true) as typeof window.confirm
  })
  return () => calls
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

/** A Toaster egyetlen toast-doboza (components/ui/toaster.tsx: fixed bottom-4 right-4). */
function toastBox(page: Page) {
  return page.locator('div.fixed.bottom-4.right-4 > div').first()
}

/** A toast CÍME (toaster.tsx: `font-semibold` div — mindig az 1. argumentum). */
function toastTitle(page: Page) {
  return toastBox(page).locator('div.font-semibold')
}

/** A toast RÉSZLET-sora (toaster.tsx: `text-sm` div — csak ha van 2. argumentum). */
function toastDetail(page: Page) {
  return toastBox(page).locator('div.text-sm')
}

function hasHorizontalOverflow(page: Page) {
  return page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
}

/** A toast layout-egészsége: nincs kilógás, levágott szöveg, és nem okoz új vízszintes overflow-t. */
async function assertToastLayoutHealthy(page: Page, label: string, overflowBefore: boolean) {
  const box = toastBox(page)
  await expect(box, `${label}: a toast nem látható`).toBeVisible()

  // A slide-in animáció (index.css: translateX(100%) → 0, 0.3s) lefutása után mérünk,
  // különben a köztes pozíció hamis „kilóg a viewportból" eredményt adna.
  await page.waitForTimeout(600)

  const rect = await box.boundingBox()
  const viewport = page.viewportSize()!
  expect(rect, `${label}: a toast nem kapott layout-boxot`).not.toBeNull()
  expect(rect!.width, `${label}: a toast szélessége 0`).toBeGreaterThan(0)
  expect(rect!.height, `${label}: a toast magassága 0`).toBeGreaterThan(0)
  expect(rect!.x, `${label}: a toast balra kilóg`).toBeGreaterThanOrEqual(0)
  expect(rect!.y, `${label}: a toast felfelé kilóg`).toBeGreaterThanOrEqual(0)
  expect(rect!.x + rect!.width, `${label}: a toast jobbra kilóg`).toBeLessThanOrEqual(
    viewport.width + 1,
  )
  expect(rect!.y + rect!.height, `${label}: a toast lefelé kilóg`).toBeLessThanOrEqual(
    viewport.height + 1,
  )

  // A szöveg nincs levágva (a doboz tartalma elfér benne).
  const clipped = await box.evaluate(
    (el) => el.scrollWidth > el.clientWidth + 1 || el.scrollHeight > el.clientHeight + 1,
  )
  expect(clipped, `${label}: a toast szövege le van vágva`).toBe(false)

  // A toast nem hoz be új vízszintes scrollbart (az oldal saját overflow-ja változatlan).
  expect(
    await hasHorizontalOverflow(page),
    `${label}: a toast új vízszintes viewport-overflow-t okozott`,
  ).toBe(overflowBefore)
}

async function openBankOrdersAndFailApprove(page: Page) {
  await page.goto('/bank-orders', { waitUntil: 'domcontentloaded' })
  const overflowBefore = await hasHorizontalOverflow(page)
  await page.getByRole('button', { name: 'Jóváhagy' }).click()
  return overflowBefore
}

test('BankOrderPage: a jóváhagyási hiba toast-ban jelenik meg (cím + részlet), 1280x800', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 800 })
  const nativeAlertCalls = await trapNativeAlert(page)
  await mockApis(page)
  await login(page)

  const overflowBefore = await openBankOrdersAndFailApprove(page)

  await expect(toastTitle(page)).toHaveText(APPROVE_ERROR_TITLE)
  await expect(toastDetail(page)).toHaveText(APPROVE_ERROR_DETAIL)
  await assertToastLayoutHealthy(page, 'BankOrderPage 1280x800', overflowBefore)
  expect(nativeAlertCalls(), 'natív window.alert() hívás történt').toBe(0)
})

test('BankOrderPage: a hiba-toast mobil viewporton (390px) sem lóg ki', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  const nativeAlertCalls = await trapNativeAlert(page)
  await mockApis(page)
  await login(page)

  const overflowBefore = await openBankOrdersAndFailApprove(page)

  await expect(toastTitle(page)).toHaveText(APPROVE_ERROR_TITLE)
  await expect(toastDetail(page)).toHaveText(APPROVE_ERROR_DETAIL)
  await assertToastLayoutHealthy(page, 'BankOrderPage 390x844', overflowBefore)
  expect(nativeAlertCalls(), 'natív window.alert() hívás történt').toBe(0)
})

test('RatesPage: a mentési validáció EGYSOROS warning-toastot ad, 1280x800', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 })
  const nativeAlertCalls = await trapNativeAlert(page)
  await mockApis(page)
  await login(page)

  await page.goto('/rates', { waitUntil: 'domcontentloaded' })
  const overflowBefore = await hasHorizontalOverflow(page)
  await page.getByTitle('Szerkesztés').first().click()
  await page.getByTitle('Mentés').click()

  // Egyargumentumos hívás → a toastban CSAK a cím van, részlet-sor nincs.
  await expect(toastTitle(page)).toHaveText(RATE_VALIDATION_TEXT)
  await expect(toastDetail(page), 'egyargumentumos toast: nem lehet részlet-sor').toHaveCount(0)
  await assertToastLayoutHealthy(page, 'RatesPage 1280x800', overflowBefore)
  expect(nativeAlertCalls(), 'natív window.alert() hívás történt').toBe(0)
})
