import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./client', () => {
  const mockPost = vi.fn()
  const mockGet = vi.fn()
  const mockPut = vi.fn()
  return { api: { post: mockPost, get: mockGet, put: mockPut, defaults: { baseURL: '/api/v1' } } }
})

import { complianceQuestionApi } from './complianceQuestions'
import { api } from './client'

const mockApi = api as unknown as {
  post: ReturnType<typeof vi.fn>
  get: ReturnType<typeof vi.fn>
  put: ReturnType<typeof vi.fn>
}

const dto = {
  id: '11111111-2222-3333-4444-555555555555',
  questionText: 'Politikai közszereplő-e Ön?',
  questionType: 'YES_NO',
  displayOrder: 1,
  active: true,
  createdByWorkerCode: 'W001',
  createdAt: '2026-07-08T10:00:00',
  updatedAt: '2026-07-08T10:00:00',
}

beforeEach(() => vi.clearAllMocks())

describe('complianceQuestionApi', () => {
  it('list_calls_get_compliance_questions', async () => {
    mockApi.get.mockResolvedValue({ data: [dto] })
    const result = await complianceQuestionApi.list()
    expect(mockApi.get).toHaveBeenCalledWith('/compliance-questions')
    expect(result).toEqual([dto])
  })

  it('create_posts_trimmed_payload', async () => {
    mockApi.post.mockResolvedValue({ data: dto })
    const result = await complianceQuestionApi.create({
      questionText: '  Politikai közszereplő-e Ön?  ',
      questionType: 'YES_NO',
      displayOrder: 1,
    })
    expect(mockApi.post).toHaveBeenCalledWith('/compliance-questions', {
      questionText: 'Politikai közszereplő-e Ön?',
      questionType: 'YES_NO',
      displayOrder: 1,
    })
    expect(result).toEqual(dto)
  })

  it('create_rejects_blank_questionText_without_network_call', async () => {
    await expect(
      complianceQuestionApi.create({
        questionText: '   ',
        questionType: 'YES_NO',
        displayOrder: null,
      }),
    ).rejects.toThrow('A kérdés szövege kötelező')
    expect(mockApi.post).not.toHaveBeenCalled()
  })

  it('create_rejects_nonpositive_displayOrder_without_network_call', async () => {
    await expect(
      complianceQuestionApi.create({
        questionText: 'Kérdés',
        questionType: 'FREE_TEXT',
        displayOrder: 0,
      }),
    ).rejects.toThrow('pozitív egész')
    expect(mockApi.post).not.toHaveBeenCalled()
  })

  it('update_puts_partial_payload_to_id_path', async () => {
    mockApi.put.mockResolvedValue({ data: { ...dto, questionText: 'Módosított' } })
    const result = await complianceQuestionApi.update(dto.id, { questionText: 'Módosított' })
    expect(mockApi.put).toHaveBeenCalledWith(`/compliance-questions/${dto.id}`, {
      questionText: 'Módosított',
    })
    expect(result.questionText).toBe('Módosított')
  })

  it('setActive_puts_boolean_body_to_active_path', async () => {
    mockApi.put.mockResolvedValue({ data: { ...dto, active: false } })
    const result = await complianceQuestionApi.setActive(dto.id, false)
    expect(mockApi.put).toHaveBeenCalledWith(`/compliance-questions/${dto.id}/active`, {
      active: false,
    })
    expect(result.active).toBe(false)
  })

  it('listActive_calls_get_active_endpoint', async () => {
    mockApi.get.mockResolvedValue({ data: [dto] })
    const result = await complianceQuestionApi.listActive()
    expect(mockApi.get).toHaveBeenCalledWith('/compliance-questions/active')
    expect(result).toEqual([dto])
  })

  it('submitAnswer_posts_trimmed_body_with_idempotency_key', async () => {
    const answer = {
      id: 'a1',
      questionId: dto.id,
      customerId: 42,
      transactionId: null,
      answerText: 'Igen',
      answeredByWorkerCode: 'FZS',
      answeredAt: '2026-07-08T11:00:00',
    }
    mockApi.post.mockResolvedValue({ data: answer })
    const result = await complianceQuestionApi.submitAnswer(
      dto.id,
      { customerId: 42, answerText: '  Igen  ' },
      'idem-key-1',
    )
    expect(mockApi.post).toHaveBeenCalledWith(
      `/compliance-questions/${dto.id}/answers`,
      { customerId: 42, transactionId: null, answerText: 'Igen' },
      { headers: { 'Idempotency-Key': 'idem-key-1' } },
    )
    expect(result).toEqual(answer)
  })

  it('submitAnswer_rejects_blank_answer_without_network_call', async () => {
    await expect(
      complianceQuestionApi.submitAnswer(dto.id, { customerId: 42, answerText: '   ' }),
    ).rejects.toThrow('A válasz szövege kötelező')
    expect(mockApi.post).not.toHaveBeenCalled()
  })
})
