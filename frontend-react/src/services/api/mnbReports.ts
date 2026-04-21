import { api } from './client'

export type MnbReportStatus = 'DRAFT' | 'SUBMITTED' | 'ACKNOWLEDGED' | 'REJECTED'

export interface MnbReportLine {
    id: string
    currencyCode: string
    buyAmount: number
    sellAmount: number
    buyHufTotal: number
    sellHufTotal: number
    avgBuyRate?: number
    avgSellRate?: number
}

export interface MnbReport {
    id: string
    companyId: string
    periodStart: string
    periodEnd: string
    status: MnbReportStatus
    submittedAt?: string
    acknowledgedAt?: string
    rejectedAt?: string
    mnbReferenceNumber?: string
    submissionError?: string
    retryCount?: number
    lastRetryAt?: string
    createdAt: string
    lines?: MnbReportLine[]
}

export const mnbReportsApi = {
    list: async (): Promise<MnbReport[]> => {
        const r = await api.get<MnbReport[]>('/mnb/reports')
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

    getDaily: async (date: string): Promise<MnbReport> => {
        const r = await api.get<MnbReport>(`/mnb/reports/daily?date=${date}`)
        return r.data
    },

    getMonthly: async (year: number, month: number): Promise<MnbReport> => {
        const r = await api.get<MnbReport>(`/mnb/reports/monthly?year=${year}&month=${month}`)
        return r.data
    },
}