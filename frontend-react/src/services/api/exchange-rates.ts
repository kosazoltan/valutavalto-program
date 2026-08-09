import { api } from './client'
import { asArray } from '../../utils/asArray'

// ================== EXCHANGE RATES API ==================

export interface ExchangeRate {
  id: number
  currencyId: number
  currencyCode: string
  currencyName: string
  validDate: string
  validTime: string
  /** FKH-032 FR-6: az árfolyam kora órában (backend számított mező). */
  ageHours?: number
  /** FKH-032 FR-6: elavult-e az árfolyam a szerver `exchange-rate.max-age-hours` szerint. */
  stale?: boolean
  baseBuyRate: number
  baseSellRate: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
  officialRate?: number
  active: boolean
  createdBy?: string
  createdAt: string
}

export interface RateApproval {
  id?: string
  branchId?: string
  branchName?: string
  currencyCode: string
  oldBuyRate?: number | string | null
  oldSellRate?: number | string | null
  newBuyRate?: number | string | null
  newSellRate?: number | string | null
  status?: string | null
  requestedById?: number | null
  requestedByName?: string | null
  approvedById?: number | null
  approvedByName?: string | null
  requestedAt?: string | null
  approvedAt?: string | null
  reason?: string | null
}

export interface RequestRateChangeRequest {
  branchId: string
  currencyCode: string
  newBuyRate: number
  newSellRate: number
  reason?: string
}

export interface CreateExchangeRateRequest {
  currencyId: number
  baseBuyRate: number
  baseSellRate: number
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
  officialRate?: number
}

export interface ParsedCurrencyRate {
  currencyCode: string
  buyRate?: number | string | null
  sellRate?: number | string | null
  mnbRate?: number | string | null
  discountBuy?: number | string | null
  discountSell?: number | string | null
  f1Buy?: number | string | null
  f1Sell?: number | string | null
  chiefTreasurerBuy?: number | string | null
  chiefTreasurerSell?: number | string | null
}

export interface ParsedRateFile {
  rates: ParsedCurrencyRate[]
  parsedAt?: string | null
  parsedLineCount: number
  skippedLineCount: number
}

function createRateFileFormData(file: File): FormData {
  const formData = new FormData()
  formData.append('file', file)
  return formData
}

export const exchangeRateApi = {
  list: async (): Promise<ExchangeRate[]> => {
    const response = await api.get<ExchangeRate[]>('/exchange-rates')
    return response.data
  },
  getByCurrencyId: async (currencyId: number): Promise<ExchangeRate> => {
    const response = await api.get<ExchangeRate>(`/exchange-rates/currency/${currencyId}`)
    return response.data
  },
  getByCurrencyCode: async (currencyCode: string): Promise<ExchangeRate> => {
    const response = await api.get<ExchangeRate>(`/exchange-rates/code/${currencyCode}`)
    return response.data
  },
  getBuyRateForAmount: async (currencyId: number, hufAmount: number): Promise<number> => {
    const response = await api.get<number>('/exchange-rates/buy-rate', {
      params: { currencyId, hufAmount },
    })
    return response.data
  },
  getSellRateForAmount: async (currencyId: number, hufAmount: number): Promise<number> => {
    const response = await api.get<number>('/exchange-rates/sell-rate', {
      params: { currencyId, hufAmount },
    })
    return response.data
  },
  create: async (data: CreateExchangeRateRequest): Promise<ExchangeRate> => {
    const response = await api.post<ExchangeRate>('/exchange-rates', data)
    return response.data
  },
  getHistoryByCode: async (
    currencyCode: string,
    startDate: string,
    endDate: string,
  ): Promise<ExchangeRate[]> => {
    const response = await api.get<ExchangeRate[]>('/exchange-rates/history', {
      params: { currencyCode, startDate, endDate },
    })
    return response.data
  },
  uploadRateFile: async (file: File): Promise<ParsedRateFile> => {
    const response = await api.post<ParsedRateFile>(
      '/exchange-rates/upload-rate-file',
      createRateFileFormData(file),
      {
        headers: { 'Content-Type': 'multipart/form-data' },
      },
    )
    return response.data
  },
  importRateFile: async (file: File): Promise<ExchangeRate[]> => {
    const response = await api.post<ExchangeRate[]>(
      '/exchange-rates/import-rate-file',
      createRateFileFormData(file),
      {
        headers: { 'Content-Type': 'multipart/form-data' },
      },
    )
    return response.data
  },
}

