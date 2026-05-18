import { describe, it, expect } from 'vitest'
import { normalizeText, tokenize, scoreDoc, searchDocs } from './textSearch'
import type { SearchableDoc } from './textSearch'

/**
 * EBC Hangsegéd RAG Layer 1 token-overlap kereső egységtesztek.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md Fázis 8 acceptance.
 */
describe('normalizeText', () => {
  it('magyar ekezetes karaktereket csokkenti', () => {
    expect(normalizeText('Árfolyamkészítő')).toBe('arfolyamkeszito')
  })

  it('nem-szo karaktereket whitespace-re cserel', () => {
    expect(normalizeText('foo, bar! baz?')).toBe('foo bar baz')
  })
})

describe('tokenize', () => {
  it('rovid szavakat es stopword-eket szuri', () => {
    expect(tokenize('A program nem mukodik')).toEqual(['program', 'mukodik'])
  })

  it('ures inputra ures arrayt ad', () => {
    expect(tokenize('')).toEqual([])
  })
})

describe('searchDocs', () => {
  const docs: SearchableDoc[] = [
    {
      id: 'faq:napzaras',
      sourceType: 'faq',
      title: 'Hogyan zarjam le a napot?',
      body: 'A napzaras a Penztar / Napzaras menupontban talalhato.',
    },
    {
      id: 'wf:vetel',
      sourceType: 'workflow',
      title: 'Vetel rogzitese',
      body: 'A vetel-tranzakcio rogzitese a Penztar / Vetel oldalon tortenik.',
    },
    {
      // Copilot PR #665: a kanonikus prefix `error:` (NEM `err:`)
      id: 'error:EBC-021',
      sourceType: 'error-code',
      title: 'EBC-021 — Arfolyam lejart',
      body: 'A rata 24 oras TTL-en tul van.',
    },
  ]

  it('napzaras kerdesre a faq:napzaras-t adja vissza elso helyen', () => {
    const results = searchDocs('hogyan zarom le a napot', docs)
    expect(results.length).toBeGreaterThan(0)
    expect(results[0]?.id).toBe('faq:napzaras')
  })

  it('arfolyam kerdesre az error:EBC-021-et talalja', () => {
    const results = searchDocs('arfolyam lejart', docs)
    expect(results.length).toBeGreaterThan(0)
    expect(results[0]?.id).toBe('error:EBC-021')
  })

  it('ures query ures eredmenyt ad', () => {
    expect(searchDocs('', docs)).toEqual([])
  })

  it('topK opcio limitalja az eredmenyek szamat', () => {
    const results = searchDocs('penztar', docs, { topK: 1 })
    expect(results.length).toBeLessThanOrEqual(1)
  })
})

describe('scoreDoc', () => {
  it('teljes egyezesnek pozitiv score-t ad', () => {
    const doc: SearchableDoc = {
      id: 'x',
      sourceType: 'faq',
      title: 'Penztar nyitas',
      body: 'penztar nyitas reggel',
    }
    expect(scoreDoc(['penztar', 'nyitas'], doc)).toBeGreaterThan(0)
  })

  it('nem-egyezesnek 0 score', () => {
    const doc: SearchableDoc = { id: 'x', sourceType: 'faq', title: 'X', body: 'almafa' }
    expect(scoreDoc(['penztar'], doc)).toBe(0)
  })
})
