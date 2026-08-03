import { expect, test, type Page } from '@playwright/test'

/**
 * FK-072_v2 E2E:
 *  - regresszió: teljes záráskori címletezés csak egész címletekkel → sikeres továbblépés
 *  - tört-bevitel kísérlete: az 1 alatti névértékű sor (EUR 0,5) mezője nem elérhető
 *    (a sor nincs a kirajzolásban), és a beküldött payload nem tartalmaz tört kulcsot.
 */

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const wizardId = '44444444-4444-4444-4444-444444444444'

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

/** Címlettörzs: HUF egész + EUR egész (100, 1) ÉS tört (0,5) sor. */
const denominationMaster = [
  { id: 1, currencyId: 2, currencyCode: 'HUF', faceValue: 20000, denominationType: 'BANKNOTE', active: true },
  { id: 2, currencyId: 2, currencyCode: 'HUF', faceValue: 1000, denominationType: 'BANKNOTE', active: true },
  { id: 3, currencyId: 4, currencyCode: 'EUR', faceValue: 100, denominationType: 'BANKNOTE', active: true },
  { id: 4, currencyId: 4, currencyCode: 'EUR', faceValue: 1, denominationType: 'COIN', active: true },
  { id: 5, currencyId: 4, currencyCode: 'EUR', faceValue: 0.5, denominationType: 'COIN', active: true },
]

async function mockClosingApis(page: Page) {
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

    if (path.endsWith('/daily-sessions/validate-closing') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          validationDate: '2026-08-03',
          errorCode: 0,
          errorMessage: 'OK',
          allValid: true,
          currencyDenominationOk: true,
          handlingFeeDenominationOk: true,
          westernUnionDenominationOk: true,
          vatDenominationOk: true,
          ecommerceDenominationOk: true,
        }),
      })
    }

    if (path.endsWith('/closing-wizard/validate-transactions') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([]),
      })
    }

    if (path.endsWith('/closing-wizard/start') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: wizardId,
          branchId: 'branch-1',
          status: 'IN_PROGRESS',
          closingType: 'DAILY',
          steps: [{ stepNumber: 1, stepName: 'Címletezés', completed: true, status: 'OK' }],
        }),
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/denominations`) && method === 'POST') {
      // Csak egész címletkulcsok mehetnek — tört kulcs (pl. "0.5") nem kerülhet a payloadba.
      expect(await route.request().postDataJSON()).toEqual({
        HUF: { 20000: 5 },
        EUR: { 100: 2 },
      })
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ total: 100800 }),
      })
    }

    if (path.endsWith('/closing-wizard/currencies-with-balance') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(['HUF', 'EUR']),
      })
    }

    if (path.endsWith('/denominations') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(denominationMaster),
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/differences`) && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { currencyCode: 'HUF', expected: 100000, actual: 100000, difference: 0, status: 'OK' },
          { currencyCode: 'EUR', expected: 200, actual: 200, difference: 0, status: 'OK' },
        ]),
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/navigate`) && method === 'POST') {
      const targetStep = Number(url.searchParams.get('targetStep') ?? '2')
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: wizardId,
          branchId: 'branch-1',
          status: 'IN_PROGRESS',
          closingType: 'DAILY',
          steps: [
            {
              stepNumber: targetStep,
              stepName: `Step ${targetStep}`,
              completed: true,
              status: 'OK',
            },
          ],
        }),
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/report`) && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          wizardId,
          branchName: 'Budapest 01',
          closingDate: '2026-08-03',
          closingType: 'DAILY',
          transactionCount: 3,
          inventory: [
            { currencyCode: 'HUF', openingBalance: 100000, currentBalance: 100000, dailyChange: 0 },
          ],
        }),
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

/** A címletsor inputja a sor-label melletti spinbutton (sorrend-független keresés). */
function denomInput(page: Page, label: string) {
  return page
    .getByText(label, { exact: true })
    .locator('..')
    .getByRole('spinbutton')
}

async function startWizardUntilDenominationStep(page: Page) {
  await page.goto('/closing/wizard', { waitUntil: 'domcontentloaded' })
  const validationRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/closing-wizard/validate-transactions',
  )
  await page.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i }).click()
  await validationRequest
  // A címletezés-blokk megjelenik (HUF 20 000-es sor mindig látszik).
  await expect(page.getByText('20 000', { exact: true })).toBeVisible()
}

test('FK-072 regresszió: záráskori címletezés csak egész címletekkel → sikeres továbblépés', async ({
  page,
}) => {
  await mockClosingApis(page)
  await login(page)
  await startWizardUntilDenominationStep(page)

  await denomInput(page, '20 000').fill('5')
  await denomInput(page, '100').fill('2')
  await page.getByRole('button', { name: /Cimletezés rogzitese/i }).click()

  await expect(page.getByText('Eltérés ellenőrzés')).toBeVisible()
  await expect(page.getByTestId('closing-differences-table')).toContainText('HUF')
  await expect(page.getByTestId('closing-differences-table')).toContainText('EUR')
})

test('FK-072 FR-1: tört címlet (EUR 0,5) mezője nem elérhető a záró-varázslóban', async ({
  page,
}) => {
  await mockClosingApis(page)
  await login(page)
  await startWizardUntilDenominationStep(page)

  // Az egész EUR sorok látszanak… (a címletsor-label a w-16 span — a lépés-sorszám
  // badge-ek is mutathatnak pl. "1"-et, ezért a keresés a sor-labelre szűkített)
  await expect(page.locator('span.w-16').filter({ hasText: /^100$/ })).toBeVisible()
  await expect(page.locator('span.w-16').filter({ hasText: /^1$/ })).toBeVisible()
  // …de a tört (0,5) sor SEMMILYEN formában nincs a DOM-ban (se disabled mezőként).
  await expect(page.getByText('0,5', { exact: true })).toHaveCount(0)
})
