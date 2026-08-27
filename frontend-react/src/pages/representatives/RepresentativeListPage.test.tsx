import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RepresentativeListPage from './RepresentativeListPage'

const mockFindByCustomer = vi.fn()
const mockList = vi.fn()

vi.mock('../../services/api/transactions', () => ({
  authorizedRepresentativeApi: {
    findByCustomer: (...args: unknown[]) => mockFindByCustomer(...args),
    list: (...args: unknown[]) => mockList(...args),
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

const representative = {
  id: 'rep-1',
  customerId: '42',
  customerName: '',
  firstName: 'Pál',
  lastName: 'Kovács',
  fullName: 'Kovács Pál',
  documentNumber: 'AB123456',
  documentTypeDid: 'Személyi igazolvány',
  relationshipDid: 'BUSINESS',
  authorizationStart: '2026-01-01',
  authorizationEnd: undefined,
  isActive: true,
  registeredAt: '2026-01-01T08:00:00Z',
}

describe('RepresentativeListPage backend contract', () => {
  beforeEach(() => {
    mockFindByCustomer.mockReset()
    mockList.mockReset()
    mockFindByCustomer.mockResolvedValue([representative])
    mockList.mockResolvedValue([representative])
  })

  it('globális listanézetben a top-level /authorized-representatives API-t használja', async () => {
    render(
      <MemoryRouter initialEntries={['/representatives']}>
        <Routes>
          <Route path="/representatives" element={<RepresentativeListPage />} />
        </Routes>
      </MemoryRouter>,
    )

    await waitFor(() => expect(mockList).toHaveBeenCalledTimes(1))

    expect(mockFindByCustomer).not.toHaveBeenCalled()
    expect((await screen.findAllByText('Kovács Pál')).length).toBeGreaterThan(0)
    expect(screen.getAllByText('42').length).toBeGreaterThan(0)
  })

  it('ügyfélhez kötött nézetben megtartja a customer route API-hívását', async () => {
    render(
      <MemoryRouter initialEntries={['/customers/42/representatives']}>
        <Routes>
          <Route
            path="/customers/:customerId/representatives"
            element={<RepresentativeListPage />}
          />
        </Routes>
      </MemoryRouter>,
    )

    await waitFor(() => expect(mockFindByCustomer).toHaveBeenCalledWith('42'))

    expect(mockList).not.toHaveBeenCalled()
    expect((await screen.findAllByText('Kovács Pál')).length).toBeGreaterThan(0)
  })
})
