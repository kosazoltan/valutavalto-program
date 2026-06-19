import { api } from './client'

export type MnbReportStatus = 'DRAFT' | 'SUBMITTED' | 'ACKNOWLEDGED' | 'REJECTED'

export interface MnbReportLine {
    id: string
    currencyCode: string
    buyAmount: number
    sellAmount: number
    buyHuf?: number
    sellHuf?: number
    buyHufTotal?: number
    sellHufTotal?: number
    buyRate?: number
    sellRate?: number
    avgBuyRate?: number
    avgSellRate?: number
    transactionCount?: number
}

export interface MnbReport {
    id: string
    companyId?: string
    periodStart?: string
    periodEnd?: string
    reportType?: string
    reportDate?: string
    status: MnbReportStatus
    branchId?: string
    totalBuyHuf?: number
    totalSellHuf?: number
    totalTransactions?: number
    submittedAt?: string
    acceptedAt?: string
    acknowledgedAt?: string
    rejectedAt?: string
    rejectionReason?: string
    mnbReferenceNumber?: string
    submissionError?: string
    retryCount?: number
    lastRetryAt?: string
    createdAt?: string
    lines?: MnbReportLine[]
}

export interface MnbCurrencyLine {
    currencyCode: string
    buyAmount?: number
    sellAmount?: number
    buyHuf?: number
    sellHuf?: number
    avgBuyRate?: number
    avgSellRate?: number
    transactionCount?: number
    openingBalance?: number
    closingBalance?: number
    calculatedClosing?: number
    balanceDiff?: number
    validationStatus?: string
}

export interface MnbDailyReport {
    date: string
    totalBuyHuf: number
    totalSellHuf: number
    totalTransactions: number
    currencyLines?: MnbCurrencyLine[]
}

export interface MnbMonthlyReport {
    month: string
    totalBuyHuf: number
    totalSellHuf: number
    totalTransactions: number
    workingDays: number
    currencyLines?: MnbCurrencyLine[]
}

export const mnbReportsApi = {
    list: async (params?: { size?: number }): Promise<MnbReport[]> => {
        const r = await api.get<MnbReport[]>('/mnb/reports', { params })
        return r.data ?? []
    },

    get: async (id: string): Promise<MnbReport> => {
        const r = await api.get<MnbReport>(`/mnb/reports/${id}`)
        return r.data
    },

    generate: async (periodStart: string, periodEnd: string): Promise<MnbReport> => {
        const r = await api.post<MnbReport>('/mnb/reports/generate', { periodStart, periodEnd })
        return r.data
    },

    submit: async (id: string): Promise<MnbReport> => {
        const r = await api.post<MnbReport>(`/mnb/reports/${id}/submit`)
        return r.data
    },

    /** XML letoltes - a browser lementi a file-t. */
    downloadXml: async (id: string): Promise<Blob> => {
        const r = await api.get(`/mnb/reports/${id}/xml`, { responseType: 'blob' })
        return r.data as unknown as Blob
    },

    /** Napi riport XML download datum szerint. */
    downloadDailyXml: async (date: string): Promise<Blob> => {
        const r = await api.get(`/mnb/reports/daily/xml?date=${date}`, { responseType: 'blob' })
        return r.data as unknown as Blob
    },

    getDaily: async (date: string): Promise<MnbDailyReport> => {
        const r = await api.get<MnbDailyReport>(`/mnb/reports/daily?date=${date}`)
        return r.data
    },

    getMonthly: async (month: string): Promise<MnbMonthlyReport> => {
        const r = await api.get<MnbMonthlyReport>(`/mnb/reports/monthly?month=${month}`)
        return r.data
    },

    validate: async (date: string): Promise<string[]> => {
        const r = await api.get<string[]>(`/mnb/reports/validate?date=${date}`)
        return r.data ?? []
    },
}
