import { describe, it, expect } from 'vitest'
import { buildOtherTasksMenu, OTHER_TASKS_EXIT_ROUTE } from './otherTasksMenu'

// EXCMD b6b FR-EFM-01/02/03/04 — a két menü-variáns tiszta logikája.
describe('buildOtherTasksMenu (FR-EFM-01: konfiguráció szerinti variáns)', () => {
  it('NAV-aktív konfiguráció → Variáns 1 (7 pont, NAV-parancsok), POS-pontok nélkül', () => {
    const items = buildOtherTasksMenu(true)
    const ids = items.map((i) => i.id)
    expect(ids).toEqual([
      'settings',
      'nav-clear-currencies',
      'nav-load-currencies',
      'nav-day-open',
      'nav-day-close',
      'nav-com-port',
      'exit',
    ])
    expect(ids).not.toContain('otp-pos')
    expect(ids).not.toContain('customer-maintenance')
  })

  it('NAV-inaktív konfiguráció → Variáns 2 (6 pont, OTP POS + adatlapok + ügyfél), NAV-parancsok nélkül', () => {
    const items = buildOtherTasksMenu(false)
    const ids = items.map((i) => i.id)
    expect(ids).toEqual([
      'settings',
      'cash-register-commands',
      'otp-pos',
      'datasheets',
      'customer-maintenance',
      'exit',
    ])
    expect(ids).not.toContain('nav-day-open')
    expect(ids).not.toContain('nav-day-close')
  })

  it('FR-EFM-04: a KILÉPÉS mindkét variáns utolsó pontja, és a pénztáros főmenübe visz', () => {
    for (const navActive of [true, false]) {
      const items = buildOtherTasksMenu(navActive)
      const last = items.at(-1)
      expect(last?.id).toBe('exit')
      expect(last?.route).toBe(OTHER_TASKS_EXIT_ROUTE)
      expect(OTHER_TASKS_EXIT_ROUTE).toBe('/cashier')
    }
  })

  it('minden menüpontnak van nem üres címkéje és "/"-rel kezdődő route-ja', () => {
    for (const navActive of [true, false]) {
      for (const item of buildOtherTasksMenu(navActive)) {
        expect(item.label.trim().length).toBeGreaterThan(0)
        expect(item.route.startsWith('/')).toBe(true)
      }
    }
  })

  it('a két variáns nem látszik egyszerre: nincs közös NAV/POS-specifikus pont', () => {
    const navIds = new Set(buildOtherTasksMenu(true).map((i) => i.id))
    const posIds = new Set(buildOtherTasksMenu(false).map((i) => i.id))
    const shared = [...navIds].filter((id) => posIds.has(id))
    // Csak a mindkét variánsban specifikált közös pontok: beállítások + kilépés.
    expect(shared.sort()).toEqual(['exit', 'settings'])
  })
})
