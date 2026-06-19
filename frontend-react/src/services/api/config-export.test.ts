import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('./client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

import { api } from './client'
import { configExportApi } from './config-export'

const mockApi = vi.mocked(api)

describe('configExportApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('telephely konfigurációt a backend export végpontról kér', async () => {
    const bundle = { branchId: 'branch-1', branchCode: 'SZEGED', systemParams: { A: '1' } }
    mockApi.get.mockResolvedValueOnce({ data: bundle })

    await expect(configExportApi.exportBranch('branch-1')).resolves.toBe(bundle)

    expect(mockApi.get).toHaveBeenCalledWith('/config/export/branch-1')
  })

  it('összes telephely konfigurációját a backend export-all végpontról kéri', async () => {
    const bundles = { 'branch-1': { branchId: 'branch-1', branchCode: 'SZEGED' } }
    mockApi.get.mockResolvedValueOnce({ data: bundles })

    await expect(configExportApi.exportAll()).resolves.toBe(bundles)

    expect(mockApi.get).toHaveBeenCalledWith('/config/export-all')
  })

  it('telephely konfiguráció importot a backend import végpontra küld', async () => {
    const bundle = { branchId: 'source-branch', branchCode: 'SOURCE' }
    const result = {
      success: true,
      importedSystemParams: 1,
      importedRateSettings: 2,
      importedRoundingRules: 3,
      importedPrintTemplates: 4,
      ledConfigImported: true,
      warnings: [],
      errors: [],
    }
    mockApi.post.mockResolvedValueOnce({ data: result })

    await expect(configExportApi.importBranch('target-branch', bundle)).resolves.toBe(result)

    expect(mockApi.post).toHaveBeenCalledWith('/config/import/target-branch', bundle)
  })
})
