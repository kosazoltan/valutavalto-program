/**
 * EBC Hangsegéd RAG Layer 1 — token-overlap szöveges kereső.
 *
 * <p>A Layer 2 (vektoros embedding-ek transformers.js-szel) Phase 8.5-ban
 * kerül implementálásra. Layer 1 már most működik a YAML tudásbázison.
 *
 * <p>Algoritmus: a query-t és minden dokumentumot tokenizáljuk (kis-betű,
 * ékezet-csökkentés, kötőjel/whitespace-mentén), majd egyszerű
 * Jaccard-szerű hasonlóságot számolunk, illetve TF-szerű bónuszt adunk
 * a magyar nyelvi morfológia néhány alapjára (rövid prefixek = elfogadott).
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §5
 *
 * <p>Egyszerű, dependency-mentes — később transformers.js fel-osztályozza.
 */

const ACCENT_FOLD: Record<string, string> = {
  á: 'a',
  é: 'e',
  í: 'i',
  ó: 'o',
  ö: 'o',
  ő: 'o',
  ú: 'u',
  ü: 'u',
  ű: 'u',
}

// Copilot PR #665: 'ki' korabban duplikalva volt. Most a kifejlesztett set
// 30 magyar stopword-ot tartalmaz, mindegyik egyszer szerepel.
const STOP_WORDS = new Set([
  'a',
  'az',
  'es',
  'is',
  'de',
  'hogy',
  'meg',
  'el',
  'ki',
  'be',
  'fel',
  'le',
  'ha',
  'nem',
  'igen',
  'ott',
  'itt',
  'ez',
  'ezt',
  'azt',
  'mi',
  'mit',
  'minden',
  'csak',
  'mar',
  'lehet',
  'kell',
  'vagy',
  'vagyis',
  'majd',
  'most',
  'olyan',
  'sem',
  'volt',
  'lesz',
])

export function normalizeText(input: string): string {
  // Copilot PR #665: NFC normalize a fold elott — NFD-bol jovo szovegben
  // a kombinalo diakritikus karakterek is jól folddolasra kerulnek
  return input
    .normalize('NFC')
    .toLowerCase()
    .replace(/[áéíóöőúüű]/g, (ch) => ACCENT_FOLD[ch] ?? ch)
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

export function tokenize(input: string): string[] {
  return normalizeText(input)
    .split(' ')
    .filter((t) => t.length >= 3 && !STOP_WORDS.has(t))
}

// Copilot PR #665: kötött union — caller exhaustiveness check, typo-vedelem
export type SourceType = 'faq' | 'module' | 'workflow' | 'error-code'

export interface SearchableDoc {
  /** unique azonosito (pl. "faq:napzaras") */
  id: string
  sourceType: SourceType
  /** ember-olvashato cim */
  title: string
  /** teljes szoveg-tartalom (a tokenizalashoz) */
  body: string
  /** opcionalis nyers payload (a callerhez visszaadando) */
  payload?: unknown
}

export interface SearchResult {
  id: string
  sourceType: SourceType
  title: string
  score: number
  payload?: unknown
}

/**
 * Score-szamitas: query-tokenek metszet / unio (Jaccard) + cim-talalat bonusz.
 *
 * <p>Copilot PR #665 perf: a tokenize() ne fusson minden hivasnal. Ha a
 * caller atadja a `precomputedDocTokens` + `precomputedTitleTokens`-t,
 * a fuggveny azt hasznalja. A `searchDocs` mindig precomputalja.
 */
export function scoreDoc(
  queryTokens: string[],
  doc: SearchableDoc,
  precomputedDocTokens?: Set<string>,
  precomputedTitleTokens?: string[],
): number {
  if (queryTokens.length === 0) return 0
  const docTokens = precomputedDocTokens ?? new Set(tokenize(`${doc.title} ${doc.body}`))
  if (docTokens.size === 0) return 0

  let overlap = 0
  for (const t of queryTokens) {
    if (docTokens.has(t)) {
      overlap++
    } else if (t.length >= 4) {
      // Rövid prefix-egyezés magyar morfológiához (mindkét oldal >=4 char,
      // Copilot PR #665: a `t.startsWith(dt)` is gated `dt.length >= 4`-re,
      // hogy a 3-char doc-token NE adjon hamis pozitiv talalatot.
      for (const dt of docTokens) {
        if (dt.length >= 4 && (dt.startsWith(t) || t.startsWith(dt))) {
          overlap += 0.5
          break
        }
      }
    }
  }

  const jaccard = overlap / (queryTokens.length + docTokens.size - overlap || 1)
  const titleTokens = precomputedTitleTokens ?? tokenize(doc.title)
  const titleHits = titleTokens.filter((tt) => queryTokens.includes(tt)).length
  return jaccard * 100 + titleHits * 5
}

export function searchDocs(
  query: string,
  docs: SearchableDoc[],
  options: { topK?: number; minScore?: number } = {},
): SearchResult[] {
  const queryTokens = tokenize(query)
  if (queryTokens.length === 0) return []

  const topK = options.topK ?? 3
  const minScore = options.minScore ?? 1

  // Copilot PR #665 perf: doc-tokenizacio egyszer per doc, NEM minden score-hivasnal
  const scored = docs
    .map<SearchResult>((doc) => {
      const docTokens = new Set(tokenize(`${doc.title} ${doc.body}`))
      const titleTokens = tokenize(doc.title)
      return {
        id: doc.id,
        sourceType: doc.sourceType,
        title: doc.title,
        score: scoreDoc(queryTokens, doc, docTokens, titleTokens),
        payload: doc.payload,
      }
    })
    .filter((r) => r.score >= minScore)
    .sort((a, b) => b.score - a.score)
    .slice(0, topK)

  return scored
}
