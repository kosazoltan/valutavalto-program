import { describe, it, expect, beforeEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useGridNavigation } from './useGridNavigation'

describe('useGridNavigation', () => {
  it('initializes with no active cell and not editing', () => {
    const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 4 }))
    expect(result.current.activeCell).toBeNull()
    expect(result.current.editing).toBe(false)
    expect(result.current.containerRef.current).toBeNull()
  })

  it('getCellProps returns correct data attributes and onFocus', () => {
    const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 4 }))
    const props = result.current.getCellProps(1, 2)
    expect(props['data-grid-row']).toBe(1)
    expect(props['data-grid-col']).toBe(2)
    expect(typeof props.onFocus).toBe('function')
  })

  it('onCellFocus sets active cell and editing (örökölt alapértelmezés: editOnFocus=true)', () => {
    const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 4 }))
    act(() => {
      result.current.onCellFocus(2, 1)
    })
    expect(result.current.activeCell).toEqual({ row: 2, col: 1 })
    expect(result.current.editing).toBe(true)
  })

  it('FK03 FR-1/FR-2: editOnFocus=false → fókusz/kattintás csak kijelöl, NEM lép szerkesztő módba', () => {
    const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 4, editOnFocus: false }))
    act(() => {
      result.current.onCellFocus(2, 1)
    })
    expect(result.current.activeCell).toEqual({ row: 2, col: 1 })
    expect(result.current.editing).toBe(false)
  })

  describe('focusCell with DOM', () => {
    let container: HTMLDivElement

    beforeEach(() => {
      container = document.createElement('div')
      document.body.appendChild(container)

      // Create a 3x3 grid of inputs
      for (let r = 0; r < 3; r++) {
        for (let c = 0; c < 3; c++) {
          const input = document.createElement('input')
          input.setAttribute('data-grid-row', String(r))
          input.setAttribute('data-grid-col', String(c))
          input.value = `r${r}c${c}`
          container.appendChild(input)
        }
      }
    })

    it('focusCell focuses the correct input', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      // Manually attach containerRef
      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(1, 2)
      })

      expect(result.current.activeCell).toEqual({ row: 1, col: 2 })
      expect(result.current.editing).toBe(false)

      const focused = container.querySelector<HTMLInputElement>('[data-grid-row="1"][data-grid-col="2"]')
      expect(document.activeElement).toBe(focused)
    })

    it('focusCell with startEditing=true selects input content', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(0, 0, true)
      })

      expect(result.current.editing).toBe(true)
      const input = container.querySelector<HTMLInputElement>('[data-grid-row="0"][data-grid-col="0"]')
      expect(document.activeElement).toBe(input)
    })

    it('focusCell clamps out-of-range row/col', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(10, -1)
      })

      // Clamped to (2, 0)
      expect(result.current.activeCell).toEqual({ row: 2, col: 0 })
    })

    /** Helper: dispatch keydown from the currently focused grid-cell input */
    const dispatchKey = (key: string, opts: Partial<KeyboardEventInit> = {}) => {
      const active = document.activeElement as HTMLElement | null
      const target = active?.hasAttribute('data-grid-row') ? active : container
      const event = new KeyboardEvent('keydown', { key, bubbles: true, ...opts })
      target.dispatchEvent(event)
    }

    it('keyboard ArrowDown moves focus down', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(0, 0)
      })

      act(() => dispatchKey('ArrowDown'))

      expect(result.current.activeCell).toEqual({ row: 1, col: 0 })
    })

    it('keyboard ArrowRight moves focus right when not editing', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(0, 0)
      })

      act(() => dispatchKey('ArrowRight'))

      expect(result.current.activeCell).toEqual({ row: 0, col: 1 })
    })

    it('keyboard Enter toggles edit mode', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      // Start at (0,0) not editing
      act(() => {
        result.current.focusCell(0, 0)
      })
      expect(result.current.editing).toBe(false)

      // Enter -> editing
      act(() => dispatchKey('Enter'))
      expect(result.current.editing).toBe(true)

      // Enter again -> move down
      act(() => dispatchKey('Enter'))
      expect(result.current.activeCell).toEqual({ row: 1, col: 0 })
    })

    it('keyboard Escape exits edit mode', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(1, 1, true)
      })
      expect(result.current.editing).toBe(true)

      act(() => dispatchKey('Escape'))
      expect(result.current.editing).toBe(false)
    })

    it('FK03 FR-5: arrow_key_does_not_set_editing_true — nyilas lépés után sincs szerkesztő mód (editOnFocus=false)', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3, editOnFocus: false }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(0, 0)
      })
      act(() => dispatchKey('ArrowDown'))

      expect(result.current.activeCell).toEqual({ row: 1, col: 0 })
      expect(result.current.editing).toBe(false)
    })

    it('FK03 FR-5: escape_sets_isEscaping_ref_before_blur — az onBlur megkülönböztetheti az Escape-blurt', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3, editOnFocus: false }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      // Blur-pillanatban olvassuk a ref-et — pontosan így használja a RateGrid onBlur-ja.
      let refAtBlur: boolean | null = null
      const input = container.querySelector<HTMLInputElement>('[data-grid-row="1"][data-grid-col="1"]')!
      input.addEventListener('blur', () => { refAtBlur = result.current.isEscapingRef.current })

      act(() => {
        result.current.focusCell(1, 1, true)
      })
      act(() => dispatchKey('Escape'))

      expect(refAtBlur).toBe(true)
      expect(result.current.editing).toBe(false)
    })

    it('keyboard Tab moves right, Shift+Tab moves left', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(0, 1)
      })

      // Tab -> right
      act(() => dispatchKey('Tab'))
      expect(result.current.activeCell).toEqual({ row: 0, col: 2 })

      // Shift+Tab -> left
      act(() => dispatchKey('Tab', { shiftKey: true }))
      expect(result.current.activeCell).toEqual({ row: 0, col: 1 })
    })

    it('Tab at end of row wraps to next row', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(0, 2)
      })

      act(() => dispatchKey('Tab'))
      expect(result.current.activeCell).toEqual({ row: 1, col: 0 })
    })

    it('printable character starts editing', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(0, 0)
      })
      expect(result.current.editing).toBe(false)

      act(() => dispatchKey('5'))
      expect(result.current.editing).toBe(true)
    })

    it('ArrowDown does not go below last row', () => {
      const { result } = renderHook(() => useGridNavigation({ rows: 3, cols: 3 }))

      Object.defineProperty(result.current.containerRef, 'current', {
        writable: true,
        value: container,
      })

      act(() => {
        result.current.focusCell(2, 0)
      })

      act(() => dispatchKey('ArrowDown'))
      expect(result.current.activeCell).toEqual({ row: 2, col: 0 })
    })
  })
})
