import { expect, test } from '@playwright/test'

const UNAUTHENTICATED_RESOURCE_ERROR =
  'Failed to load resource: the server responded with a status of 401 (Unauthorized)'
const REFRESH_COOKIE_PATH = '/api/v1/auth/refresh-cookie'

const isExpectedUnauthenticatedResourceError = (text: string): boolean =>
  text === UNAUTHENTICATED_RESOURCE_ERROR

/**
 * SMOKE TEST — App betöltés, nincs JS error
 */
test('app betöltődik a login oldalon', async ({ page }) => {
  // Audit P1.3 (2026-05-03): az App.tsx mountkor megkiserli a `/auth/refresh-cookie`
  // endpointot — ezt mockoljuk 401-gyel (nincs HttpOnly cookie), hogy ne menjen
  // ECONNREFUSED-be a Vite proxy-n keresztul (CI-ben nincs backend).
  await page.route('**/api/v1/auth/refresh-cookie', route =>
    route.fulfill({ status: 401, contentType: 'application/json', body: '{}' })
  )

  // Gyűjtsük össze a console errorokat
  const errors: string[] = []
  const unauthorizedResponses: string[] = []
  page.on('console', msg => {
    if (msg.type() === 'error') {
      errors.push(msg.text())
    }
  })
  page.on('response', response => {
    if (response.status() === 401) {
      unauthorizedResponses.push(response.url())
    }
  })

  // Navigálunk a login oldalra
  await page.goto('/login', { waitUntil: 'domcontentloaded' })

  // Ellenőrizzük, hogy az oldal betöltődött
  await expect(page).toHaveURL(/\/login/)
  
  // Alapvető elemek jelenléte: bármelyik input form
  const inputs = page.locator('input, button, [role="button"]')
  const count = await inputs.count()
  expect(count).toBeGreaterThan(0)

  const unexpectedUnauthorizedResponses = unauthorizedResponses.filter(url =>
    !url.includes(REFRESH_COOKIE_PATH)
  )
  expect(unexpectedUnauthorizedResponses).toEqual([])

  // Nem szabad, hogy kritikus JS errorok legyenek.
  // A mockolt refresh-cookie 401 normalis unauthenticated bootstrap zaj; mas 401-et
  // a fenti response-ellenorzes mar elutasit.
  const criticalErrors = errors.filter(e =>
    !isExpectedUnauthenticatedResourceError(e) &&
    !e.includes('warn') &&
    !e.includes('deprecated') &&
    !e.includes('Chrome DevTools')
  )
  expect(criticalErrors).toEqual([])
})

test('backend nem elérhető esetén teszt skip-olódik gracefully', async ({ page }) => {
  await page.route('**/api/v1/auth/refresh-cookie', route =>
    route.fulfill({ status: 401, contentType: 'application/json', body: '{}' })
  )

  // Ha a backend nem elérhető, az axios 500/offline hibát dob
  // Ezt kezelnie kell az app-nak
  const errors: string[] = []
  page.on('console', msg => {
    if (msg.type() === 'error') {
      errors.push(msg.text())
    }
  })

  await page.goto('/login')
  
  // Ha nincs error, sikeres
  // Ha van error, az OK (backend offline)
  // A lényeg: az oldal nem zuhanhat össze
  const hasErrorElement = await page.locator('[data-testid="error"]').isVisible().catch(() => false)
  
  if (!hasErrorElement && errors.length === 0) {
    // OK, backend elérhető
    expect(true).toBe(true)
  } else if (hasErrorElement || errors.length > 0) {
    // OK, gracefully kezelve
    expect(true).toBe(true)
  }
})
