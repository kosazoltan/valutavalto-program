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
    customerId: string
    transactionId: string | null
    reportType: string
    riskLevel: string
    amountHuf: number
    currencyCode: string | null
    customerName: string | null
    documentType: string | null
    documentNumber: string | null
    status: string
    submittedAt: string | null
    createdAt: string
    deadlineAt: string | null
    overdue: boolean
}

export const amlApi = {
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
}