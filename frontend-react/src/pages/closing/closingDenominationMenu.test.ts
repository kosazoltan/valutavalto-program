import { describe, it, expect } from 'vitest'
import {
  CLOSING_DENOMINATION_MENU,
  CLOSING_DENOMINATION_EXIT_ROUTE,
} from './closingDenominationMenu'

// EXCMD b5 FR-KC-05 — a „Címletezés – zárások" választó-menü adatai.
describe('CLOSING_DENOMINATION_MENU (FR-KC-05)', () => {
  it('a spec mind a 6 menüpontját tartalmazza, a forrás-képernyő sorrendjében', () => {
    expect(CLOSING_DENOMINATION_MENU.map((i) => i.id)).toEqual([
      'evening-closing',
      'handling-fee',
      'western-union',
      'afa-penztar',
      'foglalo-keszlet',
      'elektromos-kereskedes',
    ])
  })

  it('az aktív pontok (esti zárás + kezelési díj) a zárás-varázslóra visznek', () => {
    const active = CLOSING_DENOMINATION_MENU.filter((i) => !i.disabled)
    expect(active.map((i) => i.id)).toEqual(['evening-closing', 'handling-fee'])
    for (const item of active) {
      expect(item.route).toBe('/closing/wizard')
    }
  })

  it('FR-KC-05 kényszer: az inaktív (szürkített) pontoknak nincs route-juk — nem indíthatók', () => {
    const disabled = CLOSING_DENOMINATION_MENU.filter((i) => i.disabled)
    expect(disabled.map((i) => i.id)).toEqual([
      'western-union',
      'afa-penztar',
      'foglalo-keszlet',
      'elektromos-kereskedes',
    ])
    for (const item of disabled) {
      expect(item.route).toBeUndefined()
    }
  })

  it('a KILÉPÉS a pénztáros főmenübe visz', () => {
    expect(CLOSING_DENOMINATION_EXIT_ROUTE).toBe('/cashier')
  })
})
