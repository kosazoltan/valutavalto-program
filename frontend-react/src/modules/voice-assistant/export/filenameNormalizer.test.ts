import { describe, it, expect } from 'vitest'
import { normalizeForFilename, buildExportFilename } from './filenameNormalizer'

/**
 * EBC Hangsegéd filename normalizer egységtesztek.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md Fázis 5 acceptance.
 */
describe('normalizeForFilename', () => {
  it('magyar ekezetes karaktereket ASCII-ra cserel', () => {
    expect(normalizeForFilename('Árfolyamkészítő hibajelzés')).toBe('Arfolyamkeszito_hibajelzes')
  })

  it('Windows-tilalmas karaktereket eltavolit', () => {
    expect(normalizeForFilename('Hi:ba"<>|?*báz/is\\test')).toBe('Hi_ba_baz_is_test')
  })

  it('ures input eseten a fallbacket adja vissza', () => {
    expect(normalizeForFilename('', 'fallback')).toBe('fallback')
    expect(normalizeForFilename('!!!', 'fb')).toBe('fb')
  })

  it('tobbszoros underscore-okat egyre redukal', () => {
    expect(normalizeForFilename('a   b---c')).toBe('a_b---c')
  })

  it('eleje + vege underscore/pont/kotojel-trimmet csinal', () => {
    expect(normalizeForFilename('___teszt___')).toBe('teszt')
    expect(normalizeForFilename('.teszt.')).toBe('teszt')
  })
})

describe('buildExportFilename', () => {
  it('helyes formatum: YYYY-MM-DD-<title>.md', () => {
    const fn = buildExportFilename('2026-05-18T10:30:00.000Z', 'Bevétel rögzítési hiba')
    expect(fn).toBe('2026-05-18-Bevetel_rogzitesi_hiba.md')
  })

  it('extension fuggetlen a pontok szamatol', () => {
    const fn = buildExportFilename('2026-05-18', 'X', '..md')
    expect(fn).toBe('2026-05-18-X.md')
  })

  it('alapertelmezett fallback', () => {
    const fn = buildExportFilename('2026-05-18', '')
    expect(fn).toBe('2026-05-18-hibajelzes.md')
  })
})
