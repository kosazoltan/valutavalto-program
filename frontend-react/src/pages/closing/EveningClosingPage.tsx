import { useState, useCallback, useEffect } from 'react'
import { Link } from 'react-router-dom'
import {
  Moon,
  Calendar,
  Package,
  Send,
  Eye,
  CheckCircle,
  AlertTriangle,
  Clock,
  Printer,
  BarChart3,
} from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { useAuthStore } from '../../stores/authStore'
import { closingWizardApi, eveningClosingApi } from '../../services/api/index'
import { useTranslation } from 'react-i18next'
import VaultClosingChecklistPanel from '../../components/closing/VaultClosingChecklistPanel'
import type { ClosingWizardStatus } from '../../services/api/transactions'

/**
 * FKH-036 FR-1: a backend DailyDataPackage kibővített alakja. A JsonInclude.NON_NULL
 * miatt MINDEN új mező OPCIONÁLIS — a backend null mezőket egyáltalán nem küldi, és a
 * WU-1 előtti (legacy) válaszban ezek a mezők eleve hiányoznak. Az oldal ezért minden
 * olvasást null-biztosan végez.
 */
interface EveningClosingPreview {
  branchId: string
  branchName?: string
  date?: string
  status?: 'NOT_STARTED' | 'PREVIEW' | 'SENT' | 'CONFIRMED'
  balances?: Array<{
    currency: string
    amount: number
    denominationBreakdown?: Array<{ denomination: number; count: number }>
  }>
  transactionCount?: number
  totalBuyHuf?: number
  totalSellHuf?: number
  pendingSyncs?: number
  openReservations?: number
  warnings?: string[]
  packages?: Array<{
    packageId: string
    currency: string
    amount: number
    sealNumber?: string
    destination: string
  }>
}

interface EveningClosingReport {
  branchId: number
  date: string
  totalTransactionCount: number
  buyCount: number
  sellCount: number
  reversalCount: number
  conversionCount: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFees: number
  netTurnover: number
  currencyBreakdown: Record<string, number>
}

