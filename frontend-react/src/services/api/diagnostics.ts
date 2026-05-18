/**
 * Production monitoring API — kliens-oldali hibajelentések lekérdezése
 * az admin dashboard-hoz.
 *
 * Backend: DiagnosticsController (V182 client_error_log tábla).
 */
import { api } from './client'

export interface ClientErrorLog {
  id: number
  createdAt: string
  component: string
  version?: string
  osInfo?: string
  userIdentifier?: string
  errorMessage: string
  stackTrace?: string
  contextJson?: string
  clientIp?: string
  userAgent?: string
}

export interface ErrorLogPage {
  content: ClientErrorLog[]
  totalElements: number
  totalPages: number
  number: number
  size: number
}

export interface ComponentCount {
  component: string
  errorCount: number
}

export interface VersionCount {
  version: string
  errorCount: number
}

export interface ErrorSummary {
  totalAllTime: number
  last24h: number
  last7d: number
  last30d: number
  componentBreakdown7d: ComponentCount[]
  versionBreakdown7d: VersionCount[]
  generatedAt: string
}

export const diagnosticsApi = {
  listErrors: async (page = 0, size = 50): Promise<ErrorLogPage> => {
    const response = await api.get<ErrorLogPage>('/diagnostics/errors', {
      params: { page, size },
    })
    return response.data
  },

  getErrorSummary: async (): Promise<ErrorSummary> => {
    const response = await api.get<ErrorSummary>('/diagnostics/errors/summary')
    return response.data
  },

  getError: async (id: number): Promise<ClientErrorLog> => {
    const response = await api.get<ClientErrorLog>(`/diagnostics/errors/${id}`)
    return response.data
  },
}

// ===========================================================================
// V234 belso log+audit modul API (AuditDiagnosticsController)
// ===========================================================================

export interface AuditLogEntry {
  id: string
  eventId?: string
  ts: string
  eventType?: string
  action?: string
  entityType?: string
  entityId?: string
  beforeState?: string
  afterState?: string
  amount?: number
  currency?: string
  receiptNumber?: string
  traceId?: string
  clientContext?: string
  reason?: string
  signedBy?: string
  workerRole?: string
  companyId?: string
  branchName?: string
  userName?: string
  entryHash?: string
  previousHash?: string
}

export interface ErrorCodeEntry {
  code: string
  name: string
  category: string
  level: string
  userImpact?: string
  aiFixHint?: string
}

export interface ErrorCodeCatalog {
  version: string
  totalCodes: number
  codes: ErrorCodeEntry[]
}

export interface HashChainIntegrityResponse {
  checkedCount: number
  intact: boolean
  firstBrokenEntryId?: string
  message: string
}

export interface FrontendLogEntry {
  level: 'ERROR' | 'WARN'
  eventType: string
  errorCode?: string
  message: string
  clientTs?: string
  traceId?: string
  clientContext?: 'CASHIER' | 'TREASURY_HQ' | 'RFM' | 'ADMIN'
  clientVersion?: string
  attrs?: Record<string, unknown>
  stackTrace?: string
}

export const auditDiagnosticsApi = {
  recentErrors: async (limit = 100): Promise<AuditLogEntry[]> => {
    const response = await api.get<AuditLogEntry[]>('/diagnostics/audit/recent-errors', {
      params: { limit },
    })
    return response.data
  },

  byTrace: async (traceId: string): Promise<AuditLogEntry[]> => {
    const response = await api.get<AuditLogEntry[]>(`/diagnostics/audit/trace/${traceId}`)
    return response.data
  },

  entityChain: async (entityType: string, entityId: string): Promise<AuditLogEntry[]> => {
    const response = await api.get<AuditLogEntry[]>(
      `/diagnostics/audit/entity/${entityType}/${entityId}`,
    )
    return response.data
  },

  errorCodes: async (): Promise<ErrorCodeCatalog> => {
    const response = await api.get<ErrorCodeCatalog>('/diagnostics/audit/error-codes')
    return response.data
  },

  verifyHashChain: async (lastN = 100): Promise<HashChainIntegrityResponse> => {
    const response = await api.get<HashChainIntegrityResponse>(
      '/diagnostics/audit/hash-chain-verify',
      { params: { lastN } },
    )
    return response.data
  },

  forwardLog: async (entry: FrontendLogEntry): Promise<void> => {
    await api.post('/diagnostics/audit/log', entry)
  },
}
