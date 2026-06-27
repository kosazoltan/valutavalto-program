import { expect, test, type Page } from '@playwright/test'

// FK-041/II — RateWatcherGuard route-szintű izoláció VALÓS Chromium-renderrel.
// Követelmény: az „árfolyam néző" CSAK a versenytárs-árfolyam beíró oldalt érheti el; belső
// árfolyam/készlet/értéktár/irányítóközpont oldalakat URL-beírással SEM (a guard a /competitor-rates-re
// irányít). Multirole (pl. főértéktár+néző) usert viszont NEM zár — megtartja a teljes hozzáférését.

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

type Role = 'arfolyam_nezo' | 'foertektar' | 'penztar'

const WORKER_META: Record<Role, { code: string; first: string; last: string }> = {
  arfolyam_nezo: { code: 'ARFNEZO1', first: 'Árfolyam', last: 'Néző' },
  foertektar: { code: 'FOERT1', first: 'Fő', last: 'Értéktáros' },
  penztar: { code: 'PENZ1', first: 'Pénz', last: 'Táros' },
}

function makeWorker(role: Role, roles: Role[]) {
  const meta = WORKER_META[role]
  return {
    id: 11,
    workerCode: meta.code,
    firstName: meta.first,
    lastName: meta.last,
    fullName: `${meta.first} ${meta.last}`,
    role,
    branchId: 'branch-szeged',
    branchCode: 'BR-SZEGED',
    branchName: 'Szeged',
    companyId: 'company-1',
    companyCode: 'EBC',
    companyName: 'Exclusive Best Change',
    roles,
  }
}

const BOOTSTRAP = {
  competitors: [
    { id: 'comp-1', name: 'Korona Váltó', branchName: 'Szeged' },
    { id: 'comp-2', name: 'Tisza Exchange', branchName: 'Szeged' },
  ],
  currencies: [
    { id: 2, code: 'EUR', name: 'Euró' },
    { id: 3, code: 'USD', name: 'US dollár' },
    { id: 5, code: 'CHF', name: 'Svájci frank' },
    { id: 6, code: 'GBP', name: 'Angol font' },
  ],
}

async function mockApis(page: Page, activeRole: Role, roles: Role[]) {
  const worker = makeWorker(activeRole, roles)
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole,
    permissions: ['READ'],
    roles,
  })
  await page.route('**/api/v1/**', async (route) => {
    const path = new URL(route.request().url()).pathname
    const method = route.request().method()
    const json = (body: unknown) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(body) })

    if (path.endsWith('/auth/login') && method === 'POST') {
      return json({
        token,
        tokenType: 'Bearer',
        expiresAt: new Date(Date.now() + 3600_000).toISOString(),
        worker,
        activeRole,
        permissions: ['READ'],
        roles,
        roleSelectionRequired: false,
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') return json({ token })
    if (path.endsWith('/workers/me')) return json(worker)
    if (path.endsWith('/competitor-rates/bootstrap')) return json(BOOTSTRAP)
    if (path.endsWith('/competitor-rates/today')) return json([])
    return json([])
  })
}

async function login(page: Page, workerCode: string) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill(workerCode)
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await page.waitForURL((url) => !url.pathname.endsWith('/login'))
}

// A néző belső route-jai, amelyekről a guardnak a beíró oldalra kell irányítania.
const INTERNAL_ROUTES = [
  '/rates',
  '/treasury',
  '/inventory',
  '/cashier-stocks',
  '/central-workstation',
  '/dashboard',
  '/foertektar',
]

test('FK-041/II: az árfolyam néző CSAK a versenytárs-beíró oldalt éri el (RateWatcherGuard)', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 900 })
  await mockApis(page, 'arfolyam_nezo', ['arfolyam_nezo'])
  page.on('dialog', (dialog) => void dialog.accept())

  await login(page, 'ARFNEZO1')
  // Belépés után közvetlenül a beíró oldalra landol; a tartalom rendereltségét megvárjuk.
  await expect(page).toHaveURL(/\/competitor-rates$/)
  await expect(page.getByTestId('competitor-rate-entry')).toBeVisible()
  await expect(page.getByTestId('competitor-select')).toBeVisible()
  await page.screenshot({
    path: 'test-results/fk041-rate-watcher-only-view.png',
    fullPage: false,
  })

  // URL-beírás minden belső oldalra → a guard visszairányít a beíró oldalra (defense-in-depth).
  for (const route of INTERNAL_ROUTES) {
    await page.goto(route, { waitUntil: 'domcontentloaded' })
    await expect(page, `"${route}" URL-beírás NE töltse be a belső oldalt`).toHaveURL(
      /\/competitor-rates$/,
    )
    await expect(
      page.getByTestId('competitor-rate-entry'),
      `"${route}" után a beíró oldal renderelődik`,
    ).toBeVisible()
  }
  // A "/" landing is a beíró oldalra visz (nem üres irányítóközpontra).
  await page.goto('/', { waitUntil: 'domcontentloaded' })
  await expect(page).toHaveURL(/\/competitor-rates$/)
  await expect(page.getByTestId('competitor-rate-entry')).toBeVisible()
})

test('FK-041/II: a főértéktár+néző multirole user NINCS bezárva a beíró oldalra', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 900 })
  await mockApis(page, 'foertektar', ['foertektar', 'arfolyam_nezo'])
  page.on('dialog', (dialog) => void dialog.accept())

  await login(page, 'FOERT1')
  // Belső árfolyam-oldal elérhető marad (NEM redirectel a beíró oldalra).
  await page.goto('/rates', { waitUntil: 'domcontentloaded' })
  await expect(page).not.toHaveURL(/\/competitor-rates$/)
  await expect(page).toHaveURL(/\/rates$/)
  // Megvárjuk, hogy a lazy route Suspense fallback ("Oldal betöltése...") eltűnjön és a tartalom renderelődjön.
  await expect(page.getByText('Oldal betöltése...')).toHaveCount(0)
  await expect(page.getByRole('navigation')).toBeVisible()

  await page.screenshot({
    path: 'test-results/fk041-multirole-foertektar-rates.png',
    fullPage: false,
  })
})

test('FK-041/II hardening: penztáros+néző multirole FULL (Szerver) módban is a beíró oldalra záródik', async ({
  page,
}) => {
  await page.setViewportSize({ width: 1280, height: 900 })
  // roles=['penztar','arfolyam_nezo']; full módban a penztar NEM használható (isRoleSelectableForAppMode
  // ===false), így effektíve csak néző — a guardnak ZÁRNIA kell. (A bug elŐtt a penztar precedenciája
  // /cashier-re oldott, és a néző URL-beírással elérte a belső felügyeleti shellt.)
  await mockApis(page, 'arfolyam_nezo', ['penztar', 'arfolyam_nezo'])
  page.on('dialog', (dialog) => void dialog.accept())

  await login(page, 'ARFNEZO1')
  await expect(page).toHaveURL(/\/competitor-rates$/)

  // Belső felügyeleti + lokál route-ok URL-beírással → mind a beíró oldalra irányul.
  for (const route of ['/central-workstation', '/foertektar', '/cashier', '/rates', '/']) {
    await page.goto(route, { waitUntil: 'domcontentloaded' })
    await expect(page, `"${route}" full módban a néző-zárnak érvényesülnie kell`).toHaveURL(
      /\/competitor-rates$/,
    )
  }
})
