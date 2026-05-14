import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CustomerPanel from './CustomerPanel'

const mocks = vi.hoisted(() => ({
  toastWarning: vi.fn(),
  toastError: vi.fn(),
  toastSuccess: vi.fn(),
  toastInfo: vi.fn(),
  customerApiCreate: vi.fn(),
  customerApiSearch: vi.fn(),
  customerApiGetByDocumentNumber: vi.fn(),
  amlApiCheckAllThresholds: vi.fn(),
}))

vi.mock('../../../components/ui/toaster', () => ({
  toast: {
    warning: mocks.toastWarning,
    error: mocks.toastError,
    success: mocks.toastSuccess,
    info: mocks.toastInfo,
  },
}))

vi.mock('../../../services/api/index', () => ({
  customerApi: {
    create: mocks.customerApiCreate,
    search: mocks.customerApiSearch,
    getByDocumentNumber: mocks.customerApiGetByDocumentNumber,
  },
  amlApi: {
    checkAllThresholds: mocks.amlApiCheckAllThresholds,
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

describe('CustomerPanel — missing required fields UX (bug #2 fix)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.customerApiCreate.mockResolvedValue({ id: 42, name: 'Test User' })
    mocks.amlApiCheckAllThresholds.mockResolvedValue({
      transactionType: 0,
      weeklyTotal: 0,
      yearlyMax: 0,
      quarterlyCount: 0,
      quarterlyTotal: 0,
      requiresId: false,
      requiresEnhanced: false,
      blocked: false,
      warnings: [],
    })
  })

  it('SIMPLIFIED — összes szükséges mező hiányzik → hint látszik a 4 mezővel', () => {
    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={150000}
        onCustomerReady={() => {}}
      />,
    )

    const hint = screen.getByTestId('customer-missing-fields-hint')
    expect(hint).toHaveTextContent('Hiányzó mezők:')
    expect(hint).toHaveTextContent('Név')
    expect(hint).toHaveTextContent('Okmányszám')
    expect(hint).toHaveTextContent('Születési hely')
    expect(hint).toHaveTextContent('Születési idő')
  })

  it('SIMPLIFIED — csak Név kitöltve → hint a maradék 3 mezőt mutatja', async () => {
    const user = userEvent.setup()
    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={150000}
        onCustomerReady={() => {}}
      />,
    )

    const nameInputs = screen.getAllByRole('textbox')
    // First textbox is the search input, second is the name input
    await user.type(nameInputs[1]!, 'Kiss János')

    const hint = screen.getByTestId('customer-missing-fields-hint')
    expect(hint).not.toHaveTextContent('Név,')
    expect(hint).toHaveTextContent('Okmányszám')
    expect(hint).toHaveTextContent('Születési hely')
    expect(hint).toHaveTextContent('Születési idő')
  })

  it('SIMPLE — soha nincs hint (csak állampolgárság kell)', () => {
    render(
      <CustomerPanel
        identificationLevel="SIMPLE"
        minimumLevel="SIMPLE"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={50000}
        onCustomerReady={() => {}}
      />,
    )

    expect(screen.queryByTestId('customer-missing-fields-hint')).not.toBeInTheDocument()
  })

  it('FULL — Anyja neve + Lakcím extra-kötelező a SIMPLIFIED mezőkön túl', () => {
    render(
      <CustomerPanel
        identificationLevel="FULL"
        minimumLevel="FULL"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={500000}
        onCustomerReady={() => {}}
      />,
    )

    const hint = screen.getByTestId('customer-missing-fields-hint')
    expect(hint).toHaveTextContent('Anyja neve')
    expect(hint).toHaveTextContent('Lakcím')
  })

  it('SIMPLIFIED — kattintás a "Ügyfél rögzítése" gombra hiányos formmal → toast.warning konkrét mezőkkel', async () => {
    const user = userEvent.setup()
    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={150000}
        onCustomerReady={() => {}}
      />,
    )

    const saveButton = screen.getByRole('button', { name: /Ügyfél rögzítése/i })
    await user.click(saveButton)

    expect(mocks.toastWarning).toHaveBeenCalledWith(
      'Hiányzó kötelező mezők',
      expect.stringContaining('Név'),
    )
    expect(mocks.customerApiCreate).not.toHaveBeenCalled()
  })

  it('SIMPLIFIED — teljes form → API hívás történik, toast nincs', async () => {
    const user = userEvent.setup()
    const onCustomerReady = vi.fn()
    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={150000}
        onCustomerReady={onCustomerReady}
      />,
    )

    const textboxes = screen.getAllByRole('textbox')
    // [0]=search, [1]=name, [2]=birthPlace, [3]=docNumber
    await user.type(textboxes[1]!, 'Kiss János')
    await user.type(textboxes[2]!, 'Budapest')
    await user.type(textboxes[3]!, 'AB123456')
    // Date input (HTML5 type=date — userEvent.type works with ISO format)
    const dateInput = document.querySelector<HTMLInputElement>('input[type="date"]')!
    await user.type(dateInput, '1990-01-15')

    const saveButton = screen.getByRole('button', { name: /Ügyfél rögzítése/i })
    await user.click(saveButton)

    expect(mocks.toastWarning).not.toHaveBeenCalled()
    expect(mocks.customerApiCreate).toHaveBeenCalled()
  })
})
