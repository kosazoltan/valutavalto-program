import { api } from './client'

export interface ConfigBundleDto {
  branchId?: string
  branchCode?: string
  branchName?: string
  exportedAt?: string
  systemParams?: Record<string, string>
  rateSettings?: Array<{
    currencyCode?: string
    buyRate?: string
    sellRate?: string
    category?: string
  }>
  roundingRules?: Array<{
    currencyCode?: string
    precisionValue?: number
    smallThreshold?: string
    largeThreshold?: string
    smallRounding?: string
    largeRounding?: string
  }>
  printTemplates?: Array<{
    name?: string
    templateType?: string
    content?: string
    isDefault?: boolean
  }>
  ledConfig?: {
    displayType?: string
    content?: string
  }
}

export interface ConfigImportResultDto {
  success: boolean
  importedSystemParams: number
  importedRateSettings: number
  importedRoundingRules: number
  importedPrintTemplates: number
  ledConfigImported: boolean
  warnings?: string[]
  errors?: string[]
}

export const configExportApi = {
  exportBranch: async (branchId: string): Promise<ConfigBundleDto> =>
    (await api.get<ConfigBundleDto>(`/config/export/${branchId}`)).data,

  exportAll: async (): Promise<Record<string, ConfigBundleDto>> =>
    (await api.get<Record<string, ConfigBundleDto>>('/config/export-all')).data,

  importBranch: async (branchId: string, bundle: ConfigBundleDto): Promise<ConfigImportResultDto> =>
    (await api.post<ConfigImportResultDto>(`/config/import/${branchId}`, bundle)).data,
}
