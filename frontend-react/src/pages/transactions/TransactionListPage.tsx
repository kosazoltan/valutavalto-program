import { useEffect, useState, useCallback } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Search, Plus, FileText, Printer, Eye, XCircle, ChevronLeft, ChevronRight, Loader2, RefreshCw } from 'lucide-react'
import { transactionApi, type Transaction } from '../../services/api/transactions'
import type { PagedResponse } from '../../services/api/client'
import { toast } from '../../components/ui/toaster'
import { isElectron, getElectronAPI } from '../../utils/electron'
import { useTranslation } from 'react-i18next'

const PAGE_SIZE = 25

/**
 * v2.3.37 (Sourcery #301 P3): Storno tooltip-szovegek + status-derivacio kiemelt
 * konstansok / helper. Ha a UX copy valtozik, csak itt kell modositani.
 */
const STORNO_PENDING_TOOLTIP =
  'Sztornó csak véglegesítés (szerver-szinkron) után érhető el. ' +
  'A tranzakció jelenleg helyileg rögzítve, várakozik a sync-engine-re (~30 sec).'

type StornoUiState = 'available' | 'pending' | 'reversed'

function getStornoUiState(status: string | null | undefined): StornoUiState {
  if (status === 'COMPLETED') return 'available'
  if (status === 'REVERSED') return 'reversed'
  return 'pending'
}

function formatDate(dateStr: string, timeStr?: string): string {
  if (!dateStr) return ''
  const date = dateStr.substring(0, 10)
  const time = timeStr ? ` ${timeStr.substring(0, 5)}` : ''
  return `${date}${time}`
}

function formatNumber(n: number | null | undefined, decimals = 2): string {
  if (n === null || n === undefined) return '—'
  return n.toLocaleString('hu-HU', { minimumFractionDigits: decimals, maximumFractionDigits: decimals })
}

