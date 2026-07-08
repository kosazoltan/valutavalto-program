import { getIssueDb } from './issueDb'
import type { IssueDraftInput, IssueMode, IssueRecord, IssueStatus } from './issueTypes'

/**
 * EBC Hangsegéd Issue store — CRUD operáciok az IndexedDB-vel.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §6.3
 *
 * <p>A store kizárólag a felhasználó gépén tárol — adatvédelem szempontból
 * kritikus, hogy a beszélgetés-naplók NE kerüljenek backendre.
 */

function nowIso(): string {
  return new Date().toISOString()
}

/**
 * Monoton timestamp generator: garantáltan szigorúan nagyobb, mint a megadott
 * `previousIso`. Race-conditiont kerül el (lásd: issueStore.test.ts updatedAt
 * mező ugyanabban a ms-ben futott a createIssue és updateIssue között).
 *
 * <p>Modern gyors gépeken `new Date()` ms-felbontása nem elég, ezért ha a friss
 * érték nem nagyobb, +1 ms-mel lépünk előre.
 */
function nowIsoAfter(previousIso: string): string {
  const next = nowIso()
  if (next > previousIso) return next
  return new Date(new Date(previousIso).getTime() + 1).toISOString()
}

function randomId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return `issue-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
}

export async function createIssue(
  input: IssueDraftInput & { mode: IssueMode },
): Promise<IssueRecord> {
  const now = nowIso()
  const record: IssueRecord = {
    id: randomId(),
    createdAt: now,
    updatedAt: now,
    mode: input.mode,
    status: input.status ?? 'draft',
    category: input.category ?? 'bug',
    title: input.title ?? '',
    description: input.description ?? '',
    severity: input.severity ?? 'medium',
    module: input.module ?? null,
    reproSteps: input.reproSteps ?? null,
    expected: input.expected ?? null,
    actual: input.actual ?? null,
    errorCode: input.errorCode ?? null,
    reporter: input.reporter ?? {},
    attachments: input.attachments ?? [],
    quickNotes: input.quickNotes ?? [],
  }
  await getIssueDb().issues.put(record)
  return record
}

export async function getIssue(id: string): Promise<IssueRecord | undefined> {
  return getIssueDb().issues.get(id)
}

export async function updateIssue(
  id: string,
  patch: IssueDraftInput,
): Promise<IssueRecord | undefined> {
  const db = getIssueDb()
  const existing = await db.issues.get(id)
  if (!existing) return undefined
  const merged: IssueRecord = {
    ...existing,
    ...patch,
    reporter: { ...existing.reporter, ...(patch.reporter ?? {}) },
    attachments: patch.attachments ?? existing.attachments,
    quickNotes: patch.quickNotes ?? existing.quickNotes,
    id: existing.id,
    createdAt: existing.createdAt,
    updatedAt: nowIsoAfter(existing.updatedAt),
  }
  await db.issues.put(merged)
  return merged
}

/**
 * Atomi quickNote append — Dexie rw transaction-on belul, hogy parhuzamos
 * hivasok ne irjak felul egymast (Copilot + Codex #661 finding).
 */
export async function appendQuickNote(id: string, note: string): Promise<void> {
  const db = getIssueDb()
  await db.transaction('rw', db.issues, async () => {
    const existing = await db.issues.get(id)
    if (!existing) return
    existing.quickNotes = [...existing.quickNotes, note]
    existing.updatedAt = nowIsoAfter(existing.updatedAt)
    await db.issues.put(existing)
  })
}

export async function finalizeIssue(id: string): Promise<IssueRecord | undefined> {
  // Copilot #661: az 'as IssueStatus' cast felesleges, a literal eleve illeszkedik
  return updateIssue(id, { status: 'finalized' })
}

export async function listIssues(filter?: {
  mode?: IssueMode
  status?: IssueStatus
  limit?: number
}): Promise<IssueRecord[]> {
  let collection = getIssueDb().issues.orderBy('updatedAt').reverse()
  if (filter?.mode) {
    collection = collection.filter((r) => r.mode === filter.mode)
  }
  if (filter?.status) {
    collection = collection.filter((r) => r.status === filter.status)
  }
  const rows = await collection.toArray()
  // Codex #661: filter.limit === 0 valid (ures eredmenyt jelent), NEM truthy check
  return filter?.limit !== undefined ? rows.slice(0, filter.limit) : rows
}

export async function deleteIssue(id: string): Promise<void> {
  await getIssueDb().issues.delete(id)
}
