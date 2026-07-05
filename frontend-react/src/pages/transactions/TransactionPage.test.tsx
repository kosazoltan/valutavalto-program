import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import TransactionPage from './TransactionPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  transactionApiBuy: vi.fn(),
  transactionApiSell: vi.fn(),
  toast: {
    success: vi.fn(),
    info: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
  saveAndSyncPendingBuySell: vi.fn(),
  apiPost: vi.fn(),
  electronQueueAvailable: false,
  identificationLevel: 'SIMPLE' as 'SIMPLE' | 'SIMPLIFIED' | 'FULL',
  minimumLevel: 'SIMPLE' as 'SIMPLE' | 'SIMPLIFIED' | 'FULL',
  requiresSourceVerification: false,
  setIdentificationLevel: vi.fn(),
  fullAmlCustomer: {
    name: 'Kiss János',
    documentType: 'ID_CARD',
    documentNumber: 'SZIG-123456',
    nationality: 'HU',
    birthPlace: 'Budapest',
    birthDate: '1980-01-02',
    motherName: 'Nagy Anna',
    address: '1111 Budapest, Teszt utca 1.',
    isPep: true,
    pepKind: 'KORMANYFO' as const,
    sourceOfFunds: 'SAVINGS',
    sourceOfFundsDocType: 'BANK_STATEMENT',
    sourceOfFundsDocDate: '2026-01-15',
    onOwnBehalf: false,
    actorName: 'Meghatalmazott Péter',
    actorIdentity: {
      birthPlace: 'Szeged',
      birthDate: '1975-03-04',
      motherName: 'Kovács Éva',
      nationality: 'HU',
      documentType: 'PASSPORT',
      documentNumber: 'P1234567',
      address: '6720 Szeged, Actor utca 2.',
    },
    isLegalEntity: true,
    legalEntityName: 'Teszt Kft.',
    legalEntitySeat: '1051 Budapest, Cég utca 3.',
    legalEntityTaxNumber: '12345678-2-41',
    legalDeedNumber: 'CÉG-2026/1',
    beneficialOwners: [{
      name: 'Tulajdonos Tímea',
      address: '9021 Győr, Owner utca 4.',
      birthPlace: 'Győr',
      birthDate: '1970-05-06',
      nationality: 'HU',
      residenceAbroad: 'N',
      interestNature: 'Tulajdonrész',
      interestExtent: '75%',
      isPep: true,
    }],
  },
}))

type CustomerPanelMockProps = {
  identificationLevel: 'SIMPLE' | 'SIMPLIFIED' | 'FULL'
  minimumLevel: 'SIMPLE' | 'SIMPLIFIED' | 'FULL'
  onLevelChange: (level: 'SIMPLE' | 'SIMPLIFIED' | 'FULL') => void
  requiresSourceVerification: boolean
  hufTotal: number
  onCustomerReady: (data: typeof mocks.fullAmlCustomer | null) => void
  onAmlResult?: (result: { blocked: boolean; warnings: string[] } | null) => void
}

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../../services/api/index', () => ({
  transactionApi: {
    buy: mocks.transactionApiBuy,
    sell: mocks.transactionApiSell,
  },
}))

vi.mock('../../services/api/client', () => ({
  api: {
    post: mocks.apiPost,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector?: (state: any) => unknown) => {
    const worker = {
      id: 7,
      workerCode: 'PENZTAR-7',
      firstName: 'Teszt',
      lastName: 'Pénztáros',
      fullName: 'Teszt Pénztáros',
      role: 'CASHIER',
      branchId: 'branch-1',
      branchCode: 'BUD-01',
      branchName: 'Budapest 01',
      companyId: 'company-1',
      companyCode: 'EBC',
      companyName: 'Exclusive Best Change Zrt.',
    }
    const state = { worker, user: worker }
    return typeof selector === 'function' ? selector(state) : state
  },
}))

vi.mock('../../components/auth/AmlApproverModal', () => ({
  default: (props: any) => props.open ? (
    <button
      type="button"
      data-testid="aml-approve"
      onClick={() => props.onApproved(42, 'Teszt Vezető')}
    >
      AML approve
    </button>
  ) : null,
  toApprovalCustomer: (c: any) => c,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/electronTransactions', () => ({
  saveAndSyncPendingBuySell: mocks.saveAndSyncPendingBuySell,
}))

