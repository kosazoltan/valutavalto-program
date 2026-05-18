import { loadKnowledgeBase, lookupModuleById } from './knowledgeLoader'
import { searchDocs } from './textSearch'
import type { SearchResult } from './textSearch'

/**
 * EBC Hangsegéd RAG modul publikus API.
 *
 * <p>Phase 8 = Layer 1 (token-overlap szöveges kereső YAML tudásbázison).
 * Phase 8.5 = Layer 2 (transformers.js vektoros embedding-ek).
 *
 * <p>A `searchKnowledgeBase(query)` és `lookupModule(id)` a `tools/`
 * ToolContext-jébe kerül beadásra a Phase 9 Electron integraciónál.
 */

export type { SearchableDoc, SearchResult } from './textSearch'
export { normalizeText, tokenize, scoreDoc, searchDocs } from './textSearch'

export {
  loadKnowledgeBase,
  lookupModuleById,
  __resetKnowledgeCacheForTesting,
} from './knowledgeLoader'

/**
 * Convenience: a Phase 7 `ToolContext.searchKnowledge`-hez illeszkedo
 * signaturaval.
 */
export function searchKnowledgeBase(query: string, topK = 3): SearchResult[] {
  const { docs } = loadKnowledgeBase()
  return searchDocs(query, docs, { topK })
}

export function lookupModule(moduleId: string): {
  module_id: string
  found: boolean
  data?: unknown
  error?: string
} {
  const payload = lookupModuleById(moduleId)
  if (!payload) {
    return { module_id: moduleId, found: false, error: 'Modul nem talalhato a tudasbazisban.' }
  }
  return { module_id: moduleId, found: true, data: payload }
}
