import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ComplianceTransactionsPage from './ComplianceTransactionsPage'
import type { ComplianceTransactionRowDto } from '../../services/api/complianceTransactions'

const mocks = vi.hoisted(() => ({
  search: vi.fn(),
  exportCsv: vi.fn(),
  exportXlsx: vi.fn(),
  listBranches: vi.fn(),
  listCurrencies: vi.fn(),
  downloadBlob: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/complianceTransactions', () => ({
  complianceTransactionsApi: {
    search: mocks.search,
    exportCsv: mocks.exportCsv,
    exportXlsx: mocks.exportXlsx,
  },
  TRANSACTION_TYPE_LABELS: { BUY: 'Vétel', SELL: 'Eladás', REVERSAL: 'Sztornó' },
  PAYMENT_METHOD_LABELS: { CASH: 'Készpénz', CARD: 'Bankkártya' },
}))

vi.mock('../../services/api/settings', () => ({
  branchApi: { listActive: mocks.listBranches },
}))

vi.mock('../../services/api/exchange-rates', () => ({
  currencyApi: { list: mocks.listCurrencies },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: { success: mocks.toastSuccess, error: mocks.toastError },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: mocks.loggerError, warn: vi.fn() },
}))

vi.mock('../../utils/downloadBlob', () => ({
  downloadBlob: mocks.downloadBlob,
}))

const row = (over: Partial<ComplianceTransactionRowDto> = {}): ComplianceTransactionRowDto => ({
  id: 1,
  receiptNumber: 'B0001',
  transactionType: 'BUY',
  status: 'COMPLETED',
  transactionDate: '2026-07-01',
  transactionTime: '10:15:00',
  branchId: 'b-1',
  branchName: 'Teszt iroda',
  branchCode: '001',
  currencyId: 1,
  currencyCode: 'EUR',
  currencyAmount: '100.00',
  exchangeRate: '410.1234',
  hufAmount: '41010',
  paymentMethod: 'CASH',
  cashierCustomRate: false,
  kkDiscount: false,
  customerIsPep: true,
  customerOnOwnBehalf: true,
  amlSuspicious: false,
  customerId: 'C1',
  customerName: 'Teszt Elek',
  customerBirthDate: '1980-01-01',
  customerNationality: 'HU',
  customerDocumentNumber: 'AB123',
  isLegalEntityCustomer: false,
  legalEntityName: null,
  legalEntityTaxNumber: null,
  workerCode: 'W001',
  workerName: 'Dolgozó',
  originalReceiptNumber: null,
  ...over,
})

const paged = (
  content: ComplianceTransactionRowDto[],
  totalPages = 1,
  totalElements = content.length,
) => ({
  content,
  totalPages,
  totalElements,
  size: 50,
  number: 0,
})

beforeEach(() => {
  vi.clearAllMocks()
  mocks.listBranches.mockResolvedValue([{ id: 'b-1', code: '001', name: 'Teszt iroda' }])
  mocks.listCurrencies.mockResolvedValue([
    { id: 1, code: 'EUR', name: 'Euró', decimals: 2, active: true },
  ])
  mocks.search.mockResolvedValue(paged([row()]))
  mocks.exportCsv.mockResolvedValue(new Blob(['csv'], { type: 'text/csv' }))
  mocks.exportXlsx.mockResolvedValue(
    new Blob(['xlsx'], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    }),
  )
})

