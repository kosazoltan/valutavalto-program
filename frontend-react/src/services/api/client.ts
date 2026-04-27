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

// Create axios instance
export const api = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,  // HttpOnly refresh cookie (vezerlokonyv par.12.3)
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
      // Login endpoint-ra ne próbáljunk refresh-t
      if (originalRequest.url?.includes('/auth/login')) {
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
        const response = await api.post<{ token: string }>('/auth/refresh')
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

    // Log error for debugging
    logger.error('client', 'API Error:', {
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status,
      message: error.message,
    })

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

// --- Electron token persist (ha Electron-ban fut) ---
//
// ACCESS TOKEN:
//   - Web: localStorage (XSS-expozicio, kompromisszum - a silent refresh
//     minden 24h-nal ujat ad, a backend token blacklist logout-kor torli)
//   - Electron: OS-level titkositas (safeStorage / DPAPI / Keychain)
//
// REFRESH TOKEN (vezerlokonyv par.12.3, 2026-04-20 implementacio):
//   - Web: HttpOnly Secure SameSite=Strict cookie, Path=/api/v1/auth,
//     MaxAge=7d. JS-bol NEM elerheto, silent refresh interceptor
//     automatikusan hasznalja (axios withCredentials: true).
//   - Electron: safeStorage tokentárolás mellett a cookie is rendelkezesre
//     all (ugyanaz a backend /auth/login endpoint adja ki).
//   - DB: refresh_token tabla, BCrypt-hashelt token_value, token rotation
//     minden refresh-kor (regi revoke, uj issue).

/** Cached Electron token presence — kept in sync by persist/clear/load. */
let _electronTokenPresent: boolean | null = null

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

    window.localStorage.setItem(WEB_AUTH_TOKEN_KEY, token)
  } catch (err) {
    logger.error('client', 'persistToken failed:', err)
    throw err
  }
}

/** Token törlése Electron-ból (titkosított + plaintext is) */
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

    window.localStorage.removeItem(WEB_AUTH_TOKEN_KEY)
  } catch (err) {
    logger.error('client', 'clearPersistedToken failed:', err)
    throw err
  }
}

/** Token betöltése Electron-ból — titkosított (safeStorage) elsőbbséggel */
export async function loadPersistedToken(): Promise<string | null> {
  if (window.electronAPI) {
    let token: string | null = null
    if (window.electronAPI.secureLoadToken) {
      token = await window.electronAPI.secureLoadToken()
    } else {
      token = await window.electronAPI.getConfig('auth_token')
    }
    _electronTokenPresent = Boolean(token)
    return token
  }

  return window.localStorage.getItem(WEB_AUTH_TOKEN_KEY)
}

/**
 * Synchronous check for persisted token presence.
 *
 * In Electron mode the actual storage is async, so this relies on a cached
 * flag updated by persistToken / clearPersistedToken / loadPersistedToken.
 * Before any of those have been called, the cache is unknown (`null`) and
 * we optimistically return `true` so the App-level restore flow runs.
 */
export function hasPersistedToken(): boolean {
  if (window.electronAPI) {
    return _electronTokenPresent ?? (window.electronAPI.secureLoadToken != null || window.electronAPI.getConfig != null)
  }

  return Boolean(window.localStorage.getItem(WEB_AUTH_TOKEN_KEY))
}
