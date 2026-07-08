import { expect, test, Page } from '@playwright/test'

/**
 * FK-022 — Iroda adatainak szerkesztése E2E (mockolt API-val, a rates.spec.ts mintájára).
 * Lefedi: lista → Szerkesztés → előtöltött form (FR-1), read-only kód (FR-3), happy path
 * mentés + visszanavigálás (FR-2/FR-6), státuszváltás megerősítő kérdés mindkét irányban
 * (FR-4/FR-5), "Nem" → nincs mentés, tartósan zárva → isActive=false (FR-11).
 */

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 1,
  workerCode: 'FOERT01',
  firstName: 'Fő',
  lastName: 'Értéktáros',
  fullName: 'Fő Értéktáros',
  role: 'ADMIN',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const BRANCH = {
  id: 'b-1',
  code: 'BR027',
  name: 'Szeged Tesco',
  shortName: 'Tesco',
  address: '6723 Szeged, Rókusi krt. 42.',
  zipCode: '6723',
  city: 'Szeged',
  phone: '06701112233',
  email: 'szeged@ebc.hu',
  bankCode: '210',
  region: 'SZEGED',
  isActive: true,
  isVault: false,
  hasAfa: true,
  hasWu: false,
  hasMg: false,
  hasPos: true,
  closedSaturday: false,
  closedSunday: false,
}

const REGIONS = [
  { id: 'r1', category: 'REGION', code: 'SZEGED', name: 'Szeged', nameHu: 'Szeged', sortOrder: 1 },
  { id: 'r2', category: 'REGION', code: 'PECS', name: 'Pécs', nameHu: 'Pécs', sortOrder: 2 },
]

type PutCapture = { body: Record<string, unknown> | null }

/**
 * Mockolt API + login. A PUT /branches/{id} body-ját a capture-be írja.
 * Copilot #1076: az API teljesen mockolt, így a login determinisztikus — hard assert,
 * nem graceful skip (a skip elrejtené a valódi regressziót).
 */
async function loginWithBranchMocks(
  page: Page,
  capture: PutCapture,
  branchOverride?: Partial<typeof BRANCH>,
  opts?: { admin403?: boolean },
): Promise<void> {
  const branch = { ...BRANCH, ...branchOverride }
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: [],
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
          permissions: [],
          roles: ['ADMIN'],
          roleSelectionRequired: false,
        }),
      })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(worker),
      })
    }

    if (path.endsWith('/dictionaries/REGION') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(REGIONS),
      })
    }

    if (path.endsWith(`/branches/${branch.id}`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(branch),
      })
    }

    if (path.endsWith(`/branches/${branch.id}/path`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([branch]),
      })
    }

    if (path.endsWith(`/branches/${branch.id}/children`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([]),
      })
    }

    if (path.endsWith(`/admin/branches/${branch.id}`) && method === 'GET') {
      // FK-038: a valos rendszerben ez ADMIN-only (CompanyAdminController @PreAuthorize hasRole('ADMIN')),
      // ezert foertektar/ugyvezeto felhasznalonak 403-at ad. A frontend best-effort hivja, a globalis
      // 403-toastot a _skipGlobal403Toast: true elnyomja — ezt validalja az FK-038 teszt.
      if (opts?.admin403) {
        return route.fulfill({
          status: 403,
          contentType: 'application/json',
          body: JSON.stringify({
            status: 403,
            error: 'FORBIDDEN',
            message: 'Nincs jogosultságod ehhez a művelethez.',
          }),
        })
      }
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: branch.id,
          code: branch.code,
          name: branch.name,
          active: branch.isActive,
          companyName: worker.companyName,
          workerCount: 3,
          totalInventoryHuf: 0,
          lastSyncAt: null,
          openingHours: 'H-P 09:00-17:00',
        }),
      })
    }

    if (path.endsWith(`/branches/${branch.id}`) && method === 'PUT') {
      capture.body = route.request().postDataJSON() as Record<string, unknown>
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ ...branch, ...capture.body }),
      })
    }

    if (path.endsWith('/branches') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([branch]),
      })
    }

    // Default: abort (az auth.spec.ts mintájára) — a nem mockolt végpont ne adjon hamis 200-at,
    // mert pl. a refresh-cookie "sikeres" szemét-válasza kizavarja az auth-flow-t.
    return route.abort()
  })

  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('FOERT01')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()

  await expect(page).toHaveURL(/\/central-workstation$/, { timeout: 15000 })
}

