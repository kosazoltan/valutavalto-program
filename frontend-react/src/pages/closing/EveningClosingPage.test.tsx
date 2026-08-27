import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import EveningClosingPage from './EveningClosingPage'

const mocks = vi.hoisted(() => ({
  preview: vi.fn(),
  send: vi.fn(),
  report: vi.fn(),
  getStatus: vi.fn(),
  navigate: vi.fn(),
  toastWarning: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
  loggerError: vi.fn(),
}))

const authState = vi.hoisted(() => ({
  worker: {
    id: 77,
    workerCode: 'ADMIN',
    firstName: 'Admin',
    lastName: 'Teszt',
    fullName: 'Admin Teszt',
    role: 'ADMIN',
    branchId: 'branch-1',
    branchCode: 'BUD01',
    branchName: 'Budapest 01',
    companyId: 'company-1',
    companyCode: 'EBC',
    companyName: 'Exclusive Best Change',
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../utils/dateFormat', () => ({
  localIsoDate: () => '2026-06-18',
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) => selector(authState),
}))

vi.mock('react-router-dom', () => ({
  Link: ({ to, children }: { to: string; children: ReactNode }) => <a href={to}>{children}</a>,
  useNavigate: () => mocks.navigate,
}))

vi.mock('../../services/api/index', () => ({
  eveningClosingApi: {
    preview: mocks.preview,
    send: mocks.send,
    report: mocks.report,
  },
  // FKH-036 WU-3: az oldal mountkor (auto-load) a closing-státuszt is lekéri.
  closingWizardApi: { getStatus: mocks.getStatus },
}))

vi.mock('../../components/closing/VaultClosingChecklistPanel', () => ({
  default: () => <div data-testid="vault-closing-checklist" />,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    warning: mocks.toastWarning,
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

describe('EveningClosingPage report backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.report.mockResolvedValue({
      branchId: 1,
      date: '2026-06-18',
      totalTransactionCount: 7,
      buyCount: 4,
      sellCount: 2,
      reversalCount: 1,
      conversionCount: 0,
      totalBuyHuf: 120000,
      totalSellHuf: 90000,
      totalHandlingFees: 1500,
      netTurnover: -30000,
      currencyBreakdown: {
        EUR: 80000,
        USD: 40000,
      },
    })
  })

  it('a Napi jelentés gomb a GET /evening-closing/{branchId}/{date}/report backend wrapperre köt', async () => {
    const user = userEvent.setup()
    render(<EveningClosingPage />)

    await user.click(screen.getByRole('button', { name: /Napi jelentés/i }))

    await waitFor(() => {
      expect(mocks.report).toHaveBeenCalledWith('branch-1', '2026-06-18')
    })
    expect(await screen.findByTestId('evening-closing-report-panel')).toBeInTheDocument()
    expect(screen.getByText('7')).toBeInTheDocument()
    expect(screen.getByText('EUR')).toBeInTheDocument()
    expect(screen.getByText('USD')).toBeInTheDocument()
    expect(screen.getByText(/Sztornó: 1/)).toBeInTheDocument()
  })
})