export const rateApprovalApi = {
  request: async (data: RequestRateChangeRequest): Promise<RateApproval> => {
    const response = await api.post<RateApproval>('/rate-approvals/request', data)
    return response.data
  },
  approve: async (id: string): Promise<RateApproval> => {
    const response = await api.post<RateApproval>(`/rate-approvals/${id}/approve`)
    return response.data
  },
  reject: async (id: string, reason?: string): Promise<RateApproval> => {
    const response = await api.post<RateApproval>(
      `/rate-approvals/${id}/reject`,
      reason?.trim() ? { reason: reason.trim() } : undefined,
    )
    return response.data
  },
  pending: async (): Promise<RateApproval[]> => {
    const response = await api.get<RateApproval[]>('/rate-approvals/pending')
    return response.data
  },
  history: async (branchId?: string): Promise<RateApproval[]> => {
    const response = await api.get<RateApproval[]>('/rate-approvals/history', {
      params: branchId ? { branchId } : undefined,
    })
    return response.data
  },
}

// Legacy alias for backward compatibility
export const rateApi = exchangeRateApi

// ================== CURRENCIES API ==================

export interface Currency {
  id: number
  code: string
  name: string
  symbol?: string
  decimals: number
  displayOrder?: number
  active: boolean
}

export const currencyApi = {
  list: async (): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies')
    return response.data
  },
  getAll: async (): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies/all')
    return response.data
  },
  getActive: async (): Promise<Currency[]> => {
    // Same as list - returns only active currencies
    const response = await api.get<Currency[]>('/currencies')
    return response.data
  },
  getByCode: async (code: string): Promise<Currency> => {
    const response = await api.get<Currency>(`/currencies/code/${code}`)
    return response.data
  },
  getById: async (id: number): Promise<Currency> => {
    const response = await api.get<Currency>(`/currencies/${id}`)
    return response.data
  },
  // V238 (2026-05-19): admin endpoints — uj valuta + aktivalas/deaktivalas auditalva
  create: async (data: {
    code: string
    name: string
    symbol?: string
    decimalPlaces?: number
    displayOrder?: number
  }): Promise<Currency> => {
    const response = await api.post<Currency>('/currencies', data)
    return response.data
  },
  setActive: async (id: number, active: boolean, note?: string): Promise<Currency> => {
    const response = await api.patch<Currency>(`/currencies/${id}/active`, { active, note })
    return response.data
  },
  search: async (query: string): Promise<Currency[]> => {
    const response = await api.get<Currency[]>('/currencies/search', { params: { q: query } })
    return response.data
  },
}

// ================== CURRENCY DENOMINATION IMAGES API (FS-9 S2) ==================

export type CurrencyDenominationType = 'BANKNOTE' | 'COIN'
export type CurrencyDenominationSide = 'FRONT' | 'BACK'

export interface CurrencyDenominationImageDto {
  id: string
  currencyId: number
  faceValue: number
  denominationType: CurrencyDenominationType | string
  side: CurrencyDenominationSide | string
  mimeType: string
  fileSizeBytes: number
  active: boolean
  createdAt: string
  updatedAt: string
}

export interface CurrencyDenominationImageUploadRequest {
  currencyId: number
  faceValue: number
  denominationType: CurrencyDenominationType
  side: CurrencyDenominationSide
  file: File
}

