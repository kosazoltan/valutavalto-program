import { describe, it, expect } from 'vitest'
import {
  VAULT_COUNTERPARTY_CODES,
  isBankPartner,
  excludeBankPartners,
} from './bankPartners'

describe('FK-014 – bankPartners', () => {
  describe('isBankPartner', () => {
    it('mind a 10 fix VAULT_COUNTERPARTY kód banki partner (branchCode)', () => {
      for (const code of VAULT_COUNTERPARTY_CODES) {
        expect(isBankPartner({ branchCode: code })).toBe(true)
      }
    })

    it('a 10 kód `code` mezőből is felismerhető (BranchOption alak)', () => {
      expect(isBankPartner({ code: 'ERB' })).toBe(true)
      expect(isBankPartner({ code: 'FOP1' })).toBe(true)
    })

    it('strukturális: branchTypeCode === VAULT_COUNTERPARTY → banki partner (kód nélkül is)', () => {
      expect(isBankPartner({ branchTypeCode: 'VAULT_COUNTERPARTY' })).toBe(true)
      expect(isBankPartner({ branchCode: 'BR999', branchTypeCode: 'VAULT_COUNTERPARTY' })).toBe(true)
    })

    it('kis/nagybetű és körbevevő whitespace toleráns', () => {
      expect(isBankPartner({ branchCode: ' erb ' })).toBe(true)
      expect(isBankPartner({ branchTypeCode: ' vault_counterparty ' })).toBe(true)
    })

    it('valódi iroda (pénztár/értéktár) NEM banki partner', () => {
      expect(isBankPartner({ branchCode: 'BR010' })).toBe(false) // Szekszárd Értéktár
      expect(isBankPartner({ branchCode: 'BR100' })).toBe(false) // Kalocsa pénztár
      expect(isBankPartner({ code: 'BR145', branchTypeCode: 'ERTEKTAR' })).toBe(false)
    })

    it('üres/hiányzó kód → nem banki partner (nincs téves kizárás)', () => {
      expect(isBankPartner({})).toBe(false)
      expect(isBankPartner({ branchCode: '' })).toBe(false)
      expect(isBankPartner({ branchCode: null, code: null })).toBe(false)
    })

    it('részleges egyezés NEM számít (pl. RB ⊄ BR... vagy ...RB)', () => {
      expect(isBankPartner({ branchCode: 'BR050' })).toBe(false)
      expect(isBankPartner({ branchCode: 'TRBX' })).toBe(false)
    })
  })

  describe('excludeBankPartners', () => {
    it('csak a valódi irodák maradnak; a 10 partner kiesik', () => {
      const rows = [
        { branchCode: 'BR010', branchName: 'Szekszárd Értéktár' },
        { branchCode: 'BR100', branchName: 'Kalocsa' },
        { branchCode: 'ERB', branchName: 'Egyedi Raiffeisen' },
        { branchCode: 'MNB', branchName: 'Magyar Nemzeti Bank' },
        { branchCode: 'TH', branchName: 'Többlet/Hiány' },
        { branchCode: 'FOP1', branchName: '1-es főpénztár' },
      ]
      const result = excludeBankPartners(rows)
      expect(result.map((r) => r.branchCode)).toEqual(['BR010', 'BR100'])
    })

    it('megőrzi az elemek típusát/extra mezőit', () => {
      const rows = [{ code: 'BR020', name: 'Szeged', isActive: true }, { code: 'PRB', name: 'POS Raiffeisen' }]
      const result = excludeBankPartners(rows)
      expect(result).toEqual([{ code: 'BR020', name: 'Szeged', isActive: true }])
    })

    it('üres lista → üres lista', () => {
      expect(excludeBankPartners([])).toEqual([])
    })
  })
})
