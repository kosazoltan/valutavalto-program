import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import PosTerminalPage from './PosTerminalPage'

const mockList = vi.fn()
const mockStatus = vi.fn()
const mockGetById = vi.fn()

vi.mock('../../services/api/index', () => ({
  posTerminalApi: {
    list: (...args: unknown[]) => mockList(...args),
    getById: (...args: unknown[]) => mockGetById(...args),
    status: (...args: unknown[]) => mockStatus(...args),
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    error: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

const terminal = {
  id: 'pos-1',
  terminalId: 'TERM-1',
  terminalName: 'Fő kassza POS',
  branchId: 'branch-1',
  branchName: 'Szeged Értéktár',
  isActive: true,
  lastTransactionAt: '2026-06-18T08:00:00Z',
  connectionType: 'SERIAL',
  comPort: 'COM3',
}

describe('PosTerminalPage backend contract', () => {
  beforeEach(() => {
    mockList.mockReset()
    mockStatus.mockReset()
    mockGetById.mockReset()
    mockList.mockResolvedValue([terminal])
    mockGetById.mockResolvedValue({
      ...terminal,
      connectionType: 'TCP',
      ipAddress: '10.0.0.15',
      comPort: undefined,
    })
    mockStatus.mockResolvedValue({
      terminalId: 'TERM-1',
      connected: true,
      active: true,
      reachable: true,
      terminalName: 'Fő kassza POS',
      terminalType: 'SERIAL',
      message: 'OK',
    })
  })

  it('státusz lekérdezéskor meghívja a /pos-terminal-stub/status backend szerződést', async () => {
    render(<PosTerminalPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    fireEvent.click(screen.getAllByRole('button', { name: /Állapot/i })[0]!)

    await waitFor(() => {
      expect(mockStatus).toHaveBeenCalledWith('TERM-1')
      expect(screen.getAllByText('Elérhető').length).toBeGreaterThan(0)
    })
  })

  it('részletek lekérdezésekor meghívja a /pos-terminal/{id} backend szerződést', async () => {
    render(<PosTerminalPage />)

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    fireEvent.click(screen.getAllByRole('button', { name: /Részletek/i })[0]!)

    await waitFor(() => {
      expect(mockGetById).toHaveBeenCalledWith('pos-1')
      expect(screen.getByTestId('pos-terminal-detail-panel')).toBeInTheDocument()
      expect(screen.getAllByText('Fő kassza POS').length).toBeGreaterThan(0)
      expect(screen.getByText('10.0.0.15')).toBeInTheDocument()
    })
  })
})