vi.mock('./hooks/useTransactionRates', () => ({
  useTransactionRates: () => ({
    currencyRates: [
      { id: '1', code: 'EUR', name: 'Euró', buyRate: 391.50, sellRate: 398.50, unit: 1 },
      { id: '2', code: 'USD', name: 'US Dollár', buyRate: 358.20, sellRate: 365.80, unit: 1 },
    ],
    rawExchangeRates: [
      { currencyId: 1, currencyCode: 'EUR', currencyName: 'Euró', baseBuyRate: 391.50, baseSellRate: 398.50, active: true, officialRate: 395 },
      { currencyId: 2, currencyCode: 'USD', currencyName: 'US Dollár', baseBuyRate: 358.20, baseSellRate: 365.80, active: true, officialRate: 362 },
    ],
    electronQueueAvailable: mocks.electronQueueAvailable,
  }),
}))

vi.mock('./hooks/useIdentificationLevel', () => ({
  useIdentificationLevel: () => ({
    identificationLevel: mocks.identificationLevel,
    minimumLevel: mocks.minimumLevel,
    setIdentificationLevel: mocks.setIdentificationLevel,
    requiresSourceVerification: mocks.requiresSourceVerification,
  }),
}))

vi.mock('./components/CurrencySelector', () => ({
  default: ({ currencyRates, selectedCurrency, onSelect }: any) => (
    <div data-testid="currency-selector">
      {currencyRates.map((c: any) => (
        <button
          key={c.id}
          onClick={() => onSelect(c)}
          data-testid={`currency-${c.code}`}
          className={selectedCurrency?.code === c.code ? 'selected' : ''}
        >
          {c.code}
        </button>
      ))}
    </div>
  ),
}))

vi.mock('./components/CustomerPanel', () => ({
  default: ({
    identificationLevel,
    minimumLevel,
    onLevelChange,
    requiresSourceVerification,
    hufTotal,
    onCustomerReady,
    onAmlResult,
  }: CustomerPanelMockProps) => (
    <div
      data-testid="customer-panel"
      data-level={identificationLevel}
      data-min-level={minimumLevel}
      data-source-verification={String(requiresSourceVerification)}
      data-huf-total={String(hufTotal)}
    >
      <button type="button" data-testid="level-full" onClick={() => onLevelChange('FULL')} />
      <button type="button" data-testid="fill-customer" onClick={() => onCustomerReady(mocks.fullAmlCustomer)} />
      <button type="button" data-testid="clear-customer" onClick={() => onCustomerReady(null)} />
      <button type="button" data-testid="aml-block" onClick={() => onAmlResult?.({ blocked: true, warnings: [] })} />
      <button
        type="button"
        data-testid="aml-block-submit"
        onClick={() => {
          onAmlResult?.({ blocked: true, warnings: [] })
          document.querySelector<HTMLButtonElement>('[data-testid="tx-save-print"]')?.click()
        }}
      />
    </div>
  ),
}))

function renderTransactionPage() {
  render(
    <MemoryRouter>
      <TransactionPage />
    </MemoryRouter>,
  )
}

async function enterForeignAmount(user: ReturnType<typeof userEvent.setup>, amount: string) {
  const inputs = screen.getAllByPlaceholderText('0,00')
  await user.clear(inputs[0]!)
  await user.type(inputs[0]!, amount)
}

async function fillAmlCustomer(user: ReturnType<typeof userEvent.setup>) {
  await user.click(screen.getByTestId('fill-customer'))
}

function firstBuyPayload(): Record<string, unknown> {
  return mocks.transactionApiBuy.mock.calls[0]?.[0] as Record<string, unknown>
}

function firstSellPayload(): Record<string, unknown> {
  return mocks.transactionApiSell.mock.calls[0]?.[0] as Record<string, unknown>
}

