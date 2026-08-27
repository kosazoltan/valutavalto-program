import { Fragment, useEffect, useState, useCallback } from 'react'
import {
  CheckCircle2,
  Send,
  XCircle,
  RefreshCw,
  AlertTriangle,
  FileText,
  Users,
  Clock,
  Plus,
  Printer,
} from 'lucide-react'
import {
  exchangeRateMasterApi,
  type ExchangeRateMaster,
  type MasterRateStatus,
  type ExchangeRateDistribution,
  type CreateMasterRateRequest,
  type PendingPrintObligation,
} from '../../services/api/exchangeRateMaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

// =============================================================================
// RateMasterWorkflowPage — Foertektari arfolyam-publikalas workflow
//
// 3 tab:
//   1. DRAFT    - arfolyam-tervek, "Approve" gomb
//   2. APPROVED - jovahagyott arfolyamok, "Publish" gomb (workgroup selector)
//   3. PUBLISHED - aktiv arfolyamok + elosztas-status (melyik penztar kapta meg)
// =============================================================================

type TabKey = 'DRAFT' | 'APPROVED' | 'PUBLISHED'

const STATUS_LABELS: Record<MasterRateStatus, string> = {
  DRAFT: 'Vázlat',
  APPROVED: 'Jóváhagyva',
  PUBLISHED: 'Publikálva',
  REVOKED: 'Visszavonva',
  ARCHIVED: 'Archív',
}

const STATUS_COLORS: Record<MasterRateStatus, string> = {
  DRAFT: 'bg-amber-100 text-amber-800 border-amber-300',
  APPROVED: 'bg-blue-100 text-blue-800 border-blue-300',
  PUBLISHED: 'bg-green-100 text-green-800 border-green-300',
  REVOKED: 'bg-red-100 text-red-800 border-red-300',
  ARCHIVED: 'bg-slate-100 text-slate-600 border-slate-300',
}

