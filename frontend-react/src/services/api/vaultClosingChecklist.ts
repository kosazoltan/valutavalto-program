import { api } from './client'

/**
 * Értéktári zárás-előtti ellenőrzőlista API (FR-ZARUI-16..26).
 */

export interface VaultClosingChecklistDto {
  id: string
  branchId: string
  branchName?: string
  closingDate: string
  item1: boolean
  item2: boolean
  item3: boolean
  item4: boolean
  item5: boolean
  item6: boolean
  item7: boolean
  item8: boolean
  item9: boolean
  /** FR-ZARUI-26 ellenőrző személy neve */
  auditorName?: string | null
  /** FR-ZARUI-26 ellenőrző személy beosztása */
  auditorRole?: string | null
  completedByWorkerId?: number | null
  completedAt?: string | null
  createdAt?: string
  updatedAt?: string
}

export interface UpdateChecklistItemsRequest {
  item1: boolean
  item2: boolean
  item3: boolean
  item4: boolean
  item5: boolean
  item6: boolean
  item7: boolean
  item8: boolean
  item9: boolean
}

export interface CompleteChecklistRequest {
  auditorName: string
  auditorRole: string
}

export const vaultClosingChecklistApi = {
  /** Checklist lekérése vagy létrehozása (idempotens). */
  getOrCreate: async (branchId: string, date: string): Promise<VaultClosingChecklistDto> => {
    const res = await api.get<VaultClosingChecklistDto>('/vault-closing-checklist', {
      params: { branchId, date },
    })
    return res.data
  },

  /** 9 checkbox-tétel mentése (FR-ZARUI-17..25). */
  updateItems: async (
    branchId: string,
    date: string,
    req: UpdateChecklistItemsRequest,
  ): Promise<VaultClosingChecklistDto> => {
    const res = await api.put<VaultClosingChecklistDto>('/vault-closing-checklist', req, {
      params: { branchId, date },
    })
    return res.data
  },

  /** Zárás véglegesítése — FR-ZARUI-26 ellenőrző személy adataival. */
  complete: async (
    branchId: string,
    date: string,
    req: CompleteChecklistRequest,
  ): Promise<VaultClosingChecklistDto> => {
    const res = await api.post<VaultClosingChecklistDto>('/vault-closing-checklist/complete', req, {
      params: { branchId, date },
    })
    return res.data
  },
}
