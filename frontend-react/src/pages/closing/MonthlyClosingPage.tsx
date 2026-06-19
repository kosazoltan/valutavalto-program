import { useState, useEffect, useCallback } from 'react'
import { ArrowDownToLine, ArrowUpFromLine, Calendar, Search, RefreshCw, AlertTriangle, Printer, Download, CheckCircle, Trash2 } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api, hrkDailyApi, hrkMonthlyApi, monthlyClosingApi, type HrkMonthlySummary, type HrkTransaction } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'

interface MonthlyClosingSummaryItem {
  id: string | number
  yearMonth?: string
  branchName?: string
  status?: string
  closedAt?: string
  closedByName?: string
}

const currentYearMonth = (): string => new Date().toISOString().slice(0, 7)
const currentDate = (): string => new Date().toISOString().slice(0, 10)
const formatHuf = (value: number | string | null | undefined): string => {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').replace(',', '.'))
  return Number.isFinite(parsed) ? `${parsed.toLocaleString('hu-HU', { maximumFractionDigits: 0 })} Ft` : '-'
}
const formatAmount = (value: number | string | null | undefined): string => {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').replace(',', '.'))
  return Number.isFinite(parsed) ? parsed.toLocaleString('hu-HU', { maximumFractionDigits: 2 }) : '-'
}
const formatDateTime = (value?: string | null): string => value ? value.replace('T', ' ').slice(0, 16) : '-'
const parsePositiveAmount = (value: string): number | null => {
  const parsed = Number(value.replace(/\s/g, '').replace(',', '.'))
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null
}

