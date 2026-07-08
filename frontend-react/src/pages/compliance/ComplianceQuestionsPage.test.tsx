import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ComplianceQuestionsPage from './ComplianceQuestionsPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  setActive: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/complianceQuestions', () => ({
  complianceQuestionApi: {
    list: mocks.list,
    create: mocks.create,
    update: mocks.update,
    setActive: mocks.setActive,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: { success: mocks.toastSuccess, error: mocks.toastError },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: mocks.loggerError, warn: vi.fn() },
}))

const q = (over: Record<string, unknown> = {}) => ({
  id: 'id-1',
  questionText: 'Politikai közszereplő-e Ön?',
  questionType: 'YES_NO',
  displayOrder: 1,
  active: true,
  createdByWorkerCode: 'W001',
  createdAt: '2026-07-08T10:00:00',
  updatedAt: '2026-07-08T10:00:00',
  ...over,
})

beforeEach(() => {
  vi.clearAllMocks()
  mocks.list.mockResolvedValue([q()])
  mocks.create.mockResolvedValue(q({ id: 'id-2', questionType: 'FREE_TEXT', displayOrder: null }))
  mocks.update.mockResolvedValue(q({ questionText: 'Módosított kérdés' }))
  mocks.setActive.mockResolvedValue(q({ active: false }))
})

