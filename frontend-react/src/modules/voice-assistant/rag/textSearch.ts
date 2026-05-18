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
  á: 'a', é: 'e', í: 'i', ó: 'o', ö: 'o', ő: 'o', ú: 'u', ü: 'u', ű: 'u',
}

const STOP_WORDS = new Set([
  'a', 'az', 'es', 'is', 'de', 'hogy', 'meg', 'el', 'ki', 'be', 'fel', 'le',
  'ha', 'nem', 'igen', 'ott', 'itt', 'ez', 'ezt', 'azt', 'mi', 'mit', 'ki',
  'minden', 'csak', 'mar', 'lehet', 'kell', 'vagy', 'vagyis', 'majd', 'most',
])

export function normalizeText(input: string): string {
  return input
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

export interface SearchableDoc {
  /** unique azonosito (pl. "faq:napzaras") */
  id: string
  /** lattatas: 'faq' | 'module' | 'workflow' | 'error-code' */
  sourceType: string
  /** ember-olvashato cim */
  title: string
  /** teljes szoveg-tartalom (a tokenizalashoz) */
  body: string
  /** opcionalis nyers payload (a callerhez visszaadando) */
  payload?: unknown
}

export interface SearchResult {
  id: string
  sourceType: string
  title: string
  score: number
  payload?: unknown
}

/**
 * Score-szamitas: query-tokenek metszet / unio (Jaccard) + cim-talalat bonusz.
 */
export function scoreDoc(queryTokens: string[], doc: SearchableDoc): number {
  if (queryTokens.length === 0) return 0
  const docTokens = new Set(tokenize(`${doc.title} ${doc.body}`))
  if (docTokens.size === 0) return 0

  let overlap = 0
  for (const t of queryTokens) {
    if (docTokens.has(t)) {
      overlap++
    } else {
      // rövid prefix-egyezés magyar morfológiához (>=4 char)
      for (const dt of docTokens) {
        if (t.length >= 4 && (dt.startsWith(t) || t.startsWith(dt))) {
          overlap += 0.5
          break
        }
      }
    }
  }

  const jaccard = overlap / (queryTokens.length + docTokens.size - overlap || 1)
  const titleHits = tokenize(doc.title).filter((tt) => queryTokens.includes(tt)).length
  return jaccard * 100 + titleHits * 5
}

export function searchDocs(
  query: string,
  docs: SearchableDoc[],
  options: { topK?: number; minScore?: number } = {}
): SearchResult[] {
  const queryTokens = tokenize(query)
  if (queryTokens.length === 0) return []

  const topK = options.topK ?? 3
  const minScore = options.minScore ?? 1

  const scored = docs
    .map<SearchResult>((doc) => ({
      id: doc.id,
      sourceType: doc.sourceType,
      title: doc.title,
      score: scoreDoc(queryTokens, doc),
      payload: doc.payload,
    }))
    .filter((r) => r.score >= minScore)
    .sort((a, b) => b.score - a.score)
    .slice(0, topK)

  return scored
}
