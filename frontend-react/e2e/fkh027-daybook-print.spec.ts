import { expect, test, type Page } from '@playwright/test'

// ─────────────────────────────────────────────────────────────────────────────
// FKH-027 — Naplókönyv nyomtatási kép (e2e, 2026-08-02)
//
// A 9.3/3. pipeline-pont három kötelező fedése:
//  1) FR-6: a "Nyomtatás" gomb létezik és window.print()-et hív,
//  2) FR-7: nyomtatási médiában (Ctrl+P megfelelője, emulateMedia 'print') az
//     oldalsáv, a dátumválasztó, a "Lekérdezés" és a "Nyomtatás" gomb ELTŰNIK,
//     miközben a cégfejléc / dobozok / aláírás-sor LÁTHATÓ MARAD,
//  3) FR-10: a sztornózott tétel félkövér, SZÍN NÉLKÜLI "SZTORNÓ" felirattal és
//     teljes (nem csonkolt) bizonylatszámmal jelenik meg — képernyőn és nyomtatásban is.
//
// Minta: fkh026-menu-simplification.spec.ts — mockolt backend (page.route),
// lokál ertektar-mód a vv_session_app_mode session-override-dal.
// ─────────────────────────────────────────────────────────────────────────────

/** 18 karakternél hosszabb bizonylatszám — a PDFBox-os truncate(…, 18) csapdája. */
const LONG_STORNO_RECEIPT = 'UF-2026-000000101-SZ'

const DAYBOOK_RESPONSE = {
  branchId: 'branch-szeged-vault',
  branchName: 'Szeged Értéktár',
  branchAddress: '6720 Szeged, Kárász utca 1.',
  date: '2026-07-01',
  rows: [
    {
      annualSequence: 2,
      receiptNumber: 'FF-000002',
      partnerCode: '076',
      timestamp: '09:15:00',
      atadasHuf: 250000,
      storno: false,
    },
    {
      annualSequence: 3,
      receiptNumber: 'UF-2026-000000101',
      partnerCode: 'PRB',
      timestamp: '10:30:00',
      atvetelHuf: 100000,
      storno: false,
    },
    {
      annualSequence: 4,
      receiptNumber: LONG_STORNO_RECEIPT,
      partnerCode: 'PRB',
      timestamp: '11:00:00',
      atvetelHuf: -100000,
      storno: true,
    },
  ],
  totalAtadasHuf: 250000,
  totalAtvetelHuf: 0,
  openingBalanceHuf: 1500000,
  closingBalanceHuf: 1250000,
}

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const WORKER = {
  id: 42,
  workerCode: 'ERT01',
  firstName: 'Emma',
  lastName: 'Értéktáros',
  fullName: 'Értéktáros Emma',
  role: 'ertektar',
  branchId: 'branch-szeged-vault',
  branchCode: 'BR-SZEGED-V',
  branchName: 'Szeged Értéktár',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

async function mockApis(page: Page) {
  const role = 'ertektar'
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
        worker: WORKER,
        activeRole: role,
        permissions: ['READ'],
        roles: [role],
        roleSelectionRequired: false,
      })
    }
    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') return json({ token })
    if (path.endsWith('/workers/me') && method === 'GET') return json(WORKER)
    if (path.endsWith('/daily-sessions/is-open')) return json(true)
    if (path.endsWith('/daily-sessions/current')) {
      return json({ id: 'session-1', openedAt: new Date().toISOString() })
    }
    if (path.includes('/daybook/')) return json(DAYBOOK_RESPONSE)
    return json([])
  })
}

/** A `window.print()` hívások számlálása — a natív nyomtatás-dialógus blokkolna. */
async function stubPrint(page: Page) {
  await page.addInitScript(() => {
    const w = window as unknown as { __printCalls: number }
    w.__printCalls = 0
    window.print = () => {
      w.__printCalls += 1
    }
  })
}

async function printCalls(page: Page) {
  return page.evaluate(() => (window as unknown as { __printCalls: number }).__printCalls)
}

async function loginAndOpenDaybook(page: Page) {
  await page.setViewportSize({ width: 1920, height: 1080 })
  await stubPrint(page)
  await mockApis(page)
  await page.addInitScript(() => sessionStorage.setItem('vv_session_app_mode', 'ertektar'))

  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('ERT01')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await page.waitForURL((url) => !url.pathname.endsWith('/login'))

  await page.goto('/daybook', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: 'Lekérdezés' }).click()
  await expect(page.getByTestId('daybook-print-header')).toBeVisible()
}

