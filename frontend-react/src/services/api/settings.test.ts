import { beforeEach, describe, expect, it, vi } from 'vitest'
import { adminCompanyApi, branchApi, cameraExportApi, commissionCalculationApi, documentScannerApi, handlingFeeConfigApi, handlingFeeTransactionApi, mfaAdminApi, navIntegrationApi, notificationApi, ownCompanyApi, posTerminalApi, supervisorPinApi, systemParameterApi, turnoverApi, workerCommissionApi } from './settings'
import { api } from './client'

vi.mock('./client', () => {
  const mockApi = {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    defaults: { baseURL: '' },
    interceptors: {
      request: { use: vi.fn() },
      response: { use: vi.fn() },
    },
  }
  return { api: mockApi }
})

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
  put: ReturnType<typeof vi.fn>
  delete: ReturnType<typeof vi.fn>
}

describe('turnoverApi backend query contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: { ok: true } })
  })

  it('daily sends branchId and date', async () => {
    await turnoverApi.byPeriod('daily', 'branch-123', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/turnover/daily', {
      params: { branchId: 'branch-123', date: '2026-06-18' },
    })
  })

  it('weekly sends weekStart required by TurnoverController', async () => {
    await turnoverApi.byPeriod('weekly', 'branch-123', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/turnover/weekly', {
      params: { branchId: 'branch-123', weekStart: '2026-06-15' },
    })
  })

  it('monthly sends year and month required by TurnoverController', async () => {
    await turnoverApi.byPeriod('monthly', 'branch-123', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/turnover/monthly', {
      params: { branchId: 'branch-123', year: 2026, month: 6 },
    })
  })

  it('yearly sends year required by TurnoverController', async () => {
    await turnoverApi.byPeriod('yearly', 'branch-123', '2026-06-18')

    expect(mockApi.get).toHaveBeenCalledWith('/turnover/yearly', {
      params: { branchId: 'branch-123', year: 2026 },
    })
  })
})

describe('adminCompanyApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: { id: 'company-1' } })
  })

  it('getDetails calls CompanyAdminController company detail endpoint', async () => {
    await adminCompanyApi.getDetails('company-1')

    expect(mockApi.get).toHaveBeenCalledWith('/admin/companies/company-1')
  })

  it('updateCompany calls CompanyAdminController company update endpoint', async () => {
    await adminCompanyApi.updateCompany('company-1', {
      name: 'Exclusive Best Change Zrt.',
      taxNumber: '12345678-2-06',
      registrationNumber: '06-10-000001',
      address: 'Szeged',
      phone: '+361234567',
      email: 'info@example.test',
    })

    expect(mockApi.put).toHaveBeenCalledWith('/admin/companies/company-1', {
      name: 'Exclusive Best Change Zrt.',
      taxNumber: '12345678-2-06',
      registrationNumber: '06-10-000001',
      address: 'Szeged',
      phone: '+361234567',
      email: 'info@example.test',
    })
  })

})

describe('ownCompanyApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: { id: 'company-1' } })
  })

  it('getById calls OwnCompanyController ID detail endpoint', async () => {
    await ownCompanyApi.getById('company-1')

    expect(mockApi.get).toHaveBeenCalledWith('/own-companies/company-1')
  })
})

describe('branchApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: { id: 'branch-1', code: 'BR099', name: 'Teszt iroda' } })
    mockApi.post.mockResolvedValue({ data: { id: 'branch-1', code: 'BR099', name: 'Teszt iroda' } })
  })

  it('getByCode calls BranchController code lookup endpoint', async () => {
    await branchApi.getByCode('BR027')

    expect(mockApi.get).toHaveBeenCalledWith('/branches/code/BR027')
  })

  it('listRoots calls BranchController root branches endpoint', async () => {
    await branchApi.listRoots()

    expect(mockApi.get).toHaveBeenCalledWith('/branches/roots')
  })

  it('listVaultOnly calls BranchController vault-only endpoint with activeOnly', async () => {
    await branchApi.listVaultOnly(false)

    expect(mockApi.get).toHaveBeenCalledWith('/branches/vault-only', {
      params: { activeOnly: false },
    })
  })

  it('create calls full BranchController create endpoint', async () => {
    const payload = {
      code: 'BR099',
      companyId: '11111111-1111-1111-1111-111111111111',
      bankCode: 'BR099',
      branchTypeId: '22222222-2222-2222-2222-222222222222',
      name: 'Teszt iroda',
      address: '6720 Szeged, Teszt utca 1.',
      city: 'Szeged',
      zipCode: '6720',
      countryId: '33333333-3333-3333-3333-333333333333',
      branchStatusId: '44444444-4444-4444-4444-444444444444',
      openingDate: '2026-06-18',
      shortName: 'Teszt',
      hasAfa: true,
      hasWu: false,
      hasMg: false,
      hasPos: true,
      closedSaturday: false,
      closedSunday: true,
    }

    await branchApi.create(payload)

    expect(mockApi.post).toHaveBeenCalledWith('/branches', payload)
  })
})

