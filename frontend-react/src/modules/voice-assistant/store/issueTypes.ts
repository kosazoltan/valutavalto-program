/**
 * EBC Hangsegéd Issue (hibajelentés / telepítési napló) tipusok.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §6.1
 */

export type IssueMode = 'install' | 'test' | 'support'

export type IssueStatus = 'draft' | 'finalized' | 'exported'

export type IssueSeverity = 'low' | 'medium' | 'high' | 'critical'

/**
 * Hibajegy kategoria — a Phase 7 report_issue tool kotelezo mezoje.
 * Copilot+Codex PR #664 finding alapjan vezettuk be: korabban a tool
 * schema-ja kerte (required), de a handler dobta — minden mentett
 * record indistinguishable maradt downstream triage-hoz.
 */
export type IssueCategory = 'bug' | 'feature_request' | 'usability' | 'question'

export interface IssueAttachment {
  /** rövid leíró (pl. "képernyőkép a hiba pillanatában") */
  description: string
  /** filename helyett rövid ID — a fájl mellékletek külön rendszerben élnek */
  ref: string
}

export interface IssueReporter {
  /** rövid azonosító (worker_code), pl. "W-S011" */
  workerCode?: string | null
  /** kolléga neve, ahogy bemutatkozott a session-ben */
  displayName?: string | null
  /** iroda/branch ahol a hiba keletkezett */
  branchCode?: string | null
}

export interface IssueRecord {
  /** ULID / UUID — generálva client-side */
  id: string
  /** ISO-8601 timestamp (létrehozás) */
  createdAt: string
  /** ISO-8601 timestamp (utolsó módosítás) */
  updatedAt: string
  mode: IssueMode
  status: IssueStatus
  /** Triage-kategoria (Copilot+Codex PR #664). Default 'bug'. */
  category: IssueCategory
  /** rövid cím (~80 char) */
  title: string
  /** részletes leírás markdown formátumban */
  description: string
  severity: IssueSeverity
  /** érintett modul (pl. "Pénztár / Vétel", "Központi / Napzárás") */
  module?: string | null
  /** lépések a reprodukcióhoz (bullet-list markdown) */
  reproSteps?: string | null
  /** elvárt viselkedés */
  expected?: string | null
  /** ténylegesen tapasztalt viselkedés */
  actual?: string | null
  /** hibakód, ha van (pl. "EBC-021") */
  errorCode?: string | null
  reporter: IssueReporter
  attachments: IssueAttachment[]
  /** szabad-szöveges gyors-jegyzetek a session során */
  quickNotes: string[]
}

export type IssueDraftInput = Partial<Omit<IssueRecord, 'id' | 'createdAt' | 'updatedAt'>>
