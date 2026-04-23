import { api } from './client'

// Enum tipusok a backend Status-szal szinkronban
export type StocktakeStatus = 'OPEN' | 'IN_PROGRESS' | 'REVIEW' | 'CLOSED' | 'CANCELLED'

export interface VaultStocktakeItem {
    id: string
    sessionId: string
    currencyId: number
    currencyCode: string
    faceValue: number
    expectedQuantity: number
    actualQuantity: number | null
    discrepancy: number | null
    discrepancyValue: number | null
    countedBy: string | null
    countedAt: string | null
    note: string | null
}

export interface VaultStocktakeSession {
    id: string
    companyId: string
    branchId: string | null
    territoryId: number | null
    sessionName: string
    status: StocktakeStatus
    startedAt: string
    completedAt: string | null
    startedBy: string
    reviewedBy: string | null
    approvedBy: string | null
    note: string | null
    discrepancyTotalHuf: number
    items?: VaultStocktakeItem[]
}

export interface StocktakeSummary {
    sessionId: string
    sessionName: string
    status: StocktakeStatus
    totalItems: number
    countedItems: number
    discrepancyItems: number
    totalDiscrepancyHuf: number
    discrepancies: VaultStocktakeItem[]
}

export interface CreateSessionRequest {
    branchId?: string
    territoryId?: number
    sessionName: string
    note?: string
}

export interface CountItemRequest {
    actualQuantity: number
    note?: string
}

export const vaultStocktakeApi = {
    /** POST /api/v1/vault-stocktake - uj leltar session */
    create: async (req: CreateSessionRequest): Promise<VaultStocktakeSession> => {
        const r = await api.post<VaultStocktakeSession>('/vault-stocktake', req)
        return r.data
    },

    /** GET /api/v1/vault-stocktake - session lista */
    list: async (): Promise<VaultStocktakeSession[]> => {
        const r = await api.get<VaultStocktakeSession[]>('/vault-stocktake')
        return r.data
    },

    /** GET /api/v1/vault-stocktake/{id} - session details + items */
    get: async (id: string): Promise<VaultStocktakeSession> => {
        const r = await api.get<VaultStocktakeSession>(`/vault-stocktake/${id}`)
        return r.data
    },

    /** POST /api/v1/vault-stocktake/items/{itemId}/count - felvetel */
    countItem: async (itemId: string, req: CountItemRequest): Promise<VaultStocktakeItem> => {
        const r = await api.post<VaultStocktakeItem>(`/vault-stocktake/items/${itemId}/count`, req)
        return r.data
    },

    /** POST /api/v1/vault-stocktake/{id}/review - REVIEW fazisba */
    review: async (id: string): Promise<VaultStocktakeSession> => {
        const r = await api.post<VaultStocktakeSession>(`/vault-stocktake/${id}/review`)
        return r.data
    },

    /** POST /api/v1/vault-stocktake/{id}/close - CLOSED (FOERTEKTAR+ role) */
    close: async (id: string): Promise<VaultStocktakeSession> => {
        const r = await api.post<VaultStocktakeSession>(`/vault-stocktake/${id}/close`)
        return r.data
    },

    /** POST /api/v1/vault-stocktake/{id}/cancel */
    cancel: async (id: string, reason: string): Promise<VaultStocktakeSession> => {
        const r = await api.post<VaultStocktakeSession>(`/vault-stocktake/${id}/cancel`, { reason })
        return r.data
    },

    /** GET /api/v1/vault-stocktake/{id}/summary */
    summary: async (id: string): Promise<StocktakeSummary> => {
        const r = await api.get<StocktakeSummary>(`/vault-stocktake/${id}/summary`)
        return r.data
    },
}