function assertValidCurrencyDenominationUpload(req: CurrencyDenominationImageUploadRequest): void {
  if (!Number.isFinite(req.currencyId) || req.currencyId <= 0) {
    throw new Error('Valuta kiválasztása kötelező')
  }
  if (!Number.isFinite(req.faceValue) || req.faceValue <= 0) {
    throw new Error('A címlet értékének pozitív számnak kell lennie')
  }
  if (req.denominationType !== 'BANKNOTE' && req.denominationType !== 'COIN') {
    throw new Error('Érvénytelen címlet típus')
  }
  if (req.side !== 'FRONT' && req.side !== 'BACK') {
    throw new Error('Érvénytelen oldal')
  }
  if (req.file.type !== 'image/jpeg' && req.file.type !== 'image/png') {
    throw new Error('Csak JPEG vagy PNG kép tölthető fel')
  }
}

export const currencyDenominationImageApi = {
  list: async (currencyId?: number): Promise<CurrencyDenominationImageDto[]> => {
    const response = await api.get<unknown>('/currency-denomination-images', {
      params: currencyId != null ? { currencyId } : {},
    })
    return asArray<CurrencyDenominationImageDto>(response.data)
  },
  upload: async (
    req: CurrencyDenominationImageUploadRequest,
  ): Promise<CurrencyDenominationImageDto> => {
    assertValidCurrencyDenominationUpload(req)
    const formData = new FormData()
    formData.append('currencyId', String(req.currencyId))
    formData.append('faceValue', String(req.faceValue))
    formData.append('denominationType', req.denominationType)
    formData.append('side', req.side)
    formData.append('file', req.file)
    const response = await api.post<CurrencyDenominationImageDto>(
      '/currency-denomination-images/upload',
      formData,
      { headers: { 'Content-Type': 'multipart/form-data' } },
    )
    return response.data
  },
  getThumbnail: async (id: string): Promise<Blob> => {
    const response = await api.get<Blob>(`/currency-denomination-images/${id}/thumbnail`, {
      responseType: 'blob',
    })
    return response.data
  },
  getImage: async (id: string): Promise<Blob> => {
    const response = await api.get<Blob>(`/currency-denomination-images/${id}/image`, {
      responseType: 'blob',
    })
    return response.data
  },
  setActive: async (id: string, active: boolean): Promise<CurrencyDenominationImageDto> => {
    const response = await api.put<CurrencyDenominationImageDto>(
      `/currency-denomination-images/${id}/active`,
      { active },
    )
    return response.data
  },
}

// ================== RATE CREATION API ==================

export interface BankRateDTO {
  id: string
  bankId: string
  bankCode: string
  bankName: string
  currencyId: string
  currencyCode: string
  currencyName: string
  buyRate: number
  sellRate: number
  middleRate: number
  validFrom: string
  validTo?: string
  isCurrent: boolean
  source?: string
}

export interface CompetitorRateDTO {
  id: string
  competitorId: string
  competitorCode: string
  competitorName: string
  currencyId: string
  currencyCode: string
  currencyName: string
  buyRate: number
  sellRate: number
  middleRate: number
  recordedAt: string
  source?: string
  recordedById?: string
  recordedByName?: string
}

// FK-041: a terület munkacsoportonkénti árfolyam-variánsa (értéktáros read-only nézet).
export interface TerritoryWorkgroupCurrencyRate {
  currencyId: number
  currencyCode: string
  currencyName: string
  hasRate: boolean
  baseBuyRate?: number | null
  baseSellRate?: number | null
  officialRate?: number | null
  limit1Amount?: number | null
  limit1BuyRate?: number | null
  limit1SellRate?: number | null
  limit2Amount?: number | null
  limit2BuyRate?: number | null
  limit2SellRate?: number | null
  limit3Amount?: number | null
  limit3BuyRate?: number | null
  limit3SellRate?: number | null
  validTime?: string | null
}

export interface TerritoryWorkgroupRateDTO {
  workgroupId: string
  workgroupCode: string
  workgroupName: string
  tileColor?: string | null
  branchNames: string[]
  limit1Boundary?: number | null
  limit2Boundary?: number | null
  limit3Boundary?: number | null
  currencies: TerritoryWorkgroupCurrencyRate[]
}

