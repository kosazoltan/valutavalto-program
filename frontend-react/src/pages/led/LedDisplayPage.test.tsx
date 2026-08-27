import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import LedDisplayPage from './LedDisplayPage'
import { api } from '../../services/api/index'

vi.mock('../../services/api/index', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
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

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
  put: ReturnType<typeof vi.fn>
}

describe('LedDisplayPage backend contract', () => {
  beforeEach(() => {
    mockApi.get.mockReset()
    mockApi.post.mockReset()
    mockApi.put.mockReset()
    mockApi.post.mockResolvedValue({ data: {} })
    mockApi.put.mockResolvedValue({ data: {} })
    mockApi.get.mockImplementation((url: string) => {
      if (url === '/led-display/status') {
        return Promise.resolve({
          data: [
            {
              branchId: 'branch-1',
              branchName: 'Szeged kijelző',
              connected: true,
              lastRefresh: '2026-06-18T08:00:00Z',
            },
          ],
        })
      }
      if (url === '/led/status') {
        return Promise.resolve({
          data: [
            {
              branchId: 'branch-1',
              displayType: 'RATE_BOARD',
              content: 'EUR 390/402',
              lastUpdated: '2026-06-18T08:05:00Z',
            },
          ],
        })
      }
      if (url === '/led/config/branch-1') {
        return Promise.resolve({
          data: {
            displayType: 'NETWORK',
            connectionString: '192.168.1.50:9100',
            displayedCurrencies: 'EUR,USD',
          },
        })
      }
      if (url === '/led-display/config/branch-1') {
        return Promise.resolve({
          data: {
            displayType: 'SERIAL',
            comPorts: 'COM1',
            currencies: 'EUR,USD',
          },
        })
      }
      if (url === '/led/content/branch-1') {
        return Promise.resolve({
          data: [
            {
              currencyCode: 'EUR',
              buyRate: 390,
              sellRate: 402,
              unit: 1,
            },
          ],
        })
      }
      if (url === '/led-display/status/branch-1') {
        return Promise.resolve({
          data: {
            branchId: 'branch-1',
            branchName: 'Szeged kijelző',
            connected: true,
            lastRefresh: '2026-06-18T08:30:00Z',
          },
        })
      }
      return Promise.resolve({ data: null })
    })
  })

  it('konfiguráció megnyitásakor lekéri a kijelző tartalmat és a részletes fizikai státuszt', async () => {
    render(<LedDisplayPage />)

    await screen.findAllByText('Szeged kijelző')

    fireEvent.click(screen.getAllByTitle('Szerkesztés')[0]!)

    await waitFor(() => {
      expect(mockApi.get).toHaveBeenCalledWith('/led/status', {
        params: { branchId: 'branch-1' },
      })
      expect(mockApi.get).toHaveBeenCalledWith('/led/content/branch-1')
      expect(mockApi.get).toHaveBeenCalledWith('/led/config/branch-1')
      expect(mockApi.get).toHaveBeenCalledWith('/led-display/config/branch-1')
      expect(mockApi.get).toHaveBeenCalledWith('/led-display/status/branch-1')
      expect(screen.getByText('Kijelző tartalom előnézet')).toBeInTheDocument()
      expect(screen.getByTestId('led-serial-status-panel')).toHaveTextContent('Online')
      expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
    })
  })

  it('frissítéskor a /led árfolyamtábla és a led-display fizikai frissítés végpontokat is hívja', async () => {
    render(<LedDisplayPage />)

    await screen.findAllByText('Szeged kijelző')

    fireEvent.click(screen.getAllByTitle('Frissítés').at(-1)!)

    await waitFor(() => {
      expect(mockApi.post).toHaveBeenCalledWith('/led/update/branch-1')
      expect(mockApi.post).toHaveBeenCalledWith('/led/rate-board/update', null, {
        params: { branchId: 'branch-1' },
      })
      expect(mockApi.post).toHaveBeenCalledWith('/led-display/refresh/branch-1')
    })
  })

  it('mentéskor és szövegküldéskor a /led konfigurációs és futószöveg végpontokat is hívja', async () => {
    render(<LedDisplayPage />)

    await screen.findAllByText('Szeged kijelző')
    fireEvent.click(screen.getAllByTitle('Szerkesztés')[0]!)
    await screen.findByText('LED konfiguráció')

    fireEvent.click(screen.getByText('Mentés'))

    await waitFor(() => {
      expect(mockApi.put).toHaveBeenCalledWith(
        '/led/config',
        expect.objectContaining({
          branchId: 'branch-1',
          displayType: 'SERIAL',
        }),
      )
      expect(mockApi.put).toHaveBeenCalledWith(
        '/led-display/config/branch-1',
        expect.objectContaining({
          branchId: 'branch-1',
          displayType: 'SERIAL',
        }),
      )
    })

    fireEvent.click(screen.getAllByTitle('Szerkesztés')[0]!)
    await screen.findByText('LED konfiguráció')
    fireEvent.change(screen.getByLabelText('Egyéni szöveg'), {
      target: { value: 'Akciós árfolyam' },
    })
    fireEvent.click(screen.getByText('Szöveg küldése'))

    await waitFor(() => {
      expect(mockApi.post).toHaveBeenCalledWith(
        '/led/scrolling-text',
        { text: 'Akciós árfolyam' },
        {
          params: { branchId: 'branch-1' },
        },
      )
      expect(mockApi.post).toHaveBeenCalledWith('/led-display/text/branch-1', 'Akciós árfolyam', {
        headers: { 'Content-Type': 'text/plain' },
      })
    })
  })
})
