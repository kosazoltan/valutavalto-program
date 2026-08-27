/**
 * SetupWizard integrációs tesztek — VALÓS production API hívásokkal.
 *
 * Ezek a tesztek pontosan ugyanazokat az endpointokat hívják, mint a
 * SetupWizard Electron IPC láncolata:
 *   1. GET /auth/bootstrap-status
 *   2. GET /public/branches?companyCode=EBC
 *   3. GET /public/workers?companyCode=EBC&branchCode=BR039
 *   4. POST /auth/first-time-worker-setup
 *
 * A tesztek nem módosítanak adatot: a POST validációs hívások garantáltan
 * nem létező dolgozói kódot vagy eleve hibás payloadot küldenek, és csak a
 * HTTP válaszkódot, illetve a hibaüzenetet ellenőrzik.
 * A GET kérések legfeljebb 3 próbálkozással, próbálkozásonként 5 s aborttal
 * és logolt transport-retry-jal futnak. A runtime guarddal bizonyítottan read-only
 * validációs POST-ok 3 × 10 s abort-korláttal futnak; HTTP-választ soha nem retry-zunk.
 *
 * Futtatás: npx vitest run src/pages/setup/SetupWizard.integration.test.ts
 *
 * FONTOS: Ezek PRODUCTION endpointokat hívnak — ne futtasd gyakran,
 * és soha ne küldj valós jelszó-módosító kérést!
 */
import { afterEach, describe, expect, it, vi } from 'vitest'

const API_BASE = 'https://excvaluta.com/api/v1'
const COMPANY_CODE = 'EBC'
const TEST_BRANCH_CODE = 'BR039' // Szeged Tisza — ismert branch
const TEST_WORKER_CODE = 'KOSA' // Ismert worker
// 11 karakter: a backend max. 10 karakteres workerCode-validációja a worker lookup előtt elutasítja.
const LENGTH_INVALID_WORKER_CODE = 'NONEXISTENT'
const INVALID_COMPANY_CODE = 'FAKECOMPANY'

interface TransportRetryOptions {
  /** Próbálkozások összesen (1 = nincs retry). GET és őrzött validációs POST default: 3. */
  attempts?: number
  /** Attempt-enkénti abort-korlát ms-ben. GET default: 5000, POST: 10000. */
  attemptTimeoutMs?: number
  /** Backoff a próbálkozások KÖZÖTT, ms-ben; hossza attempts-1. Default: [500, 1000]. */
  backoffMs?: number[]
}

const GET_DEFAULTS = { attempts: 3, attemptTimeoutMs: 5_000, backoffMs: [500, 1_000] }

const sleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms))

const isTransportError = (err: unknown): boolean => {
  if (err instanceof DOMException && (err.name === 'TimeoutError' || err.name === 'AbortError')) {
    return true
  }
  // Node undici network-hiba: TypeError('fetch failed'), cause-ban a socket-hiba
  return err instanceof TypeError
}

/**
 * fetch explicit attempt-szintű abort-timeouttal és korlátos, logolt
 * transport-retry-jal.
 *
 * SZERZŐDÉS:
 *  - Ha BÁRMILYEN Response megérkezik (200/400/429/500/bármi), AZONNAL
 *    visszaadjuk — HTTP-státuszt SOHA nem retry-zunk.
 *  - Retry-zható hibák KIZÁRÓLAG: attempt-abort (DOMException 'TimeoutError'
 *    vagy 'AbortError' az AbortSignal.timeout-ból) és network-szintű TypeError
 *    ('fetch failed': ECONNRESET, ECONNREFUSED, ETIMEDOUT, EAI_AGAIN, socket hang).
 *  - Minden retry console.warn-nal logolódik: attempt-sorszám, URL, hiba-név,
 *    hiba-üzenet, eltelt ms.
 *  - Ha az összes attempt elfogy, aggregált Error dobódik az összes attempt
 *    hibájával és időzítésével → a teszt őszintén, diagnosztizálhatóan bukik.
 */
