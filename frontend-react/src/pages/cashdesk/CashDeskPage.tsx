import { useState, useEffect, useCallback, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { Vault, Lock, CheckCircle, Clock, FileCheck, X } from 'lucide-react'
import { cashBalanceApi, dailySessionApi } from '../../services/api/index'
import type {
  BranchBalanceSummary,
  CashBalance,
  DailySession,
  TodayStats,
} from '../../services/api/index'
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
  todayStats: TodayStats
}

/**
 * FK-075 FR-5/FR-6 (2026-08-06): a Mai statisztika panel adatai mostantól az új,
 * dedikált GET /cash-balances/today-stats végpontról érkeznek (élő, tranzakció-alapú
 * összesítés), NEM a tárolt napi-munkamenet-számlálókból. Hiba esetén nullázott
 * értékkel folytatjuk ( ugyanaz a hibaturő minta, mint a többi loadData hívás).
 */
const EMPTY_TODAY_STATS: TodayStats = {
  transactions: 0,
  buyTotal: 0,
  sellTotal: 0,
  handlingFee: 0,
}

const cashDeskLabels = {
  currencies: 'Valuták',
  hufStock: 'HUF készlet',
  detailSuffix: 'pénzkészlet részletek',
  current: 'Aktuális',
  opening: 'Nyitó',
  dailyChange: 'Napi változás',
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
  if (isNaN(d.getTime())) return raw // fallback: raw if parse-fail
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
    todayStats: EMPTY_TODAY_STATS,
  })
  const [_loading, setLoading] = useState(true)
  const [summary, setSummary] = useState<BranchBalanceSummary | null>(null)
  const [selectedBalance, setSelectedBalance] = useState<CashBalance | null>(null)
  const [codeCheckBalance, setCodeCheckBalance] = useState<CashBalance | null>(null)
  // FK-075 TBD-3 (2026-08-06): a nyitott panel AZONOSÍTÓJA külön state-ben él, hogy a
  // 30 mp-es polling lista-frissülései csendben újratölthessék a részleteket.
  const [selectedCurrency, setSelectedCurrency] = useState<{
    currencyId: number
    currency: string
  } | null>(null)
  const [detailLoadingCurrency, setDetailLoadingCurrency] = useState<string | null>(null)
  const [detailError, setDetailError] = useState<string | null>(null)
  const loadingRef = useRef(false)
  // FK-075 TBD-3: a panel NYITÁSÁT kísérő első effect-futás kihagyása — a kattintáskori
  // fetchet a handleBalanceDetails már elvégezte (duplikált hívás nélkül).
  const detailRefreshPrimedRef = useRef(false)

  const loadData = useCallback(async () => {
    if (loadingRef.current) return
    loadingRef.current = true
    setLoading(true)
    try {
      // FK-075 FR-5/FR-6: a dailySessionApi.getCurrent() mostantól CSAK a
      // nyitva/zárva állapothoz kell (isOpen/openedAt/openedBy) — a Mai
      // statisztika adatait az új GET /cash-balances/today-stats adja.
      // (A GET /daily-sessions/current-ot más felület, pl. MainLayout is
      // használja, ezért nem módosítható — lásd FK-075 §7.)
      const [balances, session, branchSummary, todayStatsRaw]: [
        CashBalance[],
        DailySession | null,
        BranchBalanceSummary | null,
        TodayStats,
      ] = await Promise.all([
        cashBalanceApi.list().catch(() => [] as CashBalance[]),
        dailySessionApi.getCurrent().catch(() => null),
        cashBalanceApi.getSummary().catch(() => null),
        cashBalanceApi.getTodayStats().catch(() => EMPTY_TODAY_STATS),
      ])
      setSummary(branchSummary)

      // Védőháló: a mai-statisztika mezők mező-szintű normalizálása. A .catch() csak a
      // hálózati hibát kezeli; ha a végpont 200-zal, de nem a várt alakkal válaszol
      // (pl. E2E catch-all mock), a hiányzó szám-mezők undefined-ek lennének és a
      // .toLocaleString() render-crash-t okozna (FK-075, relay-full.spec tanulsága).
      const safeTodayStats: TodayStats = {
        transactions: todayStatsRaw.transactions ?? 0,
        buyTotal: todayStatsRaw.buyTotal ?? 0,
        sellTotal: todayStatsRaw.sellTotal ?? 0,
        handlingFee: todayStatsRaw.handlingFee ?? 0,
      }

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
        todayStats: safeTodayStats,
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
    const handleFocus = () => {
      void loadData()
    }
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

  // FK-075 FR-3: a min/max küszöbök backend-logikája megmarad (TILOS lista),
  // itt csak a sor színezéséhez használjuk — oszlop/ikon formájában nem jelenik meg.
  const getBalanceStatus = (balance: number, min: number, max: number) => {
    if (balance < min) return 'low'
    if (balance > max) return 'high'
    return 'ok'
  }

  const handleBalanceDetails = async (item: CashDeskBalanceItem) => {
    setDetailLoadingCurrency(item.currency)
    setDetailError(null)
    detailRefreshPrimedRef.current = false
    setSelectedCurrency({ currencyId: item.currencyId, currency: item.currency })
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

  // FK-075 TBD-3 (2026-08-06): a nyitott valuta-részletek panel KÖVESSE a 30 mp-es
  // pollingot. Korábban a panel a kattintáskori értékeket mutatta „befagyva", amíg a
  // felhasználó újra nem kattintott, miközben a fő lista már frissült. Most a fő lista
  // minden frissülésénél a kiválasztott valuta részletei is CSENDben újratöltődnek:
  // nincs loading-spinner és nincs hiba-toast sem (polling-hibánál a panel a legutóbbi
  // sikeres értéket tartja, és a következő kör próbálja újra).
  useEffect(() => {
    if (!selectedCurrency) {
      detailRefreshPrimedRef.current = false
      return
    }
    if (!detailRefreshPrimedRef.current) {
      // A nyitást kísérő első futás: a fetch már a handleBalanceDetails-ben megtörtént.
      detailRefreshPrimedRef.current = true
      return
    }
    let cancelled = false
    const refresh = async () => {
      try {
        const [byId, byCode] = await Promise.all([
          cashBalanceApi.getByCurrencyId(selectedCurrency.currencyId),
          cashBalanceApi.getByCurrencyCode(selectedCurrency.currency),
        ])
        if (!cancelled) {
          setSelectedBalance(byId)
          setCodeCheckBalance(byCode)
          // A sikeres frissítés törli az esetleges korábbi betöltési hibajelzést
          // (ellenkező esetben a hibaüzenet a friss adatok mellett is látszana).
          setDetailError(null)
        }
      } catch {
        // Szándékosan csendben: a következő polling-kör újra próbálja.
      }
    }
    void refresh()
    return () => {
      cancelled = true
    }
  }, [status.balances, selectedCurrency])

  const fallbackHufBalance = status.balances.find((item) => item.currency === 'HUF')?.balance ?? 0
  const codeCheckMatches =
    !!selectedBalance &&
    !!codeCheckBalance &&
    selectedBalance.currencyId === codeCheckBalance.currencyId &&
    selectedBalance.currencyCode === codeCheckBalance.currencyCode
  const selectedBalanceTitle = selectedBalance
    ? `${selectedBalance.currencyCode} ${cashDeskLabels.detailSuffix}`
    : ''

  return (
    <div className="space-y-2">
      {/* Compact header — title + actions in one row */}
      <div className="flex justify-between items-center">
        <h1 className="text-base font-bold text-gray-800 flex items-center gap-2">
          <Vault size={18} />
          {t('cashdesk.pageTitle')}
        </h1>
        <div className="flex gap-1.5">
          {/* FK-075 FR-8: "Pénztár zárás"/"Pénztár nyitás" eltávolítva, "Napi zárás" marad */}
          <button
            onClick={() => navigate('/closing/wizard')}
            className="form-button-primary flex items-center gap-1 h-7 text-xs px-2"
          >
            <FileCheck size={14} />
            {t('misc.napiZaras')}
          </button>
        </div>
      </div>

      {/* Status Banner — compact */}
      <div
        className={`form-panel flex items-center justify-between px-3 py-1.5 ${
          status.isOpen ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'
        }`}
      >
        <div className="flex items-center gap-1.5">
          {status.isOpen ? (
            <>
              <CheckCircle className="text-green-600" size={16} />
              <span className="text-green-800 font-semibold text-sm">
                {t('cashdesk.penztarNyitva')}
              </span>
            </>
          ) : (
            <>
              <Lock className="text-red-600" size={16} />
              <span className="text-red-800 font-semibold text-sm">
                {t('cashdesk.penztarZarva')}
              </span>
            </>
          )}
        </div>
        <div className="text-xs text-gray-600 flex items-center gap-3">
          <span className="flex items-center gap-1">
            <Clock size={12} />
            {/* v2.3.38 (B12 audit fix): ISO timestamp -> hu-HU formatum (NEM raw "2026-04-29T11:43:07.623294") */}
            {t('cashdesk.nyitva')}
            {formatOpenedAtTimestamp(status.openedAt)}
          </span>
          {/* v2.3.42 (Sourcery #303): ures string-et is missing-kent kezeljuk
              (a `??` csak null/undefined fallback, NEM ures string) */}
          <span>
            {t('cashdesk.kezelo')}
            {status.openedBy?.trim() ? status.openedBy : '—'}
          </span>
        </div>
      </div>

      {/* FK-075 FR-2: "Alacsony jelzés"/"Magas jelzés" csempék eltávolítva — 2 oszlopos rács */}
      <div className="grid grid-cols-2 gap-2">
        <div className="form-panel p-2">
          <div className="text-[10px] text-gray-500 uppercase">{cashDeskLabels.currencies}</div>
          <div className="text-base font-bold text-gray-900">
            {summary?.totalCurrencies ?? status.balances.length}
          </div>
        </div>
        <div className="form-panel p-2">
          <div className="text-[10px] text-gray-500 uppercase">{cashDeskLabels.hufStock}</div>
          <div className="text-base font-bold text-gray-900">
            {(summary?.hufBalance ?? fallbackHufBalance).toLocaleString('hu-HU')} {t('common.ft')}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-2">
        {/* Cash Balances — compact table layout */}
        <div className="lg:col-span-2 form-panel p-0">
          <div className="flex justify-between items-center px-3 py-1.5 border-b border-gray-200">
            <h2 className="text-sm font-semibold text-gray-700">{t('cashdesk.penzkeszlet')}</h2>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr className="text-[10px] uppercase text-gray-500">
                  <th className="px-3 py-1 text-left w-16">{t('common.currency')}</th>
                  <th className="px-2 py-1 text-right">{t('cashdesk.keszlet')}</th>
                </tr>
              </thead>
              <tbody>
                {status.balances.map((item, idx) => {
                  const balanceStatus = getBalanceStatus(
                    item.balance,
                    item.minBalance,
                    item.maxBalance,
                  )
                  const isDetailLoading = detailLoadingCurrency === item.currency
                  return (
                    // FK-075 FR-3: MIN-MAX oszlop és (i) info-oszlop eltávolítva;
                    // a teljes sor kattintható (cursor-pointer + hover-kiemelés),
                    // az alacsony/magas sor-színezés megmarad. Betöltés alatt a
                    // kattintás no-op (korábbi disabled-gomb viselkedés).
                    <tr
                      key={item.currency}
                      onClick={() => {
                        if (!isDetailLoading) void handleBalanceDetails(item)
                      }}
                      title={`${item.currency} részletek`}
                      className={`border-b border-gray-100 last:border-0 cursor-pointer hover:bg-gray-100 ${
                        balanceStatus === 'low'
                          ? 'bg-orange-50'
                          : balanceStatus === 'high'
                            ? 'bg-yellow-50'
                            : idx % 2 === 1
                              ? 'bg-gray-50'
                              : ''
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
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
          {detailError && (
            <div className="px-3 py-2 text-xs text-red-700 bg-red-50 border-t border-red-100">
              {detailError}
            </div>
          )}
        </div>

        {/* Today's Stats — compact */}
        <div className="form-panel p-2">
          <h2 className="text-sm font-semibold text-gray-700 mb-1.5">
            {t('cashdesk.maiStatisztika')}
          </h2>
          <div className="space-y-1.5">
            <div className="bg-blue-50 px-2.5 py-1.5 rounded">
              <div className="text-[10px] text-blue-600">{t('archiving.tranzakciok')}</div>
              <div className="text-base font-bold text-blue-800">
                {status.todayStats.transactions}
              </div>
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
            {/* FK-075 FR-6: "Napi eredmény" -> "Beszedett kezelési díj", élő értékkel */}
            <div className="bg-purple-50 px-2.5 py-1.5 rounded">
              <div className="text-[10px] text-purple-600">
                {t('cashdesk.beszedettKezelesiDij')}
              </div>
              <div className="text-sm font-bold text-purple-800">
                {status.todayStats.handlingFee.toLocaleString('hu-HU')} {t('common.ft')}
              </div>
            </div>
          </div>
        </div>
      </div>

      {selectedBalance && (
        <div className="form-panel p-2">
          <div className="flex items-start justify-between gap-2 border-b border-gray-200 pb-1.5">
            <div>
              <h2 className="text-sm font-semibold text-gray-700">{selectedBalanceTitle}</h2>
              <div className="text-[11px] text-gray-500">
                {selectedBalance.currencyName ?? 'Valuta'} -{' '}
                {selectedBalance.branchName ?? 'Aktuális pénztár'}
              </div>
            </div>
            <button
              type="button"
              onClick={() => {
                setSelectedBalance(null)
                setCodeCheckBalance(null)
                setSelectedCurrency(null)
              }}
              className="inline-flex h-7 w-7 items-center justify-center rounded border border-gray-200 text-gray-600 hover:bg-gray-50"
              title="Részletek bezárása"
              aria-label="Részletek bezárása"
            >
              <X size={14} />
            </button>
          </div>
          {/* FK-075 FR-4: "Limit" mező eltávolítva — 4 oszlopos rács */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 pt-2 text-xs">
            <div>
              <div className="text-gray-500">{cashDeskLabels.current}</div>
              <div className="font-mono font-bold text-gray-900">
                {selectedBalance.currentBalance.toLocaleString('hu-HU')}
              </div>
            </div>
            <div>
              <div className="text-gray-500">{cashDeskLabels.opening}</div>
              <div className="font-mono font-bold text-gray-900">
                {selectedBalance.openingBalance.toLocaleString('hu-HU')}
              </div>
            </div>
            <div>
              <div className="text-gray-500">{cashDeskLabels.dailyChange}</div>
              <div className="font-mono font-bold text-gray-900">
                {(selectedBalance.dailyChange ?? 0).toLocaleString('hu-HU')}
              </div>
            </div>
            <div>
              <div className="text-gray-500">{cashDeskLabels.codeCheck}</div>
              <div
                className={`font-semibold ${codeCheckMatches ? 'text-green-700' : 'text-orange-700'}`}
              >
                {codeCheckMatches ? cashDeskLabels.codeCheckOk : cashDeskLabels.codeCheckMismatch}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
