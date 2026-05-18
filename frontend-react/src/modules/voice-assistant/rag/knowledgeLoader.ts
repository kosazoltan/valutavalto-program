import yaml from 'js-yaml'
import modulesYamlRaw from '../knowledge/modules.yaml?raw'
import faqYamlRaw from '../knowledge/faq.yaml?raw'
import workflowsYamlRaw from '../knowledge/workflows.yaml?raw'
import errorCodesYamlRaw from '../knowledge/error-codes.yaml?raw'
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
 */

interface ParsedYaml {
  [key: string]: unknown
}

let cache: { docs: SearchableDoc[]; raw: Record<string, ParsedYaml> } | null = null

function parseYaml(raw: string): ParsedYaml {
  try {
    const parsed = yaml.load(raw)
    return (parsed && typeof parsed === 'object' ? parsed : {}) as ParsedYaml
  } catch {
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
  const entries = (parsed.faqs ?? parsed.entries ?? []) as Array<Record<string, unknown>>
  if (!Array.isArray(entries)) return []
  return entries.map((entry, idx) => {
    const id = String(entry.id ?? `faq-${idx}`)
    const title = String(entry.question ?? entry.title ?? id)
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
  const entries = (parsed.error_codes ?? parsed.errors ?? []) as Array<Record<string, unknown>>
  if (!Array.isArray(entries)) return []
  return entries.map((entry, idx) => {
    const id = String(entry.code ?? `err-${idx}`)
    const title = `${id} — ${String(entry.title ?? entry.description ?? '')}`
    const body = joinValuesForBody(entry)
    return { id: `error:${id}`, sourceType: 'error-code', title, body, payload: entry }
  })
}

function flattenModules(parsed: ParsedYaml): SearchableDoc[] {
  const docs: SearchableDoc[] = []
  const clients = (parsed.clients ?? []) as Array<Record<string, unknown>>
  if (Array.isArray(clients)) {
    for (const client of clients) {
      const cid = String(client.id ?? client.name ?? '')
      const menu = (client.menu ?? client.modules ?? []) as Array<Record<string, unknown>>
      if (Array.isArray(menu)) {
        for (const m of menu) {
          const id = `${cid}.${String(m.id ?? m.key ?? '')}`
          docs.push({
            id: `module:${id}`,
            sourceType: 'module',
            title: String(m.title ?? m.name ?? id),
            body: joinValuesForBody(m),
            payload: m,
          })
        }
      }
    }
  }
  return docs
}

export function loadKnowledgeBase(): { docs: SearchableDoc[]; raw: Record<string, ParsedYaml> } {
  if (cache) return cache
  const raw: Record<string, ParsedYaml> = {
    modules: parseYaml(modulesYamlRaw),
    faq: parseYaml(faqYamlRaw),
    workflows: parseYaml(workflowsYamlRaw),
    errorCodes: parseYaml(errorCodesYamlRaw),
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
 * Pl: lookupModule('penztar1') vagy 'kozponti.napzaras'.
 */
export function lookupModuleById(moduleId: string): unknown | null {
  const kb = loadKnowledgeBase()
  const hit = kb.docs.find(
    (d) => d.sourceType === 'module' && d.id === `module:${moduleId}`
  )
  return hit?.payload ?? null
}

export function __resetKnowledgeCacheForTesting(): void {
  cache = null
}
