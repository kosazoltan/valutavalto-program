import {
  createIssue,
  appendQuickNote,
  finalizeIssue,
} from '../store/issueStore'
import type {
  IssueRecord,
  IssueMode,
  IssueSeverity,
  IssueReporter,
} from '../store/issueTypes'
import type { ToolName } from './toolDefinitions'

/**
 * EBC Hangsegéd function-call handler.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §5.2
 *
 * <p>A `dispatchToolCall` egyetlen belepesi pont — a Realtime API
 * `response.function_call_arguments.done` esemenyenel hivjuk. A `ToolContext`
 * tartalmazza a kornyezetfuggetlen callback-eket (install state machine,
 * knowledge lookup, vector store) — ezek default-jai stub-ok, Phase 8/9
 * cseren felulirjuk valós megvalositassal.
 */

export interface UserInfo {
  name: string
  branch: string
}

export interface InstallStep {
  step_number: number
  instructions: string
}

export interface KnowledgeLookupResult {
  module_id: string
  found: boolean
  data?: unknown
  error?: string
}

export interface VectorSearchResult {
  text: string
  source: string
  score: number
}

export interface ToolContext {
  /** A jelenlegi voice-assistant mod, hogy az issueRecord.mode-t korrektre allitsuk. */
  mode: IssueMode
  /** Felhasznalo-info getter (null ha set_user_info meg nem hivodott). */
  getUserInfo: () => UserInfo | null
  setUserInfo: (info: UserInfo) => void
  /** Install lepes-allapot leptetes. */
  nextInstallStep: (currentStep: number, success: boolean, note?: string) => InstallStep
  /** Telepites-/teszteles-lezaras. */
  finalize: (summary?: string) => void
  /** YAML modul-info lekeres (Phase 9 Electron preload-ban implementalva). */
  lookupModule: (moduleId: string) => Promise<KnowledgeLookupResult>
  /** Vektoros tudasbazis-kereses (Phase 8 implementacio). */
  searchKnowledge: (query: string, topK?: number) => Promise<VectorSearchResult[]>
  /** Korabbi hibajegyek vektoros hasonlosag. */
  findSimilarIssues: (description: string) => Promise<IssueRecord[]>
}

export function createDefaultToolContext(mode: IssueMode): ToolContext {
  let currentUser: UserInfo | null = null
  return {
    mode,
    getUserInfo: () => currentUser,
    setUserInfo: (info) => {
      currentUser = info
    },
    nextInstallStep: (current, success) => ({
      step_number: success ? current + 1 : current,
      instructions: 'A kovetkezo lepes meg nincs konfiguralva (Phase 9 Electron integraciot var).',
    }),
    finalize: () => {
      /* default: no-op — UI hook a Phase 9-ben */
    },
    lookupModule: async (moduleId) => ({
      module_id: moduleId,
      found: false,
      error: 'Knowledge lookup meg nem implementalt (Phase 8 RAG).',
    }),
    searchKnowledge: async () => [],
    findSimilarIssues: async () => [],
  }
}

function buildReporter(userInfo: UserInfo | null): IssueReporter {
  if (!userInfo) return {}
  return { displayName: userInfo.name, branchCode: userInfo.branch }
}

function severityFromString(value: unknown): IssueSeverity {
  const allowed: IssueSeverity[] = ['critical', 'high', 'medium', 'low']
  return allowed.includes(value as IssueSeverity) ? (value as IssueSeverity) : 'medium'
}

/**
 * Egyetlen entrypoint a Realtime API function-call eseményeire.
 *
 * @param name tool neve (lasd ToolName)
 * @param args parsed JSON args az AI valaszabol
 * @param ctx environment context
 * @returns serializaltado eredmeny — a Realtime API-nak vissza adott response
 */
export async function dispatchToolCall(
  name: ToolName,
  args: Record<string, unknown>,
  ctx: ToolContext
): Promise<Record<string, unknown>> {
  switch (name) {
    case 'report_issue': {
      const issue = await createIssue({
        mode: ctx.mode,
        title: String(args.title ?? '').slice(0, 80),
        description: String(args.description ?? ''),
        severity: severityFromString(args.severity),
        module: typeof args.affected_module === 'string' ? args.affected_module : null,
        reproSteps: Array.isArray(args.steps_to_reproduce)
          ? (args.steps_to_reproduce as string[]).map((s) => `- ${s}`).join('\n')
          : null,
        expected: typeof args.expected_behavior === 'string' ? args.expected_behavior : null,
        actual: typeof args.actual_behavior === 'string' ? args.actual_behavior : null,
        reporter: buildReporter(ctx.getUserInfo()),
      })
      return { success: true, issue_id: issue.id }
    }

    case 'add_quick_note': {
      const issue = await createIssue({
        mode: ctx.mode,
        title: String(args.title ?? '').slice(0, 80),
        description: String(args.body ?? ''),
        severity: 'medium',
        module: typeof args.affected_module === 'string' ? args.affected_module : 'altalanos',
        reporter: buildReporter(ctx.getUserInfo()),
      })
      await appendQuickNote(issue.id, String(args.body ?? ''))
      return { success: true, note_id: issue.id }
    }

    case 'next_install_step': {
      const step = ctx.nextInstallStep(
        Number(args.current_step ?? 0),
        Boolean(args.success ?? false),
        typeof args.note === 'string' ? args.note : undefined
      )
      return { step_number: step.step_number, instructions: step.instructions }
    }

    case 'set_user_info': {
      ctx.setUserInfo({
        name: String(args.name ?? ''),
        branch: String(args.branch ?? ''),
      })
      return { success: true }
    }

    case 'finalize_report': {
      const summary = typeof args.summary === 'string' ? args.summary : undefined
      ctx.finalize(summary)
      return { success: true }
    }

    case 'lookup_module_info':
      return ctx.lookupModule(String(args.module_id ?? '')) as unknown as Record<string, unknown>

    case 'search_knowledge': {
      const top = Math.min(5, Math.max(1, Number(args.top_k ?? 3)))
      const results = await ctx.searchKnowledge(String(args.query ?? ''), top)
      return { results }
    }

    case 'find_similar_issues': {
      const issues = await ctx.findSimilarIssues(String(args.description ?? ''))
      return { found: issues.length, issues }
    }

    default: {
      const _exhaustive: never = name
      void _exhaustive
      return { error: 'unknown_tool' }
    }
  }
}

export async function finalizeReportShortcut(issueId: string): Promise<void> {
  await finalizeIssue(issueId)
}
