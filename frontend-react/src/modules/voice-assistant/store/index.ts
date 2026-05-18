/**
 * EBC Hangsegéd IndexedDB store — publikus API.
 */
export type {
  IssueRecord,
  IssueDraftInput,
  IssueMode,
  IssueStatus,
  IssueSeverity,
  IssueReporter,
  IssueAttachment,
} from './issueTypes'

// Copilot #661: a __resetIssueDbForTesting / setIssueDbForTesting NEM kerul
// a publikus index-be — adatvesztes-veszely production hasznalat eseten.
// Test-only funkciot direkt a `./issueDb` modulbol kell importalni.
export { getIssueDb } from './issueDb'
export type { VectorCacheEntry, IssueDatabase } from './issueDb'

export {
  createIssue,
  getIssue,
  updateIssue,
  appendQuickNote,
  finalizeIssue,
  listIssues,
  deleteIssue,
} from './issueStore'
