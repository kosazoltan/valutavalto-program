import { expect, test, type Page } from '@playwright/test'

// ─────────────────────────────────────────────────────────────────────────────
// FKH-026 — Menürendszer egyszerűsítése (RED-fázis E2E, 2026-07-30;
// v3-ra frissítve a 2. körben — dokumentált spec-változás).
//
// A tesztek az ELVÁRT (még nem implementált) viselkedést rögzítik:
//  - FR-1/FR-3/FR-5/FR-6: az érintett menüpontok hiánya az oldalsávban a
//    Pénztáros/Értéktáros (és helyettesük) szerepkörnél (most RED),
//  - FR-2 + NFR-1: a nem érintett menüpontok jelenléte (regresszió-őr, most is zöld),
//  - v3 foertektar-kivétel: Főértéktáros(-helyettes) esetén MIND a 4 menüpont ÉS a
//    TransitBadge változatlanul látszik (őr, ma is zöld — a badge ma mindenkinek
//    megjelenik, mert nincs rajta role-feltétel),
//  - FR-7: a fejléc-gomb felirata "+ Új átadás" (v3: csak felirat-módosítás, a gomb
//    már létezik — PR #274; a teszt ma a felirat-eltérésen bukik → RED),
//  - FR-8: kattintásra /transfers/new töltődik + vissza-gomb (regresszió-őr),
//  - FR-9: a menüből eltávolított oldalak közvetlen URL-en TOVÁBBRA IS betöltenek
//    (POZITÍV teszt — a jelenlegi kódon is zöld, a GREEN-fázis után is zöldnek
//    KELL maradnia).
//
// Minta: cashier-stocks-mode.spec.ts — mockolt backend (page.route), böngészős
// lokál-mód a vv_session_app_mode session-override-dal (useAppMode elsőbbséggel olvassa).
// ─────────────────────────────────────────────────────────────────────────────

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

function makeWorker(role: string, workerCode: string, fullName: string) {
  return {
    id: 42,
    workerCode,
    firstName: fullName.split(' ')[1] ?? fullName,
    lastName: fullName.split(' ')[0] ?? fullName,
    fullName,
    role,
    branchId: 'branch-szeged-vault',
    branchCode: 'BR-SZEGED-V',
    branchName: 'Szeged Értéktár',
    companyId: 'company-1',
    companyCode: 'EBC',
    companyName: 'Exclusive Best Change',
  }
}

async function mockApis(
  page: Page,
  role: string,
  worker: ReturnType<typeof makeWorker>,
  transitItems: unknown[] = [],
) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: role,
    permissions: ['READ'],
    roles: [role],
  })
  await page.route('**/api/v1/**', async (route) => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const method = route.request().method()
    const json = (body: unknown) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(body) })

    if (path.endsWith('/auth/login') && method === 'POST') {
      return json({
        token,
        tokenType: 'Bearer',
        expiresAt: new Date(Date.now() + 3600_000).toISOString(),
        worker,
        activeRole: role,
        permissions: ['READ'],
        roles: [role],
        roleSelectionRequired: false,
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') return json({ token })
    if (path.endsWith('/workers/me') && method === 'GET') return json(worker)
    // penztar módban a MainLayout napi session-gate-je fut — nyitott sessiont mockolunk
    if (path.endsWith('/daily-sessions/is-open')) return json(true)
    if (path.endsWith('/daily-sessions/current')) {
      return json({ id: 'session-1', openedAt: new Date().toISOString() })
    }
    // TransitBadge poll (v3 foertektar-őr teszthez: ≥1 tétellel a badge látszik)
    if (path.endsWith('/transit/incoming')) return json(transitItems)
    return json([])
  })
}

/**
 * Lokál mód beállítása MÉG A LOGIN ELŐTT: böngészőben a useAppMode alapból 'full'-t
 * ad, a full-módú LoginPage pedig elutasítja a lokál (penztar/ertektar) szerepkört
 * ("Hozzáférés megtagadva... a lokál alkalmazást használják"). Az addInitScript a
 * page-szkriptek előtt fut minden navigációnál, így a LoginPage már lokál módban
 * validál, és a belépés a lokál default route-ra fut be.
 */
