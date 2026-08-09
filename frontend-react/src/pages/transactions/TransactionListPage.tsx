import { useEffect, useState, useCallback } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  Search,
  Plus,
  FileText,
  Printer,
  Eye,
  XCircle,
  ChevronLeft,
  ChevronRight,
  Loader2,
  RefreshCw,
  RotateCcw,
  FileDown,
  CalendarDays,
} from 'lucide-react'
import {
  receiptApi,
  transactionApi,
  type Transaction,
  type TransactionTypeName,
} from '../../services/api/transactions'
import type { PagedResponse } from '../../services/api/client'
import { toast } from '../../components/ui/toaster'
import { isElectron, getElectronAPI } from '../../utils/electron'
import { useTranslation } from 'react-i18next'
import { downloadBlob } from '../../utils/downloadBlob'
import { getBlobErrorMessage } from '../../utils/errorHandling'
import { sanitizeSyncErrorMessage } from '../../utils/syncErrorSanitizer'
import { classifyPendingSyncState } from '../../utils/pendingSyncState'
import { useOnlineStatus } from '../../hooks/useOnlineStatus'

const PAGE_SIZE = 25
const PENDING_TX_ID_OFFSET = 1_000_000
const PENDING_CONVERSION_ID_OFFSET = 2_000_000

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
  return n.toLocaleString('hu-HU', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  })
}