test.describe('FKH-027 — Naplókönyv nyomtatási kép', () => {
  test('FR-1..FR-6: cégfejléc, Nyitó/Forgalom/Záró dobozok, aláírás-sor és működő "Nyomtatás" gomb', async ({
    page,
  }) => {
    await loginAndOpenDaybook(page)

    // FR-4: cégfejléc.
    const header = page.getByTestId('daybook-print-header')
    await expect(header).toContainText('Exclusive Best Change Zrt.')
    await expect(header).toContainText('Szeged Értéktár')
    await expect(header).toContainText('6720 Szeged, Kárász utca 1.')
    await expect(header).toContainText('2026-07-01')

    // FR-1/2/3: összegző dobozok.
    await expect(page.getByTestId('daybook-opening-balance')).toContainText('Nyitó egyenleg')
    await expect(page.getByTestId('daybook-total-atadas')).toContainText('Átadás összesen')
    await expect(page.getByTestId('daybook-total-atvetel')).toContainText('Átvétel összesen')
    await expect(page.getByTestId('daybook-closing-balance')).toContainText('Záró egyenleg')

    // FR-5: aláírás-sor.
    const signatures = page.getByTestId('daybook-signatures')
    await expect(signatures).toContainText('Pénztáros aláírása')
    await expect(signatures).toContainText('Ellenőrző aláírása')

    // FR-6: a gomb a böngésző natív nyomtatását indítja.
    expect(await printCalls(page)).toBe(0)
    await page.getByRole('button', { name: 'Nyomtatás' }).click()
    expect(await printCalls(page)).toBe(1)
  })

  test('FR-7: nyomtatási médiában eltűnik az oldalsáv, a dátumválasztó és a gombok, a nyomtatvány marad', async ({
    page,
  }) => {
    await loginAndOpenDaybook(page)

    // Képernyőn minden vezérlő látszik.
    await expect(page.locator('aside')).toBeVisible()
    await expect(page.locator('input[type="date"]')).toBeVisible()
    await expect(page.getByRole('button', { name: 'Lekérdezés' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Nyomtatás' })).toBeVisible()

    // Ctrl+P megfelelője: a böngésző nyomtatási stíluslapja aktiválódik.
    await page.emulateMedia({ media: 'print' })

    await expect(page.locator('aside')).toBeHidden()
    await expect(page.locator('input[type="date"]')).toBeHidden()
    await expect(page.getByRole('button', { name: 'Lekérdezés' })).toBeHidden()
    await expect(page.getByRole('button', { name: 'Nyomtatás' })).toBeHidden()

    // A nyomtatvány tartalma viszont MARAD.
    await expect(page.getByTestId('daybook-print-header')).toBeVisible()
    await expect(page.getByTestId('daybook-opening-balance')).toBeVisible()
    await expect(page.getByTestId('daybook-total-atadas')).toBeVisible()
    await expect(page.getByTestId('daybook-closing-balance')).toBeVisible()
    await expect(page.getByTestId('daybook-signatures')).toBeVisible()

    // Nyomtatási elrendezés: nincs vízszintes túlcsordulás (levágott tartalom).
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
    )
    expect(overflow).toBeLessThanOrEqual(0)

    await page.emulateMedia({ media: 'screen' })
  })

  test('FR-10: sztornó-tétel félkövér, szín nélküli "SZTORNÓ" jelöléssel és teljes bizonylatszámmal', async ({
    page,
  }) => {
    await loginAndOpenDaybook(page)

    const badge = page.getByTestId('daybook-storno-badge')
    await expect(badge).toHaveText('SZTORNÓ')
    await expect(badge).toHaveCount(1)

    // Félkövér.
    const fontWeight = await badge.evaluate((el) => getComputedStyle(el).fontWeight)
    expect(Number(fontWeight)).toBeGreaterThanOrEqual(700)

    // SZÍN NÉLKÜLI: a jelölés színe megegyezik a befoglaló cella szövegszínével,
    // azaz nincs saját (piros) szín-felülírás — fekete-fehér nyomtatón is olvasható.
    const badgeColor = await badge.evaluate((el) => getComputedStyle(el).color)
    const cellColor = await badge.evaluate(
      (el) => getComputedStyle(el.parentElement as HTMLElement).color,
    )
    expect(badgeColor).toBe(cellColor)

    // Nem csonkolt bizonylatszám: a "-SZ" utótag is látszik, és a cella nem vágja le.
    const cell = page.locator('td', { hasText: LONG_STORNO_RECEIPT }).first()
    await expect(cell).toContainText(LONG_STORNO_RECEIPT)
    const clipped = await cell.evaluate((el) => el.scrollWidth > el.clientWidth + 1)
    expect(clipped).toBe(false)

    // Nyomtatási médiában is ugyanígy jelenik meg (FR-10: képernyőn ÉS nyomtatáskor).
    await page.emulateMedia({ media: 'print' })
    await expect(badge).toBeVisible()
    await expect(badge).toHaveText('SZTORNÓ')
    const printFontWeight = await badge.evaluate((el) => getComputedStyle(el).fontWeight)
    expect(Number(printFontWeight)).toBeGreaterThanOrEqual(700)
    const printBadgeColor = await badge.evaluate((el) => getComputedStyle(el).color)
    const printCellColor = await badge.evaluate(
      (el) => getComputedStyle(el.parentElement as HTMLElement).color,
    )
    expect(printBadgeColor).toBe(printCellColor)

    await page.emulateMedia({ media: 'screen' })
  })
})