async function forceLocalAppMode(page: Page, mode: 'penztar' | 'ertektar') {
  await page.addInitScript((m) => sessionStorage.setItem('vv_session_app_mode', m), mode)
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

/** Az oldalsáv navigációja (MainLayout <nav>). */
function sidebar(page: Page) {
  return page.getByRole('navigation')
}

test.describe('FKH-026 — Értéktáros oldalsáv (FR-1, FR-3, FR-5, FR-6 + NFR-1)', () => {
  test('ertektar módban a 4 érintett menüpont HIÁNYZIK, a nem érintettek megvannak', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1920, height: 1080 })
    const worker = makeWorker('ertektar', 'ERT01', 'Értéktáros Emma')
    await mockApis(page, 'ertektar', worker)
    await forceLocalAppMode(page, 'ertektar')
    await login(page, 'ERT01')

    await page.goto('/treasury', { waitUntil: 'domcontentloaded' })

    const nav = sidebar(page)
    // Horgony: az oldalsáv ténylegesen betöltött (nem érintett menüpont).
    await expect(nav.getByRole('link', { name: 'Értéktári dashboard' })).toBeVisible()

    // FR-1: Irodaközi trade NEM szerepel az Értéktár-módú menüben.
    await expect(nav.getByRole('link', { name: 'Irodaközi trade' })).toHaveCount(0)
    // FR-3: Úton lévő csomagok NEM szerepel.
    await expect(nav.getByRole('link', { name: 'Úton lévő csomagok' })).toHaveCount(0)
    // FR-5: Szállítólevelek NEM szerepel.
    await expect(nav.getByRole('link', { name: 'Szállítólevelek' })).toHaveCount(0)
    // FR-6: Új átadás-átvétel rögzítése önálló menüpontként NEM szerepel.
    await expect(nav.getByRole('link', { name: 'Új átadás-átvétel rögzítése' })).toHaveCount(0)

    // NFR-1: a nem érintett menüpontok változatlanul jelen vannak.
    for (const label of [
      'Átadás-átvétel',
      'Átadás-átvétel visszaigazolás (aláírás)',
      'Értéktári készlet',
      'Pénztári készletek',
      'Új pénztár felrögzítése',
      'Új munkatárs felvétele',
      'Naplókönyv',
      'Napi zárás',
      // FKH-036 FR-9: 'Napzárás' a Pénztári zárás-varázsló Értéktár-módban rejtett
      // (hidden: true); láthatósági assert alább, a rejtett halmazban.
      'Havi zárás',
      'Ügyfelek',
      'Árfolyamok (nézet)',
    ]) {
      await expect(nav.getByRole('link', { name: label, exact: true })).toBeVisible()
    }

    // FKH-036 FR-9: a pénztári Napzárás-varázsló menüpontja Értéktár-módban NEM látszik
    // (a route /closing/wizard és a ClosingWizardPage változatlan — FR-10).
    await expect(nav.getByRole('link', { name: 'Napzárás', exact: true })).toHaveCount(0)
  })
})

test.describe('FKH-026 — Pénztáros oldalsáv (FR-2, FR-3, FR-6 + NFR-1)', () => {
  test('penztar módban az Irodaközi trade MEGVAN, a transit és a transfers/new menüpont HIÁNYZIK', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1920, height: 1080 })
    const worker = makeWorker('penztar', 'PENZ01', 'Pénztáros Petra')
    await mockApis(page, 'penztar', worker)
    await forceLocalAppMode(page, 'penztar')
    await login(page, 'PENZ01')

    await page.goto('/cashier', { waitUntil: 'domcontentloaded' })

    const nav = sidebar(page)
    await expect(nav.getByRole('link', { name: 'Pénztáros főmenü' })).toBeVisible()

    // FR-2: az Irodaközi trade a Pénztár-módú menüben VÁLTOZATLANUL megjelenik.
    await expect(nav.getByRole('link', { name: 'Irodaközi trade' })).toBeVisible()
    // FR-3: Úton lévő csomagok NEM szerepel.
    await expect(nav.getByRole('link', { name: 'Úton lévő csomagok' })).toHaveCount(0)
    // FR-6: Új átadás-átvétel rögzítése önálló menüpontként NEM szerepel.
    await expect(nav.getByRole('link', { name: 'Új átadás-átvétel rögzítése' })).toHaveCount(0)

    // NFR-1 (szúrópróba): nem érintett pénztári menüpontok jelen vannak.
    for (const label of [
      'Napnyitás',
      'Valuta vétel / eladás',
      'Kassza / készlet',
      'Átadás-átvétel visszaigazolás (aláírás)',
      'Napzárás',
      'Tranzakciólista',
    ]) {
      await expect(nav.getByRole('link', { name: label, exact: true })).toBeVisible()
    }
  })
})