export default function TransactionListPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [typeFilter, setTypeFilter] = useState<string>('')

  const [page, setPage] = useState(0)
  const [data, setData] = useState<PagedResponse<Transaction> | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchTransactions = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await transactionApi.list({
        page,
        size: PAGE_SIZE,
        startDate: dateFrom || undefined,
        endDate: dateTo || undefined,
        type: (typeFilter as 'BUY' | 'SELL' | 'REVERSAL' | 'CONVERSION') || undefined,
      })

      // Electron: a helyi SQLite pending (meg fel nem kuldott) bizonylatai is latszodjanak
      let localPending: Transaction[] = []
      if (isElectron() && page === 0) {
        const api = getElectronAPI()
        if (api?.getPendingTransactions) {
          try {
            const rows = await api.getPendingTransactions()
            localPending = rows.map((r) => ({
              id: -(1_000_000 + Number(r.id)),
              receiptNumber: (r as { local_reference_number?: string }).local_reference_number ?? `L-${String(r.id).padStart(8, '0')}`, // NGM helyi bizonylatszam (V/E/K/AA/AV prefix)
              transactionDate: (r as { created_at?: string }).created_at?.slice(0, 10) ?? new Date().toISOString().slice(0, 10),
              transactionTime: (r as { created_at?: string }).created_at?.slice(11, 19) ?? '',
              transactionType: (String(r.type).toUpperCase() as Transaction['transactionType']) || 'BUY',
              currencyId: 0,
              currencyCode: r.currency_code,
              currencyAmount: Number(r.foreign_amount),
              exchangeRate: Number(r.rate),
              hufAmount: Number(r.huf_amount),
              roundedHufAmount: Number(r.rounded_huf_amount ?? r.huf_amount),
              status: 'PENDING' as const,
              customerName: r.customer_name ?? undefined,
              workerName: undefined,
              workerId: 0,
              branchId: '',
              printed: false,
              handlingFee: r.handling_fee != null ? Number(r.handling_fee) : 0,
              discountAmount: 0,
              discountPercent: r.discount_percent != null ? Number(r.discount_percent) : 0,
              createdAt: (r as { created_at?: string }).created_at ?? new Date().toISOString(),
            } as Transaction))
          } catch { /* SQLite nem elerheto */ }
        }
      }

      setData({
        ...result,
        content: [...localPending, ...result.content],
        totalElements: result.totalElements + localPending.length,
      })
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Hiba a tranzakciók betöltésekor'
      setError(msg)
      toast.error(msg)
    } finally {
      setLoading(false)
    }
  }, [page, dateFrom, dateTo, typeFilter])

  useEffect(() => {
    fetchTransactions()
  }, [fetchTransactions])

  const transactions = data?.content ?? []
  const totalElements = data?.totalElements ?? 0
  const totalPages = data?.totalPages ?? 0

  // Client-side filter on customer name (server doesn't support text search on customer name)
  const filteredTransactions = search
    ? transactions.filter(tx =>
        tx.customerName?.toLowerCase().includes(search.toLowerCase())
      )
    : transactions

  const handleSearch = () => {
    setPage(0)
    fetchTransactions()
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          {t('archiving.tranzakciok')}
        </h1>
        <div className="flex gap-2">
          <button
            onClick={fetchTransactions}
            className="form-button flex items-center gap-1"
            disabled={loading}
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            {t('common.refresh')}
          </button>
          <Link to="/transactions/new" className="form-button-primary flex items-center gap-1">
            <Plus size={16} />
            {t('misc.ujTranzakcio')}
          </Link>
        </div>
      </div>

      {/* Filters */}
      <div className="form-panel">
        <div className="flex gap-3 items-end">
          <div className="flex-1">
            <label className="form-label">{t('transactions.keresesUgyfelnev')}</label>
            <div className="flex gap-1">
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                className="form-input flex-1"
                placeholder="Ügyfél neve..."
              />
              <button className="form-button" onClick={handleSearch}>
                <Search size={16} />
              </button>
            </div>
          </div>
          <div>
            <label className="form-label">{t('transactions.datumTol')}</label>
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => { setDateFrom(e.target.value); setPage(0) }}
              className="form-input"
            />
          </div>
          <div>
            <label className="form-label">{t('transactions.datumIg')}</label>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => { setDateTo(e.target.value); setPage(0) }}
              className="form-input"
            />
          </div>
          <div>
            <label className="form-label">{t('common.type')}</label>
            <select
              value={typeFilter}
              onChange={(e) => { setTypeFilter(e.target.value); setPage(0) }}
              className="form-input"
            >
              <option value="">{t('common.all')}</option>
              <option value="BUY">{t('cashier.buy')}</option>
              <option value="SELL">{t('cashier.sell')}</option>
              <option value="REVERSAL">{t('cashier.storno')}</option>
              <option value="CONVERSION">{t('transactions.atvaltas')}</option>
            </select>
          </div>
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200 text-red-700 text-sm">
          {error}
        </div>
      )}

      {/* Loading */}
      {loading && !data && (
        <div className="form-panel flex justify-center items-center py-8">
          <Loader2 className="animate-spin text-gray-400" size={32} />
        </div>
      )}

      {/* Table */}
      {data && (
        <div className="form-panel p-0">
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{t('reports.bizonylat')}</th>
                <th>{t('transactions.datumIdo')}</th>
                <th>{t('common.type')}</th>
                <th>{t('common.deviza')}</th>
                <th className="text-right">{t('stornos.devizaOsszeg')}</th>
                <th className="text-right">{t('cashier.exchangeRate')}</th>
                <th className="text-right">{t('stornos.hufOsszeg')}</th>
                <th>{t('common.customer')}</th>
                <th>{t('common.status')}</th>
                <th className="w-24">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredTransactions.length === 0 ? (
                <tr>
                  <td colSpan={10} className="text-center text-gray-400 py-8">
                    {t('common.noResult')}
                  </td>
                </tr>
              ) : (
                filteredTransactions.map((tx) => (
                  <tr key={tx.id} className={tx.status === 'REVERSED' ? 'opacity-50 line-through' : ''}>
                    <td className="font-mono text-sm text-gray-600">{tx.receiptNumber || '—'}</td>
                    <td className="font-mono text-sm">{formatDate(tx.transactionDate, tx.transactionTime)}</td>
                    <td>
                      <span className={`px-1.5 py-0.5 text-xs rounded ${
                        tx.transactionType === 'BUY'
                          ? 'bg-green-100 text-green-700'
                          : tx.transactionType === 'SELL'
                            ? 'bg-blue-100 text-blue-700'
                            : tx.transactionType === 'REVERSAL'
                              ? 'bg-red-100 text-red-700'
                              : 'bg-purple-100 text-purple-700'
                      }`}>
                        {tx.transactionType === 'BUY' ? 'Vétel'
                          : tx.transactionType === 'SELL' ? 'Eladás'
                            : tx.transactionType === 'REVERSAL' ? 'Sztornó'
                              : 'Átváltás'}
                      </span>
                    </td>
                    <td className="font-bold">{tx.currencyCode}</td>
                    <td className="text-right font-mono">{formatNumber(tx.currencyAmount)}</td>
                    <td className="text-right font-mono text-gray-600">{formatNumber(tx.exchangeRate, 4)}</td>
                    <td className="text-right font-mono font-semibold">
                      {formatNumber(tx.roundedHufAmount ?? tx.hufAmount, 0)} {t('common.ft')}
                    </td>
                    <td>{tx.customerName || <span className="text-gray-400 italic">—</span>}</td>
                    <td>
                      <span className={`px-1.5 py-0.5 text-xs rounded ${
                        tx.status === 'COMPLETED'
                          ? 'bg-green-100 text-green-700'
                          : tx.status === 'REVERSED'
                            ? 'bg-red-100 text-red-700'
                            : 'bg-yellow-100 text-yellow-700'
                      }`}>
                        {tx.status === 'COMPLETED' ? 'Teljesítve'
                          : tx.status === 'REVERSED' ? 'Sztornózva'
                            : 'Függőben'}
                      </span>
                    </td>
                    <td>
                      <div className="flex gap-1">
                        <button
                          className="toolbar-button"
                          title="Megtekintés"
                          onClick={() => navigate(`/transactions/${tx.receiptNumber || tx.id}`)}
                          data-testid={`view-tx-${tx.id}`}
                        >
                          <Eye size={14} />
                        </button>
                        <button
                          className="toolbar-button"
                          title="Nyomtatás"
                          data-testid={`print-tx-${tx.id}`}
                        >
                          <Printer size={14} />
                        </button>
                        {/* v2.3.36 (B25 audit fix): "Függőben" tranzakciókra is mutatjuk a storno
                         * ikont, DE disabled + magyarázó tooltip-pel. A korábbi UI-ban a button
                         * egyszerűen NEM jelent meg, ezért a felhasználó nem tudta, miért hiányzik.
                         * v2.3.37 (Sourcery #301 P3): getStornoUiState helper + extract konstans. */}
                        {(() => {
                          const stornoState = getStornoUiState(tx.status)
                          if (stornoState === 'available') {
                            return (
                              <button
                                className="toolbar-button text-red-600 hover:text-red-700"
                                title="Sztornó"
                                onClick={() => navigate(`/transactions/${tx.receiptNumber || tx.id}/storno`)}
                                data-testid={`storno-tx-${tx.id}`}
                              >
                                <XCircle size={14} />
                              </button>
                            )
                          }
                          if (stornoState === 'pending') {
                            return (
                              <button
                                className="toolbar-button text-gray-400 cursor-not-allowed"
                                title={STORNO_PENDING_TOOLTIP}
                                disabled
                                data-testid={`storno-tx-${tx.id}-disabled`}
                              >
                                <XCircle size={14} />
                              </button>
                            )
                          }
                          // 'reversed' — semmi ne jelenjen meg
                          return null
                        })()}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* Pagination + Summary */}
      {data && (
        <div className="form-panel">
          <div className="flex justify-between items-center text-sm">
            <span>
              {totalElements} {t('transactions.tranzakcio')}{totalPages > 1 && ` (${page + 1}/${totalPages} oldal)`}
            </span>
            <div className="flex items-center gap-2">
              <button
                className="form-button px-2 py-1"
                disabled={page === 0}
                onClick={() => setPage(p => Math.max(0, p - 1))}
              >
                <ChevronLeft size={14} />
              </button>
              <span className="font-mono text-xs">{page + 1} / {Math.max(totalPages, 1)}</span>
              <button
                className="form-button px-2 py-1"
                disabled={page >= totalPages - 1}
                onClick={() => setPage(p => p + 1)}
              >
                <ChevronRight size={14} />
              </button>
            </div>
            <span>
              {t('audit.osszesen')}<strong className="font-mono">
                {formatNumber(filteredTransactions.reduce((sum, tx) => sum + (tx.roundedHufAmount ?? tx.hufAmount), 0), 0)} {t('common.ft')}
              </strong>
            </span>
          </div>
        </div>
      )}
    </div>
  )
}
