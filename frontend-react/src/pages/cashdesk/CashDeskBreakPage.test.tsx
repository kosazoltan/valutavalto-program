import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CashDeskBreakPage from './CashDeskBreakPage'

const mocks = vi.hoisted(() => ({
  cashDeskList: vi.fn(),
  breakList: vi.fn(),
  getActive: vi.fn(),
  start: vi.fn(),
  end: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

vi.mock('../../services/api/index', () => ({
  cashDeskApi: {
    list: mocks.cashDeskList,
  },
  cashDeskBreakApi: {
    list: mocks.breakList,
    getActive: mocks.getActive,
    start: mocks.start,
    end: mocks.end,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    warning: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

describe('CashDeskBreakPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.cashDeskList.mockResolvedValue([
      { id: 'cashdesk-1', name: 'Szeged pénztár', isActive: true },
    ])
    mocks.breakList.mockResolvedValue([])
    mocks.getActive.mockResolvedValue({
      id: 'break-1',
      cashDeskId: 'cashdesk-1',
      cashDeskName: 'Szeged pénztár',
      breakStart: '2026-06-19T09:00:00',
      breakType: 'LUNCH',
      reason: 'Ebéd',
      isActive: true,
    })
  })

  it('a kiválasztott pénztárhoz lekéri és megjeleníti az aktív szünet endpoint válaszát', async () => {
    render(<CashDeskBreakPage />)

    await waitFor(() => expect(mocks.breakList).toHaveBeenCalledWith('cashdesk-1'))
    await waitFor(() => expect(mocks.getActive).toHaveBeenCalledWith('cashdesk-1'))

    expect(await screen.findByText('cashdesk.aktivSzunet')).toBeInTheDocument()
    expect(screen.getByText('cashdesk.tipusLUNCH')).toBeInTheDocument()
    expect(screen.getByText('cashdesk.ok Ebéd')).toBeInTheDocument()
  })
})