test.describe('FKH-026 — FR-9: közvetlen URL-elérés menüpont nélkül (POZITÍV, szándékosan nem blokkolt)', () => {
  test('ertektar módban a /trades, /transit, /transfer-documents közvetlen URL-en betölt', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1920, height: 1080 })
    const worker = makeWorker('ertektar', 'ERT01', 'Értéktáros Emma')
    await mockApis(page, 'ertektar', worker)
    await forceLocalAppMode(page, 'ertektar')
    await login(page, 'ERT01')

    // FR-9: a menüből való eltávolítás NEM jelent hozzáférés-megvonást — a meglévő
    // jogosultsági szabályok szerint az oldalak URL-ről továbbra is betöltenek.
    await page.goto('/trades', { waitUntil: 'domcontentloaded' })
    await expect(page).toHaveURL(/\/trades$/)
    await expect(page.getByRole('heading', { name: 'Irodaközi trade' })).toBeVisible()

    await page.goto('/transit', { waitUntil: 'domcontentloaded' })
    await expect(page).toHaveURL(/\/transit$/)
    await expect(page.getByRole('heading', { name: 'Úton lévő csomagok' })).toBeVisible()

    await page.goto('/transfer-documents', { waitUntil: 'domcontentloaded' })
    await expect(page).toHaveURL(/\/transfer-documents$/)
    await expect(page.getByRole('heading', { name: 'Átutalási bizonylatok' })).toBeVisible()
  })
})

test.describe('FKH-026 v3 — FR-7/FR-8: "+ Új átadás" gomb-flow a /transfers oldalon', () => {
  // FR-7 ma RED: a gomb felirata még "Új átadás" (a "+ " prefix hiányzik), ezért a
  // pontos-feliratú locator nem talál. FR-8 (navigáció + vissza-gomb) a felirat
  // átvezetése után ugyanebben a flow-ban bizonyít.
  test('értéktáros: a gomb felirata "+ Új átadás", kattintásra /transfers/new tölt, vissza-gombbal /transfers', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1920, height: 1080 })
    const worker = makeWorker('ertektar', 'ERT01', 'Értéktáros Emma')
    await mockApis(page, 'ertektar', worker)
    await forceLocalAppMode(page, 'ertektar')
    await login(page, 'ERT01')

    await page.goto('/transfers', { waitUntil: 'domcontentloaded' })
    await expect(page.getByRole('heading', { name: /Átadás-átvétel visszaigazolás/ })).toBeVisible()

    // FR-7: pontos felirat-pin (exact) — ma "Új átadás", ezért RED.
    const newTransferButton = page.getByRole('link', { name: '+ Új átadás', exact: true })
    await expect(newTransferButton).toBeVisible()

    // FR-8 (regresszió-őr): kattintás → a meglévő létrehozó űrlap töltődik be.
    await newTransferButton.click()
    await expect(page).toHaveURL(/\/transfers\/new$/)
    await expect(page.getByRole('heading', { name: 'Új átadás-átvétel rögzítése' })).toBeVisible()

    // Edge case (FK v3 §9.2): böngésző vissza-gomb → visszatér a /transfers listára.
    await page.goBack()
    await expect(page).toHaveURL(/\/transfers$/)
    await expect(page.getByRole('heading', { name: /Átadás-átvétel visszaigazolás/ })).toBeVisible()
  })

  test('pénztáros: a "+ Új átadás" gomb ugyanígy működik', async ({ page }) => {
    await page.setViewportSize({ width: 1920, height: 1080 })
    const worker = makeWorker('penztar', 'PENZ01', 'Pénztáros Petra')
    await mockApis(page, 'penztar', worker)
    await forceLocalAppMode(page, 'penztar')
    await login(page, 'PENZ01')

    await page.goto('/transfers', { waitUntil: 'domcontentloaded' })
    const newTransferButton = page.getByRole('link', { name: '+ Új átadás', exact: true })
    await expect(newTransferButton).toBeVisible()
    await newTransferButton.click()
    await expect(page).toHaveURL(/\/transfers\/new$/)
    await expect(page.getByRole('heading', { name: 'Új átadás-átvétel rögzítése' })).toBeVisible()
  })
})

