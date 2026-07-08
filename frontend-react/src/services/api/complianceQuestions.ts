import { api } from './client'

export type ComplianceQuestionType = 'YES_NO' | 'FREE_TEXT'

export interface ComplianceQuestionDto {
  id: string
  questionText: string
  questionType: ComplianceQuestionType | string
  displayOrder: number | null
  active: boolean
  createdByWorkerCode: string | null
  createdAt: string
  updatedAt: string
}

export interface CreateComplianceQuestionRequest {
  questionText: string
  questionType: ComplianceQuestionType
  displayOrder: number | null
}

export interface UpdateComplianceQuestionRequest {
  questionText?: string
  questionType?: ComplianceQuestionType
  displayOrder?: number | null
}

export interface CreateQuestionAnswerRequest {
  customerId: number
  transactionId?: number | null
  answerText: string
}

export interface CustomerQuestionAnswerDto {
  id: string
  questionId: string
  customerId: number
  transactionId: number | null
  answerText: string
  answeredByWorkerCode: string | null
  answeredAt: string
}

function assertValidDisplayOrder(value: number | null | undefined): void {
  if (value == null) return
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error('A sorrend pozitív egész szám lehet')
  }
}

function assertValidQuestionText(value: string): void {
  if (!value.trim()) {
    throw new Error('A kérdés szövege kötelező')
  }
}

function assertValidQuestionType(value: ComplianceQuestionType): void {
  if (value !== 'YES_NO' && value !== 'FREE_TEXT') {
    throw new Error('Érvénytelen kérdéstípus')
  }
}

function assertValidCreate(req: CreateComplianceQuestionRequest): void {
  assertValidQuestionText(req.questionText)
  assertValidQuestionType(req.questionType)
  assertValidDisplayOrder(req.displayOrder)
}

export const complianceQuestionApi = {
  list: async (): Promise<ComplianceQuestionDto[]> => {
    const response = await api.get<ComplianceQuestionDto[]>('/compliance-questions')
    return response.data
  },

  listActive: async (): Promise<ComplianceQuestionDto[]> => {
    const response = await api.get<ComplianceQuestionDto[]>('/compliance-questions/active')
    return response.data
  },

  create: async (req: CreateComplianceQuestionRequest): Promise<ComplianceQuestionDto> => {
    assertValidCreate(req)
    const response = await api.post<ComplianceQuestionDto>('/compliance-questions', {
      questionText: req.questionText.trim(),
      questionType: req.questionType,
      displayOrder: req.displayOrder ?? null,
    })
    return response.data
  },

  update: async (
    id: string,
    req: UpdateComplianceQuestionRequest,
  ): Promise<ComplianceQuestionDto> => {
    if (req.questionText !== undefined) {
      assertValidQuestionText(req.questionText)
    }
    assertValidDisplayOrder(req.displayOrder)

    const response = await api.put<ComplianceQuestionDto>(`/compliance-questions/${id}`, {
      ...req,
      ...(req.questionText !== undefined ? { questionText: req.questionText.trim() } : {}),
    })
    return response.data
  },

  setActive: async (id: string, active: boolean): Promise<ComplianceQuestionDto> => {
    const response = await api.put<ComplianceQuestionDto>(`/compliance-questions/${id}/active`, {
      active,
    })
    return response.data
  },

  submitAnswer: async (
    questionId: string,
    req: CreateQuestionAnswerRequest,
    idempotencyKey?: string,
  ): Promise<CustomerQuestionAnswerDto> => {
    if (!req.answerText.trim()) {
      throw new Error('A válasz szövege kötelező')
    }
    const response = await api.post<CustomerQuestionAnswerDto>(
      `/compliance-questions/${questionId}/answers`,
      {
        customerId: req.customerId,
        transactionId: req.transactionId ?? null,
        answerText: req.answerText.trim(),
      },
      idempotencyKey ? { headers: { 'Idempotency-Key': idempotencyKey } } : undefined,
    )
    return response.data
  },
}
