import { describe, it, expect, vi, beforeEach } from 'vitest'
import type { InternalAxiosRequestConfig } from 'axios'

// FK-016: a central-workstation flavorban a /branches GET-ekhez clientType=CENTRAL kerül.
// A request-interceptor handlert elkapjuk az axios.create mockból, majd közvetlenül hívjuk.
const { capturedRequestHandlers, flavorMock } = vi.hoisted(() => ({
  capturedRequestHandlers: [] as Array<
    (c: InternalAxiosRequestConfig) => InternalAxiosRequestConfig
  >,
  flavorMock: { isCentral: false },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: { getState: () => ({ token: null }) },
}))
vi.mock('../../components/ui/toaster', () => ({
  toast: { error: vi.fn(), warning: vi.fn(), success: vi.fn(), info: vi.fn() },
}))
vi.mock('../../utils/clientEnv', () => ({
  isCentralWorkstationFlavor: () => flavorMock.isCentral,
}))
vi.mock('axios', async () => {
  const actual = await vi.importActual<typeof import('axios')>('axios')
  return {
    ...actual,
    default: {
      ...actual.default,
      create: vi.fn(() => ({
        defaults: { baseURL: '/api/v1' },
        interceptors: {
          request: {
            use: vi.fn((fn: (c: InternalAxiosRequestConfig) => InternalAxiosRequestConfig) => {
              capturedRequestHandlers.push(fn)
            }),
          },
          response: { use: vi.fn() },
        },
        post: vi.fn(),
      })),
    },
  }
})

// Az import regisztrálja az interceptort (a fenti mock elkapja a handlert).
import './client'

const requestInterceptor = capturedRequestHandlers[0]

function run(config: Partial<InternalAxiosRequestConfig>): InternalAxiosRequestConfig {
  if (!requestInterceptor) throw new Error('A request-interceptor nem regisztrálódott')
  return requestInterceptor({ headers: {}, ...config } as InternalAxiosRequestConfig)
}

describe('FK-016 — client.ts request interceptor (clientType=CENTRAL)', () => {
  beforeEach(() => {
    flavorMock.isCentral = false
  })

  it('regisztrálódott egy request-interceptor', () => {
    expect(typeof requestInterceptor).toBe('function')
  })

  it('central flavorban a /branches GET-hez clientType=CENTRAL kerül (a meglévő paramok mellé)', () => {
    flavorMock.isCentral = true
    const out = run({ method: 'get', url: '/branches', params: { activeOnly: true } })
    expect(out.params).toMatchObject({ activeOnly: true, clientType: 'CENTRAL' })
  })

  it('central flavorban a /branches/my-territory GET-hez is bekerül', () => {
    flavorMock.isCentral = true
    const out = run({ method: 'get', url: '/branches/my-territory' })
    expect(out.params?.clientType).toBe('CENTRAL')
  })

  it('NEM-central flavorban (értéktári/pénztári) NEM kerül clientType', () => {
    flavorMock.isCentral = false
    const out = run({ method: 'get', url: '/branches' })
    expect(out.params?.clientType).toBeUndefined()
  })

  it('central flavorban is csak /branches útra (más endpointra nem)', () => {
    flavorMock.isCentral = true
    const out = run({ method: 'get', url: '/transactions' })
    expect(out.params?.clientType).toBeUndefined()
  })

  it('central flavorban POST /branches-re NEM kerül (csak GET listázás)', () => {
    flavorMock.isCentral = true
    const out = run({ method: 'post', url: '/branches' })
    expect(out.params?.clientType).toBeUndefined()
  })
})
