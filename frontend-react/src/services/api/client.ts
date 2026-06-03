import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '../../stores/authStore'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger';
import { isCentralWorkstationFlavor } from '../../utils/clientEnv'

// Extend AxiosRequestConfig to support custom flags.
// _preservePaged: ha true, a response interceptor NEM bontja content-tömbbé a
// Spring Page<T> választ (lapozó UI komponenseknek kell a teljes Page). Típusos
// mező → nem kell `as Record<string, unknown>` cast a hívóknál (Sourcery #861).
declare module 'axios' {
  interface AxiosRequestConfig {
    _skipGlobal403Toast?: boolean
    _preservePaged?: boolean
  }
  interface InternalAxiosRequestConfig {
    _skipGlobal403Toast?: boolean
    _preservePaged?: boolean
  }
}

const WEB_AUTH_TOKEN_KEY = 'auth_token'

// Audit P1.3 follow-up (Codex P2 #384, 2026-05-04): "session hint" flag a localStorage-ban.
// NEM token (XSS-immunis), csak egy boolean: "valamikor volt loginom -> a HttpOnly
// refresh cookie valoszinu jelen van -> erdemes a refresh-cookie bootstrap-ot probalni".
// A `hasPersistedToken` web modban EZT olvassa, hogy az App.tsx restore flow CSAK akkor
// blokkolodjon a 15s axios timeout splash-en, ha tenyleg volt korabban session.
const WEB_SESSION_HINT_KEY = 'has_login_session'

// Silent refresh endpoint — HttpOnly refreshToken cookie alapjan.
// Kotelezo `permitAll`-on legyen a backend-en, mert a hivashoz nincs valid access token.
// (A korabbi `/auth/refresh` az `@PreAuthorize("isAuthenticated()")` miatt lejart accessel
// 401-et ad, igy silent refresh cel-szerunek alkalmatlan.)
export const REFRESH_ENDPOINT = '/auth/refresh-cookie'

// Endpointok, amelyekre 401 utan TILOS silent refresh-t triggerelni — kulonben vegtelen loop.
// Sourcery PR #351 follow-up: REFRESH_ENDPOINT konstans reuse, hogy a skip-list autoSync-be
// keruljon a tenyleges endpoint atallitasanal (DRY).
const REFRESH_SKIP_PATHS = ['/auth/login', '/auth/refresh', REFRESH_ENDPOINT]

// API base URL meghatározása — priorizálás:
// 1. VITE_API_URL env var (build-time)
// 2. Electron: SQLite config 'server_url' (runtime, felhasználó által állítható)
// 3. DEV mód: relatív URL (Vite proxy-n keresztül → nincs CORS probléma)
// 4. Web production: relatív URL
let API_BASE_URL = import.meta.env.VITE_API_URL

// v2.5.7 KRITIKUS FIX (race condition gyokerok analysis 2026-05-04 utan):
// Ha az Electron production buildbe `localhost:*`-os VITE_API_URL kerult be (regi build-installer.ps1
// bug a 3/6 fazisban), AZONNAL — a SQLite `server_url` async override ELOTT — felulirjuk a hardcoded
// production URL-re. Ez eliminalja a race condition-t: az elso API hivas (pl. `fetchWorkers`
// LoginPage-en) mar a HELYES URL-re megy, nem `localhost`-ra.
// A `production-urls.json` extraResources mar tartalmazza ezt az URL-t — itt build-time string-kent
// inline-oljuk a kovetkezetesseg miatt.
const PRODUCTION_API_URL = 'https://excvaluta.com/api/v1'
if (typeof window !== 'undefined' && window.electronAPI && !import.meta.env.DEV) {
  if (typeof API_BASE_URL === 'string' && /^https?:\/\/(localhost|127\.0\.0\.1|192\.168\.)/i.test(API_BASE_URL)) {
    logger.warn('[api.client] Electron prod build, de VITE_API_URL localhost-ra mutat:', API_BASE_URL,
        '-> azonnali felulirasa', PRODUCTION_API_URL, '(race condition prevention)')
    API_BASE_URL = PRODUCTION_API_URL
  }
}

