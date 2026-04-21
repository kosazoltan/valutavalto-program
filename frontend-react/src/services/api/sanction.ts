import { api } from './client'

// ========== Types ==========

export type SanctionListType = 'UN' | 'EU' | 'OFAC'
export type SanctionMatchType = 'EXACT' | 'PARTIAL' | 'ALIAS'
export type SanctionRiskLevel = 'CLEAR' | 'POSSIBLE' | 'CONFIRMED'

export interface SanctionScreeningRequest {
    name: string
    documentNumber?: string
    dateOfBirth?: string  // YYYY-MM-DD
}

export interface SanctionMatch {
    entryId: string
    fullName: string
    aliases?: string
    dateOfBirth?: string
    nationality?: string
    documentNumber?: string
    listType: SanctionListType
    listReference?: string
    matchType: SanctionMatchType
    score: number  // 0.0 - 1.0
}

export interface SanctionScreeningResult {
    matched: boolean
    matches: SanctionMatch[]
    riskLevel: SanctionRiskLevel
}

export interface SanctionEntry {
    id: string
    fullName: string
    aliases?: string
    dateOfBirth?: string
    nationality?: string
    documentNumber?: string
    listType: SanctionListType
    listReference?: string
    addedDate?: string
    lastUpdated?: string
    active: boolean
    createdAt?: string
    updatedAt?: string
}

export interface SanctionStatusResponse {
    lastUpdateDate?: string
    activeEntryCount: number
}

export interface SanctionImportResult {
    imported: number
    message: string
}

// ========== API ==========

export const sanctionApi = {
    /**
     * AML/KYC szurese ugyfelre. Minden penztaros hasznalhat.
     */
    screen: async (req: SanctionScreeningRequest): Promise<SanctionScreeningResult> => {
        const r = await api.post<SanctionScreeningResult>('/sanctions/screen', req)
        return r.data
    },

    /**
     * Listazott szankcios bejegyzesek (pagination). SUPERVISOR+.
     */
    list: async (page = 0, size = 50): Promise<SanctionEntry[]> => {
        const r = await api.get<SanctionEntry[]>('/sanctions/list', { params: { page, size } })
        return r.data ?? []
    },

    /**
     * Uj szankcios lista import (XML fajl). MANAGER+.
     */
    import: async (file: File): Promise<SanctionImportResult> => {
        const formData = new FormData()
        formData.append('file', file)
        const r = await api.post<SanctionImportResult>('/sanctions/import', formData, {
            headers: { 'Content-Type': 'multipart/form-data' },
        })
        return r.data
    },

    /**
     * Utolso frissites allapota + aktiv bejegyzesek szama.
     */
    status: async (): Promise<SanctionStatusResponse> => {
        const r = await api.get<SanctionStatusResponse>('/sanctions/status')
        return r.data
    },
}