import yaml from 'js-yaml'
import modulesYamlRaw from '../knowledge/modules.yaml?raw'
import faqYamlRaw from '../knowledge/faq.yaml?raw'
import workflowsYamlRaw from '../knowledge/workflows.yaml?raw'
import errorCodesYamlRaw from '../knowledge/error-codes.yaml?raw'
import { logger } from '../../../utils/logger'
import type { SearchableDoc } from './textSearch'

/**
 * EBC Hangsegéd YAML knowledge base loader.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §6
 *
 * <p>A 4 YAML fájl (modules, faq, workflows, error-codes) build-time
 * bundle-be kerül (Vite `?raw` import). A `loadKnowledgeBase()` egyszer
 * parse-olja és cache-eli a memóriában — a kollégai session során a
 * `search_knowledge` és `lookup_module_info` ezeket használja.
 *
 * <p>YAML sema (lasd a Phase 1 PR #654 fajlokat):
 * <ul>
 *   <li>modules.yaml: top-level `modules:` lista, minden entry `id` + `name` + ...</li>
 *   <li>faq.yaml: top-level `faq:` lista, minden entry `id` + `q` + `a`</li>
 *   <li>workflows.yaml: top-level `workflows:` lista, `id` + `name` + steps</li>
 *   <li>error-codes.yaml: top-level `errors:` lista, `code` + `title`</li>
 * </ul>
 */

interface ParsedYaml {
  [key: string]: unknown
}

let cache: { docs: SearchableDoc[]; raw: Record<string, ParsedYaml> } | null = null

function parseYaml(raw: string, label: string): ParsedYaml {
  try {
    const parsed = yaml.load(raw)
    return (parsed && typeof parsed === 'object' ? parsed : {}) as ParsedYaml
  } catch (err) {
    // Copilot PR #665: NE csendben swallow-oljuk a YAML hibakat — log-oljuk
    logger.warn('VoiceAssistant', `knowledgeLoader: ${label} YAML parse hiba: ${String(err)}`)
    return {}
  }
}

function joinValuesForBody(value: unknown, depth = 0): string {
  if (depth > 3) return ''
  if (value === null || value === undefined) return ''
  if (typeof value === 'string') return value
  if (typeof value === 'number' || typeof value === 'boolean') return String(value)
  if (Array.isArray(value)) {
    return value.map((v) => joinValuesForBody(v, depth + 1)).join(' ')
  }
  if (typeof value === 'object') {
    return Object.values(value as Record<string, unknown>)
      .map((v) => joinValuesForBody(v, depth + 1))
      .join(' ')
  }
  return ''
}

function flattenFaq(parsed: ParsedYaml): SearchableDoc[] {
  // Codex PR #665 P1: a YAML schema `faq:` (singular) — nem `faqs`/`entries`
  const entries = (parsed.faq ?? parsed.faqs ?? parsed.entries ?? []) as Array<Record<string, unknown>>
  if (!Array.isArray(entries)) return []
  return entries.map((entry, idx) => {
    const id = String(entry.id ?? `faq-${idx}`)
    // Codex PR #665 P2: FAQ entries hasznaljak a `q` mezot a kerdesnek
    const title = String(entry.q ?? entry.question ?? entry.title ?? id)
    const body = joinValuesForBody(entry)
    return { id: `faq:${id}`, sourceType: 'faq', title, body, payload: entry }
  })
}

function flattenWorkflows(parsed: ParsedYaml): SearchableDoc[] {
  const entries = (parsed.workflows ?? []) as Array<Record<string, unknown>>
  if (!Array.isArray(entries)) return []
  return entries.map((entry, idx) => {
    const id = String(entry.id ?? `wf-${idx}`)
    const title = String(entry.name ?? entry.title ?? id)
    const body = joinValuesForBody(entry)
    return { id: `workflow:${id}`, sourceType: 'workflow', title, body, payload: entry }
  })
}