// Electron DEV mode: a Vite dev szerver proxyzza a /api kereseket a backend-re,
// igy NINCS CORS (az origin: http://127.0.0.1:3000 ugyanaz mint ahova a kerest
// kuldjuk). Ezert override-oljuk a VITE_API_URL-t relativra.
// Electron production (app://): az electronAPI.getConfig('server_url')-t nezi lejjebb.
if (import.meta.env.DEV && typeof window !== 'undefined' && window.electronAPI) {
  API_BASE_URL = '/api/v1'
}

// Production hardening: excvaluta domainen mindig a sajat /api reverse-proxy legyen az alap,
// hogy a browser ne kozvetlen cross-origin hivasokkal dolgozzon (CORS preload hibak elkerulese).
if (!import.meta.env.DEV && typeof window !== 'undefined' && !window.electronAPI) {
  const host = window.location.hostname.toLowerCase()
  if (host === 'excvaluta.com' || host === 'www.excvaluta.com') {
    API_BASE_URL = '/api/v1'
  }
}

if (!API_BASE_URL) {
  if (import.meta.env.DEV) {
    API_BASE_URL = '/api/v1'
  } else if (window.electronAPI) {
    // Electron production fallback a prod szerverre
    API_BASE_URL = 'https://excvaluta.com/api/v1'
  } else {
    // Webes production — relatív URL (proxy mögött) vagy env var kötelező
    API_BASE_URL = '/api/v1'
  }
}

// v2.3.0 kritikus bugfix: Electron production-ban MINDIG felulirjuk a build-time
// VITE_API_URL-t az SQLite config store server_url-rol (a telepito wizard irja be).
// Ez azert kell, mert a build idoben a VITE_API_URL neha rossz ertekkel fix-el be
// (pl. localhost:8080 a dev build .env-bol), es a futasi kornyezet-specifikus
// URL-t a felhasznalo altal konfiguralt server_url-nek kell biztositania.
if (!import.meta.env.DEV && typeof window !== 'undefined' && window.electronAPI?.getConfig) {
  window.electronAPI.getConfig('server_url').then((url: string | null) => {
    if (url && url.trim().length > 0) {
      const normalized = url.endsWith('/api/v1') ? url : `${url.replace(/\/$/, '')}/api/v1`
      if (api.defaults.baseURL !== normalized) {
        logger.info('[api.client]', 'SQLite server_url override applied:', normalized, '(volt:', api.defaults.baseURL, ')')
        api.defaults.baseURL = normalized
      }
    }
  }).catch((err) => {
    logger.warn('[api.client]', 'SQLite server_url read failed, marad a default:', err instanceof Error ? err.message : err)
  })
}

// 2026-04-29 v2.3.11 (E-B6 renderer fagyás fix):
// `timeout: 15000` — minden axios kérés MAX 15 másodperc, utána ECONNABORTED
// hibát kap a hívó. Az Electron sync-engine már használ AbortSignal.timeout(10s)-et,
// de a frontend-react axios kliensnek korábban NEM volt timeout-ja, így egy lassan
// válaszoló endpoint (pl. excvaluta.com 404 + Caddy 504-be időtúllépés) blokkolhatta
// a renderer event-loop-ot. 15s = kompromisszum a CSV-export (lehet >10s) és a
// fagyás-prevenció között. A user-action (vétel/eladás) tipikusan <2s.
//
// Hivatkozás: D:\valutavalto-vault\sessions\2026-04-29-ertektar-mode-audit.md §E-B6
//
// 2026-05-05 v2.5.19 (Borsi #417 fix):
// 15s -> 30s. A Borsi gépen v2.5.18 indítása után a "Belépés Google fiókkal"
// POST /auth/google-login a 15s-en túl válaszolt (ESET MITM TLS handshake +
// HTTP/1.1 (HTTP/2 disabled defensively) + Google API roundtrip + Caddy + JWT).
// 30s továbbra is védi a renderert a 60s+ Caddy 504-től, de elfogadja a
// natural slow path-okat ESET-tel rendelkező gépeken. CSV-export +
// 100k-record listák már >15s lehetnek, szóval a 30s univerzálisabb.
const AXIOS_GLOBAL_TIMEOUT_MS = 30_000

// Create axios instance
export const api = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,  // HttpOnly refresh cookie (vezerlokonyv par.12.3)
  timeout: AXIOS_GLOBAL_TIMEOUT_MS,
  headers: {
    'Content-Type': 'application/json',
  },
})

