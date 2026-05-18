/**
 * EBC Hangsegéd function-call tools — publikus API.
 */
export { TOOLS } from './toolDefinitions'
export type { OpenAiTool, ToolName } from './toolDefinitions'

export {
  dispatchToolCall,
  createDefaultToolContext,
  finalizeReportShortcut,
} from './toolHandlers'
export type {
  ToolContext,
  UserInfo,
  InstallStep,
  KnowledgeLookupResult,
  VectorSearchResult,
} from './toolHandlers'
