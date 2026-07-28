import { expect, test, type Page } from '@playwright/test'

/**
 * FK-068 (RED-fázis): teljes pénztári napi zárás a felületen, a sikeres
 * véglegesítés-gombig.
 *
 * A repo e2e-infrastruktúrája mock-API-alapú (nincs valós backend), ezért a mock
 * ÁLLAPOTTARTÓ, és hűen tükrözi a backend perzisztencia-szemantikáját:
 *  - a start a backend ClosingWizardSteps.getStepsForType('DAILY') kimenetének
 *    megfelelő perzisztált lépés-listát hoz létre,
 *  - a navigate az adott POZÍCIÓT jelöli elvégzettnek (ahogy a backend
 *    navigate → executeStepCheck teszi),
 *  - a finalize a backend tényleges szabályával utasít el: ha bármely perzisztált
 *    lépés nincs elvégezve → 400, "Nem minden lépés lett végrehajtva: Lépés N".
 *
 * A felület 9 ellenőrzés-pozíciót jár be (INITIAL_STEPS), és az FK-068 utáni
 * backend pontosan 9 perzisztált lépést hoz létre — a teszt a teljes zárást a
 * sikeres véglegesítés-gombig viszi. (A RED-fázisban a tükör 10 lépéses volt,
 * és a teszt a valós hibaképpel bukott: aktív gomb, finalize 400 "Lépés 10".)
 */

// A backend ClosingWizardSteps.getStepsForType('DAILY') kimenetének TÜKRE
// (legacy lépés-sorszámok). FK-068 FR-1 után: 9 lépés, a 16-os legacy lépés
// nélkül. Ha a backend DAILY lépés-listája változik, ezt a tükör-fixture-t
// azzal EGYÜTT, dokumentált spec-változásként kell frissíteni — a teszt
// assertjei (sikeres véglegesítés a felületről) nem változhatnak emiatt.
const PERSISTED_DAILY_LEGACY_STEPS = [1, 2, 3, 4, 5, 6, 13, 14, 15]

const wizardId = '22222222-2222-2222-2222-222222222222'

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

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

type PersistedStep = { position: number; legacyStepNumber: number; completed: boolean }

function createPersistedSteps(): PersistedStep[] {
  return PERSISTED_DAILY_LEGACY_STEPS.map((legacyStepNumber, index) => ({
    position: index + 1,
    legacyStepNumber,
    completed: false,
  }))
}

