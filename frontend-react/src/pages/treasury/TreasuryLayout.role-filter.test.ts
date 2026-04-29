import { describe, it, expect } from 'vitest'
import { allTreasuryTabs, CENTRAL_VAULT_ROLES, type TreasuryTab } from './TreasuryLayout'

/**
 * Role-filter logika tesztek — TreasuryLayout treasuryTabs szűrése canonicalRoles alapján.
 *
 * 2026-04-29 v2.3.10 (Sourcery PR #271): a duplikált tab-definíciók helyett
 * importáljuk a `TreasuryLayout.tsx`-ből a `allTreasuryTabs`, `CENTRAL_VAULT_ROLES`
 * és a `TreasuryTab` típust — így a teszt nem drift-elhet el a production UI-tól.
 *
 * A 2026-04-29-i fix után a `/treasury/rates` (Árfolyamkészítés F5),
 * `/treasury/bank` (Banki Tx F4), `/treasury/vat` (ÁFA visszatérítés F7),
 * `/treasury/trb-export` (TRB Export F8), `/treasury/bank-turnover` (Bankforgalom F10)
 * tabok csak `foertektar` vagy `ugyvezeto` canonical role esetén látszanak.
 *
 * Ld. D:\valutavalto-vault\references\legacy-anti-system.md §2.3 (főértéktár separation).
 */

function filterByRole(userRoles: string[]): TreasuryTab[] {
  return allTreasuryTabs.filter(
    (tab) => !tab.canonicalRoles || tab.canonicalRoles.some((r) => userRoles.includes(r)),
  )
}

describe('TreasuryLayout role-filter', () => {
  it('helyi értéktáros (csak ertektar role) NEM látja az Árfolyamkészítés/Banki Tx/ÁFA/TRB/Bankforgalom tabokat', () => {
    const tabs = filterByRole(['ertektar'])
    const visible = tabs.map((t) => t.path)
    expect(visible).toContain('/treasury')
    expect(visible).toContain('/treasury/matrix')
    expect(visible).toContain('/treasury/movements')
    expect(visible).toContain('/treasury/reports')
    expect(visible).toContain('/treasury/customer-turnover')
    // Ezeket NE lássa
    expect(visible).not.toContain('/treasury/rates')
    expect(visible).not.toContain('/treasury/bank')
    expect(visible).not.toContain('/treasury/vat')
    expect(visible).not.toContain('/treasury/trb-export')
    expect(visible).not.toContain('/treasury/bank-turnover')
  })

  it('foertektar role látja az összes tabot', () => {
    const tabs = filterByRole(['foertektar'])
    expect(tabs.map((t) => t.path)).toEqual(allTreasuryTabs.map((t) => t.path))
  })

  it('ugyvezeto role látja az összes tabot', () => {
    const tabs = filterByRole(['ugyvezeto'])
    expect(tabs.map((t) => t.path)).toEqual(allTreasuryTabs.map((t) => t.path))
  })

  it('penztar role csak az alapfunkciókat látja (Dashboard, Mátrix, Mozgások, Jelentések, Ügyfélforgalom)', () => {
    const tabs = filterByRole(['penztar'])
    const visible = tabs.map((t) => t.path)
    expect(visible).toEqual([
      '/treasury',
      '/treasury/matrix',
      '/treasury/movements',
      '/treasury/reports',
      '/treasury/customer-turnover',
    ])
  })

  it('üres role lista is csak az alapfunkciókat látja', () => {
    const tabs = filterByRole([])
    expect(tabs.length).toBe(5)
    expect(tabs.every((t) => !t.canonicalRoles)).toBe(true)
  })

  it('foertektar + ertektar (vegyes) látja az összeset', () => {
    const tabs = filterByRole(['ertektar', 'foertektar'])
    expect(tabs.length).toBe(allTreasuryTabs.length)
  })

  it('Árfolyamkészítés tab specifikusan: csak foertektar/ugyvezeto', () => {
    const ratesTab = allTreasuryTabs.find((t) => t.path === '/treasury/rates')
    expect(ratesTab).toBeDefined()
    expect(ratesTab?.canonicalRoles).toEqual(CENTRAL_VAULT_ROLES)
    expect(ratesTab?.label).toBe('Árfolyamkészítés')
    expect(ratesTab?.hotkey).toBe('F5')
  })

  it('CENTRAL_VAULT_ROLES tartalmazza foertektar és ugyvezeto-t', () => {
    expect(CENTRAL_VAULT_ROLES).toEqual(['foertektar', 'ugyvezeto'])
  })
})