// v2.5.25 ESET MITM VEGLEGES FIX: Electron production-ban MINDEN axios hivas a main process
// electron.net.request-en megy at (IPC 'api:fetch'). A renderer Chromium fetch ESET/Kaspersky/
// Bitdefender MITM TLS proxy-val "Network Error"-t dob — a main process net.request a Windows
// certificate store-t hasznalja, ami ESET-kompatibilis.
//
// Implementacio: axios request interceptor, amely az eredeti config-ot az IPC proxy-ra iranyitja,
// majd a kapott response-t visszaforditja axios-kompatibilis formatumba.
if (typeof window !== 'undefined' && window.electronAPI?.apiRequest && !import.meta.env.DEV) {
  api.defaults.adapter = async (config: InternalAxiosRequestConfig): Promise<AxiosResponse> => {
    const baseUrl = config.baseURL ?? api.defaults.baseURL ?? ''
    let url = config.url?.startsWith('http')
      ? config.url
      : `${baseUrl}${config.url ?? ''}`

    // Codex P1: config.params must be serialized into the URL query string
    if (config.params && typeof config.params === 'object') {
      const serializer = config.paramsSerializer
      let queryString: string
      if (typeof serializer === 'function') {
        queryString = serializer(config.params)
      } else if (serializer && typeof serializer === 'object' && 'serialize' in serializer && typeof serializer.serialize === 'function') {
        queryString = serializer.serialize(config.params, serializer)
      } else {
        const searchParams = new URLSearchParams()
        for (const [key, value] of Object.entries(config.params as Record<string, unknown>)) {
          if (value !== undefined && value !== null) {
            searchParams.append(key, String(value))
          }
        }
        queryString = searchParams.toString()
      }
      if (queryString) {
        url += (url.includes('?') ? '&' : '?') + queryString
      }
    }

    const method = (config.method ?? 'GET').toUpperCase()

    const headers: Record<string, string> = {}
    if (config.headers) {
      const raw = config.headers
      if (typeof raw.forEach === 'function') {
        raw.forEach((value: string, key: string) => {
          headers[key] = value
        })
      } else if (typeof raw === 'object') {
        for (const [key, value] of Object.entries(raw)) {
          if (typeof value === 'string') headers[key] = value
        }
      }
    }

    let body: string | null = null
    if (config.data !== undefined && config.data !== null) {
      body = typeof config.data === 'string' ? config.data : JSON.stringify(config.data)
    }

    try {
      const proxyResponse = await window.electronAPI!.apiRequest({
        method,
        url,
        body,
        headers,
        timeoutMs: config.timeout ?? AXIOS_GLOBAL_TIMEOUT_MS,
      })

      let parsedData: unknown = proxyResponse.body
      const contentType = proxyResponse.headers['content-type'] ?? ''

      // Codex P1: responseType blob/arraybuffer — reconstruct binary from base64
      if ((config.responseType === 'blob' || config.responseType === 'arraybuffer') && proxyResponse.isBase64) {
        const binary = Uint8Array.from(atob(proxyResponse.body), c => c.charCodeAt(0))
        parsedData = config.responseType === 'blob'
          ? new Blob([binary], { type: contentType.split(';')[0] || 'application/octet-stream' })
          : binary.buffer
      } else if (contentType.includes('json') && typeof proxyResponse.body === 'string') {
        try { parsedData = JSON.parse(proxyResponse.body) } catch { /* keep raw string */ }
      }

      const axiosResponse: AxiosResponse = {
        data: parsedData,
        status: proxyResponse.status,
        statusText: proxyResponse.statusText,
        headers: proxyResponse.headers,
        config,
        request: {},
      }

      if (!proxyResponse.ok) {
        const error = new AxiosError(
          `Request failed with status code ${proxyResponse.status}`,
          proxyResponse.status >= 400 && proxyResponse.status < 500 ? 'ERR_BAD_REQUEST' : 'ERR_BAD_RESPONSE',
          config,
          {},
          axiosResponse,
        )
        throw error
      }

      return axiosResponse
    } catch (err) {
      if (err instanceof AxiosError) throw err
      const error = new AxiosError(
        (err as Error).message ?? 'Network Error',
        'ERR_NETWORK',
        config,
        {},
      )
      throw error
    }
  }

  logger.info('[api.client]', 'Electron main-process API proxy AKTIV (ESET MITM fix)')
}

