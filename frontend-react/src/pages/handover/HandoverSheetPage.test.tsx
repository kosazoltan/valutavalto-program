import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import HandoverSheetPage from './HandoverSheetPage'

const mocks = vi.hoisted(() => ({
  handoverList: vi.fn(),
  handoverGetById: vi.fn(),
  handoverGenerate: vi.fn(),
  handoverPrint: vi.fn(),
  handoverComplete: vi.fn(),
  cashDeskList: vi.fn(),
  toast: {
    success: vi.fn(),
  },
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  handoverSheetApi: {
    list: mocks.handoverList,
    getById: mocks.handoverGetById,
    generate: mocks.handoverGenerate,
    print: mocks.handoverPrint,
    complete: mocks.handoverComplete,
  },
  cashDeskApi: {
    list: mocks.cashDeskList,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: () => false,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingHandoverOperation: vi.fn(),
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingHandoverOperations: vi.fn(),
  mapPendingHandoverGeneratesToSheets: vi.fn(() => []),
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

describe('HandoverSheetPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.handoverList.mockResolvedValue([
      {
        id: 'sheet-1',
        sheetNumber: 'HL-001',
        fromCashDeskId: 'cashdesk-1',
        fromCashDeskName: 'Lista küldő',
        toCashDeskId: 'cashdesk-2',
        toCashDeskName: 'Lista fogadó',
        transferDate: '2026-06-19',
        amounts: {},
        status: 'DRAFT',
      },
    ])
    mocks.handoverGetById.mockResolvedValue({
      id: 'sheet-1',
      sheetNumber: 'HL-001-DETAIL',
      fromCashDeskId: 'cashdesk-1',
      fromCashDeskName: 'Backend küldő',
      toCashDeskId: 'cashdesk-2',
      toCashDeskName: 'Backend fogadó',
      transferDate: '2026-06-20',
      amounts: { EUR: 100 },
      status: 'READY',
    })
    mocks.cashDeskList.mockResolvedValue([])
  })

  it('részletnyitáskor lekéri az átadó lap backend detail reprezentációját', async () => {
    render(<HandoverSheetPage />)

    await screen.findByText('HL-001')
    fireEvent.click(screen.getByRole('button', { name: /common.details/i }))

    await waitFor(() => {
      expect(mocks.handoverGetById).toHaveBeenCalledWith('sheet-1')
      expect(screen.getByText('HL-001-DETAIL')).toBeInTheDocument()
      expect(screen.getAllByText('Backend küldő').length).toBeGreaterThan(0)
      expect(screen.getAllByText('Backend fogadó').length).toBeGreaterThan(0)
      expect(screen.getByText('READY')).toBeInTheDocument()
    })
  })
})
