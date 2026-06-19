import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CircularPage from './CircularPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

vi.mock('@/services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: vi.fn(),
    error: vi.fn(),
  },
}))

const activeCircular = {
  id: 1,
  title: 'Aktív szabályzat',
  content: 'Aktív tartalom',
  createdByName: 'Központ',
  circularType: 'GENERAL',
  priority: 'NORMAL',
  registrationNumber: 'KOR-2026-000',
  createdAt: '2026-06-18T08:00:00',
  acknowledgmentCount: 0,
}

const relevantCircular = {
  ...activeCircular,
  id: 2,
  title: 'Szegedi irodai utasítás',
  registrationNumber: 'SZG-2026-001',
  priority: 'HIGH',
}

const searchedCircular = {
  ...activeCircular,
  id: 3,
  title: 'Iktatott biztonsági körlevél',
  registrationNumber: 'KOR-2026-001',
  priority: 'URGENT',
}

const legacyUnacknowledgedCircular = {
  ...activeCircular,
  id: 4,
  title: 'Globális nyugtázatlan körlevél',
  registrationNumber: 'LEG-2026-001',
}

describe('CircularPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/circulars/types') {
        return Promise.resolve({
          data: [
            {
              type: 'GENERAL',
              description: 'Általános utasítás',
              defaultTarget: 'ALL_BRANCHES',
              defaultPriority: 'NORMAL',
            },
          ],
        })
      }
      if (path === '/circulars/my-unacknowledged') return Promise.resolve({ data: [] })
      if (path === '/circulars/unacknowledged') return Promise.resolve({ data: [legacyUnacknowledgedCircular] })
      if (path === '/circulars/active') return Promise.resolve({ data: [activeCircular] })
      if (path === '/circulars/relevant') return Promise.resolve({ data: [relevantCircular] })
      if (path === '/circulars/search') return Promise.resolve({ data: [searchedCircular] })
      return Promise.resolve({ data: [] })
    })
    mocks.apiPost.mockResolvedValue({ data: activeCircular })
  })

  it('beköti az irodához releváns listát és az iktatószámos backend keresést', async () => {
    render(<CircularPage />)

    await screen.findByText('Aktív szabályzat')

    fireEvent.click(screen.getByRole('button', { name: 'Irodához releváns' }))

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/circulars/relevant')
      expect(screen.getByText('Szegedi irodai utasítás')).toBeInTheDocument()
    })

    fireEvent.change(screen.getByPlaceholderText('Keresés iktatószám, cím, típus vagy készítő alapján'), {
      target: { value: 'KOR-2026-001' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Iktatószám keresés' }))

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/circulars/search', { params: { q: 'KOR-2026-001' } })
      expect(screen.getByText('Iktatott biztonsági körlevél')).toBeInTheDocument()
      expect(screen.getByText('Backend iktatószám keresés eredménye: 1 dokumentum')).toBeInTheDocument()
    })
  })

  it('beköti a legacy unacknowledged listát, a globális acknowledge végpontot és az egyszerű create végpontot', async () => {
    render(<CircularPage />)

    await screen.findByText('Globálisan nem nyugtázott körlevelek: 1')

    expect(mocks.apiGet).toHaveBeenCalledWith('/circulars/unacknowledged')
    fireEvent.click(screen.getByRole('button', { name: 'Globális nyugtázás' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/circulars/4/acknowledge')
    })

    fireEvent.click(screen.getByRole('button', { name: 'Új dokumentum' }))
    fireEvent.change(screen.getByLabelText('Cím'), { target: { value: 'Egyszerű körlevél' } })
    fireEvent.change(screen.getByLabelText('Tartalom'), { target: { value: 'Egyszerű körlevél tartalma' } })
    fireEvent.click(screen.getByRole('button', { name: 'Létrehozás' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/circulars', {
        title: 'Egyszerű körlevél',
        content: 'Egyszerű körlevél tartalma',
        urgent: false,
        requiresAcknowledgment: false,
      })
    })
  })
})
