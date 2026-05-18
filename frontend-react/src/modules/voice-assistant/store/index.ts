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

export { getIssueDb, __resetIssueDbForTesting } from './issueDb'
export type { VectorCacheEntry } from './issueDb'

export {
  createIssue,
  getIssue,
  updateIssue,
  appendQuickNote,
  finalizeIssue,
  listIssues,
  deleteIssue,
} from './issueStore'
