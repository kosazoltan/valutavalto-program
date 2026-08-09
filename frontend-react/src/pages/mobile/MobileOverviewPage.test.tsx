import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MobileOverviewPage from './MobileOverviewPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  getDetailedPosition: vi.fn(),
  exchangeRateList: vi.fn(),
  pendingApprovals: vi.fn(),
  approve: vi.fn(),
  shouldSync: vi.fn(),
  getErrorSummary: vi.fn(),
  branchDashboard: vi.fn(),
  branchOnline: vi.fn(),
  branchOffline: vi.fn(),
  customerSearch: vi.fn(),
  notificationGetUnread: vi.fn(),
  notificationUnreadCount: vi.fn(),
  notificationMarkAsRead: vi.fn(),
  notificationMarkAllAsRead: vi.fn(),
  posTerminalList: vi.fn(),
  posTerminalStatus: vi.fn(),
  rateApprovalPending: vi.fn(),
  rateApprovalHistory: vi.fn(),
  rateApprovalApprove: vi.fn(),
  rateApprovalReject: vi.fn(),
  documentScannerUploadScannedDocument: vi.fn(),
  documentScannerGetCustomerDocuments: vi.fn(),
  transferDocumentList: vi.fn(),
  transferDocumentPickup: vi.fn(),
  transferDocumentDeliver: vi.fn(),
  transferDocumentConfirm: vi.fn(),
  ertektarGetCollections: vi.fn(),
  ertektarGetDistributions: vi.fn(),
  ertektarGetBankTransactions: vi.fn(),
  ertektarUpdateCollectionStatus: vi.fn(),
  ertektarUpdateDistributionStatus: vi.fn(),
  ertektarUpdateBankTransactionStatus: vi.fn(),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { id: 77, branchId: 'branch-1', fullName: 'Vezető Teszt' } }),
}))

vi.mock('../../services/api/diagnostics', () => ({
  diagnosticsApi: {
    getErrorSummary: mocks.getErrorSummary,
  },
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
  },
  cashBalanceApi: {
    getDetailedPosition: mocks.getDetailedPosition,
  },
  exchangeRateApi: {
    list: mocks.exchangeRateList,
  },
  stornoApi: {
    pendingApprovals: mocks.pendingApprovals,
    approve: mocks.approve,
  },
  synchronizationApi: {
    shouldSync: mocks.shouldSync,
  },
  branchMonitoringApi: {
    dashboard: mocks.branchDashboard,
    online: mocks.branchOnline,
    offline: mocks.branchOffline,
  },
  customerApi: {
    search: mocks.customerSearch,
  },
  notificationApi: {
    getUnread: mocks.notificationGetUnread,
    unreadCount: mocks.notificationUnreadCount,
    markAsRead: mocks.notificationMarkAsRead,
    markAllAsRead: mocks.notificationMarkAllAsRead,
  },
  posTerminalApi: {
    list: mocks.posTerminalList,
    status: mocks.posTerminalStatus,
  },
  rateApprovalApi: {
    pending: mocks.rateApprovalPending,
    history: mocks.rateApprovalHistory,
    approve: mocks.rateApprovalApprove,
    reject: mocks.rateApprovalReject,
  },
  documentScannerApi: {
    uploadScannedDocument: mocks.documentScannerUploadScannedDocument,
    getCustomerDocuments: mocks.documentScannerGetCustomerDocuments,
  },
  transferDocumentApi: {
    list: mocks.transferDocumentList,
    pickup: mocks.transferDocumentPickup,
    deliver: mocks.transferDocumentDeliver,
    confirm: mocks.transferDocumentConfirm,
  },
  ertektarApi: {
    getCollections: mocks.ertektarGetCollections,
    getDistributions: mocks.ertektarGetDistributions,
    getBankTransactions: mocks.ertektarGetBankTransactions,
    updateCollectionStatus: mocks.ertektarUpdateCollectionStatus,
    updateDistributionStatus: mocks.ertektarUpdateDistributionStatus,
    updateBankTransactionStatus: mocks.ertektarUpdateBankTransactionStatus,
  },
}))

function renderPage() {
  render(
    <MemoryRouter>
      <MobileOverviewPage />
    </MemoryRouter>,
  )
}