export default function RateMasterWorkflowPage() {
  const { t } = useTranslation()
  const [activeTab, setActiveTab] = useState<TabKey>('DRAFT')
  const [rates, setRates] = useState<ExchangeRateMaster[]>([])
  const [loading, setLoading] = useState(true)
  const [err, setErr] = useState<string | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)
  const [busyDistributionId, setBusyDistributionId] = useState<string | null>(null)
  const [expandedDistId, setExpandedDistId] = useState<string | null>(null)
  const [distData, setDistData] = useState<Record<string, ExchangeRateDistribution[]>>({})
  const [pendingPrintObligations, setPendingPrintObligations] = useState<
    Record<string, PendingPrintObligation>
  >({})
  const [creating, setCreating] = useState(false)
  const [createForm, setCreateForm] = useState({
    currencyId: '',
    baseBuyRate: '',
    baseSellRate: '',
    officialRate: '',
    notes: '',
  })

  const loadRates = useCallback(async () => {
    setLoading(true)
    setErr(null)
    try {
      const data = await exchangeRateMasterApi.list(activeTab)
      setRates(data)
    } catch (e) {
      logger.error('RateMasterWorkflowPage', 'list err:', e)
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }, [activeTab])

  useEffect(() => {
    void loadRates()
  }, [loadRates])

  const parseDecimalField = (value: string): number | null => {
    const normalized = value.trim().replace(/\s/g, '').replace(',', '.')
    if (!normalized) return null
    const parsed = Number(normalized)
    return Number.isFinite(parsed) ? parsed : null
  }

  const handleCreateDraft = async () => {
    const currencyId = Number.parseInt(createForm.currencyId, 10)
    const baseBuyRate = parseDecimalField(createForm.baseBuyRate)
    const baseSellRate = parseDecimalField(createForm.baseSellRate)
    const officialRate = parseDecimalField(createForm.officialRate)

    if (
      !Number.isFinite(currencyId) ||
      currencyId <= 0 ||
      baseBuyRate === null ||
      baseSellRate === null
    ) {
      setErr('Valuta ID, vételi és eladási árfolyam kötelező.')
      return
    }

    const payload: CreateMasterRateRequest = {
      currencyId,
      baseBuyRate,
      baseSellRate,
      ...(officialRate !== null ? { officialRate } : {}),
      ...(createForm.notes.trim() ? { notes: createForm.notes.trim() } : {}),
    }

    setCreating(true)
    setErr(null)
    try {
      await exchangeRateMasterApi.create(payload)
      setCreateForm({
        currencyId: '',
        baseBuyRate: '',
        baseSellRate: '',
        officialRate: '',
        notes: '',
      })
      setActiveTab('DRAFT')
      setRates(await exchangeRateMasterApi.list('DRAFT'))
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setCreating(false)
    }
  }

  const handleApprove = async (id: string) => {
    setBusyId(id)
    try {
      await exchangeRateMasterApi.approve(id)
      await loadRates()
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setBusyId(null)
    }
  }

  const handleAcknowledgeDistribution = async (rateId: string, distributionId: string) => {
    setBusyDistributionId(distributionId)
    setErr(null)
    try {
      const obligations = await exchangeRateMasterApi.getPendingPrintObligations()
      const obligation = obligations.find((item) => item.distributionId === distributionId)
      setPendingPrintObligations((prev) => ({
        ...prev,
        ...Object.fromEntries(obligations.map((item) => [item.distributionId, item])),
      }))
      if (!obligation?.printProofToken) {
        throw new Error(
          'Proof-of-Print token hiányzik — nyomtatás nélkül az árfolyam nem igazolható vissza!',
        )
      }
      window.print()
      await exchangeRateMasterApi.acknowledgeDistribution(
        distributionId,
        obligation.printProofToken,
      )
      const dist = await exchangeRateMasterApi.getDistributionStatus(rateId)
      setDistData((prev) => ({ ...prev, [rateId]: dist }))
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setBusyDistributionId(null)
    }
  }

  const handlePublish = async (id: string) => {
    setBusyId(id)
    try {
      await exchangeRateMasterApi.publish(id)
      await loadRates()
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setBusyId(null)
    }
  }

  const handleRevoke = async (id: string) => {
    if (
      !confirm(
        'Biztosan visszavonod a publikált árfolyamot? A pénztárak a korábbira térnek vissza.',
      )
    )
      return
    setBusyId(id)
    try {
      await exchangeRateMasterApi.revoke(id)
      await loadRates()
    } catch (e) {
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setBusyId(null)
    }
  }

  const toggleDistribution = async (rateId: string) => {
    if (expandedDistId === rateId) {
      setExpandedDistId(null)
      return
    }
    setExpandedDistId(rateId)
    if (!distData[rateId]) {
      try {
        const dist = await exchangeRateMasterApi.getDistributionStatus(rateId)
        setDistData({ ...distData, [rateId]: dist })
      } catch (e) {
        logger.error('RateMasterWorkflowPage', 'dist err:', e)
      }
    }
  }

  return (
    <div className="max-w-7xl mx-auto space-y-2">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-lg font-bold text-slate-800">
            {t('rate-management.arfolyamPublikalas')}
          </h1>
          <p className="text-xs text-slate-600">
            {t('rate-management.foertektariWorkflowVazlatJovahagyasPublikalasPenztarakErtesitese')}
          </p>
        </div>
        <button
          type="button"
          onClick={() => void loadRates()}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          {t('common.refresh')}
        </button>
      </div>

      {err && (
        <div className="bg-red-50 border-l-4 border-red-600 p-4 rounded flex items-start gap-3">
          <AlertTriangle className="w-5 h-5 text-red-600 mt-0.5" />
          <div>
            <p className="text-red-800 font-medium">{t('common.error')}</p>
            <p className="text-sm text-red-700">{err}</p>
          </div>
        </div>
      )}

      <section className="rounded border border-slate-200 bg-white p-3">
        <div className="mb-2 flex items-center justify-between gap-3">
          <div>
            <h2 className="text-sm font-semibold text-slate-800">
              {i18n.t('literals.uj-torzsarfolyam-vazlat')}
            </h2>
            <p className="text-xs text-slate-500">
              {i18n.t('literals.kozponti-workflow-vazlat-letrehozasa-jov')}
            </p>
          </div>
          <button
            type="button"
            onClick={() => void handleCreateDraft()}
            disabled={creating}
            className="inline-flex items-center gap-2 rounded bg-slate-900 px-3 py-2 text-xs font-semibold text-white hover:bg-slate-800 disabled:opacity-50"
          >
            <Plus className="h-3.5 w-3.5" />
            {creating ? 'Létrehozás...' : 'Vázlat létrehozása'}
          </button>
        </div>
        <div className="grid gap-2 md:grid-cols-5">
          <label className="text-xs text-slate-600">
            {i18n.t('literals.valuta-id')}
            <input
              type="number"
              min="1"
              value={createForm.currencyId}
              onChange={(event) =>
                setCreateForm((prev) => ({ ...prev, currencyId: event.target.value }))
              }
              className="mt-1 h-9 w-full rounded border border-slate-300 px-2 text-sm"
              placeholder="1"
            />
          </label>
          <label className="text-xs text-slate-600">
            {i18n.t('literals.veteli-arfolyam')}
            <input
              type="text"
              inputMode="decimal"
              value={createForm.baseBuyRate}
              onChange={(event) =>
                setCreateForm((prev) => ({ ...prev, baseBuyRate: event.target.value }))
              }
              className="mt-1 h-9 w-full rounded border border-slate-300 px-2 text-sm"
              placeholder="390,50"
            />
          </label>
          <label className="text-xs text-slate-600">
            {i18n.t('literals.eladasi-arfolyam')}
            <input
              type="text"
              inputMode="decimal"
              value={createForm.baseSellRate}
              onChange={(event) =>
                setCreateForm((prev) => ({ ...prev, baseSellRate: event.target.value }))
              }
              className="mt-1 h-9 w-full rounded border border-slate-300 px-2 text-sm"
              placeholder="399,50"
            />
          </label>
          <label className="text-xs text-slate-600">
            {i18n.t('literals.mnb-arfolyam')}
            <input
              type="text"
              inputMode="decimal"
              value={createForm.officialRate}
              onChange={(event) =>
                setCreateForm((prev) => ({ ...prev, officialRate: event.target.value }))
              }
              className="mt-1 h-9 w-full rounded border border-slate-300 px-2 text-sm"
              placeholder="394,00"
            />
          </label>
          <label className="text-xs text-slate-600">
            {i18n.t('literals.megjegyzes')}
            <input
              type="text"
              value={createForm.notes}
              onChange={(event) =>
                setCreateForm((prev) => ({ ...prev, notes: event.target.value }))
              }
              className="mt-1 h-9 w-full rounded border border-slate-300 px-2 text-sm"
              placeholder="Opció"
            />
          </label>
        </div>
      </section>

      {/* Tabs */}
      <div className="flex gap-2 border-b border-slate-200">
        {(['DRAFT', 'APPROVED', 'PUBLISHED'] as const).map((tab) => (
          <button
            key={tab}
            type="button"
            onClick={() => setActiveTab(tab)}
            className={`px-6 py-3 font-medium transition border-b-2 ${
              activeTab === tab
                ? 'border-blue-600 text-blue-700'
                : 'border-transparent text-slate-600 hover:text-slate-800'
            }`}
          >
            {STATUS_LABELS[tab]}{' '}
            {rates.length > 0 && activeTab === tab && (
              <span className="ml-2 text-xs bg-slate-200 rounded-full px-2 py-0.5">
                {rates.length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {loading && rates.length === 0 && (
        <div className="text-center text-slate-500 py-12">{i18n.t('literals.betoltes')}</div>
      )}

      {!loading && rates.length === 0 && (
        <div className="text-center text-slate-400 py-16">
          <FileText className="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p className="text-lg">
            {t('rate-management.nincs')}
            {STATUS_LABELS[activeTab].toLowerCase()} {t('rate-management.arfolyam')}
          </p>
          {activeTab === 'DRAFT' && (
            <p className="text-sm mt-1">{t('rate-management.ujArfolyamotAzArfolyamKeszites')}</p>
          )}
        </div>
      )}

      {rates.length > 0 && (
        <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr className="text-left text-xs text-slate-600 uppercase">
                <th className="px-4 py-3">{t('common.deviza')}</th>
                <th className="px-4 py-3">{t('cashier.buy')}</th>
                <th className="px-4 py-3">{t('cashier.sell')}</th>
                <th className="px-4 py-3">{i18n.t('literals.mnb')}</th>
                <th className="px-4 py-3">{t('rate-management.limit1VE')}</th>
                <th className="px-4 py-3">{t('rate-management.limit2VE')}</th>
                <th className="px-4 py-3">{t('common.createdAt')}</th>
                <th className="px-4 py-3">{t('common.status')}</th>
                <th className="px-4 py-3 text-right">{t('common.operation')}</th>
              </tr>
            </thead>
            <tbody>
              {rates.map((r) => (
                <Fragment key={r.id}>
                  <tr className="border-t border-slate-100 hover:bg-slate-50">
                    <td className="px-4 py-3 font-mono font-bold">
                      {r.currencyCode || r.currencyId}
                    </td>
                    <td className="px-4 py-3 text-right font-mono">
                      {r.baseBuyRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })}
                    </td>
                    <td className="px-4 py-3 text-right font-mono">
                      {r.baseSellRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })}
                    </td>
                    <td className="px-4 py-3 text-right text-slate-500">
                      {r.officialRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 }) || '—'}
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-600">
                      {r.limit1Amount ? (
                        <>
                          <div>{r.limit1Amount?.toLocaleString('hu-HU')}</div>
                          <div className="text-slate-400">
                            {r.limit1BuyRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })}{' '}
                            {i18n.t('literals.lit-4')}{' '}
                            {r.limit1SellRate?.toLocaleString('hu-HU', {
                              maximumFractionDigits: 2,
                            })}
                          </div>
                        </>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-600">
                      {r.limit2Amount ? (
                        <>
                          <div>{r.limit2Amount?.toLocaleString('hu-HU')}</div>
                          <div className="text-slate-400">
                            {r.limit2BuyRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })}{' '}
                            {i18n.t('literals.lit-4')}{' '}
                            {r.limit2SellRate?.toLocaleString('hu-HU', {
                              maximumFractionDigits: 2,
                            })}
                          </div>
                        </>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-500">
                      <div className="flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {new Date(r.createdAt).toLocaleString('hu-HU')}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-block px-2 py-0.5 text-xs font-medium rounded border ${STATUS_COLORS[r.status]}`}
                      >
                        {STATUS_LABELS[r.status]}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      {activeTab === 'DRAFT' && (
                        <button
                          type="button"
                          onClick={() => void handleApprove(r.id)}
                          disabled={busyId === r.id}
                          className="inline-flex items-center gap-1 px-3 py-1.5 bg-blue-600 text-white rounded text-xs hover:bg-blue-700 disabled:opacity-50"
                        >
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          {busyId === r.id ? 'Folyamatban...' : 'Jóváhagy'}
                        </button>
                      )}
                      {activeTab === 'APPROVED' && (
                        <button
                          type="button"
                          onClick={() => void handlePublish(r.id)}
                          disabled={busyId === r.id}
                          className="inline-flex items-center gap-1 px-3 py-1.5 bg-green-600 text-white rounded text-xs hover:bg-green-700 disabled:opacity-50"
                        >
                          <Send className="w-3.5 h-3.5" />
                          {busyId === r.id ? 'Publikálás...' : 'Publikál'}
                        </button>
                      )}
                      {activeTab === 'PUBLISHED' && (
                        <div className="flex gap-1 justify-end">
                          <button
                            type="button"
                            onClick={() => void toggleDistribution(r.id)}
                            className="inline-flex items-center gap-1 px-3 py-1.5 bg-slate-100 text-slate-700 rounded text-xs hover:bg-slate-200"
                          >
                            <Users className="w-3.5 h-3.5" />
                            {expandedDistId === r.id ? 'Elrejt' : 'Elosztás'}
                          </button>
                          <button
                            type="button"
                            onClick={() => void handleRevoke(r.id)}
                            disabled={busyId === r.id}
                            className="inline-flex items-center gap-1 px-3 py-1.5 bg-red-50 text-red-700 rounded text-xs hover:bg-red-100 disabled:opacity-50"
                          >
                            <XCircle className="w-3.5 h-3.5" />
                            {t('rate-management.visszavon')}
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                  {expandedDistId === r.id &&
                    (() => {
                      const dists = distData[r.id]
                      return (
                        <tr key={r.id + '-dist'}>
                          <td colSpan={9} className="bg-slate-50 px-4 py-3">
                            <div className="text-xs font-medium text-slate-700 mb-2">
                              {t('rate-management.elosztasStatusz')}
                              {dists?.length ?? 0} {t('foertektar.penztar')}
                            </div>
                            {!dists && (
                              <div className="text-slate-500">{i18n.t('literals.betoltes')}</div>
                            )}
                            {dists && dists.length === 0 && (
                              <div className="text-slate-500">
                                {t('ratemanagement.nincsElosztasRekord')}
                              </div>
                            )}
                            {dists && dists.length > 0 && (
                              <div className="grid grid-cols-4 gap-2">
                                {dists.map((d) => {
                                  const pendingPrint = pendingPrintObligations[d.id]
                                  return (
                                    <div
                                      key={d.id}
                                      className={`text-xs p-2 rounded border ${
                                        d.status === 'ACKNOWLEDGED'
                                          ? 'bg-green-50 border-green-300 text-green-800'
                                          : d.status === 'DISTRIBUTED'
                                            ? 'bg-blue-50 border-blue-300 text-blue-800'
                                            : d.status === 'PENDING'
                                              ? 'bg-amber-50 border-amber-300 text-amber-800'
                                              : 'bg-red-50 border-red-300 text-red-800'
                                      }`}
                                    >
                                      <div className="font-mono font-bold">
                                        {d.branchCode || d.branchId.slice(0, 8)}
                                      </div>
                                      <div className="text-xs opacity-75">{d.branchName}</div>
                                      <div className="mt-1 text-xxs">{d.status}</div>
                                      {d.status !== 'ACKNOWLEDGED' && (
                                        <button
                                          type="button"
                                          onClick={() =>
                                            void handleAcknowledgeDistribution(r.id, d.id)
                                          }
                                          disabled={busyDistributionId === d.id}
                                          className="mt-2 w-full rounded bg-white/80 px-2 py-1 text-xs font-semibold text-slate-800 hover:bg-white disabled:opacity-50"
                                          data-testid={`exchange-rate-distribution-ack-${d.id}`}
                                        >
                                          <Printer className="mr-1 inline h-3 w-3" />
                                          {busyDistributionId === d.id
                                            ? 'Folyamatban...'
                                            : 'Nyomtatás + lefűzés visszaigazolása'}
                                        </button>
                                      )}
                                      {d.status === 'ACKNOWLEDGED' && (
                                        <div className="mt-1 text-xxs opacity-80">
                                          {d.printedAt
                                            ? `Nyomtatva: ${new Date(d.printedAt).toLocaleString('hu-HU')}`
                                            : 'Nyomtatás visszaigazolva'}
                                          {d.printedBy ? ` · dolgozó: ${d.printedBy}` : ''}
                                        </div>
                                      )}
                                      {pendingPrint && (
                                        <div className="hidden print:block">
                                          <h2>{i18n.t('literals.arfolyamvaltozas')}</h2>
                                          <p>
                                            {pendingPrint.currencyCode}
                                            {i18n.t('literals.v-4')}
                                            {pendingPrint.versionNumber}
                                          </p>
                                          <p>
                                            {i18n.t('literals.vetel-2')}
                                            {pendingPrint.baseBuyRate}
                                            {i18n.t('literals.eladas-4')}{' '}
                                            {pendingPrint.baseSellRate}
                                          </p>
                                          <p>
                                            {i18n.t('literals.peldany-lefuzendo-pmt-mnb-eloiras')}
                                          </p>
                                        </div>
                                      )}
                                    </div>
                                  )
                                })}
                              </div>
                            )}
                          </td>
                        </tr>
                      )
                    })()}
                </Fragment>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
