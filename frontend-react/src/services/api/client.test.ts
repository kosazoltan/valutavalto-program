import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// Mock useAuthStore to avoid zustand setup complexity in unit tests
vi.mock('../../stores/authStore', () => ({
  useAuthStore: {
    getState: vi.fn(() => ({
      token: null,
      worker: null,
      tokenType: null,
      expiresAt: null,
      activeRole: null,
      permissions: [],
      roles: [],
      login: vi.fn(),
      logout: vi.fn(),
    })),
  },
}))

// Mock toaster
vi.mock('../../components/ui/toaster', () => ({
  toast: { error: vi.fn(), success: vi.fn() },
}))

// Mock the axios instance used by client.ts (api.post for refresh-cookie bootstrap).
// vi.mock is hoisted to the top of the file BEFORE imports, so the mockPost reference
// must also be hoisted via vi.hoisted to avoid TDZ errors at module-load-time.
const { mockPost } = vi.hoisted(() => ({ mockPost: vi.fn() }))
vi.mock('axios', async () => {
  const actual = await vi.importActual<typeof import('axios')>('axios')
  return {
    ...actual,
    default: {
      ...actual.default,
      create: vi.fn(() => ({
        defaults: { baseURL: '/api/v1' },
        interceptors: {
          request: { use: vi.fn() },
          response: { use: vi.fn() },
        },
        post: mockPost,
      })),
    },
  }
})

// Now import the module under test (after the axios mock)
import { persistToken, clearPersistedToken, loadPersistedToken, hasPersistedToken, REFRESH_ENDPOINT } from './client'