export interface RateCreationDTO {
  currencyId: string
  currencyCode: string
  currencyName: string
  bankRates: BankRateDTO[]
  competitorRates: CompetitorRateDTO[]
  recommendedBuyRate: number
  recommendedSellRate: number
  recommendedMiddleRate: number
  minBuyRate: number
  maxBuyRate: number
  avgBuyRate: number
  minSellRate: number
  maxSellRate: number
  avgSellRate: number
  notes?: string
}

export interface PrepareAllRatesResult {
  [key: string]: unknown
}

export interface GroupRateDTO {
  id: string
  currencyGroupId: string
  currencyGroupCode: string
  currencyGroupName: string
  currencyId: string
  currencyCode: string
  buyRate: number
  sellRate: number
  buyMargin: number
  sellMargin: number
  validFrom: string
  isCurrent: boolean
}

export interface GroupRateEntryDTO {
  currencyId: number
  buyRate: number
  sellRate: number
  officialRate?: number | null
  limit1Amount?: number | null
  limit1BuyRate?: number | null
  limit1SellRate?: number | null
  limit2Amount?: number | null
  limit2BuyRate?: number | null
  limit2SellRate?: number | null
  limit3Amount?: number | null
  limit3BuyRate?: number | null
  limit3SellRate?: number | null
}

export interface PublishGroupRateRequest {
  groupId: string
  rates: GroupRateEntryDTO[]
}

export interface LocalRatePublishResponse {
  publicationId: string
  workgroupId: string
  publishedAt: string
  acceptedRates: number
  affectedBranches: number
  status: 'ACCEPTED_AND_DISTRIBUTION_QUEUED'
  serverPackageHash: string
  branchCodes: string[]
}

export interface LocalRateMakerBootstrapDTO {
  generatedAt: string
  mode: 'LOCAL_RATE_MAKER' | string
  publishEndpoint: string
  idempotencyRequired: boolean
  overview: RateOverviewDTO
  workgroups: WorkgroupDetailDTO[]
}

export interface RateMakerSheetDTO {
  sheetJson: string
  version: number
  source: string | null
  deviceId: string | null
  updatedBy: number | null
  updatedAt: string | null
}

export interface RateMakerSheetUpdateRequest {
  sheetJson: string
  source?: 'rate-maker' | 'central' | string
  deviceId?: string
  baseVersion?: number | null
}

export interface RateOverviewDTO {
  generatedAt: string
  currencies: RateOverviewItem[]
}

export interface RateOverviewItem {
  currencyId: number
  currencyCode: string
  currencyName: string
  displayOrder: number
  currentBuyRate: number | null
  currentSellRate: number | null
  officialRate: number | null
  limit1Amount: number | null
  limit1BuyRate: number | null
  limit1SellRate: number | null
  limit2Amount: number | null
  limit2BuyRate: number | null
  limit2SellRate: number | null
  limit3Amount: number | null
  limit3BuyRate: number | null
  limit3SellRate: number | null
  buyMarginPercent: number | null
  sellMarginPercent: number | null
  spreadPercent: number | null
  middleRate: number | null
  lastUpdated: string | null
  hasRate: boolean
}

export interface WorkgroupDetailDTO {
  id: string
  code: string
  name: string
  legacyGroupNumber: number | null
  active: boolean
  branches: WorkgroupBranchInfo[]
  limit1Boundary: number
  limit2Boundary: number
  limit3Boundary: number
  /** FK-02 (V273): csempeszín-palettakulcs a csempés listanézethez (slate/red/orange/…). */
  tileColor?: string | null
  /** FK-04/E (V275): árfolyamvédelem flag — ha true, a backend a vétel ≤ J / eladás ≥ J szabályt érvényesíti save-kor. */
  protectionEnabled?: boolean | null
}

export interface WorkgroupBranchInfo {
  id: string
  code: string
  name: string
}

export interface BranchListItem {
  id: string
  code: string
  name: string
  city: string
  assignedToCurrentWorkgroup: boolean
}