export default function EveningClosingPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''
  const [date, setDate] = useState(localIsoDate())
  const [preview, setPreview] = useState<EveningClosingPreview | null>(null)
  const [report, setReport] = useState<EveningClosingReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [reportLoading, setReportLoading] = useState(false)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [closingStatus, setClosingStatus] = useState<ClosingWizardStatus | null>(null)

  const loadPreview = useCallback(async () => {
    if (!branchId) {
      toast.warning('Fiók szükséges')
      return
    }
    try {
      setLoading(true)
      setError(null)
      const [data, status] = await Promise.all([
        eveningClosingApi.preview(branchId, date),
        closingWizardApi.getStatus(date).catch(() => null),
      ])
      setPreview(data as EveningClosingPreview)
      setClosingStatus(status)
    } catch (err) {
      logger.error('EveningClosingPage', 'Előnézet hiba:', err)
      setError(getErrorMessage(err))
      setPreview(null)
      setClosingStatus(null)
    } finally {
      setLoading(false)
    }
  }, [branchId, date])

  // FKH-036 FR-2: automatikus betöltés mountkor és dátumváltáskor (a loadPreview
  // useCallback [branchId, date] függőségei miatt). A StrictMode dupla-effekt a dev
  // buildben két idempotens, írás-mentes GET-et jelent — elfogadott (terv 13. pitfall).
  useEffect(() => {
    void loadPreview()
  }, [loadPreview])

  const loadReport = useCallback(async () => {
    if (!branchId) {
      toast.warning('Fiók szükséges')
      return
    }
    try {
      setReportLoading(true)
      setError(null)
      const data = await eveningClosingApi.report(branchId, date)
      setReport(data as EveningClosingReport)
    } catch (err) {
      logger.error('EveningClosingPage', 'Napi jelentés hiba:', err)
      setError(getErrorMessage(err))
      setReport(null)
    } finally {
      setReportLoading(false)
    }
  }, [branchId, date])

  const handleSend = async () => {
    if (!branchId || !preview) return
    if (closingStatus?.vaultContext && !closingStatus.exactMatch) {
      toast.warning('Címletezés szükséges', closingStatus.message)
      return
    }
    // FKH-036 FR-1: a warnings opcionális (JsonInclude.NON_NULL) — null-biztos olvasás.
    const warnings = preview.warnings ?? []
    if (
      warnings.length > 0 &&
      !confirm(`${warnings.length} figyelmeztetés van. Biztosan elküldi az esti zárást?`)
    )
      return
    try {
      setSending(true)
      setError(null)
      await eveningClosingApi.send(branchId, date)
      toast.success('Esti zárás elküldve')
      await loadPreview()
    } catch (err) {
      setError(getErrorMessage(err))
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setSending(false)
    }
  }

  const fmtNum = (n: number) =>
    n.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  const fmtHuf = (n: number) => n.toLocaleString('hu-HU', { minimumFractionDigits: 0 }) + ' Ft'

  const handlePrint = () => window.print()

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Moon />
          {t('closing.estiZarasCsomagkeszites')}
        </h1>
        <div className="no-print flex gap-2">
          {preview && (
            <button onClick={handlePrint} className="form-button">
              <Printer size={16} /> {t('common.print')}
            </button>
          )}
          {preview && preview.status !== 'SENT' && preview.status !== 'CONFIRMED' && (
            <button
              onClick={handleSend}
              disabled={sending || Boolean(closingStatus?.vaultContext && !closingStatus.exactMatch)}
              className="form-button-primary"
            >
              <Send size={16} /> {sending ? 'Küldés...' : 'Esti zárás küldése'}
            </button>
          )}
        </div>
      </div>

      {/* Dátum */}
      <div className="no-print form-panel flex gap-3 items-end">
        <div>
          <label className="form-label">{t('common.date')}</label>
          <div className="flex items-center gap-1">
            <Calendar size={16} className="text-gray-400" />
            <input
              className="form-input"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>
        </div>
        <button
          onClick={() => void loadPreview()}
          disabled={loading}
          className="form-button-primary"
        >
          <Eye size={16} /> {loading ? 'Betöltés...' : 'Előnézet'}
        </button>
        <button onClick={() => void loadReport()} disabled={reportLoading} className="form-button">
          <BarChart3 size={16} /> {reportLoading ? 'Betöltés...' : 'Napi jelentés'}
        </button>
      </div>

      {/* FKH-036 FR-3/FR-8: becímletező CTA-szekció — a checklist ELŐTT, nem blokkoló. */}
      {closingStatus?.vaultContext && (
        <div data-testid="fkh036-denomination-cta" className="form-panel space-y-2">
          <h2 className="font-semibold">Becímletezés</h2>
          <div className="text-sm">
            {closingStatus.denominationRecorded
              ? closingStatus.exactMatch
                ? 'A becímletezés egyezik a nyilvántartással.'
                : closingStatus.message
              : 'Erre a napra még nincs rögzített esti címletezés.'}
          </div>
          {(closingStatus.requiredCurrencies?.length ?? 0) > 0 && (
            <div className="text-sm" data-testid="fkh036-required-currencies">
              Kötelezően becímletezendő: {closingStatus.requiredCurrencies!.join(', ')}
            </div>
          )}
          <div className="flex gap-2">
            <Link
              to={`/closing/denomination-entry/EVENING?returnTo=${encodeURIComponent('/evening-closing')}`}
              className="form-button-primary"
            >
              Esti zárás címletezése
            </Link>
            {closingStatus.handlingFeeRequired && (
              <Link
                to={`/closing/denomination-entry/HANDLING_FEE?returnTo=${encodeURIComponent('/evening-closing')}`}
                className="form-button"
              >
                Kezelési díj címletezése
              </Link>
            )}
          </div>
        </div>
      )}

      {/* FR-ZARUI-16..26: Értéktári zárás-előtti ellenőrzőlista — kísérő kontroll, nem blokkoló gate */}
      <VaultClosingChecklistPanel date={date} />

      {closingStatus?.vaultContext && !closingStatus.exactMatch && (
        <div className="bg-amber-50 border border-amber-200 text-amber-900 px-4 py-3 rounded">
          {closingStatus.message}
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {report && (
        <div className="form-panel" data-testid="evening-closing-report-panel">
          <h2 className="font-semibold mb-3 flex items-center gap-1">
            <BarChart3 size={16} />
            Napi jelentés
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
            <div className="text-center rounded bg-gray-50 p-2">
              <div className="text-lg font-bold">{report.totalTransactionCount}</div>
              <div className="text-xs text-gray-500">Tranzakció</div>
            </div>
            <div className="text-center rounded bg-green-50 p-2">
              <div className="text-lg font-bold text-green-700">{fmtHuf(report.totalBuyHuf)}</div>
              <div className="text-xs text-gray-500">Vétel</div>
            </div>
            <div className="text-center rounded bg-blue-50 p-2">
              <div className="text-lg font-bold text-blue-700">{fmtHuf(report.totalSellHuf)}</div>
              <div className="text-xs text-gray-500">Eladás</div>
            </div>
            <div className="text-center rounded bg-orange-50 p-2">
              <div className="text-lg font-bold text-orange-700">
                {fmtHuf(report.totalHandlingFees)}
              </div>
              <div className="text-xs text-gray-500">Kezelési díj</div>
            </div>
            <div className="text-center rounded bg-purple-50 p-2">
              <div className="text-lg font-bold text-purple-700">{fmtHuf(report.netTurnover)}</div>
              <div className="text-xs text-gray-500">Nettó</div>
            </div>
          </div>
          <div className="mt-3 grid grid-cols-2 md:grid-cols-4 gap-2">
            {Object.entries(report.currencyBreakdown || {}).map(([currency, hufAmount]) => (
              <div key={currency} className="rounded border border-gray-200 p-2 text-sm">
                <div className="font-mono font-bold">{currency}</div>
                <div className="font-mono">{fmtHuf(hufAmount)}</div>
              </div>
            ))}
          </div>
          <div className="mt-3 text-xs text-gray-500">
            Vétel: {report.buyCount} | Eladás: {report.sellCount} | Sztornó: {report.reversalCount}{' '}
            | Konverzió: {report.conversionCount}
          </div>
        </div>
      )}

      {preview && (
        <>
          {/* Státusz */}
          <div className="flex gap-3 items-center">
            <span
              className={`badge ${
                preview.status === 'CONFIRMED'
                  ? 'badge-green'
                  : preview.status === 'SENT'
                    ? 'badge-blue'
                    : preview.status === 'PREVIEW'
                      ? 'badge-yellow'
                      : 'badge-gray'
              }`}
            >
              {preview.status === 'CONFIRMED' ? (
                <>
                  <CheckCircle size={10} className="inline" /> {t('closing.jovahagyva')}
                </>
              ) : preview.status === 'SENT' ? (
                <>
                  <Send size={10} className="inline" /> {t('closing.elkuldve')}
                </>
              ) : preview.status === 'PREVIEW' ? (
                <>
                  <Eye size={10} className="inline" /> {t('closing.elonezet')}
                </>
              ) : (
                <>
                  <Clock size={10} className="inline" /> {t('closing.nemIndult')}
                </>
              )}
            </span>
            <span className="text-sm text-gray-500">
              {preview.branchName} — {preview.date}
            </span>
          </div>

          {/* Figyelmeztetések */}
          {(preview.warnings ?? []).length > 0 && (
            <div className="bg-yellow-50 border border-yellow-200 rounded p-3 space-y-1">
              <div className="font-semibold flex items-center gap-1 text-yellow-700">
                <AlertTriangle size={16} />
                {t('closing.figyelmeztetesek')}
              </div>
              {(preview.warnings ?? []).map((w) => (
                <div key={w} className="text-sm text-yellow-600">
                  • {w}
                </div>
              ))}
            </div>
          )}

          {/* Összefoglaló */}
          <div className="grid grid-cols-4 gap-3">
            <div className="form-panel text-center">
              <div className="text-lg font-bold">{preview.transactionCount ?? 0}</div>
              <div className="text-sm text-gray-500">{t('closing.tranzakcio')}</div>
            </div>
            <div className="form-panel text-center bg-green-50">
              <div className="text-lg font-bold text-green-700">
                {fmtHuf(preview.totalBuyHuf ?? 0)}
              </div>
              <div className="text-sm text-gray-500">{t('misc.vetelHuf')}</div>
            </div>
            <div className="form-panel text-center bg-blue-50">
              <div className="text-lg font-bold text-blue-700">
                {fmtHuf(preview.totalSellHuf ?? 0)}
              </div>
              <div className="text-sm text-gray-500">{t('misc.eladasHuf')}</div>
            </div>
            <div className="form-panel text-center">
              <div className="text-lg font-bold text-orange-600">{preview.pendingSyncs ?? 0}</div>
              <div className="text-sm text-gray-500">{t('closing.szinkronVaro')}</div>
            </div>
          </div>

          {/* Készletek */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2">{t('closing.zaroKeszlet')}</h2>
            <div className="grid grid-cols-6 gap-2">
              {(preview.balances || []).map((b) => (
                <div key={b.currency} className="text-center p-2 bg-gray-50 rounded">
                  <div className="font-mono text-sm font-bold">{b.currency}</div>
                  <div className="text-sm">{fmtNum(b.amount)}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Csomagok */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2 flex items-center gap-1">
              <Package size={16} />
              {t('closing.keszitettCsomagok')}
            </h2>
            {(preview.packages || []).length === 0 ? (
              <div className="text-center text-gray-500 py-4">{t('closing.nincsCsomag')}</div>
            ) : (
              <table className="data-grid w-full">
                <thead>
                  <tr>
                    <th>{t('closing.csomagId')}</th>
                    <th>{t('common.deviza')}</th>
                    <th className="text-right">{t('common.amount')}</th>
                    <th>{t('closing.plombaszam')}</th>
                    <th>{t('closing.cel')}</th>
                  </tr>
                </thead>
                <tbody>
                  {(preview.packages ?? []).map((p) => (
                    <tr key={p.packageId}>
                      <td className="font-mono text-sm">{p.packageId}</td>
                      <td className="font-mono">{p.currency}</td>
                      <td className="text-right font-mono">{fmtNum(p.amount)}</td>
                      <td className="font-mono text-sm">{p.sealNumber || '-'}</td>
                      <td>{p.destination}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </>
      )}
    </div>
  )
}