describe('commissionCalculationApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: [] })
    mockApi.post.mockResolvedValue({ data: [] })
  })

  it('calculate calls POST /commissions/calculate with month and optional workerId', async () => {
    await commissionCalculationApi.calculate('2026-06', 77)

    expect(mockApi.post).toHaveBeenCalledWith('/commissions/calculate', null, {
      params: { month: '2026-06', workerId: 77 },
    })
  })

  it('calculateAll calls POST /commissions/calculate-all with month and optional branchId', async () => {
    await commissionCalculationApi.calculateAll('2026-06', 'branch-123')

    expect(mockApi.post).toHaveBeenCalledWith('/commissions/calculate-all', null, {
      params: { month: '2026-06', branchId: 'branch-123' },
    })
  })

  it('approve calls POST /commissions/{id}/approve', async () => {
    await commissionCalculationApi.approve('calc-1')

    expect(mockApi.post).toHaveBeenCalledWith('/commissions/calc-1/approve')
  })

  it('report calls GET /commissions/report with month', async () => {
    await commissionCalculationApi.report('2026-06')

    expect(mockApi.get).toHaveBeenCalledWith('/commissions/report', {
      params: { month: '2026-06' },
    })
  })
})

describe('workerCommissionApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: { id: '11111111-1111-1111-1111-111111111111' } })
  })

  it('getById calls WorkerCommissionController ID detail endpoint', async () => {
    await workerCommissionApi.getById('11111111-1111-1111-1111-111111111111')

    expect(mockApi.get).toHaveBeenCalledWith('/worker-commissions/11111111-1111-1111-1111-111111111111')
  })
})

describe('posTerminalApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: { terminalId: 'TERM-1', connected: true } })
  })

  it('status calls GET /pos-terminal-stub/status with terminalId', async () => {
    await posTerminalApi.status('TERM-1')

    expect(mockApi.get).toHaveBeenCalledWith('/pos-terminal-stub/status', {
      params: { terminalId: 'TERM-1' },
    })
  })
})

