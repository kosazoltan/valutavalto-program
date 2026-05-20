import { describe, it, expect } from 'vitest'
import { getAvailableTransferTypes, getAllowedTransferTypeValues, isHufOnlyTransferType, filterCurrenciesForType, buildTransferLines } from './transferRules'

const currencies = [
  { id: 1, code: 'HUF', name: 'Forint' },
  { id: 2, code: 'EUR', name: 'Euró' },
  { id: 3, code: 'USD', name: 'Dollár' },
]

describe('transferRules — átadás-átvétel üzleti szabályok', () => {
  describe('getAvailableTransferTypes (Req #2 + #3)', () => {
    it('pénztár (nem értéktár): CSAK forint / valuta / kezelési költség — értéktári feltöltés NINCS', () => {
      const types = getAvailableTransferTypes(false, 'out').map(t => t.value)
      expect(types).toEqual(['CASH', 'CURRENCY', 'HANDLING_FEE'])
      expect(types).not.toContain('VAULT_DEPOSIT')
      expect(types).not.toContain('VAULT_WITHDRAW')
    })

    it('értéktár felhasználó: a feltöltés/leszedés is választható', () => {
      const types = getAvailableTransferTypes(true, 'out').map(t => t.value)
      expect(types).toContain('VAULT_DEPOSIT')
      expect(types).toContain('VAULT_WITHDRAW')
    })

    it('átadás iránynál a címke "átadás"', () => {
      const labels = getAvailableTransferTypes(false, 'out').map(t => t.label)
      expect(labels).toContain('Valuta átadás')
      expect(labels).toContain('Forint (HUF) átadás')
      expect(labels).toContain('Kezelési költség átadás')
    })

    it('átvétel iránynál a címke "átvétel" (Req #2)', () => {
      const labels = getAvailableTransferTypes(false, 'in').map(t => t.label)
      expect(labels).toContain('Valuta átvétel')
      expect(labels).toContain('Forint (HUF) átvétel')
      expect(labels).toContain('Kezelési költség átvétel')
      expect(labels).not.toContain('Valuta átadás')
    })
  })

  describe('filterCurrenciesForType (Req #4 + #5)', () => {
    it('FT (CASH) típus → CSAK HUF', () => {
      const result = filterCurrenciesForType(currencies, 'CASH').map(c => c.code)
      expect(result).toEqual(['HUF'])
    })

    it('kezelési költség → CSAK HUF', () => {
      const result = filterCurrenciesForType(currencies, 'HANDLING_FEE').map(c => c.code)
      expect(result).toEqual(['HUF'])
    })

    it('valuta (CURRENCY) típus → HUF NÉLKÜL (csak deviza)', () => {
      const result = filterCurrenciesForType(currencies, 'CURRENCY').map(c => c.code)
      expect(result).toEqual(['EUR', 'USD'])
      expect(result).not.toContain('HUF')
    })

    it('értéktári feltöltés → minden valuta', () => {
      const result = filterCurrenciesForType(currencies, 'VAULT_DEPOSIT').map(c => c.code)
      expect(result).toEqual(['HUF', 'EUR', 'USD'])
    })
  })

  describe('getAllowedTransferTypeValues (DRY — single source of truth)', () => {
    it('pénztár: csak CASH/CURRENCY/HANDLING_FEE', () => {
      expect(getAllowedTransferTypeValues(false)).toEqual(['CASH', 'CURRENCY', 'HANDLING_FEE'])
    })
    it('értéktár: VAULT_* is benne', () => {
      expect(getAllowedTransferTypeValues(true)).toContain('VAULT_DEPOSIT')
    })
    it('konzisztens a getAvailableTransferTypes value-listájával (nincs drift)', () => {
      for (const vault of [true, false]) {
        expect(getAllowedTransferTypeValues(vault))
          .toEqual(getAvailableTransferTypes(vault, 'in').map(o => o.value))
      }
    })
  })

  describe('buildTransferLines (#6 több-valutás átadólap)', () => {
    it('érvényes sorok → lines tömb, nincs hiba; üres sor kihagyva', () => {
      const r = buildTransferLines([
        { currencyId: 2, amount: '100' },
        { currencyId: 3, amount: '200,5' },
        { currencyId: null, amount: '' },
      ])
      expect(r.error).toBeNull()
      expect(r.lines).toEqual([{ currencyId: 2, amount: 100 }, { currencyId: 3, amount: 200.5 }])
    })
    it('duplikált valuta → hiba', () => {
      const r = buildTransferLines([{ currencyId: 2, amount: '100' }, { currencyId: 2, amount: '50' }])
      expect(r.error).toContain('egyszer')
      expect(r.lines).toEqual([])
    })
    it('nem pozitív összeg → hiba', () => {
      const r = buildTransferLines([{ currencyId: 2, amount: '0' }])
      expect(r.error).toContain('pozitív')
    })
    it('nincs érvényes sor → hiba', () => {
      const r = buildTransferLines([{ currencyId: null, amount: '' }])
      expect(r.error).toContain('Legalább egy')
    })
  })

  describe('isHufOnlyTransferType', () => {
    it('CASH és HANDLING_FEE → true; CURRENCY → false', () => {
      expect(isHufOnlyTransferType('CASH')).toBe(true)
      expect(isHufOnlyTransferType('HANDLING_FEE')).toBe(true)
      expect(isHufOnlyTransferType('CURRENCY')).toBe(false)
      expect(isHufOnlyTransferType('VAULT_DEPOSIT')).toBe(false)
    })
  })
})
