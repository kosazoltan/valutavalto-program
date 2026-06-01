import { describe, it, expect } from 'vitest'
import { currentFunctionCode } from './fillHelpers'

describe('fillHelpers (FR-RFM-22)', () => {
  describe('currentFunctionCode (FR-RFM-22, #NNM)', () => {
    it('csoportszámot 2 jegyűre tölti', () => {
      expect(currentFunctionCode(1)).toBe('#01M')
      expect(currentFunctionCode(16)).toBe('#16M')
    })
    it('3+ jegyű csoportszám is megmarad', () => {
      expect(currentFunctionCode(100)).toBe('#100M')
    })
    it('null/0/negatív/NaN → #01M (alapérték)', () => {
      expect(currentFunctionCode(null)).toBe('#01M')
      expect(currentFunctionCode(0)).toBe('#01M')
      expect(currentFunctionCode(-5)).toBe('#01M')
      expect(currentFunctionCode(undefined)).toBe('#01M')
      expect(currentFunctionCode(NaN)).toBe('#01M')
    })
    it('tört csoportszámot levág', () => {
      expect(currentFunctionCode(7.9)).toBe('#07M')
    })
  })
})
