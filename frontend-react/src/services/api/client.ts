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
    // Electron production — SQLite-ból olvassa a server_url-t, fallback a prod szerverre
    API_BASE_URL = 'https://excvaluta.com/api/v1'
    // Aszinkron felülírás: ha SQLite-ban van beállítva server_url, használjuk azt
    window.electronAPI.getConfig?.('server_url').then((url: string | null) => {
      if (url) {
        const normalized = url.endsWith('/api/v1') ? url : `${url.replace(/\/$/, '')}/api/v1`
        api.defaults.baseURL = normalized
      }
    }).catch(() => { /* SQLite nem elérhető — marad a default */ })
  } else {
    // Webes production — relatív URL (proxy mögött) vagy env var kötelező
    API_BASE_URL = '/api/v1'
  }
}

// Create axios instance
export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor - add auth token + Idempotency-Key for write requests
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = useAuthStore.getState().token
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }
    // Idempotency-Key header for write methods (required by backend IdempotencyFilter)
    const method = (config.method ?? '').toUpperCase()
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method) && config.headers && !config.headers['Idempotency-Key']) {
      config.headers['Idempotency-Key'] = crypto.randomUUID()
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

/** Token mentése Electron-ban — DPAPI/Keychain titkosítással (ha elérhető) */
export async function persistToken(token: string): Promise<void> {
  try {
    if (window.electronAPI) {
      // Titkosított tárolás (safeStorage) — fallback: config store
      if (window.electronAPI.secureStoreToken) {
        await window.electronAPI.secureStoreToken(token)
      } else {
        await window.electronAPI.setConfig('auth_token', token)
      }
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
    if (window.electronAPI.secureLoadToken) {
      return window.electronAPI.secureLoadToken()
    }
    return window.electronAPI.getConfig('auth_token')
  }

  return window.localStorage.getItem(WEB_AUTH_TOKEN_KEY)
}

export function hasPersistedToken(): boolean {
  if (window.electronAPI) {
    return true
  }

  return Boolean(window.localStorage.getItem(WEB_AUTH_TOKEN_KEY))
}
