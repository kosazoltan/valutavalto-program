import { useCallback, useRef, useState } from 'react'

export interface UndoEntry<T> {
  /** Snapshot before the change */
  prev: T
  /** Snapshot after the change */
  next: T
}

interface UseUndoStackOptions {
  maxSize?: number
}

/**
 * General-purpose undo/redo stack.
 *
 * Usage:
 *   const { push, undo, redo, canUndo, canRedo } = useUndoStack<MyState>()
 *   // On change: push({ prev: oldState, next: newState })
 *   // Ctrl+Z: undo() → returns prev snapshot or null
 *   // Ctrl+Shift+Z: redo() → returns next snapshot or null
 */
export function useUndoStack<T>({ maxSize = 50 }: UseUndoStackOptions = {}) {
  const undoRef = useRef<UndoEntry<T>[]>([])
  const redoRef = useRef<UndoEntry<T>[]>([])
  const [version, setVersion] = useState(0)

  const push = useCallback(
    (entry: UndoEntry<T>) => {
      undoRef.current.push(entry)
      if (undoRef.current.length > maxSize) {
        undoRef.current.shift()
      }
      // Any new change clears the redo stack
      redoRef.current = []
      setVersion((v) => v + 1)
    },
    [maxSize],
  )

  const undo = useCallback((): T | null => {
    const entry = undoRef.current.pop()
    if (!entry) return null
    redoRef.current.push(entry)
    setVersion((v) => v + 1)
    return entry.prev
  }, [])

  const redo = useCallback((): T | null => {
    const entry = redoRef.current.pop()
    if (!entry) return null
    undoRef.current.push(entry)
    setVersion((v) => v + 1)
    return entry.next
  }, [])

  return {
    push,
    undo,
    redo,
    canUndo: undoRef.current.length > 0,
    canRedo: redoRef.current.length > 0,
    /** Changes on each push/undo/redo — useful for reactive UI */
    version,
  }
}
