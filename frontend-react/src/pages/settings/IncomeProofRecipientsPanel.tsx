import { useCallback, useEffect, useState, type KeyboardEvent } from 'react'
import { Loader2, Mail, Plus, Trash2 } from 'lucide-react'
import {
  incomeSourceDocApi,
  type IncomeProofRecipientsResponse,
} from '../../services/api/incomeSourceDocs'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

const EMAIL_REGEX = /^[^@\s]+@[^@\s]+\.[^@\s]+$/
const MAX_RECIPIENTS = 20

function extractErrorMessage(err: unknown): string {
  if (err instanceof Error) return err.message
  if (typeof err === 'string') return err
  return 'Ismeretlen hiba'
}

function normalizeRecipients(response: IncomeProofRecipientsResponse | null | undefined): string[] {
  return Array.isArray(response?.recipients) ? response.recipients : []
}

export default function IncomeProofRecipientsPanel() {
  const [recipients, setRecipients] = useState<string[]>([])
  const [inputValue, setInputValue] = useState('')
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [dirty, setDirty] = useState(false)

  const loadRecipients = useCallback(async () => {
    setLoading(true)
    try {
      const response = await incomeSourceDocApi.getRecipients()
      setRecipients(normalizeRecipients(response))
      setDirty(false)
    } catch (err) {
      logger.error('IncomeProofRecipientsPanel', 'Címzettek betöltése sikertelen:', err)
      toast.error('Betöltési hiba', extractErrorMessage(err))
      setRecipients([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadRecipients()
  }, [loadRecipients])

  const handleAdd = () => {
    const trimmed = inputValue.trim()
    if (!trimmed) return

    if (!EMAIL_REGEX.test(trimmed)) {
      toast.error('Validációs hiba', 'Az e-mail cím érvénytelen')
      return
    }

    const normalized = trimmed.toLowerCase()
    if (recipients.some((recipient) => recipient.toLowerCase() === normalized)) {
      toast.error('Validációs hiba', 'Ez az e-mail cím már szerepel a listában')
      return
    }

    if (recipients.length >= MAX_RECIPIENTS) {
      toast.error('Validációs hiba', 'Maximum 20 címzett adható meg')
      return
    }

    setRecipients((current) => [...current, trimmed])
    setInputValue('')
    setDirty(true)
  }

  const handleDelete = (recipientToRemove: string) => {
    setRecipients((current) => current.filter((recipient) => recipient !== recipientToRemove))
    setDirty(true)
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      const response = await incomeSourceDocApi.putRecipients(recipients)
      setRecipients(normalizeRecipients(response))
      setDirty(false)
      toast.success('Mentve', `${response.count} címzett elmentve`)
    } catch (err) {
      logger.error('IncomeProofRecipientsPanel', 'Címzettek mentése sikertelen:', err)
      toast.error('Mentés sikertelen', extractErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const handleInputKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter') {
      event.preventDefault()
      handleAdd()
    }
  }

  if (loading) {
    return (
      <div className="flex items-center gap-2 p-4 text-gray-500">
        <Loader2 className="h-4 w-4 animate-spin" />
        <span>{i18n.t('literals.cimzettek-betoltese')}</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <h2 className="section-title flex items-center gap-2">
        <Mail size={18} className="text-blue-600" />
        {i18n.t('literals.jovedelemigazolas-cimzettek')}
      </h2>

      <div className="rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-800">
        {i18n.t('literals.a-10-000-000-ft-feletti-jovedelemforras')}
      </div>

      <div className="rounded border border-gray-200 bg-white">
        <div className="border-b border-gray-200 px-3 py-2 text-sm font-medium text-gray-700">
          {i18n.t('literals.cimzettek-2')}
          {recipients.length}
          {i18n.t('literals.lit-4')}
          {MAX_RECIPIENTS}
          {i18n.t('literals.lit-2')}
        </div>
        <div className="divide-y divide-gray-100">
          {recipients.length === 0 && (
            <div className="px-3 py-4 text-sm text-gray-500">
              {i18n.t('literals.nincs-beallitott-cimzett')}
            </div>
          )}
          {recipients.map((recipient) => (
            <div
              key={recipient}
              data-testid={`recipient-row-${recipient}`}
              className="flex items-center justify-between gap-3 px-3 py-2"
            >
              <span className="font-mono text-sm text-gray-800">{recipient}</span>
              <button
                type="button"
                className="form-button flex items-center gap-1 text-red-600"
                onClick={() => handleDelete(recipient)}
                disabled={saving}
              >
                <Trash2 size={14} />
                {i18n.t('literals.torles')}
              </button>
            </div>
          ))}
        </div>
      </div>

      <div className="flex flex-col gap-2 sm:flex-row">
        <input
          type="email"
          className="form-input sm:max-w-sm"
          placeholder="email@cim.hu"
          value={inputValue}
          onChange={(event) => setInputValue(event.target.value)}
          onKeyDown={handleInputKeyDown}
          disabled={saving}
        />
        <button
          type="button"
          className="form-button flex items-center gap-1"
          onClick={handleAdd}
          disabled={saving}
        >
          <Plus size={14} />
          {i18n.t('literals.hozzaadas')}
        </button>
      </div>

      {dirty && (
        <div className="flex justify-end">
          <button
            type="button"
            className="form-button-primary flex items-center gap-2"
            onClick={() => void handleSave()}
            disabled={saving}
          >
            {saving && <Loader2 className="h-4 w-4 animate-spin" />}
            {saving ? 'Mentés...' : 'Mentés'}
          </button>
        </div>
      )}
    </div>
  )
}
