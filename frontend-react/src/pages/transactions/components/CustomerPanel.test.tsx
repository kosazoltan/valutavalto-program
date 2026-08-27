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
  // FK-ÁLLAMPOLGÁRSÁG (2026-06-02): a CustomerPanel betölti a NATIONALITY dictionary-t.
  dictionaryApi: {
    getByCategory: vi.fn().mockResolvedValue([]),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

async function acceptPrivacyNotice(user: ReturnType<typeof userEvent.setup>) {
  await user.click(screen.getByTestId('customer-privacy-notice-checkbox'))
}

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

  it('SIMPLIFIED — összes szükséges mező hiányzik → hint látszik a 3 mezővel (Pmt. szerint okmány NEM kötelező)', () => {
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
    expect(hint).toHaveTextContent('Születési hely')
    expect(hint).toHaveTextContent('Születési idő')
    // 2026-05-15 user-direktíva: Okmányszám SIMPLIFIED-en NEM kötelező
    expect(hint).not.toHaveTextContent('Okmányszám')
  })

  it('SIMPLIFIED — csak Név kitöltve → hint a maradék 2 mezőt mutatja (szül.hely + szül.idő)', async () => {
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

    await user.type(screen.getByTestId('customer-name-input'), 'Kiss János')

    const hint = screen.getByTestId('customer-missing-fields-hint')
    expect(hint).not.toHaveTextContent('Név,')
    expect(hint).toHaveTextContent('Születési hely')
    expect(hint).toHaveTextContent('Születési idő')
    expect(hint).not.toHaveTextContent('Okmányszám')
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

  it('FULL — Okmányszám + Anyja neve + Lakcím extra-kötelező a SIMPLIFIED mezőkön túl', () => {
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
    expect(hint).toHaveTextContent('Okmányszám')
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

    await user.type(screen.getByTestId('customer-name-input'), 'Kiss János')
    await user.type(screen.getByTestId('customer-birth-place-input'), 'Budapest')
    await user.type(screen.getByTestId('customer-birth-date-input'), '1990-01-15')
    await acceptPrivacyNotice(user)

    const saveButton = screen.getByRole('button', { name: /Ügyfél rögzítése/i })
    await user.click(saveButton)

    expect(mocks.toastWarning).not.toHaveBeenCalled()
    expect(mocks.customerApiCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        notes: expect.stringContaining('ADATKEZELESI_TAJEKOZTATO_ACK v2026-06-09'),
      }),
    )
  })
})

