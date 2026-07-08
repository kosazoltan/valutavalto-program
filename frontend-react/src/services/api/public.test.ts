import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from './client'
import { publicApi } from './public'

vi.mock('./client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
}

describe('publicApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('getGoogleConfigStatus calls GET /public/auth/google-config-status', async () => {
    mockApi.get.mockResolvedValue({
      data: {
        webConfigured: true,
        desktopConfigured: true,
        webPrefix: 'web-1234***',
        desktopPrefix: 'desk-123***',
        desktopPrefixes: ['desk-123***'],
        activeProfile: 'prod',
      },
    })

    const result = await publicApi.getGoogleConfigStatus()

    expect(mockApi.get).toHaveBeenCalledWith('/public/auth/google-config-status')
    expect(result.desktopConfigured).toBe(true)
  })

  it('identifyGoogleSetup calls POST /public/setup/google-identify with idempotency key', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        matchType: 'WORKER_EMAIL',
        requiresWorkerSelection: false,
        googleIdentity: {
          email: 'worker@example.test',
          googleSub: 'google-sub',
        },
        worker: {
          code: 'ADMIN',
          name: 'Admin Teszt',
        },
      },
    })

    const result = await publicApi.identifyGoogleSetup(
      {
        idToken: 'id-token',
        companyCode: 'EBC',
        appMode: 'ertektar',
        bindGoogleSubject: true,
      },
      { idempotencyKey: 'idem-1' },
    )

    expect(mockApi.post).toHaveBeenCalledWith(
      '/public/setup/google-identify',
      {
        idToken: 'id-token',
        companyCode: 'EBC',
        appMode: 'ertektar',
        bindGoogleSubject: true,
      },
      { headers: { 'Idempotency-Key': 'idem-1' } },
    )
    expect(result.worker?.code).toBe('ADMIN')
  })

  it('custom apiBase keeps the same public endpoint contract on installer-selected backend', async () => {
    mockApi.get.mockResolvedValue({
      data: {
        webConfigured: false,
        desktopConfigured: true,
        webPrefix: '',
        desktopPrefix: 'desk-123***',
        desktopPrefixes: ['desk-123***'],
        activeProfile: 'prod',
      },
    })

    await publicApi.getGoogleConfigStatus('https://excvaluta.com/api/v1')

    expect(mockApi.get).toHaveBeenCalledWith(
      'https://excvaluta.com/api/v1/public/auth/google-config-status',
    )
  })
})
