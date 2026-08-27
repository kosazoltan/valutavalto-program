import { type FormEvent, useCallback, useEffect, useMemo, useState } from 'react'
import { ClipboardCheck, Pencil, Plus, Power, RefreshCw, X } from 'lucide-react'
import {
  complianceQuestionApi,
  type ComplianceQuestionDto,
  type ComplianceQuestionType,
} from '../../services/api/complianceQuestions'
import { toast } from '../../components/ui/toaster'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import i18n from '../../i18n'

const TYPE_LABELS: Record<string, string> = {
  YES_NO: 'Igen/Nem',
  FREE_TEXT: 'Szabad szöveg',
}

interface FormState {
  questionText: string
  questionType: ComplianceQuestionType | ''
  displayOrder: string
}

const EMPTY_FORM: FormState = { questionText: '', questionType: '', displayOrder: '' }

function parseDisplayOrder(raw: string): number | null | undefined {
  const trimmed = raw.trim()
  if (trimmed === '') return null
  const value = Number(trimmed)
  if (!Number.isInteger(value) || value <= 0) return undefined
  return value
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

function logAndToastError(title: string, action: string, err: unknown): void {
  const message = getErrorMessage(err)
  logger.error('ComplianceQuestionsPage', action, message)
  toast.error(title, message)
}

export default function ComplianceQuestionsPage() {
  const [questions, setQuestions] = useState<ComplianceQuestionDto[]>([])
  const [form, setForm] = useState<FormState>(EMPTY_FORM)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      setQuestions(safeArray(await complianceQuestionApi.list()))
    } catch (err) {
      logAndToastError('Betöltési hiba', 'Kérdések betöltése sikertelen:', err)
      setQuestions([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const sortedQuestions = useMemo(() => sortQuestions(questions), [questions])
  const parsedOrder = parseDisplayOrder(form.displayOrder)
  const orderInvalid = parsedOrder === undefined
  const formValid = form.questionText.trim() !== '' && form.questionType !== '' && !orderInvalid

  const resetForm = () => {
    setEditingId(null)
    setForm(EMPTY_FORM)
  }

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!formValid || saving) return

    setSaving(true)
    try {
      if (editingId) {
        await complianceQuestionApi.update(editingId, {
          questionText: form.questionText.trim(),
          questionType: form.questionType as ComplianceQuestionType,
          displayOrder: parsedOrder ?? null,
        })
        toast.success('Kérdés módosítva')
      } else {
        await complianceQuestionApi.create({
          questionText: form.questionText,
          questionType: form.questionType as ComplianceQuestionType,
          displayOrder: parsedOrder ?? null,
        })
        toast.success('Kérdés létrehozva')
      }
      resetForm()
      await load()
    } catch (err) {
      logAndToastError('Mentés sikertelen', 'Mentés sikertelen:', err)
    } finally {
      setSaving(false)
    }
  }

  const startEdit = (item: ComplianceQuestionDto) => {
    setEditingId(item.id)
    setForm({
      questionText: item.questionText,
      questionType:
        item.questionType === 'YES_NO' || item.questionType === 'FREE_TEXT'
          ? item.questionType
          : '',
      displayOrder: item.displayOrder != null ? String(item.displayOrder) : '',
    })
  }

  const toggleActive = async (item: ComplianceQuestionDto) => {
    if (saving) return

    setSaving(true)
    try {
      const updated = await complianceQuestionApi.setActive(item.id, !item.active)
      setQuestions((current) =>
        current.map((question) => (question.id === updated.id ? updated : question)),
      )
      toast.success(updated.active ? 'Kérdés aktiválva' : 'Kérdés inaktiválva')
    } catch (err) {
      logAndToastError('Művelet sikertelen', 'Aktiválás sikertelen:', err)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between gap-4">
        <h1 className="form-title flex items-center gap-2">
          <ClipboardCheck className="h-6 w-6" />
          {i18n.t('literals.compliance-kerdesek')}
        </h1>
        <button
          type="button"
          onClick={() => void load()}
          className="form-button flex items-center gap-2"
          disabled={loading || saving}
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          {i18n.t('literals.frissites-2')}
        </button>
      </div>

      <div className="rounded-md border border-blue-200 bg-blue-50 p-3 text-sm text-blue-900">
        {i18n.t('literals.a-kerdesek-a-penztarak-fele-szinkronizal')}
      </div>

      <form
        className="grid grid-cols-12 items-end gap-3 rounded-md border border-gray-200 p-4"
        onSubmit={handleSubmit}
      >
        <div className="col-span-12 md:col-span-5">
          <label className="form-label required" htmlFor="question-text-input">
            {i18n.t('literals.kerdes-szovege')}
          </label>
          <input
            id="question-text-input"
            data-testid="question-text-input"
            className="form-input"
            value={form.questionText}
            onChange={(event) =>
              setForm((current) => ({ ...current, questionText: event.target.value }))
            }
            placeholder="pl. Politikai közszereplő-e Ön?"
            disabled={saving}
          />
        </div>

        <div className="col-span-12 md:col-span-3">
          <label className="form-label required" htmlFor="question-type-select">
            {i18n.t('literals.tipus')}
          </label>
          <select
            id="question-type-select"
            data-testid="question-type-select"
            className="form-input"
            value={form.questionType}
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                questionType: event.target.value as FormState['questionType'],
              }))
            }
            disabled={saving}
          >
            <option value="">{i18n.t('literals.valasszon-tipust')}</option>
            <option value="YES_NO">{i18n.t('literals.igen-nem')}</option>
            <option value="FREE_TEXT">{i18n.t('literals.szabad-szoveg')}</option>
          </select>
        </div>

        <div className="col-span-12 md:col-span-2">
          <label className="form-label" htmlFor="display-order-input">
            {i18n.t('literals.sorrend')}
          </label>
          <input
            id="display-order-input"
            data-testid="display-order-input"
            type="number"
            min={1}
            step={1}
            className="form-input"
            value={form.displayOrder}
            onChange={(event) =>
              setForm((current) => ({ ...current, displayOrder: event.target.value }))
            }
            disabled={saving}
          />
          {orderInvalid && (
            <span className="text-sm text-red-600">
              {i18n.t('literals.a-sorrend-pozitiv-egesz-szam-lehet')}
            </span>
          )}
        </div>

        <div className="col-span-12 flex gap-2 md:col-span-2">
          <button
            type="submit"
            data-testid="submit-question"
            className="form-button-primary flex flex-1 items-center justify-center gap-1"
            disabled={!formValid || saving}
          >
            <Plus className="h-4 w-4" /> {editingId ? 'Mentés' : 'Létrehozás'}
          </button>
          {editingId && (
            <button
              type="button"
              className="form-button flex items-center justify-center gap-1"
              onClick={resetForm}
              disabled={saving}
            >
              <X className="h-4 w-4" />
              {i18n.t('literals.megse-2')}
            </button>
          )}
        </div>
      </form>

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.sorrend')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.kerdes')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.tipus')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.allapot')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.rogzito')}
              </th>
              <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.muveletek')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {loading && (
              <tr>
                <td colSpan={6} className="px-3 py-4 text-center text-gray-400">
                  {i18n.t('literals.kerdesek-betoltese')}
                </td>
              </tr>
            )}
            {!loading && sortedQuestions.length === 0 && (
              <tr>
                <td colSpan={6} className="px-3 py-4 text-center text-gray-400">
                  {i18n.t('literals.nincs-rogzitett-compliance-kerdes')}
                </td>
              </tr>
            )}
            {!loading &&
              sortedQuestions.map((item) => (
                <tr key={item.id} data-testid={`question-row-${item.id}`}>
                  <td className="px-3 py-2 text-sm font-mono">{item.displayOrder ?? '—'}</td>
                  <td className="px-3 py-2 text-sm">{item.questionText}</td>
                  <td className="px-3 py-2 text-sm">
                    {TYPE_LABELS[item.questionType] ?? item.questionType}
                  </td>
                  <td className="px-3 py-2 text-sm">
                    <span
                      data-testid={`active-badge-${item.id}`}
                      className={`rounded-full px-2 py-1 text-xs font-medium ${
                        item.active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
                      }`}
                    >
                      {item.active ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td className="px-3 py-2 text-sm font-mono">{item.createdByWorkerCode ?? '—'}</td>
                  <td className="px-3 py-2 text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        className="text-blue-600 hover:text-blue-800 flex items-center gap-1 text-sm disabled:text-gray-400"
                        onClick={() => startEdit(item)}
                        disabled={saving}
                      >
                        <Pencil className="h-4 w-4" />
                        {i18n.t('literals.szerkesztes')}
                      </button>
                      <button
                        type="button"
                        data-testid={`toggle-active-${item.id}`}
                        className="text-gray-700 hover:text-gray-900 flex items-center gap-1 text-sm disabled:text-gray-400"
                        onClick={() => void toggleActive(item)}
                        disabled={saving}
                      >
                        <Power className="h-4 w-4" /> {item.active ? 'Inaktiválás' : 'Aktiválás'}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
