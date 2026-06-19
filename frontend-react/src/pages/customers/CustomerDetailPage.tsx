import { useCallback, useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import {
  User, ArrowLeft, Save, Edit, Clock, FileText,
  Phone, MapPin, CreditCard, Calendar, AlertCircle, Loader2, Users, ShieldCheck, ShieldAlert, Trash2
} from 'lucide-react'
import {
  customerApi,
  customerControlApi,
  Customer,
  CustomerCreateRequest,
  CustomerRestriction,
  CustomerScreeningLog,
} from '../../services/api/transactions'
import { amlApi, CustomerRiskProfile } from '../../services/api/aml'
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
  const canManageRestrictions = hasRole('SUPERVISOR') || hasRole('MANAGER')
  const canMergeCustomers = hasRole('MANAGER') || hasRole('ADMIN')
  const [showEddModal, setShowEddModal] = useState(false)
  const [eddReasonInput, setEddReasonInput] = useState('')
  const [eddSaving, setEddSaving] = useState(false)
  const [eddError, setEddError] = useState<string | null>(null)
  const [restrictions, setRestrictions] = useState<CustomerRestriction[]>([])
  const [screeningLog, setScreeningLog] = useState<CustomerScreeningLog[]>([])
  const [annualTotal, setAnnualTotal] = useState<number | null>(null)
  const [controlLoading, setControlLoading] = useState(false)
  const [controlError, setControlError] = useState<string | null>(null)
  const [amlRiskProfile, setAmlRiskProfile] = useState<CustomerRiskProfile | null>(null)
  const [structuringDetected, setStructuringDetected] = useState<boolean | null>(null)
  const [restrictionType, setRestrictionType] = useState<CustomerRestriction['restrictionType']>('WATCH_LIST')
  const [restrictionReason, setRestrictionReason] = useState('')
  const [restrictionExpiresAt, setRestrictionExpiresAt] = useState('')
  const [restrictionSaving, setRestrictionSaving] = useState(false)
  const [duplicateCustomerId, setDuplicateCustomerId] = useState('')
  const [mergeSaving, setMergeSaving] = useState(false)
  const [mergeError, setMergeError] = useState<string | null>(null)

  const loadControlData = useCallback(async (customerId: number) => {
    try {
      setControlLoading(true)
      setControlError(null)
      const [nextRestrictions, nextAnnualTotal, nextScreeningLog] = await Promise.all([
        customerControlApi.getRestrictions(customerId),
        customerControlApi.getAnnualTotal(customerId),
        customerControlApi.getScreeningLog(customerId),
      ])
      setRestrictions(nextRestrictions)
      setAnnualTotal(nextAnnualTotal)
      setScreeningLog(nextScreeningLog)
      if (canManageRestrictions) {
        const [nextRiskProfile, nextStructuring] = await Promise.all([
          amlApi.customerRisk(String(customerId)),
          amlApi.structuringCheck(String(customerId)),
        ])
        setAmlRiskProfile(nextRiskProfile)
        setStructuringDetected(nextStructuring.structuringDetected)
      } else {
        setAmlRiskProfile(null)
        setStructuringDetected(null)
      }
    } catch (err) {
      setControlError(getErrorMessage(err))
      logger.error('CustomerDetailPage', 'Customer control data load failed:', err)
    } finally {
      setControlLoading(false)
    }
  }, [canManageRestrictions])

  const handleMarkEdd = async () => {
    if (!id || !eddReasonInput.trim()) {
      setEddError(t('customers.eddMarkReasonRequired'))
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
        const numericId = Number(id)
        const data = await customerApi.getById(numericId)
        setCustomer(data)
        void loadControlData(numericId)
      } catch (err) {
        setError(getErrorMessage(err))
        logger.error('CustomerDetailPage', 'Failed to load customer:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [id, loadControlData])

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

  const handleAddRestriction = async () => {
    if (!id || !restrictionReason.trim()) return
    try {
      setRestrictionSaving(true)
      setControlError(null)
      await customerControlApi.addRestriction(Number(id), {
        restrictionType,
        reason: restrictionReason.trim(),
        expiresAt: restrictionExpiresAt ? `${restrictionExpiresAt}T23:59:59` : null,
      })
      setRestrictionReason('')
      setRestrictionExpiresAt('')
      await loadControlData(Number(id))
    } catch (err) {
      setControlError(getErrorMessage(err))
      logger.error('CustomerDetailPage', 'Restriction add failed:', err)
    } finally {
      setRestrictionSaving(false)
    }
  }

  const handleRemoveRestriction = async (restrictionId: string) => {
    if (!id) return
    try {
      setControlError(null)
      await customerControlApi.removeRestriction(restrictionId)
      await loadControlData(Number(id))
    } catch (err) {
      setControlError(getErrorMessage(err))
      logger.error('CustomerDetailPage', 'Restriction remove failed:', err)
    }
  }

  const handleMergeCustomer = async () => {
    if (!id) return
    const primaryId = Number(id)
    const duplicateId = Number(duplicateCustomerId)
    if (!Number.isInteger(primaryId) || !Number.isInteger(duplicateId) || duplicateId <= 0) {
      setMergeError(t('customers.mergeInvalidDuplicateId'))
      return
    }
    if (duplicateId === primaryId) {
      setMergeError(t('customers.mergeSameCustomer'))
      return
    }
    if (!window.confirm(t('customers.mergeConfirm'))) {
      return
    }

    try {
      setMergeSaving(true)
      setMergeError(null)
      const merged = await customerApi.merge(primaryId, duplicateId)
      setCustomer(merged)
      setDuplicateCustomerId('')
      await loadControlData(primaryId)
    } catch (err) {
      setMergeError(getErrorMessage(err))
      logger.error('CustomerDetailPage', 'Customer merge failed:', err)
    } finally {
      setMergeSaving(false)
    }
  }

  const formatHuf = (value: number | null) => (
    value === null ? '-' : `${Number(value).toLocaleString('hu-HU')} Ft`
  )

  const formatOptionalHuf = (value?: number | null) => (
    value === null || value === undefined ? '-' : `${Number(value).toLocaleString('hu-HU')} Ft`
  )

  const formatDateTime = (value?: string | null) => (
    value ? new Date(value).toLocaleString('hu-HU') : '-'
  )

  const restrictionTypeLabel = (value: string) => ({
    BLOCKED: 'Tiltott',
    SUSPICIOUS: 'Gyanús',
    WATCH_LIST: 'Figyelőlista',
    ANNUAL_LIMIT: 'Éves limit',
  }[value] ?? value)

  const riskLevelLabel = (value?: string) => ({
    LOW: 'Alacsony',
    MEDIUM: 'Közepes',
    HIGH: 'Magas',
    CRITICAL: 'Kritikus',
  }[value ?? ''] ?? (value || '-'))

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
    <div className="space-y-3 [&_.form-input]:min-w-0 [&_.form-input]:max-w-full [&_.form-input]:w-full">
      {/* Header */}
      <div className="flex flex-col gap-2 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex min-w-0 items-center gap-3">
          <Link to="/customers" className="toolbar-button">
            <ArrowLeft size={18} />
          </Link>
          <h1 className="flex min-w-0 flex-wrap items-center gap-2 text-xl font-bold text-gray-800">
            <User />
            {t('customers.ugyfelAdatai')}
            {customer.isVip && <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded">VIP</span>}
            {customer.eddActive && (
              <span
                title={customer.eddReason || t('customers.eddBadgeFallback')}
                className="text-xs bg-red-100 text-red-700 px-2 py-0.5 rounded flex items-center gap-1"
              >
                <ShieldCheck size={12} />
                {t('customers.eddBadge', {
                  date: customer.eddUntil ? new Date(customer.eddUntil).toLocaleDateString('hu-HU') : '',
                })}
              </span>
            )}
          </h1>
        </div>
        <div className="flex flex-wrap gap-2">
          {canMarkEdd && !isEditing && (
            <button
              onClick={() => { setEddError(null); setShowEddModal(true) }}
              className="form-button flex items-center gap-1 text-red-700"
              title={t('customers.eddMarkButtonTitle')}
            >
              <ShieldCheck size={16} />
              {t('customers.eddMarkButton')}
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

      <div className="grid grid-cols-1 gap-3 lg:grid-cols-3">
        {/* Basic Info */}
        <div className="form-panel lg:col-span-2">
          <h2 className="section-title">{t('customers.alapadatok')}</h2>
          <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
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

        {/* Customer Control */}
        <div className="form-panel lg:col-span-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="section-title flex items-center gap-2">
              <ShieldAlert size={16} />
              Ügyfél-ellenőrzés
            </h2>
            {controlLoading && (
              <span className="flex items-center gap-1 text-sm text-gray-500">
                <Loader2 size={14} className="animate-spin" />
                Kontrolladatok betöltése...
              </span>
            )}
          </div>
          {controlError && (
            <div className="mb-3 rounded border border-red-200 bg-red-50 p-2 text-sm text-red-700">
              {controlError}
            </div>
          )}
          <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
            <div className="rounded border border-blue-100 bg-blue-50 p-3">
              <div className="text-sm text-blue-700">Éves forgalom</div>
              <div className="text-lg font-bold text-blue-900" data-testid="customer-annual-total">
                {formatHuf(annualTotal)}
              </div>
            </div>
            <div className="rounded border border-amber-100 bg-amber-50 p-3">
              <div className="text-sm text-amber-700">Aktív korlátozások</div>
              <div className="text-lg font-bold text-amber-900">
                {restrictions.filter((item) => item.active).length}
              </div>
            </div>
            <div className="rounded border border-gray-200 bg-gray-50 p-3">
              <div className="text-sm text-gray-600">Szűrési napló</div>
              <div className="text-lg font-bold text-gray-900">{screeningLog.length}</div>
            </div>
          </div>

          {canManageRestrictions && (
            <div className="mt-3 grid grid-cols-1 gap-3 md:grid-cols-4">
              <div className="rounded border border-red-100 bg-red-50 p-3">
                <div className="text-sm text-red-700">AML kockázat</div>
                <div className="text-lg font-bold text-red-900" data-testid="customer-aml-risk">
                  {riskLevelLabel(amlRiskProfile?.riskLevel)}
                </div>
              </div>
              <div className="rounded border border-gray-200 bg-gray-50 p-3">
                <div className="text-sm text-gray-600">Mai AML forgalom</div>
                <div className="text-lg font-bold text-gray-900">
                  {formatOptionalHuf(amlRiskProfile?.dailyTotal)}
                </div>
                <div className="text-xs text-gray-500">{amlRiskProfile?.dailyTransactionCount ?? 0} tranzakció</div>
              </div>
              <div className="rounded border border-gray-200 bg-gray-50 p-3">
                <div className="text-sm text-gray-600">30 napos AML forgalom</div>
                <div className="text-lg font-bold text-gray-900">
                  {formatOptionalHuf(amlRiskProfile?.last30DaysTotal)}
                </div>
                <div className="text-xs text-gray-500">{amlRiskProfile?.last30DaysTransactionCount ?? 0} tranzakció</div>
              </div>
              <div className="rounded border border-amber-100 bg-amber-50 p-3">
                <div className="text-sm text-amber-700">Structuring jelzés</div>
                <div className="text-lg font-bold text-amber-900">
                  {structuringDetected === null ? '-' : structuringDetected ? 'Igen' : 'Nem'}
                </div>
                <div className="text-xs text-amber-800">
                  {amlRiskProfile?.highFrequency ? 'Magas frekvencia' : 'Normál frekvencia'}
                  {' / '}
                  {amlRiskProfile?.highVolume ? 'magas volumen' : 'normál volumen'}
                </div>
              </div>
            </div>
          )}

          {canManageRestrictions && (
            <div className="mt-3 grid grid-cols-1 items-end gap-2 lg:grid-cols-[180px_1fr_170px_auto]">
              <label className="block">
                <span className="form-label">Típus</span>
                <select
                  value={restrictionType}
                  onChange={(event) => setRestrictionType(event.target.value)}
                  className="form-input"
                  data-testid="restriction-type-select"
                >
                  <option value="WATCH_LIST">Figyelőlista</option>
                  <option value="SUSPICIOUS">Gyanús</option>
                  <option value="BLOCKED">Tiltott</option>
                  <option value="ANNUAL_LIMIT">Éves limit</option>
                </select>
              </label>
              <label className="block">
                <span className="form-label">Indoklás</span>
                <input
                  value={restrictionReason}
                  onChange={(event) => setRestrictionReason(event.target.value)}
                  className="form-input"
                  maxLength={500}
                  data-testid="restriction-reason-input"
                />
              </label>
              <label className="block">
                <span className="form-label">Lejárat</span>
                <input
                  type="date"
                  value={restrictionExpiresAt}
                  onChange={(event) => setRestrictionExpiresAt(event.target.value)}
                  className="form-input"
                />
              </label>
              <button
                onClick={() => void handleAddRestriction()}
                disabled={restrictionSaving || !restrictionReason.trim()}
                className="form-button-primary"
              >
                {restrictionSaving ? 'Rögzítés...' : 'Korlátozás rögzítése'}
              </button>
            </div>
          )}

          {canMergeCustomers && (
            <div className="mt-3 rounded border border-amber-200 bg-amber-50 p-3" data-testid="customer-merge-panel">
              <div className="mb-2 flex items-center gap-2 text-sm font-semibold text-amber-900">
                <Users size={16} />
                {t('customers.mergeTitle')}
              </div>
              <div className="grid grid-cols-1 items-end gap-2 md:grid-cols-[1fr_auto]">
                <label className="block">
                  <span className="form-label">{t('customers.mergeDuplicateIdLabel')}</span>
                  <input
                    type="number"
                    inputMode="numeric"
                    min={1}
                    value={duplicateCustomerId}
                    onChange={(event) => {
                      setDuplicateCustomerId(event.target.value)
                      setMergeError(null)
                    }}
                    className="form-input"
                    placeholder={t('customers.mergeDuplicatePlaceholder')}
                    data-testid="duplicate-customer-id-input"
                  />
                </label>
                <button
                  type="button"
                  onClick={() => void handleMergeCustomer()}
                  disabled={mergeSaving || !duplicateCustomerId.trim()}
                  className="form-button-primary min-h-10"
                >
                  {mergeSaving ? t('customers.mergeSubmitting') : t('customers.mergeSubmit')}
                </button>
              </div>
              <p className="mt-2 text-xs text-amber-800">
                {t('customers.mergeHelp')}
              </p>
              {mergeError && (
                <div className="mt-2 rounded border border-red-200 bg-red-50 p-2 text-sm text-red-700">
                  {mergeError}
                </div>
              )}
            </div>
          )}

          <div className="mt-3 grid grid-cols-1 gap-3 xl:grid-cols-2">
            <div className="overflow-hidden rounded border border-gray-200">
              <div className="border-b bg-gray-50 px-3 py-2 text-sm font-semibold">Korlátozások</div>
              <div className="divide-y divide-gray-100">
                {restrictions.length === 0 ? (
                  <div className="px-3 py-3 text-sm text-gray-500">Nincs rögzített korlátozás.</div>
                ) : restrictions.map((restriction) => (
                  <div key={restriction.id} className="flex items-start justify-between gap-3 px-3 py-2 text-sm">
                    <div>
                      <div className="font-semibold text-gray-800">
                        {restrictionTypeLabel(restriction.restrictionType)}
                        {!restriction.active && <span className="ml-2 text-xs text-gray-500">inaktív</span>}
                      </div>
                      <div className="text-gray-600">{restriction.reason}</div>
                      <div className="text-xs text-gray-500">
                        Rögzítve: {formatDateTime(restriction.addedAt)}
                        {restriction.expiresAt ? ` | Lejár: ${formatDateTime(restriction.expiresAt)}` : ''}
                      </div>
                    </div>
                    {canManageRestrictions && restriction.active && (
                      <button
                        onClick={() => void handleRemoveRestriction(restriction.id)}
                        className="toolbar-button text-red-700"
                        title="Korlátozás deaktiválása"
                        aria-label="Korlátozás deaktiválása"
                      >
                        <Trash2 size={16} />
                      </button>
                    )}
                  </div>
                ))}
              </div>
            </div>

            <div className="overflow-hidden rounded border border-gray-200">
              <div className="border-b bg-gray-50 px-3 py-2 text-sm font-semibold">Szűrési napló</div>
              <div className="divide-y divide-gray-100">
                {screeningLog.length === 0 ? (
                  <div className="px-3 py-3 text-sm text-gray-500">Nincs szűrési naplóbejegyzés.</div>
                ) : screeningLog.slice(0, 5).map((entry) => (
                  <div key={entry.id} className="px-3 py-2 text-sm">
                    <div className="font-semibold text-gray-800">
                      {entry.screeningType} / {entry.result}
                    </div>
                    {entry.details && <div className="text-gray-600">{entry.details}</div>}
                    <div className="text-xs text-gray-500">{formatDateTime(entry.screenedAt)}</div>
                  </div>
                ))}
              </div>
            </div>
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
        <div className="flex flex-wrap gap-3 text-sm text-gray-500">
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

      {/* Pmt. 30.§ (1) EDD-jelölő modal — inline (Electron renderer: window.prompt nem támogatott);
          a11y az AmlApproverModal mintájára (role=dialog + aria + Escape) */}
      {showEddModal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby="edd-mark-title"
          onKeyDown={(e) => { if (e.key === 'Escape' && !eddSaving) setShowEddModal(false) }}
        >
          <div className="w-full max-w-md rounded bg-white shadow-xl">
            <div className="flex items-center justify-between border-b p-4">
              <h2 id="edd-mark-title" className="text-lg font-semibold flex items-center gap-2">
                <ShieldCheck size={18} className="text-red-700" />
                {t('customers.eddMarkTitle')}
              </h2>
            </div>
            <div className="space-y-3 p-4">
              <p className="text-sm text-gray-600">{t('customers.eddMarkDescription')}</p>
              <label className="block text-sm">
                <span className="mb-1 block font-medium text-gray-700">{t('customers.eddMarkReasonLabel')}</span>
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
                {eddSaving ? t('customers.eddMarkSaving') : t('customers.eddMarkSubmit')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