describe('persistToken / clearPersistedToken / loadPersistedToken / hasPersistedToken (Audit P1.3)', () => {
  beforeEach(async () => {
    if ('electronAPI' in window) {
      delete (window as any).electronAPI
    }
    localStorage.clear()
    mockPost.mockReset()
    // Clear in-memory web token between tests by simulating clearPersistedToken
    // (test isolation: each test starts with no in-memory token)
    await clearPersistedToken()
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
  })

  describe('Audit P1.3 — web in-memory access token (XSS hardening)', () => {
    it('persistToken does NOT write to localStorage in web mode', async () => {
      await persistToken('my-token-123')
      expect(localStorage.getItem('auth_token')).toBeNull()
    })

    it('loadPersistedToken returns the in-memory token after persistToken', async () => {
      await persistToken('memory-token')
      const result = await loadPersistedToken()
      expect(result).toBe('memory-token')
      // Refresh-cookie endpoint must NOT be called when in-memory token exists
      expect(mockPost).not.toHaveBeenCalled()
    })

    it('clearPersistedToken removes the in-memory token (loadPersistedToken returns null)', async () => {
      await persistToken('to-be-cleared')
      await clearPersistedToken()
      // After clear, refresh-cookie call will be attempted; mock it as 401-like failure
      mockPost.mockRejectedValueOnce(new Error('Unauthorized'))
      const result = await loadPersistedToken()
      expect(result).toBeNull()
    })

    it('clearPersistedToken also removes legacy localStorage auth_token (P1.3 migration)', async () => {
      localStorage.setItem('auth_token', 'legacy-token')
      await clearPersistedToken()
      expect(localStorage.getItem('auth_token')).toBeNull()
    })

    it('loadPersistedToken triggers legacy localStorage cleanup on every web call', async () => {
      localStorage.setItem('auth_token', 'legacy-from-pre-p1.3')
      mockPost.mockRejectedValueOnce(new Error('No refresh cookie'))
      await loadPersistedToken()
      // Legacy localStorage entry MUST be wiped
      expect(localStorage.getItem('auth_token')).toBeNull()
    })

    it('loadPersistedToken bootstraps from refresh-cookie when in-memory empty', async () => {
      mockPost.mockResolvedValueOnce({ data: { token: 'cookie-bootstrapped-token' } })
      const result = await loadPersistedToken()
      expect(mockPost).toHaveBeenCalledWith(REFRESH_ENDPOINT, undefined, { withCredentials: true })
      expect(result).toBe('cookie-bootstrapped-token')
    })

    it('loadPersistedToken caches refresh-cookie result in-memory (no second network call)', async () => {
      mockPost.mockResolvedValueOnce({ data: { token: 'first-bootstrap' } })
      await loadPersistedToken()
      // Second call: should return cached in-memory token, NOT trigger another POST
      const second = await loadPersistedToken()
      expect(second).toBe('first-bootstrap')
      expect(mockPost).toHaveBeenCalledTimes(1)
    })

    it('loadPersistedToken returns null when refresh-cookie endpoint fails (no cookie / expired)', async () => {
      mockPost.mockRejectedValueOnce(new Error('401 Unauthorized'))
      const result = await loadPersistedToken()
      expect(result).toBeNull()
    })

    it('loadPersistedToken returns null when refresh-cookie response lacks token field', async () => {
      mockPost.mockResolvedValueOnce({ data: {} })
      const result = await loadPersistedToken()
      expect(result).toBeNull()
    })

    it('hasPersistedToken returns FALSE on first visit (no in-memory, no session hint) — Codex P2 #384', () => {
      // Codex P2 follow-up: a regi viselkedes (mindig true) blokkolta a logged-out
      // user-eket a 15s refresh-cookie probe splash-en. Most: false, App AZONNAL renderel.
      expect(hasPersistedToken()).toBe(false)
    })

    it('hasPersistedToken returns TRUE after persistToken (session hint set)', async () => {
      await persistToken('after-login-token')
      expect(hasPersistedToken()).toBe(true)
    })

    it('hasPersistedToken returns TRUE if session hint exists from prior session', () => {
      // Page reload utan az in-memory empty, de a hint a localStorage-ban marad.
      window.localStorage.setItem('has_login_session', '1')
      expect(hasPersistedToken()).toBe(true)
    })

    it('hasPersistedToken returns FALSE after clearPersistedToken (logout)', async () => {
      await persistToken('logged-in')
      expect(hasPersistedToken()).toBe(true)
      await clearPersistedToken()
      expect(hasPersistedToken()).toBe(false)
    })

    it('successful refresh-cookie bootstrap restores session hint', async () => {
      mockPost.mockResolvedValueOnce({ data: { token: 'restored' } })
      await loadPersistedToken()
      expect(window.localStorage.getItem('has_login_session')).toBe('1')
    })

    it('failed refresh-cookie bootstrap clears session hint', async () => {
      window.localStorage.setItem('has_login_session', '1')
      mockPost.mockRejectedValueOnce(new Error('401'))
      await loadPersistedToken()
      expect(window.localStorage.getItem('has_login_session')).toBeNull()
    })
  })

  describe('with mock electronAPI', () => {
    beforeEach(() => {
      (window as any).electronAPI = {
        setConfig: vi.fn().mockResolvedValue(undefined),
        deleteConfig: vi.fn().mockResolvedValue(undefined),
        getConfig: vi.fn().mockResolvedValue('electron-token'),
      }
    })

    afterEach(() => {
      delete (window as any).electronAPI
    })

    it('persistToken uses setConfig in Electron', async () => {
      await persistToken('electron-tok')
      expect(window.electronAPI?.setConfig).toHaveBeenCalledWith('auth_token', 'electron-tok')
    })

    it('clearPersistedToken uses deleteConfig in Electron', async () => {
      await clearPersistedToken()
      expect(window.electronAPI?.deleteConfig).toHaveBeenCalledWith('auth_token')
    })

    it('loadPersistedToken uses getConfig in Electron', async () => {
      const result = await loadPersistedToken()
      expect(window.electronAPI?.getConfig).toHaveBeenCalledWith('auth_token')
      expect(result).toBe('electron-token')
    })

    it('hasPersistedToken returns true when getConfig capability exists', () => {
      expect(hasPersistedToken()).toBe(true)
    })

    it('hasPersistedToken returns false after clearPersistedToken', async () => {
      await persistToken('electron-tok')
      expect(hasPersistedToken()).toBe(true)
      await clearPersistedToken()
      expect(hasPersistedToken()).toBe(false)
    })

    it('hasPersistedToken reflects loadPersistedToken result', async () => {
      ;(window as any).electronAPI.getConfig = vi.fn().mockResolvedValue(null)
      await loadPersistedToken()
      expect(hasPersistedToken()).toBe(false)
    })
  })
})

describe('REFRESH_ENDPOINT (P0.1 audit fix, 2026-05-03)', () => {
  it('points to /auth/refresh-cookie (NOT /auth/refresh)', () => {
    // Bizonyitek-alapu teszt: a backend `/auth/refresh` endpoint
    // `@PreAuthorize("isAuthenticated()")`, ezert lejart access tokennel 401-et ad
    // es nem alkalmas silent refresh-re. A helyes endpoint a `permitAll` /refresh-cookie,
    // amely a HttpOnly refreshToken cookie alapjan ad uj access tokent.
    expect(REFRESH_ENDPOINT).toBe('/auth/refresh-cookie')
  })

  it('does NOT point to the legacy /auth/refresh endpoint', () => {
    // Regressziovedelem: ne csusszunk vissza a regi (auth-required) endpointra.
    expect(REFRESH_ENDPOINT).not.toBe('/auth/refresh')
  })
})
