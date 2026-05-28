import { describe, it, expect } from 'vitest'
import {
  validateWorkgroupProtection,
  workgroupProtectionLabel,
  type ProtectionRow,
} from './workgroupProtection'

/** Teszt-segéd: alap szabályos sor (L=395 ≤ J=400 ≤ M=405), minden kedvezménysáv üres. */
function row(overrides: Partial<ProtectionRow> = {}): ProtectionRow {
  return {
    currencyCode: 'EUR',
    official: 400,
    buy: 395,
    sell: 405,
    limit1Buy: 0,
    limit1Sell: 0,
    limit2Buy: 0,
    limit2Sell: 0,
    limit3Buy: 0,
    limit3Sell: 0,
    ...overrides,
  }
}

describe('validateWorkgroupProtection (FK-04/E)', () => {
  it('védelem KI → mindig üres lista, akkor is ha sért', () => {
    const rows = [row({ buy: 999 })] // L > J, de védelem ki
    expect(validateWorkgroupProtection(rows, false, '3-es csoport')).toEqual([])
  })

  it('szabályos ráta (L≤J≤M) → nincs sértés', () => {
    expect(validateWorkgroupProtection([row()], true, '3-es csoport')).toEqual([])
  })

  it('vételi (L) > J → magyar "magasabb" üzenet, kód + csoport + oszlop', () => {
    const v = validateWorkgroupProtection([row({ buy: 410 })], true, '3-es csoport')
    expect(v).toHaveLength(1)
    expect(v[0]!.column).toBe('L vétel')
    expect(v[0]!.message).toBe('3-es csoport EUR L vétel nem lehet magasabb az elszámolónál (410 > 400).')
  })

  it('eladási (M) < J → magyar "alacsonyabb" üzenet', () => {
    const v = validateWorkgroupProtection([row({ sell: 390 })], true, '7-es csoport')
    expect(v).toHaveLength(1)
    expect(v[0]!.column).toBe('M eladás')
    expect(v[0]!.message).toBe('7-es csoport EUR M eladás nem lehet alacsonyabb az elszámolónál (390 < 400).')
  })

  it('kedvezménysávok (N,P,R / O,Q,S) is ellenőrződnek', () => {
    const v = validateWorkgroupProtection(
      [row({ limit1Buy: 401, limit2Buy: 402, limit3Buy: 403, limit1Sell: 399, limit2Sell: 398, limit3Sell: 397 })],
      true,
      '1-es csoport',
    )
    const cols = v.map((x) => x.column).sort()
    expect(cols).toEqual(['N vétel', 'O eladás', 'P vétel', 'Q eladás', 'R vétel', 'S eladás'].sort())
  })

  it('üres (0) cellákat NEM ellenőrzi (kötelező-ráta külön szabály)', () => {
    // sell=0 < J=400 lenne, de 0 = nem beállított → kihagyva
    const v = validateWorkgroupProtection([row({ sell: 0, buy: 0, official: 400 })], true, '1-es csoport')
    expect(v).toEqual([])
  })

  it('J=null vagy J<=0 → a sort kihagyja (nincs referencia)', () => {
    expect(validateWorkgroupProtection([row({ official: null, buy: 999 })], true, '1-es csoport')).toEqual([])
    expect(validateWorkgroupProtection([row({ official: 0, buy: 999 })], true, '1-es csoport')).toEqual([])
  })

  it('több valuta, vegyes sértés → minden sértés külön bejegyzés', () => {
    const v = validateWorkgroupProtection(
      [row({ currencyCode: 'EUR', buy: 410 }), row({ currencyCode: 'USD', official: 360, buy: 355, sell: 350 })],
      true,
      '2-es csoport',
    )
    expect(v).toHaveLength(2)
    expect(v.map((x) => x.currencyCode)).toEqual(['EUR', 'USD'])
  })
})

describe('workgroupProtectionLabel', () => {
  it('sorszámból "X-es csoport"', () => {
    expect(workgroupProtectionLabel(3, 'WG-3')).toBe('3-es csoport')
  })
  it('sorszám hiányában "(KÓD) csoport"', () => {
    expect(workgroupProtectionLabel(null, 'WG-X')).toBe('(WG-X) csoport')
    expect(workgroupProtectionLabel(undefined, 'ABC')).toBe('(ABC) csoport')
  })
})
