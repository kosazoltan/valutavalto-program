import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ComplianceQuestionsBlock from './ComplianceQuestionsBlock'

const mocks = vi.hoisted(() => ({
  listActive: vi.fn(),
  submitAnswer: vi.fn(),
  toast: { success: vi.fn(), warning: vi.fn(), error: vi.fn(), info: vi.fn() },
  loggerWarn: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../../services/api/complianceQuestions', () => ({
  complianceQuestionApi: { listActive: mocks.listActive, submitAnswer: mocks.submitAnswer },
}))
vi.mock('../../../components/ui/toaster', () => ({ toast: mocks.toast }))
vi.mock('../../../utils/logger', () => ({
  logger: { warn: mocks.loggerWarn, error: mocks.loggerError, info: vi.fn(), debug: vi.fn() },
}))

const q = (over: Record<string, unknown> = {}) => ({
  id: 'q-1',
  questionText: 'Politikai közszereplő-e Ön?',
  questionType: 'YES_NO',
  displayOrder: 1,
  active: true,
  createdByWorkerCode: 'W1',
  createdAt: '2026-07-08T10:00:00',
  updatedAt: '2026-07-08T10:00:00',
  ...over,
})

describe('ComplianceQuestionsBlock', () => {
  beforeEach(() => vi.clearAllMocks())

  it('displayOrder szerint rendezve listáz, null order a végére', async () => {
    mocks.listActive.mockResolvedValue([
      q({
        id: 'q-c',
        questionText: 'C kérdés?',
        displayOrder: null,
        createdAt: '2026-07-01T00:00:00',
      }),
      q({ id: 'q-b', questionText: 'B kérdés?', displayOrder: 2 }),
      q({ id: 'q-a', questionText: 'A kérdés?', displayOrder: 1 }),
    ])
    render(<ComplianceQuestionsBlock customerId={42} />)
    const items = await screen.findAllByTestId(/^compliance-question-/)
    expect(items.map((el) => el.getAttribute('data-testid'))).toEqual([
      'compliance-question-q-a',
      'compliance-question-q-b',
      'compliance-question-q-c',
    ])
  })

  it('YES_NO: Igen választás + Rögzít → submitAnswer customerId-vel, transactionId nélkül', async () => {
    mocks.listActive.mockResolvedValue([q()])
    mocks.submitAnswer.mockResolvedValue({ id: 'a-1' })
    render(<ComplianceQuestionsBlock customerId={42} />)
    fireEvent.click(await screen.findByRole('button', { name: 'Igen' }))
    fireEvent.click(screen.getByRole('button', { name: 'Rögzít' }))
    await waitFor(() => expect(mocks.submitAnswer).toHaveBeenCalledTimes(1))
    expect(mocks.submitAnswer).toHaveBeenCalledWith(
      'q-1',
      { customerId: 42, transactionId: null, answerText: 'YES' },
      expect.any(String),
    )
    expect(await screen.findByText('Rögzítve')).toBeInTheDocument()
  })

  it('FREE_TEXT: trimmelt szöveg megy, üresnél a Rögzít tiltott', async () => {
    mocks.listActive.mockResolvedValue([q({ questionType: 'FREE_TEXT' })])
    mocks.submitAnswer.mockResolvedValue({ id: 'a-1' })
    render(<ComplianceQuestionsBlock customerId={42} />)
    const input = await screen.findByPlaceholderText('Válasz…')
    expect(screen.getByRole('button', { name: 'Rögzít' })).toBeDisabled()
    fireEvent.change(input, { target: { value: '  munkabér  ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Rögzít' }))
    await waitFor(() =>
      expect(mocks.submitAnswer).toHaveBeenCalledWith(
        'q-1',
        { customerId: 42, transactionId: null, answerText: 'munkabér' },
        expect.any(String),
      ),
    )
  })

  it('hibás mentés: toast + STRING a loggernek, retry UGYANAZZAL az Idempotency-Key-jel', async () => {
    mocks.listActive.mockResolvedValue([q()])
    mocks.submitAnswer
      .mockRejectedValueOnce(new Error('network down'))
      .mockResolvedValue({ id: 'a-1' })
    render(<ComplianceQuestionsBlock customerId={42} />)
    fireEvent.click(await screen.findByRole('button', { name: 'Nem' }))
    fireEvent.click(screen.getByRole('button', { name: 'Rögzít' }))
    await waitFor(() =>
      expect(mocks.toast.error).toHaveBeenCalledWith(
        'Compliance-válasz mentése sikertelen',
        expect.any(String),
      ),
    )
    expect(mocks.loggerError).toHaveBeenCalled()
    for (const arg of mocks.loggerError.mock.calls[0]!) {
      expect(typeof arg).toBe('string')
    }
    fireEvent.click(screen.getByRole('button', { name: 'Rögzít' }))
    await waitFor(() => expect(mocks.submitAnswer).toHaveBeenCalledTimes(2))
    expect(mocks.submitAnswer.mock.calls[0]![1]).toMatchObject({ answerText: 'NO' })
    expect(mocks.submitAnswer.mock.calls[1]![1]).toMatchObject({ answerText: 'NO' })
    expect(mocks.submitAnswer.mock.calls[0]![2]).toBe(mocks.submitAnswer.mock.calls[1]![2])
  })

  it('fetch-hiba: csendes degradáció — nem renderel, logger.warn stringgel, nincs toast', async () => {
    mocks.listActive.mockRejectedValue(new Error('offline'))
    const { container } = render(<ComplianceQuestionsBlock customerId={42} />)
    await waitFor(() => expect(mocks.loggerWarn).toHaveBeenCalled())
    expect(container).toBeEmptyDOMElement()
    expect(mocks.toast.error).not.toHaveBeenCalled()
    for (const arg of mocks.loggerWarn.mock.calls[0]!) {
      expect(typeof arg).toBe('string')
    }
  })

  it('üres aktív-lista: nem renderel semmit', async () => {
    mocks.listActive.mockResolvedValue([])
    const { container } = render(<ComplianceQuestionsBlock customerId={42} />)
    await waitFor(() => expect(mocks.listActive).toHaveBeenCalledTimes(1))
    expect(container).toBeEmptyDOMElement()
  })
})
