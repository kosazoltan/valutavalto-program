import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import PosTerminalPage from './PosTerminalPage'

const mockList = vi.fn()
const mockStatus = vi.fn()

vi.mock('../../services/api/index', () => ({
  posTerminalApi: {
    list: (...args: unknown[]) => mockList(...args),
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
    mockList.mockResolvedValue([terminal])
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
})
