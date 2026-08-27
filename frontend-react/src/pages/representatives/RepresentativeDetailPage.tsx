import { useState, useEffect } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  User,
  FileText,
  AlertCircle,
  Loader2,
  Pencil,
  Save,
  Trash2,
  X,
} from 'lucide-react'
import {
  authorizedRepresentativeApi,
  AuthorizedRepresentative,
  RepresentativeRegistrationRequest,
} from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import AuthorizationSection from '../../components/representatives/AuthorizationSection'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function RepresentativeDetailPage() {
  const { t } = useTranslation()
  const { customerId, representativeId } = useParams<{
    customerId: string
    representativeId: string
  }>()
  const navigate = useNavigate()
  const [rep, setRep] = useState<AuthorizedRepresentative | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [editing, setEditing] = useState(false)
  const [form, setForm] = useState<RepresentativeRegistrationRequest | null>(null)

  useEffect(() => {
    if (!representativeId) return
    const load = async () => {
      try {
        setLoading(true)
        const found = await authorizedRepresentativeApi.getById(representativeId)
        setRep(found)
      } catch (err) {
        setError(getErrorMessage(err))
        logger.error('RepresentativeDetailPage', 'Failed to load representative:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [customerId, representativeId])

  const startEdit = () => {
    if (!rep) return
    setForm({
      name: rep.fullName || [rep.lastName, rep.firstName].filter(Boolean).join(' '),
      firstName: rep.firstName || undefined,
      lastName: rep.lastName || undefined,
      birthDate: rep.birthDate || undefined,
      birthPlace: rep.birthPlace || undefined,
      nationalityDid: rep.nationalityDid || undefined,
      documentType: rep.documentTypeDid || 'Személyi igazolvány',
      documentTypeDid: rep.documentTypeDid || undefined,
      documentNumber: rep.documentNumber || '',
      documentValidFrom: rep.documentValidFrom || undefined,
      documentValidTo: rep.documentValidTo || undefined,
      address: rep.address || undefined,
      phone: rep.phone || undefined,
      email: rep.email || undefined,
      representativeTypeDid: rep.representativeTypeDid || undefined,
      relationshipDid: rep.relationshipDid || undefined,
      authorizationStart: rep.authorizationStart || new Date().toISOString().slice(0, 10),
      authorizationEnd: rep.authorizationEnd || undefined,
    })
    setError(null)
    setEditing(true)
  }

  const updateForm = (field: keyof RepresentativeRegistrationRequest, value: string) => {
    setForm((prev) => (prev ? { ...prev, [field]: value || undefined } : prev))
  }

  const saveEdit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!representativeId || !form) return
    try {
      setSaving(true)
      setError(null)
      const saved = await authorizedRepresentativeApi.update(representativeId, {
        ...form,
        name: form.name.trim(),
        documentType: form.documentType.trim(),
        documentNumber: form.documentNumber.trim(),
      })
      setRep((prev) => ({
        ...saved,
        customerName: saved.customerName || prev?.customerName || '',
      }))
      setEditing(false)
      setForm(null)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('RepresentativeDetailPage', 'Failed to update representative:', err)
    } finally {
      setSaving(false)
    }
  }

  const deleteRepresentative = async () => {
    if (!representativeId || !customerId) return
    if (!confirm('Biztosan törli ezt a meghatalmazottat?')) return
    try {
      setSaving(true)
      setError(null)
      await authorizedRepresentativeApi.delete(representativeId)
      navigate(`/customers/${customerId}/representatives`)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('RepresentativeDetailPage', 'Failed to delete representative:', err)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12 text-gray-500 gap-2">
        <Loader2 size={20} className="animate-spin" />
        {i18n.t('literals.betoltes')}
      </div>
    )
  }

  if (!rep) {
    return (
      <div className="form-panel text-center py-8">
        <AlertCircle className="inline mr-2" size={16} />
        {error || 'Meghatalmazott nem található'}
        <div className="mt-4">
          <Link to={`/customers/${customerId}/representatives`} className="form-button">
            {t('common.back')}
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <Link to={`/customers/${customerId}/representatives`} className="toolbar-button">
            <ArrowLeft size={18} />
          </Link>
          <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2 min-w-0">
            <User className="shrink-0" />
            <span className="truncate">{rep.fullName}</span>
            <span
              className={`px-2 py-1 text-xs rounded shrink-0 ${
                rep.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
              }`}
            >
              {rep.isActive ? 'Aktív' : 'Inaktív'}
            </span>
          </h1>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          {editing ? (
            <button
              type="button"
              onClick={() => {
                setEditing(false)
                setForm(null)
              }}
              className="form-button flex items-center gap-1"
              disabled={saving}
            >
              <X size={16} />
              {i18n.t('literals.megse')}
            </button>
          ) : (
            <button
              type="button"
              onClick={startEdit}
              className="form-button flex items-center gap-1"
              disabled={saving}
            >
              <Pencil size={16} />
              {i18n.t('literals.szerkesztes-2')}
            </button>
          )}
          <button
            type="button"
            onClick={() => void deleteRepresentative()}
            className="form-button text-red-700 flex items-center gap-1"
            disabled={saving}
          >
            <Trash2 size={16} />
            {i18n.t('literals.torles')}
          </button>
        </div>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      {editing && form && (
        <form onSubmit={(e) => void saveEdit(e)} className="form-panel space-y-3">
          <h2 className="section-title flex items-center gap-2">
            <Pencil size={16} />
            {i18n.t('literals.meghatalmazott-szerkesztese')}
          </h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label required">{i18n.t('literals.teljes-nev')}</label>
              <input
                className="form-input"
                value={form.name}
                onChange={(e) => updateForm('name', e.target.value)}
                required
              />
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.kapcsolat')}</label>
              <select
                className="form-input"
                value={form.relationshipDid || ''}
                onChange={(e) => updateForm('relationshipDid', e.target.value)}
              >
                <option value="">{i18n.t('literals.lit-8')}</option>
                <option value="FAMILY">{i18n.t('literals.csaladtag')}</option>
                <option value="COLLEAGUE">{i18n.t('literals.munkatars')}</option>
                <option value="FRIEND">{i18n.t('literals.barat')}</option>
                <option value="PROFESSIONAL">{i18n.t('literals.szakmai')}</option>
                <option value="BUSINESS">{i18n.t('literals.uzleti')}</option>
                <option value="OTHER">{i18n.t('literals.egyeb')}</option>
              </select>
            </div>
            <div>
              <label className="form-label required">{i18n.t('literals.okmany-tipusa')}</label>
              <input
                className="form-input"
                value={form.documentType}
                onChange={(e) => updateForm('documentType', e.target.value)}
                required
              />
            </div>
            <div>
              <label className="form-label required">{i18n.t('literals.okmanyszam')}</label>
              <input
                className="form-input font-mono"
                value={form.documentNumber}
                onChange={(e) => updateForm('documentNumber', e.target.value)}
                required
              />
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.okmany-ervenyes-tol')}</label>
              <input
                type="date"
                className="form-input"
                value={form.documentValidFrom || ''}
                onChange={(e) => updateForm('documentValidFrom', e.target.value)}
              />
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.okmany-ervenyes-ig')}</label>
              <input
                type="date"
                className="form-input"
                value={form.documentValidTo || ''}
                onChange={(e) => updateForm('documentValidTo', e.target.value)}
              />
            </div>
            <div>
              <label className="form-label required">
                {i18n.t('literals.meghatalmazas-kezdete')}
              </label>
              <input
                type="date"
                className="form-input"
                value={form.authorizationStart}
                onChange={(e) => updateForm('authorizationStart', e.target.value)}
                required
              />
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.meghatalmazas-vege')}</label>
              <input
                type="date"
                className="form-input"
                value={form.authorizationEnd || ''}
                onChange={(e) => updateForm('authorizationEnd', e.target.value)}
              />
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.telefon')}</label>
              <input
                className="form-input font-mono"
                value={form.phone || ''}
                onChange={(e) => updateForm('phone', e.target.value)}
              />
            </div>
            <div>
              <label className="form-label">{i18n.t('literals.e-mail')}</label>
              <input
                type="email"
                className="form-input"
                value={form.email || ''}
                onChange={(e) => updateForm('email', e.target.value)}
              />
            </div>
            <div className="col-span-2">
              <label className="form-label">{i18n.t('literals.cim')}</label>
              <input
                className="form-input"
                value={form.address || ''}
                onChange={(e) => updateForm('address', e.target.value)}
              />
            </div>
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={saving}
              className="form-button-primary flex items-center gap-1"
            >
              <Save size={16} />
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
          </div>
        </form>
      )}

      <div className="grid grid-cols-2 gap-3">
        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2">
            <User size={16} />
            {t('representatives.szemelyesAdatok')}
          </h2>
          <dl className="space-y-2">
            <div className="flex justify-between">
              <dt className="text-gray-500 text-sm">{t('representatives.teljesNev')}</dt>
              <dd className="font-semibold">{rep.fullName}</dd>
            </div>
            {rep.birthDate && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('common.birthDate')}</dt>
                <dd>{new Date(rep.birthDate).toLocaleDateString('hu-HU')}</dd>
              </div>
            )}
            {rep.birthPlace && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('common.birthPlace')}</dt>
                <dd>{rep.birthPlace}</dd>
              </div>
            )}
            {rep.nationalityDid && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('common.nationality')}</dt>
                <dd>{rep.nationalityDid}</dd>
              </div>
            )}
            {rep.address && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('common.address')}</dt>
                <dd>{rep.address}</dd>
              </div>
            )}
            {rep.phone && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('common.phone')}</dt>
                <dd className="font-mono">{rep.phone}</dd>
              </div>
            )}
            {rep.email && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('customers.eMail')}</dt>
                <dd>{rep.email}</dd>
              </div>
            )}
            {rep.relationshipDid && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('display.kapcsolat')}</dt>
                <dd>{rep.relationshipDid}</dd>
              </div>
            )}
            {rep.representativeTypeDid && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('common.type')}</dt>
                <dd>{rep.representativeTypeDid}</dd>
              </div>
            )}
          </dl>
        </div>

        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2">
            <FileText size={16} />
            {t('customers.okmanyAdatok')}
          </h2>
          <dl className="space-y-2">
            <div className="flex justify-between">
              <dt className="text-gray-500 text-sm">{t('customers.okmanyTipus')}</dt>
              <dd>{rep.documentTypeDid || '-'}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-gray-500 text-sm">{t('common.documentNumber')}</dt>
              <dd className="font-mono font-semibold">{rep.documentNumber || '-'}</dd>
            </div>
            {rep.documentValidFrom && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('representatives.ervenyesTol')}</dt>
                <dd>{new Date(rep.documentValidFrom).toLocaleDateString('hu-HU')}</dd>
              </div>
            )}
            {rep.documentValidTo && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">{t('representatives.ervenyesIg')}</dt>
                <dd>{new Date(rep.documentValidTo).toLocaleDateString('hu-HU')}</dd>
              </div>
            )}
            <div className="flex justify-between">
              <dt className="text-gray-500 text-sm">{t('representatives.regisztralva')}</dt>
              <dd>{rep.registeredAt ? new Date(rep.registeredAt).toLocaleString('hu-HU') : '-'}</dd>
            </div>
          </dl>
        </div>
      </div>

      {/* Meghatalmazások szekció */}
      {representativeId && <AuthorizationSection representativeId={representativeId} />}
    </div>
  )
}