test.describe('FKH-026 v3 — Főértéktáros kivétel (őr, ma is zöld): menüpontok + TransitBadge változatlanul', () => {
  // A SZERVER_ROLES bypass (menuVisibility.ts:50) szándékosan marad (FK v3 §3/§8);
  // a badge ma role-feltétel nélkül, mindenkinek megjelenik — ezek az őr-tesztek a
  // GREEN-fázis után is zöldek KELL maradjanak (kizárják a naiv teljes-törlést és
  // a badge univerzális eltávolítását).
  test('foertektar ertektar módban: mind a 4 érintett menüpont látszik + badge a darabszámmal', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1920, height: 1080 })
    const worker = makeWorker('foertektar', 'FOERT1', 'Fő Értéktáros')
    await mockApis(page, 'foertektar', worker, [{ id: 'tr-1' }, { id: 'tr-2' }])
    await forceLocalAppMode(page, 'ertektar')
    await login(page, 'FOERT1')

    await page.goto('/treasury', { waitUntil: 'domcontentloaded' })

    const nav = sidebar(page)
    await expect(nav.getByRole('link', { name: 'Értéktári dashboard' })).toBeVisible()
    await expect(nav.getByRole('link', { name: 'Irodaközi trade' })).toBeVisible()
    await expect(nav.getByRole('link', { name: 'Úton lévő csomagok' })).toBeVisible()
    await expect(nav.getByRole('link', { name: 'Szállítólevelek' })).toBeVisible()
    await expect(nav.getByRole('link', { name: 'Új átadás-átvétel rögzítése' })).toBeVisible()

    // TransitBadge a fejlécen, tényleges darabszámmal (2 mockolt tétel).
    await expect(page.getByTitle(/Úton lévő csomagok: 2 db/)).toBeVisible()
  })

  test('foertektar penztar módban: az érintett menüpontok látszanak + badge a darabszámmal', async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1920, height: 1080 })
    const worker = makeWorker('foertektar', 'FOERT1', 'Fő Értéktáros')
    await mockApis(page, 'foertektar', worker, [{ id: 'tr-1' }, { id: 'tr-2' }])
    await forceLocalAppMode(page, 'penztar')
    await login(page, 'FOERT1')

    await page.goto('/cashier', { waitUntil: 'domcontentloaded' })

    const nav = sidebar(page)
    await expect(nav.getByRole('link', { name: 'Pénztáros főmenü' })).toBeVisible()
    await expect(nav.getByRole('link', { name: 'Irodaközi trade' })).toBeVisible()
    await expect(nav.getByRole('link', { name: 'Úton lévő csomagok' })).toBeVisible()
    await expect(nav.getByRole('link', { name: 'Új átadás-átvétel rögzítése' })).toBeVisible()
    // "Szállítólevelek" penztar módban eddig sem volt (FK §3) — mód-szűrés, nem bypass.
    await expect(nav.getByRole('link', { name: 'Szállítólevelek' })).toHaveCount(0)

    await expect(page.getByTitle(/Úton lévő csomagok: 2 db/)).toBeVisible()
  })
})
