import { describe, it, expect } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useUndoStack } from './useUndoStack'

describe('useUndoStack', () => {
  it('starts with empty stacks', () => {
    const { result } = renderHook(() => useUndoStack<number>())
    expect(result.current.canUndo).toBe(false)
    expect(result.current.canRedo).toBe(false)
    expect(result.current.version).toBe(0)
  })

  it('push adds entry and enables undo', () => {
    const { result } = renderHook(() => useUndoStack<number>())
    act(() => {
      result.current.push({ prev: 1, next: 2 })
    })
    expect(result.current.canUndo).toBe(true)
    expect(result.current.canRedo).toBe(false)
    expect(result.current.version).toBe(1)
  })

  it('undo returns prev snapshot', () => {
    const { result } = renderHook(() => useUndoStack<number>())
    act(() => {
      result.current.push({ prev: 10, next: 20 })
    })
    let undone: number | null = null
    act(() => {
      undone = result.current.undo()
    })
    expect(undone).toBe(10)
    expect(result.current.canUndo).toBe(false)
    expect(result.current.canRedo).toBe(true)
  })

  it('redo returns next snapshot', () => {
    const { result } = renderHook(() => useUndoStack<number>())
    act(() => {
      result.current.push({ prev: 10, next: 20 })
    })
    act(() => {
      result.current.undo()
    })
    let redone: number | null = null
    act(() => {
      redone = result.current.redo()
    })
    expect(redone).toBe(20)
    expect(result.current.canUndo).toBe(true)
    expect(result.current.canRedo).toBe(false)
  })

  it('undo on empty returns null', () => {
    const { result } = renderHook(() => useUndoStack<number>())
    let val: number | null = null
    act(() => {
      val = result.current.undo()
    })
    expect(val).toBeNull()
  })

  it('redo on empty returns null', () => {
    const { result } = renderHook(() => useUndoStack<number>())
    let val: number | null = null
    act(() => {
      val = result.current.redo()
    })
    expect(val).toBeNull()
  })

  it('push clears redo stack', () => {
    const { result } = renderHook(() => useUndoStack<number>())
    act(() => {
      result.current.push({ prev: 1, next: 2 })
    })
    act(() => {
      result.current.undo()
    })
    expect(result.current.canRedo).toBe(true)
    act(() => {
      result.current.push({ prev: 2, next: 3 })
    })
    expect(result.current.canRedo).toBe(false)
  })

  it('respects maxSize and evicts oldest', () => {
    const { result } = renderHook(() => useUndoStack<number>({ maxSize: 3 }))
    act(() => {
      result.current.push({ prev: 0, next: 1 })
      result.current.push({ prev: 1, next: 2 })
      result.current.push({ prev: 2, next: 3 })
      result.current.push({ prev: 3, next: 4 }) // evicts first
    })
    // Should be able to undo 3 times (maxSize=3), 4th should be null
    let val: number | null = null
    act(() => { val = result.current.undo() })
    expect(val).toBe(3)
    act(() => { val = result.current.undo() })
    expect(val).toBe(2)
    act(() => { val = result.current.undo() })
    expect(val).toBe(1)
    act(() => { val = result.current.undo() })
    expect(val).toBeNull()
  })

  it('multi-step undo/redo sequence', () => {
    const { result } = renderHook(() => useUndoStack<string>())
    act(() => {
      result.current.push({ prev: 'a', next: 'b' })
      result.current.push({ prev: 'b', next: 'c' })
      result.current.push({ prev: 'c', next: 'd' })
    })
    let val: string | null = null
    act(() => { val = result.current.undo() }) // d -> c
    expect(val).toBe('c')
    act(() => { val = result.current.undo() }) // c -> b
    expect(val).toBe('b')
    act(() => { val = result.current.redo() }) // b -> c
    expect(val).toBe('c')
    act(() => { val = result.current.redo() }) // c -> d
    expect(val).toBe('d')
    expect(result.current.canRedo).toBe(false)
  })

  it('version increments on each operation', () => {
    const { result } = renderHook(() => useUndoStack<number>())
    expect(result.current.version).toBe(0)
    act(() => { result.current.push({ prev: 1, next: 2 }) })
    expect(result.current.version).toBe(1)
    act(() => { result.current.undo() })
    expect(result.current.version).toBe(2)
    act(() => { result.current.redo() })
    expect(result.current.version).toBe(3)
  })
})
