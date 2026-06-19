import { useState, useEffect, useCallback, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { Vault, Lock, Unlock, Plus, Minus, AlertTriangle, CheckCircle, Clock, FileCheck, Info, X } from 'lucide-react'
import { NumberInput } from '../../components/NumberInput'
import { cashBalanceApi, dailySessionApi } from '../../services/api/index'
import type { BranchBalanceSummary, CashBalance, DailySession } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'

const CASHDESK_REFRESH_INTERVAL_MS = 30_000

interface CashDeskBalanceItem {
  currencyId: number
  currency: string
  balance: number
  minBalance: number
  maxBalance: number
}

interface CashDeskStatus {
  isOpen: boolean
  openedAt: string
  openedBy: string
  balances: CashDeskBalanceItem[]
  todayStats: { transactions: number; buyTotal: number; sellTotal: number; profit: number }
}

const cashDeskLabels = {
  currencies: 'Valuták',
  hufStock: 'HUF készlet',
  lowAlert: 'Alacsony jelzés',
  highAlert: 'Magas jelzés',
  detailSuffix: 'pénzkészlet részletek',
  current: 'Aktuális',
  opening: 'Nyitó',
  dailyChange: 'Napi változás',
  limit: 'Limit',
  codeCheck: 'Kód ellenőrzés',
  codeCheckOk: 'ID és kód egyezik',
  codeCheckMismatch: 'Eltérés vagy hiány',
}

/**
 * v2.3.38 (B12 audit fix): ISO timestamp -> hu-HU formatum.
 * Korabban a "Nyitva: {status.openedAt}" raw ISO-t mutatott:
 * "2026-04-29T11:43:07.623294" — a felhasznalo NEM tudta gyorsan ertelmezni.
 * Most "2026.04.29 11:43" formatumot mutatunk (datum + ora-perc).
 *
 * Hibrid kezeles: ha a string parsolhatatlan, az eredetit visszaadjuk
 * (hibatűrőség — nem omlik össze a UI).
 */
function formatOpenedAtTimestamp(raw: string | null | undefined): string {
  // v2.3.42 (Sourcery #303): ures string-et is missing-kent kezeljuk
  // (a `!raw` mar fed-i, de explicit `.trim()` kontaminacios szunkozt is)
  if (!raw?.trim()) return '—'
  const d = new Date(raw)
  if (isNaN(d.getTime())) return raw  // fallback: raw if parse-fail
  const date = d.toLocaleDateString('hu-HU', { year: 'numeric', month: '2-digit', day: '2-digit' })
  const time = d.toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' })
  return `${date} ${time}`
}

export default function CashDeskPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [status, setStatus] = useState<CashDeskStatus>({
    isOpen: false,
    openedAt: '',
    openedBy: '',
    balances: [],
    todayStats: { transactions: 0, buyTotal: 0, sellTotal: 0, profit: 0 },
  })
  const [_loading, setLoading] = useState(true)
  const [showMovementDialog, setShowMovementDialog] = useState(false)
  const [movementType, setMovementType] = useState<'in' | 'out'>('in')
  const [movementCurrency, setMovementCurrency] = useState('HUF')
  const [movementAmount, setMovementAmount] = useState('')
  const [summary, setSummary] = useState<BranchBalanceSummary | null>(null)
  const [selectedBalance, setSelectedBalance] = useState<CashBalance | null>(null)
  const [codeCheckBalance, setCodeCheckBalance] = useState<CashBalance | null>(null)
  const [detailLoadingCurrency, setDetailLoadingCurrency] = useState<string | null>(null)
  const [detailError, setDetailError] = useState<string | null>(null)
  const loadingRef = useRef(false)

  const loadData = useCallback(async () => {
    if (loadingRef.current) return
    loadingRef.current = true
    setLoading(true)
    try {
      const [balances, session, branchSummary]: [CashBalance[], DailySession | null, BranchBalanceSummary | null] = await Promise.all([
        cashBalanceApi.list().catch(() => [] as CashBalance[]),
        dailySessionApi.getCurrent().catch(() => null),
        cashBalanceApi.getSummary().catch(() => null),
      ])
      setSummary(branchSummary)

      setStatus({
        isOpen: !!session && session.status === 'OPEN',
        openedAt: session?.openedAt ?? '',
        openedBy: session?.openedByWorkerName ?? '',
        balances: balances.map((b) => ({
          currencyId: b.currencyId,
          currency: b.currencyCode,
          balance: b.currentBalance,
          minBalance: b.minBalance ?? 0,
          maxBalance: b.maxBalance ?? 999999999,
        })),
        todayStats: session
          ? {
              transactions: session.transactionCount ?? 0,
              buyTotal: session.buyTurnoverHuf ?? 0,
              sellTotal: session.sellTurnoverHuf ?? 0,
              profit: session.handlingFeeTotal ?? 0,
            }
          : { transactions: 0, buyTotal: 0, sellTotal: 0, profit: 0 },
      })
    } catch (error) {
      logger.error('CashDeskPage', 'Adatok betöltése sikertelen:', error)
      toast.error('Hiba', 'Pénztár adatok betöltése sikertelen')
    } finally {
      loadingRef.current = false
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  // Pénzkészlet automatikus frissítése:
  // 1. Amikor a felhasználó visszanavigál erre az oldalra (visibility change)
  // 2. Periodikus polling (30 másodpercenként) — a tranzakciók backend-oldalon
  //    frissítik a cash_balance-t, de a frontend erről nem kap push notifikációt.
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        void loadData()
      }
    }
    document.addEventListener('visibilitychange', handleVisibilityChange)

    // Focus event: a felhasználó visszakattint az ablakra (pl. Electron)
    const handleFocus = () => { void loadData() }
    window.addEventListener('focus', handleFocus)

    const interval = setInterval(() => {
      if (document.visibilityState === 'visible') void loadData()
    }, CASHDESK_REFRESH_INTERVAL_MS)

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange)
      window.removeEventListener('focus', handleFocus)
      clearInterval(interval)
    }
  }, [loadData])

  const getBalanceStatus = (balance: number, min: number, max: number) => {
    if (balance < min) return 'low'
    if (balance > max) return 'high'
    return 'ok'
  }

  const handleMovement = async () => {
    const amount = parseFloat(movementAmount)
    if (!amount || amount <= 0) {
      toast.warning('Érvénytelen összeg', 'Adjon meg pozitív összeget')
      return
    }
    try {
      const currencyBalance = status.balances.find(b => b.currency === movementCurrency)
      if (!currencyBalance) {
        toast.error('Hiba', 'Ismeretlen valutanem')
        return
      }
      await cashBalanceApi.adjust({
        currencyId: currencyBalance.currencyId,
        amount,
        incoming: movementType === 'in',
        reason: `${movementType === 'in' ? 'Bevét' : 'Kiadás'}: ${amount} ${movementCurrency}`,
      })
      toast.success('Sikeres', `${movementType === 'in' ? 'Bevét' : 'Kiadás'} rögzítve`)
      setShowMovementDialog(false)
      setMovementAmount('')
      void loadData()
    } catch (error) {
      logger.error('CashDeskPage', 'Pénzmozgás hiba:', error)
      toast.error('Hiba', 'Pénzmozgás rögzítése sikertelen')
    }
  }

  const handleBalanceDetails = async (item: CashDeskBalanceItem) => {
    setDetailLoadingCurrency(item.currency)
    setDetailError(null)
    try {
      const [byId, byCode] = await Promise.all([
        cashBalanceApi.getByCurrencyId(item.currencyId),
        cashBalanceApi.getByCurrencyCode(item.currency),
      ])
      setSelectedBalance(byId)
      setCodeCheckBalance(byCode)
    } catch (error) {
      logger.error('CashDeskPage', 'Pénzkészlet részlet betöltése sikertelen:', error)
      setDetailError(`${item.currency} részletek betöltése sikertelen`)
      toast.error('Hiba', 'Pénzkészlet részletek betöltése sikertelen')
    } finally {
      setDetailLoadingCurrency(null)
    }
  }

  const fallbackHufBalance = status.balances.find((item) => item.currency === 'HUF')?.balance ?? 0
  const codeCheckMatches =
    !!selectedBalance
    && !!codeCheckBalance
    && selectedBalance.currencyId === codeCheckBalance.currencyId
    && selectedBalance.currencyCode === codeCheckBalance.currencyCode
  const selectedBalanceTitle = selectedBalance
    ? `${selectedBalance.currencyCode} ${cashDeskLabels.detailSuffix}`
    : ''

  return (
    <div className="space-y-2">
      {/* Compact header — title + actions in one row */}
      <div className="flex justify-between items-center">
        <h1 className="text-base font-bold text-gray-800 flex items-center gap-2">
          <Vault size={18} />
          {t('branch.branch')}
        </h1>
        <div className="flex gap-1.5">
          <button
            onClick={() => navigate('/closing/wizard')}
            className="form-button-primary flex items-center gap-1 h-7 text-xs px-2"
          >
            <FileCheck size={14} />
            {t('misc.napiZaras')}
          </button>
          {status.isOpen ? (
            <button className="form-button flex items-center gap-1 text-red-600 h-7 text-xs px-2">
              <Lock size={14} />
              {t('cashdesk.penztarZaras')}
            </button>
          ) : (
            <button className="form-button-primary flex items-center gap-1 h-7 text-xs px-2">
              <Unlock size={14} />
              {t('cashdesk.penztarNyitas')}
            </button>
          )}
        </div>
      </div>

      {/* Status Banner — compact */}
      <div className={`form-panel flex items-center justify-between px-3 py-1.5 ${
        status.isOpen ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'
      }`}>
        <div className="flex items-center gap-1.5">
          {status.isOpen ? (
            <>
              <CheckCircle className="text-green-600" size={16} />
              <span className="text-green-800 font-semibold text-sm">{t('cashdesk.penztarNyitva')}</span>
            </>
          ) : (
            <>
              <Lock className="text-red-600" size={16} />
              <span className="text-red-800 font-semibold text-sm">{t('cashdesk.penztarZarva')}</span>
            </>
          )}
        </div>
        <div className="text-xs text-gray-600 flex items-center gap-3">
          <span className="flex items-center gap-1">
            <Clock size={12} />
            {/* v2.3.38 (B12 audit fix): ISO timestamp -> hu-HU formatum (NEM raw "2026-04-29T11:43:07.623294") */}
            {t('cashdesk.nyitva')}{formatOpenedAtTimestamp(status.openedAt)}
          </span>
          {/* v2.3.42 (Sourcery #303): ures string-et is missing-kent kezeljuk
              (a `??` csak null/undefined fallback, NEM ures string) */}
          <span>{t('cashdesk.kezelo')}{status.openedBy?.trim() ? status.openedBy : '—'}</span>
        </div>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-2">
        <div className="form-panel p-2">
          <div className="text-[10px] text-gray-500 uppercase">{cashDeskLabels.currencies}</div>
          <div className="text-base font-bold text-gray-900">{summary?.totalCurrencies ?? status.balances.length}</div>
        </div>
        <div className="form-panel p-2">
          <div className="text-[10px] text-gray-500 uppercase">{cashDeskLabels.hufStock}</div>
          <div className="text-base font-bold text-gray-900">
            {(summary?.hufBalance ?? fallbackHufBalance).toLocaleString('hu-HU')} {t('common.ft')}
          </div>
        </div>
        <div className="form-panel p-2">
          <div className="text-[10px] text-gray-500 uppercase">{cashDeskLabels.lowAlert}</div>
          <div className="text-base font-bold text-orange-700">{summary?.lowBalanceAlerts ?? 0}</div>
        </div>
        <div className="form-panel p-2">
          <div className="text-[10px] text-gray-500 uppercase">{cashDeskLabels.highAlert}</div>
          <div className="text-base font-bold text-yellow-700">{summary?.highBalanceAlerts ?? 0}</div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-2">
        {/* Cash Balances — compact table layout */}
        <div className="lg:col-span-2 form-panel p-0">
          <div className="flex justify-between items-center px-3 py-1.5 border-b border-gray-200">
            <h2 className="text-sm font-semibold text-gray-700">{t('cashdesk.penzkeszlet')}</h2>
            <div className="flex gap-1.5">
              <button
                onClick={() => { setMovementType('in'); setShowMovementDialog(true); }}
                className="form-button flex items-center gap-1 h-6 text-[11px] px-2"
              >
                <Plus size={12} />
                {t('cashdesk.bevet')}
              </button>
              <button
                onClick={() => { setMovementType('out'); setShowMovementDialog(true); }}
                className="form-button flex items-center gap-1 h-6 text-[11px] px-2"
              >
                <Minus size={12} />
                {t('cashdesk.kivet')}
              </button>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr className="text-[10px] uppercase text-gray-500">
                  <th className="px-3 py-1 text-left w-16">{t('common.currency')}</th>
                  <th className="px-2 py-1 text-right">{t('cashdesk.keszlet')}</th>
                  <th className="px-2 py-1 text-right text-gray-400 w-24">{t('cashdesk.minMax')}</th>
                  <th className="px-2 py-1 text-center w-16"><span className="sr-only">{t('common.status')}</span></th>
                </tr>
              </thead>
              <tbody>
                {status.balances.map((item, idx) => {
                  const balanceStatus = getBalanceStatus(item.balance, item.minBalance, item.maxBalance)
                  return (
                    <tr
                      key={item.currency}
                      className={`border-b border-gray-100 last:border-0 ${
                        balanceStatus === 'low' ? 'bg-orange-50' :
                        balanceStatus === 'high' ? 'bg-yellow-50' :
                        idx % 2 === 1 ? 'bg-gray-50/50' : ''
                      }`}
                    >
                      <td className="px-3 py-1">
                        <span className="font-mono font-bold text-sm">{item.currency}</span>
                      </td>
                      <td className="px-2 py-1 text-right">
                        <span className="font-mono font-bold text-sm">
                          {item.balance.toLocaleString('hu-HU')}
                        </span>
                      </td>
                      <td className="px-2 py-1 text-right text-[10px] text-gray-400 font-mono">
                        {item.minBalance.toLocaleString('hu-HU')} - {item.maxBalance.toLocaleString('hu-HU')}
                      </td>
                      <td className="px-2 py-1 text-center">
                        <div className="flex items-center justify-center gap-1">
                          {balanceStatus === 'low' && (
                            <span title={t('cashdesk.alacsonyKeszlet')}><AlertTriangle size={12} className="text-orange-500 inline" /></span>
                          )}
                          {balanceStatus === 'high' && (
                            <span title={t('cashdesk.magasKeszlet')}><AlertTriangle size={12} className="text-yellow-500 inline" /></span>
                          )}
                          <button
                            type="button"
                            onClick={() => void handleBalanceDetails(item)}
                            className="inline-flex h-5 w-5 items-center justify-center rounded border border-gray-200 text-blue-700 hover:bg-blue-50 disabled:opacity-50"
                            title={`${item.currency} részletek`}
                            aria-label={`${item.currency} részletek`}
                            disabled={detailLoadingCurrency === item.currency}
                          >
                            <Info size={12} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
          {detailError && (
            <div className="px-3 py-2 text-xs text-red-700 bg-red-50 border-t border-red-100">{detailError}</div>
          )}
        </div>

        {/* Today's Stats — compact */}
        <div className="form-panel p-2">
          <h2 className="text-sm font-semibold text-gray-700 mb-1.5">{t('cashdesk.maiStatisztika')}</h2>
          <div className="space-y-1.5">
            <div className="bg-blue-50 px-2.5 py-1.5 rounded">
              <div className="text-[10px] text-blue-600">{t('archiving.tranzakciok')}</div>
              <div className="text-base font-bold text-blue-800">{status.todayStats.transactions}</div>
            </div>
            <div className="bg-green-50 px-2.5 py-1.5 rounded">
              <div className="text-[10px] text-green-600">{t('cashdesk.vetelOsszesen')}</div>
              <div className="text-sm font-bold text-green-800">
                {status.todayStats.buyTotal.toLocaleString('hu-HU')} {t('common.ft')}
              </div>
            </div>
            <div className="bg-red-50 px-2.5 py-1.5 rounded">
              <div className="text-[10px] text-red-600">{t('cashdesk.eladasOsszesen')}</div>
              <div className="text-sm font-bold text-red-800">
                {status.todayStats.sellTotal.toLocaleString('hu-HU')} {t('common.ft')}
              </div>
            </div>
            <div className="bg-purple-50 px-2.5 py-1.5 rounded">
              <div className="text-[10px] text-purple-600">{t('cashdesk.napiEredmeny')}</div>
              <div className="text-sm font-bold text-purple-800">
                {status.todayStats.profit.toLocaleString('hu-HU')} {t('common.ft')}
              </div>
            </div>
          </div>
        </div>
      </div>

      {selectedBalance && (
        <div className="form-panel p-2">
          <div className="flex items-start justify-between gap-2 border-b border-gray-200 pb-1.5">
            <div>
              <h2 className="text-sm font-semibold text-gray-700">
                {selectedBalanceTitle}
              </h2>
              <div className="text-[11px] text-gray-500">
                {selectedBalance.currencyName ?? 'Valuta'} - {selectedBalance.branchName ?? 'Aktuális pénztár'}
              </div>
            </div>
            <button
              type="button"
              onClick={() => {
                setSelectedBalance(null)
                setCodeCheckBalance(null)
              }}
              className="inline-flex h-7 w-7 items-center justify-center rounded border border-gray-200 text-gray-600 hover:bg-gray-50"
              title="Részletek bezárása"
              aria-label="Részletek bezárása"
            >
              <X size={14} />
            </button>
          </div>
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-2 pt-2 text-xs">
            <div>
              <div className="text-gray-500">{cashDeskLabels.current}</div>
              <div className="font-mono font-bold text-gray-900">{selectedBalance.currentBalance.toLocaleString('hu-HU')}</div>
            </div>
            <div>
              <div className="text-gray-500">{cashDeskLabels.opening}</div>
              <div className="font-mono font-bold text-gray-900">{selectedBalance.openingBalance.toLocaleString('hu-HU')}</div>
            </div>
            <div>
              <div className="text-gray-500">{cashDeskLabels.dailyChange}</div>
              <div className="font-mono font-bold text-gray-900">{(selectedBalance.dailyChange ?? 0).toLocaleString('hu-HU')}</div>
            </div>
            <div>
              <div className="text-gray-500">{cashDeskLabels.limit}</div>
              <div className="font-mono font-bold text-gray-900">
                {(selectedBalance.minBalance ?? 0).toLocaleString('hu-HU')} - {(selectedBalance.maxBalance ?? 0).toLocaleString('hu-HU')}
              </div>
            </div>
            <div>
              <div className="text-gray-500">{cashDeskLabels.codeCheck}</div>
              <div className={`font-semibold ${codeCheckMatches ? 'text-green-700' : 'text-orange-700'}`}>
                {codeCheckMatches ? cashDeskLabels.codeCheckOk : cashDeskLabels.codeCheckMismatch}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Denomination Panel — compact */}
      <div className="form-panel p-2">
        <h2 className="text-sm font-semibold text-gray-700 mb-1">{t('cashdesk.cimletekHuf')}</h2>
        <div className="grid grid-cols-8 gap-1.5">
          {[20000, 10000, 5000, 2000, 1000, 500, 200, 100].map((denom) => (
            <div key={denom} className="text-center p-1 bg-gray-50 rounded border">
              <div className="text-xs font-semibold font-mono">{denom.toLocaleString('hu-HU')}</div>
              <NumberInput
                value="0,00"
                onChange={() => {}}
                className="form-input w-full text-center text-xs mt-0.5 py-0.5"
                allowDecimals={true}
                allowNegative={false}
                min={0}
                step="0.01"
              />
            </div>
          ))}
        </div>
      </div>

      {/* Movement Dialog */}
      {showMovementDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl p-4 w-96">
            <h3 className="text-lg font-bold mb-4">
              {movementType === 'in' ? 'Pénz bevét' : 'Pénz kivét'}
            </h3>
            <div className="space-y-3">
              <div>
                <label className="form-label">{t('common.currency')}</label>
                <select
                  value={movementCurrency}
                  onChange={(e) => setMovementCurrency(e.target.value)}
                  className="form-input"
                >
                  <option value="HUF">{t('cashdesk.hufMagyarForint')}</option>
                  <option value="EUR">{t('cashdesk.eurEuro')}</option>
                  <option value="USD">{t('cashdesk.usdUsaDollar')}</option>
                  <option value="GBP">{t('cashdesk.gbpAngolFont')}</option>
                  <option value="CHF">{t('cashdesk.chfSvajciFrank')}</option>
                </select>
              </div>
              <div>
                <label className="form-label">{t('common.amount')}</label>
                <NumberInput
                  value={movementAmount}
                  onChange={(val) => setMovementAmount(val)}
                  className="form-input"
                  placeholder="0,00"
                  allowDecimals={true}
                  allowNegative={false}
                  min={0}
                  step="0.01"
                />
              </div>
              <div>
                <label className="form-label">{t('common.note')}</label>
                <textarea className="form-input" rows={2} placeholder="Opcionális..." />
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-4">
              <button
                onClick={() => setShowMovementDialog(false)}
                className="form-button"
              >
                {t('common.cancel')}
              </button>
              <button
                onClick={handleMovement}
                className="form-button-primary"
              >
                {movementType === 'in' ? 'Bevételezés' : 'Kivételezés'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
