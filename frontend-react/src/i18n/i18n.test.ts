import { describe, it, expect, beforeAll } from 'vitest'
import i18n from './index'

/**
 * v2.4.0 (F: Sourcery #320 P3) — i18next setup unit tests.
 *
 * Cel:
 * 1. i18next initialized with hu locale
 * 2. fallback locale = hu
 * 3. common keys (Mentés, Mégse) load
 * 4. cashier keys (Vétel, Eladás) load
 * 5. nested key resolution (auth.login)
 * 6. fallback to key when missing
 * 7. interpolation (validation.minValue {{min}})
 */
describe('i18n setup', () => {
  beforeAll(async () => {
    // i18next is sync init in our setup, but ensure ready
    if (!i18n.isInitialized) {
      await i18n.init()
    }
  })

  it('initialized with hu locale', () => {
    expect(i18n.language).toBe('hu')
  })

  it('fallback locale is hu', () => {
    expect(i18n.options.fallbackLng).toEqual(['hu'])
  })

  it('loads common.save', () => {
    expect(i18n.t('common.save')).toBe('Mentés')
  })

  it('loads common.cancel', () => {
    expect(i18n.t('common.cancel')).toBe('Mégse')
  })

  it('loads common.actions (uppercase)', () => {
    expect(i18n.t('common.actions')).toBe('Műveletek')
  })

  it('loads cashier.buy', () => {
    expect(i18n.t('cashier.buy')).toBe('Vétel')
  })

  it('loads cashier.sell', () => {
    expect(i18n.t('cashier.sell')).toBe('Eladás')
  })

  it('loads cashier.storno (with accent)', () => {
    expect(i18n.t('cashier.storno')).toBe('Sztornó')
  })

  it('loads auth.login', () => {
    expect(i18n.t('auth.login')).toBe('Bejelentkezés')
  })

  it('loads branch.branchGroup (B14 fix)', () => {
    expect(i18n.t('branch.branchGroup')).toBe('Fiókcsoport')
  })

  it('returns key when missing (no throw)', () => {
    expect(i18n.t('nonexistent.key')).toBe('nonexistent.key')
  })

  it('interpolation works (validation.minValue)', () => {
    expect(i18n.t('validation.minValue', { min: 5 })).toBe('Minimum: 5')
  })

  // v2.4.X i18n batch1 — TransferDocument + MonthlyClose + StockSnapshot pages
  it('loads transferReceipts.title (with accents)', () => {
    expect(i18n.t('transferReceipts.title')).toBe('Átutalási bizonylatok')
  })

  it('loads transferReceipts.fromBranch (Forráspénztár)', () => {
    expect(i18n.t('transferReceipts.fromBranch')).toBe('Forráspénztár')
  })

  it('loads transferReceipts.toBranch (Célpénztár)', () => {
    expect(i18n.t('transferReceipts.toBranch')).toBe('Célpénztár')
  })

  it('loads monthlyClose.title (Havi zárás)', () => {
    expect(i18n.t('monthlyClose.title')).toBe('Havi zárás')
  })

  it('loads monthlyClose.month (Hónap)', () => {
    expect(i18n.t('monthlyClose.month')).toBe('Hónap')
  })

  it('loads monthlyClose.closedAt (Zárás ideje)', () => {
    expect(i18n.t('monthlyClose.closedAt')).toBe('Zárás ideje')
  })

  it('loads stockSnapshot.title (Készlet pillanatkép)', () => {
    expect(i18n.t('stockSnapshot.title')).toBe('Készlet pillanatkép')
  })

  it('loads stockSnapshot.lastUpdated (Frissítve)', () => {
    expect(i18n.t('stockSnapshot.lastUpdated')).toBe('Frissítve')
  })

  it('loads common.searchPlaceholder', () => {
    expect(i18n.t('common.searchPlaceholder')).toBe('Keresés...')
  })

  it('loads common.exportExcel', () => {
    expect(i18n.t('common.exportExcel')).toBe('Excel letöltés')
  })

  it('interpolation works (stockSnapshot.regionBranchCount)', () => {
    expect(i18n.t('stockSnapshot.regionBranchCount', { count: 5 })).toBe('5 pénztár')
  })

  // FK-085 FR-2: az 5-devizás KÉSZLET fejléc i18n kulcsa betöltődik
  it('loads foertektar.keszletOtDeviza (5 currencies)', () => {
    expect(i18n.t('foertektar.keszletOtDeviza')).toBe('Készlet (EUR / USD / GBP / CHF / HUF)')
  })
})