describe('documentScannerApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: { devices: [], mode: 'UPLOAD_BRIDGE', message: 'OK' } })
    mockApi.post.mockResolvedValue({ data: { id: 'scan-1' } })
  })

  it('devices calls GET /document-scanner/devices', async () => {
    await documentScannerApi.devices()

    expect(mockApi.get).toHaveBeenCalledWith('/document-scanner/devices')
  })

  it('scan calls POST /document-scanner/scan as multipart form-data', async () => {
    const file = new File(['scan'], 'okmany.pdf', { type: 'application/pdf' })

    await documentScannerApi.scan(file, { documentType: 'OTHER', notes: 'Teszt' })

    expect(mockApi.post).toHaveBeenCalledWith('/document-scanner/scan', expect.any(FormData), {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    const formData = mockApi.post.mock.calls[0]![1] as FormData
    expect(formData.get('file')).toBe(file)
    expect(formData.get('documentType')).toBe('OTHER')
    expect(formData.get('notes')).toBe('Teszt')
  })

  it('upload calls POST /document-scanner/upload as multipart form-data', async () => {
    const file = new File(['scan'], 'okmany.png', { type: 'image/png' })

    await documentScannerApi.upload(file, { documentType: 'ID_CARD', customerId: 12 })

    expect(mockApi.post).toHaveBeenCalledWith('/document-scanner/upload', expect.any(FormData), {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    const formData = mockApi.post.mock.calls[0]![1] as FormData
    expect(formData.get('file')).toBe(file)
    expect(formData.get('documentType')).toBe('ID_CARD')
    expect(formData.get('customerId')).toBe('12')
  })

  it('uploadScannedDocument calls POST /scanned-documents/upload as multipart form-data', async () => {
    const file = new File(['scan'], 'okmany.pdf', { type: 'application/pdf' })

    await documentScannerApi.uploadScannedDocument(file, { documentType: 'PASSPORT', transactionId: 34 })

    expect(mockApi.post).toHaveBeenCalledWith('/scanned-documents/upload', expect.any(FormData), {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    const formData = mockApi.post.mock.calls[0]![1] as FormData
    expect(formData.get('file')).toBe(file)
    expect(formData.get('documentType')).toBe('PASSPORT')
    expect(formData.get('transactionId')).toBe('34')
  })

  it('getCustomerDocuments calls GET /scanned-documents/customer/{customerId}', async () => {
    await documentScannerApi.getCustomerDocuments(12)

    expect(mockApi.get).toHaveBeenCalledWith('/scanned-documents/customer/12')
  })

  it('getTransactionDocuments calls GET /scanned-documents/transaction/{transactionId}', async () => {
    await documentScannerApi.getTransactionDocuments(34)

    expect(mockApi.get).toHaveBeenCalledWith('/scanned-documents/transaction/34')
  })

  it('deleteScannedDocument calls DELETE /scanned-documents/{id}', async () => {
    await documentScannerApi.deleteScannedDocument('scan-1')

    expect(mockApi.delete).toHaveBeenCalledWith('/scanned-documents/scan-1')
  })
})

describe('notificationApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('unreadCount reads the backend { count } response shape', async () => {
    mockApi.get.mockResolvedValue({ data: { count: 3 } })

    await expect(notificationApi.unreadCount()).resolves.toBe(3)
    expect(mockApi.get).toHaveBeenCalledWith('/notifications/unread-count')
  })

  it('send calls POST /notifications/send with workerId payload', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'notification-1' } })

    await notificationApi.send({
      workerId: 12,
      title: 'Teszt',
      message: 'Üzenet',
      type: 'INFO',
    })

    expect(mockApi.post).toHaveBeenCalledWith('/notifications/send', {
      workerId: 12,
      title: 'Teszt',
      message: 'Üzenet',
      type: 'INFO',
    })
  })

  it('markAsRead calls PUT /notifications/{id}/read canonical endpoint', async () => {
    mockApi.put.mockResolvedValue({ data: undefined })

    await notificationApi.markAsRead('notification-1')

    expect(mockApi.put).toHaveBeenCalledWith('/notifications/notification-1/read')
  })

  it('sendInApp calls POST /notifications with userId payload', async () => {
    mockApi.post.mockResolvedValue({ data: { id: 'notification-2' } })

    await notificationApi.sendInApp({
      userId: '12',
      title: 'Teszt',
      message: 'Üzenet',
      type: 'INFO',
    })

    expect(mockApi.post).toHaveBeenCalledWith('/notifications', {
      userId: '12',
      title: 'Teszt',
      message: 'Üzenet',
      type: 'INFO',
    })
  })
})

describe('supervisorPinApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('set calls POST /supervisor-pin/set with current password and pin', async () => {
    mockApi.post.mockResolvedValue({ data: { ok: true, message: 'PIN beállítva' } })

    const result = await supervisorPinApi.set('current-password', '1234')

    expect(mockApi.post).toHaveBeenCalledWith('/supervisor-pin/set', {
      currentPassword: 'current-password',
      pin: '1234',
    })
    expect(result.ok).toBe(true)
  })

  it('clear calls POST /supervisor-pin/clear with current password', async () => {
    mockApi.post.mockResolvedValue({ data: { ok: true, message: 'PIN törölve' } })

    const result = await supervisorPinApi.clear('current-password')

    expect(mockApi.post).toHaveBeenCalledWith('/supervisor-pin/clear', {
      currentPassword: 'current-password',
    })
    expect(result.ok).toBe(true)
  })
})

describe('mfaAdminApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('disable calls POST /mfa/admin/{workerId}/disable without body', async () => {
    mockApi.post.mockResolvedValue({ data: { workerId: 42, message: 'MFA letiltva' } })

    const result = await mfaAdminApi.disable(42)

    expect(mockApi.post).toHaveBeenCalledWith('/mfa/admin/42/disable')
    expect(result.workerId).toBe(42)
  })
})

