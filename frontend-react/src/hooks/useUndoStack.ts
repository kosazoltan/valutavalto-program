import { useState, useCallback, useRef } from 'react'

interface UndoStackOptions {
  /** Maximum number of undo states to keep */
  maxHistory?: number
}

/**
 * Application-level undo/redo stack for any serializable state.
 *
 * Usage:
 *   const { state, setState, undo, redo, canUndo, canRedo, checkpoint } = useUndoStack(initialState)
 *
 * - Call `checkpoint()` before a batch of changes to create an undo point
 * - Ctrl+Z triggers undo, Ctrl+Y / Ctrl+Shift+Z triggers redo
 */
export function useUndoStack<T>(initialState: T, options?: UndoStackOptions) {
  const maxHistory = options?.maxHistory ?? 50
  const [state, setStateRaw] = useState<T>(initialState)
  const undoStack = useRef<T[]>([])
  const redoStack = useRef<T[]>([])
  const lastCheckpoint = useRef<T>(initialState)

  /** Save a checkpoint (snapshot current state onto undo stack) */
  const checkpoint = useCallback(() => {
    undoStack.current.push(lastCheckpoint.current)
    if (undoStack.current.length > maxHistory) {
      undoStack.current.shift()
    }
    redoStack.current = []
    lastCheckpoint.current = state
  }, [state, maxHistory])

  /** Set state (does NOT auto-create checkpoint — call checkpoint() explicitly before batch changes) */
  const setState = useCallback((newState: T | ((prev: T) => T)) => {
    setStateRaw(prev => {
      const next = typeof newState === 'function' ? (newState as (prev: T) => T)(prev) : newState
      lastCheckpoint.current = next
      return next
    })
  }, [])

  const undo = useCallback(() => {
    if (undoStack.current.length === 0) return
    const prev = undoStack.current.pop()!
    redoStack.current.push(lastCheckpoint.current)
    lastCheckpoint.current = prev
    setStateRaw(prev)
  }, [])

  const redo = useCallback(() => {
    if (redoStack.current.length === 0) return
    const next = redoStack.current.pop()!
    undoStack.current.push(lastCheckpoint.current)
    lastCheckpoint.current = next
    setStateRaw(next)
  }, [])

  return {
    state,
    setState,
    undo,
    redo,
    checkpoint,
    canUndo: undoStack.current.length > 0,
    canRedo: redoStack.current.length > 0,
  }
}