async function mockStatefulClosingBackend(page: Page, persistedSteps: PersistedStep[]) {
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
    const json = (body: unknown, status = 200) =>
      route.fulfill({ status, contentType: 'application/json', body: JSON.stringify(body) })

    if (path.endsWith('/auth/login') && method === 'POST') {
      return json({
        token,
        tokenType: 'Bearer',
        expiresAt: new Date(Date.now() + 3600_000).toISOString(),
        worker,
        activeRole: 'ADMIN',
        permissions: ['READ', 'WRITE'],
        roles: ['ADMIN'],
        roleSelectionRequired: false,
      })
    }

    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') {
      return json({ token })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return json(worker)
    }

    if (path.endsWith('/daily-sessions/validate-closing') && method === 'GET') {
      return json({
        validationDate: new Date().toISOString().slice(0, 10),
        errorCode: 0,
        errorMessage: 'OK',
        allValid: true,
        currencyDenominationOk: true,
        handlingFeeDenominationOk: true,
        westernUnionDenominationOk: true,
        vatDenominationOk: true,
        ecommerceDenominationOk: true,
      })
    }

    if (path.endsWith('/closing-wizard/validate-transactions') && method === 'GET') {
      return json([])
    }

    if (path.endsWith('/closing-wizard/currencies-with-balance') && method === 'GET') {
      return json(['HUF'])
    }

    if (path.endsWith('/denominations') && method === 'GET') {
      return json([])
    }

    if (path.endsWith('/closing-wizard/start') && method === 'POST') {
      return json({
        id: wizardId,
        branchId: worker.branchId,
        status: 'IN_PROGRESS',
        closingType: 'DAILY',
        totalSteps: persistedSteps.length,
        steps: persistedSteps.map((s) => ({
          stepNumber: s.position,
          stepTitle: `Lépés ${s.position}`,
          completed: s.completed,
          canProceed: true,
          stepData: { legacyStepNumber: s.legacyStepNumber },
        })),
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/navigate`) && method === 'POST') {
      const targetStep = Number(url.searchParams.get('targetStep') ?? '0')
      const step = persistedSteps.find((s) => s.position === targetStep)
      if (step) {
        step.completed = true
      }
      return json({
        id: wizardId,
        branchId: worker.branchId,
        status: 'IN_PROGRESS',
        closingType: 'DAILY',
        steps: [{ stepNumber: targetStep, completed: true, status: 'OK' }],
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/denominations`) && method === 'POST') {
      return json({ total: 100000 })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/differences`) && method === 'POST') {
      return json([
        { currencyCode: 'HUF', expected: 100000, actual: 100000, difference: 0, status: 'OK' },
      ])
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/report`) && method === 'GET') {
      return json({
        wizardId,
        branchName: worker.branchName,
        closingDate: new Date().toISOString().slice(0, 10),
        closingType: 'DAILY',
        transactionCount: 0,
        inventory: [
          { currencyCode: 'HUF', openingBalance: 100000, currentBalance: 100000, dailyChange: 0 },
        ],
      })
    }

    if (path.endsWith(`/closing-wizard/${wizardId}/finalize`) && method === 'POST') {
      // A backend ClosingWizardService.finalizeClosing tényleges szabálya:
      // minden PERZISZTÁLT lépésnek elvégzettnek kell lennie.
      const incomplete = persistedSteps.filter((s) => !s.completed)
      if (incomplete.length > 0) {
        return json(
          {
            message: `Nem minden lépés lett végrehajtva: ${incomplete
              .map((s) => `Lépés ${s.position}`)
              .join(', ')}`,
          },
          400,
        )
      }
      return json({ success: true })
    }

    return json({})
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

test('FK-068: teljes pénztári napi zárás a felületen — 9 lépés után a véglegesítés sikeres', async ({
  page,
}) => {
  const persistedSteps = createPersistedSteps()
  await mockStatefulClosingBackend(page, persistedSteps)
  await login(page)

  await page.goto('/closing/wizard', { waitUntil: 'domcontentloaded' })

  // Zárás indítása → 1. ellenőrzés lefut, majd címletezés-bekérés
  const validationRequest = page.waitForRequest(
    (request) =>
      request.method() === 'GET' &&
      new URL(request.url()).pathname === '/api/v1/closing-wizard/validate-transactions',
  )
  await page.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i }).click()
  await validationRequest

  // Címletezés rögzítése (HUF 20000 × 5 = 100 000, a mock-nyilvántartással egyező)
  const firstDenomination = page.getByRole('spinbutton').first()
  await firstDenomination.fill('5')
  await page.getByRole('button', { name: /Cimletezés rogzitese/i }).click()

  // A 9 ellenőrzés-lépés lefutott, nincs eltérés → a véglegesítés-gomb aktív
  await expect(page.getByText(/9 \/ 9/)).toBeVisible()
  const finalizeButton = page.getByRole('button', {
    name: /RENDBEN — Napzárás végrehajtása/i,
  })
  await expect(finalizeButton).toBeEnabled()

  // Véglegesítés — a backend-szabály szerint MINDEN perzisztált lépésnek késznek
  // kell lennie. A mostani (10 lépéses) backend-tükörrel a finalize 400-zal
  // elutasít ("Nem minden lépés lett végrehajtva: Lépés 10") → a sikeres
  // visszajelzés nem jelenik meg → a teszt BUKIK (RED). A javítás után (9
  // perzisztált lépés) a véglegesítés átmegy.
  const finalizeResponse = page.waitForResponse(
    (response) =>
      response.request().method() === 'POST' &&
      new URL(response.url()).pathname === `/api/v1/closing-wizard/${wizardId}/finalize`,
  )
  await finalizeButton.click()
  const response = await finalizeResponse
  expect(response.status(), 'a finalize hívásnak sikeresnek kell lennie').toBe(200)

  // Felhasználó-látható sikeres lezárás (toast) — FK-068 FR-3 acceptance a felületen
  await expect(page.getByText('Napzárás végrehajtva')).toBeVisible()
})