// v2.5.13: kliens-oldali hibajelentes a backend `/diagnostics/error-report` endpointra.
// Send-and-forget IPC-n keresztul a main process-be (Electron) -> backend.
// A diagnostics endpoint ONMAGABA NEM riportolunk (vegtelen-loop elkerulese).
function reportClientError(payload: { component: string; message: string; stack?: string; context?: Record<string, unknown> }): void {
  if (typeof window === 'undefined' || !window.electronAPI?.reportError) return
  if (payload.context && typeof payload.context.url === 'string' && payload.context.url.includes('/diagnostics/')) return
  try {
    void window.electronAPI.reportError(payload)
  } catch {
    // never throw on error-reporting
  }
}

// v2.5.20 Borsi-fix: ESET MITM TLS handshake nehany kliens gepen leejti a POST connection-t
// a TLS handshake utan (nem 4xx/5xx, hanem network-level abort vagy timeout). A `/auth/login`
// es `/auth/google-login` POST-ok ertek leesnek, de egy retry tipikusan sikerul (a 08:56 nginx-log
// igazolja, hogy a backend el, csak az ESET-tel terhelt TLS conn drop-pelodik).
// Ezert a kritikus auth endpointokra es a sync polling-ra automatikus retry-t alkalmazunk.
const RETRYABLE_ENDPOINTS = ['/auth/login', '/auth/google-login', '/auth/refresh-cookie',
                             '/auth/bootstrap-status', '/transit/incoming']
const MAX_RETRY_COUNT = 2

interface RetryableConfig extends InternalAxiosRequestConfig {
  _retryCount?: number
}

function isNetworkOrTimeoutError(error: AxiosError): boolean {
  const status = error.response?.status
  if (status) return false   // 4xx/5xx — backend valaszolt, nem retry-zunk
  const code = error.code
  const msg = error.message ?? ''
  return code === 'ECONNABORTED'
      || code === 'ERR_NETWORK'
      || msg === 'Network Error'
      || /timeout of \d+ms exceeded/.test(msg)
}

// Axios response interceptor: retry network-level hibakra + 4xx/5xx hibakat hibajelentora kuldjuk.
api.interceptors.response.use(
  (resp) => resp,
  async (error: AxiosError) => {
    const config = error.config as RetryableConfig | undefined
    const url = config?.url ?? ''
    const status = error.response?.status

    // v2.5.20 Borsi-retry: kritikus auth endpointokra automatikus retry hatszer (1s, 3s wait).
    // A `/auth/login` `401`-et `isNetworkOrTimeoutError` kizar (status truthy → false),
    // szoval a rossz jelszo nem indit retry-t.
    const retryable = config
        && isNetworkOrTimeoutError(error)
        && typeof url === 'string'
        && RETRYABLE_ENDPOINTS.some(p => url.includes(p))
    if (retryable && config) {
      const retryCount = config._retryCount ?? 0
      if (retryCount < MAX_RETRY_COUNT) {
        config._retryCount = retryCount + 1
        const delayMs = retryCount === 0 ? 1000 : 3000
        logger.warn('[api.client]', `Retry ${config._retryCount}/${MAX_RETRY_COUNT} after ${delayMs}ms for ${url} — reason: ${error.message}`)
        await new Promise((r) => setTimeout(r, delayMs))
        return api.request(config)
      }
    }

    try {
      const isLoginAttempt = typeof url === 'string' && (url.includes('/auth/login') || url.includes('/auth/refresh') || url.includes('/auth/google-login'))
      if (status !== 401 || !isLoginAttempt) {
        reportClientError({
          component: 'axios-http',
          message: `${error.message} [${status ?? 'NO_STATUS'}]`,
          stack: error.stack,
          context: {
            url,
            method: config?.method,
            status,
            retryAttempts: config?._retryCount ?? 0,
            responseData: typeof error.response?.data === 'object' ? JSON.stringify(error.response.data).slice(0, 500) : String(error.response?.data ?? '').slice(0, 500),
          },
        })
      }
    } catch {
      // never throw on error-reporting
    }
    return Promise.reject(error)
  }
)