describe('CustomerPanel — AML degradált mód (local-first 2026-05-14)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('AML check hálózati hiba (no response) → blocked=false + [OFFLINE_DEGRADED] prefix', async () => {
    const user = userEvent.setup()
    const onAmlResult = vi.fn()
    mocks.customerApiCreate.mockResolvedValue({ id: 99, name: 'Test User' })
    // Axios network error pattern: response=undefined, code='ERR_NETWORK'
    mocks.amlApiCheckAllThresholds.mockRejectedValue(
      Object.assign(new Error('Network Error'), { code: 'ERR_NETWORK', isAxiosError: true }),
    )

    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={200000}
        onCustomerReady={() => {}}
        onAmlResult={onAmlResult}
      />,
    )

    await user.type(screen.getByTestId('customer-name-input'), 'Bali Henrietta')
    await user.type(screen.getByTestId('customer-birth-place-input'), 'Szeged')
    await user.type(screen.getByTestId('customer-birth-date-input'), '1985-06-20')
    await acceptPrivacyNotice(user)

    await user.click(screen.getByRole('button', { name: /Ügyfél rögzítése/i }))

    await vi.waitFor(() => {
      expect(onAmlResult).toHaveBeenCalled()
    })

    const amlResult = onAmlResult.mock.calls.at(-1)![0]
    expect(amlResult.blocked).toBe(false)
    expect(amlResult.warnings.some((w: string) => w.startsWith('[OFFLINE_DEGRADED]'))).toBe(true)
  })

  it('Codex P1 #586: AML 401 auth hiba → fail-closed (blocked=true), NEM degradált', async () => {
    const user = userEvent.setup()
    const onAmlResult = vi.fn()
    mocks.customerApiCreate.mockResolvedValue({ id: 100, name: 'Auth Test' })
    mocks.amlApiCheckAllThresholds.mockRejectedValue(
      Object.assign(new Error('Request failed with status code 401'), {
        response: { status: 401, data: { message: 'Unauthorized' } },
        isAxiosError: true,
      }),
    )

    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={200000}
        onCustomerReady={() => {}}
        onAmlResult={onAmlResult}
      />,
    )

    await user.type(screen.getByTestId('customer-name-input'), 'Auth Test')
    await user.type(screen.getByTestId('customer-birth-place-input'), 'Budapest')
    await user.type(screen.getByTestId('customer-birth-date-input'), '1990-01-01')
    await acceptPrivacyNotice(user)

    await user.click(screen.getByRole('button', { name: /Ügyfél rögzítése/i }))

    await vi.waitFor(() => {
      expect(onAmlResult).toHaveBeenCalled()
    })

    const amlResult = onAmlResult.mock.calls.at(-1)![0]
    expect(amlResult.blocked).toBe(true)
    expect(amlResult.warnings.some((w: string) => w.startsWith('[OFFLINE_DEGRADED]'))).toBe(false)
    expect(amlResult.warnings[0]).toMatch(/szerver-oldali hibával/)
  })

  it('Codex P1 #586 iter-4: AML ERR_CANCELED (AbortController) → fail-closed (NEM degradált)', async () => {
    const user = userEvent.setup()
    const onAmlResult = vi.fn()
    mocks.customerApiCreate.mockResolvedValue({ id: 103, name: 'Cancel Test' })
    mocks.amlApiCheckAllThresholds.mockRejectedValue(
      Object.assign(new Error('Request canceled'), {
        code: 'ERR_CANCELED',
        isAxiosError: true,
      }),
    )

    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={200000}
        onCustomerReady={() => {}}
        onAmlResult={onAmlResult}
      />,
    )

    await user.type(screen.getByTestId('customer-name-input'), 'Cancel Test')
    await user.type(screen.getByTestId('customer-birth-place-input'), 'Miskolc')
    await user.type(screen.getByTestId('customer-birth-date-input'), '1985-03-15')
    await acceptPrivacyNotice(user)

    await user.click(screen.getByRole('button', { name: /Ügyfél rögzítése/i }))

    await vi.waitFor(() => {
      expect(onAmlResult).toHaveBeenCalled()
    })

    const amlResult = onAmlResult.mock.calls.at(-1)![0]
    expect(amlResult.blocked).toBe(true)
    expect(amlResult.warnings.some((w: string) => w.startsWith('[OFFLINE_DEGRADED]'))).toBe(false)
  })

  it('Codex P1 #586 iter-3: AML 500 internal server error → degradált (5xx intermittens)', async () => {
    const user = userEvent.setup()
    const onAmlResult = vi.fn()
    mocks.customerApiCreate.mockResolvedValue({ id: 102, name: '500 Test' })
    mocks.amlApiCheckAllThresholds.mockRejectedValue(
      Object.assign(new Error('Internal Server Error'), {
        response: { status: 500 },
        isAxiosError: true,
      }),
    )

    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={200000}
        onCustomerReady={() => {}}
        onAmlResult={onAmlResult}
      />,
    )

    await user.type(screen.getByTestId('customer-name-input'), '500 Test')
    await user.type(screen.getByTestId('customer-birth-place-input'), 'Pécs')
    await user.type(screen.getByTestId('customer-birth-date-input'), '1998-08-08')
    await acceptPrivacyNotice(user)

    await user.click(screen.getByRole('button', { name: /Ügyfél rögzítése/i }))

    await vi.waitFor(() => {
      expect(onAmlResult).toHaveBeenCalled()
    })

    const amlResult = onAmlResult.mock.calls.at(-1)![0]
    expect(amlResult.blocked).toBe(false)
    expect(amlResult.warnings.some((w: string) => w.startsWith('[OFFLINE_DEGRADED]'))).toBe(true)
  })

  it('Codex P1 #586: AML 503 service-unavailable → degradált (network-class hiba)', async () => {
    const user = userEvent.setup()
    const onAmlResult = vi.fn()
    mocks.customerApiCreate.mockResolvedValue({ id: 101, name: '503 Test' })
    mocks.amlApiCheckAllThresholds.mockRejectedValue(
      Object.assign(new Error('Service Unavailable'), {
        response: { status: 503 },
        isAxiosError: true,
      }),
    )

    render(
      <CustomerPanel
        identificationLevel="SIMPLIFIED"
        minimumLevel="SIMPLIFIED"
        onLevelChange={() => {}}
        requiresSourceVerification={false}
        hufTotal={200000}
        onCustomerReady={() => {}}
        onAmlResult={onAmlResult}
      />,
    )

    await user.type(screen.getByTestId('customer-name-input'), '503 Test')
    await user.type(screen.getByTestId('customer-birth-place-input'), 'Debrecen')
    await user.type(screen.getByTestId('customer-birth-date-input'), '1995-05-05')
    await acceptPrivacyNotice(user)

    await user.click(screen.getByRole('button', { name: /Ügyfél rögzítése/i }))

    await vi.waitFor(() => {
      expect(onAmlResult).toHaveBeenCalled()
    })

    const amlResult = onAmlResult.mock.calls.at(-1)![0]
    expect(amlResult.blocked).toBe(false)
    expect(amlResult.warnings.some((w: string) => w.startsWith('[OFFLINE_DEGRADED]'))).toBe(true)
  })
})

describe('CustomerPanel — TD9 auto-propagate change-guard', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('azonos (trim-ekvivalens) payload nem hív újra onCustomerReady-t; érdemi változás igen', async () => {
    // FE-FLAKY/TD5 tanulság: delay: null a userEvent.setup-nál
    const user = userEvent.setup({ delay: null })
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

    await user.type(screen.getByTestId('customer-name-input'), 'Kiss')
    const countAfterTyping = onCustomerReady.mock.calls.length
    expect(countAfterTyping).toBeGreaterThan(0)

    // Trailing space: a customerName state VÁLTOZIK (effekt-dep), de a trim-elt
    // payload azonos → a guardnak el kell nyelnie a hívást.
    await user.type(screen.getByTestId('customer-name-input'), ' ')
    expect(onCustomerReady.mock.calls.length).toBe(countAfterTyping)

    // Érdemi változás → pontosan 1 új hívás, a helyes payloaddal.
    await user.type(screen.getByTestId('customer-name-input'), 'J')
    expect(onCustomerReady.mock.calls.length).toBe(countAfterTyping + 1)
    const last = onCustomerReady.mock.calls.at(-1)![0]
    expect(last).toMatchObject({ name: 'Kiss J', nationality: 'Magyar' })
    // data?.id ?? null hívói kontraktus: auto-propagate payloadban nincs id
    expect(last.id).toBeUndefined()
  })
})
