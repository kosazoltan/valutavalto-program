import { renderHook, act } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { useIdentificationLevel } from './useIdentificationLevel'

describe('useIdentificationLevel', () => {
  describe('AML küszöbértékek (2017. évi LIII. tv. 7.§)', () => {
    it('0 Ft → SIMPLE', () => {
      const { result } = renderHook(() => useIdentificationLevel('0'))
      expect(result.current.minimumLevel).toBe('SIMPLE')
      expect(result.current.identificationLevel).toBe('SIMPLE')
    })

    it('99 999 Ft → SIMPLE', () => {
      const { result } = renderHook(() => useIdentificationLevel('99999'))
      expect(result.current.minimumLevel).toBe('SIMPLE')
    })

    it('100 000 Ft → SIMPLIFIED', () => {
      const { result } = renderHook(() => useIdentificationLevel('100000'))
      expect(result.current.minimumLevel).toBe('SIMPLIFIED')
      expect(result.current.identificationLevel).toBe('SIMPLIFIED')
    })

    it('299 999 Ft → SIMPLIFIED', () => {
      const { result } = renderHook(() => useIdentificationLevel('299999'))
      expect(result.current.minimumLevel).toBe('SIMPLIFIED')
    })

    it('300 000 Ft → FULL', () => {
      const { result } = renderHook(() => useIdentificationLevel('300000'))
      expect(result.current.minimumLevel).toBe('FULL')
      expect(result.current.identificationLevel).toBe('FULL')
    })

    it('1 000 000 Ft → FULL', () => {
      const { result } = renderHook(() => useIdentificationLevel('1000000'))
      expect(result.current.minimumLevel).toBe('FULL')
    })

    it('üres string → SIMPLE (0 Ft)', () => {
      const { result } = renderHook(() => useIdentificationLevel(''))
      expect(result.current.minimumLevel).toBe('SIMPLE')
    })

    it('érvénytelen string → SIMPLE (NaN → 0)', () => {
      const { result } = renderHook(() => useIdentificationLevel('abc'))
      expect(result.current.minimumLevel).toBe('SIMPLE')
    })

    it('szóközöket tartalmaz → helyes parse ("100 000" → SIMPLIFIED)', () => {
      const { result } = renderHook(() => useIdentificationLevel('100 000'))
      expect(result.current.minimumLevel).toBe('SIMPLIFIED')
    })

    it('vesszős tizedes → helyes parse ("299999,99" → SIMPLIFIED)', () => {
      const { result } = renderHook(() => useIdentificationLevel('299999,99'))
      expect(result.current.minimumLevel).toBe('SIMPLIFIED')
    })
  })

  describe('forrásgazdagodás ellenőrzés (3.5M küszöb)', () => {
    it('3 499 999 Ft → requiresSourceVerification = false', () => {
      const { result } = renderHook(() => useIdentificationLevel('3499999'))
      expect(result.current.requiresSourceVerification).toBe(false)
    })

    it('3 500 000 Ft → requiresSourceVerification = true', () => {
      const { result } = renderHook(() => useIdentificationLevel('3500000'))
      expect(result.current.requiresSourceVerification).toBe(true)
    })

    it('10 000 000 Ft → requiresSourceVerification = true', () => {
      const { result } = renderHook(() => useIdentificationLevel('10000000'))
      expect(result.current.requiresSourceVerification).toBe(true)
    })
  })

  describe('szint választás logika', () => {
    it('SIMPLE minimum → felhasználó FULL-ra emelheti', () => {
      const { result } = renderHook(() => useIdentificationLevel('50000'))
      expect(result.current.minimumLevel).toBe('SIMPLE')

      act(() => {
        result.current.setIdentificationLevel('FULL')
      })
      expect(result.current.identificationLevel).toBe('FULL')
    })

    it('SIMPLIFIED minimum → felhasználó nem alacsonyíthat SIMPLE-re', () => {
      const { result } = renderHook(() => useIdentificationLevel('150000'))
      expect(result.current.minimumLevel).toBe('SIMPLIFIED')

      act(() => {
        result.current.setIdentificationLevel('SIMPLE')
      })
      expect(result.current.identificationLevel).toBe('SIMPLIFIED')
    })

    it('FULL minimum → felhasználó nem alacsonyíthat', () => {
      const { result } = renderHook(() => useIdentificationLevel('500000'))
      expect(result.current.minimumLevel).toBe('FULL')

      act(() => {
        result.current.setIdentificationLevel('SIMPLE')
      })
      expect(result.current.identificationLevel).toBe('FULL')

      act(() => {
        result.current.setIdentificationLevel('SIMPLIFIED')
      })
      expect(result.current.identificationLevel).toBe('FULL')
    })

    it('összeg csökkenésekor a kiválasztott szint megmarad, ha magasabb mint az új minimum', () => {
      const { result, rerender } = renderHook(({ amount }) => useIdentificationLevel(amount), {
        initialProps: { amount: '500000' },
      })
      expect(result.current.identificationLevel).toBe('FULL')

      rerender({ amount: '50000' })
      expect(result.current.minimumLevel).toBe('SIMPLE')
      expect(result.current.identificationLevel).toBe('FULL')
    })

    it('összeg növekedésekor az alacsony szint automatikusan felemelkedik', () => {
      const { result, rerender } = renderHook(({ amount }) => useIdentificationLevel(amount), {
        initialProps: { amount: '50000' },
      })
      expect(result.current.identificationLevel).toBe('SIMPLE')

      rerender({ amount: '150000' })
      expect(result.current.identificationLevel).toBe('SIMPLIFIED')

      rerender({ amount: '500000' })
      expect(result.current.identificationLevel).toBe('FULL')
    })
  })
})
