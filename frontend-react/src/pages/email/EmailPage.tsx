import { useState, useEffect, useCallback } from 'react'
import {
  Mail,
  Search,
  RefreshCw,
  Plus,
  Edit2,
  Trash2,
  AlertTriangle,
  Send,
  Reply,
  Forward,
  Eye,
  Download,
} from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface EmailAccountItem {
  id: string
  gmailAddress?: string
  displayName?: string
  isActive?: boolean
  lastSyncAt?: string
  syncError?: string
}

interface EmailAccountForm {
  id?: string
  gmailAddress: string
  displayName: string
  isActive: boolean
  scopeType: 'workerId' | 'branchId' | 'ownCompanyId' | 'vaultTerritoryId'
  scopeValue: string
}

interface EmailSummary {
  id: string
  threadId?: string
  subject?: string
  sender?: string
  from?: string
  snippet?: string
  isRead?: boolean
  hasAttachments?: boolean
  receivedAt?: number
}

interface EmailDetail {
  id: string
  threadId?: string
  subject?: string
  from?: string
  to?: string[]
  cc?: string[]
  body?: string
  htmlBody?: string
  receivedAt?: number
  attachments?: Array<{
    attachmentId: string
    filename?: string
    mimeType?: string
    size?: number
  }>
}

interface ComposeForm {
  to: string
  subject: string
  body: string
}

function fmtDate(value?: number | string): string {
  if (value == null) return '-'
  const date = typeof value === 'number' ? new Date(value) : new Date(value)
  return Number.isNaN(date.getTime()) ? String(value) : date.toLocaleString('hu-HU')
}

function accountLabel(account: EmailAccountItem): string {
  return account.displayName
    ? `${account.displayName} <${account.gmailAddress ?? '-'}>`
    : (account.gmailAddress ?? account.id)
}