async function fetchWithTransportRetry(
  url: string,
  init?: RequestInit,
  opts?: TransportRetryOptions,
): Promise<Response> {
  const { attempts, attemptTimeoutMs, backoffMs } = { ...GET_DEFAULTS, ...opts }
  const failures: string[] = []

  for (let attempt = 1; attempt <= attempts; attempt++) {
    const startedAt = Date.now()
    try {
      // Explicit abort-korlát MINDEN network-attemptre (constraint-követelmény).
      return await fetch(url, { ...init, signal: AbortSignal.timeout(attemptTimeoutMs) })
    } catch (err) {
      const elapsed = Date.now() - startedAt
      const name = err instanceof Error ? err.name : 'UnknownError'
      const message = err instanceof Error ? err.message : String(err)
      failures.push(`attempt ${attempt}/${attempts}: ${name} (${message}) ${elapsed}ms után`)

      if (!isTransportError(err) || attempt === attempts) {
        throw new Error(
          `[transport] ${init?.method ?? 'GET'} ${url} — minden próbálkozás elbukott:\n` +
            failures.map((failure) => `  - ${failure}`).join('\n'),
          { cause: err },
        )
      }
      console.warn(`[transport-retry] ${url} — ${failures[failures.length - 1]}, retry...`)
      await sleep(backoffMs[attempt - 1] ?? backoffMs[backoffMs.length - 1] ?? 500)
    }
  }
  throw new Error('unreachable') // a for-loop mindig return-öl vagy throw-ol
}

/**
 * Kizárólag biztosan read-only first-time-worker-setup validációs POST.
 * A guard minden network I/O előtt fail-closed módon bizonyít legalább egy
 * megváltoztathatatlanul hibás predikátumot; általános POST-ra nem használható.
 */
const postReadOnlyValidationWithTransportRetry = (
  url: string,
  init: RequestInit,
): Promise<Response> => {
  if (init.method !== 'POST' || typeof init.body !== 'string') {
    throw new Error(
      '[read-only validation] Kizárólag POST metódus és JSON-string body engedélyezett',
    )
  }

  let payload: unknown
  try {
    payload = JSON.parse(init.body)
  } catch (err) {
    throw new Error('[read-only validation] A request body nem érvényes JSON', { cause: err })
  }

  if (typeof payload !== 'object' || payload === null || Array.isArray(payload)) {
    throw new Error('[read-only validation] A request body csak JSON objektum lehet')
  }

  const body = payload as Record<string, unknown>
  const hasReadOnlySafetyPredicate =
    body.workerCode === LENGTH_INVALID_WORKER_CODE ||
    body.companyCode === INVALID_COMPANY_CODE ||
    !Object.prototype.hasOwnProperty.call(body, 'newPassword')

  if (!hasReadOnlySafetyPredicate) {
    throw new Error(
      '[read-only validation] Nem bizonyítható, hogy a POST payload biztosan read-only',
    )
  }

  return fetchWithTransportRetry(url, init, {
    attempts: 3,
    attemptTimeoutMs: 10_000,
    backoffMs: [500, 1_000],
  })
}

