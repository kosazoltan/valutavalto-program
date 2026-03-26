import { describe, it, expect, vi, beforeEach } from 'vitest'
import { authApi } from './auth'
import { api } from './client'

vi.mock('./client', () => {
  const mockApi = {
    post: vi.fn(),
    get: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    defaults: { baseURL: '' },
    interceptors: {
      request: { use: vi.fn() },
      response: { use: vi.fn() },
    },
  }
  return { api: mockApi }
})

const mockApi = api as unknown as {
  post: ReturnType<typeof vi.fn>
  get: ReturnType<typeof vi.fn>
}

describe('authApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('login', () => {
    it('calls POST /auth/login and returns data', async () => {
      const responseData = {
        token: 'test-token',
        tokenType: 'Bearer',
        expiresAt: '2025-01-01T00:00:00Z',
        worker: {
          id: 1,
          workerCode: 'W001',
          firstName: 'Test',
          lastName: 'User',
          fullName: 'Test User',
          role: 'CASHIER',
          branchId: 'b1',
          branchCode: '001',
          branchName: 'Pécs',
          companyId: 'c1',
          companyCode: 'EBC',
          companyName: 'EBC Zrt.',
        },
      }
      mockApi.post.mockResolvedValue({ data: responseData })

      const result = await authApi.login({
        companyCode: 'EBC',
        workerCode: 'W001',
        password: 'secret',
      })

      expect(mockApi.post).toHaveBeenCalledWith('/auth/login', {
        companyCode: 'EBC',
        workerCode: 'W001',
        password: 'secret',
      })
      expect(result.token).toBe('test-token')
      expect(result.worker.id).toBe(1)
    })
  })

  describe('googleLogin', () => {
    it('calls POST /auth/google-login', async () => {
      const responseData = { token: 'google-token', tokenType: 'Bearer', expiresAt: '', worker: {} }
      mockApi.post.mockResolvedValue({ data: responseData })

      const result = await authApi.googleLogin({ idToken: 'id_tok' })
      expect(mockApi.post).toHaveBeenCalledWith('/auth/google-login', { idToken: 'id_tok' })
      expect(result.token).toBe('google-token')
    })
  })

  describe('logout', () => {
    it('calls POST /auth/logout', async () => {
      mockApi.post.mockResolvedValue({ data: {} })
      await authApi.logout()
      expect(mockApi.post).toHaveBeenCalledWith('/auth/logout')
    })
  })

  describe('refreshToken', () => {
    it('calls POST /auth/refresh and returns token', async () => {
      mockApi.post.mockResolvedValue({ data: { token: 'refreshed' } })
      const result = await authApi.refreshToken()
      expect(mockApi.post).toHaveBeenCalledWith('/auth/refresh')
      expect(result.token).toBe('refreshed')
    })
  })

  describe('selectRole', () => {
    it('calls POST /auth/login/select-role', async () => {
      const responseData = { token: 'new-token', tokenType: 'Bearer', expiresAt: '', worker: {} }
      mockApi.post.mockResolvedValue({ data: responseData })

      const result = await authApi.selectRole({ token: 'old-token', roleCode: 'MANAGER' })
      expect(mockApi.post).toHaveBeenCalledWith('/auth/login/select-role', {
        token: 'old-token',
        roleCode: 'MANAGER',
      })
      expect(result.token).toBe('new-token')
    })
  })
})