export default function TransactionListPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [typeFilter, setTypeFilter] = useState<TransactionTypeName | ''>('')
  const [customerOnly, setCustomerOnly] = useState(false)

  const [page, setPage] = useState(0)
  const [data, setData] = useState<PagedResponse<Transaction> | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // FK-071 FR-3/NFR-1: célzott újraküldés állapota + online-detektálás.
  // Offline állapotban a gomb letiltott (disabled + magyarázó tooltip, v2.3.36 minta).
  const { isOnline } = useOnlineStatus()
  const [retryingIds, setRetryingIds] = useState<Set<number>>(new Set())

  // FKH-031 FR-6: soha fel nem kuldott (PENDING) tetel "Megtekintes" gombja nem
  // navigalhat a szerver-alapu reszletek nezetre (404 lenne) — a mar ismert helyi
  // adatokat mutatjuk egy konnyu modalban.
  const [localDetailTx, setLocalDetailTx] = useState<
    (Transaction & { syncError?: string; syncAttempts?: number }) | null
  >(null)

  const fetchTransactions = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await transactionApi.list({
        page,
        size: PAGE_SIZE,
        startDate: dateFrom || undefined,
        endDate: dateTo || undefined,
        type: typeFilter || undefined,
        customerOnly: customerOnly || undefined,
      })

      // Electron: a helyi SQLite pending (meg fel nem kuldott) bizonylatai is latszodjanak
      let localPending: Transaction[] = []
      if (isElectron() && page === 0) {
        const api = getElectronAPI()
        // Pending buy/sell/reversal tranzakciok
        if (api?.getPendingTransactions) {
          try {
            const rows = await api.getPendingTransactions()
            localPending = rows.map(
              (r) =>
                ({
                  id: -(PENDING_TX_ID_OFFSET + Number(r.id)),
                  receiptNumber:
                    (r as { local_reference_number?: string }).local_reference_number ??
                    `L-${String(r.id).padStart(8, '0')}`, // NGM helyi bizonylatszam (V/E/K/AA/AV prefix)
                  transactionDate:
                    (r as { created_at?: string }).created_at?.slice(0, 10) ??
                    new Date().toISOString().slice(0, 10),
                  transactionTime: (r as { created_at?: string }).created_at?.slice(11, 19) ?? '',
                  transactionType:
                    (String(r.type).toUpperCase() as Transaction['transactionType']) || 'BUY',
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
                  // FK-SYNC (2026-06-02): a tartós sync-hiba (ha a tétel feltöltése elbukott) — a UI
                  // megmutatja, MIÉRT ragadt "Függőben", hogy a tranzakció ne tűnjön el némán.
                  syncError: r.sync_error ?? undefined,
                  syncAttempts: r.sync_attempts ?? undefined,
                }) as Transaction & { syncError?: string; syncAttempts?: number },
            )
          } catch {
            /* SQLite nem elerheto */
          }
        }

        // Pending konverziok (kulon tabla az Electron SQLite-ban)
        if (api?.getPendingConversions) {
          try {
            const convRows = await api.getPendingConversions()
            const pendingConversions: Transaction[] = convRows
              .filter((c) => !c.synced)
              .map(
                (c) =>
                  ({
                    id: -(PENDING_CONVERSION_ID_OFFSET + Number(c.id)),
                    receiptNumber: c.local_reference_number ?? `K-${String(c.id).padStart(8, '0')}`,
                    transactionDate:
                      c.created_at?.slice(0, 10) ?? new Date().toISOString().slice(0, 10),
                    transactionTime: c.created_at?.slice(11, 19) ?? '',
                    transactionType: 'CONVERSION' as Transaction['transactionType'],
                    currencyId: c.from_currency_id ?? 0,
                    currencyCode: c.from_currency_code,
                    currencyAmount: Number(c.from_amount),
                    exchangeRate: Number(c.conversion_rate),
                    hufAmount: Number(c.calculated_huf_amount),
                    roundedHufAmount: Number(c.calculated_huf_amount),
                    status: 'PENDING' as const,
                    customerName: c.customer_name ?? undefined,
                    workerName: undefined,
                    workerId: 0,
                    branchId: '',
                    printed: false,
                    handlingFee: c.handling_fee != null ? Number(c.handling_fee) : 0,
                    discountAmount: 0,
                    discountPercent: 0,
                    createdAt: c.created_at ?? new Date().toISOString(),
                  }) as Transaction,
              )
            localPending = [...localPending, ...pendingConversions]
          } catch {
            /* SQLite nem elerheto */
          }
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
  }, [page, dateFrom, dateTo, typeFilter, customerOnly])

  useEffect(() => {
    fetchTransactions()
  }, [fetchTransactions])

  const transactions = data?.content ?? []
  const totalElements = data?.totalElements ?? 0
  const totalPages = data?.totalPages ?? 0

  // Client-side filter on customer name (server doesn't support text search on customer name).
  // FR-PA-05 "csak ügyfeles" SZERVER-oldali (customerOnly param) → a lapozás helyes; itt csak a
  // helyi név-keresés marad kliens-oldalon (a meglévő viselkedés szerint).
  const filteredTransactions = search
    ? transactions.filter((tx) => tx.customerName?.toLowerCase().includes(search.toLowerCase()))
    : transactions

  const handleSearch = () => {
    setPage(0)
    fetchTransactions()
  }

  const loadDailyTransactions = async () => {
    setLoading(true)
    setError(null)
    try {
      const daily = await transactionApi.getDaily()
      setPage(0)
      setData({
        content: daily,
        totalElements: daily.length,
        totalPages: daily.length > 0 ? 1 : 0,
        size: Math.max(daily.length, PAGE_SIZE),
        number: 0,
      })
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Hiba a mai tranzakciók betöltésekor'
      setError(msg)
      toast.error(msg)
    } finally {
      setLoading(false)
    }
  }

  const downloadReceiptPdf = async (tx: Transaction) => {
    if (tx.id <= 0) return
    try {
      const blob = await receiptApi.downloadTransactionPdf(tx.id)
      downloadBlob(blob, `bizonylat-${tx.id}.pdf`)
      toast.success('Bizonylat PDF letöltése elindítva')
    } catch (err) {
      toast.error('Nem sikerült a bizonylat PDF letöltése', await getBlobErrorMessage(err))
    }
  }

  const downloadReceiptEscPos = async (tx: Transaction) => {
    if (tx.id <= 0) return
    try {
      const blob = await receiptApi.downloadTransactionEscPos(tx.id)
      downloadBlob(blob, `bizonylat-${tx.id}.bin`)
      toast.success('ESC/POS bizonylat letöltése elindítva')
    } catch (err) {
      toast.error('Nem sikerült az ESC/POS bizonylat letöltése', await getBlobErrorMessage(err))
    }
  }

  // FK-071: a sor helyi (Electron SQLite) pending TRANZAKCIÓ-e (nem konverzió,
  // nem szerver-oldali tétel) — csak ezekre értelmezett a célzott újraküldés.
  const isPendingLocalTx = (tx: Transaction) =>
    tx.id <= -PENDING_TX_ID_OFFSET && tx.id > -PENDING_CONVERSION_ID_OFFSET

  // FK-071 FR-3/NFR-3: célzott, aszinkron újraküldés — a lista nem blokkol, a
  // gomb a futó kísérlet alatt letiltott, az eredmény (siker/új hibaüzenet) a
  // frissített pending sorból jön (a sync-engine tartósan rögzíti).
  const handleRetry = async (tx: Transaction) => {
    const api = getElectronAPI()
    if (!api?.retryPendingTransaction) return
    const localId = -tx.id - PENDING_TX_ID_OFFSET
    setRetryingIds((prev) => new Set(prev).add(tx.id))
    try {
      await api.retryPendingTransaction(localId)
      await fetchTransactions()
    } finally {
      setRetryingIds((prev) => {
        const next = new Set(prev)
        next.delete(tx.id)
        return next
      })
    }
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          {t('archiving.tranzakciok')}
        </h1>
        <div className="flex flex-wrap gap-2">
          <button
            onClick={fetchTransactions}
            className="form-button flex items-center gap-1"
            disabled={loading}
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            {t('common.refresh')}
          </button>
          <button
            onClick={() => void loadDailyTransactions()}
            className="form-button flex items-center gap-1"
            disabled={loading}
          >
            <CalendarDays size={16} />
            Mai tranzakciók
          </button>
          <Link to="/transactions/new" className="form-button-primary flex items-center gap-1">
            <Plus size={16} />
            {t('misc.ujTranzakcio')}
          </Link>
        </div>
      </div>

      {/* Filters */}
      <div className="form-panel">
        <div className="flex flex-wrap gap-3 items-end">
          <div className="min-w-[220px] flex-1">
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
          <div className="min-w-[140px]">
            <label className="form-label">{t('transactions.datumTol')}</label>
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => {
                setDateFrom(e.target.value)
                setPage(0)
              }}
              className="form-input"
            />
          </div>
          <div className="min-w-[140px]">
            <label className="form-label">{t('transactions.datumIg')}</label>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => {
                setDateTo(e.target.value)
                setPage(0)
              }}
              className="form-input"
            />
          </div>
          <div className="min-w-[140px]">
            <label className="form-label">{t('common.type')}</label>
            <select
              value={typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value as TransactionTypeName | '')
                setPage(0)
              }}
              className="form-input"
            >
              <option value="">{t('common.all')}</option>
              <option value="BUY">{t('cashier.buy')}</option>
              <option value="SELL">{t('cashier.sell')}</option>
              <option value="REVERSAL">{t('cashier.storno')}</option>
              <option value="CONVERSION">{t('transactions.atvaltas')}</option>
              <option value="TRANSFER_OUT">{t('transactions.atadasi')}</option>
              <option value="TRANSFER_IN">{t('transactions.atveteli')}</option>
            </select>
          </div>
          {/* FR-PA-05: csak ügyfeles bizonylatok szűrő */}
          <div className="min-w-[160px]">
            <label className="form-label">&nbsp;</label>
            <label className="form-input flex h-[38px] items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={customerOnly}
                onChange={(e) => {
                  setCustomerOnly(e.target.checked)
                  setPage(0)
                }}
                data-testid="filter-customer-only"
              />
              {t('transactions.csakUgyfeles', 'Csak ügyfeles')}
            </label>
          </div>
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200 text-red-700 text-sm">{error}</div>
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
          <div className="overflow-x-auto">
            <table className="data-grid min-w-full">
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
                    <tr
                      key={tx.id}
                      className={tx.status === 'REVERSED' ? 'opacity-50 line-through' : ''}
                    >
                      <td className="font-mono text-sm text-gray-600">{tx.receiptNumber || '—'}</td>
                      <td className="font-mono text-sm">
                        {formatDate(tx.transactionDate, tx.transactionTime)}
                      </td>
                      <td>
                        <span
                          className={`px-1.5 py-0.5 text-xs rounded ${
                            tx.transactionType === 'BUY'
                              ? 'bg-green-100 text-green-700'
                              : tx.transactionType === 'SELL'
                                ? 'bg-blue-100 text-blue-700'
                                : tx.transactionType === 'REVERSAL'
                                  ? 'bg-red-100 text-red-700'
                                  : 'bg-purple-100 text-purple-700'
                          }`}
                        >
                          {tx.transactionType === 'BUY'
                            ? 'Vétel'
                            : tx.transactionType === 'SELL'
                              ? 'Eladás'
                              : tx.transactionType === 'REVERSAL'
                                ? 'Sztornó'
                                : tx.transactionType === 'TRANSFER_OUT'
                                  ? 'Átadás'
                                  : tx.transactionType === 'TRANSFER_IN'
                                    ? 'Átvétel'
                                    : 'Átváltás'}
                        </span>
                      </td>
                      <td className="font-bold">{tx.currencyCode}</td>
                      <td className="text-right font-mono">{formatNumber(tx.currencyAmount)}</td>
                      <td className="text-right font-mono text-gray-600">
                        {formatNumber(tx.exchangeRate, 4)}
                      </td>
                      <td className="text-right font-mono font-semibold">
                        {formatNumber(tx.roundedHufAmount ?? tx.hufAmount, 0)} {t('common.ft')}
                      </td>
                      <td>{tx.customerName || <span className="text-gray-400 italic">—</span>}</td>
                      <td>
                        {(() => {
                          // FK-SYNC (2026-06-02): ha a függő tételnél van tartós sync-hiba, PIROS
                          // "Feltöltés hibás" badge + tooltip az okkal — így a tétel nem tűnik el
                          // némán, a felhasználó látja, miért nem ment fel.
                          // FK-071 FR-2/FR-6: a tárolt szerver-üzenet PII-szűrve, látható
                          // részletként is megjelenik, nem csak a badge-felirat.
                          const syncErr = (tx as Transaction & { syncError?: string }).syncError
                          if (tx.status === 'PENDING' && syncErr) {
                            const sanitizedErr = sanitizeSyncErrorMessage(syncErr)
                            // FKH-031 NFR-1: 7 nap utan a sync-engine mar nem probalkozik
                            // automatikusan — ezt a badge-nek is jeleznie kell, kulonben a
                            // tetel nemaan elveszik.
                            const manualRequired = classifyPendingSyncState({
                              syncError: syncErr,
                              createdAt: tx.createdAt,
                            }).needsManualIntervention
                            return (
                              <div className="flex flex-col gap-0.5">
                                <span
                                  className={`px-1.5 py-0.5 text-xs rounded cursor-help w-fit ${
                                    manualRequired
                                      ? 'bg-red-200 text-red-900 font-semibold'
                                      : 'bg-red-100 text-red-700'
                                  }`}
                                  title={`Feltöltés sikertelen: ${sanitizedErr}`}
                                >
                                  {manualRequired ? 'Kézi beavatkozás kell' : 'Feltöltés hibás'}
                                </span>
                                <span
                                  data-testid={`sync-error-detail-${tx.id}`}
                                  className="block max-w-[240px] truncate text-[11px] text-red-600"
                                  title={sanitizedErr}
                                >
                                  {sanitizedErr}
                                </span>
                              </div>
                            )
                          }
                          return (
                            <span
                              className={`px-1.5 py-0.5 text-xs rounded ${
                                tx.status === 'COMPLETED'
                                  ? 'bg-green-100 text-green-700'
                                  : tx.status === 'REVERSED'
                                    ? 'bg-red-100 text-red-700'
                                    : 'bg-yellow-100 text-yellow-700'
                              }`}
                            >
                              {/* FK-071 Döntés 2 + kiegészítés: a "Feltöltve" felirat csak
                                  Electron/offline (penztar-client) kontextusban jelenik meg —
                                  web-módban a COMPLETED sor a korábbi "Teljesítve" feliratot
                                  kapja. A "Szinkronra vár" platform-független (szerver-oldali
                                  PENDING-et a backend soha nem ír, csak az Electron-lokális
                                  merge állítja be). Csak ez a Tranzakciólista-badge érintett;
                                  a többi modul feliratai modul-lokálisak és változatlanok. */}
                              {tx.status === 'COMPLETED'
                                ? isElectron()
                                  ? 'Feltöltve'
                                  : 'Teljesítve'
                                : tx.status === 'REVERSED'
                                  ? 'Sztornózva'
                                  : 'Szinkronra vár'}
                            </span>
                          )
                        })()}
                      </td>
                      <td>
                        <div className="flex gap-1">
                          {/* FK-071 FR-3/NFR-1: célzott újraküldés helyi pending tranzakcióra.
                              Offline állapotban letiltva + magyarázó tooltip (nincs csendes
                              próbálkozás); futó kísérlet alatt szintén letiltva (NFR-3). */}
                          {isPendingLocalTx(tx) && (
                            <button
                              className="toolbar-button"
                              title={
                                !isOnline
                                  ? 'Nincs hálózati kapcsolat — az újraküldés offline nem indítható'
                                  : retryingIds.has(tx.id)
                                    ? 'Újraküldés folyamatban…'
                                    : 'Újraküldés'
                              }
                              onClick={() => void handleRetry(tx)}
                              disabled={!isOnline || retryingIds.has(tx.id)}
                              data-testid={`retry-tx-${tx.id}`}
                            >
                              <RotateCcw
                                size={14}
                                className={retryingIds.has(tx.id) ? 'animate-spin' : ''}
                              />
                            </button>
                          )}
                          <button
                            className="toolbar-button"
                            title={
                              tx.status === 'PENDING'
                                ? 'Helyi részletek (még nem került fel a szerverre)'
                                : 'Megtekintés'
                            }
                            onClick={() => {
                              // FKH-031 FR-6: PENDING tetel eseten NINCS szerver-navigacio.
                              if (tx.status === 'PENDING') {
                                setLocalDetailTx(
                                  tx as Transaction & { syncError?: string; syncAttempts?: number },
                                )
                                return
                              }
                              navigate(`/transactions/${tx.receiptNumber || tx.id}`)
                            }}
                            data-testid={`view-tx-${tx.id}`}
                          >
                            <Eye size={14} />
                          </button>
                          <button
                            className="toolbar-button"
                            title={
                              tx.id > 0
                                ? 'Bizonylat PDF letöltés'
                                : 'Bizonylat PDF csak szinkronizált tranzakcióhoz érhető el'
                            }
                            onClick={() => void downloadReceiptPdf(tx)}
                            disabled={tx.id <= 0}
                            data-testid={`receipt-pdf-tx-${tx.id}`}
                          >
                            <FileDown size={14} />
                          </button>
                          <button
                            className="toolbar-button"
                            title={
                              tx.id > 0
                                ? 'ESC/POS bizonylat letöltés'
                                : 'ESC/POS csak szinkronizált tranzakcióhoz érhető el'
                            }
                            onClick={() => void downloadReceiptEscPos(tx)}
                            disabled={tx.id <= 0}
                            data-testid={`receipt-escpos-tx-${tx.id}`}
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
                                  onClick={() =>
                                    navigate(`/transactions/${tx.receiptNumber || tx.id}/storno`)
                                  }
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
        </div>
      )}

      {/* Pagination + Summary */}
      {data && (
        <div className="form-panel">
          <div className="flex flex-wrap justify-between gap-2 text-sm">
            <span>
              {totalElements} {t('transactions.tranzakcio')}
              {totalPages > 1 && ` (${page + 1}/${totalPages} oldal)`}
            </span>
            <div className="flex items-center gap-2">
              <button
                className="form-button px-2 py-1"
                disabled={page === 0}
                onClick={() => setPage((p) => Math.max(0, p - 1))}
              >
                <ChevronLeft size={14} />
              </button>
              <span className="font-mono text-xs">
                {page + 1} / {Math.max(totalPages, 1)}
              </span>
              <button
                className="form-button px-2 py-1"
                disabled={page >= totalPages - 1}
                onClick={() => setPage((p) => p + 1)}
              >
                <ChevronRight size={14} />
              </button>
            </div>
            <span>
              {t('audit.osszesen')}
              <strong className="font-mono">
                {formatNumber(
                  filteredTransactions.reduce(
                    (sum, tx) => sum + (tx.roundedHufAmount ?? tx.hufAmount),
                    0,
                  ),
                  0,
                )}{' '}
                {t('common.ft')}
              </strong>
            </span>
          </div>
        </div>
      )}

      {/* FKH-031 FR-6: helyi (PENDING) tetel reszletei — nincs szerver-hivas, nincs 404. */}
      {localDetailTx && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
          onClick={() => setLocalDetailTx(null)}
          data-testid="local-pending-detail-overlay"
        >
          <div
            className="w-full max-w-md rounded bg-white p-4 shadow-lg"
            onClick={(e) => e.stopPropagation()}
            data-testid="local-pending-detail"
          >
            <h2 className="mb-2 text-lg font-bold text-gray-800">Helyi tétel részletei</h2>
            <p className="mb-3 text-xs text-gray-500">
              Ez a tétel még nem került fel a szerverre, ezért csak a helyben tárolt adatok
              láthatók.
            </p>
            <dl className="space-y-1 text-sm">
              <div className="flex justify-between gap-4">
                <dt className="text-gray-500">Típus</dt>
                <dd className="font-mono">{localDetailTx.transactionType}</dd>
              </div>
              <div className="flex justify-between gap-4">
                <dt className="text-gray-500">Deviza</dt>
                <dd className="font-mono">{localDetailTx.currencyCode}</dd>
              </div>
              <div className="flex justify-between gap-4">
                <dt className="text-gray-500">Összeg</dt>
                <dd className="font-mono">
                  {formatNumber(localDetailTx.foreignAmount, 2)} {localDetailTx.currencyCode}
                </dd>
              </div>
              <div className="flex justify-between gap-4">
                <dt className="text-gray-500">Árfolyam</dt>
                <dd className="font-mono">{formatNumber(localDetailTx.exchangeRate, 4)}</dd>
              </div>
              <div className="flex justify-between gap-4">
                <dt className="text-gray-500">HUF</dt>
                <dd className="font-mono">
                  {formatNumber(localDetailTx.roundedHufAmount ?? localDetailTx.hufAmount, 0)}{' '}
                  {t('common.ft')}
                </dd>
              </div>
              {localDetailTx.syncAttempts !== undefined && (
                <div className="flex justify-between gap-4">
                  <dt className="text-gray-500">Küldési kísérletek</dt>
                  <dd className="font-mono">{localDetailTx.syncAttempts}</dd>
                </div>
              )}
            </dl>
            {localDetailTx.syncError && (
              <p
                className="mt-3 rounded bg-red-50 p-2 text-xs text-red-700"
                data-testid="local-pending-detail-error"
              >
                {sanitizeSyncErrorMessage(localDetailTx.syncError)}
              </p>
            )}
            <div className="mt-4 flex justify-end">
              <button className="form-button" onClick={() => setLocalDetailTx(null)}>
                {t('common.close', 'Bezárás')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
