import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, waitFor } from '@testing-library/react'
import { useAppMode } from './useAppMode'

// Mock isElectron
vi.mock('@/utils/electron', () => ({
  isElectron: vi.fn(() => false),
  getElectronAPI: vi.fn(() => null),
}))

// Also mock the relative path used internally
vi.mock('../utils/electron', () => ({
  isElectron: vi.fn(() => false),
  getElectronAPI: vi.fn(() => null),
}))

import { isElectron } from '../utils/electron'

const mockIsElectron = isElectron as ReturnType<typeof vi.fn>

describe('useAppMode', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Default: web browser mode
    mockIsElectron.mockReturnValue(false)
    // Clear window.electronAPI
    if ('electronAPI' in window) {
      delete (window as any).electronAPI
    }
  })

  it('returns mode="full" in browser (non-Electron)', async () => {
    const { result } = renderHook(() => useAppMode())

    expect(result.current.mode).toBe('full')
    expect(result.current.isLoading).toBe(false)
  })

  it('isLoading is false immediately in browser mode', () => {
    const { result } = renderHook(() => useAppMode())
    expect(result.current.isLoading).toBe(false)
  })

  it('returns mode="penztar" initially in Electron mode', async () => {
    mockIsElectron.mockReturnValue(true)
    ;(window as any).electronAPI = {
      getConfig: vi.fn().mockResolvedValue('penztar'),
    }

    const { result } = renderHook(() => useAppMode())

    // Initial state is penztar (Electron initializer)
    expect(result.current.mode).toBe('penztar')
    expect(result.current.isLoading).toBe(true)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.mode).toBe('penztar')

    delete (window as any).electronAPI
  })

  it('returns mode="ertektar" in Electron when config says so', async () => {
    mockIsElectron.mockReturnValue(true)
    ;(window as any).electronAPI = {
      getConfig: vi.fn().mockResolvedValue('ertektar'),
    }

    const { result } = renderHook(() => useAppMode())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.mode).toBe('ertektar')

    delete (window as any).electronAPI
  })

  it('returns mode="ertekszallito" in Electron when config says so', async () => {
    mockIsElectron.mockReturnValue(true)
    ;(window as any).electronAPI = {
      getConfig: vi.fn().mockResolvedValue('ertekszallito'),
    }

    const { result } = renderHook(() => useAppMode())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.mode).toBe('ertekszallito')

    delete (window as any).electronAPI
  })

  it('defaults to "penztar" in Electron when config returns unknown value', async () => {
    mockIsElectron.mockReturnValue(true)
    ;(window as any).electronAPI = {
      getConfig: vi.fn().mockResolvedValue('unknown_mode'),
    }

    const { result } = renderHook(() => useAppMode())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.mode).toBe('penztar')

    delete (window as any).electronAPI
  })

  it('defaults to "penztar" in Electron when getConfig throws', async () => {
    mockIsElectron.mockReturnValue(true)
    ;(window as any).electronAPI = {
      getConfig: vi.fn().mockRejectedValue(new Error('config error')),
    }

    const { result } = renderHook(() => useAppMode())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.mode).toBe('penztar')

    delete (window as any).electronAPI
  })

  it('defaults to "penztar" in Electron when getConfig returns null', async () => {
    mockIsElectron.mockReturnValue(true)
    ;(window as any).electronAPI = {
      getConfig: vi.fn().mockResolvedValue(null),
    }

    const { result } = renderHook(() => useAppMode())

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.mode).toBe('penztar')

    delete (window as any).electronAPI
  })
})
