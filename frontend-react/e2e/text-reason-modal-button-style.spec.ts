import { expect, test, type Page } from '@playwright/test'

// RED (btn-primary/btn-secondary CSS-hiány): a TextReasonModal OK/Mégse gombja a
// `btn-primary` / `btn-secondary` osztályt kapja, amelyek sehol nincsenek definiálva
// a projekt CSS-ében. A Tailwind preflight a natív gomb-megjelenést leszedi
// (átlátszó háttér, 0 padding), így a gombok élesben stílus nélküli sima
// szövegként látszanak — pontosan ezt a felhasználói tünetet méri ez a spec.
//
// Miért Playwright és nem (csak) jsdom-os komponensteszt: a jsdom nem tölti be a
// Tailwind-fordított CSS-t, ezért ott csak osztálynév-stringet lehet assertálni
// (azt a TextReasonModal.buttonStyle.test.tsx meg is teszi). A tényleges tünet —
// "a gomb nem néz ki gombnak" — csak valós böngészőben, computed style-lal mérhető.

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

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['READ', 'WRITE'],
    roles: ['ADMIN'],
  })

  await page.route('**/api/v1/**', async (route) => {
    const path = new URL(route.request().url()).pathname
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
    // CashDeskBreakPage: aktív szünet NÉLKÜL, hogy a "Szünet indítása" gomb látszódjon
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

interface ButtonStyle {
  backgroundColor: string
  paddingLeft: number
  paddingRight: number
  paddingTop: number
  paddingBottom: number
  borderRadius: number
  height: number
  className: string
}

async function readButtonStyle(page: Page, name: string): Promise<ButtonStyle> {
  return page
    .getByRole('alertdialog')
    .getByRole('button', { name, exact: true })
    .evaluate((element) => {
      const style = getComputedStyle(element)
      return {
        backgroundColor: style.backgroundColor,
        paddingLeft: parseFloat(style.paddingLeft),
        paddingRight: parseFloat(style.paddingRight),
        paddingTop: parseFloat(style.paddingTop),
        paddingBottom: parseFloat(style.paddingBottom),
        borderRadius: parseFloat(style.borderTopLeftRadius),
        height: element.getBoundingClientRect().height,
        className: element.className,
      }
    })
}

/** rgba(0, 0, 0, 0) vagy bármely alpha=0 érték → nincs kitöltött háttér */
function isTransparent(color: string): boolean {
  const match = color.match(/rgba?\(([^)]+)\)/)
  if (!match) return false
  const parts = match[1].split(',').map((value) => parseFloat(value.trim()))
  return parts.length === 4 && parts[3] === 0
}

/** Minden gombra kötelező: kitöltött vagy keretezett doboz, valódi padding, lekerekítés. */
function assertLooksLikeButton(style: ButtonStyle, label: string) {
  expect(
    isTransparent(style.backgroundColor),
    `${label}: átlátszó háttér — a gomb sima szövegként jelenik meg (class="${style.className}")`,
  ).toBe(false)
  expect(
    Math.min(style.paddingLeft, style.paddingRight),
    `${label}: nincs vízszintes padding (class="${style.className}")`,
  ).toBeGreaterThanOrEqual(8)
  expect(
    Math.min(style.paddingTop, style.paddingBottom),
    `${label}: nincs függőleges padding (class="${style.className}")`,
  ).toBeGreaterThan(0)
  expect(
    style.borderRadius,
    `${label}: nincs lekerekítés (class="${style.className}")`,
  ).toBeGreaterThan(0)
  expect(style.height, `${label}: túl alacsony kattintható felület`).toBeGreaterThanOrEqual(24)
}

async function openTextReasonModal(page: Page) {
  await mockApis(page)
  await login(page)
  await page.goto('/cashdesk/breaks', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: /Szünet indítása/ }).click()
  await expect(page.getByRole('alertdialog')).toBeVisible()
}

test('TextReasonModal: az OK és a Mégse gomb valós, kirajzolt gomb-stílust kap', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 800 })
  await openTextReasonModal(page)

  const ok = await readButtonStyle(page, 'OK')
  const cancel = await readButtonStyle(page, 'Mégse')

  assertLooksLikeButton(ok, 'OK gomb')
  assertLooksLikeButton(cancel, 'Mégse gomb')

  // Az elsődleges gomb kitöltött, nem fehér háttérrel emelkedik ki
  expect(ok.backgroundColor, 'OK gomb: fehér (kiemelés nélküli) háttér').not.toBe(
    'rgb(255, 255, 255)',
  )
  // Elsődleges és másodlagos gomb vizuálisan megkülönböztethető
  expect(
    ok.backgroundColor,
    'OK és Mégse gomb háttere azonos — nincs elsődleges/másodlagos hierarchia',
  ).not.toBe(cancel.backgroundColor)
})

test('TextReasonModal: a gombok mobil viewporton (390px) is gombnak látszanak', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await openTextReasonModal(page)

  assertLooksLikeButton(await readButtonStyle(page, 'OK'), 'OK gomb (mobil)')
  assertLooksLikeButton(await readButtonStyle(page, 'Mégse'), 'Mégse gomb (mobil)')
})
