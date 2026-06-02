import { describe, it, expect } from 'vitest'
import { getAvailableTransferTypes, getAllowedTransferTypeValues, isHufOnlyTransferType, filterCurrenciesForType, buildTransferLines, filterTransferTargetBranches, isMainCashierBranch, validateCarrierSeal } from './transferRules'

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
    it('részben kitöltött sor (összeg valuta nélkül) → hiba (Codex #726)', () => {
      const r = buildTransferLines([{ currencyId: 2, amount: '100' }, { currencyId: null, amount: '50' }])
      expect(r.error).toContain('Válasszon valutát')
      expect(r.lines).toEqual([])
    })
  })

  describe('filterTransferTargetBranches (#1 cél-fiók szűrés)', () => {
    const own = { id: 'p1', code: 'BR013', name: 'Pécs Tesco', region: 'PECS', isVault: false }
    const branches = [
      own,
      { id: 'p2', code: 'BR125', name: 'Pécs Árkád', region: 'PECS', isVault: false },        // sima pénztár, kizárva
      { id: 'v1', code: 'VAULT-PECS', name: 'Pécs Értéktár', region: 'PECS', isVault: true },  // saját terület értéktára → benne
      { id: 'v2', code: 'VAULT-BP', name: 'Budapest Értéktár', region: 'BUDAPEST', isVault: true }, // más terület → kizárva
      { id: 'th', code: 'TH01', name: 'Többlet-hiány', region: 'PECS', isVault: false }, // TH KÓD-PREFIX (nincs branchTypeCode) → benne
      { id: 'fp', code: 'BR001', name: 'Egyes számú pénztár', region: 'PECS', isVault: false }, // 1.sz Főpénztár → benne
    ]
    it('csak: saját terület értéktára + TH (kód-prefix) + Egyes számú pénztár', () => {
      const ids = filterTransferTargetBranches(branches, own).map(b => b.id)
      expect(ids).toContain('v1')   // saját terület értéktár
      expect(ids).toContain('th')   // TH kód-prefix (TH01)
      expect(ids).toContain('fp')   // Egyes számú pénztár
      expect(ids).not.toContain('p2') // sima pénztár
      expect(ids).not.toContain('v2') // más terület értéktára
    })
    it('isMainCashierBranch SZŰK: nem match-el general nevet', () => {
      expect(isMainCashierBranch({ id: 'x', code: 'BR500', name: 'Pécs Plaza pénztár' })).toBe(false)
      expect(isMainCashierBranch({ id: 'f', code: 'BR001', name: 'Egyes számú pénztár' })).toBe(true)
      expect(isMainCashierBranch({ id: 'f2', code: 'BR002', name: '1.sz Főpénztár' })).toBe(true)
    })
    it('üres-fallback: ha a szűrő 0 fiókot adna, MINDET visszaadja', () => {
      const onlyPlain = [{ id: 'x', code: 'BR999', name: 'Sima Pénztár', region: 'PECS', isVault: false }]
      expect(filterTransferTargetBranches(onlyPlain, own)).toEqual(onlyPlain)
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

describe('validateCarrierSeal — átadás-átvétel szállító + plombaszám (FK02)', () => {
  it('érvényes szállító + plombaszám esetén null-t ad vissza', () => {
    expect(validateCarrierSeal("Brink's Hungary Kft.", 'ABC/12-3')).toBeNull()
  })

  it('hiányzó szállító név esetén hibát ad', () => {
    expect(validateCarrierSeal('', 'ABC-1')).toBe('A szállító nevének megadása kötelező!')
  })

  it('csak whitespace szállító név esetén hibát ad (trim után üres)', () => {
    expect(validateCarrierSeal('   ', 'ABC-1')).toBe('A szállító nevének megadása kötelező!')
  })

  it('hiányzó plombaszám esetén hibát ad', () => {
    expect(validateCarrierSeal('Brink', '')).toBe('A plombaszám megadása kötelező!')
  })

  it('csak whitespace plombaszám esetén hibát ad', () => {
    expect(validateCarrierSeal('Brink', '   ')).toBe('A plombaszám megadása kötelező!')
  })

  it('128 karakternél hosszabb szállító név esetén hibát ad', () => {
    expect(validateCarrierSeal('a'.repeat(129), 'ABC-1')).toBe('A szállító neve legfeljebb 128 karakter lehet!')
  })

  it('64 karakternél hosszabb plombaszám esetén hibát ad', () => {
    expect(validateCarrierSeal('Brink', 'A'.repeat(65))).toBe('A plombaszám legfeljebb 64 karakter lehet!')
  })

  it('érvénytelen karaktert tartalmazó plombaszám esetén hibát ad', () => {
    expect(validateCarrierSeal('Brink', 'ABC 123')).toBe('A plombaszám csak betűt, számot, kötőjelet és perjelet tartalmazhat!')
    expect(validateCarrierSeal('Brink', 'ABC#1')).toBe('A plombaszám csak betűt, számot, kötőjelet és perjelet tartalmazhat!')
  })
})
