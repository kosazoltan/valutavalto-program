import { useEffect, useState, type FormEvent } from 'react'
import { Shield, AlertTriangle, Users, Clock, XCircle, FileText, RefreshCw } from 'lucide-react'
import {
  amlApi,
  RollingWindowAuditDto,
  AmlDailySummary,
  AmlReportDto,
  AmlCheckResult,
} from '../../services/api/aml'
import { logger } from '../../utils/logger'
import { localIsoDate } from '../../utils/dateFormat'
import { useTranslation } from 'react-i18next'
import SuspiciousCustomersPanel from './SuspiciousCustomersPanel'
import i18n from '../../i18n'

// ============================================================================

const formatNumber = (value: number | null | undefined) => (value ?? 0).toLocaleString('hu-HU')
// Sprint 6.2 - Compliance Dashboard
//
// Pmt. (2017. LIII. tv.) + AML + Szankciós komplex osszesito feluletre.
// Celja: hatosagi ellenorzesek szempontjabol egybe gyujteni:
//  1. Overdue (lejárt hataridejű) bejelentesek - 2 munkanap utan
//  2. 8 napos rolling window feletti ugyfelek - 4.5M HUF alapertelmezett limit
//  3. Pending bejelentesek
//  4. Napi osszesito (mai nap)
// ============================================================================

