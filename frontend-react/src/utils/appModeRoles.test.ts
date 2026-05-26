import { describe, expect, it } from 'vitest'
import { canonicalizeRoleForAppMode, isRoleSelectableForAppMode, selectableLocalAppModes, preferredRoleForAppMode } from './appModeRoles'

describe('selectableLocalAppModes (HIBA 2026-05-26 mód-választó)', () => {
  it('üres/hiányzó validAppModes → üres lista', () => {
    expect(selectableLocalAppModes(undefined)).toEqual([])
    expect(selectableLocalAppModes(null)).toEqual([])
    expect(selectableLocalAppModes([])).toEqual([])
  })

  it('tiszta pénztáros (csak penztar) → 1 mód (nincs választó)', () => {
    expect(selectableLocalAppModes(['penztar'])).toEqual(['penztar'])
  })

  it('értéktáros (penztar + ertektar) → 2 mód, megjelenítési sorrendben', () => {
    expect(selectableLocalAppModes(['ertektar', 'penztar'])).toEqual(['penztar', 'ertektar'])
  })

  it('a full/rate-maker módokat kiszűri a lokál terminál választójából', () => {
    expect(selectableLocalAppModes(['penztar', 'ertektar', 'full', 'rate-maker'])).toEqual(['penztar', 'ertektar'])
  })
})

describe('preferredRoleForAppMode', () => {
  it('a módra kanonikusan illeszkedő role-t választja', () => {
    expect(preferredRoleForAppMode(['ertektar', 'penztar'], 'ertektar', null)).toBe('ertektar')
    expect(preferredRoleForAppMode(['ertektar', 'penztar'], 'penztar', null)).toBe('penztar')
  })

  it('ha nincs kanonikus illeszkedés, bármely a módban választható role', () => {
    expect(preferredRoleForAppMode(['ertektar'], 'penztar', null)).toBe('ertektar')
  })

  it('üres roles → fallback role', () => {
    expect(preferredRoleForAppMode([], 'ertektar', 'ertektar')).toBe('ertektar')
    expect(preferredRoleForAppMode(null, 'penztar', 'CASHIER')).toBe('CASHIER')
  })

  it('nincs használható role → null', () => {
    expect(preferredRoleForAppMode([], 'ertektar', null)).toBeNull()
    expect(preferredRoleForAppMode([], 'ertektar', '   ')).toBeNull()
  })

  // Codex P1 #860: lokál módnál a lista-sorrend miatt NE kerüljön be magasabb jogú
  // szerver-role, ha van a módra használható lokál role (least-privilege).
  it('lokál módnál a lokál role-t preferálja a szerver-role előtt (over-grant védelem)', () => {
    // foertektar (szerver) ELŐL a listában, de penztar módhoz az ertektar (lokál) a helyes
    expect(preferredRoleForAppMode(['foertektar', 'ertektar'], 'penztar', null)).toBe('ertektar')
    // sorrendtől függetlenül ugyanaz az eredmény (determinisztikus)
    expect(preferredRoleForAppMode(['ertektar', 'foertektar'], 'penztar', null)).toBe('ertektar')
  })

  it('lokál módnál ha NINCS lokál role, az inspection (szerver) role marad a fallback', () => {
    // pl. területi vezető penztár-ellenőrzéshez: csak szerver-role-ja van → azt kapja
    expect(preferredRoleForAppMode(['foertektar'], 'penztar', null)).toBe('foertektar')
  })

  it('full (szerver) módnál NEM szűkít lokál role-ra (a 2. lépés csak lokál módra fut)', () => {
    expect(preferredRoleForAppMode(['foertektar'], 'full', null)).toBe('foertektar')
  })
})

describe('isRoleSelectableForAppMode', () => {
  it('lokalis role-t barmely lokalis appMode-ban enged (kis iroda flexibilitas)', () => {
    // Sajat modban: igen
    expect(isRoleSelectableForAppMode('penztar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('ertektar', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ertekszallito', 'ertekszallito')).toBe(true)
    // Keresztbe: szinten igen (kis irodakban egy dolgozo tobb modban dolgozhat)
    expect(isRoleSelectableForAppMode('ertektar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('penztar', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ertekszallito', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('penztar', 'ertekszallito')).toBe(true)
  })

  it('lokalis role-t full (szerver/browser) modban NEM enged', () => {
    expect(isRoleSelectableForAppMode('penztar', 'full')).toBe(false)
    expect(isRoleSelectableForAppMode('ertektar', 'full')).toBe(false)
    expect(isRoleSelectableForAppMode('ertekszallito', 'full')).toBe(false)
  })

  it('server role-t full es lokalis felugyeleti belepeshez is enged', () => {
    expect(isRoleSelectableForAppMode('foertektar', 'full')).toBe(true)
    expect(isRoleSelectableForAppMode('teruleti_vezeto', 'full')).toBe(true)
    expect(isRoleSelectableForAppMode('biztonsagi_vezeto', 'full')).toBe(true)
    expect(isRoleSelectableForAppMode('foertektar', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('ADMIN', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('ugyvezeto', 'ertekszallito')).toBe(true)
  })

  it('rate-maker modban csak foertektar, ugyvezeto es admin lephet be', () => {
    expect(isRoleSelectableForAppMode('foertektar', 'rate-maker')).toBe(true)
    expect(isRoleSelectableForAppMode('ugyvezeto', 'rate-maker')).toBe(true)
    expect(isRoleSelectableForAppMode('ADMIN', 'rate-maker')).toBe(true)
    expect(isRoleSelectableForAppMode('irodavezeto', 'rate-maker')).toBe(false)
    expect(isRoleSelectableForAppMode('penztar', 'rate-maker')).toBe(false)
  })

  it('legacy courier role-t barmely lokalis modban enged', () => {
    expect(isRoleSelectableForAppMode('COURIER', 'ertekszallito')).toBe(true)
    expect(isRoleSelectableForAppMode('COURIER', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('COURIER', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('COURIER', 'full')).toBe(false)
    expect(canonicalizeRoleForAppMode('COURIER')).toBe('ertekszallito')
  })

  it('legacy penztar role-t barmely lokalis modban enged', () => {
    expect(isRoleSelectableForAppMode('CASHIER', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('CASHIER', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('CASHIER', 'ertekszallito')).toBe(true)
    expect(isRoleSelectableForAppMode('CASHIER', 'full')).toBe(false)
  })

  it('legacy ertektar role-t barmely lokalis modban enged', () => {
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'ertektar')).toBe(true)
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'penztar')).toBe(true)
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'ertekszallito')).toBe(true)
    expect(isRoleSelectableForAppMode('TREASURY_MANAGER', 'full')).toBe(false)
  })

  it('hianyzo role-t minden appMode-ban elutasit', () => {
    expect(isRoleSelectableForAppMode(null, 'penztar')).toBe(false)
    expect(isRoleSelectableForAppMode(undefined, 'ertektar')).toBe(false)
  })
})
