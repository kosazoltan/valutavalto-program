import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ReceiptPage from './ReceiptPage'

const mocks = vi.hoisted(() => ({
  receiptList: vi.fn(),
  receiptGetById: vi.fn(),
  receiptPrint: vi.fn(),
  getPendingReceiptDrafts: vi.fn(),
  getReprintableReceiptDrafts: vi.fn(),
  printPendingReceiptDraft: vi.fn(),
  toastError: vi.fn(),
  toastSuccess: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  receiptApi: {
    list: mocks.receiptList,
    getById: mocks.receiptGetById,
    print: mocks.receiptPrint,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) => selector({
    worker: {
      id: 77,
      workerCode: 'ADMIN',
      firstName: 'Admin',
      lastName: 'Teszt',
      fullName: 'Admin Teszt',
      role: 'ADMIN',
      branchId: 'branch-1',
      branchCode: 'BUD01',
      branchName: 'Budapest 01',
      companyId: 'company-1',
      companyCode: 'EBC',
      companyName: 'Exclusive Best Change',
    },
  }),
}))

vi.mock('../../utils/electron', () => ({
  isElectron: () => false,
}))

vi.mock('../../utils/localQueue', async () => {
  const actual = await vi.importActual<typeof import('../../utils/localQueue')>('../../utils/localQueue')
  return {
    ...actual,
    getPendingReceiptDrafts: mocks.getPendingReceiptDrafts,
    getReprintableReceiptDrafts: mocks.getReprintableReceiptDrafts,
    printPendingReceiptDraft: mocks.printPendingReceiptDraft,
  }
})

vi.mock('../../components/electron/ReceiptPreviewModal', () => ({
  default: () => null,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    error: mocks.toastError,
    success: mocks.toastSuccess,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

const receiptFromList = {
  id: '11111111-1111-1111-1111-111111111111',
  receiptNumber: 'V001000001',
  receiptType: 'BUY',
  issueDate: '2026-06-19T08:00:00',
  isPrinted: false,
  customerName: 'Lista Ügyfél',
  hufAmount: 10000,
}

const receiptDetail = {
  ...receiptFromList,
  customerName: 'Backend Detail Ügyfél',
  content: 'backend-detail-content',
  hufAmount: 12000,
}

describe('ReceiptPage backend detail contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.receiptList.mockResolvedValue([receiptFromList])
    mocks.receiptGetById.mockResolvedValue(receiptDetail)
    mocks.receiptPrint.mockResolvedValue(undefined)
    mocks.getPendingReceiptDrafts.mockResolvedValue([])
    mocks.getReprintableReceiptDrafts.mockResolvedValue([])
  })

  it('a részletek gomb a GET /receipts/{id} backend wrapperre köt', async () => {
    render(<ReceiptPage />)

    await waitFor(() => {
      expect(mocks.receiptList).toHaveBeenCalled()
    })

    await userEvent.click(await screen.findByRole('button', { name: /Részletek/i }))

    await waitFor(() => {
      expect(mocks.receiptGetById).toHaveBeenCalledWith('11111111-1111-1111-1111-111111111111')
    })
    expect(await screen.findByText('backend-detail-content')).toBeInTheDocument()
    expect(screen.getByText(/Backend Detail Ügyfél/)).toBeInTheDocument()
  })
})
