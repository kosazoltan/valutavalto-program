import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TreasuryDashboard from './TreasuryDashboard'

const mocks = vi.hoisted(() => ({
  getDailyTurnover: vi.fn(),
  getCompanyBalances: vi.fn(),
  getCompanyPosition: vi.fn(),
  getCompanyTotals: vi.fn(),
  getLowAlerts: vi.fn(),
  getHighAlerts: vi.fn(),
  getHistory: vi.fn(),
  treasuryDashboard: vi.fn(),
  branchComparison: vi.fn(),
  submissionStatus: vi.fn(),
  bankFlow: vi.fn(),
  branchGroupSummary: vi.fn(),
  companySummary: vi.fn(),
  ertektarBranches: vi.fn(),
  ertektarConsolidatedReport: vi.fn(),
  getCollections: vi.fn(),
  createCollection: vi.fn(),
  getDistributions: vi.fn(),
  createDistribution: vi.fn(),
  getBankTransactions: vi.fn(),
  getTransfers: vi.fn(),
  getPendingTransfers: vi.fn(),
  createTransfer: vi.fn(),
  supervisorApproveTransfer: vi.fn(),
  completeTransfer: vi.fn(),
  rejectTransfer: vi.fn(),
  getReceipts: vi.fn(),
  getReceiptsByType: vi.fn(),
  createReceipt: vi.fn(),
  finalizeReceipt: vi.fn(),
  getCorrections: vi.fn(),
  getPendingCorrections: vi.fn(),
  createCorrection: vi.fn(),
  approveCorrection: vi.fn(),
  rejectCorrection: vi.fn(),
  updateCollectionStatus: vi.fn(),
  updateDistributionStatus: vi.fn(),
  updateBankTransactionStatus: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

vi.mock('../../services/api/index', () => ({
  transactionApi: {
    getDailyTurnover: mocks.getDailyTurnover,
  },
  cashBalanceApi: {
    getCompanyBalances: mocks.getCompanyBalances,
    getCompanyPosition: mocks.getCompanyPosition,
    getCompanyTotals: mocks.getCompanyTotals,
    getLowAlerts: mocks.getLowAlerts,
    getHighAlerts: mocks.getHighAlerts,
  },
  dailySessionApi: {
    getHistory: mocks.getHistory,
  },
  treasuryApi: {
    dashboard: mocks.treasuryDashboard,
    branchComparison: mocks.branchComparison,
    submissionStatus: mocks.submissionStatus,
    bankFlow: mocks.bankFlow,
    branchGroupSummary: mocks.branchGroupSummary,
    companySummary: mocks.companySummary,
    ertektarBranches: mocks.ertektarBranches,
    ertektarConsolidatedReport: mocks.ertektarConsolidatedReport,
  },
  ertektarApi: {
    getCollections: mocks.getCollections,
    createCollection: mocks.createCollection,
    getDistributions: mocks.getDistributions,
    createDistribution: mocks.createDistribution,
    getBankTransactions: mocks.getBankTransactions,
    getTransfers: mocks.getTransfers,
    getPendingTransfers: mocks.getPendingTransfers,
    createTransfer: mocks.createTransfer,
    supervisorApproveTransfer: mocks.supervisorApproveTransfer,
    completeTransfer: mocks.completeTransfer,
    rejectTransfer: mocks.rejectTransfer,
    getReceipts: mocks.getReceipts,
    getReceiptsByType: mocks.getReceiptsByType,
    createReceipt: mocks.createReceipt,
    finalizeReceipt: mocks.finalizeReceipt,
    getCorrections: mocks.getCorrections,
    getPendingCorrections: mocks.getPendingCorrections,
    createCorrection: mocks.createCorrection,
    approveCorrection: mocks.approveCorrection,
    rejectCorrection: mocks.rejectCorrection,
    updateCollectionStatus: mocks.updateCollectionStatus,
    updateDistributionStatus: mocks.updateDistributionStatus,
    updateBankTransactionStatus: mocks.updateBankTransactionStatus,
  },
}))

describe('TreasuryDashboard', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    mocks.getDailyTurnover.mockResolvedValue({
      totalBuyCount: 0,
      totalSellCount: 0,
      totalBuyHuf: 0,
      totalSellHuf: 0,
      totalHandlingFees: 0,
    })
    mocks.getCompanyBalances.mockResolvedValue([
      {
        id: 1,
        branchId: 'branch-1',
        branchName: 'Szeged',
        currencyId: 1,
        currencyCode: 'EUR',
        currentBalance: 100,
        openingBalance: 0,
        createdAt: '2026-06-18T08:00:00',
      },
      {
        id: 2,
        branchId: 'branch-1',
        branchName: 'Szeged',
        currencyId: 2,
        currencyCode: 'USD',
        currentBalance: 200,
        openingBalance: 0,
        createdAt: '2026-06-18T08:00:00',
      },
    ])
    mocks.getCompanyPosition.mockResolvedValue({
      companyId: 'company-1',
      timestamp: '2026-06-18T08:00:00',
      currencyPositions: [
        { currencyCode: 'EUR', totalBalance: 100, branchCount: 1, hufValue: 40000 },
        { currencyCode: 'USD', totalBalance: 200, branchCount: 1, hufValue: 1195000 },
      ],
      grandTotalHuf: 1235000,
    })
    mocks.getCompanyTotals.mockResolvedValue([
      { currencyId: 1, currencyCode: 'EUR', currencyName: 'Euró', totalBalance: 1000, branchCount: 2 },
      { currencyId: 2, currencyCode: 'USD', currencyName: 'Dollár', totalBalance: 500, branchCount: 1 },
    ])
    mocks.getLowAlerts.mockResolvedValue([
      {
        id: 3,
        branchId: 'branch-2',
        branchName: 'Pécs',
        currencyId: 1,
        currencyCode: 'EUR',
        currentBalance: 2,
        openingBalance: 0,
        createdAt: '2026-06-18T08:00:00',
      },
    ])
    mocks.getHighAlerts.mockResolvedValue([
      {
        id: 4,
        branchId: 'branch-1',
        branchName: 'Szeged',
        currencyId: 2,
        currencyCode: 'USD',
        currentBalance: 9999,
        openingBalance: 0,
        createdAt: '2026-06-18T08:00:00',
      },
    ])
    mocks.getHistory.mockResolvedValue([])
    mocks.treasuryDashboard.mockResolvedValue({
      totalBuyHuf: 100000,
      totalSellHuf: 200000,
      totalFeeHuf: 5000,
      totalProfit: 25000,
      totalTransactionCount: 17,
      branchCount: 2,
      currencyTotals: {},
    })
    mocks.branchComparison.mockResolvedValue([
      {
        branchId: 'branch-1',
        branchCode: 'SZEGED',
        branchName: 'Szeged',
        totalProfit: 25000,
        transactionCount: 17,
      },
    ])
    mocks.submissionStatus.mockResolvedValue([
      {
        branchId: 'branch-1',
        branchCode: 'SZEGED',
        branchName: 'Szeged',
        submitted: true,
        submittedAt: '2026-06-18T08:00:00',
      },
      {
        branchId: 'branch-2',
        branchCode: 'PECS',
        branchName: 'Pécs',
        submitted: false,
      },
    ])
    mocks.bankFlow.mockResolvedValue([
      {
        currencyCode: 'EUR',
        currencyName: 'Euró',
        totalWithdraw: 2000000,
        totalDeposit: 500000,
        netFlow: 1500000,
      },
    ])
    mocks.branchGroupSummary.mockResolvedValue([
      {
        id: 'group-1',
        code: 'DEL',
        name: 'Dél',
        totalProfit: 25000,
        transactionCount: 17,
        branchCount: 2,
      },
    ])
    mocks.companySummary.mockResolvedValue([
      {
        id: 'company-1',
        code: 'EBC',
        name: 'EBC',
        totalProfit: 50000,
        transactionCount: 30,
        branchCount: 2,
      },
    ])
    mocks.ertektarBranches.mockResolvedValue({
      'branch-1': {
        branchId: 'branch-1',
        isOnline: true,
        dailyTransactionCount: 12,
        dailyVolumeHuf: 1200000,
        openAlerts: 0,
      },
      'branch-2': {
        branchId: 'branch-2',
        isOnline: false,
        dailyTransactionCount: 3,
        dailyVolumeHuf: 250000,
        openAlerts: 1,
      },
    })
    mocks.ertektarConsolidatedReport.mockResolvedValue({
      dateFrom: '2026-06-01',
      dateTo: '2026-06-18',
      branches: [
        {
          branchCode: 'SZEGED',
          branchName: 'Szeged',
          totalTransactions: 17,
          totalHufTurnover: 1_700_000,
          totalFees: 25_000,
        },
      ],
      totals: {
        totalTransactions: 17,
        totalSellCount: 8,
        totalBuyCount: 9,
        totalHufTurnover: 1_700_000,
        totalFees: 25_000,
      },
    })
    mocks.getCollections.mockResolvedValue([
      {
        id: 11,
        sourceBranchCode: 'SZEGED',
        sourceBranchName: 'Szeged',
        currencyCode: 'EUR',
        amount: 1200,
        status: 'REQUESTED',
      },
    ])
    mocks.getDistributions.mockResolvedValue([
      {
        id: 12,
        status: 'IN_PROGRESS',
        lines: [{ targetBranchCode: 'PECS', targetBranchName: 'Pécs', currencyCode: 'USD', amount: 500 }],
      },
    ])
    mocks.getBankTransactions.mockResolvedValue([
      {
        id: 13,
        transactionType: 'BUY',
        currencyCode: 'CHF',
        amount: 300,
        exchangeRate: 410,
        hufAmount: 123000,
        bankName: 'Raiffeisen',
        status: 'REQUESTED',
        createdAt: '2026-06-18T08:00:00',
      },
    ])
    mocks.getTransfers.mockResolvedValue([
      {
        id: 21,
        transferNumber: 'ATT-2026-0001',
        currencyCode: 'EUR',
        amount: 1000,
        status: 'REQUESTED',
        requiresSupervisor: true,
        createdAt: '2026-06-18T08:00:00',
      },
      {
        id: 22,
        transferNumber: 'ATT-2026-0002',
        currencyCode: 'USD',
        amount: 500,
        status: 'IN_PROGRESS',
        requiresSupervisor: true,
        createdAt: '2026-06-18T09:00:00',
      },
    ])
    mocks.getPendingTransfers.mockResolvedValue([
      {
        id: 21,
        transferNumber: 'ATT-2026-0001',
        currencyCode: 'EUR',
        amount: 1000,
        status: 'REQUESTED',
        requiresSupervisor: true,
        createdAt: '2026-06-18T08:00:00',
      },
    ])
    mocks.getReceipts.mockResolvedValue([
      {
        id: 31,
        receiptNumber: 'BIZ-2026-0001',
        receiptType: 'B',
        status: 'DRAFT',
        createdAt: '2026-06-18T08:00:00',
        lines: [{ currencyCode: 'EUR', amount: 100 }],
      },
    ])
    mocks.getReceiptsByType.mockImplementation((type: string) => Promise.resolve(type === 'B'
      ? [
          {
            id: 31,
            receiptNumber: 'BIZ-2026-0001',
            receiptType: 'B',
            status: 'DRAFT',
            createdAt: '2026-06-18T08:00:00',
            lines: [{ currencyCode: 'EUR', amount: 100 }],
          },
        ]
      : []))
    mocks.getCorrections.mockResolvedValue([
      {
        id: 41,
        entityType: 'VAULT',
        entityId: 'SZEGED',
        currencyCode: 'CHF',
        oldQuantity: 10,
        newQuantity: 12,
        difference: 2,
        reason: 'Leltár eltérés',
        status: 'PENDING',
        createdAt: '2026-06-18T08:00:00',
      },
    ])
    mocks.getPendingCorrections.mockResolvedValue([
      {
        id: 41,
        entityType: 'VAULT',
        entityId: 'SZEGED',
        currencyCode: 'CHF',
        oldQuantity: 10,
        newQuantity: 12,
        difference: 2,
        reason: 'Leltár eltérés',
        status: 'PENDING',
        createdAt: '2026-06-18T08:00:00',
      },
    ])
    mocks.supervisorApproveTransfer.mockResolvedValue({ id: 21, status: 'IN_PROGRESS' })
    mocks.completeTransfer.mockResolvedValue({ id: 22, status: 'COMPLETED' })
    mocks.rejectTransfer.mockResolvedValue({ id: 21, status: 'REJECTED' })
    mocks.createTransfer.mockResolvedValue({ id: 23, status: 'REQUESTED' })
    mocks.createReceipt.mockResolvedValue({ id: 32, status: 'DRAFT' })
    mocks.finalizeReceipt.mockResolvedValue({ id: 31, status: 'FINALIZED' })
    mocks.createCorrection.mockResolvedValue({ id: 42, status: 'REQUESTED' })
    mocks.createCollection.mockResolvedValue({ id: 14, status: 'REQUESTED' })
    mocks.createDistribution.mockResolvedValue({ id: 15, status: 'REQUESTED' })
    mocks.approveCorrection.mockResolvedValue({ id: 41, status: 'APPROVED' })
    mocks.rejectCorrection.mockResolvedValue({ id: 41, status: 'REJECTED' })
    mocks.updateCollectionStatus.mockResolvedValue({ id: 11, status: 'COMPLETED' })
    mocks.updateDistributionStatus.mockResolvedValue({ id: 12, status: 'REJECTED' })
    mocks.updateBankTransactionStatus.mockResolvedValue({ id: 13, status: 'IN_PROGRESS' })
  })

  it('a teljes készletértéket a backend HUF-egyenértékes company-position válaszából mutatja', async () => {
    render(<TreasuryDashboard />)

    await waitFor(() => {
      expect(mocks.getCompanyPosition).toHaveBeenCalled()
    })

    const totalStockRow = screen.getByText('Készlet érték (összes)').closest('div')
    expect(totalStockRow).toHaveTextContent('1.2M Ft')
  })

  it('a dedikált treasury backend dashboard, fiók-összehasonlítás és beküldési státusz végpontokat is megjeleníti', async () => {
    render(<TreasuryDashboard />)

    await waitFor(() => {
      expect(mocks.treasuryDashboard).toHaveBeenCalled()
      expect(mocks.branchComparison).toHaveBeenCalled()
      expect(mocks.submissionStatus).toHaveBeenCalled()
      expect(mocks.bankFlow).toHaveBeenCalled()
      expect(mocks.branchGroupSummary).toHaveBeenCalled()
      expect(mocks.companySummary).toHaveBeenCalled()
      expect(mocks.ertektarBranches).toHaveBeenCalled()
      expect(mocks.ertektarConsolidatedReport).toHaveBeenCalled()
      expect(mocks.getCompanyTotals).toHaveBeenCalled()
      expect(mocks.getLowAlerts).toHaveBeenCalled()
      expect(mocks.getHighAlerts).toHaveBeenCalled()
      expect(mocks.getTransfers).toHaveBeenCalled()
      expect(mocks.getPendingTransfers).toHaveBeenCalled()
      expect(mocks.getReceipts).toHaveBeenCalled()
      expect(mocks.getReceiptsByType).toHaveBeenCalledWith('B')
      expect(mocks.getReceiptsByType).toHaveBeenCalledWith('K')
      expect(mocks.getCorrections).toHaveBeenCalled()
      expect(mocks.getPendingCorrections).toHaveBeenCalled()
    })

    expect(screen.getByText('Backend treasury összesítő')).toBeInTheDocument()
    expect(screen.getByText('Fiók összehasonlítás')).toBeInTheDocument()
    expect(screen.getByText('Beküldési státusz')).toBeInTheDocument()
    expect(screen.getByText('Bankflow összesítő')).toBeInTheDocument()
    expect(screen.getByText('Fiókcsoport összesítő')).toBeInTheDocument()
    expect(screen.getByText('Cégösszesítő')).toBeInTheDocument()
    expect(screen.getByText('Értéktári pénztár monitoring')).toBeInTheDocument()
    expect(screen.getByText('Értéktári konszolidált riport')).toBeInTheDocument()
    expect(screen.getByText('Készlet riasztások')).toBeInTheDocument()
    expect(screen.getByText('2 jelzés')).toBeInTheDocument()
    expect(screen.getByText('1 alacsony, 1 magas')).toBeInTheDocument()
    expect(screen.getByText('Valutánkénti készlet')).toBeInTheDocument()
    expect(screen.getByText('2 valuta')).toBeInTheDocument()
    expect(screen.getAllByText(/EUR\s+1\s*000/).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText('17 db').length).toBeGreaterThanOrEqual(2)
    expect(screen.getByText('1/2 online')).toBeInTheDocument()
    expect(screen.getByText('1 offline, 1 riasztás')).toBeInTheDocument()
    expect(screen.getByText('1.7M Ft / 1 iroda')).toBeInTheDocument()
    expect(screen.getByText('1 hiányzó jelentés')).toBeInTheDocument()
    expect(screen.getByText('EUR')).toBeInTheDocument()
    expect(screen.getByText('Dél')).toBeInTheDocument()
    expect(screen.getByText('50k Ft profit')).toBeInTheDocument()
    expect(screen.getByTestId('ertektar-status-control')).toHaveTextContent('Értéktári státusz kontroll')
    expect(screen.getByTestId('ertektar-readonly-ledger')).toHaveTextContent('Értéktári bizonylat és korrekció áttekintés')
    expect(screen.getByTestId('ertektar-readonly-ledger')).toHaveTextContent('ATT-2026-0001')
    expect(screen.getByTestId('ertektar-readonly-ledger')).toHaveTextContent('BIZ-2026-0001')
    expect(screen.getByTestId('ertektar-readonly-ledger')).toHaveTextContent('VAULT SZEGED')
    expect(screen.getByTestId('ertektar-readonly-ledger')).toHaveTextContent('1 függő / 1 összes')
    expect(screen.getByTestId('ertektar-readonly-ledger')).toHaveTextContent('1 bevét / 0 kiadás')
    expect(screen.getAllByText('Szeged').length).toBeGreaterThan(0)
    expect(screen.getByText('Pécs')).toBeInTheDocument()
    expect(screen.getByText('BUY CHF')).toBeInTheDocument()
  })

  it('az értéktári státusz kontrollból meghívja a collection/distribution/bank PATCH szerződéseket', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-status-control')

    await user.click(screen.getByRole('button', { name: 'Begyűjtés #11 státusz COMPLETED' }))
    await waitFor(() => {
      expect(mocks.updateCollectionStatus).toHaveBeenCalledWith(11, 'COMPLETED')
    })

    await user.click(screen.getByRole('button', { name: 'Szétosztás #12 státusz REJECTED' }))
    await waitFor(() => {
      expect(mocks.updateDistributionStatus).toHaveBeenCalledWith(12, 'REJECTED')
    })

    await user.click(screen.getByRole('button', { name: 'Banki tranzakció #13 státusz IN_PROGRESS' }))
    await waitFor(() => {
      expect(mocks.updateBankTransactionStatus).toHaveBeenCalledWith(13, 'IN_PROGRESS')
    })
  })

  it('a begyűjtési űrlapból createCollection backend szerződést hív', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-status-control')
    await user.type(screen.getByLabelText('Forrás iroda'), 'bud01')
    await user.type(screen.getByLabelText('Begyűjtés valuta'), 'eur')
    await user.type(screen.getByLabelText('Begyűjtés összeg'), '1200')
    await user.type(screen.getByLabelText('Begyűjtés megjegyzés'), 'Napi begyűjtés')
    await user.click(screen.getByRole('button', { name: 'Begyűjtés kérése' }))

    await waitFor(() => {
      expect(mocks.createCollection).toHaveBeenCalledWith({
        sourceBranchCode: 'bud01',
        currencyCode: 'EUR',
        amount: 1200,
        note: 'Napi begyűjtés',
      })
    })
  })

  it('a szétosztási űrlapból createDistribution backend szerződést hív', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-status-control')
    await user.type(screen.getByLabelText('Cél iroda'), 'pecs')
    await user.type(screen.getByLabelText('Szétosztás valuta'), 'usd')
    await user.type(screen.getByLabelText('Szétosztás összeg'), '500')
    await user.type(screen.getByLabelText('Szétosztás megjegyzés'), 'Napi szétosztás')
    await user.click(screen.getByRole('button', { name: 'Szétosztás kérése' }))

    await waitFor(() => {
      expect(mocks.createDistribution).toHaveBeenCalledWith({
        items: [{ targetBranchCode: 'pecs', currencyCode: 'USD', amount: 500 }],
        note: 'Napi szétosztás',
      })
    })
  })

  it('begyűjtés és szétosztás elutasított confirm esetén nem küld POST-ot', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-status-control')
    await user.type(screen.getByLabelText('Forrás iroda'), 'BUD01')
    await user.type(screen.getByLabelText('Begyűjtés valuta'), 'EUR')
    await user.type(screen.getByLabelText('Begyűjtés összeg'), '1200')
    await user.click(screen.getByRole('button', { name: 'Begyűjtés kérése' }))

    await user.type(screen.getByLabelText('Cél iroda'), 'PECS')
    await user.type(screen.getByLabelText('Szétosztás valuta'), 'USD')
    await user.type(screen.getByLabelText('Szétosztás összeg'), '500')
    await user.click(screen.getByRole('button', { name: 'Szétosztás kérése' }))

    expect(mocks.createCollection).not.toHaveBeenCalled()
    expect(mocks.createDistribution).not.toHaveBeenCalled()
  })

  it('az áttételek panelből meghívja a supervisor approve/complete/reject backend szerződéseket', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')

    await user.click(screen.getByRole('button', { name: 'Áttétel #21 supervisor jóváhagyás' }))
    await waitFor(() => {
      expect(mocks.supervisorApproveTransfer).toHaveBeenCalledWith(21)
    })

    await user.click(screen.getByRole('button', { name: 'Áttétel #22 végrehajtás' }))
    await waitFor(() => {
      expect(mocks.completeTransfer).toHaveBeenCalledWith(22)
    })

    await user.click(screen.getByRole('button', { name: 'Áttétel #21 elutasítás' }))
    await waitFor(() => {
      expect(mocks.rejectTransfer).toHaveBeenCalledWith(21)
    })
  })

  it('az áttételi űrlapból createTransfer backend szerződést hív', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.type(screen.getByLabelText('Áttétel forrás iroda'), 'bud01')
    await user.type(screen.getByLabelText('Áttétel cél iroda'), 'pecs')
    await user.type(screen.getByLabelText('Áttétel valuta'), 'eur')
    await user.type(screen.getByLabelText('Áttétel összeg'), '1000')
    await user.type(screen.getByLabelText('Áttétel megjegyzés'), 'Napi áttétel')
    await user.click(screen.getByRole('button', { name: 'Áttétel kérése' }))

    await waitFor(() => {
      expect(mocks.createTransfer).toHaveBeenCalledWith({
        sourceBranchCode: 'bud01',
        targetBranchCode: 'pecs',
        currencyCode: 'EUR',
        amount: 1000,
        note: 'Napi áttétel',
      })
    })
  })

  it('az anyagbizonylat űrlapból createReceipt backend szerződést hív', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.selectOptions(screen.getByLabelText('Bizonylat típus'), 'K')
    await user.type(screen.getByLabelText('Bizonylat iroda'), 'bud01')
    await user.type(screen.getByLabelText('Bizonylat valuta'), 'eur')
    await user.type(screen.getByLabelText('Bizonylat összeg'), '250')
    await user.type(screen.getByLabelText('Partner'), 'Minta Bank')
    await user.type(screen.getByLabelText('Bizonylat megjegyzés'), 'Banki kiadás')
    await user.click(screen.getByRole('button', { name: 'Anyagbizonylat kérése' }))

    await waitFor(() => {
      expect(mocks.createReceipt).toHaveBeenCalledWith({
        receiptType: 'K',
        branchCode: 'bud01',
        counterpartName: 'Minta Bank',
        note: 'Banki kiadás',
        lines: [{ currencyCode: 'EUR', amount: 250 }],
      })
    })
  })

  it('áttétel és anyagbizonylat létrehozás elutasított confirm esetén nem küld POST-ot', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.type(screen.getByLabelText('Áttétel forrás iroda'), 'BUD01')
    await user.type(screen.getByLabelText('Áttétel cél iroda'), 'PECS')
    await user.type(screen.getByLabelText('Áttétel valuta'), 'EUR')
    await user.type(screen.getByLabelText('Áttétel összeg'), '1000')
    await user.click(screen.getByRole('button', { name: 'Áttétel kérése' }))

    await user.type(screen.getByLabelText('Bizonylat iroda'), 'BUD01')
    await user.type(screen.getByLabelText('Bizonylat valuta'), 'EUR')
    await user.type(screen.getByLabelText('Bizonylat összeg'), '250')
    await user.click(screen.getByRole('button', { name: 'Anyagbizonylat kérése' }))

    expect(mocks.createTransfer).not.toHaveBeenCalled()
    expect(mocks.createReceipt).not.toHaveBeenCalled()
  })

  it('áttétel döntés elutasított confirm esetén nem küld POST-ot', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.click(screen.getByRole('button', { name: 'Áttétel #21 supervisor jóváhagyás' }))

    expect(mocks.supervisorApproveTransfer).not.toHaveBeenCalled()
    expect(mocks.completeTransfer).not.toHaveBeenCalled()
    expect(mocks.rejectTransfer).not.toHaveBeenCalled()
  })

  it('az anyagbizonylatok panelből meghívja a finalize backend szerződést', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.click(screen.getByRole('button', { name: 'Anyagbizonylat #31 véglegesítés' }))

    await waitFor(() => {
      expect(mocks.finalizeReceipt).toHaveBeenCalledWith(31)
    })
  })

  it('anyagbizonylat véglegesítés elutasított confirm esetén nem küld POST-ot', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.click(screen.getByRole('button', { name: 'Anyagbizonylat #31 véglegesítés' }))

    expect(mocks.finalizeReceipt).not.toHaveBeenCalled()
  })

  it('a készletkorrekció űrlapból createCorrection backend szerződést hív', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.clear(screen.getByLabelText('Azonosító'))
    await user.type(screen.getByLabelText('Azonosító'), 'bud01')
    await user.clear(screen.getByLabelText('Valuta'))
    await user.type(screen.getByLabelText('Valuta'), 'eur')
    await user.clear(screen.getByLabelText('Új mennyiség'))
    await user.type(screen.getByLabelText('Új mennyiség'), '125.5')
    await user.clear(screen.getByLabelText('Indok'))
    await user.type(screen.getByLabelText('Indok'), 'Leltár eltérés')
    await user.click(screen.getByRole('button', { name: 'Korrekció kérése' }))

    await waitFor(() => {
      expect(mocks.createCorrection).toHaveBeenCalledWith({
        entityType: 'VAULT',
        entityId: 'bud01',
        currencyCode: 'EUR',
        newQuantity: 125.5,
        reason: 'Leltár eltérés',
      })
    })
  })

  it('készletkorrekció létrehozás elutasított confirm esetén nem küld POST-ot', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.type(screen.getByLabelText('Azonosító'), 'BUD01')
    await user.type(screen.getByLabelText('Valuta'), 'EUR')
    await user.type(screen.getByLabelText('Új mennyiség'), '125')
    await user.type(screen.getByLabelText('Indok'), 'Leltár eltérés')
    await user.click(screen.getByRole('button', { name: 'Korrekció kérése' }))

    expect(mocks.createCorrection).not.toHaveBeenCalled()
  })

  it('a készletkorrekciók panelből meghívja az approve/reject backend szerződéseket', async () => {
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')

    await user.click(screen.getByRole('button', { name: 'Készletkorrekció #41 jóváhagyás' }))
    await waitFor(() => {
      expect(mocks.approveCorrection).toHaveBeenCalledWith(41)
    })

    await user.click(screen.getByRole('button', { name: 'Készletkorrekció #41 elutasítás' }))
    await waitFor(() => {
      expect(mocks.rejectCorrection).toHaveBeenCalledWith(41)
    })
  })

  it('készletkorrekció döntés elutasított confirm esetén nem küld POST-ot', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const user = userEvent.setup()
    render(<TreasuryDashboard />)

    await screen.findByTestId('ertektar-readonly-ledger')
    await user.click(screen.getByRole('button', { name: 'Készletkorrekció #41 jóváhagyás' }))

    expect(mocks.approveCorrection).not.toHaveBeenCalled()
    expect(mocks.rejectCorrection).not.toHaveBeenCalled()
  })
})