export default function ComplianceDashboardPage() {
  const { t } = useTranslation()
  const [today] = useState(() => localIsoDate())
  const [summary, setSummary] = useState<AmlDailySummary | null>(null)
  const [overdue, setOverdue] = useState<AmlReportDto[]>([])
  const [pending, setPending] = useState<AmlReportDto[]>([])
  const [rollingWindow, setRollingWindow] = useState<RollingWindowAuditDto[]>([])
  const [threshold, setThreshold] = useState<number>(4500000)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [manualCheckForm, setManualCheckForm] = useState({
    customerId: '',
    amountHuf: '',
    currencyCode: 'HUF',
  })
  const [manualCheckResult, setManualCheckResult] = useState<AmlCheckResult | null>(null)
  const [manualCheckLoading, setManualCheckLoading] = useState(false)
  const [manualCheckError, setManualCheckError] = useState<string | null>(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const [s, o, p, r] = await Promise.all([
        amlApi.dailySummary(today).catch((e) => {
          logger.warn('compliance', 'summary error: ' + String(e))
          return null
        }),
        amlApi.overdueReports().catch((e) => {
          logger.warn('compliance', 'overdue error: ' + String(e))
          return []
        }),
        amlApi.pendingReports().catch((e) => {
          logger.warn('compliance', 'pending error: ' + String(e))
          return []
        }),
        amlApi.rollingWindowAudit(threshold).catch((e) => {
          logger.warn('compliance', 'rolling error: ' + String(e))
          return []
        }),
      ])
      setSummary(s)
      setOverdue(o)
      setPending(p)
      setRollingWindow(r)
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [today])

  const handleRollingRefresh = async () => {
    try {
      const r = await amlApi.rollingWindowAudit(threshold)
      setRollingWindow(r)
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err)
      setError(msg)
    }
  }

  const handleManualCheck = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const amountHuf = Number(manualCheckForm.amountHuf)
    if (!Number.isFinite(amountHuf) || amountHuf <= 0) {
      setManualCheckError('Adj meg pozitív HUF összeget.')
      setManualCheckResult(null)
      return
    }

    try {
      setManualCheckLoading(true)
      setManualCheckError(null)
      const result = await amlApi.checkTransaction({
        amountHuf,
        customerId: manualCheckForm.customerId.trim() || undefined,
        currencyCode: manualCheckForm.currencyCode.trim() || undefined,
      })
      setManualCheckResult(result)
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err)
      setManualCheckError(msg)
      setManualCheckResult(null)
    } finally {
      setManualCheckLoading(false)
    }
  }

  return (
    <div className="max-w-7xl mx-auto">
      <div className="flex flex-col gap-3 mb-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-base font-bold flex items-center gap-2">
            <Shield className="w-5 h-5 text-blue-600" />
            {t('compliance.complianceDashboard')}
          </h1>
          <p className="text-gray-600 text-xs">
            {t('compliance.pmt2017LiiiTvAmlSzankcios8NaposGorduloLimitAudit')}
          </p>
        </div>
        <button
          onClick={load}
          className="flex items-center justify-center gap-1 px-3 py-2 border rounded hover:bg-gray-50"
        >
          <RefreshCw className="w-4 h-4" />
          {t('common.refresh')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-3 mb-4 text-red-700 flex items-center gap-2">
          <XCircle className="w-5 h-5" /> {error}
        </div>
      )}

      {loading ? (
        <div className="text-center text-gray-500 py-8">{i18n.t('literals.toltodik')}</div>
      ) : (
        <>
          {/* KPI kartyak */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div className="bg-red-50 border border-red-200 rounded p-4">
              <div className="text-sm text-red-700 flex items-center gap-1">
                <Clock className="w-4 h-4" />
                {t('compliance.overdueBejelentesek')}
              </div>
              <div className="text-3xl font-bold text-red-700 mt-1">{overdue.length}</div>
              <div className="text-xs text-red-600 mt-1">{t('compliance.2MunkanapUtanLejart')}</div>
            </div>
            <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
              <div className="text-sm text-yellow-700 flex items-center gap-1">
                <FileText className="w-4 h-4" />
                {t('compliance.pendingBejelentesek')}
              </div>
              <div className="text-3xl font-bold mt-1">{pending.length}</div>
              <div className="text-xs text-gray-600 mt-1">{t('compliance.draftSubmitted')}</div>
            </div>
            <div className="bg-orange-50 border border-orange-200 rounded p-4">
              <div className="text-sm text-orange-700 flex items-center gap-1">
                <Users className="w-4 h-4" />
                {t('compliance.8NaposLimit')}
              </div>
              <div className="text-3xl font-bold mt-1">{rollingWindow.length}</div>
              <div className="text-xs text-gray-600 mt-1">
                {t('compliance.ugyfelAKuszobFolott')}
              </div>
            </div>
            <div className="bg-blue-50 border border-blue-200 rounded p-4">
              <div className="text-sm text-blue-700 flex items-center gap-1">
                <AlertTriangle className="w-4 h-4" />
                {t('compliance.maiGyanus')}
              </div>
              <div className="text-3xl font-bold mt-1">{summary?.suspiciousChecks ?? 0}</div>
              <div className="text-xs text-gray-600 mt-1">{today}</div>
            </div>
          </div>

          <div className="bg-white shadow rounded overflow-hidden mb-6">
            <div className="bg-slate-100 px-4 py-2 text-slate-900 font-semibold">
              {i18n.t('literals.kezi-aml-tranzakcio-ellenorzes')}
            </div>
            <form
              onSubmit={(event) => void handleManualCheck(event)}
              className="grid grid-cols-1 gap-3 p-4 lg:grid-cols-[1.2fr_1fr_0.7fr_auto] lg:items-end"
            >
              <div>
                <label className="form-label">{i18n.t('literals.ugyfel-azonosito')}</label>
                <input
                  type="text"
                  value={manualCheckForm.customerId}
                  onChange={(event) =>
                    setManualCheckForm((prev) => ({ ...prev, customerId: event.target.value }))
                  }
                  className="form-input font-mono"
                  placeholder="opcionális"
                  data-testid="aml-manual-customer-id"
                />
              </div>
              <div>
                <label className="form-label required">{i18n.t('literals.osszeg-huf')}</label>
                <input
                  type="number"
                  min="1"
                  value={manualCheckForm.amountHuf}
                  onChange={(event) =>
                    setManualCheckForm((prev) => ({ ...prev, amountHuf: event.target.value }))
                  }
                  className="form-input font-mono"
                  required
                  data-testid="aml-manual-amount"
                />
              </div>
              <div>
                <label className="form-label">{i18n.t('literals.valuta')}</label>
                <input
                  type="text"
                  value={manualCheckForm.currencyCode}
                  onChange={(event) =>
                    setManualCheckForm((prev) => ({
                      ...prev,
                      currencyCode: event.target.value.toUpperCase(),
                    }))
                  }
                  className="form-input font-mono uppercase"
                  maxLength={3}
                  data-testid="aml-manual-currency"
                />
              </div>
              <button
                type="submit"
                disabled={manualCheckLoading}
                className="form-button-primary justify-center"
                data-testid="aml-manual-check-button"
              >
                {manualCheckLoading ? 'Ellenőrzés...' : 'Ellenőrzés'}
              </button>
            </form>
            {(manualCheckError || manualCheckResult) && (
              <div className="border-t border-slate-200 p-4">
                {manualCheckError && (
                  <div
                    className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700"
                    role="alert"
                  >
                    {manualCheckError}
                  </div>
                )}
                {manualCheckResult && (
                  <div
                    className={`rounded border p-3 text-sm ${
                      manualCheckResult.blocked
                        ? 'border-red-300 bg-red-50 text-red-900'
                        : manualCheckResult.requiresManagerApproval ||
                            manualCheckResult.requiresEnhanced
                          ? 'border-amber-300 bg-amber-50 text-amber-900'
                          : 'border-emerald-300 bg-emerald-50 text-emerald-900'
                    }`}
                    role="status"
                    data-testid="aml-manual-result"
                  >
                    <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                      <div className="font-semibold">
                        {i18n.t('literals.tranzakcio-tipus')}
                        {manualCheckResult.transactionType}
                      </div>
                      <div className="font-mono">
                        {i18n.t('literals.8-nap')}
                        {manualCheckResult.rollingWindowTotal?.toLocaleString('hu-HU') ?? 0}{' '}
                        {i18n.t('literals.lit-33')}
                        {manualCheckResult.rollingWindowLimit?.toLocaleString('hu-HU') ?? 0}
                        {i18n.t('literals.huf-2')}
                      </div>
                    </div>
                    <div className="mt-2 grid grid-cols-1 gap-2 sm:grid-cols-3">
                      <span>{manualCheckResult.blocked ? 'Blokkolt' : 'Nem blokkolt'}</span>
                      <span>
                        {manualCheckResult.requiresId
                          ? 'Azonosítás kell'
                          : 'Azonosítás nem jelzett'}
                      </span>
                      <span>
                        {manualCheckResult.requiresManagerApproval
                          ? 'Vezetői jóváhagyás kell'
                          : 'Vezetői jóváhagyás nem jelzett'}
                      </span>
                    </div>
                    {manualCheckResult.managerApprovalReason && (
                      <div className="mt-2 font-medium">
                        {manualCheckResult.managerApprovalReason}
                      </div>
                    )}
                    {manualCheckResult.warnings?.length > 0 && (
                      <ul className="mt-2 list-disc space-y-1 pl-5">
                        {manualCheckResult.warnings.map((warning, index) => (
                          <li key={`${warning}-${index}`}>{warning}</li>
                        ))}
                      </ul>
                    )}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* OVERDUE tablazat */}
          {overdue.length > 0 && (
            <div className="bg-white shadow rounded overflow-hidden mb-6">
              <div className="bg-red-100 px-4 py-2 text-red-900 font-semibold">
                {t('compliance.lejartHataridejuBejelentesek')}
                {overdue.length}
                {i18n.t('literals.lit-2')}
              </div>
              <div className="overflow-x-auto">
                <table className="w-full min-w-[640px] text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left">{t('common.customer')}</th>
                      <th className="px-4 py-2 text-left">{t('backup.tipus')}</th>
                      <th className="px-4 py-2 text-right">{t('compliance.osszegHuf')}</th>
                      <th className="px-4 py-2 text-left">{t('compliance.hatarido')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {overdue.slice(0, 10).map((r) => (
                      <tr key={r.id} className="border-t">
                        <td className="px-4 py-2">{r.customerName || r.customerId}</td>
                        <td className="px-4 py-2">{r.reportType}</td>
                        <td className="px-4 py-2 text-right font-mono">
                          {formatNumber(r.amountHuf)}
                        </td>
                        <td className="px-4 py-2 text-red-600">
                          {r.deadlineAt && new Date(r.deadlineAt).toLocaleString('hu-HU')}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Rolling window tablazat */}
          <div className="bg-white shadow rounded overflow-hidden mb-6">
            <div className="bg-orange-100 px-4 py-3 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div className="text-orange-900 font-semibold">
                {t('compliance.8NaposGorduloLimitFelettiUgyfelek')}
                {rollingWindow.length}
                {i18n.t('literals.lit-2')}
              </div>
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
                <label className="text-sm">{t('compliance.kuszobHuf')}</label>
                <input
                  type="number"
                  value={threshold}
                  onChange={(e) => setThreshold(parseInt(e.target.value) || 4500000)}
                  className="border rounded px-2 py-1 text-sm sm:w-28"
                />
                <button
                  onClick={handleRollingRefresh}
                  className="px-2 py-1 bg-orange-600 text-white rounded text-xs"
                >
                  {t('common.refresh')}
                </button>
              </div>
            </div>
            {rollingWindow.length === 0 ? (
              <div className="p-6 text-center text-gray-500 text-sm">
                {t('compliance.nincsUgyfelAKuszobFelett')}
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full min-w-[640px] text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left">{t('common.customer')}</th>
                      <th className="px-4 py-2 text-right">{t('compliance.8NaposOsszeg')}</th>
                      <th className="px-4 py-2 text-right">{t('compliance.kuszob')}</th>
                      <th className="px-4 py-2 text-center">{t('compliance.highRiskFlag')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rollingWindow.map((r) => (
                      <tr key={r.customerId} className="border-t">
                        <td className="px-4 py-2">
                          <div className="font-medium">{r.customerName || r.customerId}</div>
                          <div className="text-xs text-gray-500">{r.customerId}</div>
                        </td>
                        <td className="px-4 py-2 text-right font-mono">
                          {formatNumber(r.rollingWindowTotalHuf)}
                        </td>
                        <td className="px-4 py-2 text-right font-mono">
                          {(r.exceedPercent ?? 0).toFixed(1)}
                          {i18n.t('literals.lit-30')}
                        </td>
                        <td className="px-4 py-2 text-center">
                          {r.highRiskFlag ? (
                            <span className="px-2 py-1 bg-red-100 text-red-700 rounded text-xs">
                              {i18n.t('literals.magas')}
                            </span>
                          ) : (
                            <span className="text-gray-400 text-xs">
                              {i18n.t('literals.lit-15')}
                            </span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <SuspiciousCustomersPanel />

          {/* Napi osszesito */}
          {summary && (
            <div className="bg-white shadow rounded overflow-hidden">
              <div className="bg-blue-100 px-4 py-2 text-blue-900 font-semibold">
                {t('compliance.maiNapOsszesito')}
                {summary.date}
                {i18n.t('literals.lit-2')}
              </div>
              <div className="grid grid-cols-1 gap-4 p-4 sm:grid-cols-2 lg:grid-cols-4">
                <div>
                  <div className="text-xs text-gray-600">{t('compliance.standardEllenorzes')}</div>
                  <div className="text-lg font-bold">{summary.standardChecks}</div>
                </div>
                <div>
                  <div className="text-xs text-gray-600">{t('compliance.fokozott')}</div>
                  <div className="text-lg font-bold">{summary.enhancedChecks}</div>
                </div>
                <div>
                  <div className="text-xs text-gray-600">{t('compliance.gyanus')}</div>
                  <div className="text-lg font-bold text-orange-600">
                    {summary.suspiciousChecks}
                  </div>
                </div>
                <div>
                  <div className="text-xs text-gray-600">{t('compliance.osszegHuf2')}</div>
                  <div className="text-lg font-bold font-mono">
                    {formatNumber(summary.totalAmountHuf)}
                  </div>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}
