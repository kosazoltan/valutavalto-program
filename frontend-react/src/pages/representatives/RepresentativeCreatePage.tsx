import { useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { ArrowLeft, Save, AlertCircle } from 'lucide-react'
import { authorizedRepresentativeApi, RepresentativeRegistrationRequest } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'

export default function RepresentativeCreatePage() {
  const { t } = useTranslation()
  const { customerId } = useParams<{ customerId: string }>()
  const navigate = useNavigate()
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState({
    name: '',
    documentType: 'Személyi igazolvány',
    documentNumber: '',
    documentValidTo: '',
    address: '',
    phone: '',
    email: '',
    relationshipDid: '',
    authorizationStart: new Date().toISOString().slice(0, 10),
    authorizationEnd: '',
  })

  const update = (field: string, value: string) => {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!customerId) return
    try {
      setSaving(true)
      setError(null)
      const req: RepresentativeRegistrationRequest = {
        name: form.name,
        documentType: form.documentType,
        documentNumber: form.documentNumber,
        documentValidTo: form.documentValidTo || undefined,
        address: form.address || undefined,
        phone: form.phone || undefined,
        email: form.email || undefined,
        relationshipDid: form.relationshipDid || undefined,
        authorizationStart: form.authorizationStart,
        authorizationEnd: form.authorizationEnd || undefined,
      }
      await authorizedRepresentativeApi.register(customerId, req, '')
      navigate(`/customers/${customerId}/representatives`)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('RepresentativeCreatePage', 'Failed to create representative:', err)
    } finally {
      setSaving(false)
    }
  }

  if (!customerId) {
    return <div className="form-panel text-center py-8 text-gray-500">{t('representatives.ugyfelIdHianyzik')}</div>
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-3">
        <Link to={`/customers/${customerId}/representatives`} className="toolbar-button">
          <ArrowLeft size={18} />
        </Link>
        <h1 className="text-xl font-bold text-gray-800">{t('representatives.ujMeghatalmazott')}</h1>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      <form onSubmit={(e) => void handleSubmit(e)} className="space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <div className="form-panel">
            <h2 className="section-title">{t('representatives.szemelyesAdatok')}</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label required">{t('representatives.teljesNev')}</label>
                <input type="text" value={form.name} onChange={(e) => update('name', e.target.value)} className="form-input" required />
              </div>
              <div>
                <label className="form-label">{t('common.address')}</label>
                <input type="text" value={form.address} onChange={(e) => update('address', e.target.value)} className="form-input" />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="form-label">{t('common.phone')}</label>
                  <input type="tel" value={form.phone} onChange={(e) => update('phone', e.target.value)} className="form-input font-mono" />
                </div>
                <div>
                  <label className="form-label">{t('customers.eMail')}</label>
                  <input type="email" value={form.email} onChange={(e) => update('email', e.target.value)} className="form-input" />
                </div>
              </div>
              <div>
                <label className="form-label">{t('pos.kapcsolatTipusa')}</label>
                <select value={form.relationshipDid} onChange={(e) => update('relationshipDid', e.target.value)} className="form-input">
                  <option value="">—</option>
                  <option value="FAMILY">{t('pep.csaladtag')}</option>
                  <option value="COLLEAGUE">{t('representatives.munkatars')}</option>
                  <option value="FRIEND">{t('representatives.barat')}</option>
                  <option value="PROFESSIONAL">{t('representatives.szakmai')}</option>
                  <option value="BUSINESS">{t('representatives.uzleti')}</option>
                  <option value="OTHER">{t('common.other')}</option>
                </select>
              </div>
            </div>
          </div>

          <div className="form-panel">
            <h2 className="section-title">{t('customers.okmanyAdatok')}</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label required">{t('customers.okmanyTipusa')}</label>
                <select value={form.documentType} onChange={(e) => update('documentType', e.target.value)} className="form-input" required>
                  <option>{t('customers.szemelyiIgazolvany')}</option>
                  <option>{t('customers.utlevel')}</option>
                  <option>{t('customers.vezetoiEngedely')}</option>
                  <option>{t('customers.tartozkodasiEngedely')}</option>
                </select>
              </div>
              <div>
                <label className="form-label required">{t('common.documentNumber')}</label>
                <input type="text" value={form.documentNumber} onChange={(e) => update('documentNumber', e.target.value)} className="form-input font-mono" required />
              </div>
              <div>
                <label className="form-label">{t('representatives.okmanyLejarat')}</label>
                <input type="date" value={form.documentValidTo} onChange={(e) => update('documentValidTo', e.target.value)} className="form-input" />
              </div>
            </div>

            <h2 className="section-title mt-4">{t('commissions.ervenyesseg')}</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label required">{t('representatives.meghatalmazasKezdete')}</label>
                <input type="date" value={form.authorizationStart} onChange={(e) => update('authorizationStart', e.target.value)} className="form-input" required />
              </div>
              <div>
                <label className="form-label">{t('representatives.meghatalmazasVege')}</label>
                <input type="date" value={form.authorizationEnd} onChange={(e) => update('authorizationEnd', e.target.value)} className="form-input" />
              </div>
            </div>
          </div>
        </div>

        <div className="form-panel flex justify-end gap-2">
          <Link to={`/customers/${customerId}/representatives`} className="form-button">{t('common.cancel')}</Link>
          <button type="submit" disabled={saving} className="form-button-primary flex items-center gap-1">
            <Save size={16} />
            {saving ? 'Mentés...' : 'Mentés'}
          </button>
        </div>
      </form>
    </div>
  )
}