describe('TransactionPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.identificationLevel = 'SIMPLE'
    mocks.minimumLevel = 'SIMPLE'
    mocks.requiresSourceVerification = false
    mocks.electronQueueAvailable = false
    mocks.apiPost.mockResolvedValue({ data: { requiresApproval: false } })
  })

  it('oldal renderelésének ellenőrzése', () => {
    renderTransactionPage()
    expect(screen.getByText('Új tranzakció')).toBeInTheDocument()
  })

  it('modern CustomerPanel renderel az azonosítási propokkal', () => {
    mocks.identificationLevel = 'FULL'
    mocks.minimumLevel = 'SIMPLIFIED'
    mocks.requiresSourceVerification = true

    renderTransactionPage()

    const panel = screen.getByTestId('customer-panel')
    expect(panel).toHaveAttribute('data-level', 'FULL')
    expect(panel).toHaveAttribute('data-min-level', 'SIMPLIFIED')
    expect(panel).toHaveAttribute('data-source-verification', 'true')
    expect(screen.getByTestId('level-full')).toBeInTheDocument()
  })

  it('deviza választó és tranzakció típus gombok megjelenése', () => {
    renderTransactionPage()
    expect(screen.getByTestId('currency-selector')).toBeInTheDocument()
    expect(screen.getByText(/VÉTEL/)).toBeInTheDocument()
    expect(screen.getByText(/ELADÁS/)).toBeInTheDocument()
  })

  it('elsőre megjelenítés: EUR kiválasztva', () => {
    renderTransactionPage()
    const eurButton = screen.getByTestId('currency-EUR')
    expect(eurButton).toHaveClass('selected')
  })

  it('számadatok input mezőket megjelenít', () => {
    renderTransactionPage()
    expect(screen.getByText(/EUR összeg/)).toBeInTheDocument()
    expect(screen.getByText(/HUF összeg/)).toBeInTheDocument()
  })

  it('deviza választás módosítja az árfolyamot', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const usdButton = screen.getByTestId('currency-USD')
    await user.click(usdButton)

    // Component updates to show USD exchange rate
    expect(usdButton).toHaveClass('selected')
  })

  it('deviza összeg megadásakor HUF automatikusan kiszámítódik', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const inputs = screen.getAllByPlaceholderText('0,00')
    const foreignInput = inputs[0]!

    await user.clear(foreignInput)
    await user.type(foreignInput, '100')

    // EUR * 100 * 391.50 = 39150
    await waitFor(() => {
      const hufInputs = screen.getAllByPlaceholderText('0,00')
      expect(hufInputs[1]).toHaveValue('39150')
    })
  })

  it('HUF összeg megadásakor deviza automatikusan kiszámítódik', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const inputs = screen.getAllByPlaceholderText('0,00')
    const foreignInput = inputs[0] as HTMLInputElement
    const hufInput = inputs[1] as HTMLInputElement

    await user.clear(hufInput)
    await user.type(hufInput, '1000')

    await waitFor(() => {
      expect(hufInput).toHaveValue('1000')
      expect(foreignInput).toHaveValue('2,55')
    })
  })

  it('Mégsem gomb navigál vissza', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const cancelButton = screen.getByText('Mégse')
    await user.click(cancelButton)

    expect(mocks.navigate).toHaveBeenCalledWith('/transactions')
  })

  it('Mentés és nyomtatás gomb összeg nélkül figyelmeztető toast-ot mutat', async () => {
    renderTransactionPage()
    const user = userEvent.setup()

    const saveButton = screen.getByTestId('tx-save-print')
    // Összeg nélkül → toast warning
    await user.click(saveButton)

    // Toast warning hívás ellenőrzés
    expect(mocks.toast.warning).toHaveBeenCalledWith(
      'Érvénytelen összeg',
      'Kérem adjon meg érvényes összeget!',
    )
  })

  it('FULL azonosításnál ügyféladat nélkül nem indít mentést', async () => {
    mocks.identificationLevel = 'FULL'
    mocks.minimumLevel = 'FULL'
    const user = userEvent.setup()

    renderTransactionPage()
    await enterForeignAmount(user, '100')

    await user.click(screen.getByTestId('tx-save-print'))

    expect(mocks.toast.warning).toHaveBeenCalledWith(
      'Ügyfél azonosítás kötelező',
      '100.000 Ft feletti tranzakcióhoz ügyfél azonosítás KÖTELEZŐ!',
    )
    expect(mocks.transactionApiBuy).not.toHaveBeenCalled()
    expect(mocks.transactionApiSell).not.toHaveBeenCalled()
  })

  it('blokkolt AML eredménnyel tiltja a mentés gombot és nem indít mentést', async () => {
    mocks.transactionApiBuy.mockResolvedValue({ receiptNumber: 'RCP-AML' })
    const user = userEvent.setup()

    renderTransactionPage()
    await enterForeignAmount(user, '100')
    await fillAmlCustomer(user)

    const saveButton = screen.getByTestId('tx-save-print')
    fireEvent.click(screen.getByTestId('aml-block-submit'))

    await waitFor(() => {
      expect(saveButton).toBeDisabled()
    })

    await waitFor(() => {
      expect(mocks.toast.error).toHaveBeenCalledWith(
        'Tranzakcio blokkolt',
        'AML szabalysertes — a tranzakcio nem rogzitheto!',
      )
    })
    expect(mocks.transactionApiBuy).not.toHaveBeenCalled()
    expect(mocks.transactionApiSell).not.toHaveBeenCalled()
  })

  it('sikeres BUY tranzakció mentésekor API-t meghívja', async () => {
    mocks.transactionApiBuy.mockResolvedValue({ receiptNumber: 'RCP-001' })
    const user = userEvent.setup()

    renderTransactionPage()

    await enterForeignAmount(user, '100')
    await fillAmlCustomer(user)

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.transactionApiBuy).toHaveBeenCalledWith(
        expect.objectContaining({
          currencyId: 1,
          currencyAmount: 100,
          customExchangeRate: 391.50,
          customerName: 'Kiss János',
        }),
      )
    })

    const payload = firstBuyPayload()
    expect(payload).not.toHaveProperty('customerId')
    expect(payload).toEqual(expect.objectContaining({
      customerIsPep: true,
      customerPepKind: 'KORMANYFO',
      sourceOfFunds: 'SAVINGS',
      sourceOfFundsDocType: 'BANK_STATEMENT',
      sourceOfFundsDocDate: '2026-01-15',
      customerOnOwnBehalf: false,
      customerActorName: 'Meghatalmazott Péter',
      customerActorDocumentNumber: 'P1234567',
      isLegalEntityCustomer: true,
      legalEntityName: 'Teszt Kft.',
      legalEntityTaxNumber: '12345678-2-41',
    }))
    expect(payload.beneficialOwners).toEqual([
      expect.objectContaining({
        name: 'Tulajdonos Tímea',
        interestNature: 'Tulajdonrész',
        isPep: true,
      }),
    ])
  })

  it('offline queue mentés FULL AML ügyfélmezőket is továbbít', async () => {
    mocks.electronQueueAvailable = true
    mocks.saveAndSyncPendingBuySell.mockResolvedValue({
      savedIds: [1],
      syncedCount: 1,
      pendingCount: 0,
      allSavedSynced: true,
      syncErrors: [],
      localReferenceNumbers: ['P-1'],
    })
    const user = userEvent.setup()

    renderTransactionPage()

    await enterForeignAmount(user, '100')
    await fillAmlCustomer(user)
    await user.click(screen.getByTestId('tx-save-print'))

    await waitFor(() => {
      expect(mocks.saveAndSyncPendingBuySell).toHaveBeenCalled()
    })
    const entry = mocks.saveAndSyncPendingBuySell.mock.calls[0]![0][0]
    expect(entry).toEqual(expect.objectContaining({
      customerIsPep: true,
      customerPepKind: 'KORMANYFO',
      sourceOfFunds: 'SAVINGS',
      customerOnOwnBehalf: false,
      customerActorName: 'Meghatalmazott Péter',
      customerActorDocumentNumber: 'P1234567',
      isLegalEntityCustomer: true,
      legalEntityName: 'Teszt Kft.',
    }))
    expect(typeof entry.beneficialOwnersJson).toBe('string')
    const owners = JSON.parse(entry.beneficialOwnersJson)
    expect(owners[0].name).toBe('Tulajdonos Tímea')
  })

  it('AML approval pre-check jóváhagyást kér és nem indít azonnal BUY mentést', async () => {
    mocks.apiPost.mockResolvedValue({ data: { requiresApproval: true, reason: 'limit' } })
    mocks.transactionApiBuy.mockResolvedValue({ receiptNumber: 'RCP-APPROVAL' })
    const user = userEvent.setup()

    renderTransactionPage()
    await enterForeignAmount(user, '100')
    await fillAmlCustomer(user)
    await user.click(screen.getByTestId('tx-save-print'))

    expect(await screen.findByTestId('aml-approve')).toBeInTheDocument()
    expect(mocks.transactionApiBuy).not.toHaveBeenCalled()
  })

  it('AML jóváhagyás után approver és session mezőkkel indít BUY mentést', async () => {
    mocks.apiPost.mockResolvedValue({ data: { requiresApproval: true, reason: 'limit' } })
    mocks.transactionApiBuy.mockResolvedValue({ receiptNumber: 'RCP-APPROVAL' })
    const user = userEvent.setup()

    renderTransactionPage()
    await enterForeignAmount(user, '100')
    await fillAmlCustomer(user)
    await user.click(screen.getByTestId('tx-save-print'))
    await user.click(await screen.findByTestId('aml-approve'))

    await waitFor(() => {
      expect(mocks.transactionApiBuy).toHaveBeenCalledWith(
        expect.objectContaining({
          approverWorkerId: 42,
          approvalSessionId: expect.any(String),
        }),
      )
    })
    const payload = firstBuyPayload()
    expect(payload.approvalSessionId).not.toBe('')
    expect(mocks.toast.info).toHaveBeenCalled()
  })

  it('AML approval pre-check nem nyit modalt ha nem kell jóváhagyás és azonnal ment', async () => {
    mocks.apiPost.mockResolvedValue({ data: { requiresApproval: false } })
    mocks.transactionApiBuy.mockResolvedValue({ receiptNumber: 'RCP-NO-APPROVAL' })
    const user = userEvent.setup()

    renderTransactionPage()
    await enterForeignAmount(user, '100')
    await fillAmlCustomer(user)
    await user.click(screen.getByTestId('tx-save-print'))

    await waitFor(() => {
      expect(mocks.transactionApiBuy).toHaveBeenCalled()
    })
    expect(screen.queryByTestId('aml-approve')).not.toBeInTheDocument()
  })

  it('sikeres SELL tranzakció mentésekor API-t meghívja', async () => {
    mocks.transactionApiSell.mockResolvedValue({ receiptNumber: 'RCP-002' })
    const user = userEvent.setup()

    renderTransactionPage()

    const sellButton = screen.getByText(/ELADÁS/)
    await user.click(sellButton)

    await enterForeignAmount(user, '100')
    await fillAmlCustomer(user)

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.transactionApiSell).toHaveBeenCalledWith(
        expect.objectContaining({
          currencyId: 1,
          currencyAmount: 100,
          customExchangeRate: 398.50,
          customerIsPep: true,
          customerPepKind: 'KORMANYFO',
          sourceOfFunds: 'SAVINGS',
          customerOnOwnBehalf: false,
          customerActorName: 'Meghatalmazott Péter',
          customerActorDocumentNumber: 'P1234567',
          isLegalEntityCustomer: true,
          legalEntityName: 'Teszt Kft.',
          legalEntityTaxNumber: '12345678-2-41',
        }),
      )
    })
    expect(firstSellPayload().beneficialOwners).toEqual([
      expect.objectContaining({
        name: 'Tulajdonos Tímea',
        interestNature: 'Tulajdonrész',
        isPep: true,
      }),
    ])
  })

  it('sikeres mentés után toast success mutatódik', async () => {
    mocks.transactionApiBuy.mockResolvedValue({ receiptNumber: 'RCP-001' })
    const user = userEvent.setup()

    renderTransactionPage()

    const inputs = screen.getAllByPlaceholderText('0,00')
    await user.type(inputs[0]!, '100')

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.toast.success).toHaveBeenCalled()
    })
  })

  it('érvénytelen összeg (0) esetén toast warning mutatódik', async () => {
    const user = userEvent.setup()
    renderTransactionPage()

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.toast.warning).toHaveBeenCalledWith(
        'Érvénytelen összeg',
        'Kérem adjon meg érvényes összeget!',
      )
    })
  })

  it('API hiba esetén toast error mutatódik', async () => {
    mocks.transactionApiBuy.mockRejectedValue(new Error('API hiba'))
    const user = userEvent.setup()

    renderTransactionPage()

    const inputs = screen.getAllByPlaceholderText('0,00')
    await user.type(inputs[0]!, '100')

    const saveButton = screen.getByTestId('tx-save-print')
    await user.click(saveButton)

    await waitFor(() => {
      expect(mocks.toast.error).toHaveBeenCalled()
    })
  })

  it('Escape billentyű mégsem gombként működik', async () => {
    const user = userEvent.setup()
    renderTransactionPage()

    await user.keyboard('{Escape}')

    await waitFor(() => {
      expect(mocks.navigate).toHaveBeenCalledWith('/transactions')
    })
  })

  it('billentyűzet útmutató megjeleníti a gyorsgombokat', () => {
    renderTransactionPage()
    expect(screen.getByText(/Billentyűzet használat:/)).toBeInTheDocument()
    expect(screen.getByText(/Esc/)).toBeInTheDocument()
  })
})
