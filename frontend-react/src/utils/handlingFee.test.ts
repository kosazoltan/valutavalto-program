import { describe, it, expect } from 'vitest'
import { computeHandlingFee } from './handlingFee'
import type { HandlingFeeConfig } from '../services/api/settings'

/**
 * FK-KEZDIJ B.1 (2026-06-12): a kliens-oldali díj-tükör BIT-PONTOS paritása a backend
 * HandlingFeeService (PER_MILLE/BRACKET) + HandlingFeeCalculator (roundToFive) számításával.
 */
const perMille = (rate: number, max: number | null = null): HandlingFeeConfig => ({
  feeType: 'PER_MILLE',
  perMilleRate: rate,
  perMilleMaxAmount: max,
  brackets: [],
})

const bracket = (rows: Array<[number, number, number]>): HandlingFeeConfig => ({
  feeType: 'BRACKET',
  perMilleRate: 0,
  perMilleMaxAmount: null,
  brackets: rows.map(([bracketOrder, upperLimit, feeAmount]) => ({
    bracketOrder,
    upperLimit,
    feeAmount,
    active: true,
  })),
})

describe('computeHandlingFee — PER_MILLE (backend-paritás)', () => {
  it('összeg × ezrelék / 1000, HALF_UP egészre, majd 5 Ft-szabály', () => {
    // 123 456 × 3 / 1000 = 370.368 → HALF_UP 370 → roundToFive 370
    expect(computeHandlingFee(123456, perMille(3))).toBe(370)
    // 100 000 × 3 / 1000 = 300 → 300
    expect(computeHandlingFee(100000, perMille(3))).toBe(300)
    // 111 111 × 3 / 1000 = 333.333 → 333 → 5-szabály (3→5): 335
    expect(computeHandlingFee(111111, perMille(3))).toBe(335)
    // 110 600 × 3 / 1000 = 331.8 → HALF_UP 332 → 5-szabály (2→0): 330
    expect(computeHandlingFee(110600, perMille(3))).toBe(330)
    // 112 600 × 3 / 1000 = 337.8 → 338 → 5-szabály (8→10): 340
    expect(computeHandlingFee(112600, perMille(3))).toBe(340)
  })

  it('max-sapka érvényesül (ha > 0), a sapkázott érték is 5 Ft-ra kerekül', () => {
    expect(computeHandlingFee(10_000_000, perMille(3, 5000))).toBe(5000)
    expect(computeHandlingFee(10_000_000, perMille(3, 0))).toBe(30000) // 0 sapka = nincs sapka
    expect(computeHandlingFee(10_000_000, perMille(3, null))).toBe(30000)
  })
})

describe('computeHandlingFee — BRACKET (backend-paritás)', () => {
  const cfg = bracket([
    [1, 50000, 200],
    [2, 150000, 500],
    [3, 400000, 1000],
  ])

  it('az első sáv, ahol összeg <= upperLimit (határérték a sávhoz tartozik)', () => {
    expect(computeHandlingFee(30000, cfg)).toBe(200)
    expect(computeHandlingFee(50000, cfg)).toBe(200) // pontosan a határon: <= → ez a sáv
    expect(computeHandlingFee(50001, cfg)).toBe(500)
    expect(computeHandlingFee(150000, cfg)).toBe(500)
    expect(computeHandlingFee(400000, cfg)).toBe(1000)
  })

  it('az utolsó sáv felett az utolsó sáv díja érvényesül', () => {
    expect(computeHandlingFee(9_999_999, cfg)).toBe(1000)
  })

  it('inaktív sávok kiszűrve; üres sávtábla → 0 (backend-paritás)', () => {
    const withInactive = bracket([[1, 50000, 200]])
    withInactive.brackets.push({
      bracketOrder: 2,
      upperLimit: 999999999,
      feeAmount: 7777,
      active: false,
    })
    expect(computeHandlingFee(100000, withInactive)).toBe(200) // utolsó AKTÍV sáv díja
    expect(computeHandlingFee(100000, bracket([]))).toBe(0)
  })
})

describe('computeHandlingFee — szélek', () => {
  it('NONE → 0; null konfig → null (nincs tükör-számítás); 0/negatív összeg → 0', () => {
    expect(
      computeHandlingFee(100000, {
        feeType: 'NONE',
        perMilleRate: 0,
        perMilleMaxAmount: null,
        brackets: [],
      }),
    ).toBe(0)
    expect(computeHandlingFee(100000, null)).toBeNull()
    expect(computeHandlingFee(0, perMille(3))).toBe(0)
    expect(computeHandlingFee(-5, perMille(3))).toBe(0)
  })
})
