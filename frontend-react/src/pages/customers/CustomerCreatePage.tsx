import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Save, User, Building, AlertCircle } from 'lucide-react'
import { customerApi, CustomerCreateRequest } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'

export default function CustomerCreatePage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [customerType, setCustomerType] = useState<'person' | 'company'>('person')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    name: '',
    birthName: '',
    birthDate: '',
    birthPlace: '',
    motherName: '',
    nationality: 'Magyar',
    taxNumber: '',
    companyName: '',
    registrationNumber: '',
    vatNumber: '',
    documentType: 'Személyi igazolvány',
    documentNumber: '',
    documentExpiry: '',
    postalCode: '',
    city: '',
    address: '',
    country: 'Magyarország',
    phone: '',
    email: '',
    isVip: false,
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      setSaving(true)
      setError(null)
      const req: CustomerCreateRequest = {
        name: customerType === 'company' ? formData.companyName : formData.name,
        birthName: formData.birthName || undefined,
        motherName: formData.motherName || undefined,
        birthDate: formData.birthDate || undefined,
        birthPlace: formData.birthPlace || undefined,
        nationality: formData.nationality || undefined,
        documentNumber: formData.documentNumber || undefined,
        documentType: formData.documentType || undefined,
        documentExpiry: formData.documentExpiry || undefined,
        address: formData.address || undefined,
        postalCode: formData.postalCode || undefined,
        city: formData.city || undefined,
        country: formData.country || undefined,
        phone: formData.phone || undefined,
        email: formData.email || undefined,
        isCompany: customerType === 'company',
        companyName: customerType === 'company' ? formData.companyName : undefined,
        taxNumber: formData.taxNumber || formData.vatNumber || undefined,
        registrationNumber: formData.registrationNumber || undefined,
        isVip: formData.isVip,
      }
      const created = await customerApi.create(req)
      navigate(`/customers/${created.id}`)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('CustomerCreatePage', 'Failed to create customer:', err)
    } finally {
      setSaving(false)
    }
  }

  const updateField = (field: string, value: string | boolean) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-3">
          <Link to="/customers" className="toolbar-button">
            <ArrowLeft size={18} />
          </Link>
          <h1 className="text-xl font-bold text-gray-800">{t('customers.ujUgyfelRogzitese')}</h1>
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

      <form onSubmit={(e) => void handleSubmit(e)} className="space-y-3">
        {/* Customer Type Selection */}
        <div className="form-panel">
          <h2 className="section-title">{t('customers.ugyfelTipusa')}</h2>
          <div className="flex gap-3">
            <button
              type="button"
              onClick={() => setCustomerType('person')}
              className={`flex items-center gap-2 px-4 py-2 rounded border-2 transition-colors ${
                customerType === 'person'
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              <User size={18} />
              {t('customers.maganszemely')}
            </button>
            <button
              type="button"
              onClick={() => setCustomerType('company')}
              className={`flex items-center gap-2 px-4 py-2 rounded border-2 transition-colors ${
                customerType === 'company'
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              <Building size={18} />
              {t('customers.cegesUgyfel')}
            </button>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {/* Basic Info */}
          <div className="form-panel">
            <h2 className="section-title">
              {customerType === 'person' ? 'Személyes adatok' : 'Cégadatok'}
            </h2>

            {customerType === 'person' ? (
              <div className="space-y-3">
                <div>
                  <label className="form-label required">{t('common.name')}</label>
                  <input type="text" value={formData.name} onChange={(e) => updateField('name', e.target.value)} className="form-input" required />
                </div>
                <div>
                  <label className="form-label">{t('common.birthName')}</label>
                  <input type="text" value={formData.birthName} onChange={(e) => updateField('birthName', e.target.value)} className="form-input" />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="form-label required">{t('common.birthDate')}</label>
                    <input type="date" value={formData.birthDate} onChange={(e) => updateField('birthDate', e.target.value)} className="form-input" required />
                  </div>
                  <div>
                    <label className="form-label">{t('common.birthPlace')}</label>
                    <input type="text" value={formData.birthPlace} onChange={(e) => updateField('birthPlace', e.target.value)} className="form-input" />
                  </div>
                </div>
                <div>
                  <label className="form-label required">{t('common.motherName')}</label>
                  <input type="text" value={formData.motherName} onChange={(e) => updateField('motherName', e.target.value)} className="form-input" required />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="form-label">{t('common.nationality')}</label>
                    <input type="text" value={formData.nationality} onChange={(e) => updateField('nationality', e.target.value)} className="form-input" />
                  </div>
                  <div>
                    <label className="form-label">{t('common.taxNumber')}</label>
                    <input type="text" value={formData.taxNumber} onChange={(e) => updateField('taxNumber', e.target.value)} className="form-input font-mono" />
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-3">
                <div>
                  <label className="form-label required">{t('blacklist.cegnev2')}</label>
                  <input type="text" value={formData.companyName} onChange={(e) => updateField('companyName', e.target.value)} className="form-input" required />
                </div>
                <div>
                  <label className="form-label required">{t('common.companyRegNumber')}</label>
                  <input type="text" value={formData.registrationNumber} onChange={(e) => updateField('registrationNumber', e.target.value)} className="form-input font-mono" required />
                </div>
                <div>
                  <label className="form-label required">{t('common.taxNumber')}</label>
                  <input type="text" value={formData.vatNumber} onChange={(e) => updateField('vatNumber', e.target.value)} className="form-input font-mono" required />
                </div>
              </div>
            )}
          </div>

          {/* Document Info */}
          <div className="form-panel">
            <h2 className="section-title">{t('customers.okmanyAdatok')}</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label required">{t('customers.okmanyTipusa')}</label>
                <select value={formData.documentType} onChange={(e) => updateField('documentType', e.target.value)} className="form-input" required>
                  <option>{t('customers.szemelyiIgazolvany')}</option>
                  <option>{t('customers.utlevel')}</option>
                  <option>{t('customers.vezetoiEngedely')}</option>
                  <option>{t('customers.tartozkodasiEngedely')}</option>
                </select>
              </div>
              <div>
                <label className="form-label required">{t('common.documentNumber')}</label>
                <input type="text" value={formData.documentNumber} onChange={(e) => updateField('documentNumber', e.target.value)} className="form-input font-mono" required />
              </div>
              <div>
                <label className="form-label">{t('customers.okmanyErvenyessege')}</label>
                <input type="date" value={formData.documentExpiry} onChange={(e) => updateField('documentExpiry', e.target.value)} className="form-input" />
              </div>
            </div>
          </div>

          {/* Address */}
          <div className="form-panel">
            <h2 className="section-title">{t('customers.lakcimSzekhely')}</h2>
            <div className="space-y-3">
              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="form-label required">{t('customers.iranyitoszam')}</label>
                  <input type="text" value={formData.postalCode} onChange={(e) => updateField('postalCode', e.target.value)} className="form-input" required />
                </div>
                <div className="col-span-2">
                  <label className="form-label required">{t('common.city')}</label>
                  <input type="text" value={formData.city} onChange={(e) => updateField('city', e.target.value)} className="form-input" required />
                </div>
              </div>
              <div>
                <label className="form-label required">{t('customers.utcaHazszam')}</label>
                <input type="text" value={formData.address} onChange={(e) => updateField('address', e.target.value)} className="form-input" required />
              </div>
              <div>
                <label className="form-label">{t('common.country')}</label>
                <input type="text" value={formData.country} onChange={(e) => updateField('country', e.target.value)} className="form-input" />
              </div>
            </div>
          </div>

          {/* Contact */}
          <div className="form-panel">
            <h2 className="section-title">{t('customers.elerhetosegek')}</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label">{t('customers.telefonszam')}</label>
                <input type="tel" value={formData.phone} onChange={(e) => updateField('phone', e.target.value)} className="form-input font-mono" placeholder="+36..." />
              </div>
              <div>
                <label className="form-label">{t('customers.eMailCim')}</label>
                <input type="email" value={formData.email} onChange={(e) => updateField('email', e.target.value)} className="form-input" />
              </div>
            </div>
          </div>
        </div>

        {/* Submit */}
        <div className="form-panel flex justify-end gap-2">
          <Link to="/customers" className="form-button">{t('common.cancel')}</Link>
          <button type="submit" disabled={saving} className="form-button-primary flex items-center gap-1">
            <Save size={16} />
            {saving ? 'Mentés...' : 'Mentés'}
          </button>
        </div>
      </form>
    </div>
  )
}