describe('ComplianceQuestionsPage', () => {
  it('loads_and_displays_questions', async () => {
    render(<ComplianceQuestionsPage />)

    const row = await screen.findByTestId('question-row-id-1')
    expect(within(row).getByText('Politikai közszereplő-e Ön?')).toBeInTheDocument()
    expect(within(row).getByText('Igen/Nem')).toBeInTheDocument()
    expect(screen.getByTestId('active-badge-id-1')).toHaveTextContent('Aktív')
    expect(mocks.list).toHaveBeenCalledTimes(1)
  })

  it('load_error_shows_toast', async () => {
    mocks.list.mockRejectedValue(new Error('network'))

    render(<ComplianceQuestionsPage />)

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Betöltési hiba', 'network')
    })
    expect(screen.getByText('Nincs rögzített compliance-kérdés.')).toBeInTheDocument()
  })

  it('create_button_disabled_until_valid', async () => {
    const user = userEvent.setup()
    render(<ComplianceQuestionsPage />)

    await screen.findByText('Politikai közszereplő-e Ön?')
    const submit = screen.getByTestId('submit-question')
    expect(submit).toBeDisabled()

    await user.type(screen.getByTestId('question-text-input'), 'Új kérdés')
    expect(submit).toBeDisabled()

    await user.selectOptions(screen.getByTestId('question-type-select'), 'YES_NO')
    expect(submit).toBeEnabled()
  })

  it('create_success_posts_and_reloads', async () => {
    const user = userEvent.setup()
    render(<ComplianceQuestionsPage />)

    await screen.findByText('Politikai közszereplő-e Ön?')
    await user.type(screen.getByTestId('question-text-input'), 'Új szabad kérdés')
    await user.selectOptions(screen.getByTestId('question-type-select'), 'FREE_TEXT')
    await user.click(screen.getByTestId('submit-question'))

    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalledWith({
        questionText: 'Új szabad kérdés',
        questionType: 'FREE_TEXT',
        displayOrder: null,
      })
    })
    expect(mocks.toastSuccess).toHaveBeenCalledWith('Kérdés létrehozva')
    await waitFor(() => expect(mocks.list).toHaveBeenCalledTimes(2))
    expect(screen.getByTestId('question-text-input')).toHaveValue('')
    expect(screen.getByTestId('question-type-select')).toHaveValue('')
  })

  it('create_error_shows_toast', async () => {
    const user = userEvent.setup()
    mocks.create.mockRejectedValue(new Error('hiba'))
    render(<ComplianceQuestionsPage />)

    await screen.findByText('Politikai közszereplő-e Ön?')
    await user.type(screen.getByTestId('question-text-input'), 'Új kérdés')
    await user.selectOptions(screen.getByTestId('question-type-select'), 'YES_NO')
    await user.click(screen.getByTestId('submit-question'))

    await waitFor(() => {
      expect(mocks.toastError).toHaveBeenCalledWith('Mentés sikertelen', 'hiba')
    })
  })

  it('invalid_displayOrder_disables_submit', async () => {
    const user = userEvent.setup()
    render(<ComplianceQuestionsPage />)

    await screen.findByText('Politikai közszereplő-e Ön?')
    await user.type(screen.getByTestId('question-text-input'), 'Új kérdés')
    await user.selectOptions(screen.getByTestId('question-type-select'), 'FREE_TEXT')
    await user.type(screen.getByTestId('display-order-input'), '0')

    expect(screen.getByTestId('submit-question')).toBeDisabled()
    expect(screen.getByText('A sorrend pozitív egész szám lehet')).toBeInTheDocument()

    await user.clear(screen.getByTestId('display-order-input'))
    await user.type(screen.getByTestId('display-order-input'), '2')
    expect(screen.getByTestId('submit-question')).toBeEnabled()
  })

  it('edit_populates_form_and_puts', async () => {
    const user = userEvent.setup()
    render(<ComplianceQuestionsPage />)

    const row = await screen.findByTestId('question-row-id-1')
    await user.click(within(row).getByRole('button', { name: 'Szerkesztés' }))

    expect(screen.getByTestId('question-text-input')).toHaveValue('Politikai közszereplő-e Ön?')
    expect(screen.getByTestId('question-type-select')).toHaveValue('YES_NO')
    expect(screen.getByTestId('display-order-input')).toHaveValue(1)
    expect(screen.getByTestId('submit-question')).toHaveTextContent('Mentés')

    await user.click(screen.getByRole('button', { name: 'Mégse' }))
    expect(screen.getByTestId('submit-question')).toHaveTextContent('Létrehozás')

    await user.click(within(row).getByRole('button', { name: 'Szerkesztés' }))
    await user.clear(screen.getByTestId('question-text-input'))
    await user.type(screen.getByTestId('question-text-input'), 'Módosított kérdés')
    await user.click(screen.getByTestId('submit-question'))

    await waitFor(() => {
      expect(mocks.update).toHaveBeenCalledWith('id-1', {
        questionText: 'Módosított kérdés',
        questionType: 'YES_NO',
        displayOrder: 1,
      })
    })
  })

  it('toggle_active_calls_setActive', async () => {
    const user = userEvent.setup()
    render(<ComplianceQuestionsPage />)

    const row = await screen.findByTestId('question-row-id-1')
    await user.click(within(row).getByTestId('toggle-active-id-1'))

    await waitFor(() => {
      expect(mocks.setActive).toHaveBeenCalledWith('id-1', false)
    })
    expect(screen.getByTestId('active-badge-id-1')).toHaveTextContent('Inaktív')
    expect(
      within(screen.getByTestId('question-row-id-1')).getByRole('button', { name: 'Aktiválás' }),
    ).toBeInTheDocument()
  })

  it('list_sorted_by_displayOrder_nulls_last', async () => {
    mocks.list.mockResolvedValue([
      q({
        id: 'id-order-2',
        questionText: 'Második',
        displayOrder: 2,
        createdAt: '2026-07-08T10:00:00',
      }),
      q({
        id: 'id-order-null',
        questionText: 'Sorrend nélkül',
        displayOrder: null,
        createdAt: '2026-07-08T09:00:00',
      }),
      q({
        id: 'id-order-1',
        questionText: 'Első',
        displayOrder: 1,
        createdAt: '2026-07-08T11:00:00',
      }),
    ])

    render(<ComplianceQuestionsPage />)

    await screen.findByText('Első')
    const rowIds = screen
      .getAllByTestId(/^question-row-/)
      .map((row) => row.getAttribute('data-testid'))
    expect(rowIds).toEqual([
      'question-row-id-order-1',
      'question-row-id-order-2',
      'question-row-id-order-null',
    ])
  })
})
