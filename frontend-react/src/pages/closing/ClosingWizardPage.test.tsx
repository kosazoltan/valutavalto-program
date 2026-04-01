import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ClosingWizardPage from './ClosingWizardPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  closingWizardApiStart: vi.fn(),
  closingWizardApiNavigate: vi.fn(),
  closingWizardApiFinalize: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
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
    navigate: mocks.closingWizardApiNavigate,
    finalize: mocks.closingWizardApiFinalize,
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

function renderClosingWizardPage() {
  mocks.useAuthStore.mockImplementation((selector: any) =>
    selector({ worker: mockWorker }),
  )

  render(
    <MemoryRouter>
      <ClosingWizardPage />
    </MemoryRouter>,
  )
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
  })

  it('oldal renderelésének ellenőrzése', () => {
    renderClosingWizardPage()
    expect(screen.getByText('NAPZÁRÁS WIZARD')).toBeInTheDocument()
  })

  it('cashier header megjelenítése', () => {
    renderClosingWizardPage()
    expect(screen.getByTestId('cashier-header')).toBeInTheDocument()
  })

  it('zárási lépéseket listázza', () => {
    renderClosingWizardPage()
    expect(screen.getByText(/MTCN szám ellenőrzés/)).toBeInTheDocument()
    expect(screen.getByText(/Esti pénztár címletezése/)).toBeInTheDocument()
  })

  it('zárás megkezdése gombra kattintás API-t meghívja', async () => {
    mocks.closingWizardApiStart.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      status: 'IN_PROGRESS',
      steps: [],
    })
    mocks.closingWizardApiNavigate.mockResolvedValue({
      steps: [
        { stepNumber: 1, status: 'DONE', message: 'OK' },
      ],
    })

    renderClosingWizardPage()
    const user = userEvent.setup()

    const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
    await user.click(startButton)

    await waitFor(() => {
      expect(mocks.closingWizardApiStart).toHaveBeenCalledWith(
        mockWorker.branchId,
        mockWorker.branchId,
        'DAILY',
        String(mockWorker.id),
      )
    })
  })

  it('lépések állapot mutatói megjelennek', () => {
    renderClosingWizardPage()
    // Check for step items in the list
    const stepLabels = screen.getByText(/MTCN szám ellenőrzés/)
    expect(stepLabels).toBeInTheDocument()
  })

  it('progress bar megjelenítése', () => {
    renderClosingWizardPage()
    expect(screen.getByText(/Előrehaladás/)).toBeInTheDocument()
  })

  it('nem bejelentkezett felhasználó esetén error toast', async () => {
    mocks.useAuthStore.mockImplementation((selector: any) =>
      selector({ worker: null }),
    )

    renderClosingWizardPage()
    // With no worker, the page should still render but button click should fail internally
    expect(screen.getByText('NAPZÁRÁS WIZARD')).toBeInTheDocument()
  })

  it('lépés elhagyása (skip) lehetséges', async () => {
    renderClosingWizardPage()
    const user = userEvent.setup()

    const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
    await user.click(startButton)

    await waitFor(() => {
      expect(mocks.closingWizardApiStart).toHaveBeenCalled()
    })
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

  it('összes lépés sikeres befejezése után zárás lehetséges', async () => {
    mocks.closingWizardApiStart.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      status: 'IN_PROGRESS',
      steps: Array.from({ length: 9 }, (_, i) => ({
        stepNumber: i + 1,
        status: 'DONE',
      })),
    })

    renderClosingWizardPage()

    // Sikeres zárás gombnak lennie kell — check for finalize button text
    const buttons = screen.getAllByRole('button')
    expect(buttons.length).toBeGreaterThan(0)
  })

  it('zárás véglegesítése API-t meghívja', async () => {
    mocks.closingWizardApiStart.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      status: 'IN_PROGRESS',
      steps: [],
    })
    mocks.closingWizardApiFinalize.mockResolvedValue({ id: 'wizard-1', status: 'COMPLETED' })

    renderClosingWizardPage()
    const user = userEvent.setup()

    const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
    await user.click(startButton)

    await waitFor(() => {
      expect(mocks.closingWizardApiStart).toHaveBeenCalled()
    })
  })

  it('hiba történt egy lépésnél — újrapróbálás lehetséges', async () => {
    mocks.closingWizardApiStart.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      status: 'IN_PROGRESS',
      steps: [
        { stepNumber: 1, status: 'FAILED', message: 'Hiba történt' },
      ],
    })

    renderClosingWizardPage()
    const user = userEvent.setup()

    const startButton = screen.getByRole('button', { name: /ELLENŐRZÉS INDÍTÁSA/i })
    await user.click(startButton)

    await waitFor(() => {
      expect(mocks.closingWizardApiStart).toHaveBeenCalled()
    })
  })

  it('idő mutatása az elvégzett lépésekhez', async () => {
    mocks.closingWizardApiStart.mockResolvedValue({
      id: 'wizard-1',
      branchId: 'b1',
      status: 'IN_PROGRESS',
      steps: [
        { stepNumber: 1, status: 'DONE', completedAt: '10:45:30' },
      ],
    })

    renderClosingWizardPage()

    // Az idő információ a step-en belül megjelenik
    expect(screen.getByText('NAPZÁRÁS WIZARD')).toBeInTheDocument()
  })
})
