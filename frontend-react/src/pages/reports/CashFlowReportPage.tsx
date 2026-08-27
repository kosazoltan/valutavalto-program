import { useState, useCallback, useEffect } from 'react'
import { Printer, Calendar, RefreshCw, AlertTriangle } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { cashFlowReportApi, type CashFlowReport } from '../../services/api/settings'
import i18n from '../../i18n'

/**
 * FKH-030: Pénzforgalom riport.
 *
 * <p>A Bank/Terület/Pénztár felé irányuló pénzmozgások bizonylatonkénti listája
 * tetszőleges dátumtartományra. A terület-szűrést a BACKEND végzi (FR-9) — a kliens
 * csak a tartományt küldi.</p>
 */
const COMPANY_HEADER = 'Exclusive Best Change Zrt.'

/** NFR-5: 1 évnél hosszabb tartománynál a UI figyelmeztet (a backend el is utasítja). */
const MAX_RANGE_DAYS = 366

/** A folyó hónap első napja — FR-2 alapértelmezett TŐL érték. */
function firstDayOfCurrentMonth(): string {
  const now = new Date()
  return localIsoDate(new Date(now.getFullYear(), now.getMonth(), 1))
}

function daysBetween(from: string, to: string): number {
  const a = new Date(from).getTime()
  const b = new Date(to).getTime()
  if (Number.isNaN(a) || Number.isNaN(b)) return 0
  return Math.round((b - a) / 86_400_000)
}

function formatAmount(value: number | null): string {
  if (value === null || value === undefined) return ''
  return value.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

export default function CashFlowReportPage() {
  const [from, setFrom] = useState<string>(firstDayOfCurrentMonth())
  const [to, setTo] = useState<string>(localIsoDate(new Date()))
  const [data, setData] = useState<CashFlowReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const rangeTooLong = daysBetween(from, to) > MAX_RANGE_DAYS
  const rangeInverted = !!from && !!to && new Date(to) < new Date(from)

  const load = useCallback(async () => {
    if (rangeInverted) {
      setError('Az IG dátum nem lehet korábbi, mint a TŐL dátum.')
      return
    }
    setLoading(true)
    setError(null)
    try {
      const result = await cashFlowReportApi.get(from, to)
      setData(result)
      // FK-075 minta: a sikeres frissítés TÖRLI a korábbi hibaüzenetet, különben
      // friss adat mellett állna egy elavult hiba.
      setError(null)
    } catch (e) {
      const message = getErrorMessage(e)
      logger.error('CashFlowReport', 'Pénzforgalom riport betöltése sikertelen', e)
      setError(message)
      toast.error(message)
    } finally {
      setLoading(false)
    }
  }, [from, to, rangeInverted])

  useEffect(() => {
    void load()
    // Csak induláskor töltünk automatikusan; utána a felhasználó frissít.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const rows = data?.rows ?? []

  return (
    <div className="p-4 space-y-4">
      {/* Nyomtatási fejléc — képernyőn rejtve, nyomtatásban látszik */}
      <div className="hidden print:block text-center mb-4">
        <h1 className="text-lg font-bold">{COMPANY_HEADER}</h1>
        <h2 className="text-base">{i18n.t('literals.penzforgalom-riport')}</h2>
        <p className="text-sm">
          {i18n.t('literals.idoszak-2')}
          {data?.from ?? from}
          {i18n.t('literals.lit-32')}
          {data?.to ?? to}
        </p>
      </div>

      <div className="no-print flex flex-wrap items-end gap-3">
        <h1 className="text-xl font-semibold mr-auto">{i18n.t('literals.penzforgalom-riport')}</h1>
        <button
          type="button"
          onClick={() => window.print()}
          disabled={rows.length === 0}
          className="flex items-center gap-2 rounded bg-gray-100 px-3 py-2 hover:bg-gray-200 disabled:opacity-50"
        >
          <Printer size={16} />
          {i18n.t('literals.nyomtatas-2')}
        </button>
      </div>

      <div className="no-print flex flex-wrap items-end gap-3 rounded-lg border bg-white p-3 dark:bg-gray-800">
        <label className="flex flex-col text-sm">
          <span className="mb-1 flex items-center gap-1 text-gray-600">
            <Calendar size={14} />
            {i18n.t('literals.tol-2')}
          </span>
          <input
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="rounded border px-2 py-1"
          />
        </label>
        <label className="flex flex-col text-sm">
          <span className="mb-1 flex items-center gap-1 text-gray-600">
            <Calendar size={14} />
            {i18n.t('literals.ig-2')}
          </span>
          <input
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="rounded border px-2 py-1"
          />
        </label>
        <button
          type="button"
          onClick={() => void load()}
          disabled={loading || rangeInverted}
          className="flex items-center gap-2 rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          {i18n.t('literals.lekerdezes-2')}
        </button>
      </div>

      {rangeTooLong && (
        <div className="no-print flex items-center gap-2 rounded border border-amber-300 bg-amber-50 p-2 text-sm text-amber-800">
          <AlertTriangle size={16} />
          {i18n.t('literals.az-idoszak-hosszabb-1-evnel-a-lekerdezes')}
        </div>
      )}

      {error && (
        <div className="no-print rounded border border-red-300 bg-red-50 p-2 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="overflow-x-auto rounded-lg border bg-white dark:bg-gray-800">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-left dark:bg-gray-700">
            <tr>
              <th className="px-2 py-2">{i18n.t('literals.datum-2')}</th>
              <th className="px-2 py-2">{i18n.t('literals.bizonylatszam-2')}</th>
              <th className="px-2 py-2">{i18n.t('literals.partner')}</th>
              <th className="px-2 py-2">{i18n.t('literals.valuta')}</th>
              <th className="px-2 py-2 text-right">{i18n.t('literals.atvett-osszeg')}</th>
              <th className="px-2 py-2 text-right">{i18n.t('literals.atadott-osszeg')}</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && !loading && (
              <tr>
                <td colSpan={6} className="px-2 py-4 text-center text-gray-500">
                  {i18n.t('literals.nincs-tetel-a-megadott-idoszakban')}
                </td>
              </tr>
            )}
            {rows.map((row, idx) => (
              <tr
                key={`${row.receiptNumber}-${row.currency ?? ''}-${idx}`}
                className={row.storno ? 'text-red-600 line-through' : ''}
              >
                <td className="px-2 py-1">{row.date}</td>
                <td className="px-2 py-1">{row.receiptNumber}</td>
                <td className="px-2 py-1">
                  {row.partnerCode ?? '—'}
                  <span className="ml-1 text-xs text-gray-500">
                    {i18n.t('literals.lit-19')}
                    {row.partnerCategory}
                    {i18n.t('literals.lit-2')}
                  </span>
                </td>
                <td className="px-2 py-1">{row.currency ?? ''}</td>
                <td className="px-2 py-1 text-right">{formatAmount(row.receivedAmount)}</td>
                <td className="px-2 py-1 text-right">{formatAmount(row.handedOverAmount)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <p className="no-print text-xs text-gray-500">
        {rows.length}
        {i18n.t('literals.tetel-a-lista-a-sajat-korzetehez-tartozo')}
      </p>
    </div>
  )
}
