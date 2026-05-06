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