describe('ComplianceTransactionsPage', () => {
  it('mount: törzsadat betöltés, NINCS auto-keresés', async () => {
    render(<ComplianceTransactionsPage />)

    expect(screen.getByText('Állítsa be a szűrőket, majd indítsa a keresést.')).toBeInTheDocument()
    await waitFor(() => expect(mocks.listBranches).toHaveBeenCalledTimes(1))
    expect(mocks.listCurrencies).toHaveBeenCalledTimes(1)
    expect(mocks.search).not.toHaveBeenCalled()
  })

  it('keresés: criteria a kitöltött mezőkből, üresek kihagyva', async () => {
    const user = userEvent.setup()
    mocks.search.mockResolvedValue(paged([]))
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.type(screen.getByTestId('filter-endDate'), '2026-07-08')
    await user.click(screen.getByTestId('filter-pepOnly'))
    await user.click(screen.getByTestId('search-button'))

    await waitFor(() => {
      expect(mocks.search).toHaveBeenCalledWith(
        { startDate: '2026-07-01', endDate: '2026-07-08', pepOnly: true },
        0,
        50,
      )
    })
  })

  it('találat renderelés: HU címkék + formázott számok', async () => {
    const user = userEvent.setup()
    render(<ComplianceTransactionsPage />)

    await user.click(screen.getByTestId('search-button'))

    const resultRow = await screen.findByTestId('tx-row-1')
    expect(within(resultRow).getByText('Vétel')).toBeInTheDocument()
    expect(within(resultRow).getByText('Készpénz')).toBeInTheDocument()
    expect(within(resultRow).getByText('PEP')).toBeInTheDocument()
    expect(resultRow).toHaveTextContent(/41[\s\u00A0\u202F]010/)
    expect(resultRow).toHaveTextContent(/410,1234/)
  })

  it('keresési hiba: toast + logger message-dzsel', async () => {
    const user = userEvent.setup()
    mocks.search.mockRejectedValue(new Error('szerverhiba'))
    render(<ComplianceTransactionsPage />)

    await user.click(screen.getByTestId('search-button'))

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Keresési hiba', 'szerverhiba')
    })
    expect(mocks.loggerError).toHaveBeenCalledWith(
      'ComplianceTransactionsPage',
      'Keresés sikertelen:',
      'szerverhiba',
    )
  })

  it('lapozás: Következő az activeCriteria-val és page+1-gyel', async () => {
    const user = userEvent.setup()
    mocks.search.mockResolvedValue(paged([row()], 3, 120))
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.click(screen.getByTestId('search-button'))
    await waitFor(() => {
      expect(mocks.search).toHaveBeenCalledWith({ startDate: '2026-07-01' }, 0, 50)
    })
    expect(screen.getByTestId('prev-page')).toBeDisabled()

    await user.type(screen.getByTestId('filter-endDate'), '2026-07-08')
    await user.click(screen.getByTestId('next-page'))

    await waitFor(() => {
      expect(mocks.search).toHaveBeenLastCalledWith({ startDate: '2026-07-01' }, 1, 50)
    })
  })

  it('új keresés lapozás után: page visszaáll 0-ra', async () => {
    const user = userEvent.setup()
    mocks.search.mockResolvedValue(paged([row()], 3, 120))
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.click(screen.getByTestId('search-button'))
    await screen.findByTestId('tx-row-1')
    await user.click(screen.getByTestId('next-page'))
    await waitFor(() => {
      expect(mocks.search).toHaveBeenLastCalledWith({ startDate: '2026-07-01' }, 1, 50)
    })

    await user.type(screen.getByTestId('filter-customerName'), 'Teszt Elek')
    await user.click(screen.getByTestId('search-button'))

    await waitFor(() => {
      expect(mocks.search).toHaveBeenLastCalledWith(
        { startDate: '2026-07-01', customerName: 'Teszt Elek' },
        0,
        50,
      )
    })
  })

  it('export CSV: activeCriteria-val, downloadBlob hívva', async () => {
    const user = userEvent.setup()
    render(<ComplianceTransactionsPage />)

    expect(screen.getByTestId('export-csv')).toBeDisabled()
    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.click(screen.getByTestId('search-button'))
    await screen.findByTestId('tx-row-1')
    await user.type(screen.getByTestId('filter-endDate'), '2026-07-08')
    await user.click(screen.getByTestId('export-csv'))

    await waitFor(() => {
      expect(mocks.exportCsv).toHaveBeenCalledWith({ startDate: '2026-07-01' })
    })
    expect(mocks.downloadBlob).toHaveBeenCalledWith(
      expect.any(Blob),
      expect.stringMatching(/^compliance_tranzakciok_\d{4}-\d{2}-\d{2}\.csv$/),
      'text/csv;charset=utf-8',
    )
    expect(mocks.toastSuccess).toHaveBeenCalledWith('Export letöltve')
  })

  it('export hiba: toast, nincs downloadBlob', async () => {
    const user = userEvent.setup()
    mocks.exportCsv.mockRejectedValue(new Error('exporthiba'))
    render(<ComplianceTransactionsPage />)

    await user.click(screen.getByTestId('search-button'))
    await screen.findByTestId('tx-row-1')
    await user.click(screen.getByTestId('export-csv'))

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Export sikertelen', 'exporthiba')
    })
    expect(mocks.loggerError).toHaveBeenCalledWith(
      'ComplianceTransactionsPage',
      'Export sikertelen:',
      'exporthiba',
    )
    expect(mocks.downloadBlob).not.toHaveBeenCalled()
  })

  it('üres találat: Nincs a szűrőknek megfelelő tranzakció', async () => {
    const user = userEvent.setup()
    mocks.search.mockResolvedValue(paged([], 0, 0))
    render(<ComplianceTransactionsPage />)

    await user.click(screen.getByTestId('search-button'))

    expect(await screen.findByText('Nincs a szűrőknek megfelelő tranzakció.')).toBeInTheDocument()
  })

  it('szűrők törlése nem üríti az activeCriteria-t és a találatot', async () => {
    const user = userEvent.setup()
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.click(screen.getByTestId('search-button'))
    const resultRow = await screen.findByTestId('tx-row-1')
    expect(resultRow).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Szűrők törlése' }))

    expect(screen.getByTestId('filter-startDate')).toHaveValue('')
    expect(screen.getByTestId('tx-row-1')).toBeInTheDocument()
    expect(screen.getByTestId('export-csv')).toBeEnabled()
  })
})
