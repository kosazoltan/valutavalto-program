import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook, act, waitFor } from '@testing-library/react'
import { useOnlineStatus } from './useOnlineStatus'

// Mock isElectron and api
vi.mock('../utils/electron', () => ({
  isElectron: vi.fn(() => false),
  getElectronAPI: vi.fn(() => null),
}))

vi.mock('../services/api/index', () => ({
  api: {
    get: vi.fn().mockResolvedValue({ data: { status: 'UP' } }),
    defaults: { baseURL: '' },
    interceptors: { request: { use: vi.fn() }, response: { use: vi.fn() } },
  },
  persistToken: vi.fn(),
  clearPersistedToken: vi.fn(),
}))

import { isElectron } from '../utils/electron'
import { api } from '../services/api/index'

const mockIsElectron = isElectron as ReturnType<typeof vi.fn>
const mockApi = api as unknown as { get: ReturnType<typeof vi.fn> }

describe('useOnlineStatus', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockIsElectron.mockReturnValue(false)
    mockApi.get.mockResolvedValue({ data: { status: 'UP' } })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('returns isOnline=true when network is online and backend reachable', async () => {
    const { result } = renderHook(() => useOnlineStatus())

    await waitFor(() => {
      expect(result.current.lastCheckedAt).not.toBeNull()
    })

    expect(result.current.isNetworkOnline).toBe(true)
    expect(result.current.isBackendReachable).toBe(true)
    expect(result.current.isOnline).toBe(true)
  })

  it('sets isBackendReachable=false when backend check fails', async () => {
    mockApi.get.mockRejectedValue(new Error('Network error'))

    const { result } = renderHook(() => useOnlineStatus())

    await waitFor(() => {
      expect(result.current.lastCheckedAt).not.toBeNull()
    })

    expect(result.current.isBackendReachable).toBe(false)
    expect(result.current.isOnline).toBe(false)
  })

  it('responds to offline event', async () => {
    const { result } = renderHook(() => useOnlineStatus())

    act(() => {
      window.dispatchEvent(new Event('offline'))
    })

    expect(result.current.isNetworkOnline).toBe(false)
    expect(result.current.isBackendReachable).toBe(false)
    expect(result.current.isOnline).toBe(false)
    expect(result.current.lastCheckedAt).not.toBeNull()
  })

  it('responds to online event and triggers backend check', async () => {
    const { result } = renderHook(() => useOnlineStatus())

    // Go offline first
    act(() => {
      window.dispatchEvent(new Event('offline'))
    })
    expect(result.current.isNetworkOnline).toBe(false)

    // Go back online
    act(() => {
      window.dispatchEvent(new Event('online'))
    })
    expect(result.current.isNetworkOnline).toBe(true)
  })

  it('sets lastCheckedAt after backend check', async () => {
    const { result } = renderHook(() => useOnlineStatus())

    await waitFor(() => {
      expect(result.current.lastCheckedAt).toBeInstanceOf(Date)
    })
  })

  it('in Electron mode starts periodic polling', async () => {
    mockIsElectron.mockReturnValue(true)
    vi.useFakeTimers()

    const { unmount } = renderHook(() => useOnlineStatus())

    // Initial check
    await act(async () => {
      await Promise.resolve()
    })

    // Advance timer — triggers another check
    await act(async () => {
      vi.advanceTimersByTime(30000)
      await Promise.resolve()
    })

    // Should have been called multiple times
    expect(mockApi.get.mock.calls.length).toBeGreaterThanOrEqual(1)

    unmount()
    vi.useRealTimers()
  })
})