export default function EmailPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const [accounts, setAccounts] = useState<EmailAccountItem[]>([])
  const [configurableAccounts, setConfigurableAccounts] = useState<EmailAccountItem[]>([])
  const [selectedAccountId, setSelectedAccountId] = useState('')
  const [folder, setFolder] = useState('INBOX')
  const [messages, setMessages] = useState<EmailSummary[]>([])
  const [selectedMessage, setSelectedMessage] = useState<EmailDetail | null>(null)
  const [unreadCount, setUnreadCount] = useState<number | null>(null)
  const [loading, setLoading] = useState(true)
  const [messageLoading, setMessageLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [accountSearch, setAccountSearch] = useState('')
  const [mailSearch, setMailSearch] = useState('')
  const [accountForm, setAccountForm] = useState<EmailAccountForm | null>(null)
  const [composeMode, setComposeMode] = useState<'new' | 'reply' | 'forward' | null>(null)
  const [compose, setCompose] = useState<ComposeForm>({ to: '', subject: '', body: '' })

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const [accountResult, unreadResult] = await Promise.allSettled([
        api.get<{ accounts?: EmailAccountItem[]; configurable?: EmailAccountItem[] }>(
          '/email/accounts',
        ),
        api.get<{ unreadCount?: number }>('/email/unread-count'),
      ])

      if (accountResult.status === 'fulfilled') {
        const ownAccounts = safeArray<EmailAccountItem>(accountResult.value.data?.accounts)
        const configurable = safeArray<EmailAccountItem>(accountResult.value.data?.configurable)
        setAccounts(ownAccounts)
        setConfigurableAccounts(configurable)
        setSelectedAccountId((current) => current || ownAccounts[0]?.id || '')
      } else {
        logger.error('EmailPage', 'Fióklista betöltési hiba:', accountResult.reason)
        setAccounts([])
        setConfigurableAccounts([])
        setError(getErrorMessage(accountResult.reason))
      }

      if (unreadResult.status === 'fulfilled') {
        setUnreadCount(unreadResult.value.data?.unreadCount ?? 0)
      } else {
        logger.error('EmailPage', 'Olvasatlan szám betöltési hiba:', unreadResult.reason)
        setUnreadCount(null)
      }
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  const loadMessages = useCallback(
    async (accountId = selectedAccountId) => {
      if (!accountId) {
        setMessages([])
        setSelectedMessage(null)
        return
      }
      try {
        setMessageLoading(true)
        setError(null)
        const response = await api.get<{ messages?: EmailSummary[] }>('/email/messages', {
          params: { accountId, folder, maxResults: 50 },
        })
        setMessages(safeArray<EmailSummary>(response.data?.messages))
        setSelectedMessage(null)
      } catch (err) {
        const msg = getErrorMessage(err)
        logger.error('EmailPage', 'Levél lista betöltési hiba:', err)
        setError(msg)
        setMessages([])
      } finally {
        setMessageLoading(false)
      }
    },
    [folder, selectedAccountId],
  )

  useEffect(() => {
    void loadData()
  }, [loadData])

  useEffect(() => {
    void loadMessages()
  }, [loadMessages])

  const filteredAccounts = accounts.filter((item) => {
    if (!accountSearch) return true
    const term = accountSearch.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  const openAccountForm = (account?: EmailAccountItem) => {
    setAccountForm({
      id: account?.id,
      gmailAddress: account?.gmailAddress ?? '',
      displayName: account?.displayName ?? '',
      isActive: account?.isActive ?? true,
      scopeType: 'workerId',
      scopeValue: worker?.id != null ? String(worker.id) : '',
    })
    setMessage(null)
    setError(null)
  }

  const saveAccount = async () => {
    if (!accountForm) return
    if (!accountForm.gmailAddress.trim() || !accountForm.scopeValue.trim()) {
      setError('Gmail cím és scope azonosító megadása kötelező.')
      return
    }
    const payload: Record<string, string | number | boolean> = {
      gmailAddress: accountForm.gmailAddress.trim(),
      displayName: accountForm.displayName.trim(),
      isActive: accountForm.isActive,
    }
    if (accountForm.scopeType === 'workerId') {
      payload.workerId = Number(accountForm.scopeValue)
    } else if (accountForm.scopeType === 'vaultTerritoryId') {
      payload.vaultTerritoryId = Number(accountForm.scopeValue)
    } else {
      payload[accountForm.scopeType] = accountForm.scopeValue.trim()
    }

    try {
      setSaving(true)
      setError(null)
      if (accountForm.id) {
        await api.put(`/email/accounts/${accountForm.id}`, payload)
        setMessage('E-mail fiók frissítve.')
      } else {
        await api.post('/email/accounts', payload)
        setMessage('E-mail fiók létrehozva.')
      }
      setAccountForm(null)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'Fiók mentési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const startOAuth = async (id: string) => {
    try {
      setError(null)
      const response = await api.get<{ authUrl?: string }>(`/email/accounts/${id}/auth`)
      if (response.data?.authUrl) {
        window.open(response.data.authUrl, '_blank', 'noopener,noreferrer')
      }
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'OAuth indítási hiba:', err)
      setError(msg)
    }
  }

  const deleteAccount = async (id: string) => {
    if (!confirm('Biztosan törli az e-mail fiókot?')) return
    try {
      setError(null)
      await api.delete(`/email/accounts/${id}`)
      setMessage('E-mail fiók törölve.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('EmailPage', 'Törlési hiba:', err)
    }
  }

  const searchMessages = async () => {
    if (!mailSearch.trim()) {
      await loadMessages()
      return
    }
    try {
      setMessageLoading(true)
      setError(null)
      const response = await api.get<EmailSummary[]>('/email/search', {
        params: {
          accountId: selectedAccountId || undefined,
          query: mailSearch.trim(),
          maxResults: 50,
        },
      })
      setMessages(safeArray<EmailSummary>(response.data))
      setSelectedMessage(null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'Levél keresési hiba:', err)
      setError(msg)
    } finally {
      setMessageLoading(false)
    }
  }

  const openMessage = async (id: string) => {
    try {
      setError(null)
      const response = await api.get<EmailDetail>(`/email/messages/${id}`, {
        params: { accountId: selectedAccountId || undefined },
      })
      setSelectedMessage(response.data ?? null)
      await api.post(`/email/messages/${id}/read`, undefined, {
        params: { accountId: selectedAccountId || undefined },
      })
      setMessages((current) =>
        current.map((item) => (item.id === id ? { ...item, isRead: true } : item)),
      )
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'Levél részlet hiba:', err)
      setError(msg)
    }
  }

  const deleteMessage = async (id: string) => {
    if (!confirm('Biztosan törli a levelet?')) return
    try {
      setError(null)
      await api.delete(`/email/messages/${id}`, {
        params: { accountId: selectedAccountId || undefined },
      })
      setMessages((current) => current.filter((item) => item.id !== id))
      if (selectedMessage?.id === id) setSelectedMessage(null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'Levél törlési hiba:', err)
      setError(msg)
    }
  }

  const openCompose = (mode: 'new' | 'reply' | 'forward') => {
    setComposeMode(mode)
    setMessage(null)
    setError(null)
    if (mode === 'reply' && selectedMessage) {
      setCompose({
        to: selectedMessage.from ?? '',
        subject: `Re: ${selectedMessage.subject ?? ''}`,
        body: '',
      })
    } else if (mode === 'forward' && selectedMessage) {
      setCompose({
        to: '',
        subject: `Fw: ${selectedMessage.subject ?? ''}`,
        body: selectedMessage.body ?? selectedMessage.htmlBody ?? '',
      })
    } else {
      setCompose({ to: '', subject: '', body: '' })
    }
  }

  const sendCompose = async () => {
    if (!composeMode) return
    if ((composeMode === 'new' || composeMode === 'forward') && !compose.to.trim()) {
      setError('Címzett megadása kötelező.')
      return
    }
    try {
      setSaving(true)
      setError(null)
      if (composeMode === 'reply' && selectedMessage) {
        await api.post(
          `/email/messages/${selectedMessage.id}/reply`,
          { body: compose.body },
          {
            params: { accountId: selectedAccountId || undefined },
          },
        )
        setMessage('Válasz elküldve.')
      } else if (composeMode === 'forward' && selectedMessage) {
        await api.post(
          `/email/messages/${selectedMessage.id}/forward`,
          { to: compose.to },
          {
            params: { accountId: selectedAccountId || undefined },
          },
        )
        setMessage('Továbbítás elküldve.')
      } else {
        await api.post(
          '/email/messages',
          {
            to: compose.to,
            subject: compose.subject,
            body: compose.body,
          },
          {
            params: { accountId: selectedAccountId || undefined },
          },
        )
        setMessage('Levél elküldve.')
      }
      setComposeMode(null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'Levél küldési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const downloadAttachment = async (attachmentId: string) => {
    if (!selectedMessage) return
    try {
      setError(null)
      const response = await api.get<Blob>(
        `/email/attachments/${selectedMessage.id}/${attachmentId}`,
        {
          params: { accountId: selectedAccountId || undefined },
          responseType: 'blob',
        },
      )
      const url = URL.createObjectURL(response.data)
      window.open(url, '_blank', 'noopener,noreferrer')
      window.setTimeout(() => URL.revokeObjectURL(url), 30_000)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmailPage', 'Csatolmány letöltési hiba:', err)
      setError(msg)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="form-title flex items-center gap-2">
          <Mail className="h-6 w-6" />
          {t('email.emailBeallitasok')}
        </h1>
        <div className="flex items-center gap-2">
          <span className="rounded border border-gray-200 bg-white px-3 py-2 text-sm">
            {i18n.t('literals.olvasatlan')}
            <b>{unreadCount ?? '-'}</b>
          </span>
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => openAccountForm()}
            className="form-button-primary flex items-center gap-1"
          >
            <Plus className="h-4 w-4" />
            {t('common.new')}
          </button>
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {message && (
        <div className="rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
          {message}
        </div>
      )}

      {accountForm && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">
            {accountForm.id ? 'E-mail fiók szerkesztése' : 'Új e-mail fiók'}
          </h2>
          <div className="grid gap-3 lg:grid-cols-5">
            <div>
              <label htmlFor="email-account-address" className="form-label">
                {i18n.t('literals.gmail-cim')}
              </label>
              <input
                id="email-account-address"
                className="form-input w-full"
                value={accountForm.gmailAddress}
                onChange={(e) =>
                  setAccountForm((current) =>
                    current ? { ...current, gmailAddress: e.target.value } : current,
                  )
                }
              />
            </div>
            <div>
              <label htmlFor="email-account-display" className="form-label">
                {i18n.t('literals.megjelenitett-nev')}
              </label>
              <input
                id="email-account-display"
                className="form-input w-full"
                value={accountForm.displayName}
                onChange={(e) =>
                  setAccountForm((current) =>
                    current ? { ...current, displayName: e.target.value } : current,
                  )
                }
              />
            </div>
            <div>
              <label htmlFor="email-account-scope-type" className="form-label">
                {i18n.t('literals.scope')}
              </label>
              <select
                id="email-account-scope-type"
                className="form-input w-full"
                value={accountForm.scopeType}
                onChange={(e) =>
                  setAccountForm((current) =>
                    current
                      ? { ...current, scopeType: e.target.value as EmailAccountForm['scopeType'] }
                      : current,
                  )
                }
              >
                <option value="workerId">{i18n.t('literals.dolgozo-id')}</option>
                <option value="branchId">{i18n.t('literals.fiok-uuid')}</option>
                <option value="ownCompanyId">{i18n.t('literals.sajat-ceg-uuid')}</option>
                <option value="vaultTerritoryId">{i18n.t('literals.ertektar-terulet-id')}</option>
              </select>
            </div>
            <div>
              <label htmlFor="email-account-scope-value" className="form-label">
                {i18n.t('literals.scope-azonosito')}
              </label>
              <input
                id="email-account-scope-value"
                className="form-input w-full"
                value={accountForm.scopeValue}
                onChange={(e) =>
                  setAccountForm((current) =>
                    current ? { ...current, scopeValue: e.target.value } : current,
                  )
                }
              />
            </div>
            <label className="flex items-end gap-2 pb-2 text-sm">
              <input
                type="checkbox"
                checked={accountForm.isActive}
                onChange={(e) =>
                  setAccountForm((current) =>
                    current ? { ...current, isActive: e.target.checked } : current,
                  )
                }
              />
              {i18n.t('literals.aktiv-2')}
            </label>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void saveAccount()}
              disabled={saving}
              className="form-button-primary"
            >
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button type="button" onClick={() => setAccountForm(null)} className="form-button">
              {i18n.t('literals.megse')}
            </button>
          </div>
        </div>
      )}

      <div className="grid gap-4 xl:grid-cols-[minmax(360px,1fr)_2fr]">
        <section className="space-y-3">
          <div className="rounded border border-gray-200 bg-white p-3 space-y-3">
            <div className="flex items-center gap-2">
              <Search className="h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Fiók keresés..."
                value={accountSearch}
                onChange={(e) => setAccountSearch(e.target.value)}
                className="form-input w-full"
              />
            </div>
            <div className="data-grid overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.gmail-cim')}
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.nev')}
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {t('common.active')}
                    </th>
                    <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                      {t('common.actions')}
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 bg-white">
                  {loading ? (
                    <tr>
                      <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                        {i18n.t('literals.betoltes')}
                      </td>
                    </tr>
                  ) : filteredAccounts.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                        {t('common.noData')}
                      </td>
                    </tr>
                  ) : (
                    filteredAccounts.map((item) => (
                      <tr
                        key={item.id}
                        className={
                          selectedAccountId === item.id ? 'bg-blue-50' : 'hover:bg-gray-50'
                        }
                      >
                        <td className="px-4 py-3 text-sm">
                          <button
                            type="button"
                            className="text-left text-blue-700 hover:underline"
                            onClick={() => setSelectedAccountId(item.id)}
                          >
                            {item.gmailAddress ?? '-'}
                          </button>
                        </td>
                        <td className="px-4 py-3 text-sm">{item.displayName ?? '-'}</td>
                        <td className="px-4 py-3 text-sm">{item.isActive ? 'Igen' : 'Nem'}</td>
                        <td className="px-4 py-3 text-right whitespace-nowrap">
                          <button
                            onClick={() => openAccountForm(item)}
                            className="form-button mr-2 p-1 text-blue-600"
                            title="Szerkesztés"
                          >
                            <Edit2 className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => void startOAuth(item.id)}
                            className="form-button mr-2 p-1"
                            title="OAuth kapcsolás"
                          >
                            <Mail className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => void deleteAccount(item.id)}
                            className="form-button p-1 text-red-600"
                            title="Törlés"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
            {configurableAccounts.length > 0 && (
              <div className="text-xs text-gray-500">
                {i18n.t('literals.konfiguralhato-fiokok')}
                {configurableAccounts.map(accountLabel).join(', ')}
              </div>
            )}
          </div>
        </section>

        <section className="space-y-3">
          <div className="rounded border border-gray-200 bg-white p-3 space-y-3">
            <div className="grid gap-2 md:grid-cols-[180px_1fr_auto_auto]">
              <select
                value={folder}
                onChange={(e) => setFolder(e.target.value)}
                className="form-input w-full"
              >
                <option value="INBOX">{i18n.t('literals.inbox')}</option>
                <option value="SENT">{i18n.t('literals.sent')}</option>
                <option value="TRASH">{i18n.t('literals.trash')}</option>
              </select>
              <input
                value={mailSearch}
                onChange={(e) => setMailSearch(e.target.value)}
                className="form-input w-full"
                placeholder="Levél keresés..."
              />
              <button
                type="button"
                onClick={() => void searchMessages()}
                className="form-button flex items-center gap-1"
              >
                <Search className="h-4 w-4" />
                {i18n.t('literals.kereses-2')}
              </button>
              <button
                type="button"
                onClick={() => openCompose('new')}
                className="form-button-primary flex items-center gap-1"
              >
                <Send className="h-4 w-4" />
                {i18n.t('literals.uj-level')}
              </button>
            </div>

            <div className="data-grid overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.targy')}
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.felado')}
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.erkezett')}
                    </th>
                    <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                      {t('common.actions')}
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 bg-white">
                  {messageLoading ? (
                    <tr>
                      <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                        {i18n.t('literals.betoltes')}
                      </td>
                    </tr>
                  ) : messages.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-4 py-8 text-center text-sm text-gray-500">
                        {t('common.noData')}
                      </td>
                    </tr>
                  ) : (
                    messages.map((item) => (
                      <tr
                        key={item.id}
                        className={
                          item.isRead ? 'hover:bg-gray-50' : 'bg-yellow-50 hover:bg-yellow-100'
                        }
                      >
                        <td className="px-4 py-3 text-sm">{item.subject ?? '-'}</td>
                        <td className="px-4 py-3 text-sm">{item.sender ?? item.from ?? '-'}</td>
                        <td className="px-4 py-3 text-sm">{fmtDate(item.receivedAt)}</td>
                        <td className="px-4 py-3 text-right whitespace-nowrap">
                          <button
                            onClick={() => void openMessage(item.id)}
                            className="form-button mr-2 p-1"
                            title="Megnyitás"
                          >
                            <Eye className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => void deleteMessage(item.id)}
                            className="form-button p-1 text-red-600"
                            title="Törlés"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {selectedMessage && (
            <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="text-base font-semibold">{selectedMessage.subject ?? '-'}</h2>
                  <div className="text-sm text-gray-500">{selectedMessage.from ?? '-'}</div>
                </div>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => openCompose('reply')}
                    className="form-button flex items-center gap-1"
                  >
                    <Reply className="h-4 w-4" />
                    {i18n.t('literals.valasz')}
                  </button>
                  <button
                    type="button"
                    onClick={() => openCompose('forward')}
                    className="form-button flex items-center gap-1"
                  >
                    <Forward className="h-4 w-4" />
                    {i18n.t('literals.tovabbitas')}
                  </button>
                </div>
              </div>
              <div className="text-sm">
                <span className="text-gray-500">{i18n.t('literals.cimzettek')}</span>{' '}
                {(selectedMessage.to ?? []).join(', ') || '-'}
              </div>
              <div className="rounded border border-gray-200 bg-gray-50 p-3 text-sm whitespace-pre-wrap">
                {selectedMessage.body ?? selectedMessage.htmlBody ?? ''}
              </div>
              {(selectedMessage.attachments ?? []).length > 0 && (
                <div className="space-y-2">
                  <h3 className="text-sm font-semibold">{i18n.t('literals.csatolmanyok')}</h3>
                  {selectedMessage.attachments?.map((attachment) => (
                    <button
                      key={attachment.attachmentId}
                      type="button"
                      onClick={() => void downloadAttachment(attachment.attachmentId)}
                      className="form-button mr-2 flex items-center gap-1"
                    >
                      <Download className="h-4 w-4" />
                      {attachment.filename ?? attachment.attachmentId}
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}

          {composeMode && (
            <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
              <h2 className="text-base font-semibold">
                {composeMode === 'reply'
                  ? 'Válasz'
                  : composeMode === 'forward'
                    ? 'Továbbítás'
                    : 'Új levél'}
              </h2>
              {composeMode !== 'reply' && (
                <div>
                  <label htmlFor="email-compose-to" className="form-label">
                    {i18n.t('literals.cimzett')}
                  </label>
                  <input
                    id="email-compose-to"
                    value={compose.to}
                    onChange={(e) => setCompose((current) => ({ ...current, to: e.target.value }))}
                    className="form-input w-full"
                  />
                </div>
              )}
              {composeMode === 'new' && (
                <div>
                  <label htmlFor="email-compose-subject" className="form-label">
                    {i18n.t('literals.targy')}
                  </label>
                  <input
                    id="email-compose-subject"
                    value={compose.subject}
                    onChange={(e) =>
                      setCompose((current) => ({ ...current, subject: e.target.value }))
                    }
                    className="form-input w-full"
                  />
                </div>
              )}
              <div>
                <label htmlFor="email-compose-body" className="form-label">
                  {i18n.t('literals.szoveg')}
                </label>
                <textarea
                  id="email-compose-body"
                  value={compose.body}
                  onChange={(e) => setCompose((current) => ({ ...current, body: e.target.value }))}
                  className="form-input h-32 w-full"
                />
              </div>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => void sendCompose()}
                  disabled={saving}
                  className="form-button-primary"
                >
                  {saving ? 'Küldés...' : 'Küldés'}
                </button>
                <button type="button" onClick={() => setComposeMode(null)} className="form-button">
                  {i18n.t('literals.megse')}
                </button>
              </div>
            </div>
          )}
        </section>
      </div>

      <div className="text-sm text-gray-500">
        {t('audit.osszesen')}
        {filteredAccounts.length}
        {i18n.t('literals.lit-10')}
        {accounts.length}
      </div>
    </div>
  )
}
