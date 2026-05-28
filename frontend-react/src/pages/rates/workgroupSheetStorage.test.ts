import { describe, it, expect } from 'vitest'
import {
  sheet0RowToValues,
  loadSheet0ByCurrency,
  loadGroupFormulas,
  saveGroupFormulas,
  loadAllGroupValueSnapshots,
  saveGroupValueSnapshot,
} from './workgroupSheetStorage'
import type { WgValues } from './workgroupSheetFormula'

/** Minimál in-memory Storage stub a teszthez (jsdom localStorage helyett, izolált). */
function memStorage(): Storage {
  const m = new Map<string, string>()
  return {
    get length() {
      return m.size
    },
    clear: () => m.clear(),
    getItem: (k: string) => (m.has(k) ? m.get(k)! : null),
    key: (i: number) => Array.from(m.keys())[i] ?? null,
    removeItem: (k: string) => void m.delete(k),
    setItem: (k: string, v: string) => void m.set(k, v),
  } as Storage
}

describe('sheet0RowToValues', () => {
  it('A–I mezőket mappolja, a D/currency címkét kihagyja', () => {
    const v = sheet0RowToValues({
      currency: 'EUR',
      settlement: 400,
      otp: 401,
      helper: 402,
      weakMultiBuy: 395,
      weakMultiSell: 405,
      crossSettlement: 399,
      crossRate: 1.08,
      wholesale: 398,
    })
    expect(v).toEqual({ A: 400, B: 401, C: 402, E: 395, F: 405, G: 399, H: 1.08, I: 398 })
  })

  it('hiányzó mezőket kihagy', () => {
    expect(sheet0RowToValues({ currency: 'USD', settlement: 360 })).toEqual({ A: 360 })
  })
})

describe('loadSheet0ByCurrency', () => {
  it('valutakód → A–I map a 0-s lap localStorage-ból', () => {
    const s = memStorage()
    s.setItem('arfolyamkeszito.mainSheet.v1', JSON.stringify([
      { currency: 'EUR', settlement: 400, weakMultiSell: 405 },
      { currency: 'usd', settlement: 360 },
    ]))
    const map = loadSheet0ByCurrency(s)
    expect(map.get('EUR')).toEqual({ A: 400, F: 405 })
    expect(map.get('USD')).toEqual({ A: 360 }) // upper-case kulcs
  })

  it('hiányzó / hibás JSON → üres map', () => {
    expect(loadSheet0ByCurrency(memStorage()).size).toBe(0)
    const s = memStorage()
    s.setItem('arfolyamkeszito.mainSheet.v1', '{nem json')
    expect(loadSheet0ByCurrency(s).size).toBe(0)
  })
})

describe('group formulas round-trip', () => {
  it('mentés → betöltés ugyanazt adja, csoportonként külön kulcs', () => {
    const s = memStorage()
    saveGroupFormulas('g-1', { '1.buyRate': 'J - 5' }, s)
    saveGroupFormulas('g-2', { '2.sellRate': '#01L + 1' }, s)
    expect(loadGroupFormulas('g-1', s)).toEqual({ '1.buyRate': 'J - 5' })
    expect(loadGroupFormulas('g-2', s)).toEqual({ '2.sellRate': '#01L + 1' })
    expect(loadGroupFormulas('g-3', s)).toEqual({})
  })
})

describe('group value snapshots (#NN)', () => {
  it('több csoport pillanatképe round-trip', () => {
    const s = memStorage()
    const g1: Map<string, WgValues> = new Map([['EUR', { L: 390, M: 410 }]])
    const g3: Map<string, WgValues> = new Map([['eur', { L: 392 }]])
    saveGroupValueSnapshot(1, g1, s)
    saveGroupValueSnapshot(3, g3, s)
    const all = loadAllGroupValueSnapshots(s)
    expect(all.get(1)!.get('EUR')).toEqual({ L: 390, M: 410 })
    expect(all.get(3)!.get('EUR')).toEqual({ L: 392 }) // upper-case kulcs
  })

  it('ugyanazon csoport újramentése felülírja', () => {
    const s = memStorage()
    saveGroupValueSnapshot(1, new Map([['EUR', { L: 390 }]]), s)
    saveGroupValueSnapshot(1, new Map([['EUR', { L: 400 }]]), s)
    expect(loadAllGroupValueSnapshots(s).get(1)!.get('EUR')).toEqual({ L: 400 })
  })
})
