import { describe, it, expect } from 'vitest'
import { resolveDefaultBankName } from './bankDefaults'

describe('resolveDefaultBankName (FK-005/C1 — értéktár → bank = Raiffeisen)', () => {
  it('a Raiffeisent választja a törzsből, ha benne van', () => {
    const banks = [{ name: 'OTP Bank' }, { name: 'Raiffeisen Bank' }, { name: 'K&H Bank' }]
    expect(resolveDefaultBankName(banks)).toBe('Raiffeisen Bank')
  })

  it('kis/nagybetű-érzéketlen és részleges egyezést is elfogad', () => {
    expect(resolveDefaultBankName([{ name: 'RAIFFEISEN BANK Zrt.' }])).toBe('RAIFFEISEN BANK Zrt.')
  })

  it('kanonikus "Raiffeisen Bank"-ot ad, ha a törzs üres', () => {
    expect(resolveDefaultBankName([])).toBe('Raiffeisen Bank')
  })

  it('kanonikus nevet ad, ha a törzsben nincs Raiffeisen', () => {
    expect(resolveDefaultBankName([{ name: 'OTP Bank' }, { name: 'Erste Bank' }])).toBe(
      'Raiffeisen Bank',
    )
  })

  it('NEM aktiválódik véletlen substring-re (csak prefix-egyezés)', () => {
    expect(resolveDefaultBankName([{ name: 'Nem-Raiffeisen Takarék' }])).toBe('Raiffeisen Bank')
  })

  it('defenzív: null/undefined bemenet → kanonikus név, nincs kivétel', () => {
    expect(resolveDefaultBankName(null)).toBe('Raiffeisen Bank')
    expect(resolveDefaultBankName(undefined)).toBe('Raiffeisen Bank')
  })

  it('defenzív: name nélküli/üres elemeket átugorja', () => {
    expect(resolveDefaultBankName([{}, { name: null }, { name: 'Raiffeisen Bank' }])).toBe(
      'Raiffeisen Bank',
    )
  })
})