// window.onerror + window.onunhandledrejection: minden uncaught JS hiba a renderer-ben
if (typeof window !== 'undefined') {
  window.addEventListener('error', (event) => {
    reportClientError({
      component: 'electron-renderer',
      message: event.message,
      stack: event.error?.stack,
      context: { source: 'window.onerror', filename: event.filename, lineno: event.lineno, colno: event.colno },
    })
  })
  window.addEventListener('unhandledrejection', (event) => {
    const reason = event.reason
    const message = reason?.message ?? String(reason)
    const stack = reason?.stack
    reportClientError({
      component: 'electron-renderer',
      message,
      stack,
      context: { source: 'unhandledrejection' },
    })
  })
}

// Request interceptor - add auth token + Idempotency-Key for write requests
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const {token} = useAuthStore.getState()
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    // FK-016 (2026-06-03): a Központi Munkaállomás kliens (central-workstation flavor) minden
    // /branches GET lekérdezéséhez clientType=CENTRAL-t fűz, hogy a backend a virtuális
    // partnereket (VAULT_COUNTERPARTY) kizárja. Az értéktári/pénztári kliens nem küldi ezt,
    // így ott a partnerek (átadás-átvétel) változatlanul megmaradnak (regresszió-mentesség).
    if (
      (config.method ?? 'get').toUpperCase() === 'GET' &&
      config.url?.startsWith('/branches') &&
      isCentralWorkstationFlavor()
    ) {
      config.params = { ...(config.params ?? {}), clientType: 'CENTRAL' }
    }
    // Idempotency-Key header for write methods (required by backend IdempotencyFilter)
    // Fix: axios 1.x AxiosHeaders set() API hasznalata a direkt assignment helyett
    const method = (config.method ?? '').toUpperCase()
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method) && config.headers) {
      const existing = typeof config.headers.get === 'function'
        ? config.headers.get('Idempotency-Key')
        : config.headers['Idempotency-Key']
      if (!existing) {
        const newKey = crypto.randomUUID()
        if (typeof config.headers.set === 'function') {
          config.headers.set('Idempotency-Key', newKey)
        } else {
          config.headers['Idempotency-Key'] = newKey
        }
      }
    }
    return config
  },
  (error: AxiosError) => {
    logger.error('client', 'Request interceptor error:', error)
    return Promise.reject(error)
  }
)

// Token refresh state — megakadályozza a párhuzamos refresh kéréseket
let isRefreshing = false
let failedQueue: Array<{
  resolve: (token: string) => void
  reject: (error: unknown) => void
}> = []

function processQueue(error: unknown, token: string | null) {
  failedQueue.forEach(({ resolve, reject }) => {
    if (token) resolve(token)
    else reject(error)
  })
  failedQueue = []
}

