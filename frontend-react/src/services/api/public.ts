import { api } from './client'

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
  /** v2.5.1-E B6: ÉRTÉKTÁRI fiók-e (TRUE = vault, FALSE = pénztár). */
  isVault?: boolean
}

export interface GoogleConfigStatus {
  webConfigured: boolean
  desktopConfigured: boolean
  webPrefix: string
  desktopPrefix: string
  desktopPrefixes: string[]
  activeProfile: string
}

export interface SetupGoogleIdentifyRequest {
  idToken: string
  companyCode: string
  appMode: string
  selectedWorkerCode?: string
  bindGoogleSubject?: boolean
}

export interface SetupGoogleIdentifyResponse {
  matchType: 'WORKER_EMAIL' | 'HQ_EMAIL' | 'BRANCH_SHARED_EMAIL'
  requiresWorkerSelection: boolean
  message?: string
  googleIdentity: {
    email: string
    googleSub: string
    name?: string | null
    picture?: string | null
  }
  branch?: {
    code: string
    name: string
    city?: string
    address?: string
    isVault?: boolean
  } | null
  worker?: {
    code: string
    name: string
    role?: string | null
    roles?: string[]
    validAppModes?: string[]
  } | null
  workerOptions?: Array<{
    code: string
    name: string
    role?: string | null
    roles?: string[]
    validAppModes?: string[]
  }>
  validAppModes?: string[]
  requestedAppModeAllowed?: boolean
}

function customApiUrl(apiBase: string | undefined, endpoint: string): string | null {
  const normalized = apiBase?.trim().replace(/\/+$/, '')
  return normalized ? `${normalized}${endpoint}` : null
}

export const publicApi = {
  /** Get active workers for the region of the given branch (no-auth). */
  getWorkersByBranch: async (branchCode: string, companyCode?: string): Promise<PublicWorker[]> => {
    const normalizedBranchCode = branchCode.trim()
    const normalizedCompanyCode = companyCode?.trim() ?? ''
    if (!normalizedBranchCode || !normalizedCompanyCode) return []
    const response = await api.get<PublicWorker[]>('/public/workers', {
      params: {
        branchCode: normalizedBranchCode,
        companyCode: normalizedCompanyCode,
      },
    })
    return response.data ?? []
  },

  /**
   * Get all active branches for a company (no-auth).
   *
   * v2.5.1-E B6: opcionális `vaultOnly=true` szűrő, ami csak az ÉRTÉKTÁRI
   * (is_vault=TRUE) fiókokat adja vissza — a SetupWizard értéktár módú
   * telepítéskor használja.
   */
  getBranchesByCompany: async (companyCode: string, vaultOnly = false): Promise<PublicBranch[]> => {
    if (!companyCode) return []
    const response = await api.get<PublicBranch[]>('/public/branches', {
      params: { companyCode, vaultOnly },
    })
    return response.data ?? []
  },

  getGoogleConfigStatus: async (apiBase?: string): Promise<GoogleConfigStatus> => {
    const customUrl = customApiUrl(apiBase, '/public/auth/google-config-status')
    const response = customUrl
      ? await api.get<GoogleConfigStatus>(customUrl)
      : await api.get<GoogleConfigStatus>('/public/auth/google-config-status')
    return response.data
  },

  identifyGoogleSetup: async (
    request: SetupGoogleIdentifyRequest,
    options?: { apiBase?: string; idempotencyKey?: string },
  ): Promise<SetupGoogleIdentifyResponse> => {
    const config = options?.idempotencyKey
      ? { headers: { 'Idempotency-Key': options.idempotencyKey } }
      : undefined
    const customUrl = customApiUrl(options?.apiBase, '/public/setup/google-identify')
    const response = customUrl
      ? await api.post<SetupGoogleIdentifyResponse>(customUrl, request, config)
      : await api.post<SetupGoogleIdentifyResponse>(
          '/public/setup/google-identify',
          request,
          config,
        )
    return response.data
  },
}
