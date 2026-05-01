import { api } from "./client"

// ================== PUBLIC API (no-auth) ==================

export interface PublicWorker {
  code: string
  name: string
  region: string
}

export interface PublicBranch {
  code: string
  name: string
  city?: string
  address?: string
  /** v2.5.0 B6: ÉRTÉKTÁRI fiók-e (TRUE = vault, FALSE = pénztár). */
  isVault?: boolean
}

export const publicApi = {
  /** Get active workers for the region of the given branch (no-auth). */
  getWorkersByBranch: async (branchCode: string): Promise<PublicWorker[]> => {
    if (!branchCode) return []
    const response = await api.get<PublicWorker[]>("/public/workers", {
      params: { branchCode },
    })
    return response.data ?? []
  },

  /**
   * Get all active branches for a company (no-auth).
   *
   * v2.5.0 B6: opcionális `vaultOnly=true` szűrő, ami csak az ÉRTÉKTÁRI
   * (is_vault=TRUE) fiókokat adja vissza — a SetupWizard értéktár módú
   * telepítéskor használja.
   */
  getBranchesByCompany: async (companyCode: string, vaultOnly = false): Promise<PublicBranch[]> => {
    if (!companyCode) return []
    const response = await api.get<PublicBranch[]>("/public/branches", {
      params: { companyCode, vaultOnly },
    })
    return response.data ?? []
  },
}