// Response interceptor - handle errors + token refresh + 403 kezelés
api.interceptors.response.use(
  (response: AxiosResponse) => {
    // Auto-unwrap Spring Boot paginated responses (Page<T> → T[])
    // When backend returns { content: [...], totalElements, totalPages, ... }
    // but frontend expects a plain array, extract just the content.
    // Skip unwrap when request has _preservePaged flag (for paginated UI components).
    const d = response.data
    const preservePaged = response.config?._preservePaged === true
    if (!preservePaged && d && typeof d === 'object' && !Array.isArray(d) && Array.isArray(d.content) && ('totalElements' in d || 'totalPages' in d || 'number' in d)) {
      response.data = d.content
    }
    return response
  },
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    // 401 — token lejárt: próbáljuk refreshelni
    if (error.response?.status === 401 && !originalRequest._retry) {
      // Login + refresh endpointokra ne triggereljunk silent refresh-t (vegtelen loop).
      if (originalRequest.url && REFRESH_SKIP_PATHS.some((p) => originalRequest.url!.includes(p))) {
        return Promise.reject(error)
      }

      if (isRefreshing) {
        // Már fut egy refresh — várakozunk rá
        return new Promise((resolve, reject) => {
          failedQueue.push({
            resolve: (token: string) => {
              if (originalRequest.headers) {
                originalRequest.headers.Authorization = `Bearer ${token}`
              }
              resolve(api(originalRequest))
            },
            reject,
          })
        })
      }

      originalRequest._retry = true
      isRefreshing = true

      try {
        // Silent refresh a HttpOnly refreshToken cookie alapjan (vezerlokonyv par.12.3).
        // A `withCredentials: true` (lasd `api.create({ withCredentials: true })`) miatt
        // a browser automatikusan kuldi a `refreshToken` cookie-t a /auth/refresh-cookie
        // endpoint-ra, amely permitAll-on van, igy lejart access tokennel is mukodik.
        const response = await api.post<{ token: string }>(REFRESH_ENDPOINT)
        const newToken = response.data.token
        const authStore = useAuthStore.getState()
        if (authStore.worker) {
          authStore.login(authStore.worker, newToken, authStore.tokenType ?? 'Bearer', authStore.expiresAt ?? '',
            authStore.activeRole, authStore.permissions, authStore.roles, false, authStore.centralModules)
        }
        processQueue(null, newToken)
        if (originalRequest.headers) {
          originalRequest.headers.Authorization = `Bearer ${newToken}`
        }
        return api(originalRequest)
      } catch (refreshError) {
        processQueue(refreshError, null)
        // Refresh is sikertelen — kijelentkeztetés
        useAuthStore.getState().logout()
        window.location.href = '/login'
        return Promise.reject(refreshError)
      } finally {
        isRefreshing = false
      }
    }

    // 403 — jogosultság hiány (NEM logout, hanem informatív hiba)
    if (error.response?.status === 403) {
      if (originalRequest._skipGlobal403Toast) {
        logger.warn('client', '403 Forbidden (global toast skipped):', originalRequest.url)
      } else {
        logger.warn('client', '403 Forbidden:', originalRequest.url, '— Nincs jogosultság ehhez a művelethez')
        toast.error(
          'Hozzáférés megtagadva',
          'Nincs jogosultságod ehhez a művelethez. Kérj hozzáférést az adminisztrátortól.'
        )
      }
    }

    // Log error for debugging.
    // Audit P1.3 (2026-05-03): a refresh-cookie endpoint sikertelen probalkozasai
    // normalis allapot (user nincs bejelentkezve / lejart cookie). Ezeket DEBUG
    // szinten logoljuk, hogy NE szennyezzek a console.error-t (smoke testek!).
    const isRefreshCookieAttempt = error.config?.url?.includes(REFRESH_ENDPOINT)
    if (isRefreshCookieAttempt) {
      logger.debug('client', 'refresh-cookie attempt failed (normal if not logged in):', {
        status: error.response?.status,
        message: error.message,
      })
    } else {
      logger.error('client', 'API Error:', {
        url: error.config?.url,
        method: error.config?.method,
        status: error.response?.status,
        message: error.message,
      })
    }

    return Promise.reject(error)
  }
)

// Generic API response type
export interface ApiResponse<T> {
  data: T
  message?: string
  success: boolean
}

// Paginated response type
export interface PagedResponse<T> {
  content: T[]
  totalElements: number
  totalPages: number
  size: number
  number: number
}

// --- Token persist ---
//
// ACCESS TOKEN tarolas (Audit P1.3 — 2026-05-03 refaktor):
//   - Web: IN-MEMORY MODUL VALTOZO (`_webAccessToken`). NEM kerul localStorage/
//     sessionStorage-ba, igy egy XSS payload NEM tudja a perzisztens storage-bol
//     kiolvasni a tokent es kesobbi sessionre exfiltralni. Megjegyzes: aktiv XSS
//     ugyanabban a JS runtime-ban tovabbra is hozzafer az authenticated axios
//     instance-hoz / a window.fetch-hez — a cel a *perzisztens kiolvasas* es a
//     storage-bol valo replay megakadalyozasa, NEM a teljes XSS-immunitas.
//     Page-reload eseten a `loadPersistedToken` a HttpOnly refresh cookie-bol
//     kapcsol uj access tokent (`/auth/refresh-cookie`).
//   - Electron: OS-level titkositas (safeStorage / DPAPI / Keychain) — valtozatlan.
//
// REFRESH TOKEN (vezerlokonyv par.12.3, 2026-04-20 implementacio):
//   - Web: HttpOnly Secure SameSite=Strict cookie, Path=/api/v1/auth,
//     MaxAge=7d. JS-bol NEM elerheto, silent refresh interceptor automatikusan
//     hasznalja (axios withCredentials: true).
//   - Electron: safeStorage tokentárolás mellett a cookie is rendelkezesre
//     all (ugyanaz a backend /auth/login endpoint adja ki).
//   - DB: refresh_token tabla, BCrypt-hashelt token_value, token rotation
//     minden refresh-kor (regi revoke, uj issue).
//
// Migracio LegacyTokenCleanup: a meglevo localStorage `auth_token` felhasznalok
// elso load-kor torlik a localStorage-bol (lasd a `loadPersistedToken` web ag).

