import { useState, useEffect, useCallback } from 'react'
import {
  Plus,
  Receipt,
  RefreshCw,
  Eye,
  XCircle,
  CheckCircle,
  User,
  Building2,
  Briefcase,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { ertektarApi } from '../../services/api/index'
import type { VatRefundItem, VatRefundRequest, VatRefundType } from '../../services/api/index'
import { formatDateTime } from './treasuryUtils'
import { TableSkeleton } from './LoadingSkeleton'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

const VOUCHER_TYPE_LABELS: Record<VatRefundType, string> = {
  AK: 'Külföldi ügyfél ÁFA',
  AB: 'Céges ÁFA kifizetés',
  AV: 'Innova Invest ellátmány',
}

const VOUCHER_TYPE_ICONS: Record<VatRefundType, typeof User> = {
  AK: User,
  AB: Building2,
  AV: Briefcase,
}

const VOUCHER_TYPES: { value: VatRefundType; label: string; description: string }[] = [
  { value: 'AK', label: 'Külföldi ügyfél ÁFA', description: 'EU ügyfél ÁFA visszatérítés HUF-ban' },
  { value: 'AB', label: 'Céges ÁFA kifizetés', description: 'Cég részére ÁFA kifizetés' },
  {
    value: 'AV',
    label: 'Innova Invest ellátmány',
    description: 'Pénzmozgás Innova Invest felé/vissza',
  },
]

const VAT_PERCENT_OPTIONS = [0, 5, 18, 27]

function todayIsoDate(): string {
  return new Date().toISOString().slice(0, 10)
}

function formatCurrency(amount: number | undefined | null): string {
  if (amount == null) return '0'
  return amount.toLocaleString('hu-HU', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
}

export default function VatRefundPage() {
  const { t } = useTranslation()
  const [loading, setLoading] = useState(true)
  const [records, setRecords] = useState<VatRefundItem[]>([])
  const [showNewModal, setShowNewModal] = useState(false)
  const [showDetailModal, setShowDetailModal] = useState<VatRefundItem | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [stornoTarget, setStornoTarget] = useState<VatRefundItem | null>(null)
  const [stornoSubmitting, setStornoSubmitting] = useState(false)

  // Filters
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [typeFilter, setTypeFilter] = useState<VatRefundType | 'all'>('all')
  const [customerFilter, setCustomerFilter] = useState('')

  // Form state — backend contract
  const [voucherType, setVoucherType] = useState<VatRefundType>('AK')
  const [grossAmount, setGrossAmount] = useState('')
  const [vatPercentage, setVatPercentage] = useState<number>(27)
  const [customerName, setCustomerName] = useState('')
  const [customerAddress, setCustomerAddress] = useState('')
  const [customerIdentifier, setCustomerIdentifier] = useState('')
  const [bankAccountNumber, setBankAccountNumber] = useState('')
  const [companyName, setCompanyName] = useState('')
  const [siteAddress, setSiteAddress] = useState('')
  const [deedNumber, setDeedNumber] = useState('')

  const fetchData = useCallback(async () => {
    try {
      const data = await ertektarApi
        .getVatRefunds(dateFrom || undefined, dateTo || undefined)
        .catch(() => [])
      setRecords(safeArray<VatRefundItem>(data))
    } catch (err) {
      logger.error('VatRefundPage', 'Fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [dateFrom, dateTo])

  useEffect(() => {
    void fetchData()
  }, [fetchData])

  useHotkeys('n', () => setShowNewModal(true), { enableOnFormTags: false })
  useHotkeys(
    'escape',
    () => {
      setShowNewModal(false)
      setShowDetailModal(null)
      setDetailLoading(false)
      setStornoTarget(null)
    },
    { enableOnFormTags: true },
  )

  const resetForm = () => {
    setVoucherType('AK')
    setGrossAmount('')
    setVatPercentage(27)
    setCustomerName('')
    setCustomerAddress('')
    setCustomerIdentifier('')
    setBankAccountNumber('')
    setCompanyName('')
    setSiteAddress('')
    setDeedNumber('')
  }

  const computedVatAmount = grossAmount
    ? Math.round((parseFloat(grossAmount) * vatPercentage) / (100 + vatPercentage))
    : 0
  const computedNetAmount = grossAmount
    ? Math.round(parseFloat(grossAmount) - computedVatAmount)
    : 0

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault()
      if (!grossAmount) return
      setSubmitting(true)
      try {
        const gross = parseFloat(grossAmount)
        const vatAmt = Math.round((gross * vatPercentage) / (100 + vatPercentage))
        const request: VatRefundRequest = {
          voucherType,
          grossAmount: gross,
          vatAmount: vatAmt,
          vatPercentage: vatPercentage || undefined,
          customerName: customerName || undefined,
          customerAddress: customerAddress || undefined,
          customerIdentifier: customerIdentifier || undefined,
          bankAccountNumber: bankAccountNumber || undefined,
          companyName: companyName || undefined,
          siteAddress: siteAddress || undefined,
          deedNumber: deedNumber || undefined,
        }
        await ertektarApi.createVatRefund(request)
        setShowNewModal(false)
        resetForm()
        void fetchData()
      } catch (err) {
        logger.error('VatRefundPage', 'Create error:', err)
      } finally {
        setSubmitting(false)
      }
    },
    [
      voucherType,
      grossAmount,
      vatPercentage,
      customerName,
      customerAddress,
      customerIdentifier,
      bankAccountNumber,
      companyName,
      siteAddress,
      deedNumber,
      fetchData,
    ],
  )

  const handleStorno = useCallback(async () => {
    if (!stornoTarget) return
    setStornoSubmitting(true)
    try {
      await ertektarApi.stornoVatRefund(stornoTarget.id)
      setStornoTarget(null)
      void fetchData()
    } catch (err) {
      logger.error('VatRefundPage', 'Storno error:', err)
    } finally {
      setStornoSubmitting(false)
    }
  }, [stornoTarget, fetchData])

  const fetchDailyData = useCallback(async () => {
    try {
      setLoading(true)
      const today = todayIsoDate()
      const data = await ertektarApi.getDailyVatRefunds(today).catch(() => [])
      setRecords(safeArray<VatRefundItem>(data))
    } catch (err) {
      logger.error('VatRefundPage', 'Daily fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  const openDetail = useCallback(async (record: VatRefundItem) => {
    setShowDetailModal(record)
    setDetailLoading(true)
    try {
      const detail = await ertektarApi.getVatRefund(record.id)
      setShowDetailModal(detail)
    } catch (err) {
      logger.error('VatRefundPage', 'Detail fetch error:', err)
    } finally {
      setDetailLoading(false)
    }
  }, [])

  const filtered = records.filter((r) => {
    if (typeFilter !== 'all' && r.voucherType !== typeFilter) return false
    if (
      customerFilter &&
      !(r.customerName ?? '').toLowerCase().includes(customerFilter.toLowerCase())
    )
      return false
    return true
  })

  const activeCount = records.filter((r) => !r.isReversed).length
  const reversedCount = records.filter((r) => r.isReversed).length

  if (loading) return <TableSkeleton rows={6} cols={7} />

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold text-secondary-900 flex items-center gap-2">
            <Receipt size={22} className="text-primary-600" />
            {t('treasury.afaVisszaterites')}
          </h1>
          <span className="badge badge-blue">
            {t('treasury.aktiv')}
            {activeCount}
          </span>
          {reversedCount > 0 && (
            <span className="badge badge-orange">
              {t('treasury.sztorno')}
              {reversedCount}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => void fetchDailyData()} className="form-button h-8 text-xs">
            {t('common.today', 'Mai nap')}
          </button>
          <button onClick={() => void fetchData()} className="form-button h-8 text-xs">
            <RefreshCw size={14} />
          </button>
          <button onClick={() => setShowNewModal(true)} className="form-button-primary h-8 text-xs">
            <Plus size={16} />
            <span>{t('treasury.ujBizonylat')}</span>
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="form-panel">
        <div className="flex flex-wrap gap-3 items-end">
          <div>
            <label className="form-label text-xs">{t('common.type')}</label>
            <select
              className="form-input w-44 h-8 text-xs"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value as VatRefundType | 'all')}
            >
              <option value="all">{t('treasury.mindenTipus2')}</option>
              {VOUCHER_TYPES.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="form-label text-xs">{t('treasury.ugyfelCeg')}</label>
            <input
              type="text"
              className="form-input w-44 h-8 text-xs"
              placeholder="Név keresés..."
              value={customerFilter}
              onChange={(e) => setCustomerFilter(e.target.value)}
            />
          </div>
          <div>
            <label className="form-label text-xs">{t('components.datumtol')}</label>
            <input
              type="date"
              className="form-input h-8 text-xs"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
            />
          </div>
          <div>
            <label className="form-label text-xs">{t('components.datumig')}</label>
            <input
              type="date"
              className="form-input h-8 text-xs"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
            />
          </div>
          {(typeFilter !== 'all' || customerFilter || dateFrom || dateTo) && (
            <button
              className="form-button h-8 text-xs"
              onClick={() => {
                setTypeFilter('all')
                setCustomerFilter('')
                setDateFrom('')
                setDateTo('')
              }}
            >
              {t('treasury.szuroTorlese')}
            </button>
          )}
        </div>
      </div>

      {/* Table */}
      <div className="form-panel">
        <div className="space-y-2 md:hidden">
          {filtered.length === 0 && (
            <p className="rounded border border-secondary-200 bg-secondary-50 p-3 text-center text-sm text-secondary-500">
              {t('common.noResult')}
            </p>
          )}
          {filtered.map((r) => {
            const TypeIcon = VOUCHER_TYPE_ICONS[r.voucherType]
            return (
              <div
                key={r.id}
                className={`rounded border border-secondary-200 bg-white p-3 ${r.isReversed ? 'opacity-60' : ''}`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <div className="break-words font-mono text-xs font-semibold text-secondary-900">
                      {r.serialNumber}
                    </div>
                    <div className="mt-1 flex items-center gap-1 text-xs text-secondary-600">
                      <TypeIcon size={13} className="text-primary-500 shrink-0" />
                      <span>{VOUCHER_TYPE_LABELS[r.voucherType]}</span>
                    </div>
                  </div>
                  <span className={`badge ${r.isReversed ? 'badge-orange' : 'badge-green'}`}>
                    {r.isReversed ? 'Sztornó' : 'Aktív'}
                  </span>
                </div>
                <div className="mt-2 text-sm font-semibold text-secondary-800">
                  {r.customerName || r.companyName || '-'}
                </div>
                <div className="mt-2 grid grid-cols-2 gap-2 text-xs">
                  <div>
                    <span className="text-secondary-500">{t('treasury.bruttoFt')}</span>
                    <div className="font-mono font-semibold">
                      {formatCurrency(r.grossAmount)} {t('components.ft')}
                    </div>
                  </div>
                  <div>
                    <span className="text-secondary-500">{t('treasury.afaFt')}</span>
                    <div className="font-mono">
                      {formatCurrency(r.vatAmount)} {t('components.ft')}
                    </div>
                  </div>
                </div>
                <div className="mt-3 flex items-center justify-between gap-2">
                  <span className="text-xs text-secondary-500">{r.transactionDate}</span>
                  <div className="flex items-center gap-3">
                    <button
                      className="text-primary-600 hover:text-primary-700"
                      title="Részletek"
                      aria-label={`Részletek ${r.serialNumber}`}
                      onClick={() => void openDetail(r)}
                    >
                      <Eye size={16} />
                    </button>
                    {!r.isReversed && (
                      <button
                        className="text-red-500 hover:text-red-700"
                        title="Sztornó"
                        onClick={() => setStornoTarget(r)}
                      >
                        <XCircle size={16} />
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )
          })}
        </div>

        <div className="hidden overflow-x-auto md:block">
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th className="w-24">{t('treasury.sorszam')}</th>
                <th className="w-36">{t('common.type')}</th>
                <th className="w-44">{t('treasury.ugyfelCeg')}</th>
                <th className="text-right w-28">{t('treasury.bruttoFt')}</th>
                <th className="text-right w-28">{t('treasury.afaFt')}</th>
                <th className="text-right w-16">{t('treasury.afa')}</th>
                <th className="w-24">{t('common.status')}</th>
                <th className="w-28">{t('common.date')}</th>
                <th className="w-12"></th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={9} className="text-center text-sm text-secondary-400 py-8">
                    {t('common.noResult')}
                  </td>
                </tr>
              )}
              {filtered.map((r) => {
                const TypeIcon = VOUCHER_TYPE_ICONS[r.voucherType]
                return (
                  <tr key={r.id} className={r.isReversed ? 'opacity-50 line-through' : ''}>
                    <td className="font-mono text-xs">{r.serialNumber}</td>
                    <td>
                      <span className="flex items-center gap-1 text-xs">
                        <TypeIcon size={13} className="text-primary-500 shrink-0" />
                        {VOUCHER_TYPE_LABELS[r.voucherType]}
                      </span>
                    </td>
                    <td className="text-xs text-secondary-700">
                      {r.customerName || r.companyName || '-'}
                    </td>
                    <td className="text-right font-mono font-semibold">
                      {formatCurrency(r.grossAmount)} {t('components.ft')}
                    </td>
                    <td className="text-right font-mono text-xs">
                      {formatCurrency(r.vatAmount)} {t('components.ft')}
                    </td>
                    <td className="text-right font-mono text-xs">
                      {r.vatPercentage != null ? `${r.vatPercentage}%` : '-'}
                    </td>
                    <td>
                      <span className={`badge ${r.isReversed ? 'badge-orange' : 'badge-green'}`}>
                        {r.isReversed ? 'Sztornó' : 'Aktív'}
                      </span>
                    </td>
                    <td className="text-xs">{r.transactionDate}</td>
                    <td className="flex items-center gap-1">
                      <button
                        className="text-primary-600 hover:text-primary-700"
                        title="Részletek"
                        aria-label={`Részletek ${r.serialNumber}`}
                        onClick={() => void openDetail(r)}
                      >
                        <Eye size={15} />
                      </button>
                      {!r.isReversed && (
                        <button
                          className="text-red-500 hover:text-red-700"
                          title="Sztornó"
                          onClick={() => setStornoTarget(r)}
                        >
                          <XCircle size={15} />
                        </button>
                      )}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* New Record Modal */}
      {showNewModal && (
        <div
          className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
          onClick={() => setShowNewModal(false)}
        >
          <div
            className="bg-white rounded-lg shadow-xl p-4 max-w-lg w-full mx-4 max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-xl font-bold text-secondary-900 mb-3 flex items-center gap-2">
              <Receipt size={24} className="text-primary-600" />
              {t('treasury.ujAfaBizonylat')}
            </h2>
            <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4">
              {/* Type selector */}
              <div>
                <label className="form-label">{t('treasury.bizonylatTipusa')}</label>
                <div className="grid grid-cols-1 gap-2">
                  {VOUCHER_TYPES.map((t) => {
                    const Icon = VOUCHER_TYPE_ICONS[t.value]
                    return (
                      <button
                        key={t.value}
                        type="button"
                        onClick={() => setVoucherType(t.value)}
                        className={`p-3 rounded-lg border-2 transition-all flex items-center gap-3 text-left ${
                          voucherType === t.value
                            ? 'border-primary-500 bg-primary-50'
                            : 'border-secondary-200 hover:border-secondary-400'
                        }`}
                      >
                        <Icon
                          size={20}
                          className={
                            voucherType === t.value ? 'text-primary-600' : 'text-secondary-400'
                          }
                        />
                        <div>
                          <div className="font-semibold text-sm">{t.label}</div>
                          <div className="text-xs text-secondary-500">{t.description}</div>
                        </div>
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* Amounts */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('treasury.bruttoOsszegFt')}</label>
                  <input
                    type="number"
                    className="form-input w-full font-mono"
                    placeholder="0"
                    value={grossAmount}
                    onChange={(e) => setGrossAmount(e.target.value)}
                    required
                    min="1"
                    step="1"
                  />
                </div>
                <div>
                  <label className="form-label">{t('treasury.afa')}</label>
                  <select
                    className="form-input w-full"
                    value={vatPercentage}
                    onChange={(e) => setVatPercentage(parseInt(e.target.value))}
                  >
                    {VAT_PERCENT_OPTIONS.map((p) => (
                      <option key={p} value={p}>
                        {p}
                        {i18n.t('literals.lit-30')}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Calculated preview */}
              {grossAmount && parseFloat(grossAmount) > 0 && (
                <div className="p-3 rounded-lg bg-secondary-50 border border-secondary-200 grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span className="text-secondary-500 text-xs">{t('treasury.afaOsszeg')}</span>
                    <div className="font-bold font-mono">
                      {formatCurrency(computedVatAmount)} {t('components.ft')}
                    </div>
                  </div>
                  <div>
                    <span className="text-secondary-500 text-xs">{t('treasury.nettoOsszeg')}</span>
                    <div className="font-bold font-mono">
                      {formatCurrency(computedNetAmount)} {t('components.ft')}
                    </div>
                  </div>
                </div>
              )}

              {/* AK: Customer data */}
              {voucherType === 'AK' && (
                <>
                  <div>
                    <label className="form-label">{t('pep.ugyfelNeve2')}</label>
                    <input
                      type="text"
                      className="form-input w-full"
                      value={customerName}
                      onChange={(e) => setCustomerName(e.target.value)}
                      required
                    />
                  </div>
                  <div>
                    <label className="form-label">{t('treasury.ugyfelLakcime')}</label>
                    <input
                      type="text"
                      className="form-input w-full"
                      value={customerAddress}
                      onChange={(e) => setCustomerAddress(e.target.value)}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="form-label">{t('treasury.azonositoUtlevelSzig')}</label>
                      <input
                        type="text"
                        className="form-input w-full"
                        value={customerIdentifier}
                        onChange={(e) => setCustomerIdentifier(e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">{t('treasury.bankszamlaszam')}</label>
                      <input
                        type="text"
                        className="form-input w-full"
                        value={bankAccountNumber}
                        onChange={(e) => setBankAccountNumber(e.target.value)}
                      />
                    </div>
                  </div>
                </>
              )}

              {/* AB: Company data */}
              {voucherType === 'AB' && (
                <>
                  <div>
                    <label className="form-label">{t('treasury.cegNeve')}</label>
                    <input
                      type="text"
                      className="form-input w-full"
                      value={companyName}
                      onChange={(e) => setCompanyName(e.target.value)}
                      required
                    />
                  </div>
                  <div>
                    <label className="form-label">{t('treasury.telephelyCim')}</label>
                    <input
                      type="text"
                      className="form-input w-full"
                      value={siteAddress}
                      onChange={(e) => setSiteAddress(e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="form-label">{t('treasury.okiratszam')}</label>
                    <input
                      type="text"
                      className="form-input w-full"
                      value={deedNumber}
                      onChange={(e) => setDeedNumber(e.target.value)}
                    />
                  </div>
                </>
              )}

              {/* Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t">
                <button
                  type="button"
                  className="form-button"
                  onClick={() => {
                    setShowNewModal(false)
                    resetForm()
                  }}
                >
                  {t('common.cancel')}
                </button>
                <button type="submit" className="form-button-primary" disabled={submitting}>
                  <CheckCircle size={18} />
                  <span>{submitting ? 'Mentés...' : 'Rögzítés'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {showDetailModal && (
        <div
          className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
          onClick={() => setShowDetailModal(null)}
        >
          <div
            className="bg-white rounded-lg shadow-xl p-4 max-w-md w-full mx-4"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-xl font-bold text-secondary-900 mb-4 flex items-center gap-2">
              <Receipt size={20} className="text-primary-600" />
              {showDetailModal.serialNumber}
            </h2>
            {detailLoading && (
              <div className="mb-3 rounded border border-secondary-200 bg-secondary-50 px-3 py-2 text-xs text-secondary-600">
                {i18n.t('literals.reszletadatok-frissitese')}
              </div>
            )}
            <div className="space-y-2 text-sm">
              <DetailRow label="Típus" value={VOUCHER_TYPE_LABELS[showDetailModal.voucherType]} />
              <DetailRow label="Státusz" value={showDetailModal.isReversed ? 'Sztornó' : 'Aktív'} />
              <DetailRow
                label="Bruttó"
                value={`${formatCurrency(showDetailModal.grossAmount)} Ft`}
                mono
              />
              <DetailRow
                label="ÁFA"
                value={`${formatCurrency(showDetailModal.vatAmount)} Ft`}
                mono
              />
              {showDetailModal.vatPercentage != null && (
                <DetailRow label="ÁFA %" value={`${showDetailModal.vatPercentage}%`} mono />
              )}
              {showDetailModal.customerName && (
                <DetailRow label="Ügyfél" value={showDetailModal.customerName} />
              )}
              {showDetailModal.customerAddress && (
                <DetailRow label="Lakcím" value={showDetailModal.customerAddress} />
              )}
              {showDetailModal.customerIdentifier && (
                <DetailRow label="Azonosító" value={showDetailModal.customerIdentifier} mono />
              )}
              {showDetailModal.bankAccountNumber && (
                <DetailRow label="Bankszámla" value={showDetailModal.bankAccountNumber} mono />
              )}
              {showDetailModal.companyName && (
                <DetailRow label="Cég" value={showDetailModal.companyName} />
              )}
              {showDetailModal.siteAddress && (
                <DetailRow label="Telephely" value={showDetailModal.siteAddress} />
              )}
              {showDetailModal.deedNumber && (
                <DetailRow label="Okirat" value={showDetailModal.deedNumber} mono />
              )}
              <DetailRow label="Dátum" value={showDetailModal.transactionDate} />
              {showDetailModal.createdByWorker && (
                <DetailRow label="Rögzítette" value={showDetailModal.createdByWorker} />
              )}
              <DetailRow label="Létrehozva" value={formatDateTime(showDetailModal.createdAt)} />
            </div>
            <div className="flex gap-3 mt-6">
              {!showDetailModal.isReversed && (
                <button
                  className="form-button flex items-center gap-2 text-red-600 border-red-200 hover:bg-red-50"
                  onClick={() => {
                    setShowDetailModal(null)
                    setStornoTarget(showDetailModal)
                  }}
                >
                  <XCircle size={16} />
                  {t('cashier.storno')}
                </button>
              )}
              <button
                onClick={() => setShowDetailModal(null)}
                className="form-button-primary flex-1"
              >
                {t('common.close')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Storno Confirm Modal */}
      {stornoTarget && (
        <div
          className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
          onClick={() => setStornoTarget(null)}
        >
          <div
            className="bg-white rounded-lg shadow-xl p-4 max-w-sm w-full mx-4"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-lg font-bold text-secondary-900 mb-3 flex items-center gap-2">
              <XCircle size={20} className="text-red-500" />
              {t('treasury.sztornoMegerosites')}
            </h2>
            <p className="text-sm text-secondary-600 mb-2">
              {stornoTarget.serialNumber} {t('treasury.sztornozasa')}
            </p>
            <p className="text-sm font-semibold text-secondary-800 mb-3">
              {VOUCHER_TYPE_LABELS[stornoTarget.voucherType]}
              {i18n.t('literals.lit-28')} {formatCurrency(stornoTarget.grossAmount)}{' '}
              {t('common.ft')}
            </p>
            <div className="flex gap-3">
              <button className="form-button flex-1" onClick={() => setStornoTarget(null)}>
                {t('common.cancel')}
              </button>
              <button
                className="form-button-primary flex-1 bg-red-600 hover:bg-red-700 border-red-600"
                onClick={() => void handleStorno()}
                disabled={stornoSubmitting}
              >
                {stornoSubmitting ? 'Feldolgozás...' : 'Sztornó'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function DetailRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex justify-between py-1 border-b border-secondary-100">
      <span className="text-secondary-600">{label}</span>
      <span className={`font-semibold text-secondary-900 ${mono ? 'font-mono' : ''}`}>{value}</span>
    </div>
  )
}
