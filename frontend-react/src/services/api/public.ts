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

  /** Get all active branches for a company (no-auth). */
  getBranchesByCompany: async (companyCode: string): Promise<PublicBranch[]> => {
    if (!companyCode) return []
    const response = await api.get<PublicBranch[]>("/public/branches", {
      params: { companyCode },
    })
    return response.data ?? []
  },
}
