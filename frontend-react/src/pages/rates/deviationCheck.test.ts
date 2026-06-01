import { describe, it, expect } from 'vitest'
import { isSignificantDeviation, SIGNIFICANT_DEVIATION_THRESHOLD } from './deviationCheck'

describe('isSignificantDeviation (FK02-B / FR-2..5)', () => {
  it('a küszöb 10%', () => {
    expect(SIGNIFICANT_DEVIATION_THRESHOLD).toBe(0.1)
  })

  it('null/üres értékeknél nincs korlátozás', () => {
    expect(isSignificantDeviation(null, 100)).toBe(false)
    expect(isSignificantDeviation(100, null)).toBe(false)
    expect(isSignificantDeviation(null, null)).toBe(false)
  })

  it('0 alapnál nincs korlátozás (nem értelmezhető arány)', () => {
    expect(isSignificantDeviation(0, 100)).toBe(false)
  })

  it('10% alatti eltérés → false', () => {
    expect(isSignificantDeviation(400, 420)).toBe(false) // 5%
    expect(isSignificantDeviation(400, 439)).toBe(false) // 9.75%
  })

  it('pontosan 10% → true (>=)', () => {
    expect(isSignificantDeviation(400, 440)).toBe(true) // +10%
    expect(isSignificantDeviation(400, 360)).toBe(true) // -10%
  })

  it('10% feletti eltérés → true (elgépelés-védelem)', () => {
    expect(isSignificantDeviation(400, 4000)).toBe(true) // 900%
    expect(isSignificantDeviation(400, 200)).toBe(true)  // -50%
  })

  it('negatív alapnál abszolút arányt számol', () => {
    expect(isSignificantDeviation(-100, -120)).toBe(true) // 20%
    expect(isSignificantDeviation(-100, -105)).toBe(false) // 5%
  })
})
