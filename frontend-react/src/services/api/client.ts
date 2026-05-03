import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '../../stores/authStore'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger';

// Extend AxiosRequestConfig to support _skipGlobal403Toast flag
declare module 'axios' {
  interface AxiosRequestConfig {
    _skipGlobal403Toast?: boolean
  }
  interface InternalAxiosRequestConfig {
    _skipGlobal403Toast?: boolean
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
const AXIOS_GLOBAL_TIMEOUT_MS = 15_000

// Create axios instance
export const api = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,  // HttpOnly refresh cookie (vezerlokonyv par.12.3)
  timeout: AXIOS_GLOBAL_TIMEOUT_MS,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor - add auth token + Idempotency-Key for write requests
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const {token} = useAuthStore.getState()
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
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
    const preservePaged = (response.config as unknown as Record<string, unknown>)?._preservePaged === true
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
            authStore.activeRole, authStore.permissions, authStore.roles)
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
    _electronTokenPresent = Boolean(token)
    return token
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
  try {
    const res = await api.post(REFRESH_ENDPOINT, undefined, { withCredentials: true })
    const newToken = res?.data?.token
    if (typeof newToken === 'string' && newToken) {
      _webAccessToken = newToken
      // Codex P2 #384: a sikeres refresh-cookie bizonyitja, hogy van session.
      // Frissitjuk a hint-et arra az esetre ha a localStorage uritodott (pl. private mode).
      try { window.localStorage.setItem(WEB_SESSION_HINT_KEY, '1') } catch { /* ignore */ }
      return newToken
    }
  } catch (err) {
    // Refresh cookie hianyzik VAGY lejart — normalis ha a user nincs bejelentkezve.
    // Codex P2 #384: a hint-et toroljuk, hogy a kovetkezo page-load-on a hasPersistedToken
    // false-t adjon es az App splash-mentes login-ra menjen.
    try { window.localStorage.removeItem(WEB_SESSION_HINT_KEY) } catch { /* ignore */ }
    logger.debug('client', 'loadPersistedToken: refresh-cookie unavailable (user not logged in)', err)
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