/** Cached Electron token presence — kept in sync by persist/clear/load. */
let _electronTokenPresent: boolean | null = null

/**
 * Audit P1.3: web in-memory access token (NEM localStorage).
 * Page reload utan null — a `loadPersistedToken` `/auth/refresh-cookie`-bol szerez ujat.
 */
let _webAccessToken: string | null = null

function isExpiredJwt(token: string): boolean {
  const parts = token.split('.')
  if (parts.length !== 3 || !parts[1]) {
    return true
  }

  try {
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/')
    const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4)
    const payload = JSON.parse(atob(padded)) as { exp?: unknown }
    return typeof payload.exp !== 'number' || payload.exp <= Math.floor(Date.now() / 1000)
  } catch {
    return true
  }
}

async function refreshAccessTokenFromCookie(): Promise<string | null> {
  try {
    const res = await api.post(REFRESH_ENDPOINT, undefined, { withCredentials: true })
    const newToken = res?.data?.token
    return typeof newToken === 'string' && newToken ? newToken : null
  } catch (err) {
    logger.debug('client', 'refresh-cookie bootstrap unavailable (user not logged in)', err)
    return null
  }
}

/** Token mentése Electron-ban — DPAPI/Keychain titkosítással (ha elérhető) */
export async function persistToken(token: string): Promise<void> {
  try {
    if (window.electronAPI) {
      if (window.electronAPI.secureStoreToken) {
        await window.electronAPI.secureStoreToken(token)
      } else {
        await window.electronAPI.setConfig('auth_token', token)
      }
      _electronTokenPresent = true
      return
    }

    // Audit P1.3: web in-memory tarolas, NEM localStorage (XSS perzisztencia ellen).
    _webAccessToken = token
    // Codex P2 #384 (2026-05-04): session hint flag, hogy a kovetkezo page-load-on
    // a `hasPersistedToken` true-t adjon -> az App restore flow lefusson a refresh-cookie
    // bootstrap-ra. Logout-ot kovetoen a `clearPersistedToken` torli (lasd alabb).
    try { window.localStorage.setItem(WEB_SESSION_HINT_KEY, '1') } catch { /* ignore (private mode) */ }
  } catch (err) {
    logger.error('client', 'persistToken failed:', err)
    throw err
  }
}

/** Token törlése (Electron: titkosított store; Web: in-memory + legacy localStorage) */
export async function clearPersistedToken(): Promise<void> {
  try {
    if (window.electronAPI) {
      if (window.electronAPI.secureClearToken) {
        await window.electronAPI.secureClearToken()
      } else {
        await window.electronAPI.deleteConfig('auth_token')
      }
      _electronTokenPresent = false
      return
    }

    // Audit P1.3: in-memory clear; legacy localStorage cleanup (P1.3 migracio)
    _webAccessToken = null
    try { window.localStorage.removeItem(WEB_AUTH_TOKEN_KEY) } catch { /* ignore */ }
    // Codex P2 #384: session hint flag clear, hogy a kovetkezo page-load-on
    // a `hasPersistedToken` false-t adjon -> az App restore flow NE blokkolodjon a
    // 15s refresh-cookie probe splash-en, ha a user kijelentkezett.
    try { window.localStorage.removeItem(WEB_SESSION_HINT_KEY) } catch { /* ignore */ }
  } catch (err) {
    logger.error('client', 'clearPersistedToken failed:', err)
    throw err
  }
}

/**
 * Token betöltése.
 *
 * <p>Electron: titkosított safeStorage-ből (változatlan).</p>
 * <p>Web (Audit P1.3): először az in-memory `_webAccessToken`-t adja vissza ha
 * letezik. Ha nincs (page reload eseten), megkiserli a `/auth/refresh-cookie`
 * endpointot — a HttpOnly refresh cookie alapjan szerez uj access tokent.
 * Sikertelen refresh eseten null-t ad vissza (user-nek be kell jelentkeznie).
 *
 * <p>Legacy migracio: ha localStorage-ban talalhato `auth_token`, azt **toroljuk**
 * (P1.3 fix: a localStorage-os tokenek mar nem hasznalhatok).</p>
 */
