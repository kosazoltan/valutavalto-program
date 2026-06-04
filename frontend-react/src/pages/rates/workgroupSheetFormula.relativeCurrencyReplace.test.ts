import { describe, it, expect } from 'vitest'
import { replaceFormulaCurrency } from './workgroupSheetFormula'

/**
 * FK02-D — FR-1..4 + TBD-4: relatív valutakód-csere lehúzáskor.
 * A `!<oszlop><KÓD>` hivatkozás kódja a célsor valutájára cserélődik, DE CSAK ha a kód
 * megegyezik a forrássor valutájával. A `#NN` és az egybetűs self-refek változatlanok.
 */
describe('replaceFormulaCurrency — relatív valutakód-csere (FK02-D)', () => {
  it('FR-1: !EAUD (AUD sorból) lehúzva BAM-ra → !EBAM', () => {
    expect(replaceFormulaCurrency('!EAUD', 'AUD', 'BAM')).toBe('!EBAM')
  })

  it('FR-1: !EAUD → !EBRL (másik célsor)', () => {
    expect(replaceFormulaCurrency('!EAUD', 'AUD', 'BRL')).toBe('!EBRL')
  })

  it('FR-2: #02L (csoportközi) NEM tartalmaz valutakódot → változatlan', () => {
    expect(replaceFormulaCurrency('#02L', 'AUD', 'BAM')).toBe('#02L')
  })

  it('FR-4: !EAUD*0.97 (összetett képlet) → !EBAM*0.97', () => {
    expect(replaceFormulaCurrency('!EAUD*0.97', 'AUD', 'BAM')).toBe('!EBAM*0.97')
  })

  it('FR-3: több hivatkozás egy képletben — mind a forrás-kódot cseréli', () => {
    expect(replaceFormulaCurrency('(!EAUD+!FAUD)/2', 'AUD', 'BAM')).toBe('(!EBAM+!FBAM)/2')
  })

  it('TBD-4: !FEUR az EUA sorból (EUR ≠ EUA) → NEM cserélődik', () => {
    expect(replaceFormulaCurrency('!FEUR', 'EUA', 'BAM')).toBe('!FEUR')
  })

  it('TBD-4: vegyes — csak a forrás-kóddal egyező cserélődik', () => {
    // AUD sorból: !EAUD cserélődik, a fix !FEUR marad
    expect(replaceFormulaCurrency('!EAUD*0.97+!FEUR', 'AUD', 'BAM')).toBe('!EBAM*0.97+!FEUR')
  })

  it('self-refek (egybetűs 0-s lap A–C/E–I, csoport J–S) és számok változatlanok', () => {
    expect(replaceFormulaCurrency('F+1', 'AUD', 'BAM')).toBe('F+1')
    expect(replaceFormulaCurrency('L*M', 'AUD', 'BAM')).toBe('L*M')
  })

  it('from === to vagy üres → változatlan', () => {
    expect(replaceFormulaCurrency('!EAUD', 'AUD', 'AUD')).toBe('!EAUD')
    expect(replaceFormulaCurrency('!EAUD', '', 'BAM')).toBe('!EAUD')
  })

  it('kisbetűs forráskód is egyezik (case-insensitive)', () => {
    expect(replaceFormulaCurrency('!Eaud', 'aud', 'bam')).toBe('!EBAM')
  })
})