/**
 * Lista → Szerkesztés gomb → szerkesztő oldal. Kliens-oldali navigáció a menün át
 * (a page.goto teljes reload-ja elveszítené a memóriabeli auth-state-et → örök "Betöltés...").
 * Hard assertek: ha bármely lépés elakad, a teszt FAIL-el (nem skip).
 */
async function openEditPage(page: Page, opts?: { showInactive?: boolean }): Promise<void> {
  // FONTOS: isVisible() nem vár — waitFor kell, hogy a sidebar/lista kirenderelődjön.
  const menuLink = page.getByRole('link', { name: /Pénztár Törzs Adatbázis/ })
  await menuLink.waitFor({ state: 'visible', timeout: 15000 })
  await menuLink.click()
  await expect(page).toHaveURL(/\/admin\/branches$/, { timeout: 15000 })
  if (opts?.showInactive) {
    await page.getByRole('checkbox', { name: /Inaktívak is/ }).check()
  }
  const editButton = page.getByRole('button', { name: /Szerkesztés/ }).first()
  await editButton.waitFor({ state: 'visible', timeout: 15000 })
  await editButton.click()
  await expect(page).toHaveURL(/\/admin\/branches\/b-1\/edit$/, { timeout: 15000 })
}

test('FK-022 FR-1/FR-3: a szerkesztő form előtöltve nyílik, a kód read-only', async ({ page }) => {
  const capture: PutCapture = { body: null }
  await loginWithBranchMocks(page, capture)
  await openEditPage(page)

  await expect(page.getByText('1. Alapadatok')).toBeVisible()
  await expect(page.getByLabel(/Megjelenítendő név/)).toHaveValue('Szeged Tesco')
  await expect(page.getByLabel(/Pénztár pontos címe/)).toHaveValue('6723 Szeged, Rókusi krt. 42.')

  const codeInput = page.getByLabel(/Pénztár száma/)
  await expect(codeInput).toHaveValue('BR027')
  await expect(codeInput).toBeDisabled()
})

test('FK-022 FR-2/FR-6: mezőmódosítás + mentés → PUT payload + vissza a listára', async ({
  page,
}) => {
  const capture: PutCapture = { body: null }
  await loginWithBranchMocks(page, capture)
  await openEditPage(page)

  await page.getByLabel(/Megjelenítendő név/).fill('Szeged Belváros')
  await page.getByRole('checkbox', { name: /Western Union/ }).check()
  await page.getByRole('button', { name: /^Mentés/ }).click()

  await expect(page).toHaveURL(/\/admin\/branches$/, { timeout: 8000 })
  expect(capture.body).toMatchObject({ name: 'Szeged Belváros', hasWu: true, isActive: true })
  expect(capture.body).not.toHaveProperty('code')
})

test('FK-022 FR-4/FR-11: aktív → inaktív státuszváltás megerősítéssel, Igen → isActive=false', async ({
  page,
}) => {
  const capture: PutCapture = { body: null }
  await loginWithBranchMocks(page, capture)
  await openEditPage(page)

  await page.getByRole('checkbox', { name: /Tartósan zárva/ }).check()
  await page.getByRole('button', { name: /^Mentés/ }).click()

  await expect(page.getByText('Biztosan inaktívra állítja ezt az irodát?')).toBeVisible()
  expect(capture.body).toBeNull() // megerősítés ELŐTT nincs mentés

  await page.getByRole('button', { name: 'Igen' }).click()
  await expect(page).toHaveURL(/\/admin\/branches$/, { timeout: 8000 })
  expect(capture.body).toMatchObject({ isActive: false })
})

