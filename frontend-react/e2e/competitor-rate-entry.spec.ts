import { expect, test, type Page } from '@playwright/test'

// FK-041/II — versenytárs-árfolyam BEVITEL (árfolyam néző) valós Chromium render-ellenőrzés.
// Az `arfolyam_nezo` szerepkör Szerver (full) módban ÉRVÉNYES (SERVER_ALLOWED_CANONICAL_ROLES), ezért
// a böngészőben közvetlenül beléphet. Ellenőrizzük: (1) a beíró oldal renderel + beküld; (2) a belső
// /rates-ről a guard átirányít a dedikált beíró oldalra (külön szkóp, nem látja a belső árfolyamokat).

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 88,
  workerCode: 'NEZO1',
  firstName: 'Árfolyam',
  lastName: 'Néző',
  fullName: 'Árfolyam Néző',
  role: 'arfolyam_nezo',
  branchId: 'branch-szeged',
  branchCode: 'BR-SZEGED',
  branchName: 'Tisza Sarok',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const bootstrap = {
  competitors: [{ id: 'c1', name: 'Rivál Change', branchName: 'Tisza Sarok' }],
  currencies: [
    { id: 1, code: 'EUR', name: 'Euró' },
    { id: 2, code: 'USD', name: 'US dollár' },
  ],
}

const submitted: Array<Record<string, unknown>> = []

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'arfolyam_nezo',
    permissions: ['READ'],
    roles: ['arfolyam_nezo'],
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
          activeRole: 'arfolyam_nezo',
          permissions: ['READ'],
          roles: ['arfolyam_nezo'],
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
    if (path.endsWith('/competitor-rates/bootstrap') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(bootstrap),
      })
    }
    if (path.endsWith('/competitor-rates/today') && method === 'GET') {
      // competitorId-függő: c1-re a MAI EUR-előtöltés, máskülönben üres.
      const competitorId = url.searchParams.get('competitorId')
      const body =
        competitorId === 'c1'
          ? [{ currencyId: 1, currencyCode: 'EUR', buyRate: 388, sellRate: 402 }]
          : []
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(body),
      })
    }
    if (path.endsWith('/competitor-rates') && method === 'POST') {
      submitted.push(route.request().postDataJSON())
      return route.fulfill({ status: 201, contentType: 'application/json', body: '' })
    }
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) })
  })
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('NEZO1')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await page.waitForURL((url) => !url.pathname.endsWith('/login'))
}

test('FK-041/II: árfolyam néző beviszi a versenytárs-árfolyamot (Chromium)', async ({ page }) => {
  await page.setViewportSize({ width: 414, height: 896 }) // mobil-méret (PWA)
  submitted.length = 0
  await mockApis(page)
  page.on('dialog', (dialog) => void dialog.accept())
  await login(page)

  // FK-041/II login-redirect: belépés után AUTOMATIKUSAN a beíró oldalra landol (nincs explicit goto).
  await expect(page).toHaveURL(/\/competitor-rates$/)
  await expect(page.getByTestId('competitor-rate-entry')).toBeVisible()
  await page.getByTestId('competitor-select').selectOption('c1')

  // Előtöltés: a c1 MAI EUR vételi árfolyama (388) megjelenik a mezőben — várjuk be a fill előtt.
  await expect(page.getByTestId('buy-EUR')).toHaveValue('388')

  await page.getByTestId('buy-EUR').fill('390')
  await page.getByTestId('sell-EUR').fill('400')
  await page.getByTestId('submit-competitor-rates').click()

  await expect.poll(() => submitted.length).toBeGreaterThan(0)
  expect(submitted[0]).toEqual({
    competitorId: 'c1',
    rates: [{ currencyId: 1, buyRate: 390, sellRate: 400 }],
  })

  // A „Telepítés a telefonra" segéd (URL + QR + lépések) megnyitása a vizuális bizonyítékhoz.
  await page.getByTestId('pwa-install-toggle').click()
  await expect(page.getByTestId('pwa-install-qr')).toBeVisible()
  await page.screenshot({ path: 'test-results/fk041-competitor-entry.png', fullPage: true })
})

test('FK-041/II: az árfolyam néző a /rates-ről a beíró oldalra irányít (nem lát belső árfolyamot)', async ({
  page,
}) => {
  await mockApis(page)
  page.on('dialog', (dialog) => void dialog.accept())
  await login(page)

  await page.goto('/rates', { waitUntil: 'domcontentloaded' })
  await expect(page).toHaveURL(/\/competitor-rates$/)
  await expect(page.getByTestId('competitor-rate-entry')).toBeVisible()

  // A belső árfolyam-történet direkt URL-lel sem érhető el (MenuRoleGate → elnavigál).
  await page.goto('/rates/history', { waitUntil: 'domcontentloaded' })
  await expect(page).not.toHaveURL(/\/rates\/history$/)
})
