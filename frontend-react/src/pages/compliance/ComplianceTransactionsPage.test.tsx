import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ComplianceTransactionsPage from './ComplianceTransactionsPage'
import type { ComplianceTransactionRowDto } from '../../services/api/complianceTransactions'

const mocks = vi.hoisted(() => ({
  search: vi.fn(),
  exportCsv: vi.fn(),
  exportXlsx: vi.fn(),
  listTemplates: vi.fn(),
  createTemplate: vi.fn(),
  removeTemplate: vi.fn(),
  createAudit: vi.fn(),
  listAudit: vi.fn(),
  downloadAuditPdf: vi.fn(),
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
  complianceSearchTemplatesApi: {
    list: mocks.listTemplates,
    create: mocks.createTemplate,
    remove: mocks.removeTemplate,
  },
  complianceSearchAuditApi: {
    create: mocks.createAudit,
    list: mocks.listAudit,
    downloadPdf: mocks.downloadAuditPdf,
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
  mocks.listTemplates.mockResolvedValue([])
  mocks.createTemplate.mockResolvedValue({
    id: 'tpl-1',
    name: 'Havi PEP',
    criteria: { startDate: '2026-07-01', pepOnly: true },
    createdByWorkerCode: 'W001',
    createdAt: '2026-07-09T10:00:00',
  })
  mocks.removeTemplate.mockResolvedValue(undefined)
  mocks.createAudit.mockResolvedValue({
    id: 'aud-1',
    title: 'PEP keresés',
    description: 'Leírás',
    criteria: { pepOnly: true },
    resultCount: 1,
    createdByWorkerCode: 'W001',
    createdAt: '2026-07-09T10:00:00',
  })
  mocks.listAudit.mockResolvedValue([])
  mocks.downloadAuditPdf.mockResolvedValue(new Blob(['pdf'], { type: 'application/pdf' }))
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

  it('keresés: beneficialOwnerName mező megjelenik a criteria-ban', async () => {
    const user = userEvent.setup()
    mocks.search.mockResolvedValue(paged([]))
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-beneficialOwnerName'), 'Kovács Tulaj Béla')
    await user.click(screen.getByTestId('search-button'))

    await waitFor(() => {
      expect(mocks.search).toHaveBeenCalledWith({ beneficialOwnerName: 'Kovács Tulaj Béla' }, 0, 50)
    })
  })

  it('keresés: customerCountry és customerBirthName mező megjelenik a criteria-ban', async () => {
    const user = userEvent.setup()
    mocks.search.mockResolvedValue(paged([]))
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-customerCountry'), 'Irán')
    await user.type(screen.getByTestId('filter-customerBirthName'), 'Kovács Született Anna')
    await user.click(screen.getByTestId('search-button'))

    await waitFor(() => {
      expect(mocks.search).toHaveBeenCalledWith(
        { customerCountry: 'Irán', customerBirthName: 'Kovács Született Anna' },
        0,
        50,
      )
    })
  })

  it('keresés: relatedMinCount pozitív egész számként jelenik meg a criteria-ban', async () => {
    const user = userEvent.setup()
    mocks.search.mockResolvedValue(paged([]))
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-relatedMinCount'), '3')
    await user.click(screen.getByTestId('search-button'))

    await waitFor(() => {
      expect(mocks.search).toHaveBeenCalledWith({ relatedMinCount: 3 }, 0, 50)
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

  it('bukott keresés nem promótálja az activeCriteria-t', async () => {
    const user = userEvent.setup()
    mocks.search
      .mockResolvedValueOnce(paged([row()]))
      .mockRejectedValueOnce(new Error('keresés bukott'))
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.click(screen.getByTestId('search-button'))
    await waitFor(() => {
      expect(mocks.search).toHaveBeenCalledWith({ startDate: '2026-07-01' }, 0, 50)
    })

    await user.type(screen.getByTestId('filter-endDate'), '2026-07-08')
    await user.click(screen.getByTestId('search-button'))

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Keresési hiba', 'keresés bukott')
    })
    await user.click(screen.getByTestId('export-csv'))

    await waitFor(() => {
      expect(mocks.exportCsv).toHaveBeenCalledWith({ startDate: '2026-07-01' })
    })
  })

  it('első bukott keresés után az export disabled marad', async () => {
    const user = userEvent.setup()
    mocks.search.mockRejectedValueOnce(new Error('első hiba'))
    render(<ComplianceTransactionsPage />)

    expect(screen.getByTestId('export-csv')).toBeDisabled()
    expect(screen.getByTestId('save-audit')).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Sablon mentése' })).toBeDisabled()

    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.click(screen.getByTestId('search-button'))

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Keresési hiba', 'első hiba')
    })
    expect(screen.getByTestId('export-csv')).toBeDisabled()
    expect(screen.getByTestId('save-audit')).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Sablon mentése' })).toBeDisabled()
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

  it('export hiba: Blob-hibatestből olvasott üzenetet mutat', async () => {
    const user = userEvent.setup()
    mocks.exportCsv.mockRejectedValue({
      response: {
        data: new window.Blob([JSON.stringify({ message: 'Blob export üzenet' })], {
          type: 'application/json',
        }),
      },
    })
    render(<ComplianceTransactionsPage />)

    await user.click(screen.getByTestId('search-button'))
    await screen.findByTestId('tx-row-1')
    await user.click(screen.getByTestId('export-csv'))

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Export sikertelen', 'Blob export üzenet')
    })
    expect(mocks.loggerError).toHaveBeenCalledWith(
      'ComplianceTransactionsPage',
      'Export sikertelen:',
      'Blob export üzenet',
    )
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
    expect(await screen.findByTestId('tx-row-1')).toBeInTheDocument()
    expect(screen.getByTestId('export-csv')).toBeEnabled()
  })

  it('sablon mentése: aktív criteria-val POST', async () => {
    const user = userEvent.setup()
    render(<ComplianceTransactionsPage />)

    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.click(screen.getByTestId('filter-pepOnly'))
    await user.click(screen.getByTestId('search-button'))
    await waitFor(() => {
      expect(mocks.search).toHaveBeenCalledWith({ startDate: '2026-07-01', pepOnly: true }, 0, 50)
    })

    await user.click(screen.getByRole('button', { name: 'Sablon mentése' }))
    await user.type(screen.getByTestId('save-template'), 'Havi PEP')
    await user.click(screen.getByTestId('confirm-save-template'))

    await waitFor(() => {
      expect(mocks.createTemplate).toHaveBeenCalledWith('Havi PEP', {
        startDate: '2026-07-01',
        pepOnly: true,
      })
    })
    expect(mocks.toastSuccess).toHaveBeenCalledWith('Sablon mentve')
  })

  it('sablon betöltése: form feltöltődik, keresés NEM indul', async () => {
    const user = userEvent.setup()
    mocks.listTemplates.mockResolvedValue([
      {
        id: 'tpl-1',
        name: 'PEP sablon',
        criteria: {
          startDate: '2026-07-01',
          endDate: null,
          pepOnly: true,
          customRateOnly: false,
          customerName: null,
        },
        createdByWorkerCode: 'W001',
        createdAt: '2026-07-09T10:00:00',
      },
    ])
    render(<ComplianceTransactionsPage />)

    await screen.findByRole('option', { name: 'PEP sablon' })
    expect(mocks.search).not.toHaveBeenCalled()

    await user.selectOptions(screen.getByTestId('template-select'), 'tpl-1')

    expect(screen.getByTestId('filter-startDate')).toHaveValue('2026-07-01')
    expect(screen.getByTestId('filter-endDate')).toHaveValue('')
    expect(screen.getByTestId('filter-customerName')).toHaveValue('')
    expect(screen.getByTestId('filter-pepOnly')).toBeChecked()
    expect(screen.getByTestId('filter-customRateOnly')).not.toBeChecked()
    expect(mocks.search).not.toHaveBeenCalled()
  })

  it('sablon betöltése: a numerikus relatedMinCount string inputértékként töltődik vissza', async () => {
    const user = userEvent.setup()
    mocks.listTemplates.mockResolvedValue([
      {
        id: 'tpl-related',
        name: 'Összefüggő tranzakciók',
        criteria: { relatedMinCount: 5 },
        createdByWorkerCode: 'W001',
        createdAt: '2026-07-12T10:00:00',
      },
    ])
    render(<ComplianceTransactionsPage />)

    await screen.findByRole('option', { name: 'Összefüggő tranzakciók' })
    await user.selectOptions(screen.getByTestId('template-select'), 'tpl-related')

    expect(screen.getByTestId('filter-relatedMinCount')).toHaveValue(5)
    expect(mocks.search).not.toHaveBeenCalled()
  })

  it('sablon törlés: remove + reload', async () => {
    const user = userEvent.setup()
    mocks.listTemplates
      .mockResolvedValueOnce([
        {
          id: 'tpl-1',
          name: 'PEP sablon',
          criteria: { pepOnly: true },
          createdByWorkerCode: 'W001',
          createdAt: '2026-07-09T10:00:00',
        },
      ])
      .mockResolvedValueOnce([])
    render(<ComplianceTransactionsPage />)

    await screen.findByRole('option', { name: 'PEP sablon' })
    await user.selectOptions(screen.getByTestId('template-select'), 'tpl-1')
    await user.click(screen.getByTestId('delete-template'))

    await waitFor(() => expect(mocks.removeTemplate).toHaveBeenCalledWith('tpl-1'))
    expect(mocks.listTemplates).toHaveBeenCalledTimes(2)
  })

  it('audit-mentés: modal, cím kötelező, create a legutóbbi keresés criteria-jával', async () => {
    const user = userEvent.setup()
    render(<ComplianceTransactionsPage />)

    expect(screen.getByTestId('save-audit')).toBeDisabled()
    await user.type(screen.getByTestId('filter-startDate'), '2026-07-01')
    await user.click(screen.getByTestId('filter-pepOnly'))
    await user.click(screen.getByTestId('search-button'))
    await waitFor(() => {
      expect(mocks.search).toHaveBeenCalledWith({ startDate: '2026-07-01', pepOnly: true }, 0, 50)
    })

    await user.click(screen.getByTestId('save-audit'))
    expect(screen.getByRole('button', { name: 'Mentés' })).toBeDisabled()
    await user.type(screen.getByTestId('audit-title'), 'PEP keresés')
    await user.type(screen.getByTestId('audit-description'), 'Leírás')
    await user.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => {
      expect(mocks.createAudit).toHaveBeenCalledWith('PEP keresés', 'Leírás', {
        startDate: '2026-07-01',
        pepOnly: true,
      })
    })
    expect(mocks.toastSuccess).toHaveBeenCalledWith('Keresés mentve az audit naplóba')
  })

  it('audit-lista: kinyitásra tölt, criteria lenyitható HU címkékkel', async () => {
    const user = userEvent.setup()
    mocks.listAudit.mockResolvedValue([
      {
        id: 'aud-1',
        title: 'PEP keresés',
        description: 'Leírás',
        criteria: { pepOnly: true, type: 'BUY', currencyIds: [1] },
        resultCount: 3,
        createdByWorkerCode: 'W001',
        createdAt: '2026-07-09T10:00:00',
      },
    ])
    render(<ComplianceTransactionsPage />)

    await user.click(screen.getByTestId('toggle-audit-list'))
    expect(await screen.findByText('PEP keresés')).toBeInTheDocument()
    expect(mocks.listAudit).toHaveBeenCalledTimes(1)

    await user.click(screen.getByTestId('audit-criteria-aud-1'))

    expect(screen.getAllByText('Csak PEP').length).toBeGreaterThan(1)
    expect(screen.getByText('igen')).toBeInTheDocument()
    expect(screen.getAllByText('Típus').length).toBeGreaterThan(1)
    expect(screen.getAllByText('Vétel').length).toBeGreaterThan(1)
    expect(screen.getByText('EUR')).toBeInTheDocument()
  })

  it('audit PDF: downloadPdf + downloadBlob a fix fájlnévvel', async () => {
    const user = userEvent.setup()
    const pdf = new Blob(['pdf'], { type: 'application/pdf' })
    mocks.listAudit.mockResolvedValue([
      {
        id: 'aud-1',
        title: 'PEP keresés',
        description: null,
        criteria: { pepOnly: true },
        resultCount: 3,
        createdByWorkerCode: 'W001',
        createdAt: '2026-07-09T10:00:00',
      },
    ])
    mocks.downloadAuditPdf.mockResolvedValue(pdf)
    render(<ComplianceTransactionsPage />)

    await user.click(screen.getByTestId('toggle-audit-list'))
    await screen.findByText('PEP keresés')
    await user.click(screen.getByTestId('audit-pdf-aud-1'))

    await waitFor(() => expect(mocks.downloadAuditPdf).toHaveBeenCalledWith('aud-1'))
    expect(mocks.downloadBlob).toHaveBeenCalledWith(
      pdf,
      'compliance_kereses_audit_aud-1.pdf',
      'application/pdf',
    )
  })

  it('audit PDF hiba: Blob-hibatestből olvasott üzenetet mutat', async () => {
    const user = userEvent.setup()
    mocks.listAudit.mockResolvedValue([
      {
        id: 'aud-1',
        title: 'PEP keresés',
        description: null,
        criteria: { pepOnly: true },
        resultCount: 3,
        createdByWorkerCode: 'W001',
        createdAt: '2026-07-09T10:00:00',
      },
    ])
    mocks.downloadAuditPdf.mockRejectedValue({
      response: {
        data: new window.Blob([JSON.stringify({ message: 'Blob PDF üzenet' })], {
          type: 'application/json',
        }),
      },
    })
    render(<ComplianceTransactionsPage />)

    await user.click(screen.getByTestId('toggle-audit-list'))
    await screen.findByText('PEP keresés')
    await user.click(screen.getByTestId('audit-pdf-aud-1'))

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Audit PDF hiba', 'Blob PDF üzenet')
    })
    expect(mocks.loggerError).toHaveBeenCalledWith(
      'ComplianceTransactionsPage',
      'Audit PDF letöltése sikertelen:',
      'Blob PDF üzenet',
    )
  })
})
