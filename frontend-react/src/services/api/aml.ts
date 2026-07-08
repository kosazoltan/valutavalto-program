import { api } from './client'

export interface RollingWindowAuditDto {
  customerId: string
  customerName: string | null
  rollingWindowTotalHuf: number
  rollingWindowLimitHuf: number
  exceedPercent: number
  auditAt: string
  sinceDate: string
  windowDays: number
  highRiskFlag: boolean
}

export interface AmlDailySummary {
  date: string
  totalReports: number
  pendingReports: number
  submittedReports: number
  flaggedReports: number
  standardChecks: number
  enhancedChecks: number
  suspiciousChecks: number
  thresholdChecks: number
  totalAmountHuf: number
}

export interface AmlReportDto {
  id: string
  customerId: string | null
  transactionId: string | null
  reportType: string
  riskLevel: string
  amountHuf: number
  currencyCode: string | null
  originalAmount: number | null
  customerName: string | null
  documentType: string | null
  documentNumber: string | null
  workerNotes: string | null
  reviewedBy: string | null
  reviewedAt: string | null
  status: string
  submittedAt: string | null
  acknowledgedAt: string | null
  externalReference: string | null
  createdBy: string | null
  createdAt: string
  deadlineAt: string | null
  overdue: boolean
}

export interface CreateAmlReportRequest {
  customerId?: string
  transactionId?: number
  reportType: 'STANDARD' | 'ENHANCED' | 'SUSPICIOUS' | 'THRESHOLD'
  riskLevel?: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'
  amountHuf: number
  currencyCode?: string
  originalAmount?: number
  customerName?: string
  documentType?: string
  documentNumber?: string
  workerNotes?: string
}

export interface CustomerRiskProfile {
  customerId: string
  customerName: string | null
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL' | string
  last30DaysTotal: number
  last30DaysTransactionCount: number
  dailyTotal: number
  dailyTransactionCount: number
  annualTotal: number
  structuringDetected: boolean
  highFrequency: boolean
  highVolume: boolean
}

export interface StructuringCheckResult {
  customerId: string
  structuringDetected: boolean
}

export interface AmlTransactionCheckRequest {
  amountHuf: number
  customerId?: string
  currencyCode?: string
}

export interface AmlCheckResult {
  transactionType: number
  weeklyTotal: number
  yearlyMax: number
  quarterlyCount: number
  quarterlyTotal: number
  requiresId: boolean
  requiresEnhanced: boolean
  blocked: boolean
  rollingWindowExceeded: boolean
  rollingWindowLimit: number
  rollingWindowTotal: number
  rollingWindowDays: number
  requiresManagerApproval: boolean
  managerApprovalReason: string | null
  warnings: string[]
}

export const amlApi = {
  /** POST /api/v1/aml/check */
  checkTransaction: async (request: AmlTransactionCheckRequest): Promise<AmlCheckResult> => {
    const r = await api.post<AmlCheckResult>('/aml/check', request)
    return r.data
  },

  /** GET /api/v1/aml/rolling-window-audit - Sprint 6.2 compliance */
  rollingWindowAudit: async (thresholdHuf?: number): Promise<RollingWindowAuditDto[]> => {
    const r = await api.get<RollingWindowAuditDto[]>('/aml/rolling-window-audit', {
      params: thresholdHuf ? { thresholdHuf } : {},
    })
    return r.data
  },

  /** GET /api/v1/aml/summary?date= */
  dailySummary: async (date: string): Promise<AmlDailySummary> => {
    const r = await api.get<AmlDailySummary>('/aml/summary', { params: { date } })
    return r.data
  },

  /** GET /api/v1/aml/overdue */
  overdueReports: async (): Promise<AmlReportDto[]> => {
    const r = await api.get<AmlReportDto[]>('/aml/overdue')
    return r.data
  },

  /** GET /api/v1/aml/pending */
  pendingReports: async (): Promise<AmlReportDto[]> => {
    const r = await api.get<AmlReportDto[]>('/aml/pending')
    return r.data
  },

  /** POST /api/v1/aml/report */
  submitReport: async (request: CreateAmlReportRequest): Promise<AmlReportDto> => {
    const r = await api.post<AmlReportDto>('/aml/report', request)
    return r.data
  },

  /** GET /api/v1/aml/customer-risk/{customerId} */
  customerRisk: async (customerId: string): Promise<CustomerRiskProfile> => {
    const r = await api.get<CustomerRiskProfile>(`/aml/customer-risk/${customerId}`)
    return r.data
  },

  /** GET /api/v1/aml/structuring-check/{customerId} */
  structuringCheck: async (customerId: string): Promise<StructuringCheckResult> => {
    const r = await api.get<StructuringCheckResult>(`/aml/structuring-check/${customerId}`)
    return r.data
  },
}