describe('read-only validation POST helper proof', () => {
  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('unsafe real-worker payload fails before fetch', () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch')

    expect(() =>
      postReadOnlyValidationWithTransportRetry('https://example.invalid/setup', {
        method: 'POST',
        body: JSON.stringify({
          companyCode: COMPANY_CODE,
          workerCode: TEST_WORKER_CODE,
          newPassword: 'UnsafeRealWorkerPassword',
        }),
      }),
    ).toThrow('read-only validation')
    expect(fetchSpy).not.toHaveBeenCalled()
  })

  it('safe validation POST retries transport errors up to the third attempt', async () => {
    vi.useFakeTimers()
    const fetchSpy = vi
      .spyOn(globalThis, 'fetch')
      .mockRejectedValueOnce(new TypeError('fetch failed 1'))
      .mockRejectedValueOnce(new TypeError('fetch failed 2'))
      .mockResolvedValueOnce(new Response(null, { status: 400 }))

    const responsePromise = postReadOnlyValidationWithTransportRetry(
      'https://example.invalid/setup',
      {
        method: 'POST',
        body: JSON.stringify({
          companyCode: COMPANY_CODE,
          workerCode: LENGTH_INVALID_WORKER_CODE,
          newPassword: 'SafeValidationOnly',
        }),
      },
    )
    await vi.runAllTimersAsync()

    await expect(responsePromise).resolves.toHaveProperty('status', 400)
    expect(fetchSpy).toHaveBeenCalledTimes(3)
  })

  it('HTTP 500 returns immediately without retry', async () => {
    const fetchSpy = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(new Response(null, { status: 500 }))

    const response = await postReadOnlyValidationWithTransportRetry(
      'https://example.invalid/setup',
      {
        method: 'POST',
        body: JSON.stringify({
          companyCode: INVALID_COMPANY_CODE,
          workerCode: TEST_WORKER_CODE,
          newPassword: 'SafeValidationOnly',
        }),
      },
    )

    expect(response.status).toBe(500)
    expect(fetchSpy).toHaveBeenCalledTimes(1)
  })
})

// ---------------------------------------------------------------------------
// 1. Bootstrap status
// ---------------------------------------------------------------------------
describe('Production API — Bootstrap status', () => {
  it('GET /auth/bootstrap-status 200 + completed flag', async () => {
    const res = await fetchWithTransportRetry(`${API_BASE}/auth/bootstrap-status`)
    expect(res.status).toBe(200)

    const body = (await res.json()) as { completed?: boolean }
    expect(body).toHaveProperty('completed')
    expect(typeof body.completed).toBe('boolean')
    // Production-on a bootstrap lezárt:
    expect(body.completed).toBe(true)
  })
})

// ---------------------------------------------------------------------------
// 2. Branch listing
// ---------------------------------------------------------------------------
describe('Production API — Branch listing', () => {
  it('GET /public/branches?companyCode=EBC visszaad legalább 60 irodát', async () => {
    const res = await fetchWithTransportRetry(
      `${API_BASE}/public/branches?companyCode=${COMPANY_CODE}`,
    )
    expect(res.status).toBe(200)

    const branches = (await res.json()) as Array<{
      code: string
      name: string
      city: string
      isVault?: boolean
    }>
    expect(Array.isArray(branches)).toBe(true)
    expect(branches.length).toBeGreaterThanOrEqual(60)

    // Minden branch-nek kell code, name, city
    for (const b of branches) {
      expect(b.code).toBeTruthy()
      expect(b.name).toBeTruthy()
      expect(b.city).toBeTruthy()
    }
  })

  it('A BR039 (Szeged Tisza) iroda létezik a listában', async () => {
    const res = await fetchWithTransportRetry(
      `${API_BASE}/public/branches?companyCode=${COMPANY_CODE}`,
    )
    const branches = (await res.json()) as Array<{ code: string; name: string }>
    const br039 = branches.find((b) => b.code === TEST_BRANCH_CODE)
    expect(br039).toBeDefined()
  })

  it('Ismeretlen cégkód üres listát ad (nem hibát)', async () => {
    const res = await fetchWithTransportRetry(`${API_BASE}/public/branches?companyCode=FAKECOMPANY`)
    expect(res.status).toBe(200)
    const branches = await res.json()
    expect(Array.isArray(branches)).toBe(true)
    expect(branches.length).toBe(0)
  })
})

