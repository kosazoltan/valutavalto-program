import { describe, it, expect } from 'vitest'
import { computeCrossSettlement, resolveSettlement, crossSettlementStaysAuto } from './mainSheetRules'

describe('mainSheetRules — Főlap A/G cella-feloldás', () => {
  describe('computeCrossSettlement (G oszlop)', () => {
    it('EUR-bázis: base / crossRate', () => {
      // EUR elszámoló 400, EUR/CZK kereszt 24.5 → 400/24.5
      expect(computeCrossSettlement({ crossBase: 'EUR', crossRate: 24.5 }, 400, 350)).toBeCloseTo(400 / 24.5, 6)
    })
    it('USD-bázis: usdSettlement / crossRate', () => {
      expect(computeCrossSettlement({ crossBase: 'USD', crossRate: 3.6 }, 400, 360)).toBeCloseTo(360 / 3.6, 6)
    })
    it('nem kereszt-valuta → 0', () => {
      expect(computeCrossSettlement({ crossBase: null, crossRate: 0 }, 400, 360)).toBe(0)
    })
    it('hiányzó crossRate → 0', () => {
      expect(computeCrossSettlement({ crossBase: 'EUR', crossRate: 0 }, 400, 360)).toBe(0)
    })
  })

  describe('resolveSettlement (A oszlop)', () => {
    it('nem kereszt-valuta → a beírt settlement (mindig kézi)', () => {
      expect(resolveSettlement({ settlement: 405.5, crossRate: 0, crossBase: null }, 400, 360)).toBe(405.5)
    })
    it('kereszt-valuta, NINCS kézi felülírás → a kereszt-számolt G érték (auto)', () => {
      const row = { settlement: 99, crossRate: 24.5, crossBase: 'EUR' as const, settlementManual: false }
      expect(resolveSettlement(row, 400, 360)).toBeCloseTo(400 / 24.5, 6)
    })
    it('kereszt-valuta, KÉZI felülírás → a beírt settlement (G-t felülírja)', () => {
      const row = { settlement: 17.25, crossRate: 24.5, crossBase: 'EUR' as const, settlementManual: true }
      expect(resolveSettlement(row, 400, 360)).toBe(17.25)
    })
  })

  describe('crossSettlementStaysAuto (P1 #722 — fókusz/blur ne zárja le az auto-t)', () => {
    const autoG = 400 / 24.5 // ≈ 16.3265
    it('auto cella + változatlan érték (2 tizedes egyezik) → marad auto (true)', () => {
      expect(crossSettlementStaysAuto(16.33, autoG, 2, false)).toBe(true)
    })
    it('auto cella + ténylegesen eltérő érték → kézire vált (false)', () => {
      expect(crossSettlementStaysAuto(17.50, autoG, 2, false)).toBe(false)
    })
    it('már kézi cella → mindig false (nem releváns a no-op)', () => {
      expect(crossSettlementStaysAuto(16.33, autoG, 2, true)).toBe(false)
    })
  })
})
