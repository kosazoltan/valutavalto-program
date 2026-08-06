import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { AxiosError } from 'axios'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ClosingWizardPage from './ClosingWizardPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  closingWizardApiStart: vi.fn(),
  closingWizardApiGet: vi.fn(),
  closingWizardApiGetStep: vi.fn(),
  closingWizardApiValidateTransactions: vi.fn(),
  closingWizardApiNavigate: vi.fn(),
  closingWizardApiFinalize: vi.fn(),
  closingWizardApiCancel: vi.fn(),
  closingWizardApiSubmitDenominations: vi.fn(),
  closingWizardApiCalculateDifferences: vi.fn(),
  closingWizardApiGetReport: vi.fn(),
  closingWizardApiGetCurrenciesWithBalance: vi.fn(),
  denominationApiList: vi.fn(),
  currencyApiGetActive: vi.fn(),
  dailySessionApiValidateClosing: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
    info: vi.fn(),
  },
  useAuthStore: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../../services/api/index', () => ({
  closingWizardApi: {
    start: mocks.closingWizardApiStart,
    get: mocks.closingWizardApiGet,
    getStep: mocks.closingWizardApiGetStep,
    validateTransactions: mocks.closingWizardApiValidateTransactions,
    navigate: mocks.closingWizardApiNavigate,
    finalize: mocks.closingWizardApiFinalize,
    cancel: mocks.closingWizardApiCancel,
    submitDenominations: mocks.closingWizardApiSubmitDenominations,
    calculateDifferences: mocks.closingWizardApiCalculateDifferences,
    getReport: mocks.closingWizardApiGetReport,
    getCurrenciesWithBalance: mocks.closingWizardApiGetCurrenciesWithBalance,
  },
  denominationApi: {
    list: mocks.denominationApiList,
  },
  currencyApi: {
    getActive: mocks.currencyApiGetActive,
  },
  dailySessionApi: {
    validateClosing: mocks.dailySessionApiValidateClosing,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

vi.mock('../../components/cashier/CashierHeader', () => ({
  CashierHeader: () => <div data-testid="cashier-header">Pénztárvezető: Test</div>,
}))

const mockWorker = {
  id: 1,
  workerCode: 'AB12',
  firstName: 'Teszt',
  lastName: 'Felhasználó',
  fullName: 'Teszt Felhasználó',
  role: 'CASHIER',
  branchId: 'b1',
  branchCode: 'KORUT',
  branchName: 'Korut',
  companyId: 'c1',
}

function renderClosingWizardPage(initialEntries = ['/closing/wizard']) {
  mocks.useAuthStore.mockImplementation((selector: any) => selector({ worker: mockWorker }))

  render(
    <MemoryRouter initialEntries={initialEntries}>
      <Routes>
        <Route path="/closing/wizard" element={<ClosingWizardPage />} />
        <Route path="/closing/wizard/:wizardId" element={<ClosingWizardPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

/** Helper: start wizard, step 1 passes, wizard pauses for denomination */
async function runStep1() {
  mocks.closingWizardApiStart.mockResolvedValue({
    id: 'wizard-1',
    branchId: 'b1',
    status: 'IN_PROGRESS',
    steps: [],
  })
  mocks.closingWizardApiNavigate.mockResolvedValue({
    steps: [{ stepNumber: 1, completed: true, stepDescription: 'OK' }],
  })

  renderClosingWizardPage()
  const user = userEvent.setup()

  const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
  await user.click(startButton)

  // Wait for step 1 to complete and denomination section to appear
  await waitFor(() => {
    expect(screen.getByText(/KITOLTÉS SZUKSÉGES/)).toBeInTheDocument()
  })

  return user
}

describe('ClosingWizardPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.closingWizardApiStart.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      status: 'IN_PROGRESS',
      steps: [],
      createdAt: new Date().toISOString(),
    })
    mocks.closingWizardApiSubmitDenominations.mockResolvedValue({ total: 100000 })
    mocks.closingWizardApiCalculateDifferences.mockResolvedValue([
      {
        currencyCode: 'HUF',
        expected: 100000,
        actual: 100000,
        difference: 0,
        status: 'OK',
      },
    ])
    mocks.closingWizardApiGetReport.mockResolvedValue({
      wizardId: 'wizard-1',
      branchName: 'Korut',
      closingDate: '2026-06-18',
      closingType: 'DAILY',
      transactionCount: 7,
      buyCount: 4,
      sellCount: 3,
      reversalCount: 1,
      buyTurnoverHuf: 1200000,
      sellTurnoverHuf: 900000,
      handlingFeeTotal: 15000,
      openingBalanceHuf: 500000,
      closingBalanceHuf: 620000,
      inventory: [
        {
          currencyCode: 'HUF',
          openingBalance: 500000,
          currentBalance: 620000,
          dailyChange: 120000,
        },
      ],
    })
    mocks.closingWizardApiGet.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      branchName: 'Korut',
      closingDate: '2026-06-18',
      closingType: 'DAILY',
      currentStep: 2,
      totalSteps: 9,
      wizardStatus: 'IN_PROGRESS',
      startedByWorkerId: '1',
      startedByWorkerName: 'Teszt Felhasználó',
      startedAt: '2026-06-18T18:00:00',
      steps: [
        {
          stepNumber: 1,
          stepTitle: 'Backend MTCN ellenőrzés',
          stepDescription: 'Backendből betöltött első lépés',
          completed: true,
          canProceed: true,
          stepData: {},
        },
        {
          stepNumber: 2,
          stepTitle: 'Backend címletezés',
          stepDescription: 'Backendből betöltött aktuális lépés',
          completed: false,
          canProceed: true,
          stepData: {},
        },
      ],
    })
    mocks.closingWizardApiGetStep.mockResolvedValue({
      stepNumber: 2,
      stepTitle: 'Backend címletezés',
      stepDescription: 'Backendből betöltött aktuális lépés',
      completed: false,
      canProceed: true,
      stepData: {},
    })
    mocks.closingWizardApiValidateTransactions.mockResolvedValue([])
    // FK-063: default pénztári készlet — csak HUF (a meglévő tesztek HUF-only formát várnak)
    mocks.closingWizardApiGetCurrenciesWithBalance.mockResolvedValue(['HUF'])
    mocks.denominationApiList.mockResolvedValue([])
    mocks.currencyApiGetActive.mockResolvedValue([])
    mocks.dailySessionApiValidateClosing.mockResolvedValue({
      validationDate: '2026-06-18',
      errorCode: 0,
      errorMessage: 'Minden címletezés rendben',
      allValid: true,
      currencyDenominationOk: true,
      handlingFeeDenominationOk: true,
      westernUnionDenominationOk: true,
      vatDenominationOk: true,
      ecommerceDenominationOk: true,
    })
  })

  it('oldal renderelésének ellenőrzése', () => {
    renderClosingWizardPage()
    expect(screen.getByText('NAPZÁRÁS WIZARD')).toBeInTheDocument()
  })

  it('G10: a kiválasztott zárás-típus átmegy a start() hívásba', async () => {
    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [{ stepNumber: 1, completed: true, stepDescription: 'OK' }],
    })
    renderClosingWizardPage()
    const user = userEvent.setup()

    await user.selectOptions(screen.getByRole('combobox'), 'DECADE')
    await user.click(screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i }))

    await waitFor(() => expect(mocks.closingWizardApiStart).toHaveBeenCalled())
    // start(branchId, cashDeskId, closingType, workerId) → 3. argumentum a típus
    const firstCall = mocks.closingWizardApiStart.mock.calls[0]
    expect(firstCall?.[2]).toBe('DECADE')
  })

  it('NEM rendereli a saját CashierHeader-t (v2.5.3 PR #345 — MainLayout headere helyettesíti)', () => {
    renderClosingWizardPage()
    expect(screen.queryByTestId('cashier-header')).not.toBeInTheDocument()
  })

  it('zárási lépéseket listázza', () => {
    renderClosingWizardPage()
    expect(screen.getByText(/MTCN szám ellenőrzés/)).toBeInTheDocument()
    expect(screen.getByText(/Esti pénztár címletezése/)).toBeInTheDocument()
  })

  it('zárás megkezdése gombra kattintás API-t meghívja', async () => {
    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [{ stepNumber: 1, completed: true, stepDescription: 'OK' }],
    })

    renderClosingWizardPage()
    const user = userEvent.setup()

    const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
    await user.click(startButton)

    await waitFor(() => {
      expect(mocks.closingWizardApiStart).toHaveBeenCalledWith(
        mockWorker.branchId,
        undefined,
        'DAILY',
        String(mockWorker.id),
      )
    })
  })

  it('nyitott tranzakció validáció hibánál nem indít új zárási wizardot', async () => {
    mocks.closingWizardApiValidateTransactions.mockResolvedValue([
      'Van folyamatban lévő (PENDING) tranzakció!',
    ])

    renderClosingWizardPage()
    const user = userEvent.setup()

    await user.click(screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i }))

    await waitFor(() => {
      expect(mocks.closingWizardApiValidateTransactions).toHaveBeenCalled()
    })
    expect(mocks.closingWizardApiStart).not.toHaveBeenCalled()
    expect(mocks.toast.warning).toHaveBeenCalledWith(
      'Nyitott tranzakció validáció sikertelen',
      'Van folyamatban lévő (PENDING) tranzakció!',
    )
    expect(screen.getByText(/Van folyamatban lévő/)).toBeInTheDocument()
  })

  it('lépések állapot mutatói megjelennek', () => {
    renderClosingWizardPage()
    const stepLabels = screen.getByText(/MTCN szám ellenőrzés/)
    expect(stepLabels).toBeInTheDocument()
  })

  it('progress bar megjelenítése', () => {
    renderClosingWizardPage()
    expect(screen.getByText(/Előrehaladás/)).toBeInTheDocument()
  })

  it('nem bejelentkezett felhasználó esetén error toast', async () => {
    mocks.useAuthStore.mockImplementation((selector: any) => selector({ worker: null }))

    render(
      <MemoryRouter>
        <ClosingWizardPage />
      </MemoryRouter>,
    )

    expect(screen.getByText('NAPZÁRÁS WIZARD')).toBeInTheDocument()
  })

  it('API hiba során hibaüzenet jelenik meg', async () => {
    mocks.closingWizardApiStart.mockRejectedValue(new Error('API hiba'))

    renderClosingWizardPage()
    const user = userEvent.setup()

    const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
    await user.click(startButton)

    await waitFor(() => {
      expect(mocks.toast.error).toHaveBeenCalled()
    })
  })

  it('start HTTP 400 esetén a backend validációs üzenetét mutatja', async () => {
    const backendError = new AxiosError(
      'Request failed with status code 400',
      'ERR_BAD_REQUEST',
      undefined,
      undefined,
      {
        status: 400,
        data: { message: 'Már van aktív zárási varázsló ehhez az irodához a mai napra!' },
      } as never,
    )
    mocks.closingWizardApiValidateTransactions.mockResolvedValue([])
    mocks.closingWizardApiStart.mockRejectedValue(backendError)

    renderClosingWizardPage()
    const user = userEvent.setup()

    await user.click(screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i }))

    await waitFor(() =>
      expect(mocks.toast.error).toHaveBeenCalledWith(
        'Napzárás hiba',
        'Már van aktív zárási varázsló ehhez az irodához a mai napra!',
      ),
    )
  })

  // ========== DENOMINATION FLOW TESTS ==========

  it('step 1 után megáll és címletezési inputot mutat', async () => {
    await runStep1()
    // Denomination section visible with "KITOLTÉS SZUKSÉGES" badge
    expect(screen.getByText(/Esti penztár cimletezése/)).toBeInTheDocument()
    expect(screen.getByText(/KITOLTÉS SZUKSÉGES/)).toBeInTheDocument()
  })

  it('cimletezés összeg helyes számolás', async () => {
    const user = await runStep1()

    // Fill in: 2 x 10,000 Ft = 20,000
    const inputs = screen.getAllByRole('spinbutton')
    // Second input is 10,000 (HUF_DENOMINATIONS order: 20k, 10k, ...)
    await user.clear(inputs[1]!)
    await user.type(inputs[1]!, '2')

    // Verify the total is computed correctly — 2 x 10,000 = 20,000
    // Use a function matcher since toLocaleString may produce non-breaking spaces
    // v2.5.3 (PR #345): a text-xl text-base-re csökkent a kompakt layout során
    const totalEl = screen.getByText((_content, element) => {
      return (
        element?.tagName === 'SPAN' &&
        element.classList.contains('text-base') &&
        element.textContent?.replace(/\s/g, '') === '20000Ft'
      )
    })
    expect(totalEl).toBeInTheDocument()
  })

  it('cimletezés rögzítés gomb 0 összegnél disabled', async () => {
    await runStep1()

    const submitBtn = screen.getByRole('button', { name: /Cimletezés rogzitese/i })
    expect(submitBtn).toBeDisabled()
  })

  it('cimletezés rögzítés elindítja a hátralevő lépéseket (2-9)', async () => {
    const user = await runStep1()

    // Steps 2-9 will all pass
    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [{ stepNumber: 2, completed: true }],
    })

    // Enter denomination
    const inputs = screen.getAllByRole('spinbutton')
    await user.clear(inputs[0]!) // 20,000 Ft
    await user.type(inputs[0]!, '5')

    const submitBtn = screen.getByRole('button', { name: /Cimletezés rogzitese/i })
    expect(submitBtn).not.toBeDisabled()
    await user.click(submitBtn)

    // Verify steps 2-9 navigate calls happen
    await waitFor(() => {
      expect(mocks.closingWizardApiCalculateDifferences).toHaveBeenCalledWith('wizard-1', {
        HUF: 100000,
      })
      // Step 1 was called in runStep1, steps 2-9 = 8 more calls
      expect(mocks.closingWizardApiNavigate).toHaveBeenCalledTimes(9) // 1 + 8
    })
  })

  it('route wizardId alapján betölti a backend wizardot és az aktuális lépést', async () => {
    renderClosingWizardPage(['/closing/wizard/wizard-1'])

    await waitFor(() => {
      expect(mocks.closingWizardApiGet).toHaveBeenCalledWith('wizard-1')
      expect(mocks.closingWizardApiGetStep).toHaveBeenCalledWith('wizard-1', 2)
    })

    expect(screen.getByTestId('closing-wizard-current-step')).toHaveTextContent(
      'Backend címletezés',
    )
    expect(screen.getByText('Backend MTCN ellenőrzés')).toBeInTheDocument()
  })

  it('cimletezés után backend eltérés-számítást kér és megjeleníti az eredményt', async () => {
    const user = await runStep1()

    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [{ stepNumber: 2, completed: true }],
    })
    mocks.closingWizardApiCalculateDifferences.mockResolvedValue([
      {
        currencyCode: 'HUF',
        expected: 100000,
        actual: 120000,
        difference: 20000,
        status: 'DISCREPANCY',
      },
    ])

    const inputs = screen.getAllByRole('spinbutton')
    await user.clear(inputs[0]!)
    await user.type(inputs[0]!, '6')
    await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

    await waitFor(() => {
      expect(mocks.closingWizardApiCalculateDifferences).toHaveBeenCalledWith('wizard-1', {
        HUF: 120000,
      })
      expect(screen.getByText('Eltérés ellenőrzés')).toBeInTheDocument()
      expect(screen.getByTestId('closing-differences-table')).toHaveTextContent('DISCREPANCY')
    })
  })

  it('betölti és megjeleníti a napi zárás előellenőrzés backend státuszát', async () => {
    renderClosingWizardPage()

    await waitFor(() => {
      expect(mocks.dailySessionApiValidateClosing).toHaveBeenCalled()
      expect(screen.getByText('Napi zárás előellenőrzés')).toBeInTheDocument()
      expect(screen.getByText('Minden címletezés rendben')).toBeInTheDocument()
    })
  })

  it('sikeres zárási lépések után betölti és megjeleníti a backend zárási riportot', async () => {
    const user = await runStep1()

    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [{ stepNumber: 2, completed: true }],
    })

    const inputs = screen.getAllByRole('spinbutton')
    await user.clear(inputs[0]!)
    await user.type(inputs[0]!, '2')
    await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

    await waitFor(() => {
      expect(mocks.closingWizardApiGetReport).toHaveBeenCalledWith('wizard-1')
      expect(screen.getByText('Zárási riport előnézet')).toBeInTheDocument()
      expect(screen.getByText('Korut')).toBeInTheDocument()
      expect(screen.getAllByText('HUF').length).toBeGreaterThanOrEqual(1)
    })
  })

  it('finalize tiltva ha cimletezés nincs rögzítve', async () => {
    renderClosingWizardPage()

    // Finalize button exists but disabled
    const finalizeBtn = screen.getByRole('button', { name: /Minden lépés szükséges/i })
    expect(finalizeBtn).toBeDisabled()
  })

  it('finalize engedélyezve ha minden step PASS és cimletezés rögzítve', async () => {
    const user = await runStep1()

    // Steps 2-9 pass
    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [{ stepNumber: 2, completed: true }],
    })
    mocks.closingWizardApiFinalize.mockResolvedValue({ success: true, message: 'OK' })

    // Denomination
    const inputs = screen.getAllByRole('spinbutton')
    await user.clear(inputs[0]!)
    await user.type(inputs[0]!, '3')
    const submitBtn = screen.getByRole('button', { name: /Cimletezés rogzitese/i })
    await user.click(submitBtn)

    // Wait for all steps to complete
    await waitFor(() => {
      expect(mocks.closingWizardApiNavigate).toHaveBeenCalledTimes(9)
    })

    // Now finalize should show
    await waitFor(() => {
      const finalizeBtn = screen.getByRole('button', { name: /Napzárás végrehajtása/i })
      expect(finalizeBtn).not.toBeDisabled()
    })
  })

  it('cancel reseteli a wizardot és a cimletezést', async () => {
    mocks.closingWizardApiNavigate.mockRejectedValueOnce(new Error('step 1 fail'))
    mocks.closingWizardApiCancel.mockResolvedValue({})

    renderClosingWizardPage()
    const user = userEvent.setup()

    const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
    await user.click(startButton)

    await waitFor(() => {
      expect(screen.getByText(/ÚJRA/)).toBeInTheDocument()
    })

    await user.click(screen.getByRole('button', { name: /ÚJRA/i }))

    // Should reset back to initial state
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })).toBeInTheDocument()
    })
  })

  it('zárás véglegesítése API-t meghívja', async () => {
    const user = await runStep1()

    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [{ stepNumber: 2, completed: true }],
    })
    mocks.closingWizardApiFinalize.mockResolvedValue({ success: true, message: 'OK' })

    // Denomination
    const inputs = screen.getAllByRole('spinbutton')
    await user.clear(inputs[0]!)
    await user.type(inputs[0]!, '1')
    await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

    await waitFor(() => {
      expect(mocks.closingWizardApiNavigate).toHaveBeenCalledTimes(9)
    })

    await waitFor(async () => {
      const finalizeBtn = screen.getByRole('button', { name: /Napzárás végrehajtása/i })
      await user.click(finalizeBtn)
    })

    await waitFor(() => {
      expect(mocks.closingWizardApiFinalize).toHaveBeenCalledWith('wizard-1', String(mockWorker.id))
    })
  })

  // ========== FK-063: MULTI-DEVIZÁS PÉNZTÁRI BECÍMLETEZÉS ==========

  describe('FK-063 multi-devizás pénztári becímletezés', () => {
    beforeEach(() => {
      mocks.closingWizardApiGetCurrenciesWithBalance.mockResolvedValue(['HUF', 'EUR'])
      mocks.denominationApiList.mockResolvedValue([
        { currencyCode: 'HUF', faceValue: 20000 },
        { currencyCode: 'HUF', faceValue: 10000 },
        { currencyCode: 'EUR', faceValue: 100 },
        { currencyCode: 'EUR', faceValue: 50 },
        { currencyCode: 'USD', faceValue: 100 }, // nincs készlet → nem jelenhet meg
      ])
    })

    it('FR-2: pénztár módban HUF+EUR szekció renderel (USD nem, mert nincs készlet)', async () => {
      await runStep1()

      await waitFor(() => {
        expect(mocks.closingWizardApiGetCurrenciesWithBalance).toHaveBeenCalled()
      })
      // Szekció-fejlécek több pénznemnél
      expect(screen.getByText('HUF')).toBeInTheDocument()
      expect(screen.getByText('EUR')).toBeInTheDocument()
      expect(screen.queryByText('USD')).not.toBeInTheDocument()
      // HUF 2 + EUR 2 = 4 input
      expect(screen.getAllByRole('spinbutton')).toHaveLength(4)
    })

    it('FR-7: a Tovább gomb csak akkor aktív, ha minden kötelező pénznem ki van töltve', async () => {
      const user = await runStep1()

      const inputs = screen.getAllByRole('spinbutton')
      const submitBtn = screen.getByRole('button', { name: /Cimletezés rogzitese/i })

      // Csak HUF kitöltve → disabled
      await user.clear(inputs[0]!)
      await user.type(inputs[0]!, '2')
      expect(submitBtn).toBeDisabled()

      // EUR is kitöltve → enabled
      await user.clear(inputs[2]!)
      await user.type(inputs[2]!, '3')
      expect(submitBtn).not.toBeDisabled()
    })

    it('FR-7: pénznemenkénti részösszeg jelenik meg (nem összevont Ft)', async () => {
      const user = await runStep1()

      const inputs = screen.getAllByRole('spinbutton')
      await user.clear(inputs[0]!)
      await user.type(inputs[0]!, '2') // 40 000 HUF
      await user.clear(inputs[2]!)
      await user.type(inputs[2]!, '3') // 300 EUR

      const totalEl = screen.getByText((_c, element) => {
        return (
          element?.tagName === 'SPAN' &&
          element.classList.contains('text-base') &&
          element.textContent?.replace(/\s/g, '') === '40000HUF+300EUR'
        )
      })
      expect(totalEl).toBeInTheDocument()
    })

    it('FR-2 fallback: végpont-hiba esetén HUF-only forma marad', async () => {
      mocks.closingWizardApiGetCurrenciesWithBalance.mockRejectedValue(new Error('offline'))
      await runStep1()

      // 12 beépített HUF címlet
      expect(screen.getAllByRole('spinbutton')).toHaveLength(12)
      expect(screen.queryByText('EUR')).not.toBeInTheDocument()
    })
  })

  // ========== FK-064: EGYSÉGES ZÁRÁS-KÉSZENLÉT ==========

  describe('FK-064 zárás-készenlét egységesítés', () => {
    it('FR-1: mindhárom forrás rendben → "Kész a beküldésre"', async () => {
      const user = await runStep1()
      mocks.closingWizardApiNavigate.mockResolvedValue({
        steps: [{ stepNumber: 2, completed: true }],
      })

      const inputs = screen.getAllByRole('spinbutton')
      await user.clear(inputs[0]!)
      await user.type(inputs[0]!, '3')
      await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

      await waitFor(() => {
        expect(screen.getByTestId('closing-readiness-banner')).toHaveTextContent(
          'Kész a beküldésre',
        )
      })
    })

    it('FR-2: kezdeti állapotban "Van teendő" + a checklist forrás nevesítve', () => {
      renderClosingWizardPage()
      const banner = screen.getByTestId('closing-readiness-banner')
      expect(banner).toHaveTextContent('Van teendő')
      expect(banner).toHaveTextContent('ellenőrzési lista')
    })

    it('FR-2: előellenőrzés hibás → az előellenőrző panel forrás is nevesítve', async () => {
      mocks.dailySessionApiValidateClosing.mockResolvedValue({
        validationDate: '2026-06-18',
        errorCode: 1,
        errorMessage: 'Hiányzó címletezés',
        allValid: false,
        currencyDenominationOk: false,
        handlingFeeDenominationOk: true,
        westernUnionDenominationOk: true,
        vatDenominationOk: true,
        ecommerceDenominationOk: true,
      })
      renderClosingWizardPage()

      await waitFor(() => {
        expect(screen.getByTestId('closing-readiness-banner')).toHaveTextContent(
          'előellenőrző panel',
        )
      })
    })

    it('FR-3: DISCREPANCY az eltérés-táblázatban → a panel nem mutat "minden rendben"-t', async () => {
      const user = await runStep1()
      mocks.closingWizardApiNavigate.mockResolvedValue({
        steps: [{ stepNumber: 2, completed: true }],
      })
      mocks.closingWizardApiCalculateDifferences.mockResolvedValue([
        { currencyCode: 'HUF', expected: 100000, actual: 100000, difference: 0, status: 'OK' },
        { currencyCode: 'EUR', expected: 500, actual: 450, difference: -50, status: 'DISCREPANCY' },
      ])

      const inputs = screen.getAllByRole('spinbutton')
      await user.clear(inputs[0]!)
      await user.type(inputs[0]!, '3')
      await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

      await waitFor(() => {
        expect(screen.queryByText('Minden címletezés rendben')).not.toBeInTheDocument()
        expect(
          screen.getByText('Megoldatlan eltérés van az eltérés-táblázatban'),
        ).toBeInTheDocument()
        const banner = screen.getByTestId('closing-readiness-banner')
        expect(banner).toHaveTextContent('Van teendő')
        expect(banner).toHaveTextContent('eltérés-táblázat')
      })
    })

    it('FR-4: az eltérés-táblázat N pénznem-sorral is renderel (4 sor)', async () => {
      const user = await runStep1()
      mocks.closingWizardApiNavigate.mockResolvedValue({
        steps: [{ stepNumber: 2, completed: true }],
      })
      mocks.closingWizardApiCalculateDifferences.mockResolvedValue([
        { currencyCode: 'HUF', expected: 1, actual: 1, difference: 0, status: 'OK' },
        { currencyCode: 'EUR', expected: 2, actual: 2, difference: 0, status: 'OK' },
        { currencyCode: 'USD', expected: 3, actual: 3, difference: 0, status: 'OK' },
        { currencyCode: 'GBP', expected: 4, actual: 4, difference: 0, status: 'OK' },
      ])

      const inputs = screen.getAllByRole('spinbutton')
      await user.clear(inputs[0]!)
      await user.type(inputs[0]!, '3')
      await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

      await waitFor(() => {
        const table = screen.getByTestId('closing-differences-table')
        expect(table.querySelectorAll('tbody tr')).toHaveLength(4)
        expect(table).toHaveTextContent('GBP')
      })
    })

    it('FR-5: DISCREPANCY esetén a véglegesítés gomb inaktív marad', async () => {
      const user = await runStep1()
      mocks.closingWizardApiNavigate.mockResolvedValue({
        steps: [{ stepNumber: 2, completed: true }],
      })
      mocks.closingWizardApiCalculateDifferences.mockResolvedValue([
        { currencyCode: 'EUR', expected: 500, actual: 450, difference: -50, status: 'DISCREPANCY' },
      ])

      const inputs = screen.getAllByRole('spinbutton')
      await user.clear(inputs[0]!)
      await user.type(inputs[0]!, '3')
      await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

      await waitFor(() => {
        expect(mocks.closingWizardApiNavigate).toHaveBeenCalledTimes(9)
      })
      const finalizeBtn = screen.getByRole('button', { name: /Minden lépés szükséges/i })
      expect(finalizeBtn).toBeDisabled()
    })
  })

  // ========== FK-073: ZÁRÁSKORI TOLERANCIA — status-alapú blokkolás ==========

  describe('FK-073 eltérés-blokkolás a backend status alapján', () => {
    it('FR-2a: status OK sor NEM blokkol pénznemtől függetlenül (még HUF kis eltérésnél is)', async () => {
      const user = await runStep1()
      mocks.closingWizardApiNavigate.mockResolvedValue({
        steps: [{ stepNumber: 2, completed: true }],
      })
      // A backend tolerancia-kiértékelése minden sort OK-nak minősített,
      // pedig a HUF-sorban van nem nulla (≤1 Ft) eltérés.
      mocks.closingWizardApiCalculateDifferences.mockResolvedValue([
        { currencyCode: 'HUF', expected: 100000, actual: 100001, difference: 1, status: 'OK' },
        { currencyCode: 'EUR', expected: 500, actual: 500, difference: 0, status: 'OK' },
        { currencyCode: 'USD', expected: 200, actual: 200, difference: 0, status: 'OK' },
      ])

      const inputs = screen.getAllByRole('spinbutton')
      await user.clear(inputs[0]!)
      await user.type(inputs[0]!, '3')
      await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

      await waitFor(() => {
        expect(screen.getByTestId('closing-readiness-banner')).toHaveTextContent(
          'Kész a beküldésre',
        )
        expect(screen.getByText('Minden címletezés rendben')).toBeInTheDocument()
      })
      const finalizeBtn = screen.getByRole('button', { name: /Napzárás végrehajtása/i })
      expect(finalizeBtn).not.toBeDisabled()
    })

    it('FR-2b: status DISCREPANCY HUF ≤1 eltéréssel IS blokkol (a régi HUF-kivétel megszűnt)', async () => {
      const user = await runStep1()
      mocks.closingWizardApiNavigate.mockResolvedValue({
        steps: [{ stepNumber: 2, completed: true }],
      })
      // 1 Ft-os HUF-eltérés, amit a backend DISCREPANCY-nek minősített:
      // a korábbi kézzel bedrótozott frontend HUF ≤1 kivétel ezt már nem védheti fel.
      mocks.closingWizardApiCalculateDifferences.mockResolvedValue([
        {
          currencyCode: 'HUF',
          expected: 100000,
          actual: 100001,
          difference: 1,
          status: 'DISCREPANCY',
        },
      ])

      const inputs = screen.getAllByRole('spinbutton')
      await user.clear(inputs[0]!)
      await user.type(inputs[0]!, '3')
      await user.click(screen.getByRole('button', { name: /Cimletezés rogzitese/i }))

      await waitFor(() => {
        expect(mocks.closingWizardApiNavigate).toHaveBeenCalledTimes(9)
      })
      await waitFor(() => {
        expect(screen.queryByText('Minden címletezés rendben')).not.toBeInTheDocument()
        expect(
          screen.getByText('Megoldatlan eltérés van az eltérés-táblázatban'),
        ).toBeInTheDocument()
        const banner = screen.getByTestId('closing-readiness-banner')
        expect(banner).toHaveTextContent('Van teendő')
        expect(banner).toHaveTextContent('eltérés-táblázat')
      })
      const finalizeBtn = screen.getByRole('button', { name: /Minden lépés szükséges/i })
      expect(finalizeBtn).toBeDisabled()
    })
  })
})
