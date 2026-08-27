import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import BackupPage from './BackupPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  exportBranch: vi.fn(),
  exportAll: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { branchId: 'branch-1' } }),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
  },
  configExportApi: {
    exportBranch: mocks.exportBranch,
    exportAll: mocks.exportAll,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('BackupPage config export', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockResolvedValue({ data: [] })
    mocks.apiPost.mockResolvedValue({ data: {} })
    mocks.exportBranch.mockResolvedValue({ branchId: 'branch-1', branchCode: 'SZEGED' })
    mocks.exportAll.mockResolvedValue({
      'branch-1': { branchId: 'branch-1', branchCode: 'SZEGED' },
    })
    vi.spyOn(window.URL, 'createObjectURL').mockReturnValue('blob:config')
    vi.spyOn(window.URL, 'revokeObjectURL').mockImplementation(() => undefined)
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => undefined)
  })

  it('a telephelyi és összes konfiguráció exportot a /config backend szerződésre köti', async () => {
    const user = userEvent.setup()
    render(<BackupPage />)

    await waitFor(() => expect(mocks.apiGet).toHaveBeenCalledWith('/backup/history'))
    await user.click(screen.getByRole('button', { name: /Telephely config/i }))
    await user.click(screen.getByRole('button', { name: /Összes config/i }))

    await waitFor(() => {
      expect(mocks.exportBranch).toHaveBeenCalledWith('branch-1')
      expect(mocks.exportAll).toHaveBeenCalled()
    })
  })
})
