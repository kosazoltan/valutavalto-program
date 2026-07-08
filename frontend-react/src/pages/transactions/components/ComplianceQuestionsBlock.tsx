import { useCallback, useEffect, useRef, useState } from 'react'
import { ClipboardCheck, CheckCircle } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import {
  complianceQuestionApi,
  type ComplianceQuestionDto,
} from '../../../services/api/complianceQuestions'
import { toast } from '../../../components/ui/toaster'
import { getErrorMessage } from '../../../utils/errorHandling'
import { logger } from '../../../utils/logger'
import { safeArray } from '../../../utils/safeArray'

/**
 * FS-10 S3: pénztár-oldali compliance-kérdés blokk.
 * CSAK mentett ügyfélnél mountolja a szülő (customerId kötelező — a
 * POST /answers customerId-t követel, fail-closed). NEM blokkolja a
 * tranzakció-submitet: additív, hibánál csendben degradál (fetch) ill.
 * toast + stabil Idempotency-Key-es retry (submit).
 */
interface Props {
  customerId: number
}

interface AnswerDraft {
  value: string
  saved: boolean
  submitting: boolean
}

function sortQuestions(items: ComplianceQuestionDto[]): ComplianceQuestionDto[] {
  return [...items].sort((a, b) => {
    if (a.displayOrder != null && b.displayOrder != null && a.displayOrder !== b.displayOrder) {
      return a.displayOrder - b.displayOrder
    }
    if (a.displayOrder != null && b.displayOrder == null) return -1
    if (a.displayOrder == null && b.displayOrder != null) return 1
    return a.createdAt.localeCompare(b.createdAt)
  })
}

export default function ComplianceQuestionsBlock({ customerId }: Props) {
  const { t } = useTranslation()
  const [questions, setQuestions] = useState<ComplianceQuestionDto[]>([])
  const [loaded, setLoaded] = useState(false)
  const [drafts, setDrafts] = useState<Record<string, AnswerDraft>>({})
  // Idempotencia (D4): kérdésenként stabil kulcs SIKERIG — dupla-katt/retry
  // nem rögzít duplán (a client.ts interceptor kérésenként ÚJ kulcsot adna).
  const idemKeysRef = useRef<Record<string, string>>({})
  const submittingQuestionIdsRef = useRef<Set<string>>(new Set())

  useEffect(() => {
    let cancelled = false
    complianceQuestionApi
      .listActive()
      .then((data) => {
        if (cancelled) return
        setQuestions(sortQuestions(safeArray<ComplianceQuestionDto>(data)))
        setLoaded(true)
      })
      .catch((err: unknown) => {
        if (cancelled) return
        // Csendes degradáció (D5): offline/hibánál a blokk nem jelenik meg,
        // a tranzakció-flow érintetlen. LOGGER-RAW-ERR: csak string megy a loggernek.
        logger.warn(
          'ComplianceQuestionsBlock',
          'Aktív kérdések betöltése sikertelen:',
          getErrorMessage(err),
        )
        setLoaded(false)
      })
    return () => {
      cancelled = true
    }
  }, [])

  const setDraftValue = useCallback((questionId: string, value: string) => {
    setDrafts((prev) => ({
      ...prev,
      [questionId]: { value, saved: false, submitting: false },
    }))
  }, [])

  const handleSubmitAnswer = useCallback(
    async (questionId: string) => {
      const draft = drafts[questionId]
      const answerText = draft?.value.trim()
      if (
        !answerText ||
        draft?.saved ||
        draft?.submitting ||
        submittingQuestionIdsRef.current.has(questionId)
      ) {
        return
      }
      idemKeysRef.current[questionId] ??= crypto.randomUUID()
      submittingQuestionIdsRef.current.add(questionId)
      setDrafts((prev) => ({
        ...prev,
        [questionId]: { ...prev[questionId]!, submitting: true },
      }))
      try {
        await complianceQuestionApi.submitAnswer(
          questionId,
          { customerId, transactionId: null, answerText },
          idemKeysRef.current[questionId],
        )
        delete idemKeysRef.current[questionId]
        setDrafts((prev) => ({
          ...prev,
          [questionId]: { value: draft!.value, saved: true, submitting: false },
        }))
      } catch (err: unknown) {
        const message = getErrorMessage(err)
        logger.error('ComplianceQuestionsBlock', 'Válasz rögzítése sikertelen:', message)
        toast.error(t('complianceQuestions.mentesSikertelen'), message)
        setDrafts((prev) => ({
          ...prev,
          [questionId]: { ...prev[questionId]!, submitting: false },
        }))
      } finally {
        submittingQuestionIdsRef.current.delete(questionId)
      }
    },
    [drafts, customerId, t],
  )

  if (!loaded || questions.length === 0) return null

  const yesNoOptions = [
    { value: 'YES', label: t('complianceQuestions.igen') },
    { value: 'NO', label: t('complianceQuestions.nem') },
  ]

  return (
    <div
      className="border-t border-gray-200 dark:border-gray-700 pt-2 space-y-2"
      data-testid="compliance-questions-block"
    >
      <div className="flex items-center gap-2">
        <ClipboardCheck className="w-4 h-4 text-gray-500" />
        <span className="text-sm font-semibold">{t('complianceQuestions.cim')}</span>
      </div>
      <p className="text-xs text-gray-500 dark:text-gray-400">{t('complianceQuestions.leiras')}</p>
      {questions.map((question) => {
        const draft = drafts[question.id]
        const saved = draft?.saved ?? false
        return (
          <div
            key={question.id}
            data-testid={`compliance-question-${question.id}`}
            className="space-y-1"
          >
            <p className="text-sm text-gray-800 dark:text-gray-200">{question.questionText}</p>
            <div className="flex items-center gap-2">
              {question.questionType === 'YES_NO' ? (
                <>
                  {yesNoOptions.map((opt) => (
                    <button
                      key={opt.value}
                      type="button"
                      disabled={saved || (draft?.submitting ?? false)}
                      onClick={() => setDraftValue(question.id, opt.value)}
                      className={`px-3 py-1 rounded border text-sm ${
                        draft?.value === opt.value
                          ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/30 font-semibold'
                          : 'border-gray-300 dark:border-gray-600'
                      } disabled:opacity-50`}
                    >
                      {opt.label}
                    </button>
                  ))}
                </>
              ) : (
                <input
                  type="text"
                  value={draft?.value ?? ''}
                  disabled={saved || (draft?.submitting ?? false)}
                  placeholder={t('complianceQuestions.valaszPlaceholder')}
                  onChange={(e) => setDraftValue(question.id, e.target.value)}
                  className="form-input flex-1 text-sm"
                />
              )}
              {saved ? (
                <span className="inline-flex items-center gap-1 text-sm text-green-600">
                  <CheckCircle className="w-4 h-4" />
                  {t('complianceQuestions.rogzitve')}
                </span>
              ) : (
                <button
                  type="button"
                  disabled={!draft?.value.trim() || (draft?.submitting ?? false)}
                  onClick={() => {
                    void handleSubmitAnswer(question.id)
                  }}
                  className="form-button text-sm disabled:opacity-50"
                >
                  {t('complianceQuestions.rogzit')}
                </button>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
