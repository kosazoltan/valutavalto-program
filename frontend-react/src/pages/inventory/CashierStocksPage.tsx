import { useState, useEffect, useCallback, useMemo } from 'react'
import {
  Download,
  Package,
  Search,
  RefreshCw,
  AlertTriangle,
  Wallet,
  MapPin,
  Printer,
} from 'lucide-react'
import {
  api,
  branchApi,
  currencyApi,
  exchangeRateApi,
  Currency,
  type ExchangeRate,
  type BranchInfo,
} from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { useAppMode } from '../../hooks/useAppMode'
import i18n from '../../i18n'

interface InventoryItem {
  id: string | number
  branchId?: string
  currencyCode?: string
  branchName?: string
  currentBalance?: number
  lastUpdated?: string
}

interface BranchGroup {
  branchId?: string
  branchName: string
  items: InventoryItem[]
  hufTotal: number
  nonZeroCount: number
}

interface VaultStockRow {
  currencyCode: string
  currencyName?: string
  vaultTerritoryId?: string | null
  branchId?: string | null
  closing?: number
}

interface InventoryMovementRow {
  currencyCode?: string
  amount?: number
  hufValue?: number
  movementType?: string
}

interface TurnoverSummary {
  buyHuf: number
  sellHuf: number
}

function todayLocalIso(): string {
  const now = new Date()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  return `${now.getFullYear()}-${month}-${day}`
}

function formatClock(value: Date | null): string {
  if (!value) return '-'
  return value.toLocaleTimeString('hu-HU', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })
}

function roundHuf(value: number): number {
  return Math.round(value)
}

function formatBalance(value: number | undefined, currencyCode: string | undefined): string {
  if (typeof value !== 'number') return value ?? '-'
  if (currencyCode === 'HUF') return value.toLocaleString('hu-HU', { maximumFractionDigits: 0 })
  return value.toLocaleString('hu-HU', { maximumFractionDigits: 2 })
}