test('FK-022 FR-4: megerősítő kérdésnél "Nem" → nincs mentés, a form megmarad', async ({
  page,
}) => {
  const capture: PutCapture = { body: null }
  await loginWithBranchMocks(page, capture)
  await openEditPage(page)

  await page.getByRole('checkbox', { name: /Tartósan zárva/ }).check()
  await page.getByRole('button', { name: /^Mentés/ }).click()
  await expect(page.getByText('Biztosan inaktívra állítja ezt az irodát?')).toBeVisible()

  await page.getByRole('button', { name: 'Nem' }).click()
  await expect(page.getByText('Biztosan inaktívra állítja ezt az irodát?')).toBeHidden()
  await expect(page).toHaveURL(/\/admin\/branches\/b-1\/edit$/)
  expect(capture.body).toBeNull()
})

test('FK-022 FR-5: inaktív iroda visszaaktiválása megerősítéssel → isActive=true', async ({
  page,
}) => {
  const capture: PutCapture = { body: null }
  await loginWithBranchMocks(page, capture, { isActive: false })

  // Az inaktív iroda a lista alapszűrőjében nem látszik — az "Inaktívak is" szűrővel érjük el (FK-020).
  await openEditPage(page, { showInactive: true })

  // inaktív iroda → a "Tartósan zárva" előtöltve bepipálva
  await expect(page.getByRole('checkbox', { name: /Tartósan zárva/ })).toBeChecked()
  await page.getByRole('checkbox', { name: /Tartósan zárva/ }).uncheck()
  await page.getByRole('button', { name: /^Mentés/ }).click()

  await expect(page.getByText('Biztosan aktívra állítja ezt az irodát?')).toBeVisible()
  await page.getByRole('button', { name: 'Igen' }).click()
  await expect(page).toHaveURL(/\/admin\/branches$/, { timeout: 8000 })
  expect(capture.body).toMatchObject({ isActive: true })
})

test('FK-038: /admin/branches 403 → NINCS "Hozzáférés megtagadva" toast, a form betölt (1920×1080)', async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 1920, height: 1080 })
  const capture: PutCapture = { body: null }
  await loginWithBranchMocks(page, capture, undefined, { admin403: true })

  // A betöltéskori best-effort GET /admin/branches/{id} 403-at kap (admin403 mock = a valós
  // foertektar-helyzet, mert a végpont ADMIN-only). A form a /branches/{id} 200-ból töltődik;
  // ha a fix nem lenne, a globális interceptor "Hozzáférés megtagadva" toastot dobna.
  await openEditPage(page)

  // A form betöltődik — a 403-at a betöltő Promise.all .catch-e elnyeli, a form NEM bukik el.
  await expect(page.getByText('1. Alapadatok')).toBeVisible()
  await expect(page.getByLabel(/Megjelenítendő név/)).toHaveValue('Szeged Tesco')

  // A FIX lényege: a globális 403-toast NEM jelenik meg (a _skipGlobal403Toast: true miatt).
  await expect(page.getByText(/Hozzáférés megtagadva/i)).toHaveCount(0)
  await expect(page.getByText(/Nincs jogosultság/i)).toHaveCount(0)

  // Teljes képernyős render-épség: nincs váratlan vízszintes scrollbar / viewport overflow.
  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)

  // Vizuális bizonyíték a report-hoz — testInfo.attach: egyedi név, parallel/retry-biztos (Copilot review).
  await testInfo.attach('fk038-branch-edit-403-no-toast', {
    body: await page.screenshot({ fullPage: true }),
    contentType: 'image/png',
  })
})