export async function loadPersistedToken(): Promise<string | null> {
  if (window.electronAPI) {
    const token: string | null = window.electronAPI.secureLoadToken
      ? await window.electronAPI.secureLoadToken()
      : await window.electronAPI.getConfig('auth_token')
    if (token) {
      const expired = isExpiredJwt(token)
      if (!expired) {
        _electronTokenPresent = true
        return token
      }

      const refreshedToken = await refreshAccessTokenFromCookie()
      if (refreshedToken) {
        try {
          await persistToken(refreshedToken)
        } catch (err) {
          logger.warn('client', 'Electron refreshed token persistence failed; using in-memory token for this startup', err)
        }
        _electronTokenPresent = true
        return refreshedToken
      }
      await clearPersistedToken()
    }

    _electronTokenPresent = false
    return null
  }

  // Audit P1.3: legacy localStorage cleanup — minden web user elso load-jakor
  try {
    if (window.localStorage.getItem(WEB_AUTH_TOKEN_KEY)) {
      window.localStorage.removeItem(WEB_AUTH_TOKEN_KEY)
      logger.info('client', 'Audit P1.3: legacy localStorage auth_token torolve (XSS-hardening)')
    }
  } catch { /* ignore (private mode browsers) */ }

  // Ha mar van in-memory token (login utan VAGY refresh-cookie sikeres volt), add vissza
  if (_webAccessToken) return _webAccessToken

  // Egyebkent megkiseroljuk a refresh-cookie-bol (HttpOnly cookie, JS NEM eri el)
  // Ha sikeres -> uj access tokent kapunk, in-memory mentjuk
  // Ha sikertelen -> null (user be kell jelentkezzen)
  const newToken = await refreshAccessTokenFromCookie()
  if (newToken) {
    _webAccessToken = newToken
    // Codex P2 #384: a sikeres refresh-cookie bizonyitja, hogy van session.
    // Frissitjuk a hint-et arra az esetre ha a localStorage uritodott (pl. private mode).
    try { window.localStorage.setItem(WEB_SESSION_HINT_KEY, '1') } catch { /* ignore */ }
    return newToken
  } else {
    // Refresh cookie hianyzik VAGY lejart — normalis ha a user nincs bejelentkezve.
    // Codex P2 #384: a hint-et toroljuk, hogy a kovetkezo page-load-on a hasPersistedToken
    // false-t adjon es az App splash-mentes login-ra menjen.
    try { window.localStorage.removeItem(WEB_SESSION_HINT_KEY) } catch { /* ignore */ }
  }
  return null
}

/**
 * Synchronous check for persisted token presence.
 *
 * <p>Electron mode: cached flag (set by persist/clear/load).</p>
 *
 * <p>Web mode (Audit P1.3 + Codex P2 follow-up #384, 2026-05-04):</p>
 * <ul>
 *   <li>true ha van in-memory `_webAccessToken` (mar lefutott egy login VAGY refresh-cookie bootstrap)</li>
 *   <li>true ha a `WEB_SESSION_HINT_KEY` localStorage hint jelzi, hogy korabban volt
 *       sikeres login (azaz valoszinu jelen van HttpOnly refresh cookie). Ekkor az
 *       App.tsx restore flow elinditja a `loadPersistedToken`-t, ami az async
 *       refresh-cookie-bol bootstrap-ol.</li>
 *   <li>false egyebkent (kijelentkezett vagy soha-nem-loggalt user). Ekkor az App
 *       AZONNAL renderel anelkul, hogy a 15s axios timeout splash-re varakozna —
 *       ez a Codex P2 #384 regression-fix.</li>
 * </ul>
 *
 * <p>A hint NEM token, csak egy boolean — XSS sem nyer vele semmit.</p>
 */
export function hasPersistedToken(): boolean {
  if (window.electronAPI) {
    return _electronTokenPresent ?? (window.electronAPI.secureLoadToken != null || window.electronAPI.getConfig != null)
  }

  if (_webAccessToken) return true
  try {
    return window.localStorage.getItem(WEB_SESSION_HINT_KEY) === '1'
  } catch {
    // Private mode browser — jobban jarunk false-szal (nincs splash regression)
    return false
  }
}
