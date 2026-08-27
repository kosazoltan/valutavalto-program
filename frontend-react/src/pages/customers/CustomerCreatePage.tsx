import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Save, User, Building, AlertCircle, ShieldCheck } from 'lucide-react'
import {
  customerApi,
  CustomerCreateRequest,
  teaorApi,
  TeaorCode,
} from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import {
  PRIVACY_NOTICE_VERSION,
  appendPrivacyNoticeAcknowledgement,
} from '../../utils/privacyNotice'
import type { Customer } from '../../services/api/transactions'
import i18n from '../../i18n'

export default function CustomerCreatePage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [customerType, setCustomerType] = useState<'person' | 'company'>('person')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [privacyNoticeAccepted, setPrivacyNoticeAccepted] = useState(false)
  const [teaorSuggestions, setTeaorSuggestions] = useState<TeaorCode[]>([])
  const [teaorOpen, setTeaorOpen] = useState(false)
  const [documentDuplicate, setDocumentDuplicate] = useState<Customer | null>(null)
  const [documentChecking, setDocumentChecking] = useState(false)
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
    teaorCode: '',
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
    isPep: null as boolean | null,
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
        teaorCode: customerType === 'company' ? formData.teaorCode || undefined : undefined,
        isVip: formData.isVip,
        isPep: formData.isPep ?? undefined,
        notes: appendPrivacyNoticeAcknowledgement(),
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
    setFormData((prev) => ({ ...prev, [field]: value }))
    if (field === 'documentNumber' || field === 'documentType') {
      setDocumentDuplicate(null)
    }
  }

  const checkDocumentDuplicate = async () => {
    const documentNumber = formData.documentNumber.trim()
    if (customerType !== 'person' || documentNumber.length < 3) {
      setDocumentDuplicate(null)
      return
    }

    const documentType = formData.documentType.toLowerCase()
    try {
      setDocumentChecking(true)
      const existing =
        documentType.includes('útlev') || documentType.includes('utlev')
          ? await customerApi.getByPassport(documentNumber)
          : documentType.includes('személyi') || documentType.includes('szemelyi')
            ? await customerApi.getByIdCard(documentNumber)
            : await customerApi.getByDocumentNumber(documentNumber)
      setDocumentDuplicate(existing)
    } catch (err) {
      setDocumentDuplicate(null)
      logger.debug(
        'CustomerCreatePage',
        'Okmány duplikáció ellenőrzés: nincs találat vagy nem elérhető',
        err,
      )
    } finally {
      setDocumentChecking(false)
    }
  }

  const handleTeaorChange = (value: string) => {
    updateField('teaorCode', value)
    if (value.trim().length < 2) {
      setTeaorSuggestions([])
      setTeaorOpen(false)
      return
    }
    teaorApi
      .search(value.trim())
      .then((results) => {
        setTeaorSuggestions(results)
        setTeaorOpen(results.length > 0)
      })
      .catch(() => {
        setTeaorSuggestions([])
        setTeaorOpen(false)
      })
  }

  const selectTeaor = (t: TeaorCode) => {
    updateField('teaorCode', t.code)
    setTeaorSuggestions([])
    setTeaorOpen(false)
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
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
          <div className="grid gap-3 sm:grid-cols-2">
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

        <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
          {/* Basic Info */}
          <div className="form-panel">
            <h2 className="section-title">
              {customerType === 'person' ? 'Személyes adatok' : 'Cégadatok'}
            </h2>

            {customerType === 'person' ? (
              <div className="space-y-3">
                <div>
                  <label className="form-label required">{t('common.name')}</label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => updateField('name', e.target.value)}
                    className="form-input"
                    required
                    data-testid="customer-create-name-input"
                  />
                </div>
                <div>
                  <label className="form-label">{t('common.birthName')}</label>
                  <input
                    type="text"
                    value={formData.birthName}
                    onChange={(e) => updateField('birthName', e.target.value)}
                    className="form-input"
                  />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="form-label required">{t('common.birthDate')}</label>
                    <input
                      type="date"
                      value={formData.birthDate}
                      onChange={(e) => updateField('birthDate', e.target.value)}
                      className="form-input"
                      required
                      data-testid="customer-create-birth-date-input"
                    />
                  </div>
                  <div>
                    <label className="form-label">{t('common.birthPlace')}</label>
                    <input
                      type="text"
                      value={formData.birthPlace}
                      onChange={(e) => updateField('birthPlace', e.target.value)}
                      className="form-input"
                    />
                  </div>
                </div>
                <div>
                  <label className="form-label required">{t('common.motherName')}</label>
                  <input
                    type="text"
                    value={formData.motherName}
                    onChange={(e) => updateField('motherName', e.target.value)}
                    className="form-input"
                    required
                    data-testid="customer-create-mother-name-input"
                  />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="form-label">{t('common.nationality')}</label>
                    <input
                      type="text"
                      value={formData.nationality}
                      onChange={(e) => updateField('nationality', e.target.value)}
                      className="form-input"
                    />
                  </div>
                  <div>
                    <label className="form-label">{t('common.taxNumber')}</label>
                    <input
                      type="text"
                      value={formData.taxNumber}
                      onChange={(e) => updateField('taxNumber', e.target.value)}
                      className="form-input font-mono"
                    />
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-3">
                <div>
                  <label className="form-label required">{t('blacklist.cegnev2')}</label>
                  <input
                    type="text"
                    value={formData.companyName}
                    onChange={(e) => updateField('companyName', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                <div>
                  <label className="form-label required">{t('common.companyRegNumber')}</label>
                  <input
                    type="text"
                    value={formData.registrationNumber}
                    onChange={(e) => updateField('registrationNumber', e.target.value)}
                    className="form-input font-mono"
                    required
                  />
                </div>
                <div className="relative">
                  <label className="form-label">{t('customers.teaorCode')}</label>
                  <input
                    type="text"
                    value={formData.teaorCode}
                    onChange={(e) => handleTeaorChange(e.target.value)}
                    onFocus={() => setTeaorOpen(teaorSuggestions.length > 0)}
                    onBlur={() => setTimeout(() => setTeaorOpen(false), 150)}
                    className="form-input font-mono"
                    placeholder="pl. 6612 vagy tevékenység neve"
                    autoComplete="off"
                  />
                  {teaorOpen && (
                    <ul className="absolute z-20 left-0 right-0 mt-1 max-h-56 overflow-auto bg-white border border-gray-300 rounded shadow-lg">
                      {teaorSuggestions.map((s) => (
                        <li key={s.code}>
                          <button
                            type="button"
                            onMouseDown={(e) => {
                              e.preventDefault()
                              selectTeaor(s)
                            }}
                            className="w-full text-left px-3 py-1.5 text-sm hover:bg-blue-50 flex gap-2"
                          >
                            <span className="font-mono text-blue-700">{s.code}</span>
                            <span className="text-gray-700">{s.name}</span>
                          </button>
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
                <div>
                  <label className="form-label required">{t('common.taxNumber')}</label>
                  <input
                    type="text"
                    value={formData.vatNumber}
                    onChange={(e) => updateField('vatNumber', e.target.value)}
                    className="form-input font-mono"
                    required
                  />
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
                <select
                  value={formData.documentType}
                  onChange={(e) => updateField('documentType', e.target.value)}
                  className="form-input"
                  required
                >
                  <option>{t('customers.szemelyiIgazolvany')}</option>
                  <option>{t('customers.utlevel')}</option>
                  <option>{t('customers.vezetoiEngedely')}</option>
                  <option>{t('customers.tartozkodasiEngedely')}</option>
                </select>
              </div>
              <div>
                <label className="form-label required">{t('common.documentNumber')}</label>
                <input
                  type="text"
                  value={formData.documentNumber}
                  onChange={(e) => updateField('documentNumber', e.target.value)}
                  onBlur={() => void checkDocumentDuplicate()}
                  className="form-input font-mono"
                  required
                  data-testid="customer-create-document-number-input"
                />
                {documentChecking && (
                  <p className="mt-1 text-xs text-gray-500">
                    {i18n.t('literals.okmany-ellenorzese')}
                  </p>
                )}
              </div>
              {documentDuplicate && (
                <div
                  className="rounded border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900"
                  role="alert"
                >
                  <div className="font-semibold">
                    {i18n.t('literals.mar-letezik-ugyfel-ezzel-az-okmannyal')}
                  </div>
                  <div className="mt-1">
                    {documentDuplicate.name}{' '}
                    {documentDuplicate.customerCode ? `(${documentDuplicate.customerCode})` : ''}
                  </div>
                  <Link
                    to={`/customers/${documentDuplicate.id}`}
                    className="mt-2 inline-block font-medium text-amber-800 underline"
                  >
                    {i18n.t('literals.meglevo-ugyfel-megnyitasa')}
                  </Link>
                </div>
              )}
              <div>
                <label className="form-label">{t('customers.okmanyErvenyessege')}</label>
                <input
                  type="date"
                  value={formData.documentExpiry}
                  onChange={(e) => updateField('documentExpiry', e.target.value)}
                  className="form-input"
                />
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
                  <input
                    type="text"
                    value={formData.postalCode}
                    onChange={(e) => updateField('postalCode', e.target.value)}
                    className="form-input"
                    required
                    data-testid="customer-create-postal-code-input"
                  />
                </div>
                <div className="col-span-2">
                  <label className="form-label required">{t('common.city')}</label>
                  <input
                    type="text"
                    value={formData.city}
                    onChange={(e) => updateField('city', e.target.value)}
                    className="form-input"
                    required
                    data-testid="customer-create-city-input"
                  />
                </div>
              </div>
              <div>
                <label className="form-label required">{t('customers.utcaHazszam')}</label>
                <input
                  type="text"
                  value={formData.address}
                  onChange={(e) => updateField('address', e.target.value)}
                  className="form-input"
                  required
                  data-testid="customer-create-address-input"
                />
              </div>
              <div>
                <label className="form-label">{t('common.country')}</label>
                <input
                  type="text"
                  value={formData.country}
                  onChange={(e) => updateField('country', e.target.value)}
                  className="form-input"
                />
              </div>
            </div>
          </div>

          {/* Contact */}
          <div className="form-panel">
            <h2 className="section-title">{t('customers.elerhetosegek')}</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label">{t('customers.telefonszam')}</label>
                <input
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => updateField('phone', e.target.value)}
                  className="form-input font-mono"
                  placeholder="+36..."
                />
              </div>
              <div>
                <label className="form-label">{t('customers.eMailCim')}</label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => updateField('email', e.target.value)}
                  className="form-input"
                />
              </div>
            </div>
          </div>

          {/* Compliance */}
          <div className="form-panel lg:col-span-2">
            <h2 className="section-title flex items-center gap-2">
              <ShieldCheck size={16} />
              {i18n.t('literals.compliance')}
            </h2>
            <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
              <div>
                <label className="form-label required">
                  {i18n.t('literals.kiemelt-kozszereplo-pep')}
                </label>
                <select
                  value={formData.isPep === null ? '' : String(formData.isPep)}
                  onChange={(e) => updateField('isPep', e.target.value === 'true')}
                  className="form-input"
                  required
                  data-testid="customer-is-pep-select"
                >
                  <option value="">{i18n.t('literals.valassz-2')}</option>
                  <option value="false">{i18n.t('literals.nem-kozszereplo')}</option>
                  <option value="true">
                    {i18n.t('literals.kiemelt-kozszereplo-vagy-kozeli-hozzatar')}
                  </option>
                </select>
              </div>
              <label className="flex items-start gap-2 rounded border border-slate-300 bg-slate-50 p-3 text-sm text-slate-700">
                <input
                  type="checkbox"
                  className="mt-1"
                  checked={privacyNoticeAccepted}
                  onChange={(e) => setPrivacyNoticeAccepted(e.target.checked)}
                  required
                  data-testid="customer-privacy-notice-checkbox"
                />
                <span>
                  {i18n.t('literals.az-ugyfel-megkapta-az-adatkezelesi-tajek')}
                  {PRIVACY_NOTICE_VERSION}
                  {i18n.t('literals.lit-5')}
                </span>
              </label>
            </div>
          </div>
        </div>

        {/* Submit */}
        <div className="form-panel flex justify-end gap-2">
          <Link to="/customers" className="form-button">
            {t('common.cancel')}
          </Link>
          <button
            type="submit"
            disabled={
              saving ||
              !privacyNoticeAccepted ||
              formData.isPep === null ||
              documentDuplicate != null
            }
            className="form-button-primary flex items-center gap-1"
            data-testid="customer-create-save-button"
          >
            <Save size={16} />
            {saving ? 'Mentés...' : 'Mentés'}
          </button>
        </div>
      </form>
    </div>
  )
}
