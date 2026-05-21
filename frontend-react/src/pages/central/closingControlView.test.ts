import { describe, it, expect } from 'vitest'
import type { ClosingControlStatus } from '../../services/api'
import {
  isClosingDone,
  computeClosingSummary,
  sortByBranchCode,
  matchesClosingFilter,
} from './closingControlView'

let branchIdSeq = 0
function row(partial: Partial<ClosingControlStatus>): ClosingControlStatus {
  return {
    branchId: partial.branchId ?? `branch-${++branchIdSeq}`,
    controlDate: '2026-05-21',
    dailyClosingDone: false,
    eveningClosingDone: false,
    navClosingDone: false,
    alertLevel: 'NONE',
    ...partial,
  } as ClosingControlStatus
}

describe('FK-003 closingControlView', () => {
  it('isClosingDone: completedCount>=requiredCount → done; egyébként nem', () => {
    expect(isClosingDone(row({ completedCount: 3, requiredCount: 3 }))).toBe(true)
    expect(isClosingDone(row({ completedCount: 2, requiredCount: 3 }))).toBe(false)
  })

  it('isClosingDone fallback: 3 boolean → done csak ha mind a 3 igaz', () => {
    expect(isClosingDone(row({ dailyClosingDone: true, eveningClosingDone: true, navClosingDone: true }))).toBe(true)
    expect(isClosingDone(row({ dailyClosingDone: true, eveningClosingDone: true, navClosingDone: false }))).toBe(false)
  })

  it('computeClosingSummary: total = done + notArrived (FK-003 1. pont)', () => {
    const rows = [
      row({ completedCount: 3, requiredCount: 3 }), // done
      row({ completedCount: 3, requiredCount: 3 }), // done
      row({ completedCount: 0, requiredCount: 3 }), // notArrived
    ]
    const s = computeClosingSummary(rows)
    expect(s.total).toBe(3)
    expect(s.done).toBe(2)
    expect(s.notArrived).toBe(1)
    expect(s.done + s.notArrived).toBe(s.total)
  })

  it('sortByBranchCode: numerikusan tudatos (BR009 < BR010 < BR105)', () => {
    const sorted = sortByBranchCode([
      row({ branchCode: 'BR105' }),
      row({ branchCode: 'BR009' }),
      row({ branchCode: 'BR010' }),
    ])
    expect(sorted.map((r) => r.branchCode)).toEqual(['BR009', 'BR010', 'BR105'])
  })

  it('matchesClosingFilter: állapot + keresés', () => {
    const done = row({ branchCode: 'BR009', branchName: 'Dombóvár Tesco', completedCount: 3, requiredCount: 3 })
    const missing = row({ branchCode: 'BR010', branchName: 'Szekszárd Értéktár', completedCount: 0, requiredCount: 3 })

    expect(matchesClosingFilter(done, 'all', '')).toBe(true)
    expect(matchesClosingFilter(done, 'done', '')).toBe(true)
    expect(matchesClosingFilter(done, 'notArrived', '')).toBe(false)
    expect(matchesClosingFilter(missing, 'notArrived', '')).toBe(true)

    // keresés
    expect(matchesClosingFilter(done, 'all', 'dombóvár')).toBe(true)
    expect(matchesClosingFilter(done, 'all', 'szekszárd')).toBe(false)
  })
})
