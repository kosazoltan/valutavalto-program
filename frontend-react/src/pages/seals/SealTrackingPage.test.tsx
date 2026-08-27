import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SealTrackingPage from './SealTrackingPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => {
      const labels: Record<string, string> = {
        'seals.plombaNyilvantartas': 'Plomba nyilvántartás',
        'seals.plombaSzam': 'Plombaszám',
        'seals.felhelyezve': 'Felhelyezve',
        'seals.eltavolitva': 'Eltávolítva',
        'common.new': 'Új',
        'common.status2': 'Státusz',
        'common.actions': 'Műveletek',
        'common.noData': 'Nincs adat',
        'audit.osszesen': 'Összesen: ',
      }
      return labels[key] ?? key
    },
  }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      worker: { id: 77, branchCode: 'SZEG', branchId: 'branch-1', fullName: 'Teszt Vezető' },
    }),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

const unusedSeal = {
  id: 'seal-unused-1',
  branchId: 'branch-1',
  sealNumber: 'SZEG-20260618-001',
  sealType: 'CLOSE',
  sessionId: null,
  workerId: 77,
  note: null,
  createdAt: '2026-06-18T09:00:00',
  usedAt: null,
}

function renderPage() {
  render(<SealTrackingPage />)
}

describe('SealTrackingPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/seal-tracking/active') {
        return Promise.resolve({
          data: [
            {
              id: 'tracking-1',
              transferType: 'TRANSFER',
              transferId: 1001,
              sealNumber: 'SZEG-20260618-000',
              transitStatus: 'SEALED',
              sealedAt: '2026-06-18T08:30:00',
              sealedBy: 77,
              openedAt: null,
              openedBy: null,
              notes: null,
            },
          ],
        })
      }
      if (path === '/seal-numbers/today') {
        return Promise.resolve({ data: [unusedSeal] })
      }
      if (path === '/seal-numbers/unused') {
        return Promise.resolve({ data: [unusedSeal] })
      }
      return Promise.resolve({ data: null })
    })
    mocks.apiPost.mockResolvedValue({ data: unusedSeal })
  })

  it('betölti a generált és felhasználatlan plombaszámokat a backendről', async () => {
    renderPage()

    await screen.findByText('Generált plombaszámok')

    expect(mocks.apiGet).toHaveBeenCalledWith('/seal-tracking/active')
    expect(mocks.apiGet).toHaveBeenCalledWith('/seal-numbers/today')
    expect(mocks.apiGet).toHaveBeenCalledWith('/seal-numbers/unused')
    expect(screen.getByText('Mai: 1')).toBeInTheDocument()
    expect(screen.getByText('Felhasználatlan: 1')).toBeInTheDocument()
    expect(screen.getAllByText('SZEG-20260618-001').length).toBeGreaterThan(0)
  })

  it('a generálás a SealNumberController generate szerződésére hív', async () => {
    const user = userEvent.setup()
    renderPage()

    await screen.findByText('Generált plombaszámok')
    await user.type(screen.getByLabelText('Plombaszám megjegyzés'), 'zárási plomba')
    await user.click(screen.getByRole('button', { name: 'Generálás' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/seal-numbers/generate', {
        branchCode: 'SZEG',
        sealType: 'CLOSE',
        sessionId: null,
        note: 'zárási plomba',
      })
    })
  })

  it('a felhasználás rögzítése a SealNumberController use szerződésére hív', async () => {
    const user = userEvent.setup()
    renderPage()

    await screen.findByText('Generált plombaszámok')
    await user.click(screen.getByRole('button', { name: 'Felhasználva' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/seal-numbers/seal-unused-1/use')
    })
  })
})
