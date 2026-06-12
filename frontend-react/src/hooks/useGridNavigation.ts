import { useCallback, useRef, useEffect, useState } from 'react'

export interface GridCell {
  row: number
  col: number
}

interface UseGridNavigationOptions {
  rows: number
  cols: number
  /** CSS selector to find input elements within the grid container */
  inputSelector?: string
  /**
   * FK03-fix (FR-1, FR-2): ha false, a kattintás/fókusz csak KIJELÖLI a cellát
   * (formázott érték látszik), szerkesztő módba dupla kattintás / Enter /
   * gépelés visz. Alapértelmezés true (örökölt viselkedés) — a scope-on kívüli
   * fogyasztók (SettlementRateEntry) változatlanok maradnak.
   */
  editOnFocus?: boolean
}

/**
 * Excel-like keyboard navigation for editable grid tables.
 *
 * Features:
 * - Arrow keys move between cells (up/down/left/right)
 * - Enter activates cell for editing (focuses input, selects all)
 * - Enter again (or Tab) moves to the next cell down (or right at bottom)
 * - Escape deactivates cell (blurs input)
 * - Tab/Shift+Tab move right/left
 */
export function useGridNavigation({ rows, cols, editOnFocus = true }: UseGridNavigationOptions) {
  const containerRef = useRef<HTMLDivElement>(null)
  const [activeCell, setActiveCell] = useState<GridCell | null>(null)
  const [editing, setEditing] = useState(false)
  /** Suppresses onCellFocus when focusCell is driving programmatic focus */
  const suppressFocusRef = useRef(false)
  /**
   * FK03-fix (FR-5): az Escape-kezelő az onBlur ELŐTT igazra állítja, hogy a
   * fogyasztó onBlur-ja megkülönböztethesse az Escape-blurt (revert, NINCS
   * commit) a normál blurtól (commit). A fogyasztó felelőssége visszaállítani.
   */
  const isEscapingRef = useRef(false)

  const getInput = useCallback((row: number, col: number): HTMLInputElement | null => {
    if (!containerRef.current) return null
    return containerRef.current.querySelector<HTMLInputElement>(
      `[data-grid-row="${row}"][data-grid-col="${col}"]`
    )
  }, [])

  const focusCell = useCallback((row: number, col: number, startEditing = false) => {
    const clamped = { row: Math.max(0, Math.min(row, rows - 1)), col: Math.max(0, Math.min(col, cols - 1)) }
    const input = getInput(clamped.row, clamped.col)
    if (!input) return

    setActiveCell(clamped)

    if (startEditing) {
      setEditing(true)
      input.focus()
      input.select()
    } else {
      setEditing(false)
      // Suppress the onFocus handler so it doesn't re-enable editing
      suppressFocusRef.current = true
      input.focus()
      // Move cursor to end without selecting
      const len = input.value.length
      input.setSelectionRange(len, len)
    }
  }, [rows, cols, getInput])

  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if (!activeCell) return

    // Only handle events from grid-cell inputs (skip limit/other inputs)
    const target = e.target as HTMLElement
    if (!target.hasAttribute('data-grid-row') || !target.hasAttribute('data-grid-col')) return

    const { row, col } = activeCell

    switch (e.key) {
      case 'ArrowUp':
        e.preventDefault()
        if (row > 0) focusCell(row - 1, col)
        break

      case 'ArrowDown':
        e.preventDefault()
        if (row < rows - 1) focusCell(row + 1, col)
        break

      case 'ArrowLeft':
        if (!editing) {
          e.preventDefault()
          if (col > 0) focusCell(row, col - 1)
        }
        break

      case 'ArrowRight':
        if (!editing) {
          e.preventDefault()
          if (col < cols - 1) focusCell(row, col + 1)
        }
        break

      case 'Enter':
        e.preventDefault()
        if (!editing) {
                  // Activate cell for editing
                  focusCell(row, col, true)
                }
        else if (row < rows - 1) {
                    focusCell(row + 1, col)
                  }
        else if (col < cols - 1) {
                    focusCell(0, col + 1)
                  }
        break

      case 'Tab':
        e.preventDefault()
        if (e.shiftKey) {
                  // Move left (or wrap to prev row end)
                  if (col > 0) {
                    focusCell(row, col - 1)
                  } else if (row > 0) {
                    focusCell(row - 1, cols - 1)
                  }
                }
        else if (col < cols - 1) {
                    focusCell(row, col + 1)
                  }
        else if (row < rows - 1) {
                    focusCell(row + 1, 0)
                  }
        break

      case 'Escape': {
        e.preventDefault()
        // FK03-fix (FR-5): a blur ELŐTT jelezzük, hogy Escape okozza — az onBlur
        // így revertál (nem commitol).
        isEscapingRef.current = true
        setEditing(false)
        // Keep focus on cell but exit edit mode
        const escInput = getInput(row, col)
        if (escInput) escInput.blur()
        break
      }

      default: {
        // If a printable character is typed and not editing, start editing
        if (!editing && e.key.length === 1 && !e.ctrlKey && !e.altKey && !e.metaKey) {
          setEditing(true)
          const defInput = getInput(row, col)
          if (defInput) {
            defInput.focus()
            defInput.select()
          }
        }
        break
      }
    }
  }, [activeCell, editing, rows, cols, focusCell, getInput])

  useEffect(() => {
    const container = containerRef.current
    if (!container) return

    container.addEventListener('keydown', handleKeyDown)
    return () => container.removeEventListener('keydown', handleKeyDown)
  }, [handleKeyDown])

  /** Called when an input is clicked/focused directly */
  const onCellFocus = useCallback((row: number, col: number) => {
    if (suppressFocusRef.current) {
      suppressFocusRef.current = false
      return
    }
    setActiveCell({ row, col })
    // FK03-fix (FR-1, FR-2): editOnFocus=false esetén a fókusz ≠ szerkesztő mód —
    // a cella kijelölt állapotba kerül, szerkesztésbe dupla kattintás / Enter /
    // gépelés visz (Főlap-referencia viselkedés). Codex/Copilot #1112: mindig
    // SZINKRONIZÁLUNK (nem csak bekapcsolunk) — különben egy előző cella
    // szerkesztő módja "ragadna" az új cellára kattintáskor.
    setEditing(editOnFocus)
  }, [editOnFocus])

  return {
    containerRef,
    activeCell,
    editing,
    setEditing,
    isEscapingRef,
    focusCell,
    onCellFocus,
    /** data-attributes to spread on each input: data-grid-row, data-grid-col */
    getCellProps: (row: number, col: number) => ({
      'data-grid-row': row,
      'data-grid-col': col,
      onFocus: () => onCellFocus(row, col),
    }),
  }
}