function flattenErrorCodes(parsed: ParsedYaml): SearchableDoc[] {
  const entries = (parsed.errors ?? parsed.error_codes ?? []) as Array<Record<string, unknown>>
  if (!Array.isArray(entries)) return []
  return entries.map((entry, idx) => {
    const id = String(entry.code ?? `err-${idx}`)
    // Copilot PR #665: a trailing em-dash csak akkor jelenjen meg ha van title-szoveg
    const subtitle = entry.title ?? entry.description ?? null
    const title = subtitle ? `${id} — ${String(subtitle)}` : id
    const body = joinValuesForBody(entry)
    // Copilot PR #665: az `err:` (test docs) vs `error:` (loader) inconzisztencia
    // megoldva — itt `error:` a kanonikus prefix.
    return { id: `error:${id}`, sourceType: 'error-code', title, body, payload: entry }
  })
}

function flattenModules(parsed: ParsedYaml): SearchableDoc[] {
  // Codex PR #665 P1: a modules.yaml top-level `modules:` lista (NEM clients[].menu[])
  const docs: SearchableDoc[] = []
  const modules = (parsed.modules ?? []) as Array<Record<string, unknown>>
  if (!Array.isArray(modules)) return docs

  for (const m of modules) {
    const rawId = m.id ?? m.key ?? null
    if (!rawId) {
      // Copilot PR #665: ne hagyjunk degenarate `module:.` id-t
      logger.warn('VoiceAssistant', 'knowledgeLoader: modules.yaml entry id nelkul, atugorva')
      continue
    }
    const id = String(rawId)
    docs.push({
      id: `module:${id}`,
      sourceType: 'module',
      title: String(m.name ?? m.title ?? id),
      body: joinValuesForBody(m),
      payload: m,
    })
  }
  return docs
}

export function loadKnowledgeBase(): { docs: SearchableDoc[]; raw: Record<string, ParsedYaml> } {
  if (cache) return cache
  const raw: Record<string, ParsedYaml> = {
    modules: parseYaml(modulesYamlRaw, 'modules.yaml'),
    faq: parseYaml(faqYamlRaw, 'faq.yaml'),
    workflows: parseYaml(workflowsYamlRaw, 'workflows.yaml'),
    errorCodes: parseYaml(errorCodesYamlRaw, 'error-codes.yaml'),
  }
  const docs: SearchableDoc[] = [
    ...flattenFaq(raw.faq ?? {}),
    ...flattenWorkflows(raw.workflows ?? {}),
    ...flattenErrorCodes(raw.errorCodes ?? {}),
    ...flattenModules(raw.modules ?? {}),
  ]
  cache = { docs, raw }
  return cache
}

/**
 * Egy konkret modul-info lekerese a modules.yaml-bol.
 *
 * Codex PR #675 P1 fix: kezeli MIND a raw ID-t ('penztar.fomenu'),
 * MIND a prefixed ID-t ('module:penztar.fomenu'). A korabbi
 * `module:${moduleId}` strict-formacio double-prefix bug-ot okozott a
 * `searchKnowledgeBase` -> `lookupModule` chaining flow-ban, ahol a
 * search-result mar `module:<id>` formaban erkezett, es a lookup
 * `module:module:<id>`-t hasonlitott, NEM talalt es false negativ-et adott.
 */
export function lookupModuleById(moduleId: string): unknown | null {
  if (!moduleId) return null
  const kb = loadKnowledgeBase()
  // Normalizálás: ha a caller mar átadta a 'module:' prefixet, NE duplázzuk.
  const canonicalId = moduleId.startsWith('module:') ? moduleId : `module:${moduleId}`
  const hit = kb.docs.find(
    (d) => d.sourceType === 'module' && d.id === canonicalId
  )
  return hit?.payload ?? null
}

export function __resetKnowledgeCacheForTesting(): void {
  cache = null
}
