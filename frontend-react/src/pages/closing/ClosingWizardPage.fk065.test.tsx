import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ClosingWizardPage from './ClosingWizardPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  closingWizardApiStart: vi.fn(),
  closingWizardApiGet: vi.fn(),
  closingWizardApiGetStep: vi.fn(),
  closingWizardApiGetStatus: vi.fn(),
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
    getStatus: mocks.closingWizardApiGetStatus,
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

function renderPage(initialEntries = ['/closing/wizard']) {
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

function statusResponse(activeWizardId: string | null, activeWizardStatus: string | null = null) {
  return {
    branchId: 'b1',
    closingDate: '2026-07-27',
    vaultContext: false,
    denominationRecorded: false,
    exactMatch: false,
    message: '',
    differences: [],
    // FK-065 FR-2: új nullable mezők a backend ClosingWizardStatusDto-ból.
    // EGYHÍVÁSOS FR-3 szerződés: az EXPIRED-ágat a frontend az
    // activeWizardStatus-ból dönti el, NEM külön get(activeWizardId) hívásból.
    activeWizardId,
    activeWizardStatus,
  }
}

/**
 * FK-065 RED-fázis tesztek. MINDEGYIKNEK BUKNIA KELL most:
 * a wizardStatusPolicy modul, a mount-kori getStatus-hívás, a Folytatás /
 * Megszakítás és újraindítás UI, az ismeretlen-státusz catch-ág és a
 * step-1-bukás → cancel viselkedés még nem létezik.
 * Tesztet a bukás elfedésére módosítani TILOS.
 */
describe('ClosingWizardPage — FK-065 beragadt zárási munkamenet', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.closingWizardApiGetStatus.mockResolvedValue(statusResponse(null))
    mocks.closingWizardApiValidateTransactions.mockResolvedValue([])
    mocks.closingWizardApiGetCurrenciesWithBalance.mockResolvedValue(['HUF'])
    mocks.denominationApiList.mockResolvedValue([])
    mocks.currencyApiGetActive.mockResolvedValue([])
    mocks.dailySessionApiValidateClosing.mockResolvedValue({
      validationDate: '2026-07-27',
      errorCode: 0,
      errorMessage: 'Minden címletezés rendben',
      allValid: true,
    })
    mocks.closingWizardApiStart.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      status: 'IN_PROGRESS',
      steps: [],
    })
    mocks.closingWizardApiCancel.mockResolvedValue({})
  })

  // ============ FR-3: beragadt munkamenet felajánlása ============

  it('FR-3: activeWizardId+IN_PROGRESS esetén Folytatás és Megszakítás és újraindítás gombok jelennek meg', async () => {
    mocks.closingWizardApiGetStatus.mockResolvedValue(statusResponse('wizard-9', 'IN_PROGRESS'))

    renderPage()

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /Folytatás/i })).toBeInTheDocument()
    })
    expect(screen.getByRole('button', { name: /Megszakítás és újraindítás/i })).toBeInTheDocument()
    expect(mocks.closingWizardApiGetStatus).toHaveBeenCalled()
    // Egyhívásos szerződés: a döntéshez NEM hívható külön get(activeWizardId)
    expect(mocks.closingWizardApiGet).not.toHaveBeenCalled()
  })

  it('FR-3: activeWizardId=null esetén a normál indítás-folyamat fut, folytatás-gombok nélkül', async () => {
    mocks.closingWizardApiGetStatus.mockResolvedValue(statusResponse(null))

    renderPage()

    await waitFor(() => {
      expect(mocks.closingWizardApiGetStatus).toHaveBeenCalled()
    })
    expect(screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Folytatás/i })).not.toBeInTheDocument()
    expect(
      screen.queryByRole('button', { name: /Megszakítás és újraindítás/i }),
    ).not.toBeInTheDocument()
  })

  it('FR-3: EXPIRED státuszra nincs Folytatás gomb, csak Új zárás indítása', async () => {
    mocks.closingWizardApiGetStatus.mockResolvedValue(statusResponse('wizard-exp', 'EXPIRED'))

    renderPage()

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /Új zárás indítása/i })).toBeInTheDocument()
    })
    expect(screen.queryByRole('button', { name: /Folytatás/i })).not.toBeInTheDocument()
    // Egyhívásos szerződés: az EXPIRED-ág az activeWizardStatus-ból dől el
    expect(mocks.closingWizardApiGet).not.toHaveBeenCalled()
  })

  it('FR-3 fallback: ismeretlen wizard-státusznál semleges hibaüzenet, az oldal nem omlik össze', async () => {
    // A resolveWizardResumeAction ismeretlen státuszra throw-t ad (exhaustiveness-
    // garancia) — a hívó oldalon (ClosingWizardPage) try/catch kötelező, semleges
    // üzenettel. SZERZŐDÉS-DÖNTÉS: az üzenet INLINE szövegként jelenik meg (nem
    // toast), mert perzisztensnek kell maradnia, amíg a felhasználó nem frissít.
    mocks.closingWizardApiGetStatus.mockResolvedValue(statusResponse('wizard-x', 'SOMETHING_NEW'))

    renderPage()

    await waitFor(() => {
      expect(
        screen.getByText(/Állapot lekérdezése sikertelen, frissítsd az oldalt/i),
      ).toBeInTheDocument()
    })
    // Az oldal működőképes marad: a normál indítás elérhető, folytatás-gombok nincsenek
    expect(screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Folytatás/i })).not.toBeInTheDocument()
    expect(
      screen.queryByRole('button', { name: /Megszakítás és újraindítás/i }),
    ).not.toBeInTheDocument()
  })

  it('FR-3 Bugbot-fix: bukó cancel után a banner megmarad, konkrét hibaüzenet, új zárás NEM indul', async () => {
    mocks.closingWizardApiGetStatus.mockResolvedValue(statusResponse('wizard-9', 'IN_PROGRESS'))
    mocks.closingWizardApiCancel.mockRejectedValue(new Error('Hálózati hiba'))

    renderPage()
    const user = userEvent.setup()
    await waitFor(() => {
      expect(
        screen.getByRole('button', { name: /Megszakítás és újraindítás/i }),
      ).toBeInTheDocument()
    })
    await user.click(screen.getByRole('button', { name: /Megszakítás és újraindítás/i }))

    // Konkrét hibaüzenet jelenik meg (inline, nem általános toast)
    await waitFor(() => {
      expect(
        screen.getByText(/A korábbi munkamenet megszakítása sikertelen, próbáld újra/i),
      ).toBeInTheDocument()
    })
    // A banner megmarad — a vezetett helyreállítás (Folytatás) továbbra is elérhető
    expect(screen.getByRole('button', { name: /Folytatás/i })).toBeInTheDocument()
    // Új zárás NEM indul (runClosing nem fut): sem validateTransactions, sem start
    expect(mocks.closingWizardApiValidateTransactions).not.toHaveBeenCalled()
    expect(mocks.closingWizardApiStart).not.toHaveBeenCalled()
    // A hiba után státusz-újralekérdezés történik (mount + refresh = 2 hívás)
    expect(mocks.closingWizardApiGetStatus).toHaveBeenCalledTimes(2)
  })

  it('FR-3 Bugbot-fix: aktív stale-banner mellett a normál indítás-gomb nem érhető el', async () => {
    // A staleWizard-hiányos ág (normál indítás-flow változatlan) fedése:
    // az "activeWizardId=null" teszt assertálja, hogy a start gomb ilyenkor látszik.
    mocks.closingWizardApiGetStatus.mockResolvedValue(statusResponse('wizard-9', 'IN_PROGRESS'))

    renderPage()

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /Folytatás/i })).toBeInTheDocument()
    })
    // A start gomb nem renderelődik — csak a Folytatás / Megszakítás és
    // újraindítás úton lehet továbblépni.
    expect(screen.queryByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })).not.toBeInTheDocument()
  })

  // ============ FR-4: bukó indítás nem hagy beragadt sort ============

  it('FR-4: az 1. lépés bukásakor a wizard megszakításra kerül (cancel hívódik)', async () => {
    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [
        {
          stepNumber: 1,
          completed: false,
          stepDescription: 'MTCN ellenőrzés sikertelen',
          stepData: { message: 'MTCN eltérés' },
        },
      ],
    })

    renderPage()
    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i }))

    await waitFor(() => {
      expect(mocks.closingWizardApiCancel).toHaveBeenCalledWith('wizard-1')
    })
  })

  it('FR-4: kivétel (catch-ág) esetén is megszakításra kerül a wizard', async () => {
    mocks.closingWizardApiNavigate.mockRejectedValue(new Error('Hálózati hiba'))

    renderPage()
    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i }))

    await waitFor(() => {
      expect(mocks.closingWizardApiCancel).toHaveBeenCalledWith('wizard-1')
    })
  })
})
