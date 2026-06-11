import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import {
  User, ArrowLeft, Save, Edit, Clock, FileText,
  Phone, MapPin, CreditCard, Calendar, AlertCircle, Loader2, Users, ShieldCheck
} from 'lucide-react'
import { customerApi, Customer, CustomerCreateRequest } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'

export default function CustomerDetailPage() {
  const { t } = useTranslation()
  const { id } = useParams<{ id: string }>()
  const [isEditing, setIsEditing] = useState(false)
  const [customer, setCustomer] = useState<Customer | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  // V.2.7 c) Pmt. 30.§ (1) manuális EDD-jelölés (V309/V310) — supervisor+ művelet
  const hasRole = useAuthStore((s) => s.hasRole)
  const canMarkEdd = hasRole('SUPERVISOR') || hasRole('MANAGER')
  const [showEddModal, setShowEddModal] = useState(false)
  const [eddReasonInput, setEddReasonInput] = useState('')
  const [eddSaving, setEddSaving] = useState(false)
  const [eddError, setEddError] = useState<string | null>(null)

  const handleMarkEdd = async () => {
    if (!id || !eddReasonInput.trim()) {
      setEddError('Az indok megadása kötelező.')
      return
    }
    try {
      setEddSaving(true)
      setEddError(null)
      const updated = await customerApi.markEdd(Number(id), eddReasonInput.trim())
      setCustomer(updated)
      setShowEddModal(false)
      setEddReasonInput('')
    } catch (err) {
      setEddError(getErrorMessage(err))
      logger.error('CustomerDetailPage', 'EDD-jelölés hiba:', err)
    } finally {
      setEddSaving(false)
    }
  }

  useEffect(() => {
    if (!id) return
    const load = async () => {
      try {
        setLoading(true)
        setError(null)
        const data = await customerApi.getById(Number(id))
        setCustomer(data)
      } catch (err) {
        setError(getErrorMessage(err))
        logger.error('CustomerDetailPage', 'Failed to load customer:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [id])

  const handleSave = async () => {
    if (!customer || !id) return
    try {
      setSaving(true)
      setError(null)
      const req: CustomerCreateRequest = {
        name: customer.name,
        birthName: customer.birthName,
        motherName: customer.motherName,
        birthDate: customer.birthDate,
        birthPlace: customer.birthPlace,
        nationality: customer.nationality,
        documentNumber: customer.documentNumber,
        documentType: customer.documentType,
        documentExpiry: customer.documentExpiry,
        address: customer.address,
        postalCode: customer.postalCode,
        city: customer.city,
        country: customer.country,
        phone: customer.phone,
        email: customer.email,
        isCompany: customer.isCompany,
        companyName: customer.companyName,
        taxNumber: customer.taxNumber,
        registrationNumber: customer.registrationNumber,
        isVip: customer.isVip,
        isPep: customer.isPep,
        notes: customer.notes,
      }
      const updated = await customerApi.update(Number(id), req)
      setCustomer(updated)
      setIsEditing(false)
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12 text-gray-500 gap-2">
        <Loader2 size={20} className="animate-spin" />
        Betöltés...
      </div>
    )
  }

  if (!customer) {
    return (
      <div className="form-panel text-center py-8">
        <AlertCircle className="inline mr-2" size={16} />
        {error || 'Ügyfél nem található'}
        <div className="mt-4">
          <Link to="/customers" className="form-button">{t('common.back')}</Link>
        </div>
      </div>
    )
  }

  const updateField = <K extends keyof Customer>(field: K, value: Customer[K]) => {
    setCustomer(prev => prev ? { ...prev, [field]: value } : prev)
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-3">
          <Link to="/customers" className="toolbar-button">
            <ArrowLeft size={18} />
          </Link>
          <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
            <User />
            {t('customers.ugyfelAdatai')}
            {customer.isVip && <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded">VIP</span>}
            {customer.eddActive && (
              <span
                title={customer.eddReason || 'Megerősített eljárás (V.2.7)'}
                className="text-xs bg-red-100 text-red-700 px-2 py-0.5 rounded flex items-center gap-1"
              >
                <ShieldCheck size={12} />
                EDD {customer.eddUntil}-ig
              </span>
            )}
          </h1>
        </div>
        <div className="flex gap-2">
          {canMarkEdd && !isEditing && (
            <button
              onClick={() => { setEddError(null); setShowEddModal(true) }}
              className="form-button flex items-center gap-1 text-red-700"
              title="Pmt. 30.§ (1) bejelentett ügyfél megerősített eljárás (EDD) alá vonása 1 évre"
            >
              <ShieldCheck size={16} />
              EDD-jelölés (Pmt. 30.§)
            </button>
          )}
          <Link
            to={`/customers/${id}/representatives`}
            className="form-button flex items-center gap-1"
          >
            <Users size={16} />
            {t('customers.meghatalmazottak')}
          </Link>
          {isEditing ? (
            <>
              <button onClick={() => setIsEditing(false)} className="form-button">
                {t('common.cancel')}
              </button>
              <button onClick={() => void handleSave()} disabled={saving} className="form-button-primary flex items-center gap-1">
                <Save size={16} />
                {saving ? 'Mentés...' : 'Mentés'}
              </button>
            </>
          ) : (
            <button onClick={() => setIsEditing(true)} className="form-button flex items-center gap-1">
              <Edit size={16} />
              {t('common.edit')}
            </button>
          )}
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

      <div className="grid grid-cols-3 gap-3">
        {/* Basic Info */}
        <div className="form-panel col-span-2">
          <h2 className="section-title">{t('customers.alapadatok')}</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">{t('common.name')}</label>
              <input type="text" value={customer.name || ''} onChange={(e) => updateField('name', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">{t('common.birthName')}</label>
              <input type="text" value={customer.birthName || ''} onChange={(e) => updateField('birthName', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">{t('common.birthDate')}</label>
              <input type="date" value={customer.birthDate || ''} onChange={(e) => updateField('birthDate', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">{t('common.birthPlace')}</label>
              <input type="text" value={customer.birthPlace || ''} onChange={(e) => updateField('birthPlace', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">{t('common.motherName')}</label>
              <input type="text" value={customer.motherName || ''} onChange={(e) => updateField('motherName', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">{t('common.nationality')}</label>
              <input type="text" value={customer.nationality || ''} onChange={(e) => updateField('nationality', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">{t('common.taxNumber')}</label>
              <input type="text" value={customer.taxNumber || ''} onChange={(e) => updateField('taxNumber', e.target.value)} disabled={!isEditing} className="form-input font-mono" />
            </div>
            <div>
              <label className="form-label">{t('common.note')}</label>
              <input type="text" value={customer.notes || ''} onChange={(e) => updateField('notes', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label flex items-center gap-1">
                <ShieldCheck size={14} />
                Kiemelt közszereplő (PEP)
              </label>
              <select
                value={customer.isPep ? 'true' : 'false'}
                onChange={(e) => updateField('isPep', e.target.value === 'true')}
                disabled={!isEditing}
                className="form-input"
                data-testid="customer-detail-is-pep-select"
              >
                <option value="false">Nem közszereplő</option>
                <option value="true">Kiemelt közszereplő vagy közeli hozzátartozó</option>
              </select>
            </div>
          </div>
        </div>

        {/* Stats Card */}
        <div className="form-panel">
          <h2 className="section-title">{t('customers.statisztika')}</h2>
          <div className="space-y-3">
            <div className="bg-blue-50 p-3 rounded">
              <div className="text-sm text-blue-600">{t('customers.osszesTranzakcio')}</div>
              <div className="text-lg font-bold text-blue-800">{customer.transactionCount ?? 0}</div>
            </div>
            {customer.lastTransactionDate && (
              <div className="bg-gray-50 p-3 rounded">
                <div className="text-sm text-gray-600 flex items-center gap-1">
                  <Clock size={14} />
                  {t('customers.utolsoTranzakcio')}
                </div>
                <div className="text-lg font-semibold">
                  {new Date(customer.lastTransactionDate).toLocaleDateString('hu-HU')}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Document Info */}
        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2">
            <FileText size={16} />
            {t('customers.okmanyAdatok')}
          </h2>
          <div className="space-y-3">
            <div>
              <label className="form-label">{t('customers.okmanyTipusa')}</label>
              <select value={customer.documentType || ''} onChange={(e) => updateField('documentType', e.target.value)} disabled={!isEditing} className="form-input">
                <option value="">—</option>
                <option value="Személyi igazolvány">{t('customers.szemelyiIgazolvany')}</option>
                <option value="Útlevél">{t('customers.utlevel')}</option>
                <option value="Vezetői engedély">{t('customers.vezetoiEngedely')}</option>
                <option value="Tartózkodási engedély">{t('customers.tartozkodasiEngedely')}</option>
              </select>
            </div>
            <div>
              <label className="form-label">{t('common.documentNumber')}</label>
              <input type="text" value={customer.documentNumber || ''} onChange={(e) => updateField('documentNumber', e.target.value)} disabled={!isEditing} className="form-input font-mono" />
            </div>
            <div>
              <label className="form-label">{t('commissions.ervenyesseg')}</label>
              <input type="date" value={customer.documentExpiry || ''} onChange={(e) => updateField('documentExpiry', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
          </div>
        </div>

        {/* Contact Info */}
        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2">
            <Phone size={16} />
            {t('customers.elerhetosegek')}
          </h2>
          <div className="space-y-3">
            <div>
              <label className="form-label">{t('common.phone')}</label>
              <input type="tel" value={customer.phone || ''} onChange={(e) => updateField('phone', e.target.value)} disabled={!isEditing} className="form-input font-mono" />
            </div>
            <div>
              <label className="form-label">{t('customers.eMail')}</label>
              <input type="email" value={customer.email || ''} onChange={(e) => updateField('email', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
          </div>
        </div>

        {/* Address */}
        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2">
            <MapPin size={16} />
            {t('common.homeAddress')}
          </h2>
          <div className="space-y-3">
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="form-label">{t('customers.iranyitoszam')}</label>
                <input type="text" value={customer.postalCode || ''} onChange={(e) => updateField('postalCode', e.target.value)} disabled={!isEditing} className="form-input" />
              </div>
              <div>
                <label className="form-label">{t('common.city')}</label>
                <input type="text" value={customer.city || ''} onChange={(e) => updateField('city', e.target.value)} disabled={!isEditing} className="form-input" />
              </div>
            </div>
            <div>
              <label className="form-label">{t('customers.utcaHazszam')}</label>
              <input type="text" value={customer.address || ''} onChange={(e) => updateField('address', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">{t('common.country')}</label>
              <input type="text" value={customer.country || ''} onChange={(e) => updateField('country', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
          </div>
        </div>
      </div>

      {/* Metadata */}
      <div className="form-panel">
        <div className="flex gap-3 text-sm text-gray-500">
          <span className="flex items-center gap-1">
            <Calendar size={14} />
            {t('customers.letrehozva')}{customer.createdAt ? new Date(customer.createdAt).toLocaleString('hu-HU') : '-'}
          </span>
          <span className="flex items-center gap-1">
            <Clock size={14} />
            {t('customers.modositva')}{customer.updatedAt ? new Date(customer.updatedAt).toLocaleString('hu-HU') : '-'}
          </span>
          <span className="flex items-center gap-1">
            <CreditCard size={14} />
            {t('customers.id')}{id}
          </span>
        </div>
      </div>

      {/* Pmt. 30.§ (1) EDD-jelölő modal — inline (Electron renderer: window.prompt nem támogatott) */}
      {showEddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded bg-white shadow-xl">
            <div className="flex items-center justify-between border-b p-4">
              <h2 className="text-lg font-semibold flex items-center gap-2">
                <ShieldCheck size={18} className="text-red-700" />
                EDD-jelölés — Pmt. 30.§ (1)
              </h2>
            </div>
            <div className="space-y-3 p-4">
              <p className="text-sm text-gray-600">
                Az ügyfél 1 évre megerősített eljárás (V.2.7 c) alá kerül. A jelölés
                audit-naplózott és nem rövidíthető — csak indokkal adható.
              </p>
              <label className="block text-sm">
                <span className="mb-1 block font-medium text-gray-700">Indok (pl. bejelentés azonosító)</span>
                <textarea
                  value={eddReasonInput}
                  onChange={(e) => setEddReasonInput(e.target.value)}
                  rows={3}
                  maxLength={400}
                  className="w-full rounded border px-3 py-2"
                  autoFocus
                />
              </label>
              {eddError && (
                <div className="rounded border border-red-300 bg-red-50 p-2 text-sm text-red-800">{eddError}</div>
              )}
            </div>
            <div className="flex items-center justify-end gap-2 border-t p-4">
              <button onClick={() => setShowEddModal(false)} className="form-button" disabled={eddSaving}>
                {t('common.cancel')}
              </button>
              <button
                onClick={() => void handleMarkEdd()}
                disabled={eddSaving || !eddReasonInput.trim()}
                className="form-button-primary"
              >
                {eddSaving ? 'Mentés...' : 'EDD-jelölés rögzítése'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
