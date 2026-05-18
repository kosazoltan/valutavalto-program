/**
 * EBC Hangsegéd OpenAI function-calling tools.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §5.1
 *
 * <p>A `tools` tömb átadható az OpenAI Realtime API `session.update`
 * eseménynek a `tools` mezőben. A nyelv: magyar (a kollégák szavaival).
 */

export type ToolName =
  | 'report_issue'
  | 'next_install_step'
  | 'set_user_info'
  | 'finalize_report'
  | 'add_quick_note'
  | 'lookup_module_info'
  | 'search_knowledge'
  | 'find_similar_issues'

export interface OpenAiTool {
  type: 'function'
  name: ToolName
  description: string
  parameters: Record<string, unknown>
}

export const TOOLS: OpenAiTool[] = [
  {
    type: 'function',
    name: 'report_issue',
    description: 'Strukturalt hibajegy vagy fejlesztesi keres rogzitese az IndexedDB-be.',
    parameters: {
      type: 'object',
      required: ['category', 'severity', 'title', 'description', 'affected_module'],
      properties: {
        category: { type: 'string', enum: ['bug', 'feature_request', 'usability', 'question'] },
        severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
        title: { type: 'string', description: 'Rovid cim, max 80 karakter.' },
        description: { type: 'string', description: 'Reszletes leiras a kollega szavaival.' },
        steps_to_reproduce: { type: 'array', items: { type: 'string' } },
        expected_behavior: { type: 'string' },
        actual_behavior: { type: 'string' },
        affected_module: {
          type: 'string',
          description: 'Pl: atvaltas, naplo, nav, keszlet, bizonylat, beallitasok, telepito',
        },
      },
    },
  },
  {
    type: 'function',
    name: 'next_install_step',
    description: 'Lekeri a kovetkezo telepitesi lepest, ha az elozo sikeres volt.',
    parameters: {
      type: 'object',
      required: ['current_step', 'success'],
      properties: {
        // Copilot PR #680 finding: a state machine replay-idempotency
        // (Set-based) megkoveteli, hogy az LLM ervenyes current_step-et
        // kuldjon. A min/max=1..7 a TOTAL_INSTALL_STEPS hatara.
        current_step: { type: 'integer', minimum: 1, maximum: 7 },
        success: { type: 'boolean' },
        note: { type: 'string', description: 'Opcionalis megjegyzes.' },
      },
    },
  },
  {
    type: 'function',
    name: 'set_user_info',
    description: 'Tarolja a felhasznalo nevet es fiokjat az MD jelentes fejlecehez.',
    parameters: {
      type: 'object',
      required: ['name', 'branch'],
      properties: {
        name: { type: 'string' },
        branch: { type: 'string' },
      },
    },
  },
  {
    type: 'function',
    name: 'finalize_report',
    description: 'Lezarja a tesztelest, jelzi a UI-nak hogy a kollega a letoltes gombot lathatja.',
    parameters: {
      type: 'object',
      properties: {
        summary: { type: 'string', description: 'Rovid osszegzes a kollega tapasztalatairol.' },
      },
    },
  },
  {
    type: 'function',
    name: 'add_quick_note',
    description:
      'GYORS jegyzet rogzites trigger szora ("jegyezd fel", "ird le", "rogzitsd"). Kevesebb mezo mint a report_issue, ha a kollega csak gyorsan akar valamit elmenteni.',
    parameters: {
      type: 'object',
      required: ['title', 'body'],
      properties: {
        title: { type: 'string', description: 'Egy soros cim, max 80 karakter.' },
        body: { type: 'string', description: 'A kollega altal mondott szoveg, kicsit takarosabban.' },
        affected_module: {
          type: 'string',
          description: 'Ha kideritheto, melyik modul. Egyebkent "altalanos".',
        },
      },
    },
  },
  {
    type: 'function',
    name: 'lookup_module_info',
    description:
      'Strukturalt info lekerese egy adott modulrol a lokalis YAML tudasbazisbol (knowledge/modules.yaml).',
    parameters: {
      type: 'object',
      required: ['module_id'],
      properties: {
        module_id: {
          type: 'string',
          description:
            'A modul azonositoja, pl. "beosztas.szabadsag", "foertektar.lekotesek", "ertektar.napi_beszamolo", "penztar1".',
        },
      },
    },
  },
  {
    type: 'function',
    name: 'search_knowledge',
    description:
      'Termeszetes nyelvu kereses a vektoros memoriaban (Phase 8 RAG Layer 2). Hasznald, amikor a kollega olyan kerdest tesz fel, ami nem kotheto egy modulhoz, vagy GYIK jellegu.',
    parameters: {
      type: 'object',
      required: ['query'],
      properties: {
        query: { type: 'string', description: 'A kereses lekerdezese magyarul.' },
        top_k: { type: 'number', description: 'Hany talalat kell vissza. Default 3, max 5.' },
      },
    },
  },
  {
    type: 'function',
    name: 'find_similar_issues',
    description:
      'Megnezi, hogy a kollega altal jelzett problema mar elofordult-e korabban. Vektoros hasonlosag alapjan.',
    parameters: {
      type: 'object',
      required: ['description'],
      properties: {
        description: { type: 'string' },
      },
    },
  },
]
