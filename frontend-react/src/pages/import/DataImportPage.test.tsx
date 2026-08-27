import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DataImportPage from './DataImportPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  importBranch: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { branchId: 'branch-1' } }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
  },
  configExportApi: {
    importBranch: mocks.importBranch,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('DataImportPage config import', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockResolvedValue({ data: [] })
    mocks.apiPost.mockResolvedValue({ data: {} })
    mocks.importBranch.mockResolvedValue({
      success: true,
      importedSystemParams: 1,
      importedRateSettings: 2,
      importedRoundingRules: 3,
      importedPrintTemplates: 4,
      ledConfigImported: true,
      warnings: [],
      errors: [],
    })
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('a konfiguráció JSON importot a /config/import backend szerződésre köti', async () => {
    const user = userEvent.setup()
    render(<DataImportPage />)

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/data-import/history', {
        params: { branchId: 'branch-1' },
      })
    })

    const bundle = { branchId: 'source-branch', branchCode: 'SOURCE', systemParams: { A: '1' } }
    const file = new File([JSON.stringify(bundle)], 'config.json', { type: 'application/json' })
    await user.upload(screen.getByLabelText(/Config JSON import/i), file)

    await waitFor(() => {
      expect(mocks.importBranch).toHaveBeenCalledWith('branch-1', bundle)
      expect(screen.getByText('Import sikeres')).toBeInTheDocument()
    })
  })
})
