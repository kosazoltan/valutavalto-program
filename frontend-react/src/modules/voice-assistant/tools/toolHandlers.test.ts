import { describe, it, expect, beforeEach, vi } from 'vitest'
import { dispatchToolCall, createDefaultToolContext } from './toolHandlers'
import { TOOLS } from './toolDefinitions'

/**
 * EBC Hangsegéd function-call handler egysegtesztek.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md Fázis 7 acceptance.
 *
 * <p>A teszt NEM hivja meg a Dexie IndexedDB-t — helyette mockoljuk az
 * issueStore-bol importalt createIssue/appendQuickNote/finalizeIssue
 * fuggvenyeket.
 */

const mocks = vi.hoisted(() => ({
  createIssue: vi.fn(async (input: { mode: string; title: string; category?: string }) => ({
    id: 'mock-id-' + input.title,
    createdAt: '2026-05-18T00:00:00.000Z',
    updatedAt: '2026-05-18T00:00:00.000Z',
    mode: input.mode,
    status: 'draft',
    category: input.category ?? 'bug',
    title: input.title,
    description: '',
    severity: 'medium',
    module: null,
    reproSteps: null,
    expected: null,
    actual: null,
    errorCode: null,
    reporter: {},
    attachments: [],
    quickNotes: [],
  })),
}))

vi.mock('../store/issueStore', () => ({
  createIssue: mocks.createIssue,
  appendQuickNote: vi.fn(async () => undefined),
  finalizeIssue: vi.fn(async () => undefined),
}))

describe('TOOLS catalog', () => {
  it('pontosan 8 tool-t exportal', () => {
    expect(TOOLS.length).toBe(8)
  })

  it('minden tool egyedi nevvel', () => {
    const names = TOOLS.map((t) => t.name)
    expect(new Set(names).size).toBe(names.length)
  })
})

describe('dispatchToolCall', () => {
  let ctx: ReturnType<typeof createDefaultToolContext>

  beforeEach(() => {
    ctx = createDefaultToolContext('test')
  })

  it('report_issue letrehoz egy issue-t', async () => {
    const result = await dispatchToolCall(
      'report_issue',
      {
        category: 'bug',
        severity: 'high',
        title: 'Teszt hiba',
        description: 'lecsapodott a program',
        affected_module: 'penztar1',
      },
      ctx,
    )
    expect(result).toMatchObject({ success: true })
    expect(result.issue_id).toBeDefined()
  })

  it('report_issue: a category mező perzisztalt (Codex PR #664 regression check)', async () => {
    mocks.createIssue.mockClear()
    await dispatchToolCall(
      'report_issue',
      {
        category: 'feature_request',
        severity: 'medium',
        title: 'Uj ablak',
        description: 'kellene egy uj funkcio',
        affected_module: 'arfolyam',
      },
      ctx,
    )
    expect(mocks.createIssue).toHaveBeenCalledWith(
      expect.objectContaining({ category: 'feature_request' }),
    )
  })

  it('report_issue: ervenytelen category default-ra (bug) esik', async () => {
    mocks.createIssue.mockClear()
    await dispatchToolCall(
      'report_issue',
      {
        category: 'invalid-cat',
        severity: 'medium',
        title: 'X',
        description: 'y',
        affected_module: 'm',
      },
      ctx,
    )
    expect(mocks.createIssue).toHaveBeenCalledWith(expect.objectContaining({ category: 'bug' }))
  })

  it('set_user_info eltarolja az infot, getUserInfo visszaadja', () => {
    expect(ctx.getUserInfo()).toBeNull()
    ctx.setUserInfo({ name: 'Heni', branch: 'W-S011' })
    expect(ctx.getUserInfo()).toEqual({ name: 'Heni', branch: 'W-S011' })
  })

  it('next_install_step a default ctx-ben placeholder valaszt ad', async () => {
    const r = await dispatchToolCall('next_install_step', { current_step: 2, success: true }, ctx)
    expect(r.step_number).toBe(3)
    expect(String(r.instructions)).toContain('Phase 9')
  })

  it('search_knowledge a default ctx-ben ures eredmenyt ad', async () => {
    const r = await dispatchToolCall('search_knowledge', { query: 'hol a napzaras' }, ctx)
    expect(r).toEqual({ results: [] })
  })

  it('lookup_module_info default ctx-ben "Phase 8 RAG" stub-ot ad', async () => {
    const r = await dispatchToolCall('lookup_module_info', { module_id: 'penztar1' }, ctx)
    expect(r).toMatchObject({ found: false })
    expect(String(r.error)).toContain('Phase 8')
  })

  it('add_quick_note letrehoz egy issue-t altalanos modullal', async () => {
    const r = await dispatchToolCall(
      'add_quick_note',
      { title: 'Felirat', body: 'irjuk fel ezt' },
      ctx,
    )
    expect(r).toMatchObject({ success: true })
    expect(r.note_id).toBeDefined()
  })
})