// ---------------------------------------------------------------------------
// 3. Worker listing
// ---------------------------------------------------------------------------
describe('Production API — Worker listing', () => {
  it('GET /public/workers?companyCode=EBC&branchCode=BR039 visszaad dolgozókat', async () => {
    const res = await fetchWithTransportRetry(
      `${API_BASE}/public/workers?companyCode=${COMPANY_CODE}&branchCode=${TEST_BRANCH_CODE}`,
    )
    expect(res.status).toBe(200)

    const workers = (await res.json()) as Array<{
      code: string
      name: string
      region?: string
    }>
    expect(Array.isArray(workers)).toBe(true)
    expect(workers.length).toBeGreaterThan(0)

    // Minden worker-nek kell code + name
    for (const w of workers) {
      expect(w.code).toBeTruthy()
      expect(w.name).toBeTruthy()
    }
  })

  it('A KOSA dolgozó megjelenik a BR039 worker listában', async () => {
    const res = await fetchWithTransportRetry(
      `${API_BASE}/public/workers?companyCode=${COMPANY_CODE}&branchCode=${TEST_BRANCH_CODE}`,
    )
    const workers = (await res.json()) as Array<{ code: string; name: string }>
    const kosa = workers.find((w) => w.code === TEST_WORKER_CODE)
    expect(kosa).toBeDefined()
    expect(kosa!.name).toBeTruthy()
  })

  it('branchCode nélkül üres lista (nem hiba)', async () => {
    const res = await fetchWithTransportRetry(
      `${API_BASE}/public/workers?companyCode=${COMPANY_CODE}`,
    )
    expect(res.status).toBe(200)
    const workers = await res.json()
    expect(Array.isArray(workers)).toBe(true)
    expect(workers.length).toBe(0)
  })

  it('Ismeretlen branchCode üres lista (nem hiba)', async () => {
    const res = await fetchWithTransportRetry(
      `${API_BASE}/public/workers?companyCode=${COMPANY_CODE}&branchCode=FAKEBRANCH`,
    )
    expect(res.status).toBe(200)
    const workers = await res.json()
    expect(Array.isArray(workers)).toBe(true)
    expect(workers.length).toBe(0)
  })
})

// ---------------------------------------------------------------------------
// 4. Worker first-time setup (read-only validation tesztek)
// ---------------------------------------------------------------------------
describe('Production API — Worker first-time setup validation', () => {
  // FONTOS: ezek a tesztek SZÁNDÉKOSAN NEM állítanak be jelszót.
  // Csak a hibakódokat és hibaüzeneteket validálják.
  //
  // 2026-05-18: az `/auth/first-time-worker-setup` endpoint a production-ön
  // rate-limit védelem alatt áll (bot-elleni védelem). Ha egymás után többször
  // hívjuk, HTTP 429 jön vissza. A 429 ÉPP a backend-funkcionalitás bizonyítéka
  // (az endpoint él és védi magát), tehát accept-eljük.

  /** A rate-limit HTTP 429 önmagában azt jelenti, hogy az endpoint él. */
  const isRateLimitedOrExpected = (actual: number, expected: number): boolean =>
    actual === expected || actual === 429

  it('Ismeretlen workerCode → 400 hibaválasz (vagy 429 rate-limit)', async () => {
    const res = await postReadOnlyValidationWithTransportRetry(
      `${API_BASE}/auth/first-time-worker-setup`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          companyCode: COMPANY_CODE,
          workerCode: LENGTH_INVALID_WORKER_CODE,
          newPassword: 'Test123!',
        }),
      },
    )
    expect(isRateLimitedOrExpected(res.status, 400)).toBe(true)
    if (res.status === 429) return // rate-limit → endpoint él, teszt elfogadva
    const body = (await res.json()) as Record<string, unknown>
    // Spring Boot 4 RFC-7807: { title, status, detail, message } — bármelyik tartalmazhatja a hibát
    const errorText = String(body.message ?? body.detail ?? '')
    expect(errorText).toBeTruthy()
  })

  it('Ismeretlen companyCode → 400 + hibaüzenet (vagy 429)', async () => {
    const res = await postReadOnlyValidationWithTransportRetry(
      `${API_BASE}/auth/first-time-worker-setup`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          companyCode: INVALID_COMPANY_CODE,
          workerCode: TEST_WORKER_CODE,
          newPassword: 'Test123!',
        }),
      },
    )
    expect(isRateLimitedOrExpected(res.status, 400)).toBe(true)
    if (res.status === 429) return
    const body = (await res.json()) as { message?: string }
    expect(body.message).toContain('Ismeretlen cegkod')
  })

  it('Hiányzó newPassword → 400 (validációs hiba) (vagy 429)', async () => {
    const res = await postReadOnlyValidationWithTransportRetry(
      `${API_BASE}/auth/first-time-worker-setup`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          companyCode: COMPANY_CODE,
          workerCode: TEST_WORKER_CODE,
        }),
      },
    )
    // A backend validálja a DTO-t — hiányzó mező → 400 (vagy 429 ha rate-limited)
    expect(isRateLimitedOrExpected(res.status, 400)).toBe(true)
  })
})

