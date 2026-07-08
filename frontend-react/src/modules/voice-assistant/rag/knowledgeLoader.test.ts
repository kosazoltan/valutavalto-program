import { describe, it, expect, beforeEach } from 'vitest'
import {
  loadKnowledgeBase,
  lookupModuleById,
  __resetKnowledgeCacheForTesting,
} from './knowledgeLoader'

/**
 * EBC Hangsegéd knowledgeLoader smoke teszt (Copilot+Codex PR #665 P1 fix).
 *
 * <p>A korabbi loader flattenFaq + flattenModules implementacioja rossz
 * kulcsokat olvasott (`faqs` vs `faq`, `clients[].menu` vs root `modules`).
 * Eredmenykent egy `loadKnowledgeBase()` ures docs arrayt adott vissza.
 *
 * <p>Ez a smoke teszt minden kovetkezo schema-driftet azonnal jelzi:
 * a 4 YAML mindegyikbol legalabb 1 dokumentumot ki KELL nyerni.
 */
describe('loadKnowledgeBase smoke', () => {
  beforeEach(() => {
    __resetKnowledgeCacheForTesting()
  })

  it('a 4 YAML-bol mindegyik forrasbol legalabb 1 dokumentum betoltodik', () => {
    const { docs } = loadKnowledgeBase()
    const sourceTypes = new Set(docs.map((d) => d.sourceType))

    expect(sourceTypes.has('faq')).toBe(true)
    expect(sourceTypes.has('module')).toBe(true)
    expect(sourceTypes.has('workflow')).toBe(true)
    expect(sourceTypes.has('error-code')).toBe(true)
  })

  it('faq dokumentumok q mezojuket hasznaljak title-kent', () => {
    const { docs } = loadKnowledgeBase()
    const faqDocs = docs.filter((d) => d.sourceType === 'faq')
    expect(faqDocs.length).toBeGreaterThan(0)
    // egy FAQ entry sem szabad, hogy az id-jet hasznalja title-kent (q nelkul)
    for (const d of faqDocs) {
      expect(d.title.startsWith('faq-')).toBe(false)
    }
  })

  it('module dokumentumok mind module: prefixszel', () => {
    const { docs } = loadKnowledgeBase()
    const moduleDocs = docs.filter((d) => d.sourceType === 'module')
    expect(moduleDocs.length).toBeGreaterThan(0)
    for (const d of moduleDocs) {
      expect(d.id.startsWith('module:')).toBe(true)
      // ne legyen `module:cid.` (uresen vegzodo) trailing
      expect(d.id.endsWith('.')).toBe(false)
    }
  })

  it('lookupModuleById visszaad egy ervenyes modult (penztar.fomenu)', () => {
    const m = lookupModuleById('penztar.fomenu')
    expect(m).not.toBeNull()
  })

  it('lookupModuleById nem-letezo id-re null-t ad', () => {
    const m = lookupModuleById('nem-letezo-modul-id')
    expect(m).toBeNull()
  })

  it('Codex PR #675 P1: lookupModuleById elfogadja a prefixed id-t is (NEM double-prefix)', () => {
    // A korabbi bug: search-result `module:penztar.fomenu` -> lookup `module:module:penztar.fomenu`
    // most a prefixed format-ot is elfogadjuk - mindkettre ugyanazt a payload-ot adja
    const rawResult = lookupModuleById('penztar.fomenu')
    const prefixedResult = lookupModuleById('module:penztar.fomenu')
    expect(rawResult).not.toBeNull()
    expect(prefixedResult).not.toBeNull()
    expect(prefixedResult).toEqual(rawResult)
  })

  it('lookupModuleById ures inputra null', () => {
    expect(lookupModuleById('')).toBeNull()
  })

  it('error-code dokumentumok error: prefixszel + kanonikus id', () => {
    const { docs } = loadKnowledgeBase()
    const errorDocs = docs.filter((d) => d.sourceType === 'error-code')
    expect(errorDocs.length).toBeGreaterThan(0)
    for (const d of errorDocs) {
      expect(d.id.startsWith('error:')).toBe(true)
      // trailing em-dash csak akkor, ha van vegen valami
      if (d.title.endsWith(' — ')) {
        throw new Error(`Title ends with em-dash + space (no subtitle): "${d.title}"`)
      }
    }
  })
})