describe('MobileOverviewPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    vi.clearAllMocks()
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    mocks.rateApprovalPending.mockResolvedValue([
      {
        id: 'rate-approval-1',
        branchId: 'branch-1',
        branchName: 'Szeged Értéktár',
        currencyCode: 'EUR',
        oldBuyRate: 390,
        oldSellRate: 399,
        newBuyRate: 392,
        newSellRate: 401,
        status: 'PENDING',
        requestedByName: 'Árfolyam Teszt',
        requestedAt: '2026-06-18T09:30:00',
        reason: 'Piaci korrekció',
      },
    ])
    mocks.rateApprovalHistory.mockResolvedValue([
      {
        id: 'rate-approval-history-1',
        branchId: 'branch-1',
        branchName: 'Szeged Értéktár',
        currencyCode: 'USD',
        oldBuyRate: 360,
        oldSellRate: 369,
        newBuyRate: 361,
        newSellRate: 370,
        status: 'APPROVED',
        requestedByName: 'Árfolyam Teszt',
        requestedAt: '2026-06-18T08:30:00',
      },
    ])
    mocks.rateApprovalApprove.mockResolvedValue({ id: 'rate-approval-1', status: 'APPROVED' })
    mocks.rateApprovalReject.mockResolvedValue({ id: 'rate-approval-1', status: 'REJECTED' })
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/dashboard/summary') {
        return Promise.resolve({
          data: {
            todayVolume: 12_500_000,
            activeBranches: 9,
            openTransactions: 47,
            alertCount: 2,
          },
        })
      }
      if (path === '/data-collection/status') {
        return Promise.resolve({
          data: [
            {
              id: 'dc-1',
              branchId: 'branch-online',
              collectionDate: '2026-06-18',
              status: 'COMPLETED',
              collectionType: 'DAILY',
              transactionCount: 12,
            },
          ],
        })
      }
      if (path === '/supervisor/params') {
        return Promise.resolve({
          data: [
            {
              id: 'param-1',
              key: 'SUPERVISOR_LIMIT',
              value: '100000',
              type: 'NUMBER',
              category: 'SUPERVISOR',
              description: 'Teszt limit',
              updatedAt: '2026-06-18T10:00:00',
            },
          ],
        })
      }
      if (path === '/sync/restore/status') {
        return Promise.resolve({
          data: {
            branchId: 'branch-1',
            totalTransactions: 128,
            earliestDate: '2026-01-01',
            latestDate: '2026-06-18',
            restoreAvailable: true,
          },
        })
      }
      if (path === '/year-opening/status') {
        return Promise.resolve({
          data: {
            lastExecutionYear: 2025,
            lastExecutionAt: '2026-01-01T00:00:00',
            canExecute: true,
            status: 'OK',
          },
        })
      }
      if (path === '/western-union/balance') {
        return Promise.resolve({
          data: [
            {
              id: 'wu-balance-1',
              branchId: 'branch-1',
              usdBalance: 1500,
              hufBalance: 540000,
              updatedAt: '2026-06-18T10:00:00',
            },
          ],
        })
      }
      if (path === '/western-union/daily-report') {
        return Promise.resolve({
          data: {
            date: '2026-06-18',
            sendCount: 2,
            receiveCount: 1,
            totalSendUsd: 400,
            totalReceiveUsd: 250,
            totalFees: 3500,
            stornoCount: 0,
          },
        })
      }
      if (path === '/reports/daily/submission-status') {
        return Promise.resolve({
          data: [
            {
              branchId: 'branch-online',
              branchCode: 'BUD01',
              branchName: 'Budapest 01',
              submitted: true,
              submittedAt: '2026-06-18T18:00:00',
            },
            {
              branchId: 'branch-offline',
              branchCode: 'SZEGED',
              branchName: 'Szeged Értéktár',
              submitted: false,
              submittedAt: null,
            },
          ],
        })
      }
      if (path === '/camera/status') {
        return Promise.resolve({
          data: [
            { cameraId: 'cam-1', cameraName: 'Pénztár kamera', recording: true, connected: true },
            { cameraId: 'cam-2', cameraName: 'Bejárat kamera', recording: false, connected: false },
          ],
        })
      }
      if (path === '/camera/admin/storage-stats') {
        return Promise.resolve({
          data: {
            totalUsageBytes: 1_073_741_824,
            availableSpaceBytes: 10_737_418_240,
            totalRecordings: 24,
            oldestDate: '2026-06-01',
            newestDate: '2026-06-18',
          },
        })
      }
      if (path === '/camera/admin/upload-status') {
        return Promise.resolve({ data: { pendingUploads: 2 } })
      }
      if (path === '/cash-register/devices') {
        return Promise.resolve({
          data: [
            {
              id: 'device-1',
              branchId: 'branch-1',
              code: 'PENZTAR-1',
              name: 'Pénztárgép 1',
              appMode: 'PENZTAR',
              appVersion: 'v2.28.11',
              lastSeenAt: new Date().toISOString(),
              isActive: true,
            },
          ],
        })
      }
      if (path === '/cash-register/events/branch-1') {
        return Promise.resolve({
          data: [
            {
              id: 'event-1',
              eventType: 'RECEIPT',
              status: 'OK',
              receiptNumber: 'NAV-1',
              occurredAt: '2026-06-18T10:00:00',
            },
          ],
        })
      }
      if (path === '/cash-register/receipt-gaps/branch-1') {
        return Promise.resolve({ data: ['Hiányzó sorszám: NAV-2'] })
      }
      if (path === '/nav/closings') {
        return Promise.resolve({
          data: {
            content: [
              {
                id: 'nav-closing-1',
                branchId: 'branch-1',
                closingDate: '2026-06-18',
                closingType: 'DAILY',
                totalRevenue: 1250000,
                totalExpense: 200000,
                status: 'OPEN',
              },
            ],
          },
        })
      }
      if (path === '/western-union-stub/rates') {
        return Promise.resolve({
          data: [
            {
              sourceCurrency: 'USD',
              targetCurrency: 'HUF',
              rate: 360.25,
              fee: 5,
            },
          ],
        })
      }
      if (path === '/western-union-stub/status/1234567890') {
        return Promise.resolve({
          data: {
            mtcn: '1234567890',
            status: 'AVAILABLE',
            message: 'Teszt WU státusz',
            amountUsd: 100,
            destinationCountry: 'HU',
          },
        })
      }
      return Promise.resolve({ data: null })
    })
    mocks.apiPost.mockResolvedValue({ data: { status: 'OK' } })
    mocks.posTerminalList.mockResolvedValue([
      {
        id: 'pos-1',
        terminalId: 'TERM-1',
        terminalName: 'OTP POS 1',
        branchId: 'branch-1',
        branchName: 'Budapest 01',
        isActive: true,
        lastTransactionAt: '2026-06-18T09:45:00',
      },
    ])
    mocks.posTerminalStatus.mockResolvedValue({
      terminalId: 'TERM-1',
      connected: true,
      active: true,
      reachable: true,
      terminalName: 'OTP POS 1',
      terminalType: 'OTP',
      lastTransactionAt: '2026-06-18T09:45:00',
      message: 'Elérhető',
    })
    mocks.getDetailedPosition.mockResolvedValue({
      branchId: 'branch-1',
      timestamp: '2026-06-18T10:00:00',
      items: [
        {
          currencyId: 1,
          currencyCode: 'EUR',
          currencyName: 'Euró',
          currentBalance: 500,
          openingBalance: 700,
          dailyChange: -200,
          buyRate: 390,
          sellRate: 399,
          midRate: 394.5,
          hufValue: 197250,
          openingHufValue: 276150,
          dailyChangeHuf: -78900,
          minBalance: 600,
          maxBalance: 4000,
          isLowBalance: true,
          isHighBalance: false,
          lastTransactionAt: '2026-06-18T09:45:00',
        },
      ],
      totalHufValue: 5_000_000,
      totalOpeningHufValue: 4_500_000,
      totalDailyChangeHuf: 500_000,
      currencyCount: 4,
      lowBalanceAlerts: 1,
      highBalanceAlerts: 0,
    })
    mocks.exchangeRateList.mockResolvedValue([
      {
        id: 1,
        currencyId: 1,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        validDate: '2026-06-18',
        validTime: '08:00',
        baseBuyRate: 390,
        baseSellRate: 399,
        officialRate: 394,
        active: true,
        createdAt: '2026-06-18T08:00:00',
      },
    ])
    mocks.pendingApprovals.mockResolvedValue([
      {
        id: 'approval-1',
        transactionId: 'tx-1',
        workerId: '12',
        branchId: 'branch-1',
        dailyStornoCount: 2,
        approvalStatusDid: 'pending',
        approvalStatusCode: 'PENDING',
        requestReason: 'Hibás bizonylat',
        workerName: 'Pénztáros Teszt',
        receiptNumber: 'V0001',
      },
    ])
    mocks.shouldSync.mockResolvedValue({ shouldSync: true, pendingCount: 3 })
    mocks.getErrorSummary.mockResolvedValue({
      totalAllTime: 15,
      last24h: 1,
      last7d: 4,
      last30d: 9,
      componentBreakdown7d: [],
      versionBreakdown7d: [],
      generatedAt: '2026-06-18T10:00:00',
    })
    mocks.branchDashboard.mockResolvedValue({
      'branch-online': {
        branchId: 'branch-online',
        lastHeartbeat: '2026-06-18T10:00:00',
        lastSync: '2026-06-18T09:59:00',
        isOnline: true,
        dailyTransactionCount: 12,
        dailyVolumeHuf: 1_200_000,
        openAlerts: 0,
      },
      'branch-offline': {
        branchId: 'branch-offline',
        lastHeartbeat: '2026-06-18T09:45:00',
        lastSync: '2026-06-18T09:40:00',
        isOnline: false,
        dailyTransactionCount: 3,
        dailyVolumeHuf: 250_000,
        openAlerts: 1,
      },
    })
    mocks.branchOnline.mockResolvedValue([
      {
        branchId: 'branch-online',
        isOnline: true,
        dailyTransactionCount: 12,
        dailyVolumeHuf: 1_200_000,
        openAlerts: 0,
      },
    ])
    mocks.branchOffline.mockResolvedValue([
      {
        branchId: 'branch-offline',
        lastHeartbeat: '2026-06-18T09:45:00',
        isOnline: false,
        dailyTransactionCount: 3,
        dailyVolumeHuf: 250_000,
        openAlerts: 1,
      },
    ])
    mocks.approve.mockResolvedValue({})
    mocks.customerSearch.mockResolvedValue([
      {
        id: 42,
        name: 'Teszt Elek',
        documentNumber: 'AB123456',
        active: true,
      },
    ])
    mocks.notificationGetUnread.mockResolvedValue([
      {
        id: 'notification-1',
        title: 'Mobil riasztás',
        message: 'Hiányzó napi jelentés',
        type: 'WARNING',
        isRead: false,
        createdAt: '2026-06-18T10:00:00',
      },
    ])
    mocks.notificationUnreadCount.mockResolvedValue(1)
    mocks.notificationMarkAsRead.mockResolvedValue({})
    mocks.notificationMarkAllAsRead.mockResolvedValue({})
    mocks.documentScannerUploadScannedDocument.mockResolvedValue({
      id: 'scan-new',
      customerId: 42,
      documentType: 'ID_CARD',
      fileName: 'id-card.jpg',
      mimeType: 'image/jpeg',
      fileSizeBytes: 12,
      scannedAt: '2026-06-18T10:05:00',
    })
    mocks.documentScannerGetCustomerDocuments.mockResolvedValue([
      {
        id: 'scan-1',
        customerId: 42,
        documentType: 'ID_CARD',
        fileName: 'id-card.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 12,
        scannedAt: '2026-06-18T10:05:00',
      },
    ])
    mocks.transferDocumentList.mockResolvedValue([
      {
        id: 101,
        documentNumber: 'ATD-101',
        sourceType: 'BRANCH',
        sourceId: 'SZEGED',
        destinationType: 'BRANCH',
        destinationId: 'BUD01',
        currencyCode: 'EUR',
        quantity: 500,
        status: 'PENDING',
        createdAt: '2026-06-18T10:00:00',
      },
      {
        id: 102,
        documentNumber: 'ATD-102',
        sourceType: 'BRANCH',
        sourceId: 'BUD01',
        destinationType: 'BRANCH',
        destinationId: 'SZEGED',
        currencyCode: 'HUF',
        quantity: 125000,
        status: 'PICKED_UP',
        createdAt: '2026-06-18T11:00:00',
      },
      {
        id: 103,
        documentNumber: 'ATD-103',
        sourceType: 'BRANCH',
        sourceId: 'BUD02',
        destinationType: 'BRANCH',
        destinationId: 'SZEGED',
        currencyCode: 'USD',
        quantity: 1000,
        status: 'DELIVERED',
        createdAt: '2026-06-18T12:00:00',
      },
    ])
    mocks.transferDocumentPickup.mockResolvedValue({})
    mocks.transferDocumentDeliver.mockResolvedValue({})
    mocks.transferDocumentConfirm.mockResolvedValue({})
    mocks.ertektarGetCollections.mockResolvedValue([
      {
        id: 11,
        sourceBranchCode: 'SZEGED',
        sourceBranchName: 'Szeged Értéktár',
        currencyCode: 'EUR',
        amount: 1200,
        status: 'REQUESTED',
      },
    ])
    mocks.ertektarGetDistributions.mockResolvedValue([
      {
        id: 12,
        status: 'IN_PROGRESS',
        note: 'Mobil szétosztás',
        lines: [
          {
            targetBranchCode: 'PECS',
            targetBranchName: 'Pécs',
            currencyCode: 'USD',
            amount: 300,
          },
        ],
      },
    ])
    mocks.ertektarGetBankTransactions.mockResolvedValue([
      {
        id: 13,
        transactionType: 'BUY',
        currencyCode: 'CHF',
        amount: 500,
        exchangeRate: 410,
        hufAmount: 205000,
        bankName: 'Raiffeisen',
        status: 'REQUESTED',
        createdAt: '2026-06-18T10:00:00',
      },
    ])
    mocks.ertektarUpdateCollectionStatus.mockResolvedValue({ id: 11, status: 'COMPLETED' })
    mocks.ertektarUpdateDistributionStatus.mockResolvedValue({ id: 12, status: 'REJECTED' })
    mocks.ertektarUpdateBankTransactionStatus.mockResolvedValue({ id: 13, status: 'IN_PROGRESS' })
  })

  it('a mobil felügyeleti panelekhez a meglévő backend API-kat hívja', async () => {
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Mobil felügyelet')).toBeInTheDocument()
      expect(screen.getAllByText('Pénztár').length).toBeGreaterThan(0)
      expect(screen.getByText('Mobil munkanézet')).toBeInTheDocument()
      expect(screen.getByText('Riasztás és státusz')).toBeInTheDocument()
      expect(screen.getAllByText('Jóváhagyás').length).toBeGreaterThan(0)
      expect(screen.getByText('Ügyfél és AML')).toBeInTheDocument()
      expect(screen.getByText('Terepi kontroll')).toBeInTheDocument()
      expect(screen.getAllByText('Kamera').length).toBeGreaterThan(0)
      expect(screen.getAllByText('Értéktár').length).toBeGreaterThan(0)
      expect(screen.getAllByText('Eszközök').length).toBeGreaterThan(0)
      expect(screen.getByText('Vezetői státusz')).toBeInTheDocument()
      expect(screen.getByText('Központi adatgyűjtés')).toBeInTheDocument()
      expect(screen.getByText('Irodai online állapot')).toBeInTheDocument()
      expect(screen.getByText('Pénztári mobil műveletek')).toBeInTheDocument()
      expect(screen.getByText('Értéktári és terepi mobil műveletek')).toBeInTheDocument()
      expect(screen.getByText('Compliance mobil műveletek')).toBeInTheDocument()
      expect(screen.getByText('Vezetői mobil műveletek')).toBeInTheDocument()
      expect(screen.getByText('Integrációs mobil státusz')).toBeInTheDocument()
      expect(screen.getByText('Üzemi kontroll')).toBeInTheDocument()
      expect(screen.getByText('Árfolyam jóváhagyások')).toBeInTheDocument()
    })

    expect(mocks.apiGet).toHaveBeenCalledWith('/dashboard/summary')
    expect(mocks.apiGet).toHaveBeenCalledWith('/data-collection/status')
    expect(mocks.apiGet).toHaveBeenCalledWith('/supervisor/params')
    expect(mocks.apiGet).toHaveBeenCalledWith('/sync/restore/status')
    expect(mocks.apiGet).toHaveBeenCalledWith('/year-opening/status')
    expect(mocks.apiGet).toHaveBeenCalledWith('/western-union/balance', {
      params: { branchId: 'branch-1' },
    })
    expect(mocks.apiGet).toHaveBeenCalledWith('/western-union/daily-report', {
      params: { branchId: 'branch-1', date: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/) },
    })
    expect(mocks.apiGet).toHaveBeenCalledWith('/reports/daily/submission-status', {
      params: { date: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/) },
    })
    expect(mocks.rateApprovalPending).toHaveBeenCalled()
    expect(mocks.rateApprovalHistory).toHaveBeenCalled()
    expect(mocks.apiGet).toHaveBeenCalledWith('/camera/status')
    expect(mocks.apiGet).toHaveBeenCalledWith('/camera/admin/storage-stats')
    expect(mocks.apiGet).toHaveBeenCalledWith('/camera/admin/upload-status')
    expect(mocks.posTerminalList).toHaveBeenCalled()
    expect(mocks.posTerminalStatus).toHaveBeenCalledWith('TERM-1')
    expect(mocks.apiGet).toHaveBeenCalledWith('/cash-register/devices')
    expect(mocks.apiGet).toHaveBeenCalledWith('/cash-register/events/branch-1', {
      params: { date: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/) },
    })
    expect(mocks.apiGet).toHaveBeenCalledWith('/cash-register/receipt-gaps/branch-1', {
      params: { date: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/) },
    })
    expect(mocks.apiGet).toHaveBeenCalledWith('/nav/closings', {
      params: {
        page: 0,
        size: 5,
        dateFrom: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
        dateTo: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
      },
    })
    expect(mocks.apiGet).toHaveBeenCalledWith('/western-union-stub/rates')
    expect(mocks.getDetailedPosition).toHaveBeenCalled()
    expect(mocks.exchangeRateList).toHaveBeenCalled()
    expect(mocks.pendingApprovals).toHaveBeenCalled()
    expect(mocks.shouldSync).toHaveBeenCalled()
    expect(mocks.getErrorSummary).toHaveBeenCalled()
    expect(mocks.branchDashboard).toHaveBeenCalled()
    expect(mocks.branchOnline).toHaveBeenCalled()
    expect(mocks.branchOffline).toHaveBeenCalledWith(5)
    expect(mocks.transferDocumentList).toHaveBeenCalled()
    expect(mocks.ertektarGetCollections).toHaveBeenCalled()
    expect(mocks.ertektarGetDistributions).toHaveBeenCalled()
    expect(mocks.ertektarGetBankTransactions).toHaveBeenCalled()
    expect(mocks.notificationGetUnread).toHaveBeenCalled()
    expect(mocks.notificationUnreadCount).toHaveBeenCalled()
    expect(screen.getByText('branch-offline')).toBeInTheDocument()
    expect(
      screen
        .getAllByRole('link', { name: /Új ügyfél/i })
        .some((link) => link.getAttribute('href') === '/customers/new'),
    ).toBe(true)
    expect(screen.getByRole('link', { name: /AML ellenőrzés/i })).toHaveAttribute(
      'href',
      '/compliance',
    )
    expect(screen.getByRole('link', { name: /Értéktári készlet/i })).toHaveAttribute(
      'href',
      '/inventory',
    )
    expect(screen.getByRole('link', { name: /Zárás beérkezés/i })).toHaveAttribute(
      'href',
      '/central/closing-control',
    )
    expect(screen.getByText('Restore tranzakció')).toBeInTheDocument()
    expect(screen.getByText('WU USD')).toBeInTheDocument()
    expect(screen.getByText('Napi jelentés')).toBeInTheDocument()
    expect(screen.getByText('Hiányzó jelentés')).toBeInTheDocument()
    expect(screen.getByText('SZEGED')).toBeInTheDocument()
    expect(screen.getByText('Függő árfolyam')).toBeInTheDocument()
    expect(screen.getByText('Piaci korrekció')).toBeInTheDocument()
    expect(screen.getByText('POS terminálok')).toBeInTheDocument()
  })

  it('a felsorolt telefonos használati pontokhoz külön mobil munkanézetet ad', async () => {
    const user = userEvent.setup()
    renderPage()

    const cashierArea = await screen.findByTestId('mobile-work-area-cashier')
    expect(within(cashierArea).getByRole('link', { name: /Vétel \/ eladás/i })).toHaveAttribute(
      'href',
      '/transactions/cashier',
    )
    // FK-078 FR-7: a régi, önálló „Címletezés" oldal megszűnt — mobil nézetből sem érhető el.
    expect(within(cashierArea).queryByRole('link', { name: /Címletezés/i })).toBeNull()
    expect(within(cashierArea).getByText('Pénztári készletfigyelő')).toBeInTheDocument()
    expect(within(cashierArea).getAllByText('EUR').length).toBeGreaterThan(0)
    expect(within(cashierArea).getByText('Alacsony')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /Terepi kontroll/i }))
    const fieldArea = await screen.findByTestId('mobile-work-area-field')
    expect(within(fieldArea).getByRole('link', { name: /Plomba/i })).toHaveAttribute(
      'href',
      '/seal-tracking',
    )
    expect(within(fieldArea).getByRole('link', { name: /Bizonylatok/i })).toHaveAttribute(
      'href',
      '/transfer-documents',
    )
    expect(within(fieldArea).getByText('Offline irodák')).toBeInTheDocument()
    expect(within(fieldArea).getByText('Mobil átadási bizonylatok')).toBeInTheDocument()
    expect(within(fieldArea).getByText('ATD-101')).toBeInTheDocument()

    const cameraUseCaseButton = screen.getAllByRole('button', { name: /Kamera/i })[0]
    if (!cameraUseCaseButton) throw new Error('Hiányzik a Kamera mobil használati pont')
    await user.click(cameraUseCaseButton)
    const cameraArea = await screen.findByTestId('mobile-work-area-camera')
    expect(within(cameraArea).getByText('Kamera mobil státusz')).toBeInTheDocument()
    expect(within(cameraArea).getByText('Pénztár kamera')).toBeInTheDocument()
    expect(within(cameraArea).getByText('Bejárat kamera')).toBeInTheDocument()
    expect(within(cameraArea).getByText('Offline')).toBeInTheDocument()
    expect(within(cameraArea).getByRole('link', { name: /Élő kép/i })).toHaveAttribute(
      'href',
      '/camera/live',
    )
    expect(within(cameraArea).getByRole('link', { name: /Státusz/i })).toHaveAttribute(
      'href',
      '/camera/status',
    )

    const vaultUseCaseButton = screen.getAllByRole('button', { name: /Értéktár/i })[0]
    if (!vaultUseCaseButton) throw new Error('Hiányzik az Értéktár mobil használati pont')
    await user.click(vaultUseCaseButton)
    const vaultArea = await screen.findByTestId('mobile-work-area-vault')
    expect(within(vaultArea).getByText('Értéktári mobil státusz')).toBeInTheDocument()
    expect(within(vaultArea).getByText('Begyűjtés #11')).toBeInTheDocument()
    expect(within(vaultArea).getByText('Szétosztás #12')).toBeInTheDocument()
    expect(within(vaultArea).getByText('Banki tétel #13')).toBeInTheDocument()
    expect(within(vaultArea).getByRole('link', { name: /Értéktári dashboard/i })).toHaveAttribute(
      'href',
      '/treasury',
    )

    const approvalUseCaseButton = screen.getAllByRole('button', { name: /Jóváhagyás/i })[0]
    if (!approvalUseCaseButton) throw new Error('Hiányzik a Jóváhagyás mobil használati pont')
    await user.click(approvalUseCaseButton)
    const approvalArea = await screen.findByTestId('mobile-work-area-approval')
    expect(within(approvalArea).getByRole('link', { name: /AML kontroll/i })).toHaveAttribute(
      'href',
      '/compliance',
    )
    expect(
      within(approvalArea).getByRole('button', { name: /Mobil engedélyezés/i }),
    ).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /Ügyfél és AML/i }))
    const customerArea = await screen.findByTestId('mobile-work-area-customer')
    expect(within(customerArea).getByPlaceholderText('Név vagy okmányszám...')).toBeInTheDocument()
    expect(within(customerArea).getByRole('link', { name: /Új ügyfél/i })).toHaveAttribute(
      'href',
      '/customers/new',
    )
    expect(within(customerArea).getByRole('link', { name: /Megkeresés/i })).toHaveAttribute(
      'href',
      '/police-requests',
    )
    expect(within(customerArea).getByText('Telefonos okmányfeltöltés')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /Riasztás és státusz/i }))
    const managementArea = await screen.findByTestId('mobile-work-area-management')
    expect(within(managementArea).getByRole('link', { name: /Irányító/i })).toHaveAttribute(
      'href',
      '/central-workstation',
    )
    expect(within(managementArea).getByText('Hiányzó jelentés')).toBeInTheDocument()
    expect(within(managementArea).getByText('Irodai sync gyorsműveletek')).toBeInTheDocument()
    expect(within(managementArea).getByRole('button', { name: /Teljes sync/i })).toBeInTheDocument()
    expect(within(managementArea).getByText('Évnyitás admin workflow')).toBeInTheDocument()
    expect(within(managementArea).getByText('Supervisor mobil felülbírálás')).toBeInTheDocument()
    expect(within(managementArea).getByText('Mobil értesítések')).toBeInTheDocument()

    const integrationsUseCaseButton = screen.getAllByRole('button', { name: /Eszközök/i })[0]
    if (!integrationsUseCaseButton) throw new Error('Hiányzik az Eszközök mobil használati pont')
    await user.click(integrationsUseCaseButton)
    const integrationsArea = await screen.findByTestId('mobile-work-area-integrations')
    expect(within(integrationsArea).getByText('POS mobil runtime')).toBeInTheDocument()
    expect(within(integrationsArea).getByText('OTP POS 1')).toBeInTheDocument()
    expect(within(integrationsArea).getByText('Pénztárgép mobil állapot')).toBeInTheDocument()
    expect(within(integrationsArea).getByText('Pénztárgép 1')).toBeInTheDocument()
    expect(within(integrationsArea).getByText('NAV zárás mobil lista')).toBeInTheDocument()
    expect(within(integrationsArea).getByText('WU adapter mobil státusz')).toBeInTheDocument()
    expect(within(integrationsArea).getByRole('link', { name: /POS terminálok/i })).toHaveAttribute(
      'href',
      '/pos-terminal',
    )
    expect(within(integrationsArea).getByRole('link', { name: /NAV integráció/i })).toHaveAttribute(
      'href',
      '/nav-integration',
    )
  })

  it('alsó mobil navigációval is vált a hét valós munkanézet között', async () => {
    const user = userEvent.setup()
    renderPage()

    const bottomNav = await screen.findByTestId('mobile-bottom-nav')
    expect(within(bottomNav).getByTestId('mobile-bottom-nav-cashier')).toHaveAttribute(
      'aria-current',
      'page',
    )

    await user.click(within(bottomNav).getByTestId('mobile-bottom-nav-field'))
    expect(await screen.findByTestId('mobile-work-area-field')).toBeInTheDocument()
    expect(within(bottomNav).getByTestId('mobile-bottom-nav-field')).toHaveAttribute(
      'aria-current',
      'page',
    )

    await user.click(within(bottomNav).getByTestId('mobile-bottom-nav-camera'))
    expect(await screen.findByTestId('mobile-work-area-camera')).toBeInTheDocument()

    await user.click(within(bottomNav).getByTestId('mobile-bottom-nav-vault'))
    expect(await screen.findByTestId('mobile-work-area-vault')).toBeInTheDocument()

    await user.click(within(bottomNav).getByTestId('mobile-bottom-nav-approval'))
    expect(await screen.findByTestId('mobile-work-area-approval')).toBeInTheDocument()

    await user.click(within(bottomNav).getByTestId('mobile-bottom-nav-customer'))
    expect(await screen.findByTestId('mobile-work-area-customer')).toBeInTheDocument()

    await user.click(within(bottomNav).getByTestId('mobile-bottom-nav-management'))
    expect(await screen.findByTestId('mobile-work-area-management')).toBeInTheDocument()

    await user.click(within(bottomNav).getByTestId('mobile-bottom-nav-integrations'))
    expect(await screen.findByTestId('mobile-work-area-integrations')).toBeInTheDocument()
  })

  it('mobil WU adapter státuszkeresést a backend MTCN szerződésre köti', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Eszközök/i }))
    const panel = await screen.findByTestId('mobile-work-area-integrations')
    await user.type(within(panel).getByLabelText('WU MTCN státusz'), '1234567890')
    await user.click(within(panel).getByRole('button', { name: /Státusz/i }))

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/western-union-stub/status/1234567890')
      expect(screen.getByText(/1234567890 - AVAILABLE/)).toBeInTheDocument()
    })
  })

  it('mobil vezetői nézetből indítja a branch sync backend szerződést', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Riasztás és státusz/i }))
    const panel = await screen.findByTestId('mobile-sync-actions-panel')
    await user.click(within(panel).getByRole('button', { name: /Teljes sync/i }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/sync/full/branch-1', null, {
        validateStatus: expect.any(Function),
      })
    })
  })

  it('mobil vezetői nézetből megerősítéssel meghívja az évnyitás execute backend szerződést', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Riasztás és státusz/i }))
    const panel = await screen.findByTestId('mobile-year-opening-panel')
    await user.clear(within(panel).getByLabelText('Cél év'))
    await user.type(within(panel).getByLabelText('Cél év'), '2027')
    await user.click(within(panel).getByRole('button', { name: /Futtatás/i }))

    await waitFor(() => {
      expect(window.confirm).toHaveBeenCalledWith(
        'Biztosan futtatod az évnyitást 2027 évre? Ez adminisztratív záró/nyitó workflow.',
      )
      expect(mocks.apiPost).toHaveBeenCalledWith('/year-opening/execute', null, {
        params: { targetYear: 2027 },
      })
    })
  })

  it('mobil supervisor felülbírálásból meghívja az authenticate, rate és fee backend szerződéseket', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Riasztás és státusz/i }))
    const panel = await screen.findByTestId('mobile-supervisor-override-panel')

    mocks.apiPost.mockResolvedValueOnce({ data: { authenticated: true } })
    await user.type(within(panel).getByLabelText('Supervisor jelszó'), 'titkos')
    await user.click(within(panel).getByRole('button', { name: /Supervisor ellenőrzés/i }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/supervisor/authenticate', { password: 'titkos' })
    })

    await user.clear(within(panel).getByLabelText('Iroda ID'))
    await user.type(
      within(panel).getByLabelText('Iroda ID'),
      '11111111-1111-1111-1111-111111111111',
    )
    await user.clear(within(panel).getByLabelText('Valuta'))
    await user.type(within(panel).getByLabelText('Valuta'), 'eur')
    await user.type(within(panel).getByLabelText('Vételi'), '395.5')
    await user.type(within(panel).getByLabelText('Eladási'), '401.25')
    await user.type(within(panel).getByLabelText('Indoklás'), 'Mobil piaci felülbírálás')
    await user.click(within(panel).getByRole('button', { name: /Árfolyam felülbírálás küldése/i }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/supervisor/override-rate', {
        branchId: '11111111-1111-1111-1111-111111111111',
        currency: 'EUR',
        newBuyRate: 395.5,
        newSellRate: 401.25,
        reason: 'Mobil piaci felülbírálás',
      })
    })

    await user.type(within(panel).getByLabelText('Tranzakció ID'), '987')
    await user.type(within(panel).getByLabelText('Új díj'), '750')
    await user.type(within(panel).getByLabelText('Díj indoklás'), 'Mobil díj korrekció')
    await user.click(within(panel).getByRole('button', { name: /Díj felülbírálás küldése/i }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/supervisor/override-fee', {
        transactionId: 987,
        newFee: 750,
        reason: 'Mobil díj korrekció',
      })
    })
    // Ez a teszt ~20 egymást követő userEvent interakciót + waitFor-t futtat; a teljes
    // (1769 teszt) suite párhuzamos terhelése alatt az 5000ms vitest-default kevés és flaky
    // timeoutot okoz (izoláltan stabilan zöld). Explicit, bővebb timeout a flaky ellen.
  }, 20000)

  it('mobil jóváhagyásból meghívja a sztornó approve backend szerződést', async () => {
    const user = userEvent.setup()
    renderPage()

    const approvalButtons = await screen.findAllByRole('button', { name: /Jóváhagyás/i })
    const approvalUseCaseButton = approvalButtons[0]
    if (!approvalUseCaseButton) throw new Error('Hiányzik a Jóváhagyás mobil használati pont')
    await user.click(approvalUseCaseButton)
    await user.click(await screen.findByRole('button', { name: /Mobil engedélyezés/i }))

    await waitFor(() => {
      expect(mocks.approve).toHaveBeenCalledWith('approval-1', true)
    })
  })

  it('mobil árfolyam jóváhagyásból meghívja az approve backend szerződést', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click((await screen.findAllByRole('button', { name: /Árfolyam engedélyezés/i }))[0]!)

    await waitFor(() => {
      expect(mocks.rateApprovalApprove).toHaveBeenCalledWith('rate-approval-1')
    })
  })

  it('mobil árfolyam jóváhagyásból meghívja a reject backend szerződést', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click((await screen.findAllByRole('button', { name: /Árfolyam elutasítás/i }))[0]!)

    await waitFor(() => {
      expect(mocks.rateApprovalReject).toHaveBeenCalledWith('rate-approval-1', 'Mobil elutasítás')
    })
  })

  it('mobil ügyfélkeresést backend keresésre köti', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Ügyfél és AML/i }))
    const input = await screen.findByPlaceholderText('Név vagy okmányszám...')
    await user.type(input, 'AB123456')
    await user.click(screen.getByRole('button', { name: 'Ügyfél keresése' }))

    await waitFor(() => {
      expect(mocks.customerSearch).toHaveBeenCalledWith('AB123456')
      expect(screen.getByText('Teszt Elek')).toBeInTheDocument()
    })
  })

  it('mobil okmányfeltöltést és ügyfél dokumentumlistát a scanned-documents backend szerződésre köti', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Ügyfél és AML/i }))
    const input = await screen.findByPlaceholderText('Név vagy okmányszám...')
    await user.type(input, 'AB123456')
    await user.click(screen.getByRole('button', { name: 'Ügyfél keresése' }))
    await user.click(await screen.findByRole('button', { name: 'Lista' }))

    await waitFor(() => {
      expect(mocks.documentScannerGetCustomerDocuments).toHaveBeenCalledWith(42)
      expect(screen.getByText('id-card.jpg')).toBeInTheDocument()
    })

    const file = new File(['mobil'], 'mobil-id.jpg', { type: 'image/jpeg' })
    await user.upload(screen.getByTestId('mobile-document-upload-input'), file)

    await waitFor(() => {
      expect(mocks.documentScannerUploadScannedDocument).toHaveBeenCalledWith(file, {
        customerId: 42,
        documentType: 'ID_CARD',
        notes: undefined,
      })
    })
  })

  it('mobil értesítésből olvasottként jelöl és tömeges olvasás backend szerződést hív', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Riasztás és státusz/i }))
    await screen.findByText('Mobil értesítések')
    await user.click(screen.getByRole('button', { name: 'Olvasott' }))

    await waitFor(() => {
      expect(mocks.notificationMarkAsRead).toHaveBeenCalledWith('notification-1')
    })

    await user.click(screen.getByRole('button', { name: /Mind olvasott/i }))

    await waitFor(() => {
      expect(mocks.notificationMarkAllAsRead).toHaveBeenCalled()
    })
  })

  it('mobil átadási bizonylatokból meghívja a terepi workflow backend szerződéseket', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Terepi kontroll/i }))

    await user.type(await screen.findByTestId('mobile-transfer-pin-101'), '1234')
    await user.click(await screen.findByTestId('mobile-transfer-pickup-101'))
    await user.click(await screen.findByTestId('mobile-transfer-deliver-102'))
    await user.click(await screen.findByTestId('mobile-transfer-confirm-103'))

    await waitFor(() => {
      expect(mocks.transferDocumentPickup).toHaveBeenCalledWith(101, 77, '1234')
      expect(mocks.transferDocumentDeliver).toHaveBeenCalledWith(102)
      expect(mocks.transferDocumentConfirm).toHaveBeenCalledWith(103, 77)
    })
  })

  it('mobil értéktári státusz nézetből meghívja a három PATCH backend szerződést', async () => {
    const user = userEvent.setup()
    renderPage()

    const vaultUseCaseButton = (await screen.findAllByRole('button', { name: /Értéktár/i }))[0]
    if (!vaultUseCaseButton) throw new Error('Hiányzik az Értéktár mobil használati pont')
    await user.click(vaultUseCaseButton)
    await screen.findByTestId('mobile-work-area-vault')
    await user.click(screen.getByRole('button', { name: 'Begyűjtés #11 mobil státusz COMPLETED' }))
    await user.click(screen.getByRole('button', { name: 'Szétosztás #12 mobil státusz REJECTED' }))
    await user.click(
      screen.getByRole('button', { name: 'Banki tétel #13 mobil státusz IN_PROGRESS' }),
    )

    await waitFor(() => {
      expect(mocks.ertektarUpdateCollectionStatus).toHaveBeenCalledWith(11, 'COMPLETED')
      expect(mocks.ertektarUpdateDistributionStatus).toHaveBeenCalledWith(12, 'REJECTED')
      expect(mocks.ertektarUpdateBankTransactionStatus).toHaveBeenCalledWith(13, 'IN_PROGRESS')
    })
  })
})