describe('handlingFeeTransactionApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('calculate calls POST /handling-fees/calculate with transactionId and hufAmount', async () => {
    mockApi.post.mockResolvedValue({ data: { amount: 5000, netFee: 5000, feeType: 'TIERED' } })

    const result = await handlingFeeTransactionApi.calculate({ transactionId: 123, hufAmount: 750000 })

    expect(mockApi.post).toHaveBeenCalledWith('/handling-fees/calculate', {
      transactionId: 123,
      hufAmount: 750000,
    })
    expect(result.netFee).toBe(5000)
  })

  it('applyDiscount calls POST /handling-fees/{id}/discount with discountPercent and reason', async () => {
    const feeId = '11111111-1111-1111-1111-111111111111'
    mockApi.post.mockResolvedValue({ data: { amount: 5000, netFee: 4500, discountPercent: 10 } })

    const result = await handlingFeeTransactionApi.applyDiscount(feeId, {
      discountPercent: 10,
      reason: 'VIP',
    })

    expect(mockApi.post).toHaveBeenCalledWith(`/handling-fees/${feeId}/discount`, {
      discountPercent: 10,
      reason: 'VIP',
    })
    expect(result.netFee).toBe(4500)
  })
})

describe('handlingFeeConfigApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('saveBrackets calls POST /handling-fee-config/brackets with bracket list', async () => {
    const brackets = [
      { bracketOrder: 1, upperLimit: 100000, feeAmount: 500, active: true },
      { bracketOrder: 2, upperLimit: 500000, feeAmount: 1500, active: true },
    ]
    mockApi.post.mockResolvedValue({ data: brackets })

    const result = await handlingFeeConfigApi.saveBrackets(brackets)

    expect(mockApi.post).toHaveBeenCalledWith('/handling-fee-config/brackets', brackets)
    expect(result).toEqual(brackets)
  })
})

describe('cameraExportApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.post.mockResolvedValue({ data: { id: 'request-1' } })
  })

  it('approveSecond calls the dual approval endpoint', async () => {
    await cameraExportApi.approveSecond('request-1')

    expect(mockApi.post).toHaveBeenCalledWith('/camera/export/request-1/approve-second')
  })
})

describe('navIntegrationApi backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: 'REC-20260618' })
  })

  it('receiveReceiptNumber calls the NAV receipt number endpoint with COM port', async () => {
    const result = await navIntegrationApi.receiveReceiptNumber('COM3')

    expect(mockApi.get).toHaveBeenCalledWith('/nav-integration/receive-receipt-number', {
      params: { comPort: 'COM3' },
    })
    expect(result).toBe('REC-20260618')
  })
})

describe('systemParameterApi management backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockResolvedValue({ data: [] })
    mockApi.put.mockResolvedValue({ data: { parameterKey: 'RATE_SPREAD_EUR' } })
    mockApi.post.mockResolvedValue({ data: { updated: '2' } })
  })

  it('list calls GET /system-parameters canonical endpoint', async () => {
    await systemParameterApi.list()

    expect(mockApi.get).toHaveBeenCalledWith('/system-parameters')
  })

  it('listManaged calls GET /system-params management endpoint', async () => {
    await systemParameterApi.listManaged()

    expect(mockApi.get).toHaveBeenCalledWith('/system-params')
  })

  it('getByCategory calls GET /system-parameters/category/{category}', async () => {
    await systemParameterApi.getByCategory('RATE')

    expect(mockApi.get).toHaveBeenCalledWith('/system-parameters/category/RATE')
  })

  it('getManagedByCategory calls GET /system-params/category/{category}', async () => {
    await systemParameterApi.getManagedByCategory('RATE')

    expect(mockApi.get).toHaveBeenCalledWith('/system-params/category/RATE')
  })

  it('update calls PUT /system-parameters/{id}', async () => {
    await systemParameterApi.update('param-1', {
      parameterValue: '5',
      description: 'EUR spread',
    })

    expect(mockApi.put).toHaveBeenCalledWith('/system-parameters/param-1', {
      parameterValue: '5',
      description: 'EUR spread',
    })
  })

  it('updateByKey calls PUT /system-params/{key} with management body shape', async () => {
    await systemParameterApi.updateByKey('RATE_SPREAD_EUR', {
      value: '5',
      description: 'EUR spread',
    })

    expect(mockApi.put).toHaveBeenCalledWith('/system-params/RATE_SPREAD_EUR', {
      value: '5',
      description: 'EUR spread',
    })
  })

  it('bulkUpdate calls POST /system-params/bulk-update with parameters wrapper', async () => {
    await systemParameterApi.bulkUpdate({
      RATE_SPREAD_EUR: '5',
      RATE_SPREAD_USD: '4',
    })

    expect(mockApi.post).toHaveBeenCalledWith('/system-params/bulk-update', {
      parameters: {
        RATE_SPREAD_EUR: '5',
        RATE_SPREAD_USD: '4',
      },
    })
  })
})