async function getRateMakerDeviceId(): Promise<string> {
  const key = 'rate_maker_device_id'
  const electronApi = typeof window !== 'undefined' ? window.electronAPI : undefined
  if (electronApi?.getConfig && electronApi.setConfig) {
    const existing = await electronApi.getConfig(key)
    if (existing?.trim()) return existing.trim()
    const generated = `rate-maker-${crypto.randomUUID()}`
    await electronApi.setConfig(key, generated)
    return generated
  }

  const existing = window.localStorage.getItem(key)
  if (existing?.trim()) return existing.trim()
  const generated = `rate-maker-web-${crypto.randomUUID()}`
  window.localStorage.setItem(key, generated)
  return generated
}

async function sha256Hex(text: string): Promise<string> {
  if (!crypto.subtle) return ''
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

async function buildLocalRatePackage(data: PublishGroupRateRequest) {
  const clientPackageId = crypto.randomUUID()
  const createdAt = new Date().toISOString()
  const clientVersion =
    typeof window !== 'undefined' && window.electronAPI?.getAppVersion
      ? await window.electronAPI.getAppVersion()
      : (import.meta.env.VITE_APP_VERSION ?? __APP_VERSION__)

  const packageWithoutHash = {
    clientPackageId,
    clientDeviceId: await getRateMakerDeviceId(),
    clientVersion,
    createdAt,
    groupId: data.groupId,
    operatorNote: 'Helyi főértéktárosi árfolyamkészítő',
    rates: data.rates,
  }

  return {
    ...packageWithoutHash,
    clientPackageHash: await sha256Hex(JSON.stringify(packageWithoutHash)),
  }
}

export const rateCreationApi = {
  getLocalRateMakerBootstrap: async (): Promise<LocalRateMakerBootstrapDTO> => {
    const response = await api.get<LocalRateMakerBootstrapDTO>('/local-rate-maker/bootstrap')
    return response.data
  },
  getLocalRateMakerSheet: async (): Promise<RateMakerSheetDTO | null> => {
    const response = await api.get<RateMakerSheetDTO | ''>('/local-rate-maker/sheet', {
      validateStatus: (status) => status === 200 || status === 204,
    })
    if (response.status === 204 || !response.data) return null
    return response.data as RateMakerSheetDTO
  },
  putLocalRateMakerSheet: async (
    sheetJson: string,
    request: Omit<RateMakerSheetUpdateRequest, 'sheetJson'> = {},
  ): Promise<RateMakerSheetDTO> => {
    const payload: RateMakerSheetUpdateRequest = {
      sheetJson,
      source:
        request.source ??
        (import.meta.env.VITE_APP_FLAVOR === 'rate-maker' ? 'rate-maker' : 'central'),
      deviceId: request.deviceId ?? (await getRateMakerDeviceId()),
      ...(request.baseVersion != null ? { baseVersion: request.baseVersion } : {}),
    }
    const response = await api.put<RateMakerSheetDTO>('/local-rate-maker/sheet', payload)
    return response.data
  },
  getOverview: async (): Promise<RateOverviewDTO> => {
    const response = await api.get<RateOverviewDTO>('/rate-creation/overview')
    return response.data
  },
  getWorkgroupDetails: async (): Promise<WorkgroupDetailDTO[]> => {
    const response = await api.get<WorkgroupDetailDTO[]>('/rate-creation/workgroups')
    return response.data
  },
  getBankRates: async (): Promise<BankRateDTO[]> => {
    const response = await api.get<BankRateDTO[]>('/rate-creation/bank-rates')
    return response.data
  },
  getCompetitorRates: async (): Promise<CompetitorRateDTO[]> => {
    const response = await api.get<CompetitorRateDTO[]>('/rate-creation/competitor-rates')
    return response.data
  },
  // FK-041: a hívó területének (régió) munkacsoportonkénti árfolyam-variánsai az értéktáros nézetéhez.
  getTerritoryWorkgroupRates: async (): Promise<TerritoryWorkgroupRateDTO[]> => {
    const response = await api.get<TerritoryWorkgroupRateDTO[]>(
      '/rate-creation/territory-workgroup-rates',
    )
    return response.data
  },
  prepareRateCreation: async (currencyId: string): Promise<RateCreationDTO> => {
    const response = await api.get<RateCreationDTO>(`/rate-creation/prepare/${currencyId}`)
    return response.data
  },
  prepareAllCurrencies: async (): Promise<PrepareAllRatesResult> => {
    const response = await api.post<PrepareAllRatesResult>('/rate-creation/prepare/all')
    return response.data
  },
  publishGroupRate: async (
    data: PublishGroupRateRequest,
  ): Promise<void | LocalRatePublishResponse> => {
    if (import.meta.env.VITE_APP_FLAVOR === 'rate-maker') {
      const ratePackage = await buildLocalRatePackage(data)
      const response = await api.post<LocalRatePublishResponse>(
        '/local-rate-maker/packages/publish',
        ratePackage,
        { headers: { 'Idempotency-Key': ratePackage.clientPackageId } },
      )
      return response.data
    }
    await api.post('/rate-creation/publish-group-rate', data)
  },
  getBranches: async (workgroupId: string): Promise<BranchListItem[]> => {
    const response = await api.get<BranchListItem[]>(
      `/rate-creation/branches?workgroupId=${workgroupId}`,
    )
    return response.data
  },
  updateWorkgroupBranches: async (workgroupId: string, branchIds: string[]): Promise<void> => {
    await api.post(
      `/rate-creation/workgroups/${workgroupId}/branches`,
      { branchIds },
      { _skipGlobal403Toast: true },
    )
  },
  updateWorkgroupLimits: async (
    workgroupId: string,
    limits: { limit1Boundary: number; limit2Boundary: number; limit3Boundary: number },
  ): Promise<void> => {
    await api.put(`/rate-creation/workgroups/${workgroupId}/limits`, limits, {
      _skipGlobal403Toast: true,
    })
  },
}

// ================== CURRENCY GROUPS API ==================

export interface CurrencyGroupDTO {
  id: string
  code: string
  name: string
  description?: string
  currencyIds?: string | null
  sortOrder?: number
  isActive: boolean
}

export interface CurrencyGroupSaveDTO {
  code: string
  name: string
  description?: string | null
  currencyIds?: string | null
  isActive: boolean
}

export const currencyGroupApi = {
  list: async (): Promise<CurrencyGroupDTO[]> => {
    const response = await api.get<CurrencyGroupDTO[]>('/currency-groups')
    return response.data
  },
  getById: async (id: string): Promise<CurrencyGroupDTO> => {
    const response = await api.get<CurrencyGroupDTO>(`/currency-groups/${id}`)
    return response.data
  },
  create: async (data: CurrencyGroupSaveDTO): Promise<CurrencyGroupDTO> => {
    const response = await api.post<CurrencyGroupDTO>('/currency-groups', data)
    return response.data
  },
  update: async (id: string | number, data: CurrencyGroupSaveDTO): Promise<CurrencyGroupDTO> => {
    const response = await api.put<CurrencyGroupDTO>(`/currency-groups/${id}`, data)
    return response.data
  },
  remove: async (id: string | number): Promise<void> => {
    await api.delete(`/currency-groups/${id}`)
  },
}

// ================== RATE WORKGROUPS API ==================

export interface RateWorkgroupDTO {
  id: string
  code: string
  name: string
  legacyGroupNumber?: number
  active: boolean
  /** FK-02: csempe-szín paletta-kulcs (pl. 'amber'); null = alapértelmezett. */
  tileColor?: string | null
  /**
   * FK-04/E árfolyamvédelem: ha true, a csoport-lap mentésekor a backend
   * elutasítja a vételi > J vagy eladási < J értékeket. A csempe jobb felső
   * checkbox vezérli (A.3). Régi backend null-t adhat — false-ként kezelendő.
   */
  protectionEnabled?: boolean | null
  /** FK-04/D: kedvezményhatárok — alsó sáv felső határa Ft-ban. */
  limit1Boundary?: number | null
  /** FK-04/D: kedvezményhatárok — középső sáv felső határa Ft-ban. */
  limit2Boundary?: number | null
  /** FK-04/D: kedvezményhatárok — felső sáv felső határa Ft-ban. */
  limit3Boundary?: number | null
}

export interface RateWorkgroupSaveDTO {
  name: string
  code: string
  legacyGroupNumber?: number
  active: boolean
  tileColor?: string | null
  /** FK-04/E árfolyamvédelem flag (lásd RateWorkgroupDTO). */
  protectionEnabled?: boolean | null
  /** FK-04/D kedvezményhatárok (lásd RateWorkgroupDTO). */
  limit1Boundary?: number | null
  limit2Boundary?: number | null
  limit3Boundary?: number | null
}

export const rateWorkgroupApi = {
  list: async (): Promise<RateWorkgroupDTO[]> => {
    const response = await api.get<RateWorkgroupDTO[]>('/rate-management/workgroups')
    return response.data
  },
  create: async (data: RateWorkgroupSaveDTO): Promise<RateWorkgroupDTO> => {
    const response = await api.post<RateWorkgroupDTO>('/rate-management/workgroups', data)
    return response.data
  },
  update: async (id: string, data: RateWorkgroupSaveDTO): Promise<RateWorkgroupDTO> => {
    const response = await api.put<RateWorkgroupDTO>(`/rate-management/workgroups/${id}`, data)
    return response.data
  },
  // FK-02: "törlés" = soft-delete (inaktiválás) a backendben (FK-006 elv).
  remove: async (id: string): Promise<void> => {
    await api.delete(`/rate-management/workgroups/${id}`)
  },
}

// ================== COMPETITORS API ==================

export interface CompetitorDTO {
  id: string
  code: string
  name: string
  address?: string
  city?: string
  website?: string
  apiUrl?: string
  notes?: string
  branchId?: string | null
  isActive: boolean
  sortOrder?: number
}

export interface CompetitorSaveDTO {
  name: string
  website?: string | null
  branchId?: string | null
  isActive: boolean
}

export const competitorApi = {
  list: async (): Promise<CompetitorDTO[]> => {
    const response = await api.get<CompetitorDTO[]>('/competitors')
    return response.data
  },
  getById: async (id: string): Promise<CompetitorDTO> => {
    const response = await api.get<CompetitorDTO>(`/competitors/${id}`)
    return response.data
  },
  create: async (data: CompetitorSaveDTO): Promise<CompetitorDTO> => {
    const response = await api.post<CompetitorDTO>('/competitors', data)
    return response.data
  },
  update: async (id: string | number, data: CompetitorSaveDTO): Promise<CompetitorDTO> => {
    const response = await api.put<CompetitorDTO>(`/competitors/${id}`, data)
    return response.data
  },
  remove: async (id: string | number): Promise<void> => {
    await api.delete(`/competitors/${id}`)
  },
}

// ================== EXCHANGE RATE POLLING API ==================

export interface ExchangeRatePollingStatus {
  lastPollTime?: string | null
  lastPollSuccess: boolean
  lastPollError?: string | null
  lastPollUpdatedCount: number
  lastPollSource: string
}

export interface ExchangeRatePollingSource {
  id: number
  name: string
  url?: string
  pollIntervalMinutes?: number
  active: boolean
  lastSuccessAt?: string | null
  lastErrorAt?: string | null
  lastError?: string | null
  successCount?: number
  errorCount?: number
}

export type EcbRateSnapshot = Record<string, number | string>

export interface ApplyMarginsRequest {
  currencyId: number
  spread: number
}

export interface UpdateExchangeRateSourceRequest {
  pollIntervalMinutes?: number
  active?: boolean
}

export interface ExchangeRatePollingMessage {
  message: string
}

export const exchangeRatePollingApi = {
  status: async (): Promise<ExchangeRatePollingStatus> => {
    const response = await api.get<ExchangeRatePollingStatus>('/rates/polling/status')
    return response.data
  },
  sources: async (): Promise<ExchangeRatePollingSource[]> => {
    const response = await api.get<ExchangeRatePollingSource[]>('/rates/polling/sources')
    return response.data
  },
  ecbRates: async (): Promise<EcbRateSnapshot> => {
    const response = await api.get<EcbRateSnapshot>('/rates/polling/ecb')
    return response.data
  },
  trigger: async (): Promise<ExchangeRatePollingMessage> => {
    const response = await api.post<ExchangeRatePollingMessage>('/rates/polling/trigger')
    return response.data
  },
  applyMargins: async (data: ApplyMarginsRequest): Promise<ExchangeRatePollingMessage> => {
    const response = await api.post<ExchangeRatePollingMessage>(
      '/rates/polling/apply-margins',
      data,
    )
    return response.data
  },
  updateSource: async (
    id: number,
    data: UpdateExchangeRateSourceRequest,
  ): Promise<ExchangeRatePollingSource> => {
    const response = await api.put<ExchangeRatePollingSource>(`/rates/polling/sources/${id}`, data)
    return response.data
  },
}

// ================== ROUNDING RULES API ==================

export type RoundingDirection = 'BUY' | 'SELL'

export interface RoundingRule {
  id?: number | null
  currencyCode: string
  precisionValue: number | string
  smallThreshold: number | string
  largeThreshold: number | string
  smallRounding: string
  largeRounding: string
}

export interface RoundingResult {
  original: number | string
  rounded: number | string
}

export const roundingRuleApi = {
  list: async (): Promise<RoundingRule[]> => {
    const response = await api.get<RoundingRule[]>('/rounding-rules')
    return response.data
  },
  getByCurrencyCode: async (currencyCode: string, amount: number): Promise<RoundingRule> => {
    const response = await api.get<RoundingRule>(`/rounding-rules/${currencyCode}`, {
      params: { amount },
    })
    return response.data
  },
  round: async (
    currencyCode: string,
    amount: number,
    direction: RoundingDirection,
  ): Promise<RoundingResult> => {
    const response = await api.post<RoundingResult>('/rounding-rules/round', null, {
      params: { currencyCode, amount, direction },
    })
    return response.data
  },
}

// ================== EXCHANGE RATE DISPLAY API ==================

export interface ExchangeRateDisplay {
  id: string
  displayName: string
  currencyIds: string
  refreshInterval: number
  isActive: boolean
  displayType?: string
  connectionType?: string
  comPort?: string
  baudRate?: number
  ipAddress?: string
  port?: number
  rowCount?: number
  columnCount?: number
  brightness?: number
  showBuyRate?: boolean
  showSellRate?: boolean
  showMiddleRate?: boolean
  showFlag?: boolean
}

export interface ExchangeRateDisplayRateRow {
  currencyId?: number
  currencyCode?: string
  currencyName?: string
  baseBuyRate?: number
  baseSellRate?: number
  buyRate?: string | number
  sellRate?: string | number
}

interface ExchangeRateDisplayCurrentRatesResponse {
  displayId: string
  displayName: string
  rates: ExchangeRateDisplayRateRow[]
  refreshInterval: number
  generatedAt: string
}

export interface ExchangeRateDisplayPreviewRow {
  currency: string
  buyRate: string
  sellRate: string
}

const formatDisplayRate = (value: string | number | undefined): string => {
  if (value == null || value === '') return '-'
  return typeof value === 'number' ? value.toFixed(2) : value
}

export const exchangeRateDisplayApi = {
  list: async (): Promise<ExchangeRateDisplay[]> => {
    const response = await api.get<ExchangeRateDisplay[]>('/exchange-rate-display')
    return response.data
  },
  getCurrentRates: async (displayId: string): Promise<ExchangeRateDisplayPreviewRow[]> => {
    const response = await api.get<ExchangeRateDisplayCurrentRatesResponse>(
      `/exchange-rate-display/${displayId}/current-rates`,
    )
    return (response.data.rates ?? []).map((rate) => ({
      currency: rate.currencyCode ?? rate.currencyName ?? String(rate.currencyId ?? '-'),
      buyRate: formatDisplayRate(rate.baseBuyRate ?? rate.buyRate),
      sellRate: formatDisplayRate(rate.baseSellRate ?? rate.sellRate),
    }))
  },
  updateDisplay: async (displayId: string, data: Partial<ExchangeRateDisplay>): Promise<void> => {
    await api.post(`/exchange-rate-display/${displayId}/update`, data)
  },
}
