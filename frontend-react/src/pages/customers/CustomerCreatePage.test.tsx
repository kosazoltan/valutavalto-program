import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CustomerCreatePage from './CustomerCreatePage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  customerCreate: vi.fn(),
  teaorSearch: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../../services/api/transactions', () => ({
  customerApi: {
    create: (...args: unknown[]) => mocks.customerCreate(...args),
  },
  teaorApi: {
    search: (...args: unknown[]) => mocks.teaorSearch(...args),
  },
}))

function renderPage() {
  return render(
    <MemoryRouter>
      <CustomerCreatePage />
    </MemoryRouter>,
  )
}

describe('CustomerCreatePage compliance controls', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.customerCreate.mockResolvedValue({ id: 42, name: 'Kiss János' })
    mocks.teaorSearch.mockResolvedValue([])
  })

  it('PEP választás és adatkezelési acknowledge nélkül nem engedi a mentést', () => {
    renderPage()

    expect(screen.getByTestId('customer-create-save-button')).toBeDisabled()
    expect(screen.getByTestId('customer-is-pep-select')).toBeRequired()
    expect(screen.getByTestId('customer-privacy-notice-checkbox')).toBeRequired()
  })

  it('sikeres mentéskor PEP státuszt és adatkezelési acknowledge marker-t küld', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(screen.getByTestId('customer-create-name-input'), 'Kiss János')
    await user.type(screen.getByTestId('customer-create-birth-date-input'), '1990-01-15')
    await user.type(screen.getByTestId('customer-create-mother-name-input'), 'Nagy Éva')
    await user.type(screen.getByTestId('customer-create-document-number-input'), '123456AB')
    await user.type(screen.getByTestId('customer-create-postal-code-input'), '1051')
    await user.type(screen.getByTestId('customer-create-city-input'), 'Budapest')
    await user.type(screen.getByTestId('customer-create-address-input'), 'Fő utca 1.')
    await user.selectOptions(screen.getByTestId('customer-is-pep-select'), 'false')
    await user.click(screen.getByTestId('customer-privacy-notice-checkbox'))

    await user.click(screen.getByTestId('customer-create-save-button'))

    await waitFor(() => expect(mocks.customerCreate).toHaveBeenCalled())
    expect(mocks.customerCreate).toHaveBeenCalledWith(expect.objectContaining({
      isPep: false,
      notes: expect.stringContaining('ADATKEZELESI_TAJEKOZTATO_ACK v2026-06-09'),
    }))
    expect(mocks.navigate).toHaveBeenCalledWith('/customers/42')
  })
})
