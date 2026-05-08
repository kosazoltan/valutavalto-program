import { describe, it, expect } from 'vitest'
import { generateChallenge, computeResponse, validateResponse } from './rateAuthCode'

describe('rateAuthCode', () => {
  describe('generateChallenge', () => {
    it('generates 4-letter uppercase string', () => {
      const c = generateChallenge()
      expect(c).toHaveLength(4)
      expect(c).toMatch(/^[A-Z]{4}$/)
    })
  })

  describe('computeResponse', () => {
    // ABCD: B(1) C(1) → 11*2=22 + dayOfWeek(5=Friday) + dayOfMonth(8) = 35
    it('ABCD on 2026-05-08 (Friday) → 35', () => {
      const date = new Date(2026, 4, 8) // May 8, 2026 is a Friday
      expect(date.getDay()).toBe(5) // sanity: Friday = 5
      expect(computeResponse('ABCD', date)).toBe(35)
    })

    // Vowels = 0: AEIA → E(0), I(0) → 00*2=0 + dayOfWeek + dayOfMonth
    it('vowels score 0', () => {
      const date = new Date(2026, 4, 8)
      expect(computeResponse('AEIA', date)).toBe(0 + 5 + 8)
    })

    // L-Z = 2: XLYA → L(2), Y(2) → 22*2=44
    it('L-Z letters score 2', () => {
      const date = new Date(2026, 4, 8)
      expect(computeResponse('XLYA', date)).toBe(44 + 5 + 8)
    })

    // Mixed: ZBKF → B(1), K(1) → 11*2=22
    it('A-K non-vowels score 1', () => {
      const date = new Date(2026, 4, 8)
      expect(computeResponse('ZBKF', date)).toBe(22 + 5 + 8)
    })

    // Sunday: getDay() === 0 → dayOfWeek should be 7
    it('Sunday counts as 7', () => {
      const sunday = new Date(2026, 4, 10) // May 10, 2026 is a Sunday
      expect(sunday.getDay()).toBe(0) // sanity
      expect(computeResponse('ABCD', sunday)).toBe(22 + 7 + 10)
    })

    // Day 1 of month
    it('day-of-month 1', () => {
      const date = new Date(2026, 4, 1) // May 1, 2026 is a Friday
      expect(computeResponse('ABCD', date)).toBe(22 + 5 + 1)
    })

    // Short challenge returns 0
    it('short challenge returns 0', () => {
      expect(computeResponse('AB', new Date())).toBe(0)
    })
  })

  describe('validateResponse', () => {
    it('correct response returns true', () => {
      const date = new Date(2026, 4, 8)
      expect(validateResponse('ABCD', 35, date)).toBe(true)
    })

    it('wrong response returns false', () => {
      const date = new Date(2026, 4, 8)
      expect(validateResponse('ABCD', 99, date)).toBe(false)
    })
  })
})
