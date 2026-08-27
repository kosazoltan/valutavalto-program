import { useState, useEffect, useMemo } from 'react'
import { Users, Search, Calendar, Download, CheckCircle, Eye, X } from 'lucide-react'
import {
  commissionCalculationApi,
  workerCommissionApi,
  type CommissionCalculation,
  type WorkerCommission,
} from '../../services/api/index'
import { formatInteger, formatDecimal } from '../../utils/numberFormat'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'
import i18n from '../../i18n'

export default function WorkerCommissionPage() {
  const { t } = useTranslation()
  const branchId = useAuthStore((state) => state.worker?.branchId ?? '')
  const [commissions, setCommissions] = useState<WorkerCommission[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [reportMonth, setReportMonth] = useState(() => new Date().toISOString().slice(0, 7))
  const [monthlyReport, setMonthlyReport] = useState<CommissionCalculation[]>([])
  const [monthlyReportLoading, setMonthlyReportLoading] = useState(false)
  const [calculationLoading, setCalculationLoading] = useState<'single' | 'all' | null>(null)
  const [approvingCalculationId, setApprovingCalculationId] = useState<string | null>(null)
  const [selectedCommission, setSelectedCommission] = useState<WorkerCommission | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)

  const filteredCommissions = useMemo(() => {
    if (!searchTerm) return commissions
    const term = searchTerm.toLowerCase()
    return commissions.filter(
      (c) =>
        c.workerName?.toLowerCase().includes(term) || c.branchName?.toLowerCase().includes(term),
    )
  }, [commissions, searchTerm])

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await workerCommissionApi.list()
      setCommissions(data)
    } catch (err) {
      logger.error('WorkerCommissionPage', 'Jutalékok betöltési hiba:', err)
      setError('Hiba a jutalékok betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleFilterByPeriod = async () => {
    if (!branchId) {
      toast.warning('Hiányzó fiók', 'A jutalék időszakos szűréséhez fiók azonosító szükséges')
      return
    }
    if (!startDate || !endDate) {
      toast.warning('Hiányzó adatok', 'Kérjük, adja meg az időszakot')
      return
    }
    try {
      setError(null)
      const data = await workerCommissionApi.getByPeriod(branchId, startDate, endDate)
      setCommissions(data)
    } catch (err) {
      logger.error('WorkerCommissionPage', 'Szűrési hiba:', err)
      setError('Hiba történt az időszak szűrése során')
    }
  }

  const handleExportAccountingList = async () => {
    if (!branchId) {
      toast.warning('Hiányzó fiók', 'Az exporthoz fiók azonosító szükséges')
      return
    }
    if (!startDate || !endDate) {
      toast.warning('Hiányzó adatok', 'Kérjük, adja meg az időszakot')
      return
    }
    try {
      setError(null)
      await workerCommissionApi.getAccountingList(branchId, startDate, endDate)
      /** Megjegyzés: CSV export terve készíthető külön PR-ben. */
    } catch (err) {
      logger.error('WorkerCommissionPage', 'Export hiba:', err)
      setError('Hiba történt az export során')
    }
  }

  const handleCalculatePeriod = async () => {
    if (!branchId) {
      toast.warning('Hiányzó fiók', 'A jutalékszámításhoz fiók azonosító szükséges')
      return
    }
    if (!startDate || !endDate) {
      toast.warning('Hiányzó adatok', 'Kérjük, adja meg az időszakot')
      return
    }
    try {
      setError(null)
      const data = await workerCommissionApi.calculate(branchId, startDate, endDate)
      setCommissions(data)
    } catch (err) {
      logger.error('WorkerCommissionPage', 'Időszaki jutalékszámítás hiba:', err)
      setError('Hiba történt az időszaki jutalék számítása során')
    }
  }

  const handleLoadMonthlyReport = async () => {
    if (!reportMonth) {
      toast.warning('Hiányzó hónap', 'Kérjük, adja meg a jutalék riport hónapját')
      return
    }
    try {
      setMonthlyReportLoading(true)
      setError(null)
      setMonthlyReport(await commissionCalculationApi.report(reportMonth))
    } catch (err) {
      logger.error('WorkerCommissionPage', 'Havi jutalék riport hiba:', err)
      setMonthlyReport([])
      setError('Hiba történt a havi jutalék riport betöltése során')
    } finally {
      setMonthlyReportLoading(false)
    }
  }

  const handleCalculateMonthly = async (scope: 'single' | 'all') => {
    if (!reportMonth) {
      toast.warning('Hiányzó hónap', 'Kérjük, adja meg a jutalék számítás hónapját')
      return
    }
    try {
      setCalculationLoading(scope)
      setError(null)
      if (scope === 'all') {
        setMonthlyReport(
          await commissionCalculationApi.calculateAll(reportMonth, branchId || undefined),
        )
      } else {
        setMonthlyReport([await commissionCalculationApi.calculate(reportMonth)])
      }
    } catch (err) {
      logger.error('WorkerCommissionPage', 'Havi jutalékszámítás hiba:', err)
      setError('Hiba történt a havi jutalék számítás során')
    } finally {
      setCalculationLoading(null)
    }
  }

  const handleApproveMonthlyCalculation = async (id: string) => {
    try {
      setApprovingCalculationId(id)
      setError(null)
      const approved = await commissionCalculationApi.approve(id)
      setMonthlyReport((current) => current.map((row) => (row.id === id ? approved : row)))
    } catch (err) {
      logger.error('WorkerCommissionPage', 'Havi jutalék jóváhagyási hiba:', err)
      setError('Hiba történt a havi jutalék jóváhagyása során')
    } finally {
      setApprovingCalculationId(null)
    }
  }

  const handleLoadCommissionDetail = async (id: string) => {
    try {
      setDetailLoadingId(id)
      setError(null)
      setSelectedCommission(await workerCommissionApi.getById(id))
    } catch (err) {
      logger.error('WorkerCommissionPage', 'Jutalék részletek betöltési hiba:', err)
      setError('Hiba történt a jutalék részleteinek betöltése során')
    } finally {
      setDetailLoadingId(null)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">{i18n.t('literals.betoltes')}</div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Users />
          {t('commissions.dolgozoiJutalekok')}
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {selectedCommission && (
        <section
          className="rounded border border-blue-200 bg-blue-50 p-3"
          data-testid="worker-commission-detail"
        >
          <div className="mb-3 flex items-start justify-between gap-3">
            <div className="min-w-0">
              <h2 className="truncate text-base font-bold text-blue-950">
                {selectedCommission.workerName}
              </h2>
              <p className="text-sm text-blue-900">{selectedCommission.branchName || '-'}</p>
            </div>
            <button
              type="button"
              onClick={() => setSelectedCommission(null)}
              className="toolbar-button"
              aria-label="Jutalék részletek bezárása"
              title="Bezárás"
            >
              <X size={16} />
            </button>
          </div>
          <dl className="grid grid-cols-2 gap-2 text-sm md:grid-cols-4">
            <DetailItem
              label={t('common.period')}
              value={`${selectedCommission.periodStart} - ${selectedCommission.periodEnd}`}
            />
            <DetailItem
              label={t('archiving.tranzakciok')}
              value={String(selectedCommission.transactionCount || 0)}
            />
            <DetailItem
              label={t('commissions.jutalek')}
              value={
                selectedCommission.commissionRate
                  ? `${formatDecimal(selectedCommission.commissionRate * 100, 2, 2)}%`
                  : '-'
              }
            />
            <DetailItem
              label={t('commissions.jutalekOsszeg')}
              value={`${selectedCommission.commissionAmount ? formatInteger(selectedCommission.commissionAmount) : '0'} ${selectedCommission.currencyCode || ''}`.trim()}
            />
            <DetailItem
              label={t('common.amount')}
              value={`${selectedCommission.totalTransactionAmount ? formatInteger(selectedCommission.totalTransactionAmount) : '0'} ${selectedCommission.currencyCode || ''}`.trim()}
            />
            <DetailItem
              label={t('common.status')}
              value={selectedCommission.statusName || selectedCommission.statusDid || '-'}
            />
            <DetailItem label="Számítás dátuma" value={selectedCommission.calculationDate || '-'} />
            <DetailItem label="Jóváhagyó" value={selectedCommission.approvedByName || '-'} />
          </dl>
          {selectedCommission.notes && (
            <div className="mt-3 rounded border border-blue-100 bg-white px-3 py-2 text-sm text-blue-950">
              {selectedCommission.notes}
            </div>
          )}
        </section>
      )}

      <div className="form-panel space-y-4">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
          <div>
            <label className="form-label">{t('common.startDate')}</label>
            <input
              type="date"
              className="form-input"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
            />
          </div>
          <div>
            <label className="form-label">{t('common.endDate')}</label>
            <input
              type="date"
              className="form-input"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
            />
          </div>
          <div className="flex items-end gap-2">
            <button
              onClick={handleFilterByPeriod}
              className="form-button-primary flex items-center gap-2"
            >
              <Calendar size={16} />
              {t('common.filter')}
            </button>
            <button
              onClick={handleExportAccountingList}
              className="form-button flex items-center gap-2"
            >
              <Download size={16} />
              {t('commissions.export')}
            </button>
            <button onClick={handleCalculatePeriod} className="form-button flex items-center gap-2">
              <CheckCircle size={16} />
              {i18n.t('literals.idoszaki-szamitas')}
            </button>
          </div>
          <div>
            <label className="form-label">{t('common.search')}</label>
            <div className="relative">
              <Search
                className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={16}
              />
              <input
                type="text"
                className="form-input pl-8"
                placeholder="Dolgozó vagy fiók..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="form-panel">
        <div className="mb-3 flex flex-col gap-3 border-b border-gray-200 pb-3 md:flex-row md:items-end md:justify-between">
          <div className="min-w-0">
            <h2 className="text-base font-bold text-gray-800">
              {i18n.t('literals.havi-jutalekszamitas-riport')}
            </h2>
            <p className="text-sm text-gray-500">
              {i18n.t('literals.backend-szamitasi-riport-a-kivalasztott')}
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end">
            <div>
              <label className="form-label">{i18n.t('literals.honap')}</label>
              <input
                type="month"
                className="form-input"
                value={reportMonth}
                onChange={(e) => setReportMonth(e.target.value)}
              />
            </div>
            <button
              type="button"
              onClick={handleLoadMonthlyReport}
              disabled={monthlyReportLoading || calculationLoading != null}
              className="form-button-primary flex min-h-10 items-center justify-center gap-2 disabled:opacity-60"
            >
              <Calendar size={16} />
              {monthlyReportLoading ? 'Betöltés...' : 'Riport betöltése'}
            </button>
            <button
              type="button"
              onClick={() => void handleCalculateMonthly('single')}
              disabled={monthlyReportLoading || calculationLoading != null}
              className="form-button flex min-h-10 items-center justify-center gap-2 disabled:opacity-60"
            >
              <Calendar size={16} />
              {calculationLoading === 'single' ? 'Számítás...' : 'Saját számítás'}
            </button>
            <button
              type="button"
              onClick={() => void handleCalculateMonthly('all')}
              disabled={monthlyReportLoading || calculationLoading != null}
              className="form-button flex min-h-10 items-center justify-center gap-2 disabled:opacity-60"
            >
              <Users size={16} />
              {calculationLoading === 'all' ? 'Számítás...' : 'Fiók számítása'}
            </button>
          </div>
        </div>

        {monthlyReport.length > 0 && (
          <div className="mb-4 space-y-3 md:hidden">
            {monthlyReport.map((row) => (
              <article
                key={row.id}
                className="rounded border border-gray-200 bg-white p-3 shadow-sm"
              >
                <div className="mb-3 flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.dolgozo-id')}
                    </p>
                    <p className="text-lg font-bold text-gray-900">{row.workerId}</p>
                  </div>
                  <span
                    className={`badge ${row.status === 'APPROVED' ? 'badge-green' : 'badge-yellow'}`}
                  >
                    {row.status}
                  </span>
                </div>
                <dl className="grid grid-cols-2 gap-x-3 gap-y-2 text-sm">
                  <div>
                    <dt className="text-gray-500">{i18n.t('literals.idoszak')}</dt>
                    <dd className="font-medium text-gray-900">{row.period}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{i18n.t('literals.tranzakcio')}</dt>
                    <dd className="font-medium text-gray-900">{row.totalTransactions ?? 0}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{i18n.t('literals.forgalom-huf')}</dt>
                    <dd className="font-mono text-gray-900">
                      {formatInteger(row.totalVolumeHuf ?? 0)}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{i18n.t('literals.jutalek')}</dt>
                    <dd className="font-mono text-gray-900">
                      {formatDecimal((row.commissionRate ?? 0) * 100, 2, 2)}
                      {i18n.t('literals.lit-30')}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{i18n.t('literals.jutalek-2')}</dt>
                    <dd className="font-mono text-gray-900">
                      {formatInteger(row.commissionAmount ?? 0)}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{i18n.t('literals.bonusz')}</dt>
                    <dd className="font-mono text-gray-900">
                      {formatInteger(row.bonusAmount ?? 0)}
                    </dd>
                  </div>
                  <div className="col-span-2 border-t border-gray-100 pt-2">
                    <dt className="text-gray-500">{i18n.t('literals.netto')}</dt>
                    <dd className="font-mono text-lg font-bold text-gray-900">
                      {formatInteger(row.netCommission ?? 0)}
                    </dd>
                  </div>
                </dl>
                {row.status === 'CALCULATED' && (
                  <button
                    type="button"
                    onClick={() => void handleApproveMonthlyCalculation(row.id)}
                    disabled={approvingCalculationId === row.id}
                    className="mt-3 flex min-h-10 w-full items-center justify-center gap-2 rounded bg-emerald-600 px-3 text-sm font-semibold text-white disabled:opacity-60"
                  >
                    <CheckCircle size={16} />
                    {approvingCalculationId === row.id
                      ? `${t('common.approve')}...`
                      : t('common.approve')}
                  </button>
                )}
              </article>
            ))}
          </div>
        )}

        {monthlyReport.length > 0 && (
          <div className="mb-4 hidden overflow-x-auto md:block">
            <table className="data-grid w-full min-w-[760px]">
              <thead>
                <tr>
                  <th>{i18n.t('literals.dolgozo-id')}</th>
                  <th>{i18n.t('literals.idoszak')}</th>
                  <th>{i18n.t('literals.tranzakcio')}</th>
                  <th>{i18n.t('literals.forgalom-huf')}</th>
                  <th>{i18n.t('literals.jutalek')}</th>
                  <th>{i18n.t('literals.jutalek-2')}</th>
                  <th>{i18n.t('literals.bonusz')}</th>
                  <th>{i18n.t('literals.netto')}</th>
                  <th>{i18n.t('literals.statusz')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {monthlyReport.map((row) => (
                  <tr key={row.id}>
                    <td>{row.workerId}</td>
                    <td>{row.period}</td>
                    <td>{row.totalTransactions ?? 0}</td>
                    <td className="font-mono">{formatInteger(row.totalVolumeHuf ?? 0)}</td>
                    <td className="font-mono">
                      {formatDecimal((row.commissionRate ?? 0) * 100, 2, 2)}
                      {i18n.t('literals.lit-30')}
                    </td>
                    <td className="font-mono">{formatInteger(row.commissionAmount ?? 0)}</td>
                    <td className="font-mono">{formatInteger(row.bonusAmount ?? 0)}</td>
                    <td className="font-bold font-mono">{formatInteger(row.netCommission ?? 0)}</td>
                    <td>
                      <span
                        className={`badge ${row.status === 'APPROVED' ? 'badge-green' : 'badge-yellow'}`}
                      >
                        {row.status}
                      </span>
                    </td>
                    <td>
                      {row.status === 'CALCULATED' ? (
                        <button
                          type="button"
                          onClick={() => void handleApproveMonthlyCalculation(row.id)}
                          disabled={approvingCalculationId === row.id}
                          className="inline-flex min-h-9 items-center justify-center gap-1 rounded bg-emerald-600 px-3 text-xs font-semibold text-white disabled:opacity-60"
                        >
                          <CheckCircle size={14} />
                          {approvingCalculationId === row.id
                            ? `${t('common.approve')}...`
                            : t('common.approve')}
                        </button>
                      ) : (
                        <span className="text-xs text-gray-400">{i18n.t('literals.lit-15')}</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="space-y-3 md:hidden">
          {filteredCommissions.length === 0 ? (
            <div className="rounded border border-gray-200 bg-white p-4 text-center text-gray-500">
              {t('common.noResult')}
            </div>
          ) : (
            filteredCommissions.map((c) => (
              <article key={c.id} className="rounded border border-gray-200 bg-white p-3 shadow-sm">
                <div className="mb-3 flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="truncate text-lg font-bold text-gray-900">{c.workerName}</p>
                    <p className="truncate text-sm text-gray-500">{c.branchName || '-'}</p>
                  </div>
                  <span
                    className={`badge ${c.statusName === 'Jóváhagyva' ? 'badge-green' : 'badge-yellow'}`}
                  >
                    {c.statusName}
                  </span>
                </div>
                <dl className="grid grid-cols-2 gap-x-3 gap-y-2 text-sm">
                  <div className="col-span-2">
                    <dt className="text-gray-500">{t('common.period')}</dt>
                    <dd className="font-medium text-gray-900">
                      {c.periodStart}
                      {i18n.t('literals.lit-17')}
                      {c.periodEnd}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{t('archiving.tranzakciok')}</dt>
                    <dd className="font-medium text-gray-900">{c.transactionCount || 0}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{t('commissions.jutalek')}</dt>
                    <dd className="font-mono text-gray-900">
                      {c.commissionRate ? `${formatDecimal(c.commissionRate * 100, 2, 2)}%` : '-'}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{t('common.amount')}</dt>
                    <dd className="font-mono text-gray-900">
                      {c.totalTransactionAmount ? formatInteger(c.totalTransactionAmount) : '0'}{' '}
                      {c.currencyCode}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{t('commissions.jutalekOsszeg')}</dt>
                    <dd className="font-mono font-bold text-gray-900">
                      {c.commissionAmount ? formatInteger(c.commissionAmount) : '0'}{' '}
                      {c.currencyCode}
                    </dd>
                  </div>
                </dl>
                <button
                  type="button"
                  onClick={() => void handleLoadCommissionDetail(c.id)}
                  disabled={detailLoadingId === c.id}
                  className="mt-3 flex min-h-10 w-full items-center justify-center gap-2 rounded border border-gray-300 bg-white px-3 text-sm font-semibold text-gray-700 disabled:opacity-60"
                >
                  <Eye size={16} />
                  {detailLoadingId === c.id ? 'Betöltés...' : 'Részletek'}
                </button>
              </article>
            ))
          )}
        </div>

        <div className="hidden overflow-x-auto md:block">
          <table className="data-grid w-full min-w-[880px]">
            <thead>
              <tr>
                <th>{t('commissions.dolgozo')}</th>
                <th>{t('commissions.fok')}</th>
                <th>{t('common.period')}</th>
                <th>{t('archiving.tranzakciok')}</th>
                <th>{t('common.amount')}</th>
                <th>{t('commissions.jutalek')}</th>
                <th>{t('commissions.jutalekOsszeg')}</th>
                <th>{t('common.status')}</th>
                <th>{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredCommissions.length === 0 ? (
                <tr>
                  <td colSpan={9} className="text-center text-gray-500 py-4">
                    {t('common.noResult')}
                  </td>
                </tr>
              ) : (
                filteredCommissions.map((c) => (
                  <tr key={c.id}>
                    <td>{c.workerName}</td>
                    <td>{c.branchName || '-'}</td>
                    <td>
                      {c.periodStart}
                      {i18n.t('literals.lit-17')}
                      {c.periodEnd}
                    </td>
                    <td>{c.transactionCount || 0}</td>
                    <td className="font-mono">
                      {c.totalTransactionAmount ? formatInteger(c.totalTransactionAmount) : '0'}{' '}
                      {c.currencyCode}
                    </td>
                    <td className="font-mono">
                      {c.commissionRate ? `${formatDecimal(c.commissionRate * 100, 2, 2)}%` : '-'}
                    </td>
                    <td className="font-bold font-mono">
                      {c.commissionAmount ? formatInteger(c.commissionAmount) : '0'}{' '}
                      {c.currencyCode}
                    </td>
                    <td>
                      <span
                        className={`badge ${c.statusName === 'Jóváhagyva' ? 'badge-green' : 'badge-yellow'}`}
                      >
                        {c.statusName}
                      </span>
                    </td>
                    <td>
                      <button
                        type="button"
                        onClick={() => void handleLoadCommissionDetail(c.id)}
                        disabled={detailLoadingId === c.id}
                        className="toolbar-button"
                        aria-label={`Jutalék részletek: ${c.workerName}`}
                        title="Részletek"
                      >
                        <Eye
                          size={14}
                          className={detailLoadingId === c.id ? 'animate-pulse' : ''}
                        />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

function DetailItem({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded border border-blue-100 bg-white px-3 py-2">
      <dt className="text-xs text-blue-700">{label}</dt>
      <dd className="mt-0.5 break-words font-semibold text-blue-950">{value}</dd>
    </div>
  )
}