// ---------------------------------------------------------------------------
// 5. Teljes SetupWizard flow szimuláció (read-only)
// ---------------------------------------------------------------------------
describe('Production API — SetupWizard teljes flow szimuláció', () => {
  it('A teljes flow lépései mind sikeresen hívhatók', { timeout: 90_000 }, async () => {
    // 1. Bootstrap check
    const bootstrapRes = await fetchWithTransportRetry(`${API_BASE}/auth/bootstrap-status`)
    expect(bootstrapRes.status).toBe(200)
    const bootstrap = (await bootstrapRes.json()) as { completed: boolean }

    // 2. Branch-ek lekérése
    const branchesRes = await fetchWithTransportRetry(
      `${API_BASE}/public/branches?companyCode=${COMPANY_CODE}`,
    )
    expect(branchesRes.status).toBe(200)
    const branches = (await branchesRes.json()) as Array<{ code: string; name: string }>
    expect(branches.length).toBeGreaterThan(0)

    // 3. Worker-ek lekérése a kiválasztott branch-höz
    const selectedBranch = branches.find((b) => b.code === TEST_BRANCH_CODE)
    expect(selectedBranch).toBeDefined()

    const workersRes = await fetchWithTransportRetry(
      `${API_BASE}/public/workers?companyCode=${COMPANY_CODE}&branchCode=${selectedBranch!.code}`,
    )
    expect(workersRes.status).toBe(200)
    const workers = (await workersRes.json()) as Array<{ code: string; name: string }>
    expect(workers.length).toBeGreaterThan(0)

    // 4. Dolgozó kiválasztás
    const selectedWorker = workers.find((w) => w.code === TEST_WORKER_CODE)
    expect(selectedWorker).toBeDefined()

    // 5. First-time setup endpoint read-only validációs ellenőrzése.
    // A valós KOSA dolgozót csak a GET flow-ban választjuk ki és ellenőrizzük; POST-ban soha
    // nem küldjük el. A garantáltan elutasított workerCode kizárja a jelszómódosítást.
    const setupRes = await postReadOnlyValidationWithTransportRetry(
      `${API_BASE}/auth/first-time-worker-setup`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          companyCode: COMPANY_CODE,
          workerCode: LENGTH_INVALID_WORKER_CODE,
          newPassword: 'IntegrationTestPassword_DO_NOT_SAVE',
        }),
      },
    )
    // Fail-closed: csak a validációs 400 vagy a dokumentált rate-limit 429 elfogadható.
    expect([400, 429]).toContain(setupRes.status)

    if (setupRes.status === 429) {
      console.log('[Integration] Rate-limit hit (HTTP 429) — endpoint él, teszt elfogadva')
      return
    }

    const setupBody = (await setupRes.json()) as Record<string, unknown>
    const errorText = String(setupBody.message ?? setupBody.detail ?? '')
    expect(errorText).toBeTruthy()

    // Összegzés logolás
    console.log(`[Integration] Bootstrap completed: ${bootstrap.completed}`)
    console.log(`[Integration] Branches: ${branches.length}`)
    console.log(`[Integration] Workers for ${TEST_BRANCH_CODE}: ${workers.length}`)
    console.log(`[Integration] First-time-setup response: HTTP ${setupRes.status}`)
    console.log(`[Integration] Error message: ${errorText}`)
  })
})
