import 'fake-indexeddb/auto'
import { describe, it, expect, beforeEach } from 'vitest'
import {
  createIssue,
  getIssue,
  updateIssue,
  appendQuickNote,
  finalizeIssue,
  listIssues,
  deleteIssue,
} from './issueStore'
import { __resetIssueDbForTesting, getIssueDb } from './issueDb'

/**
 * EBC Hangsegéd issueStore CRUD egysegtesztek (Copilot #661 finding).
 *
 * <p>fake-indexeddb-vel a Dexie-t valós IndexedDB-ben futtatjuk teszt-kornyezetben.
 */
describe('issueStore CRUD', () => {
  beforeEach(async () => {
    // 1) Reset singleton es 2) clear the persisted IndexedDB tables
    __resetIssueDbForTesting()
    const db = getIssueDb()
    await db.issues.clear()
    await db.vectorCache.clear()
  })

  it('createIssue + getIssue: a letrehozott record visszaolvashato', async () => {
    const created = await createIssue({
      mode: 'support',
      title: 'Teszt cim',
      description: 'leiras',
      severity: 'high',
    })
    expect(created.id).toBeDefined()
    const fetched = await getIssue(created.id)
    expect(fetched?.title).toBe('Teszt cim')
    expect(fetched?.severity).toBe('high')
  })

  it('updateIssue: a mezok deepmerge-elnek (reporter), timestamp frissul', async () => {
    const created = await createIssue({ mode: 'test', title: 'A', reporter: { displayName: 'Heni' } })
    const updated = await updateIssue(created.id, { description: 'frissites', reporter: { workerCode: 'W-S011' } })
    expect(updated?.description).toBe('frissites')
    expect(updated?.reporter.displayName).toBe('Heni')
    expect(updated?.reporter.workerCode).toBe('W-S011')
    expect(updated?.updatedAt).not.toBe(created.updatedAt)
  })

  it('appendQuickNote atomi: parhuzamos hivasok mindegyike megorzodik', async () => {
    const created = await createIssue({ mode: 'support', title: 'Q' })
    // 5 parhuzamos append
    await Promise.all([
      appendQuickNote(created.id, 'note1'),
      appendQuickNote(created.id, 'note2'),
      appendQuickNote(created.id, 'note3'),
      appendQuickNote(created.id, 'note4'),
      appendQuickNote(created.id, 'note5'),
    ])
    const fetched = await getIssue(created.id)
    expect(fetched?.quickNotes.length).toBe(5)
    expect(new Set(fetched?.quickNotes).size).toBe(5)
  })

  it('finalizeIssue status-t finalized-re allitja', async () => {
    const created = await createIssue({ mode: 'install', title: 'X' })
    const final = await finalizeIssue(created.id)
    expect(final?.status).toBe('finalized')
  })

  it('listIssues: limit: 0 ures arrayt ad (NEM full list)', async () => {
    await createIssue({ mode: 'test', title: 'A' })
    await createIssue({ mode: 'test', title: 'B' })
    const empty = await listIssues({ limit: 0 })
    expect(empty).toEqual([])
    const all = await listIssues()
    expect(all.length).toBe(2)
  })

  it('listIssues filter mode szerint', async () => {
    await createIssue({ mode: 'install', title: 'I' })
    await createIssue({ mode: 'support', title: 'S' })
    const supports = await listIssues({ mode: 'support' })
    expect(supports.length).toBe(1)
    expect(supports[0]?.title).toBe('S')
  })

  it('deleteIssue eltavolitja a rekordot', async () => {
    const created = await createIssue({ mode: 'support', title: 'D' })
    await deleteIssue(created.id)
    const fetched = await getIssue(created.id)
    expect(fetched).toBeUndefined()
  })
})
