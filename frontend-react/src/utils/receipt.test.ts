import { describe, it, expect } from 'vitest'
import { generateReceiptNumber, parseReceiptNumber } from './receipt'
import type { TransactionType } from './receipt'

// ─────────────────────────── generateReceiptNumber ───────────────────────────

describe('generateReceiptNumber', () => {
  it('SELL → E prefix', () => {
    expect(generateReceiptNumber('SELL', '001', 100001)).toBe('E001100001')
  })

  it('BUY → V prefix', () => {
    expect(generateReceiptNumber('BUY', '002', 1)).toBe('V002000001')
  })

  it('TRANSFER_OUT → F prefix', () => {
    expect(generateReceiptNumber('TRANSFER_OUT', '003', 5)).toBe('F003000005')
  })

  it('TRANSFER_IN → U prefix', () => {
    expect(generateReceiptNumber('TRANSFER_IN', '004', 10)).toBe('U004000010')
  })

  it('CONVERSION → K prefix', () => {
    expect(generateReceiptNumber('CONVERSION', '005', 99)).toBe('K005000099')
  })

  it('WESTERN_UNION_SEND → W prefix', () => {
    expect(generateReceiptNumber('WESTERN_UNION_SEND', '006', 1000)).toBe('W006001000')
  })

  it('WESTERN_UNION_RECEIVE → W prefix', () => {
    expect(generateReceiptNumber('WESTERN_UNION_RECEIVE', '007', 2)).toBe('W007000002')
  })

  it('MONEYGRAM_SEND → M prefix', () => {
    expect(generateReceiptNumber('MONEYGRAM_SEND', '008', 3)).toBe('M008000003')
  })

  it('MONEYGRAM_RECEIVE → M prefix', () => {
    expect(generateReceiptNumber('MONEYGRAM_RECEIVE', '009', 4)).toBe('M009000004')
  })

  it('VIGNETTE → X prefix', () => {
    expect(generateReceiptNumber('VIGNETTE', '010', 5)).toBe('X010000005')
  })

  it('PHONE_TOPUP → X prefix', () => {
    expect(generateReceiptNumber('PHONE_TOPUP', '011', 6)).toBe('X011000006')
  })

  it('OTHER → X prefix', () => {
    expect(generateReceiptNumber('OTHER', '012', 7)).toBe('X012000007')
  })

  it('PARTIAL_REFUND → PR prefix', () => {
    expect(generateReceiptNumber('PARTIAL_REFUND', '001', 1)).toBe('PR001000001')
  })

  it('REVERSAL throws', () => {
    expect(() => generateReceiptNumber('REVERSAL', '001', 1)).toThrow()
  })

  it('unknown type throws', () => {
    expect(() => generateReceiptNumber('UNKNOWN' as TransactionType, '001', 1)).toThrow()
  })

  it('branchCode with numeric part gets padded', () => {
    // "BC1" → extracts "1" → padded to "001"
    expect(generateReceiptNumber('SELL', 'BC1', 5)).toBe('E001000005')
  })

  it('empty branchCode → 000', () => {
    expect(generateReceiptNumber('SELL', '', 1)).toBe('E000000001')
  })

  it('branchCode with only letters uses hash fallback', () => {
    const result = generateReceiptNumber('BUY', 'ABC', 1)
    expect(result).toMatch(/^V\d{3}000001$/)
  })

  it('large branchCode number mod 1000', () => {
    // "1234" → 1234 % 1000 = 234
    expect(generateReceiptNumber('SELL', '1234', 1)).toBe('E234000001')
  })

  it('sequence padded to 6 digits', () => {
    const result = generateReceiptNumber('SELL', '001', 1)
    expect(result.slice(-6)).toBe('000001')
  })
})

// ─────────────────────────── parseReceiptNumber ───────────────────────────

describe('parseReceiptNumber', () => {
  it('parses SELL receipt', () => {
    const parsed = parseReceiptNumber('E001100001')
    expect(parsed).not.toBeNull()
    expect(parsed!.prefix).toBe('E')
    expect(parsed!.branchCode).toBe('001')
    expect(parsed!.sequence).toBe(100001)
  })

  it('parses BUY receipt', () => {
    const parsed = parseReceiptNumber('V002000001')
    expect(parsed).not.toBeNull()
    expect(parsed!.prefix).toBe('V')
    expect(parsed!.branchCode).toBe('002')
    expect(parsed!.sequence).toBe(1)
  })

  it('parses PARTIAL_REFUND (2-char prefix)', () => {
    const parsed = parseReceiptNumber('PR001000001')
    expect(parsed).not.toBeNull()
    expect(parsed!.prefix).toBe('PR')
    expect(parsed!.branchCode).toBe('001')
    expect(parsed!.sequence).toBe(1)
  })

  it('returns null for short string', () => {
    expect(parseReceiptNumber('E001')).toBeNull()
  })

  it('returns null for empty string', () => {
    expect(parseReceiptNumber('')).toBeNull()
  })

  it('returns null for null-ish (empty)', () => {
    // @ts-expect-error testing null input
    expect(parseReceiptNumber(null)).toBeNull()
  })

  it('roundtrip: generate → parse', () => {
    const receiptNumber = generateReceiptNumber('SELL', '001', 100001)
    const parsed = parseReceiptNumber(receiptNumber)
    expect(parsed).not.toBeNull()
    expect(parsed!.sequence).toBe(100001)
  })
})
