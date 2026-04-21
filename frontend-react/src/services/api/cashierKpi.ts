import { api } from './client'

export interface CashierKpiRow {
    workerId: number
    workerName: string
    txCount: number
    buyCount: number
    sellCount: number
    reversalCount: number
    totalHuf: number
    buyHuf: number
    sellHuf: number
    totalFees: number
    customerCount: number
    avgTxHuf: number
    reversalRatio: number
}

export interface CashierKpiSummary {
    dateFrom: string
    dateTo: string
    totalTxCount: number
    totalBuyCount: number
    totalSellCount: number
    totalReversalCount: number
    totalHuf: number
    totalFees: number
    activeWorkerCount: number
    totalCustomerCount: number
    reversalRatio: number
    rows: CashierKpiRow[]
}

export const cashierKpiApi = {
    /**
     * B2: Penztaros KPI dashboard adatok lekerese adott idotartomanyra.
     * @param dateFrom YYYY-MM-DD
     * @param dateTo YYYY-MM-DD
     */
    get: async (dateFrom: string, dateTo: string): Promise<CashierKpiSummary> => {
        const r = await api.get<CashierKpiSummary>('/cashier-kpis', {
            params: { dateFrom, dateTo },
        })
        return r.data
    },
}