import { describe, it, expect } from 'vitest'
import {
  computeEuaRate, euaDeviationExceeds, raiffeisenBand, computeRsRate, computeCrossRate,
} from './rfmRules'

describe('rfmRules (G22 — RFM számítási mag)', () => {
  describe('EUA (FR-RFM-09)', () => {
    it('computeEuaRate: gyenge euró eladás × 1.2', () => {
      expect(computeEuaRate(400)).toBeCloseTo(480, 6)
    })
    it('computeEuaRate: 0/negatív → 0', () => {
      expect(computeEuaRate(0)).toBe(0)
      expect(computeEuaRate(-5)).toBe(0)
    })
    it('euaDeviationExceeds: a ×1.2-höz képest pontosan 20% NEM lép túl', () => {
      // expected = 480; +20% = 576 — épp a határ, nem lép túl (>20% kell)
      expect(euaDeviationExceeds(576, 400)).toBe(false)
    })
    it('euaDeviationExceeds: 20% felett → true', () => {
      expect(euaDeviationExceeds(600, 400)).toBe(true) // 600 vs 480 = +25%
    })
    it('euaDeviationExceeds: a képzett értékhez közeli → false', () => {
      expect(euaDeviationExceeds(485, 400)).toBe(false)
    })
    it('euaDeviationExceeds: 0 bemenet → false (nem dönthető el)', () => {
      expect(euaDeviationExceeds(0, 400)).toBe(false)
      expect(euaDeviationExceeds(500, 0)).toBe(false)
    })
  })

  describe('Raiffeisen sáv (FR-RFM-12/13)', () => {
    it('±10% alapból az elszámoló köré', () => {
      expect(raiffeisenBand(400)).toEqual({ min: 360, max: 440 })
    })
    it('szabadon állítható százalék (pl. OTP-bázis ±5%)', () => {
      expect(raiffeisenBand(400, 5)).toEqual({ min: 380, max: 420 })
    })
    it('0/negatív bázis → {0,0}', () => {
      expect(raiffeisenBand(0)).toEqual({ min: 0, max: 0 })
    })
  })

  describe('R/S képlet (FR-RFM-19)', () => {
    it('P + kedvezmény (pl. EUR: P + 0,25)', () => {
      expect(computeRsRate(410, 0.25)).toBeCloseTo(410.25, 6)
    })
    it('érvénytelen kedvezmény → P', () => {
      expect(computeRsRate(410, NaN)).toBe(410)
    })
  })

  describe('Kereszt-árfolyam (FR-RFM-04/05)', () => {
    it('bázis / kereszt-ráta', () => {
      expect(computeCrossRate(400, 25)).toBeCloseTo(16, 6)
    })
    it('0 kereszt-ráta → 0 (nincs osztás 0-val)', () => {
      expect(computeCrossRate(400, 0)).toBe(0)
    })
  })
})
