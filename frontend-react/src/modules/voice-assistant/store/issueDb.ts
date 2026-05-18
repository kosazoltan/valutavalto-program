import Dexie, { Table } from 'dexie'
import type { IssueRecord } from './issueTypes'

/**
 * EBC Hangsegéd IndexedDB séma (Dexie 4).
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §6.2
 *
 * <p>A `issues` táblát a hibajelentések és telepítési naplók tárolásra használjuk.
 * A `vectorCache` táblát a transformers.js által generált embeddingek
 * memoizálására (Phase 8 — RAG Layer 2 vector).
 *
 * <p>Az adatok kizárólag a felhasználó gépén élnek, NEM kerülnek felhőbe.
 */
export class IssueDatabase extends Dexie {
  issues!: Table<IssueRecord, string>
  vectorCache!: Table<VectorCacheEntry, string>

  constructor() {
    super('EbcVoiceAssistantDb')
    this.version(1).stores({
      issues: 'id, createdAt, updatedAt, mode, status, severity',
      vectorCache: 'key, sourceType, updatedAt',
    })
  }
}

export interface VectorCacheEntry {
  /** sha1(source content) — egyértelmű kulcs */
  key: string
  /** 'knowledge' | 'faq' | 'workflow' | 'error-code' | 'issue' */
  sourceType: string
  /** forrás-rekord ID (pl. error-code: "EBC-021", issue: id) */
  sourceId: string
  /** L2-normalizált float vektor */
  embedding: number[]
  /** ISO-8601 timestamp */
  updatedAt: string
}

/**
 * Lazy-init singleton + explicit injection-pont teszteleshez.
 *
 * <p>Copilot #661: a komment-eredeti "fakeDb-vel felulirhato" igeret most
 * tenylegesen kovetheto: `setIssueDbForTesting(fakeDb)` hivassal a teszt
 * be tudja injektalni a sajat instance-jat (pl. fake-indexeddb-vel).
 */
let dbInstance: IssueDatabase | null = null

export function getIssueDb(): IssueDatabase {
  if (!dbInstance) {
    dbInstance = new IssueDatabase()
  }
  return dbInstance
}

/**
 * Test-only: explicit DB injektalas.
 * NEM exportalva a public store/index.ts-bol — csak `issueDb.ts`-bol direkt.
 */
export function setIssueDbForTesting(db: IssueDatabase | null): void {
  if (dbInstance && dbInstance !== db) {
    dbInstance.close()
  }
  dbInstance = db
}

/** Test-only: reseteli a singleton-t. */
export function __resetIssueDbForTesting(): void {
  if (dbInstance) {
    dbInstance.close()
  }
  dbInstance = null
}
