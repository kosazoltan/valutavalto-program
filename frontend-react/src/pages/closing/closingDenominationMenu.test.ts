import { describe, it, expect } from 'vitest'
import {
  CLOSING_DENOMINATION_MENU,
  CLOSING_DENOMINATION_EXIT_ROUTE,
} from './closingDenominationMenu'

// EXCMD b5 FR-KC-05 — a „Címletezés – zárások" választó-menü adatai.
describe('CLOSING_DENOMINATION_MENU (FR-KC-05)', () => {
  // FK-078 FR-6: az „Elektromos kereskedés" csempe eltávolítva — 5 pont a korábbi 6 helyett.
  it('az 5 megmaradó menüpontot tartalmazza, a forrás-képernyő sorrendjében', () => {
    expect(CLOSING_DENOMINATION_MENU.map((i) => i.id)).toEqual([
      'evening-closing',
      'handling-fee',
      'western-union',
      'afa-penztar',
      'foglalo-keszlet',
    ])
  })

  it('FK-078 FR-6: az elektromos kereskedés csempe nem jelenik meg', () => {
    expect(CLOSING_DENOMINATION_MENU.some((i) => i.id === 'elektromos-kereskedes')).toBe(false)
  })

  // FK-078 FR-1: az aktív pontok már NEM a zárás-varázslóra, hanem a közös,
  // kategória-tudatos becímletező oldalra visznek.
  it('FK-078 FR-1: az aktív pontok a becímletező oldalra visznek, kategóriával', () => {
    const active = CLOSING_DENOMINATION_MENU.filter((i) => !i.disabled)
    expect(active.map((i) => i.id)).toEqual(['evening-closing', 'handling-fee'])
    expect(active.map((i) => i.route)).toEqual([
      '/closing/denomination-entry/EVENING',
      '/closing/denomination-entry/HANDLING_FEE',
    ])
    for (const item of active) {
      expect(item.route).not.toBe('/closing/wizard')
    }
  })

  it('FR-KC-05 kényszer: az inaktív (szürkített) pontoknak nincs route-juk — nem indíthatók', () => {
    const disabled = CLOSING_DENOMINATION_MENU.filter((i) => i.disabled)
    // FK-078 FR-8: a WU / ÁFA / Foglaló változatlanul, inaktívan marad.
    expect(disabled.map((i) => i.id)).toEqual(['western-union', 'afa-penztar', 'foglalo-keszlet'])
    for (const item of disabled) {
      expect(item.route).toBeUndefined()
    }
  })

  it('a KILÉPÉS a pénztáros főmenübe visz', () => {
    expect(CLOSING_DENOMINATION_EXIT_ROUTE).toBe('/cashier')
  })
})
