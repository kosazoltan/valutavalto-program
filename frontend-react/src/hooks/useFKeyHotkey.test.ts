import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useFKeyHotkey, type FunctionKey } from './useFKeyHotkey'

/**
 * v2.3.59 TDD coverage gap fix — useFKeyHotkey unit test.
 *
 * Cel:
 * 1. F1-F12 union type-safe binding
 * 2. preventDefault() automatikusan hivodik
 * 3. callback meghivodik a hotkey lenyomasanal
 * 4. enableOnFormTags: true (form-input-okban is mukodik)
 *
 * Dependency: react-hotkeys-hook a `useHotkeys`-t ad. A test mock-olja
 * a useHotkeys-t es ellenorzi a parameter-eket.
 */

const mockUseHotkeys = vi.hoisted(() => vi.fn())

vi.mock('react-hotkeys-hook', () => ({
  useHotkeys: mockUseHotkeys,
}))

describe('useFKeyHotkey', () => {
  beforeEach(() => {
    mockUseHotkeys.mockClear()
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('regisztralja a useHotkeys-t a megadott key-jel', () => {
    const callback = vi.fn()
    renderHook(() => useFKeyHotkey('f1', callback))
    expect(mockUseHotkeys).toHaveBeenCalledTimes(1)
    expect(mockUseHotkeys.mock.calls[0]?.[0]).toBe('f1')
  })

  it('a callback wrapper hivja preventDefault()-et az event-en', () => {
    const callback = vi.fn()
    renderHook(() => useFKeyHotkey('f5', callback))
    const wrapper = mockUseHotkeys.mock.calls[0]?.[1] as (e: KeyboardEvent) => void

    const event = { preventDefault: vi.fn() } as unknown as KeyboardEvent
    wrapper(event)

    expect(event.preventDefault).toHaveBeenCalledTimes(1)
    expect(callback).toHaveBeenCalledTimes(1)
  })

  it('options { enableOnFormTags: true } passzolva', () => {
    renderHook(() => useFKeyHotkey('f3', vi.fn()))
    const options = mockUseHotkeys.mock.calls[0]?.[2] as Record<string, boolean>
    expect(options).toMatchObject({ enableOnFormTags: true })
  })

  it('a callback wrapper NEM kapja meg az event-et (nincs leak)', () => {
    const callback = vi.fn()
    renderHook(() => useFKeyHotkey('f7', callback))
    const wrapper = mockUseHotkeys.mock.calls[0]?.[1] as (e: KeyboardEvent) => void

    const event = { preventDefault: vi.fn() } as unknown as KeyboardEvent
    wrapper(event)

    // A callback NEM kapja meg az event-et — clean abstraction
    expect(callback).toHaveBeenCalledWith()
    expect(callback).not.toHaveBeenCalledWith(event)
  })

  it('minden F1-F12 key elfogadhato a FunctionKey union-altal', () => {
    const keys: FunctionKey[] = [
      'f1', 'f2', 'f3', 'f4', 'f5', 'f6',
      'f7', 'f8', 'f9', 'f10', 'f11', 'f12',
    ]
    keys.forEach((key) => {
      mockUseHotkeys.mockClear()
      renderHook(() => useFKeyHotkey(key, vi.fn()))
      expect(mockUseHotkeys.mock.calls[0]?.[0]).toBe(key)
    })
  })

  it('multiple useFKeyHotkey hivasok mind regisztralva', () => {
    renderHook(() => {
      useFKeyHotkey('f1', vi.fn())
      useFKeyHotkey('f2', vi.fn())
      useFKeyHotkey('f5', vi.fn())
    })
    expect(mockUseHotkeys).toHaveBeenCalledTimes(3)
    expect(mockUseHotkeys.mock.calls[0]?.[0]).toBe('f1')
    expect(mockUseHotkeys.mock.calls[1]?.[0]).toBe('f2')
    expect(mockUseHotkeys.mock.calls[2]?.[0]).toBe('f5')
  })
})