export default function CashierStocksPage() {
  const { t } = useTranslation()
  // FK-040: a főértéktári (full) mód a kártyás Országos készlet nézetet kapja; az értéktáros (ertektar)
  // és minden más mód a felső táblázatos részletet is. (appMode !== 'full' → értéktáros-viselkedés.)
  const { mode: appMode } = useAppMode()
  const [items, setItems] = useState<InventoryItem[]>([])
  // FK-008: az aktív valutanem-törzs (display_order szerint) — minden kártya EBBŐL épül,
  // így az értéktár-kártyák is a teljes listát mutatják (0 egyenleggel is), és az inaktív/ismeretlen
  // valuták (pl. TST – FK-007, DKK/NOK/SEK – FK-006) nem jelennek meg.
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [rates, setRates] = useState<ExchangeRate[]>([])
  const [vaultStockRows, setVaultStockRows] = useState<VaultStockRow[]>([])
  const [turnoverByBranch, setTurnoverByBranch] = useState<
    Map<string, Map<string, TurnoverSummary>>
  >(new Map())
  const [branchMeta, setBranchMeta] = useState<
    Map<string, { id?: string; region: string; isVault: boolean; vaultTerritoryId?: number | null }>
  >(new Map())
  const [vaultByRegion, setVaultByRegion] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedBranchId, setSelectedBranchId] = useState('ALL')
  const [lastRefreshAt, setLastRefreshAt] = useState<Date | null>(null)
  // FK-1: a pénztárválasztó legördülő a territory-scope-helyes my-territory listából épül (nem a stockból),
  // így a hívó Értéktáros területének MINDEN aktív pénztára megjelenik. Full módban üres (a felső rész rejtve).
  const [territoryCashiers, setTerritoryCashiers] = useState<BranchInfo[]>([])

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      // A készlet a kötelező adat; a valutanem-törzs best-effort (Copilot P2): ha a /currencies
      // elhasal, a stock attól még megjelenik (allItems → fallback a nyers sorokra).
      const today = todayLocalIso()
      // FK-040: full (főértéktár) módban a felső táblázat rejtve → az árfolyam (oszlopok) és a
      // forgalmi (movement-log) adatok feleslegesek, ezért nem is hívjuk őket (NFR-1 teljesítmény).
      const isFull = appMode === 'full'
      const [stockResult, currencyResult, ratesResult, vaultStockResult, territoryResult] =
        await Promise.allSettled([
          api.get<InventoryItem[]>('/inventory/stock'),
          currencyApi.list(),
          isFull ? Promise.resolve([] as ExchangeRate[]) : exchangeRateApi.list(),
          api.get<VaultStockRow[]>('/inventory/vault-stock'),
          // FK-1: a pénztárválasztó legördülő forrása (full módban rejtve → nem kérjük le).
          isFull ? Promise.resolve([] as BranchInfo[]) : branchApi.listMyTerritory(),
        ])
      if (stockResult.status === 'rejected') throw stockResult.reason
      const stockItems = safeArray<InventoryItem>(stockResult.value.data)
      setItems(stockItems)
      if (currencyResult.status === 'fulfilled') {
        setCurrencies(safeArray<Currency>(currencyResult.value))
      } else {
        logger.warn(
          'CashierStocksPage',
          'Valutanem-törzs betöltése sikertelen (teljes lista kihagyva)',
          currencyResult.reason,
        )
        setCurrencies([])
      }
      if (ratesResult.status === 'fulfilled') {
        setRates(safeArray<ExchangeRate>(ratesResult.value))
      } else {
        logger.warn(
          'CashierStocksPage',
          'Árfolyamok betöltése sikertelen (árfolyam oszlopok üresek)',
          ratesResult.reason,
        )
        setRates([])
      }
      if (vaultStockResult.status === 'fulfilled') {
        setVaultStockRows(safeArray<VaultStockRow>(vaultStockResult.value.data))
      } else {
        logger.warn(
          'CashierStocksPage',
          'Értéktári készlet betöltése sikertelen (értéktár-kártya 0-val marad)',
          vaultStockResult.reason,
        )
        setVaultStockRows([])
      }
      // FK-1: a legördülő a területi (my-territory) pénztárakból; az értéktár (isVault) nem pénztár.
      if (territoryResult.status === 'fulfilled') {
        setTerritoryCashiers(
          safeArray<BranchInfo>(territoryResult.value).filter((b) => b.isVault !== true),
        )
      } else {
        logger.warn(
          'CashierStocksPage',
          'Területi pénztárlista betöltése sikertelen (legördülő üres)',
          territoryResult.reason,
        )
        setTerritoryCashiers([])
      }

      // FK-040: a forgalmi (movement-log) lekérdezés csak az értéktáros felső táblázatához kell — full
      // módban kihagyjuk (a táblázat rejtve, NFR-1).
      if (isFull) {
        setTurnoverByBranch(new Map())
      } else {
        const branchIds = Array.from(
          new Set(
            stockItems.map((item) => item.branchId).filter((id): id is string => Boolean(id)),
          ),
        )
        const movementResults = await Promise.allSettled(
          branchIds.map(async (branchId) => {
            const response = await api.get<InventoryMovementRow[]>(
              '/inventory-movements/movement-log',
              {
                params: { branchId, date: today },
              },
            )
            return [branchId, safeArray<InventoryMovementRow>(response.data)] as const
          }),
        )
        const nextTurnover = new Map<string, Map<string, TurnoverSummary>>()
        for (const result of movementResults) {
          if (result.status === 'rejected') {
            logger.warn('CashierStocksPage', 'Forgalmi adatok betöltése sikertelen', result.reason)
            continue
          }
          const [branchId, rows] = result.value
          const byCurrency = new Map<string, TurnoverSummary>()
          for (const row of rows) {
            if (!row.currencyCode) continue
            const summary = byCurrency.get(row.currencyCode) ?? { buyHuf: 0, sellHuf: 0 }
            const hufValue = Number(row.hufValue ?? row.amount ?? 0)
            if (row.movementType === 'BANK_WITHDRAW') summary.buyHuf += hufValue
            if (row.movementType === 'BANK_DEPOSIT') summary.sellHuf += hufValue
            byCurrency.set(row.currencyCode, summary)
          }
          nextTurnover.set(branchId, byCurrency)
        }
        setTurnoverByBranch(nextTurnover)
      }
      setLastRefreshAt(new Date())
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('CashierStocksPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [appMode])

  // FK-002: a terület-besorolás (branch-törzsadat) betöltése KÜLÖN a fő készlet-loadtól
  // (Copilot #730) — ne tartsa loading-ban az oldalt, és hiba esetén üríti a map-eket,
  // hogy determinisztikusan visszaálljon a sima egy-grides nézet.
  const loadBranchMeta = useCallback(async () => {
    try {
      const branches = await branchApi.listActive()
      const meta = new Map<
        string,
        { id?: string; region: string; isVault: boolean; vaultTerritoryId?: number | null }
      >()
      const vaults = new Map<string, string>()
      for (const b of branches) {
        meta.set(b.name, {
          id: b.id,
          region: b.region ?? '',
          isVault: b.isVault === true,
          vaultTerritoryId: b.vaultTerritoryId,
        })
        if (b.isVault === true && b.region && !vaults.has(b.region)) vaults.set(b.region, b.name)
      }
      setBranchMeta(meta)
      setVaultByRegion(vaults)
    } catch (branchErr) {
      logger.warn(
        'CashierStocksPage',
        'Branch törzsadat betöltése sikertelen (területi csoportosítás kihagyva)',
        branchErr,
      )
      setBranchMeta(new Map())
      setVaultByRegion(new Map())
    }
  }, [])

  useEffect(() => {
    void loadData()
    void loadBranchMeta()
  }, [loadData, loadBranchMeta])

  useEffect(() => {
    const timer = window.setInterval(
      () => {
        void loadData()
        void loadBranchMeta()
      },
      10 * 60 * 1000,
    )
    return () => window.clearInterval(timer)
  }, [loadData, loadBranchMeta])

  // FK-008: a teljes készlet-mátrix a valutanem-törzsből építve. Minden branch (pénztár ÉS értéktár)
  // minden aktív valutára kap egy sort; az egyenleg a /inventory/stock-ból, ahol nincs → 0. Így az
  // értéktár-kártyák is a teljes listát mutatják, és csak az aktív valuták jelennek meg (TST/DKK/NOK/SEK
  // kizárva). A branch-univerzum KIZÁRÓLAG a /inventory/stock scope-szűrt soraiból jön (Codex P1):
  // a backend getAllStock() companyId + területi filterre szűr, a branchMeta (branchApi.listActive)
  // viszont GLOBÁLIS aktív lista — ha azt unionoznánk, egy területre korlátozott (pl. ERTEKTAR) user
  // idegen branch-eket látna (scope-szivárgás). A branchMeta CSAK régió/isVault metaadat marad.
  const allItems = useMemo<InventoryItem[]>(() => {
    if (currencies.length === 0) return items // törzs még tölt → fallback a nyers sorokra
    const balByBranch = new Map<string, Map<string, number>>()
    const branchIdByName = new Map<string, string>()
    for (const it of items) {
      if (!it.branchName || !it.currencyCode) continue
      let m = balByBranch.get(it.branchName)
      if (!m) {
        m = new Map<string, number>()
        balByBranch.set(it.branchName, m)
      }
      if (typeof it.currentBalance === 'number') m.set(it.currencyCode, it.currentBalance)
      if (it.branchId) branchIdByName.set(it.branchName, it.branchId)
    }
    const activeCodes = new Set(currencies.map((c) => c.code))
    const branchNames = new Set<string>(balByBranch.keys())
    const result: InventoryItem[] = []
    for (const branchName of branchNames) {
      const bal = balByBranch.get(branchName)
      for (const c of currencies) {
        result.push({
          id: `${branchName}|${c.code}`,
          branchId: branchIdByName.get(branchName),
          branchName,
          currencyCode: c.code,
          currentBalance: bal?.get(c.code) ?? 0,
        })
      }
      // Árva, NEM-nulla egyenleg egy inaktivált/ismeretlen valutában: nem rejtjük el (néma
      // adatvesztés ellen). A 0-egyenlegű árvák (pl. TST) kimaradnak — FK-007.
      if (bal) {
        for (const [code, balance] of bal) {
          if (!activeCodes.has(code) && balance !== 0) {
            result.push({
              id: `${branchName}|${code}`,
              branchId: branchIdByName.get(branchName),
              branchName,
              currencyCode: code,
              currentBalance: balance,
            })
          }
        }
      }
    }
    return result
  }, [items, currencies])

  const filtered = useMemo(() => {
    if (!searchTerm) return allItems
    const term = searchTerm.toLowerCase()
    return allItems.filter((item) =>
      Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term)),
    )
  }, [allItems, searchTerm])

  const branchGroups: BranchGroup[] = useMemo(() => {
    const map = new Map<string, BranchGroup>()
    for (const item of filtered) {
      const name = item.branchName ?? '(ismeretlen)'
      let group = map.get(name)
      if (!group) {
        group = {
          branchId: item.branchId,
          branchName: name,
          items: [],
          hufTotal: 0,
          nonZeroCount: 0,
        }
        map.set(name, group)
      }
      if (!group.branchId && item.branchId) group.branchId = item.branchId
      group.items.push(item)
      if (item.currencyCode === 'HUF' && typeof item.currentBalance === 'number') {
        group.hufTotal += item.currentBalance
      }
      if (typeof item.currentBalance === 'number' && item.currentBalance !== 0) {
        group.nonZeroCount += 1
      }
    }
    // FK-008: a valutanemek sorrendje a törzs display_order-je szerint (nem betűrend).
    const order = new Map<string, number>()
    currencies.forEach((c, i) => order.set(c.code, i))
    for (const group of map.values()) {
      group.items.sort(
        (a, b) =>
          (order.get(a.currencyCode ?? '') ?? 999) - (order.get(b.currencyCode ?? '') ?? 999),
      )
    }
    return Array.from(map.values()).sort((a, b) => b.hufTotal - a.hufTotal)
  }, [filtered, currencies])

  const grandTotalHuf = branchGroups.reduce((sum, g) => sum + g.hufTotal, 0)
  const totalBranches = branchGroups.length
  const totalNonZero = branchGroups.reduce((sum, g) => sum + g.nonZeroCount, 0)
  const ratesByCurrency = useMemo(
    () => new Map(rates.map((rate) => [rate.currencyCode, rate])),
    [rates],
  )
  const vaultStockByBranchCurrency = useMemo(() => {
    const map = new Map<string, number>()
    for (const row of vaultStockRows) {
      if (!row.branchId || !row.currencyCode) continue
      map.set(`${row.branchId}|${row.currencyCode}`, Number(row.closing ?? 0))
    }
    return map
  }, [vaultStockRows])

  // FK-1: a legördülő a territory-scope-helyes my-territory pénztárlistából épül (nem a stock-szűrt
  // branchGroups-ból), így a hívó Értéktáros területének MINDEN aktív pénztára megjelenik. Az értéktár
  // (isVault) kihagyva. Az id a branch UUID — a detailedRows ugyanezzel az id-vel szűr a stockból.
  const cashierOptions = useMemo(
    () =>
      territoryCashiers
        .filter((b) => b.isVault !== true)
        .map((b) => ({ id: b.id ?? b.name, name: b.name }))
        .filter((option) => option.id)
        .sort((a, b) => a.name.localeCompare(b.name, 'hu-HU')),
    [territoryCashiers],
  )

  const detailedRows = useMemo(() => {
    const selectedGroups =
      selectedBranchId === 'ALL'
        ? branchGroups.filter((group) => !branchMeta.get(group.branchName)?.isVault)
        : branchGroups.filter(
            (group) =>
              (group.branchId ?? branchMeta.get(group.branchName)?.id ?? group.branchName) ===
              selectedBranchId,
          )

    const stockByCurrency = new Map<string, number>()
    const turnoverByCurrency = new Map<string, TurnoverSummary>()
    for (const group of selectedGroups) {
      const branchId = group.branchId ?? branchMeta.get(group.branchName)?.id
      for (const item of group.items) {
        if (!item.currencyCode) continue
        stockByCurrency.set(
          item.currencyCode,
          (stockByCurrency.get(item.currencyCode) ?? 0) + Number(item.currentBalance ?? 0),
        )
      }
      if (branchId) {
        const branchTurnover = turnoverByBranch.get(branchId)
        if (branchTurnover) {
          for (const [currencyCode, summary] of branchTurnover.entries()) {
            const total = turnoverByCurrency.get(currencyCode) ?? { buyHuf: 0, sellHuf: 0 }
            total.buyHuf += summary.buyHuf
            total.sellHuf += summary.sellHuf
            turnoverByCurrency.set(currencyCode, total)
          }
        }
      }
    }

    const codes = new Set<string>([
      ...currencies.map((currency) => currency.code),
      ...stockByCurrency.keys(),
      ...turnoverByCurrency.keys(),
      ...ratesByCurrency.keys(),
    ])
    const order = new Map<string, number>()
    currencies.forEach((currency, index) => order.set(currency.code, index))
    return Array.from(codes)
      .sort((a, b) => (order.get(a) ?? 999) - (order.get(b) ?? 999) || a.localeCompare(b))
      .map((currencyCode) => ({
        currencyCode,
        stock: stockByCurrency.get(currencyCode) ?? 0,
        turnover: turnoverByCurrency.get(currencyCode) ?? { buyHuf: 0, sellHuf: 0 },
        rate: ratesByCurrency.get(currencyCode),
      }))
  }, [branchGroups, branchMeta, currencies, ratesByCurrency, selectedBranchId, turnoverByBranch])

  // FK-002: területenként csoportosítás (8 terület = 1 értéktár + pénztárai).
  const territories = useMemo(() => {
    const map = new Map<
      string,
      { regionKey: string; vaultName: string; groups: BranchGroup[]; hufTotal: number }
    >()
    for (const group of branchGroups) {
      const region = branchMeta.get(group.branchName)?.region || 'BESOROLATLAN'
      let terr = map.get(region)
      if (!terr) {
        terr = {
          regionKey: region,
          vaultName: vaultByRegion.get(region) ?? '',
          groups: [],
          hufTotal: 0,
        }
        map.set(region, terr)
      }
      terr.groups.push(group)
      terr.hufTotal += group.hufTotal
    }
    // FK-003: minden területi szekció ELEJÉN az értéktár kártyája. Ha a vaultnak nincs
    // készlet-csoportja (0 tétel), üres kártyát injektálunk, hogy mindig megjelenjen.
    for (const terr of map.values()) {
      if (!terr.vaultName) continue
      if (!terr.groups.some((g) => g.branchName === terr.vaultName)) {
        // FK-007: az üres (készletsor nélküli) értéktár-kártya is a központi aktív valutanem-törzsből
        // kapja a sorait, 0 egyenleggel — ne "0 valuta" üres kártyaként jelenjen meg, mint a pénztárak.
        // Ha a /currencies törzs még tölt (currencies üres), marad az üres fallback (best-effort).
        // A keresőszűrőt az injektált sorokra is alkalmazzuk (Codex/Copilot), hogy konzisztens legyen
        // a pénztárkártyák szűrésével; ha keresésnél egyetlen sor sem talál, a vault-kártyát nem injektáljuk.
        const term = searchTerm.trim().toLowerCase()
        const vaultBranchId = branchMeta.get(terr.vaultName)?.id
        const vaultItems: InventoryItem[] = currencies
          .map((c) => ({
            id: `${terr.vaultName}|${c.code}`,
            branchId: vaultBranchId,
            branchName: terr.vaultName,
            currencyCode: c.code,
            currentBalance: vaultBranchId
              ? (vaultStockByBranchCurrency.get(`${vaultBranchId}|${c.code}`) ?? 0)
              : 0,
          }))
          .filter(
            (it) =>
              !term ||
              it.branchName.toLowerCase().includes(term) ||
              it.currencyCode.toLowerCase().includes(term),
          )
        // Injektálunk, ha (a) van megjelenítendő (szűrt) valutasor, VAGY (b) a /currencies törzs még/nem
        // töltött (currencies üres) — ekkor a FK-003 „mindig látszik az értéktár-kártya" fallback marad
        // érvényben (üres kártyával). CSAK akkor hagyjuk ki, ha VAN törzs, de a keresés mindent kiszűrt.
        if (vaultItems.length > 0 || currencies.length === 0) {
          terr.groups.push({
            branchId: vaultBranchId,
            branchName: terr.vaultName,
            items: vaultItems,
            hufTotal: vaultItems
              .filter((item) => item.currencyCode === 'HUF')
              .reduce((sum, item) => sum + Number(item.currentBalance ?? 0), 0),
            nonZeroCount: vaultItems.filter((item) => Number(item.currentBalance ?? 0) !== 0)
              .length,
          })
        }
      }
      terr.groups.sort((a, b) => {
        // Copilot #763: komparátor-szerződés (antiszimmetria) — ha mindkettő a vault
        // (self-compare), 0-t kell adni, NEM -1-et.
        const av = a.branchName === terr.vaultName
        const bv = b.branchName === terr.vaultName
        if (av && bv) return 0
        if (av) return -1
        if (bv) return 1
        return b.hufTotal - a.hufTotal
      })
    }
    return Array.from(map.values()).sort((a, b) => b.hufTotal - a.hufTotal)
  }, [branchGroups, branchMeta, vaultByRegion, currencies, searchTerm, vaultStockByBranchCurrency])

  // Akkor csoportosítunk terület szerint, ha van értelmes besorolás (van branch-meta és
  // nem csak a "BESOROLATLAN" szekció létezik). Különben marad a sima, egy-grides nézet.
  const groupByTerritory =
    branchMeta.size > 0 &&
    !(territories.length === 1 && territories[0]?.regionKey === 'BESOROLATLAN')
  const selectedBranchName =
    selectedBranchId === 'ALL'
      ? 'Körzet összesen'
      : (cashierOptions.find((option) => option.id === selectedBranchId)?.name ??
        'Kiválasztott pénztár')

  return (
    <div className="space-y-2">
      <style>{`
        @media print {
          body * { visibility: hidden; }
          .cashier-stock-print, .cashier-stock-print * { visibility: visible; }
          .cashier-stock-print { position: absolute; left: 0; top: 0; width: 100%; }
          .no-print { display: none !important; }
        }
      `}</style>
      {/* Header + kereső */}
      <div className="no-print flex items-center justify-between gap-3 flex-wrap">
        <h1 className="form-title flex items-center gap-2 text-lg">
          <Package className="h-5 w-5" />
          {t('inventory.penztariKeszletek')}
        </h1>
        <div className="flex items-center gap-2 flex-1 max-w-md">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Keresés (valuta, pénztár)..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="form-input w-full pl-10 h-8 text-sm"
            />
          </div>
          <button
            onClick={() => {
              void loadData()
              void loadBranchMeta()
            }}
            className="form-button p-2"
            title="Frissítés"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {error && (
        <div className="no-print form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {/* FK-040: a felső táblázatos részlet (Részletes pénztári készlet) CSAK értéktáros (nem-full) módban
          jelenik meg; full (főértéktár) módban rejtve — ott az alsó kártyás Országos készlet a nézet. */}
      {appMode !== 'full' && (
        <section className="cashier-stock-print form-panel p-3">
          <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
            <div>
              <h2 className="text-sm font-bold text-secondary-900">
                {i18n.t('literals.reszletes-penztari-keszlet')}
              </h2>
              <p className="text-xs text-gray-500">
                {selectedBranchName}
                {i18n.t('literals.lit-9')}
                {todayLocalIso()}
                {i18n.t('literals.utolso-frissites')} {formatClock(lastRefreshAt)}
              </p>
            </div>
            <div className="no-print flex flex-wrap items-end gap-2">
              <label className="grid gap-1 text-xs font-semibold text-gray-600">
                {i18n.t('literals.penztar-2')}
                <select
                  className="form-input h-9 min-w-56"
                  value={selectedBranchId}
                  onChange={(event) => setSelectedBranchId(event.target.value)}
                >
                  <option value="ALL">{i18n.t('literals.korzet-osszesen')}</option>
                  {cashierOptions.map((option) => (
                    <option key={option.id} value={option.id}>
                      {option.name}
                    </option>
                  ))}
                </select>
              </label>
              <button
                onClick={() => {
                  void loadData()
                  void loadBranchMeta()
                }}
                className="form-button h-9 px-3"
                title="Frissítés"
              >
                <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
                {i18n.t('literals.frissites')}
              </button>
              <button
                onClick={() => window.print()}
                className="form-button h-9 px-3"
                title="Nyomtatás"
              >
                <Printer className="h-4 w-4" />
                {i18n.t('literals.nyomtatas')}
              </button>
              <button
                type="button"
                onClick={() => undefined}
                className="form-button h-9 px-3"
                title="MNB letöltése"
              >
                <Download className="h-4 w-4" />
                {i18n.t('literals.mnb-letoltese')}
              </button>
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[980px] text-xs">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50 text-left text-gray-600">
                  <th className="px-2 py-2">{i18n.t('literals.val')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.keszlet')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.forgalom-vetel')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.forgalom-eladas')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.arf-vetel')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.arf-eladas')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.elszamolo')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.1-kedv-vetel')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.1-kedv-eladas')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.2-kedv-vetel')}</th>
                  <th className="px-2 py-2 text-right">{i18n.t('literals.2-kedv-eladas')}</th>
                </tr>
              </thead>
              <tbody>
                {detailedRows.map((row) => {
                  const expired = row.rate?.validDate ? row.rate.validDate < todayLocalIso() : false
                  const rateClass = expired ? 'text-amber-700 font-semibold' : 'text-secondary-900'
                  return (
                    <tr key={row.currencyCode} className="border-b border-gray-100">
                      <td className="px-2 py-1.5 font-mono font-semibold">{row.currencyCode}</td>
                      <td className="px-2 py-1.5 text-right font-mono">
                        {formatBalance(row.stock, row.currencyCode)}
                      </td>
                      <td className="px-2 py-1.5 text-right font-mono">
                        {roundHuf(row.turnover.buyHuf).toLocaleString('hu-HU')}
                      </td>
                      <td className="px-2 py-1.5 text-right font-mono">
                        {roundHuf(row.turnover.sellHuf).toLocaleString('hu-HU')}
                      </td>
                      <td className={`px-2 py-1.5 text-right font-mono ${rateClass}`}>
                        {row.rate?.baseBuyRate?.toLocaleString('hu-HU') ?? '-'}
                      </td>
                      <td className={`px-2 py-1.5 text-right font-mono ${rateClass}`}>
                        {row.rate?.baseSellRate?.toLocaleString('hu-HU') ?? '-'}
                      </td>
                      <td className={`px-2 py-1.5 text-right font-mono ${rateClass}`}>
                        {row.rate?.officialRate?.toLocaleString('hu-HU') ?? '-'}
                      </td>
                      <td className={`px-2 py-1.5 text-right font-mono ${rateClass}`}>
                        {row.rate?.limit1BuyRate?.toLocaleString('hu-HU') ?? '-'}
                      </td>
                      <td className={`px-2 py-1.5 text-right font-mono ${rateClass}`}>
                        {row.rate?.limit1SellRate?.toLocaleString('hu-HU') ?? '-'}
                      </td>
                      <td className={`px-2 py-1.5 text-right font-mono ${rateClass}`}>
                        {row.rate?.limit2BuyRate?.toLocaleString('hu-HU') ?? '-'}
                      </td>
                      <td className={`px-2 py-1.5 text-right font-mono ${rateClass}`}>
                        {row.rate?.limit2SellRate?.toLocaleString('hu-HU') ?? '-'}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {/* Összesen — kompakt sáv (FK-040: full módban is megmarad) */}
      <div
        className="no-print rounded-lg bg-gradient-to-br from-primary-50 to-primary-100 border border-primary-200 px-4 py-2"
        data-testid="inventory-summary-bar"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Wallet className="h-4 w-4 text-primary-700" />
            <span className="text-sm text-primary-700 font-medium">
              {t('inventory.osszesenHufKeszlet')}
            </span>
            <span className="text-xl font-bold font-mono text-primary-900">
              {grandTotalHuf.toLocaleString('hu-HU', { maximumFractionDigits: 0 })} {t('common.ft')}
            </span>
          </div>
          <span className="text-xs text-primary-600">
            <strong>{totalBranches}</strong> {t('inventory.penztar')}
            {i18n.t('literals.lit-9')}
            {totalNonZero} {t('inventory.aktivTetel')}
          </span>
        </div>
      </div>

      {/* Pénztáranként kártyák */}
      {loading && branchGroups.length === 0 ? (
        <div className="no-print form-panel text-center text-sm text-gray-500 py-8">
          {i18n.t('literals.betoltes')}
        </div>
      ) : branchGroups.length === 0 ? (
        <div className="no-print form-panel text-center text-sm text-gray-500 py-8">
          {t('common.noData')}
        </div>
      ) : groupByTerritory ? (
        /* FK-002: területi szekciók (terület / értéktár neve fejléccel) */
        <div className="no-print space-y-4">
          {territories.map((terr) => (
            <section key={terr.regionKey}>
              <div className="flex items-center gap-2 mb-1 px-1 py-1 border-b-2 border-primary-200">
                <MapPin className="h-4 w-4 text-primary-700" />
                <h2 className="font-bold text-secondary-900 text-sm">
                  {terr.regionKey}
                  {terr.vaultName && (
                    <span className="font-normal text-gray-500">
                      {i18n.t('literals.lit-9')}
                      {terr.vaultName}
                    </span>
                  )}
                </h2>
                <span className="ml-auto text-xs text-primary-700 font-mono">
                  {terr.hufTotal.toLocaleString('hu-HU', { maximumFractionDigits: 0 })}{' '}
                  {t('common.ft')}
                  <span className="text-gray-400">
                    {' '}
                    {i18n.t('literals.lit-38')}
                    {terr.groups.length} {t('inventory.penztar')}
                  </span>
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-2">
                {terr.groups.map((group) => (
                  <BranchCard
                    key={group.branchName}
                    group={group}
                    isVault={!!terr.vaultName && group.branchName === terr.vaultName}
                  />
                ))}
              </div>
            </section>
          ))}
        </div>
      ) : (
        <div className="no-print grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-2">
          {branchGroups.map((group) => (
            <BranchCard key={group.branchName} group={group} />
          ))}
        </div>
      )}
    </div>
  )
}

function BranchCard({ group, isVault = false }: { group: BranchGroup; isVault?: boolean }) {
  const { t } = useTranslation()
  // FK-003: az értéktár kártya vizuálisan elkülönül a pénztárkártyáktól (borostyán keret + háttér + ÉRTÉKTÁR jelvény).
  return (
    <div
      data-testid="branch-card"
      className={`form-panel p-2 hover:shadow-md transition-shadow ${isVault ? 'ring-2 ring-amber-400 bg-amber-50/60' : ''}`}
    >
      <div className="flex items-center justify-between mb-1 pb-1 border-b border-gray-200">
        <h3
          className="font-bold text-secondary-900 text-sm truncate flex-1 flex items-center gap-1"
          title={group.branchName}
        >
          {isVault && (
            <span className="text-[9px] font-bold uppercase bg-amber-500 text-white rounded px-1 py-px shrink-0">
              {i18n.t('literals.ertektar')}
            </span>
          )}
          <span className="truncate">{group.branchName}</span>
        </h3>
        <span className="text-[10px] text-gray-500 ml-1 shrink-0">
          {group.items.length} {t('inventory.valuta')}
        </span>
      </div>
      <table className="w-full text-xs">
        <tbody>
          {group.items.map((item) => {
            const isZero = !item.currentBalance || item.currentBalance === 0
            return (
              <tr key={`${item.id}`} className={isZero ? 'text-gray-400' : ''}>
                <td className="py-px font-mono font-semibold w-10">{item.currencyCode ?? '-'}</td>
                <td
                  className={`py-px text-right font-mono ${isZero ? '' : 'text-secondary-900 font-semibold'}`}
                >
                  {formatBalance(item.currentBalance, item.currencyCode)}
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