export default function MonthlyClosingPage() {
  const { t } = useTranslation()
  // 2026-04-29 B35 fix: a backend /closing/monthly endpoint csak {branchId}-os
  // GET-eket implemental, root-level lista nincs. A current worker branch-et
  // hasznaljuk a multi-tenant biztonsag tiszteletben tartasaval.
  const branchId = useAuthStore((state) => state.worker?.branchId)
  const [items, setItems] = useState<MonthlyClosingSummaryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [hrkYearMonth, setHrkYearMonth] = useState(currentYearMonth)
  const [hrkSummary, setHrkSummary] = useState<HrkMonthlySummary | null>(null)
  const [hrkLoading, setHrkLoading] = useState(false)
  const [hrkClosing, setHrkClosing] = useState(false)
  const [hrkError, setHrkError] = useState<string | null>(null)
  const [hrkDailyDate, setHrkDailyDate] = useState(currentDate)
  const [hrkJournal, setHrkJournal] = useState<HrkTransaction[]>([])
  const [hrkDailyRows, setHrkDailyRows] = useState<HrkTransaction[]>([])
  const [hrkDailyLoading, setHrkDailyLoading] = useState(false)
  const [hrkDailyClosing, setHrkDailyClosing] = useState(false)
  const [hrkDailyError, setHrkDailyError] = useState<string | null>(null)
  const [hrkMovementType, setHrkMovementType] = useState<'HANDOVER' | 'RECEIVE'>('HANDOVER')
  const [hrkCurrencyCode, setHrkCurrencyCode] = useState('')
  const [hrkAmount, setHrkAmount] = useState('')
  const [hrkHufAmount, setHrkHufAmount] = useState('')
  const [hrkBankAccountNumber, setHrkBankAccountNumber] = useState('')
  const [hrkNote, setHrkNote] = useState('')
  const [hrkMovementSaving, setHrkMovementSaving] = useState(false)
  const [hrkCancellingId, setHrkCancellingId] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    if (!branchId) {
      setError(t('monthlyClose.branchRequired'))
      setLoading(false)
      return
    }
    try {
      setLoading(true)
      setError(null)
      const data = await monthlyClosingApi.getAllClosedMonths(branchId)
      setItems(safeArray<typeof items[0]>(data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [branchId, t])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const loadHrkSummary = useCallback(async () => {
    try {
      setHrkLoading(true)
      setHrkError(null)
      setHrkSummary(await hrkMonthlyApi.getSummary(hrkYearMonth))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'HRK havi összesítő hiba:', err)
      setHrkSummary(null)
      setHrkError(msg)
    } finally {
      setHrkLoading(false)
    }
  }, [hrkYearMonth])

  useEffect(() => {
    void loadHrkSummary()
  }, [loadHrkSummary])

  const loadHrkJournal = useCallback(async () => {
    if (!branchId) {
      setHrkDailyError(t('monthlyClose.branchRequired'))
      return
    }
    try {
      setHrkDailyLoading(true)
      setHrkDailyError(null)
      setHrkJournal(await hrkDailyApi.getJournal(branchId))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'HRK napi napló hiba:', err)
      setHrkJournal([])
      setHrkDailyError(msg)
    } finally {
      setHrkDailyLoading(false)
    }
  }, [branchId, t])

  useEffect(() => {
    void loadHrkJournal()
  }, [loadHrkJournal])

  const filtered = items.filter(item => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some(v =>
      v != null && String(v).toLowerCase().includes(term)
    )
  })

  const downloadMonthlyPdf = async (yearMonth?: string) => {
    if (!branchId || !yearMonth) return
    try {
      const response = await api.get<Blob>(`/closing/monthly/${branchId}/${yearMonth}/pdf`, { responseType: 'blob' })
      const url = URL.createObjectURL(response.data)
      const link = document.createElement('a')
      link.href = url
      link.download = `havi-zaras-${yearMonth}.pdf`
      document.body.appendChild(link)
      link.click()
      link.remove()
      URL.revokeObjectURL(url)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'PDF letöltési hiba:', err)
      setError(msg)
    }
  }

  const closeHrkMonth = async () => {
    if (!window.confirm(`Biztosan lezárja a HRK havi összesítőt erre a hónapra: ${hrkYearMonth}?`)) {
      return
    }
    try {
      setHrkClosing(true)
      setHrkError(null)
      setHrkSummary(await hrkMonthlyApi.close(hrkYearMonth))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'HRK havi zárás hiba:', err)
      setHrkError(msg)
    } finally {
      setHrkClosing(false)
    }
  }

  const closeHrkDaily = async () => {
    if (!branchId) {
      setHrkDailyError(t('monthlyClose.branchRequired'))
      return
    }
    if (!window.confirm(`Biztosan elkészíti a HRK napi zárást erre a napra: ${hrkDailyDate}?`)) {
      return
    }
    try {
      setHrkDailyClosing(true)
      setHrkDailyError(null)
      const rows = await hrkDailyApi.closeDaily(branchId, hrkDailyDate)
      setHrkDailyRows(rows)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'HRK napi zárás hiba:', err)
      setHrkDailyError(msg)
    } finally {
      setHrkDailyClosing(false)
    }
  }

  const saveHrkMovement = async () => {
    if (!branchId) {
      setHrkDailyError(t('monthlyClose.branchRequired'))
      return
    }

    const currencyCode = hrkCurrencyCode.trim().toUpperCase()
    const amount = parsePositiveAmount(hrkAmount)
    const hufAmount = parsePositiveAmount(hrkHufAmount)
    if (!currencyCode || amount == null || hufAmount == null) {
      setHrkDailyError('HRK rögzítéshez valuta, pozitív összeg és pozitív HUF összeg szükséges.')
      return
    }

    const label = hrkMovementType === 'HANDOVER' ? 'pénztár-bank átadás' : 'bank-pénztár átvétel'
    if (!window.confirm(`Biztosan rögzíti a HRK ${label} műveletet?`)) {
      return
    }

    try {
      setHrkMovementSaving(true)
      setHrkDailyError(null)
      const payload = {
        currencyCode,
        amount,
        hufAmount,
        bankAccountNumber: hrkBankAccountNumber.trim() || undefined,
        note: hrkNote.trim() || undefined,
      }
      if (hrkMovementType === 'HANDOVER') {
        await hrkDailyApi.handover(branchId, payload)
      } else {
        await hrkDailyApi.receive(branchId, payload)
      }
      setHrkCurrencyCode('')
      setHrkAmount('')
      setHrkHufAmount('')
      setHrkBankAccountNumber('')
      setHrkNote('')
      await Promise.all([loadHrkJournal(), loadHrkSummary()])
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'HRK napi mozgás rögzítési hiba:', err)
      setHrkDailyError(msg)
    } finally {
      setHrkMovementSaving(false)
    }
  }

  const cancelHrkMovement = async (row: HrkTransaction) => {
    if (!row.id || row.status !== 'PENDING') return
    if (!window.confirm(`Biztosan törli a HRK tételt: ${row.reference ?? row.id}?`)) {
      return
    }

    try {
      setHrkCancellingId(row.id)
      setHrkDailyError(null)
      await hrkDailyApi.cancel(row.id)
      await Promise.all([loadHrkJournal(), loadHrkSummary()])
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('MonthlyClosingPage', 'HRK napi mozgás törlési hiba:', err)
      setHrkDailyError(msg)
    } finally {
      setHrkCancellingId(null)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Calendar className="h-6 w-6" />
          {t('monthlyClose.title')}
        </h1>
        <div className="no-print flex items-center gap-2">
          <button onClick={() => window.print()} className="form-button" title={t('common.print')}>
            <Printer className="h-4 w-4" /> {t('common.print')}
          </button>
          <button onClick={() => void loadData()} className="form-button p-2" title={t('common.refresh')}>
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="no-print flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder={t('common.searchPlaceholder')}
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      <section className="rounded-lg border border-gray-200 bg-white p-4" data-testid="hrk-monthly-panel">
        <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div>
            <h2 className="text-base font-bold text-gray-900">HRK havi készletmozgás</h2>
            <p className="mt-1 text-sm text-gray-500">Pénztár-bank átadás/átvétel havi összesítője.</p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end">
            <div>
              <label htmlFor="hrk-year-month" className="form-label">HRK hónap</label>
              <input
                id="hrk-year-month"
                type="month"
                value={hrkYearMonth}
                onChange={(event) => setHrkYearMonth(event.target.value)}
                className="form-input"
              />
            </div>
            <button
              type="button"
              onClick={() => void loadHrkSummary()}
              disabled={hrkLoading}
              className="form-button inline-flex items-center gap-2"
            >
              <RefreshCw className={`h-4 w-4 ${hrkLoading ? 'animate-spin' : ''}`} />
              HRK frissítés
            </button>
            <button
              type="button"
              onClick={() => void closeHrkMonth()}
              disabled={hrkClosing || !hrkSummary}
              className="form-button-primary inline-flex items-center gap-2"
            >
              <CheckCircle className="h-4 w-4" />
              {hrkClosing ? 'HRK zárás...' : 'HRK havi zárás'}
            </button>
          </div>
        </div>

        {hrkError && (
          <div className="form-error mt-3 flex items-center gap-2">
            <AlertTriangle className="h-4 w-4" />
            {hrkError}
          </div>
        )}

        <div className="mt-4 grid grid-cols-2 gap-2 md:grid-cols-4">
          <div className="rounded-md bg-gray-50 p-3">
            <div className="text-xs text-gray-500">Tranzakció</div>
            <div className="mt-1 text-lg font-bold">{hrkSummary?.totalTransactions ?? 0}</div>
          </div>
          <div className="rounded-md bg-gray-50 p-3">
            <div className="text-xs text-gray-500">Átadás HUF</div>
            <div className="mt-1 text-lg font-bold">{formatHuf(hrkSummary?.totalHandoverHuf)}</div>
          </div>
          <div className="rounded-md bg-gray-50 p-3">
            <div className="text-xs text-gray-500">Átvétel HUF</div>
            <div className="mt-1 text-lg font-bold">{formatHuf(hrkSummary?.totalReceiveHuf)}</div>
          </div>
          <div className="rounded-md bg-gray-50 p-3">
            <div className="text-xs text-gray-500">Nettó HUF</div>
            <div className="mt-1 text-lg font-bold">{formatHuf(hrkSummary?.netHuf)}</div>
          </div>
        </div>

        <div className="mt-4 overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Valuta</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Átadás db</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Átadás HUF</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Átvétel db</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Átvétel HUF</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Nettó</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {hrkLoading ? (
                <tr><td colSpan={6} className="px-3 py-6 text-center text-gray-500">HRK összesítő betöltése...</td></tr>
              ) : !hrkSummary || hrkSummary.currencyBreakdown.length === 0 ? (
                <tr><td colSpan={6} className="px-3 py-6 text-center text-gray-500">Nincs HRK havi mozgás.</td></tr>
              ) : hrkSummary.currencyBreakdown.map((row) => (
                <tr key={row.currencyCode}>
                  <td className="px-3 py-2 font-bold">{row.currencyCode}</td>
                  <td className="px-3 py-2 text-right">{row.handoverCount}</td>
                  <td className="px-3 py-2 text-right">{formatHuf(row.handoverHuf)}</td>
                  <td className="px-3 py-2 text-right">{row.receiveCount}</td>
                  <td className="px-3 py-2 text-right">{formatHuf(row.receiveHuf)}</td>
                  <td className="px-3 py-2 text-right">{formatHuf(row.netHuf)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="mt-6 border-t border-gray-200 pt-4" data-testid="hrk-daily-panel">
          <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div>
              <h3 className="text-sm font-bold text-gray-900">HRK napi napló</h3>
              <p className="mt-1 text-sm text-gray-500">Pénztár-bank HRK mozgások napi ellenőrzése és zárási listája.</p>
            </div>
            <div className="flex flex-col gap-2 sm:flex-row sm:items-end">
              <div>
                <label htmlFor="hrk-daily-date" className="form-label">HRK nap</label>
                <input
                  id="hrk-daily-date"
                  type="date"
                  value={hrkDailyDate}
                  onChange={(event) => setHrkDailyDate(event.target.value)}
                  className="form-input"
                />
              </div>
              <button
                type="button"
                onClick={() => void loadHrkJournal()}
                disabled={hrkDailyLoading}
                className="form-button inline-flex items-center gap-2"
              >
                <RefreshCw className={`h-4 w-4 ${hrkDailyLoading ? 'animate-spin' : ''}`} />
                Napi napló frissítés
              </button>
              <button
                type="button"
                onClick={() => void closeHrkDaily()}
                disabled={hrkDailyClosing}
                className="form-button-primary inline-flex items-center gap-2"
              >
                <CheckCircle className="h-4 w-4" />
                {hrkDailyClosing ? 'Napi zárás...' : 'HRK napi zárás'}
              </button>
            </div>
          </div>

          {hrkDailyError && (
            <div className="form-error mt-3 flex items-center gap-2">
              <AlertTriangle className="h-4 w-4" />
              {hrkDailyError}
            </div>
          )}

          <div className="mt-4 rounded-md border border-gray-200 bg-gray-50 p-3" data-testid="hrk-daily-movement-form">
            <div className="grid grid-cols-1 gap-3 md:grid-cols-6">
              <div>
                <label htmlFor="hrk-movement-type" className="form-label">Művelet</label>
                <select
                  id="hrk-movement-type"
                  value={hrkMovementType}
                  onChange={(event) => setHrkMovementType(event.target.value as 'HANDOVER' | 'RECEIVE')}
                  className="form-input"
                >
                  <option value="HANDOVER">Pénztár → bank</option>
                  <option value="RECEIVE">Bank → pénztár</option>
                </select>
              </div>
              <div>
                <label htmlFor="hrk-currency-code" className="form-label">Valuta</label>
                <input
                  id="hrk-currency-code"
                  value={hrkCurrencyCode}
                  onChange={(event) => setHrkCurrencyCode(event.target.value.toUpperCase())}
                  className="form-input uppercase"
                  maxLength={3}
                  placeholder="EUR"
                />
              </div>
              <div>
                <label htmlFor="hrk-amount" className="form-label">Összeg</label>
                <input
                  id="hrk-amount"
                  value={hrkAmount}
                  onChange={(event) => setHrkAmount(event.target.value)}
                  className="form-input"
                  inputMode="decimal"
                  placeholder="250"
                />
              </div>
              <div>
                <label htmlFor="hrk-huf-amount" className="form-label">HUF összeg</label>
                <input
                  id="hrk-huf-amount"
                  value={hrkHufAmount}
                  onChange={(event) => setHrkHufAmount(event.target.value)}
                  className="form-input"
                  inputMode="decimal"
                  placeholder="100000"
                />
              </div>
              <div>
                <label htmlFor="hrk-bank-account" className="form-label">Bankszámla</label>
                <input
                  id="hrk-bank-account"
                  value={hrkBankAccountNumber}
                  onChange={(event) => setHrkBankAccountNumber(event.target.value)}
                  className="form-input"
                  placeholder="Opcionális"
                />
              </div>
              <div className="flex items-end">
                <button
                  type="button"
                  onClick={() => void saveHrkMovement()}
                  disabled={hrkMovementSaving}
                  className="form-button-primary inline-flex min-h-10 w-full items-center justify-center gap-2"
                >
                  {hrkMovementType === 'HANDOVER' ? <ArrowUpFromLine className="h-4 w-4" /> : <ArrowDownToLine className="h-4 w-4" />}
                  {hrkMovementSaving ? 'Rögzítés...' : 'HRK rögzítés'}
                </button>
              </div>
            </div>
            <div className="mt-3">
              <label htmlFor="hrk-note" className="form-label">Megjegyzés</label>
              <input
                id="hrk-note"
                value={hrkNote}
                onChange={(event) => setHrkNote(event.target.value)}
                className="form-input"
                placeholder="Opcionális HRK megjegyzés"
              />
            </div>
          </div>

          <div className="mt-4 grid grid-cols-2 gap-2 md:grid-cols-4">
            <div className="rounded-md bg-gray-50 p-3">
              <div className="text-xs text-gray-500">Napló sor</div>
              <div className="mt-1 text-lg font-bold">{hrkJournal.length}</div>
            </div>
            <div className="rounded-md bg-gray-50 p-3">
              <div className="text-xs text-gray-500">Napi zárás sor</div>
              <div className="mt-1 text-lg font-bold">{hrkDailyRows.length}</div>
            </div>
            <div className="rounded-md bg-gray-50 p-3">
              <div className="text-xs text-gray-500">Napló HUF</div>
              <div className="mt-1 text-lg font-bold">
                {formatHuf(hrkJournal.reduce((sum, row) => sum + Number(String(row.hufAmount ?? 0).replace(',', '.')), 0))}
              </div>
            </div>
            <div className="rounded-md bg-gray-50 p-3">
              <div className="text-xs text-gray-500">Zárás HUF</div>
              <div className="mt-1 text-lg font-bold">
                {formatHuf(hrkDailyRows.reduce((sum, row) => sum + Number(String(row.hufAmount ?? 0).replace(',', '.')), 0))}
              </div>
            </div>
          </div>

          <div className="mt-4 overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Időpont</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Típus</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Ref.</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Valuta</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Összeg</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">HUF</th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Státusz</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Művelet</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {hrkDailyLoading ? (
                  <tr><td colSpan={8} className="px-3 py-6 text-center text-gray-500">HRK napi napló betöltése...</td></tr>
                ) : hrkJournal.length === 0 ? (
                  <tr><td colSpan={8} className="px-3 py-6 text-center text-gray-500">Nincs HRK napi napló.</td></tr>
                ) : hrkJournal.slice(0, 10).map((row) => (
                  <tr key={row.id}>
                    <td className="px-3 py-2 whitespace-nowrap">{formatDateTime(row.createdAt)}</td>
                    <td className="px-3 py-2 font-semibold">{row.type}</td>
                    <td className="px-3 py-2">{row.reference ?? '-'}</td>
                    <td className="px-3 py-2 font-bold">{row.currencyCode}</td>
                    <td className="px-3 py-2 text-right">{formatAmount(row.amount)}</td>
                    <td className="px-3 py-2 text-right">{formatHuf(row.hufAmount)}</td>
                    <td className="px-3 py-2">{row.status ?? '-'}</td>
                    <td className="px-3 py-2 text-right">
                      <button
                        type="button"
                        onClick={() => void cancelHrkMovement(row)}
                        disabled={row.status !== 'PENDING' || hrkCancellingId === row.id}
                        className="form-button inline-flex items-center gap-1 text-xs disabled:cursor-not-allowed disabled:opacity-50"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                        Törlés
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.month')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.branch')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.status')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.closedAt')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('monthlyClose.closedBy')}</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.loading')}</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.noData')}</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.yearMonth ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.branchName ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.closedAt ? new Date(item.closedAt).toLocaleString('hu-HU') : '-'}</td>
                <td className="px-4 py-3 text-sm">{item.closedByName ?? '-'}</td>
                <td className="px-4 py-3 text-right">
                  <button
                    type="button"
                    onClick={() => void downloadMonthlyPdf(item.yearMonth)}
                    disabled={!item.yearMonth}
                    className="form-button inline-flex items-center gap-2 text-xs"
                  >
                    <Download className="h-4 w-4" />
                    PDF
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('common.total')}: {filtered.length} / {items.length}
      </div>
    </div>
  )
}
