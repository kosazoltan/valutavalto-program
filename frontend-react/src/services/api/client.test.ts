import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { persistToken, clearPersistedToken, loadPersistedToken, hasPersistedToken, REFRESH_ENDPOINT } from './client'

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

describe('persistToken / clearPersistedToken / loadPersistedToken / hasPersistedToken', () => {
  beforeEach(() => {
    // Ensure no electronAPI
    if ('electronAPI' in window) {
      delete (window as any).electronAPI
    }
    localStorage.clear()
  })

  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
  })

  describe('persistToken', () => {
    it('writes token to localStorage in web mode', async () => {
      await persistToken('my-token-123')
      expect(localStorage.getItem('auth_token')).toBe('my-token-123')
    })
  })

  describe('clearPersistedToken', () => {
    it('removes token from localStorage', async () => {
      localStorage.setItem('auth_token', 'some-token')
      await clearPersistedToken()
      expect(localStorage.getItem('auth_token')).toBeNull()
    })
  })

  describe('loadPersistedToken', () => {
    it('returns null when no token stored', async () => {
      const result = await loadPersistedToken()
      expect(result).toBeNull()
    })

    it('returns token from localStorage', async () => {
      localStorage.setItem('auth_token', 'stored-token')
      const result = await loadPersistedToken()
      expect(result).toBe('stored-token')
    })
  })

  describe('hasPersistedToken', () => {
    it('returns false when no token', () => {
      expect(hasPersistedToken()).toBe(false)
    })

    it('returns true when token exists in localStorage', () => {
      localStorage.setItem('auth_token', 'tok')
      expect(hasPersistedToken()).toBe(true)
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
