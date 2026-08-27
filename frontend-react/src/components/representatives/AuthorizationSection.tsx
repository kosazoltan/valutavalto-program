import { useState, useEffect, useCallback } from 'react'
import { Shield, Plus, CheckCircle, XCircle, Pause, Play, AlertCircle, Loader2 } from 'lucide-react'
import {
  authorizedRepresentativeApi,
  Authorization,
  AuthorizationCreateRequest,
} from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../ui/toaster'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import { useTextReasonModal } from '../TextReasonModal'
import i18n from '../../i18n'

interface Props {
  representativeId: string
}

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  PENDING: { label: 'Függőben', color: 'bg-yellow-100 text-yellow-700' },
  ACTIVE: { label: 'Aktív', color: 'bg-green-100 text-green-700' },
  SUSPENDED: { label: 'Felfüggesztve', color: 'bg-orange-100 text-orange-700' },
  REVOKED: { label: 'Visszavonva', color: 'bg-red-100 text-red-700' },
}

export default function AuthorizationSection({ representativeId }: Props) {
  const { t } = useTranslation()
  const worker = useAuthStore((s) => s.worker)
  const workerId = worker?.id ?? 0

  const [authorizations, setAuthorizations] = useState<Authorization[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  const [form, setForm] = useState<AuthorizationCreateRequest>({
    operationDid: 'CURRENCY_EXCHANGE',
    startDate: new Date().toISOString().split('T')[0]!,
  })

  // FKH-027 C-csoport: a natív window.prompt() kiváltása (Electronban silent no-op)
  const { modal: reasonModal, requestReason } = useTextReasonModal()

  const loadAuthorizations = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await authorizedRepresentativeApi.findAuthorizations(representativeId)
      setAuthorizations(data)
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [representativeId])

  useEffect(() => {
    void loadAuthorizations()
  }, [loadAuthorizations])

  const handleCreate = async () => {
    try {
      setSubmitting(true)
      await authorizedRepresentativeApi.createAuthorization(representativeId, form, workerId)
      toast.success('Meghatalmazás létrehozva')
      setShowForm(false)
      setForm({
        operationDid: 'CURRENCY_EXCHANGE',
        startDate: new Date().toISOString().split('T')[0]!,
      })
      void loadAuthorizations()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setSubmitting(false)
    }
  }

  const handleAction = async (
    authId: string,
    action: 'verify' | 'suspend' | 'resume' | 'revoke',
  ) => {
    const reason =
      action === 'suspend' || action === 'revoke'
        ? await requestReason({
            title: `${action === 'suspend' ? 'Felfüggesztés' : 'Visszavonás'} oka:`,
          })
        : undefined
    // Az őr változatlan: trim nélküli falsy-vizsgálat, tehát a null (Mégse) ÉS az
    // üres string (OK üresen) egyaránt a "nincs API-hívás" ágba tartozik.
    if ((action === 'suspend' || action === 'revoke') && !reason) return

    try {
      if (action === 'verify') {
        await authorizedRepresentativeApi.verifyAuthorization(authId, workerId)
      } else if (action === 'suspend') {
        await authorizedRepresentativeApi.suspendAuthorization(authId, workerId, reason!)
      } else if (action === 'resume') {
        await authorizedRepresentativeApi.resumeAuthorization(authId, workerId)
      } else {
        await authorizedRepresentativeApi.revokeAuthorization(authId, workerId, reason!)
      }
      toast.success('Művelet sikeres')
      void loadAuthorizations()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const getStatusBadge = (status?: string) => {
    const s = STATUS_LABELS[status || 'PENDING'] || STATUS_LABELS.PENDING!
    return <span className={`px-2 py-1 text-xs rounded ${s.color}`}>{s.label}</span>
  }

  return (
    <div className="form-panel">
      <div className="flex justify-between items-center mb-3">
        <h2 className="section-title flex items-center gap-2">
          <Shield size={16} />
          {t('components.meghatalmazasok')}
        </h2>
        <button
          onClick={() => setShowForm(!showForm)}
          className="form-button flex items-center gap-1"
        >
          <Plus size={14} />
          {t('components.ujMeghatalmazas')}
        </button>
      </div>

      {error && (
        <div className="flex items-center gap-2 text-red-600 text-sm mb-2">
          <AlertCircle size={14} /> {error}
        </div>
      )}

      {showForm && (
        <div className="border rounded p-3 mb-3 bg-gray-50 space-y-2">
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="text-sm text-gray-600">{t('components.muveletTipus')}</label>
              <select
                value={form.operationDid}
                onChange={(e) => setForm({ ...form, operationDid: e.target.value })}
                className="form-input w-full"
              >
                <option value="CURRENCY_EXCHANGE">{t('components.valutavaltas')}</option>
                <option value="CASH_DEPOSIT">{t('components.keszpenzBefizetes')}</option>
                <option value="CASH_WITHDRAWAL">{t('components.keszpenzKifizetes')}</option>
                <option value="ALL_OPERATIONS">{t('components.mindenMuvelet')}</option>
              </select>
            </div>
            <div>
              <label className="text-sm text-gray-600">{t('common.startDate')}</label>
              <input
                type="date"
                value={form.startDate}
                onChange={(e) => setForm({ ...form, startDate: e.target.value })}
                className="form-input w-full"
              />
            </div>
            <div>
              <label className="text-sm text-gray-600">{t('components.lejaratiDatum')}</label>
              <input
                type="date"
                value={form.expiryDate || ''}
                onChange={(e) => setForm({ ...form, expiryDate: e.target.value || undefined })}
                className="form-input w-full"
              />
            </div>
            <div>
              <label className="text-sm text-gray-600">{t('components.osszegLimitFt')}</label>
              <input
                type="number"
                value={form.maxAmount || ''}
                onChange={(e) =>
                  setForm({
                    ...form,
                    maxAmount: e.target.value ? Number(e.target.value) : undefined,
                  })
                }
                className="form-input w-full"
                placeholder="Korlátlan"
              />
            </div>
            <div>
              <label className="text-sm text-gray-600">{t('components.maxTranzakcioszam')}</label>
              <input
                type="number"
                min={1}
                value={form.maxTransactionCount || ''}
                onChange={(e) =>
                  setForm({
                    ...form,
                    maxTransactionCount: e.target.value ? Number(e.target.value) : undefined,
                  })
                }
                className="form-input w-full"
                placeholder="Korlátlan"
              />
            </div>
            <div>
              <label className="text-sm text-gray-600">{t('components.egyszeriLimitFt')}</label>
              <input
                type="number"
                value={form.singleTransactionLimit || ''}
                onChange={(e) =>
                  setForm({
                    ...form,
                    singleTransactionLimit: e.target.value ? Number(e.target.value) : undefined,
                  })
                }
                className="form-input w-full"
                placeholder="Korlátlan"
              />
            </div>
            <div>
              <label className="text-sm text-gray-600">{t('common.note')}</label>
              <input
                type="text"
                value={form.notes || ''}
                onChange={(e) => setForm({ ...form, notes: e.target.value || undefined })}
                className="form-input w-full"
              />
            </div>
          </div>
          <div className="flex justify-end gap-2 mt-2">
            <button onClick={() => setShowForm(false)} className="form-button">
              {t('common.cancel')}
            </button>
            <button onClick={handleCreate} disabled={submitting} className="form-button-primary">
              {submitting ? 'Mentés...' : 'Létrehozás'}
            </button>
          </div>
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center py-4 text-gray-500 gap-2">
          <Loader2 size={16} className="animate-spin" />
          {i18n.t('literals.betoltes-2')}
        </div>
      ) : authorizations.length === 0 ? (
        <div className="text-center py-4 text-gray-500 text-sm">
          {t('components.nincsMeghatalmazas')}
        </div>
      ) : (
        <table className="data-grid w-full text-sm">
          <thead>
            <tr>
              <th>{t('common.operation')}</th>
              <th>{t('common.status')}</th>
              <th>{t('components.kezdet')}</th>
              <th>{t('components.lejarat')}</th>
              <th>{t('components.limit')}</th>
              <th>{t('components.hasznalat')}</th>
              <th className="w-32">{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {authorizations.map((auth) => (
              <tr key={auth.id}>
                <td>{auth.authorizationTypeDid || '-'}</td>
                <td>{getStatusBadge(auth.statusDid)}</td>
                <td>
                  {auth.startDate ? new Date(auth.startDate).toLocaleDateString('hu-HU') : '-'}
                </td>
                <td>
                  {auth.expiryDate
                    ? new Date(auth.expiryDate).toLocaleDateString('hu-HU')
                    : 'Korlátlan'}
                </td>
                <td className="font-mono">
                  {auth.maxAmount != null
                    ? `${auth.maxAmount.toLocaleString('hu-HU')} Ft`
                    : 'Korlátlan'}
                </td>
                <td className="font-mono">
                  {auth.usedTransactionCount ?? 0}
                  {i18n.t('literals.lit-10')}
                  {auth.maxTransactionCount ?? '∞'}
                </td>
                <td>
                  <div className="flex gap-1">
                    {auth.statusDid === 'PENDING' && (
                      <button
                        onClick={() => handleAction(auth.id, 'verify')}
                        className="toolbar-button text-green-600"
                        title="Jóváhagyás"
                      >
                        <CheckCircle size={14} />
                      </button>
                    )}
                    {auth.statusDid === 'ACTIVE' && (
                      <button
                        onClick={() => handleAction(auth.id, 'suspend')}
                        className="toolbar-button text-orange-600"
                        title="Felfüggesztés"
                      >
                        <Pause size={14} />
                      </button>
                    )}
                    {auth.statusDid === 'SUSPENDED' && (
                      <button
                        onClick={() => handleAction(auth.id, 'resume')}
                        className="toolbar-button text-green-600"
                        title="Újraaktiválás"
                      >
                        <Play size={14} />
                      </button>
                    )}
                    {auth.statusDid !== 'REVOKED' && (
                      <button
                        onClick={() => handleAction(auth.id, 'revoke')}
                        className="toolbar-button text-red-600"
                        title="Visszavonás"
                      >
                        <XCircle size={14} />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      {reasonModal}
    </div>
  )
}
