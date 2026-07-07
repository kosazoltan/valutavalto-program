import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import IncomeProofRecipientsPanel from './IncomeProofRecipientsPanel'

const mocks = vi.hoisted(() => ({
  getRecipients: vi.fn(),
  putRecipients: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/incomeSourceDocs', () => ({
  incomeSourceDocApi: {
    getRecipients: mocks.getRecipients,
    putRecipients: mocks.putRecipients,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

describe('IncomeProofRecipientsPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getRecipients.mockResolvedValue({ recipients: ['a@x.hu', 'b@y.hu'] })
    mocks.putRecipients.mockResolvedValue({ recipients: ['a@x.hu', 'b@y.hu', 'c@z.hu'], count: 3 })
  })

  it('loads and displays recipients from GET', async () => {
    render(<IncomeProofRecipientsPanel />)

    expect(screen.getByText('Címzettek betöltése...')).toBeInTheDocument()
    expect(await screen.findByText('a@x.hu')).toBeInTheDocument()
    expect(screen.getByText('b@y.hu')).toBeInTheDocument()
  })

  it('load error calls toast.error', async () => {
    mocks.getRecipients.mockRejectedValue(new Error('network'))

    render(<IncomeProofRecipientsPanel />)

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Betöltési hiba', 'network')
    })
  })

  it('invalid email add calls validation toast and does not add', async () => {
    const user = userEvent.setup()
    render(<IncomeProofRecipientsPanel />)

    await screen.findByText('a@x.hu')
    await user.type(screen.getByPlaceholderText('email@cim.hu'), 'rossz-email')
    await user.click(screen.getByRole('button', { name: 'Hozzáadás' }))

    expect(mocks.toastError).toHaveBeenCalledWith(
      'Validációs hiba',
      expect.stringContaining('érvénytelen'),
    )
    expect(screen.queryByText('rossz-email')).not.toBeInTheDocument()
  })

  it('duplicate email add calls validation toast', async () => {
    const user = userEvent.setup()
    render(<IncomeProofRecipientsPanel />)

    await screen.findByText('a@x.hu')
    await user.type(screen.getByPlaceholderText('email@cim.hu'), 'A@X.HU')
    await user.click(screen.getByRole('button', { name: 'Hozzáadás' }))

    expect(mocks.toastError).toHaveBeenCalledWith(
      'Validációs hiba',
      expect.stringContaining('már szerepel'),
    )
  })

  it('max 20 recipients blocks adding extra recipient', async () => {
    const user = userEvent.setup()
    mocks.getRecipients.mockResolvedValue({
      recipients: Array.from({ length: 20 }, (_value, index) => `user${index + 1}@x.hu`),
    })

    render(<IncomeProofRecipientsPanel />)

    await screen.findByText('user20@x.hu')
    await user.type(screen.getByPlaceholderText('email@cim.hu'), 'extra@x.hu')
    await user.click(screen.getByRole('button', { name: 'Hozzáadás' }))

    expect(mocks.toastError).toHaveBeenCalledWith(
      'Validációs hiba',
      expect.stringContaining('Maximum 20'),
    )
    expect(screen.queryByText('extra@x.hu')).not.toBeInTheDocument()
  })

  it('successful save after adding recipient calls PUT and success toast', async () => {
    const user = userEvent.setup()
    render(<IncomeProofRecipientsPanel />)

    await screen.findByText('a@x.hu')
    await user.type(screen.getByPlaceholderText('email@cim.hu'), 'c@z.hu')
    await user.click(screen.getByRole('button', { name: 'Hozzáadás' }))
    await user.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => {
      expect(mocks.putRecipients).toHaveBeenCalledWith(['a@x.hu', 'b@y.hu', 'c@z.hu'])
    })
    expect(mocks.toastSuccess).toHaveBeenCalledWith('Mentve', '3 címzett elmentve')
    expect(await screen.findByText('c@z.hu')).toBeInTheDocument()
  })

  it('PUT error calls save failure toast', async () => {
    const user = userEvent.setup()
    mocks.putRecipients.mockRejectedValue('400')

    render(<IncomeProofRecipientsPanel />)

    await screen.findByText('a@x.hu')
    await user.click(
      within(screen.getByTestId('recipient-row-a@x.hu')).getByRole('button', { name: /Törlés/i }),
    )
    await user.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Mentés sikertelen', '400')
    })
  })

  it('empty list save sends { recipients: [] } and shows success toast', async () => {
    const user = userEvent.setup()
    mocks.getRecipients.mockResolvedValue({ recipients: ['a@x.hu'] })
    mocks.putRecipients.mockResolvedValue({ recipients: [], count: 0 })

    render(<IncomeProofRecipientsPanel />)

    await screen.findByText('a@x.hu')
    await user.click(
      within(screen.getByTestId('recipient-row-a@x.hu')).getByRole('button', { name: /Törlés/i }),
    )
    await screen.findByText('Nincs beállított címzett.')
    await user.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => {
      expect(mocks.putRecipients).toHaveBeenCalledWith([])
    })
    expect(mocks.toastSuccess).toHaveBeenCalledWith('Mentve', '0 címzett elmentve')
  })

  it('trim and case-insensitive dedup rejects whitespace-padded duplicate', async () => {
    const user = userEvent.setup()
    mocks.getRecipients.mockResolvedValue({ recipients: ['A@X.hu'] })

    render(<IncomeProofRecipientsPanel />)

    await screen.findByText('A@X.hu')
    await user.type(screen.getByPlaceholderText('email@cim.hu'), '  a@x.hu  ')
    await user.click(screen.getByRole('button', { name: 'Hozzáadás' }))

    expect(mocks.toastError).toHaveBeenCalledWith(
      'Validációs hiba',
      expect.stringContaining('már szerepel'),
    )
    // list still has exactly one entry
    expect(screen.getAllByText('A@X.hu')).toHaveLength(1)
  })
})
