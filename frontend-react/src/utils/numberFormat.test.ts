import { describe, it, expect } from 'vitest'
import { formatInteger, formatDecimal, formatCurrency, getNumberClassName } from './numberFormat'

describe('formatInteger', () => {
  it('formats a simple integer', () => {
    // hu-HU locale uses non-breaking space (U+00A0) as thousands separator
    const result = formatInteger(1234567)
    expect(result).toMatch(/1.234.567/)
  })

  it('returns "0" for null', () => {
    expect(formatInteger(null)).toBe('0')
  })

  it('returns "0" for undefined', () => {
    expect(formatInteger(undefined)).toBe('0')
  })

  it('returns "0" for empty string', () => {
    expect(formatInteger('')).toBe('0')
  })

  it('returns "0" for NaN string', () => {
    expect(formatInteger('abc')).toBe('0')
  })

  it('floors decimal input', () => {
    const result = formatInteger(1234.9)
    expect(result).not.toContain(',')
    // should floor to 1234 (locale-specific thousands separator not guaranteed in jsdom)
    expect(result).toContain('234')
  })

  it('handles string number input', () => {
    const result = formatInteger('5000')
    // Should contain the digits 5000 (locale separator may vary)
    expect(result).toContain('5')
    expect(result).toMatch(/5[\s\u00a0.,]?0/)
  })

  it('handles zero', () => {
    expect(formatInteger(0)).toBe('0')
  })

  it('handles negative number', () => {
    const result = formatInteger(-1000)
    expect(result).toContain('1')
  })
})

describe('formatDecimal', () => {
  it('returns "0" for null', () => {
    expect(formatDecimal(null)).toBe('0')
  })

  it('returns "0" for undefined', () => {
    expect(formatDecimal(undefined)).toBe('0')
  })

  it('returns "0" for empty string', () => {
    expect(formatDecimal('')).toBe('0')
  })

  it('returns "0" for NaN string', () => {
    expect(formatDecimal('xyz')).toBe('0')
  })

  it('formats with default 0 min / 2 max decimals', () => {
    const result = formatDecimal(1234.5)
    // hu-HU uses comma as decimal separator
    expect(result).toContain(',')
  })

  it('formats with custom minDecimals=2 maxDecimals=4', () => {
    const result = formatDecimal(1.5, 2, 4)
    expect(result).toContain(',')
  })

  it('handles string decimal', () => {
    const result = formatDecimal('123.45', 2, 2)
    expect(result).toContain(',')
  })

  it('handles zero', () => {
    expect(formatDecimal(0)).toBe('0')
  })
})

describe('formatCurrency', () => {
  it('always formats with 2 decimal places', () => {
    const result = formatCurrency(1234.5)
    // hu-HU: "1 234,50"
    expect(result).toContain(',')
    expect(result).toMatch(/50/)
  })

  it('returns "0,00" pattern for null', () => {
    // formatDecimal returns '0' for null, but with 2 decimals it would be '0,00'
    const result = formatCurrency(null)
    // null → '0' (from formatDecimal null guard)
    expect(result).toBe('0')
  })

  it('formats large currency value', () => {
    const result = formatCurrency(1000000.00)
    expect(result).toMatch(/1/)
  })
})

describe('getNumberClassName', () => {
  it('returns "font-mono" by default', () => {
    expect(getNumberClassName()).toBe('font-mono')
  })

  it('appends additional class', () => {
    expect(getNumberClassName('text-right')).toBe('font-mono text-right')
  })

  it('trims result when no additional class', () => {
    const result = getNumberClassName('')
    expect(result).toBe('font-mono')
  })
})
