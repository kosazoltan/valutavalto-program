import { useState, useEffect, useCallback, useRef } from 'react'
import { Vault, RefreshCw, AlertTriangle, Info, Printer } from 'lucide-react'
import { api, currencyApi, type Currency } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage, isNotFoundError } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'
import { useVaultStockUpdates } from '../../hooks/useVaultStockUpdates'
import i18n from '../../i18n'

/**
 * v2.4.9: Az "Értéktári készlet" oldal — KIZÁRÓLAG az értéktár saját készletét
 * mutatja, valutánként a napi flow-val (nyitó / átvett / átadott / záró).
 *
 * NEM a pénztárak készleteit — azok külön menüpontban: /cashier-stocks
 * (Pénztári készletek).
 *
 * 2026-06-17 (FR-1..6): KÜLÖNBSÉG + FRISSÍTVE oszlopok eltávolítva; zebra + pozitív
 * egyenleg kiemelés; nyomtatás; automatikus frissítés átadás-átvétel COMPLETED eseménynél
 * (WebSocket invalidáció + change-detection).
 */
interface VaultStockRow {
  currencyCode: string
  currencyName: string
  opening: number | null
  received: number | null
  issued: number | null
  closing: number | null
}

interface BanknoteInventoryRow {
  id: number
  currencyId?: number | null
  currencyCode: string
  faceValue: number
  quantity: number
  totalValue?: number | null
  minQuantity?: number | null
  maxQuantity?: number | null
  lowStock?: boolean
  overStock?: boolean
  lastCountedAt?: string | null
  lastCountedBy?: string | null
}

interface CashBalanceRow {
  branchId?: string | null
  branchName?: string | null
  currencyId?: number | string | null
  currencyCode?: string | null
  currencyName?: string | null
  currentBalance?: number | string | null
  openingBalance?: number | string | null
  lowBalanceAlert?: boolean
  highBalanceAlert?: boolean
}

interface StockMatrixDto {
  matrix?: Record<string, Record<string, number | string | null> | null> | null
}

interface InventoryMovementRow {
  id?: number | null
  fromBranchName?: string | null
  toBranchName?: string | null
  currencyCode?: string | null
  amount?: number | string | null
  statusDisplay?: string | null
  status?: string | null
  movementTypeDisplay?: string | null
  movementType?: string | null
  createdAt?: string | null
}

interface InventoryBalanceDto {
  currencyCode?: string | null
  openingBalance?: number | string | null
  closingBalance?: number | string | null
  totalIn?: number | string | null
  totalOut?: number | string | null
  date?: string | null
}

interface RegenerationResultDto {
  discrepancyCount?: number | null
  correctedCount?: number | null
  regeneratedAt?: string | null
  regeneratedByName?: string | null
}

type InventoryOperationType = 'bankWithdraw' | 'bankDeposit' | 'transfer' | 'correction'

interface InventoryCurrencyOption {
  id: number
  code: string
  name: string
}

interface TransferTargetOption {
  branchId: string
  code: string
  name: string
  isVault: boolean
}

function formatCurrency(value: number | null | undefined, code?: string): string {
  if (value == null) return '—'
  const opts: Intl.NumberFormatOptions =
    code === 'HUF' ? { maximumFractionDigits: 0 } : { maximumFractionDigits: 2 }
  return value.toLocaleString('hu-HU', opts)
}

function formatAmount(value: number | string | null | undefined, code?: string | null): string {
  if (value == null || value === '') return '—'
  const numeric = typeof value === 'number' ? value : Number(value)
  if (!Number.isFinite(numeric)) return String(value)
  return formatCurrency(numeric, code ?? undefined)
}

function num(value: number | string | null | undefined): number {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').replace(',', '.'))
  return Number.isFinite(parsed) ? parsed : 0
}

/** Change-detection kulcs: csak a megjelenített számszerű mezők számítanak. */
function serializeRows(rows: VaultStockRow[]): string {
  return JSON.stringify(
    rows.map((r) => [r.currencyCode, r.currencyName, r.opening, r.received, r.issued, r.closing]),
  )
}

/**
 * FK-037 (2026-06-20): 403 (jogosultság-hiány) felismerése AxiosError-import nélkül.
 * Az operatív készlet-riportok egy része vezetői végpont; a szűkebb szerepkörök (pl. Értéktáros)
 * ezeken 403-at kapnak — ez várt állapot, NEM valódi hiba, ezért nem dobunk rá hibabannert.
 */
const isForbiddenError = (reason: unknown): boolean =>
  typeof reason === 'object' &&
  reason !== null &&
  (reason as { response?: { status?: number } }).response?.status === 403

export default function InventoryPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((s) => s.worker)
  const [rows, setRows] = useState<VaultStockRow[]>([])
  const [banknoteRows, setBanknoteRows] = useState<BanknoteInventoryRow[]>([])
  const [lowStockRows, setLowStockRows] = useState<BanknoteInventoryRow[]>([])
  const [overStockRows, setOverStockRows] = useState<BanknoteInventoryRow[]>([])
  const [banknoteError, setBanknoteError] = useState<string | null>(null)
  const [banknoteActionMessage, setBanknoteActionMessage] = useState<string | null>(null)
  const [banknoteActionLoading, setBanknoteActionLoading] = useState(false)
  const [selectedBanknoteId, setSelectedBanknoteId] = useState<number | null>(null)
  const [banknoteQuantity, setBanknoteQuantity] = useState('1')
  const [thresholdMin, setThresholdMin] = useState('')
  const [thresholdMax, setThresholdMax] = useState('')
  const [branchStockRows, setBranchStockRows] = useState<CashBalanceRow[]>([])
  const [stockMatrixInfo, setStockMatrixInfo] = useState({ branches: 0, currencies: 0 })
  const [movementRows, setMovementRows] = useState<InventoryMovementRow[]>([])
  const [movementLogRows, setMovementLogRows] = useState<InventoryMovementRow[]>([])
  const [selectedMovementDetail, setSelectedMovementDetail] = useState<InventoryMovementRow | null>(
    null,
  )
  const [movementDetailLoadingId, setMovementDetailLoadingId] = useState<number | null>(null)
  const [inventoryOperationType, setInventoryOperationType] =
    useState<InventoryOperationType>('bankWithdraw')
  const [inventoryCurrencyId, setInventoryCurrencyId] = useState('')
  const [inventoryCurrencies, setInventoryCurrencies] = useState<InventoryCurrencyOption[]>([])
  const [inventoryCurrenciesLoading, setInventoryCurrenciesLoading] = useState(false)
  const [inventoryCurrenciesError, setInventoryCurrenciesError] = useState<string | null>(null)
  const [transferTargets, setTransferTargets] = useState<TransferTargetOption[]>([])
  const [transferTargetsLoading, setTransferTargetsLoading] = useState(false)
  const [transferTargetsLoaded, setTransferTargetsLoaded] = useState(false)
  const [transferTargetsError, setTransferTargetsError] = useState<string | null>(null)
  const [inventoryAmount, setInventoryAmount] = useState('')
  const [inventoryTargetBranchId, setInventoryTargetBranchId] = useState('')
  const [inventoryNotes, setInventoryNotes] = useState('')
  const [inventoryOperationMessage, setInventoryOperationMessage] = useState<string | null>(null)
  const [inventoryOperationLoading, setInventoryOperationLoading] = useState(false)
  const [movementActionId, setMovementActionId] = useState<string | null>(null)
  const [regenerationRunning, setRegenerationRunning] = useState(false)
  const [dailyBalance, setDailyBalance] = useState<InventoryBalanceDto | null>(null)
  const [lastRegeneration, setLastRegeneration] = useState<RegenerationResultDto | null>(null)
  const [operationalInventoryError, setOperationalInventoryError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null)

  // A WS-callback (refreshIfChanged) a legfrissebb sorokat ref-en keresztül éri el,
  // hogy ne épüljön újra a feliratkozás minden adatváltozásnál.
  const rowsRef = useRef<VaultStockRow[]>(rows)
  useEffect(() => {
    rowsRef.current = rows
  }, [rows])

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<VaultStockRow[]>('/inventory/vault-stock')
      setRows(safeArray<VaultStockRow>(response.data))
      setLastRefresh(new Date())
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Értéktári készlet betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  const loadBanknoteInventory = useCallback(async () => {
    if (!worker?.branchId) {
      setBanknoteRows([])
      setLowStockRows([])
      setOverStockRows([])
      setBanknoteError(null)
      return
    }

    try {
      setBanknoteError(null)
      const [inventoryResponse, lowResponse, overResponse] = await Promise.all([
        api.get<BanknoteInventoryRow[]>(`/banknote-inventory/branch/${worker.branchId}`),
        api.get<BanknoteInventoryRow[]>(`/banknote-inventory/branch/${worker.branchId}/low-stock`),
        api.get<BanknoteInventoryRow[]>(`/banknote-inventory/branch/${worker.branchId}/over-stock`),
      ])
      const nextRows = safeArray<BanknoteInventoryRow>(inventoryResponse.data)
      setBanknoteRows(nextRows)
      setLowStockRows(safeArray<BanknoteInventoryRow>(lowResponse.data))
      setOverStockRows(safeArray<BanknoteInventoryRow>(overResponse.data))
      setSelectedBanknoteId((current) => current ?? nextRows[0]?.id ?? null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Címletszintű készlet betöltési hiba:', err)
      setBanknoteError(msg)
      setBanknoteRows([])
      setLowStockRows([])
      setOverStockRows([])
    }
  }, [worker?.branchId])

  const loadInventoryCurrencies = useCallback(async () => {
    setInventoryCurrenciesLoading(true)
    setInventoryCurrenciesError(null)
    try {
      const data = await currencyApi.list()
      const options = safeArray<Currency>(data)
        .filter((currency) => currency.active !== false && currency.id != null)
        .map((currency) => ({
          id: Number(currency.id),
          code: currency.code,
          name: currency.name,
        }))
        .filter(
          (currency) => Number.isInteger(currency.id) && currency.id > 0 && Boolean(currency.code),
        )
      setInventoryCurrencies(options)
      setInventoryCurrencyId((current) => current || (options[0] ? String(options[0].id) : ''))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Devizalista betöltési hiba:', err)
      setInventoryCurrencies([])
      setInventoryCurrenciesError(msg)
    } finally {
      setInventoryCurrenciesLoading(false)
    }
  }, [])

  const loadTransferTargets = useCallback(async () => {
    if (transferTargetsLoaded || transferTargetsLoading) return
    setTransferTargetsLoading(true)
    setTransferTargetsError(null)
    try {
      const response = await api.get<TransferTargetOption[]>('/inventory/transfer-targets', {
        _skipGlobal403Toast: true,
      })
      const options = safeArray<TransferTargetOption>(response.data).filter((target) =>
        Boolean(target.branchId),
      )
      setTransferTargets(options)
      setInventoryTargetBranchId((current) => current || (options[0]?.branchId ?? ''))
      setTransferTargetsLoaded(true)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Transfer cél telephely lista betöltési hiba:', err)
      setTransferTargets([])
      setTransferTargetsError(msg)
      setTransferTargetsLoaded(true)
    } finally {
      setTransferTargetsLoading(false)
    }
  }, [transferTargetsLoaded, transferTargetsLoading])

  const loadOperationalInventory = useCallback(async () => {
    if (!worker?.branchId) {
      setBranchStockRows([])
      setStockMatrixInfo({ branches: 0, currencies: 0 })
      setMovementRows([])
      setMovementLogRows([])
      setDailyBalance(null)
      setLastRegeneration(null)
      setOperationalInventoryError(null)
      return
    }

    const date = new Date().toISOString().slice(0, 10)

    setOperationalInventoryError(null)
    // FK-037: Promise.allSettled — egyetlen részleges 403 NEM buktathatja el a többi, jogosult
    // adatot. Korábban (Promise.all) a /inventory/stock vagy /matrix 403-ja az egész blokkot
    // elbuktatta, így minden state 0-ra nullázódott, miközben az értéktári záró készlet a külön
    // /inventory/vault-stock hívásból (loadData) helyesen látszott — ez okozta a "220M Ft + minden 0"
    // ellentmondást. A `_skipGlobal403Toast` elnyomja a globális toast-ot (a 403-at itt kezeljük).
    const [
      branchStockResult,
      matrixResult,
      movementsResult,
      movementLogResult,
      dailyBalanceResult,
      regenerationResult,
    ] = await Promise.allSettled([
      api.get<CashBalanceRow[]>(`/inventory/stock/${worker.branchId}`, {
        _skipGlobal403Toast: true,
      }),
      api.get<StockMatrixDto>('/inventory/matrix', { _skipGlobal403Toast: true }),
      api.get<{ content?: InventoryMovementRow[] } | InventoryMovementRow[]>(
        '/inventory/movements',
        {
          params: { branchId: worker.branchId, size: 5, sort: 'createdAt,desc' },
          _skipGlobal403Toast: true,
        },
      ),
      api.get<InventoryMovementRow[]>('/inventory-movements/movement-log', {
        params: { branchId: worker.branchId, date },
        _skipGlobal403Toast: true,
      }),
      api.get<InventoryBalanceDto>('/inventory-movements/daily-balance', {
        params: { branchId: worker.branchId, date },
        _skipGlobal403Toast: true,
      }),
      api.get<RegenerationResultDto>('/inventory/regeneration/last', {
        params: { branchId: worker.branchId },
        _skipGlobal403Toast: true,
      }),
    ])

    if (branchStockResult.status === 'fulfilled') {
      const branchStockRows = safeArray<CashBalanceRow>(branchStockResult.value.data)
      setBranchStockRows(branchStockRows)
      const firstCurrencyId = branchStockRows.find((row) => row.currencyId != null)?.currencyId
      setInventoryCurrencyId(
        (current) => current || (firstCurrencyId == null ? '' : String(firstCurrencyId)),
      )
    } else {
      setBranchStockRows([])
    }

    if (matrixResult.status === 'fulfilled') {
      const matrix = matrixResult.value.data?.matrix ?? {}
      const currencyCodes = new Set<string>()
      Object.values(matrix).forEach((branchCurrencies) => {
        Object.keys(branchCurrencies ?? {}).forEach((code) => currencyCodes.add(code))
      })
      setStockMatrixInfo({ branches: Object.keys(matrix).length, currencies: currencyCodes.size })
    } else {
      setStockMatrixInfo({ branches: 0, currencies: 0 })
    }

    if (movementsResult.status === 'fulfilled') {
      const movementData = movementsResult.value.data
      const movementContent = Array.isArray(movementData) ? movementData : movementData?.content
      setMovementRows(safeArray<InventoryMovementRow>(movementContent))
    } else {
      setMovementRows([])
    }

    setMovementLogRows(
      movementLogResult.status === 'fulfilled'
        ? safeArray<InventoryMovementRow>(movementLogResult.value.data)
        : [],
    )
    setDailyBalance(
      dailyBalanceResult.status === 'fulfilled' ? (dailyBalanceResult.value.data ?? null) : null,
    )
    setLastRegeneration(
      regenerationResult.status === 'fulfilled' ? (regenerationResult.value.data ?? null) : null,
    )

    // Hibabanner CSAK valódi (nem-403) hibánál. A 403 (jogosultság-hiány) a szűkebb szerepköröknél
    // várt — ilyenkor a fenti widgetek üres/scope-szűkített állapotban maradnak, de a fő értéktári
    // záró készlet (külön /inventory/vault-stock, loadData) változatlanul helyes → nincs riasztó banner.
    const results = [
      branchStockResult,
      matrixResult,
      movementsResult,
      movementLogResult,
      dailyBalanceResult,
      regenerationResult,
    ]
    // FK-039 (2026-06-22): a /inventory/regeneration/last 404-et ad, ha az adott fiókon MÉG
    // sosem futott készlet-regenerálás — ez normál üres állapot (a „Mégsem regenerált" widget),
    // NEM betöltési hiba. A 404-et csak ennél az egy (opcionális) végpontnál nyomjuk el; a
    // regeneration egyéb hibái (pl. valódi 500) és a többi végpont 404/500-jai továbbra is
    // bannert dobnak. (Korábban ezt a 404-et a movement-log/daily-balance 500-ja elnyomta;
    // a backend CAST-fix után ez maradt volna az egyetlen látható „hiba".)
    const realFailure = results.find(
      (r): r is PromiseRejectedResult =>
        r.status === 'rejected' &&
        !isForbiddenError(r.reason) &&
        !(r === regenerationResult && isNotFoundError(r.reason)),
    )
    if (realFailure) {
      const msg = getErrorMessage(realFailure.reason)
      logger.error('InventoryPage', 'Készlet riportok betöltési hiba:', realFailure.reason)
      setOperationalInventoryError(msg)
    }
  }, [worker?.branchId])

  // FR-3: WebSocket-invalidációra csendben re-fetch, és CSAK akkor frissít, ha a
  // (territory-scope-olt) válasz ténylegesen változott → más iroda/értéktár mozgása
  // (ami a saját scope-olt nézetet nem érinti) nem okoz látható frissítést.
  // NFR-5: az automatikus frissítés hibája silent fail (nincs hibaüzenet).
  const refreshIfChanged = useCallback(async () => {
    try {
      const response = await api.get<VaultStockRow[]>('/inventory/vault-stock')
      const next = safeArray<VaultStockRow>(response.data)
      if (serializeRows(next) !== serializeRows(rowsRef.current)) {
        setRows(next)
        setLastRefresh(new Date())
      }
    } catch (err) {
      logger.debug('InventoryPage', 'Automatikus frissítés sikertelen (silent):', err)
    }
  }, [])

  useEffect(() => {
    void loadData()
    void loadBanknoteInventory()
    void loadOperationalInventory()
    void loadInventoryCurrencies()
  }, [loadData, loadBanknoteInventory, loadOperationalInventory, loadInventoryCurrencies])

  useEffect(() => {
    if (inventoryOperationType === 'transfer') {
      void loadTransferTargets()
    } else {
      setInventoryTargetBranchId('')
    }
  }, [inventoryOperationType, loadTransferTargets])

  useVaultStockUpdates(refreshIfChanged)

  const totalHufClosing = rows
    .filter((r) => r.currencyCode === 'HUF')
    .reduce((sum, r) => sum + (r.closing ?? 0), 0)
  const isVaultOperationalContext = rows.length > 0

  const selectedBanknote =
    banknoteRows.find((row) => row.id === selectedBanknoteId) ?? banknoteRows[0]
  const parsedBanknoteQuantity = Math.max(0, Number.parseInt(banknoteQuantity, 10) || 0)

  const runBanknoteAction = async (action: 'add' | 'remove' | 'count' | 'thresholds') => {
    if (!worker?.branchId || !selectedBanknote) {
      setBanknoteActionMessage('Nincs kiválasztott címletsor.')
      return
    }
    if (
      (action === 'add' || action === 'remove' || action === 'count') &&
      parsedBanknoteQuantity <= 0
    ) {
      setBanknoteActionMessage('Adj meg pozitív darabszámot.')
      return
    }

    setBanknoteActionLoading(true)
    setBanknoteActionMessage(null)
    try {
      if (action === 'add') {
        await api.post(`/banknote-inventory/branch/${worker.branchId}/add`, null, {
          params: {
            currencyId: selectedBanknote.currencyId,
            currencyCode: selectedBanknote.currencyCode,
            faceValue: selectedBanknote.faceValue,
            quantity: parsedBanknoteQuantity,
          },
        })
        setBanknoteActionMessage('Címletkészlet növelve.')
      } else if (action === 'remove') {
        await api.post(`/banknote-inventory/branch/${worker.branchId}/remove`, null, {
          params: {
            currencyId: selectedBanknote.currencyId,
            faceValue: selectedBanknote.faceValue,
            quantity: parsedBanknoteQuantity,
          },
        })
        setBanknoteActionMessage('Címletkészlet csökkentve.')
      } else if (action === 'count') {
        await api.post(`/banknote-inventory/${selectedBanknote.id}/count`, null, {
          params: {
            actualQuantity: parsedBanknoteQuantity,
            workerId: worker.workerCode ?? worker.id ?? '',
          },
        })
        setBanknoteActionMessage('Tényleges darabszám rögzítve.')
      } else {
        const minQuantity = thresholdMin.trim() ? Number.parseInt(thresholdMin, 10) : undefined
        const maxQuantity = thresholdMax.trim() ? Number.parseInt(thresholdMax, 10) : undefined
        await api.put(`/banknote-inventory/${selectedBanknote.id}/thresholds`, null, {
          params: { minQuantity, maxQuantity },
        })
        setBanknoteActionMessage('Címlet riasztási küszöbök mentve.')
      }
      await loadBanknoteInventory()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Címletszintű készlet művelet sikertelen:', err)
      setBanknoteActionMessage(msg)
    } finally {
      setBanknoteActionLoading(false)
    }
  }

  const loadMovementDetail = async (movementId: number | null | undefined) => {
    if (movementId == null) return
    try {
      setMovementDetailLoadingId(movementId)
      setOperationalInventoryError(null)
      const response = await api.get<InventoryMovementRow>(`/inventory/movements/${movementId}`)
      setSelectedMovementDetail(response.data ?? null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Készletmozgás részlet betöltési hiba:', err)
      setOperationalInventoryError(msg)
    } finally {
      setMovementDetailLoadingId(null)
    }
  }

  const parsedInventoryAmount = () => {
    const parsed = Number(String(inventoryAmount).replace(',', '.'))
    return Number.isFinite(parsed) && parsed >= 0 ? parsed : null
  }

  const parsedInventoryCurrencyId = () => {
    const parsed = Number(inventoryCurrencyId)
    return Number.isInteger(parsed) && parsed > 0 ? parsed : null
  }

  const submitInventoryOperation = async () => {
    const branchId = worker?.branchId
    const currencyId = parsedInventoryCurrencyId()
    const amount = parsedInventoryAmount()
    const notes = inventoryNotes.trim()

    if (!branchId) {
      setInventoryOperationMessage('Nincs saját telephely azonosító a készletművelethez.')
      return
    }
    if (currencyId == null) {
      setInventoryOperationMessage('Válassz devizát a listából.')
      return
    }
    if (amount == null || (inventoryOperationType !== 'correction' && amount <= 0)) {
      setInventoryOperationMessage('Adj meg érvényes, pozitív összeget.')
      return
    }
    if (inventoryOperationType === 'transfer' && !inventoryTargetBranchId.trim()) {
      setInventoryOperationMessage('Átadásnál kötelező a cél telephely azonosító.')
      return
    }
    if (inventoryOperationType === 'correction' && !notes) {
      setInventoryOperationMessage('Korrekciónál kötelező az indoklás.')
      return
    }

    setInventoryOperationLoading(true)
    setInventoryOperationMessage(null)
    try {
      if (inventoryOperationType === 'bankWithdraw') {
        await api.post('/inventory/bank-withdraw', {
          branchId,
          currencyId,
          amount,
          notes: notes || undefined,
        })
      } else if (inventoryOperationType === 'bankDeposit') {
        await api.post('/inventory/bank-deposit', {
          branchId,
          currencyId,
          amount,
          notes: notes || undefined,
        })
      } else if (inventoryOperationType === 'transfer') {
        await api.post('/inventory/transfer', {
          fromBranchId: branchId,
          toBranchId: inventoryTargetBranchId.trim(),
          currencyId,
          amount,
          notes: notes || undefined,
        })
      } else {
        await api.post('/inventory/correction', {
          branchId,
          currencyId,
          newAmount: amount,
          reason: notes,
        })
      }
      setInventoryOperationMessage('Készletművelet rögzítve.')
      await loadOperationalInventory()
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Készletművelet sikertelen:', err)
      setInventoryOperationMessage(msg)
    } finally {
      setInventoryOperationLoading(false)
    }
  }

  const runMovementAction = async (
    movement: InventoryMovementRow,
    action: 'approve' | 'receive' | 'cancel',
  ) => {
    if (movement.id == null) return

    const key = `${movement.id}:${action}`
    setMovementActionId(key)
    setInventoryOperationMessage(null)
    try {
      if (action === 'approve') {
        await api.post(`/inventory/${movement.id}/approve`)
      } else if (action === 'receive') {
        await api.post(`/inventory/${movement.id}/receive`, {
          receivedAmount: num(movement.amount),
        })
      } else {
        await api.post(`/inventory/${movement.id}/cancel`)
      }
      setInventoryOperationMessage('Készletmozgás státusza frissítve.')
      await loadOperationalInventory()
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Készletmozgás státusz művelet sikertelen:', err)
      setInventoryOperationMessage(msg)
    } finally {
      setMovementActionId(null)
    }
  }

  const runInventoryRegeneration = async () => {
    if (!worker?.branchId) {
      setInventoryOperationMessage('Nincs saját telephely azonosító a regeneráláshoz.')
      return
    }

    setRegenerationRunning(true)
    setInventoryOperationMessage(null)
    try {
      const response = await api.post<RegenerationResultDto>('/inventory/regeneration/run', null, {
        params: { branchId: worker.branchId },
      })
      setLastRegeneration(response.data ?? null)
      setInventoryOperationMessage('Készlet regenerálás lefutott.')
      await loadOperationalInventory()
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Készlet regenerálás sikertelen:', err)
      setInventoryOperationMessage(msg)
    } finally {
      setRegenerationRunning(false)
    }
  }

  return (
    <div className="space-y-3">
      <div className="no-print flex items-center justify-between gap-3 flex-wrap">
        <h1 className="text-lg font-bold text-secondary-900 flex items-center gap-2">
          <Vault className="h-5 w-5 text-primary-700" />
          {t('inventory.ertektariKeszlet')}
          <span className="text-xs text-gray-500 font-normal">
            {t('inventory.sajatValutankent')}
          </span>
        </h1>
        <div className="flex items-center gap-2">
          {lastRefresh && (
            <span className="text-xs text-gray-500">{lastRefresh.toLocaleTimeString('hu-HU')}</span>
          )}
          <button
            onClick={() => void loadData()}
            className="form-button h-8 text-xs flex items-center gap-1"
            title={t('common.refresh')}
          >
            <RefreshCw className={`h-3 w-3 ${loading ? 'animate-spin' : ''}`} />
            {t('common.refresh')}
          </button>
          <button
            onClick={() => window.print()}
            className="form-button h-8 text-xs flex items-center gap-1"
            title={t('common.print')}
          >
            <Printer className="h-3 w-3" />
            {t('common.print')}
          </button>
        </div>
      </div>

      {/* Nyomtatási fejléc — csak nyomtatáskor látszik (telephely + dátum), lábléc nélkül */}
      <div className="hidden print:block mb-2">
        <div className="text-base font-bold">{t('inventory.ertektariKeszlet')}</div>
        <div className="text-sm">
          {worker?.branchName ?? worker?.branchCode ?? ''}
          {i18n.t('literals.lit-28')} {new Date().toLocaleDateString('hu-HU')}
        </div>
      </div>

      {error && (
        <div className="no-print form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {banknoteError && (
        <div className="no-print form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {i18n.t('literals.cimletszintu-keszlet-betoltesi-hiba')}
          {banknoteError}
        </div>
      )}

      {operationalInventoryError && (
        <div className="no-print form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {i18n.t('literals.keszlet-riportok-betoltesi-hiba')}
          {operationalInventoryError}
        </div>
      )}

      {/* HUF összesen kiemelt kártya */}
      <div className="no-print rounded-lg bg-gradient-to-br from-primary-50 to-primary-100 border-2 border-primary-200 p-4 shadow-sm">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Vault className="h-6 w-6 text-primary-700" />
            <div>
              <div className="text-sm text-primary-700 font-medium">
                {t('inventory.ertektariZaroHufKeszlet')}
              </div>
              <div className="text-2xl font-bold font-mono text-primary-900">
                {totalHufClosing.toLocaleString('hu-HU', { maximumFractionDigits: 0 })}{' '}
                {t('common.ft')}
              </div>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm text-primary-700">
              {rows.length} {t('inventory.valuta')}
            </div>
          </div>
        </div>
      </div>

      <section className="no-print form-panel p-0">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-gray-200 bg-gray-50 px-3 py-2">
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-sm font-bold text-secondary-900">
                {i18n.t('literals.mobil-keszlet-riportok')}
              </h2>
              {isVaultOperationalContext && (
                <span
                  data-testid="vault-context-badge"
                  className="text-[9px] font-bold uppercase bg-amber-500 text-white rounded px-1 py-px shrink-0"
                >
                  {t('inventory.ertektarBadge')}
                </span>
              )}
            </div>
            <div className="text-xs text-gray-500">
              {t('inventory.operativRiportokAlcim')}
              {isVaultOperationalContext
                ? ` · ${t('inventory.ertektariCurrencyStockKonyveles')}`
                : ''}
            </div>
          </div>
          <button
            type="button"
            onClick={() => void loadOperationalInventory()}
            className="form-button h-8 text-xs flex items-center gap-1"
          >
            <RefreshCw className="h-3 w-3" />
            {i18n.t('literals.riportok-frissitese')}
          </button>
        </div>
        <div
          className="border-b border-gray-200 bg-white px-3 py-3"
          data-testid="inventory-operation-panel"
        >
          <div className="grid gap-2 lg:grid-cols-[160px_120px_120px_minmax(180px,1fr)_minmax(180px,1fr)_auto] lg:items-end">
            <label className="block">
              <span className="form-label">{i18n.t('literals.muvelet')}</span>
              <select
                className="form-input w-full"
                value={inventoryOperationType}
                onChange={(event) =>
                  setInventoryOperationType(event.target.value as InventoryOperationType)
                }
                aria-label="Készletművelet típusa"
              >
                <option value="bankWithdraw">{i18n.t('literals.bankbol-kivet')}</option>
                <option value="bankDeposit">{i18n.t('literals.bankba-befizetes')}</option>
                <option value="transfer">{i18n.t('literals.irodak-kozti-atadas')}</option>
                <option value="correction">{i18n.t('literals.korrekcio')}</option>
              </select>
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.deviza-2')}</span>
              <select
                className="form-input w-full"
                value={inventoryCurrencyId}
                onChange={(event) => setInventoryCurrencyId(event.target.value)}
                aria-label="Deviza kiválasztása"
                disabled={inventoryCurrenciesLoading || inventoryCurrencies.length === 0}
              >
                <option value="">
                  {inventoryCurrenciesLoading ? 'Devizák betöltése...' : 'Válassz devizát'}
                </option>
                {inventoryCurrencies.map((currency) => (
                  <option key={currency.id} value={currency.id}>
                    {currency.code}
                    {i18n.t('literals.lit-32')}
                    {currency.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="block">
              <span className="form-label">
                {inventoryOperationType === 'correction' ? 'Új egyenleg' : 'Összeg'}
              </span>
              <input
                className="form-input w-full font-mono"
                inputMode="decimal"
                value={inventoryAmount}
                onChange={(event) => setInventoryAmount(event.target.value)}
                placeholder={inventoryOperationType === 'correction' ? 'Új egyenleg' : 'Összeg'}
              />
            </label>
            <label className="block">
              <span className="form-label">{t('inventory.celTelephely')}</span>
              <select
                className="form-input w-full"
                value={inventoryOperationType === 'transfer' ? inventoryTargetBranchId : ''}
                onChange={(event) => setInventoryTargetBranchId(event.target.value)}
                disabled={
                  inventoryOperationType !== 'transfer' ||
                  transferTargetsLoading ||
                  (transferTargetsLoaded && transferTargets.length === 0)
                }
                aria-label={t('inventory.celTelephelyKivalasztasa')}
              >
                <option value="">
                  {inventoryOperationType !== 'transfer'
                    ? t('inventory.csakAtadasnal')
                    : transferTargetsLoading
                      ? t('inventory.celTelephelyekBetoltese')
                      : t('inventory.valasszCelTelephelyet')}
                </option>
                {transferTargets.map((target) => (
                  <option key={target.branchId} value={target.branchId}>
                    {target.code}
                    {i18n.t('literals.lit-18')}
                    {target.name}
                    {target.isVault ? ` · ${t('inventory.ertektarBadge')}` : ''}
                  </option>
                ))}
              </select>
            </label>
            <label className="block">
              <span className="form-label">
                {inventoryOperationType === 'correction' ? 'Indoklás' : 'Megjegyzés'}
              </span>
              <input
                className="form-input w-full"
                value={inventoryNotes}
                onChange={(event) => setInventoryNotes(event.target.value)}
                placeholder={
                  inventoryOperationType === 'correction' ? 'Kötelező indoklás' : 'Opcionális'
                }
              />
            </label>
            <button
              type="button"
              onClick={() => void submitInventoryOperation()}
              disabled={
                inventoryOperationLoading ||
                inventoryCurrenciesLoading ||
                inventoryCurrencies.length === 0
              }
              className="form-button-primary h-9 text-xs"
            >
              {inventoryOperationLoading ? 'Mentés...' : 'Művelet rögzítése'}
            </button>
          </div>
          {inventoryOperationMessage && (
            <p className="mt-2 text-xs text-gray-600">{inventoryOperationMessage}</p>
          )}
          {inventoryCurrenciesError && (
            <p className="mt-2 text-xs text-red-700">
              {i18n.t('literals.devizalista-betoltesi-hiba')}
              {inventoryCurrenciesError}
            </p>
          )}
          {inventoryOperationType === 'transfer' &&
            transferTargetsLoaded &&
            transferTargets.length === 0 &&
            !transferTargetsLoading && (
              <p className="mt-2 text-xs text-gray-600">
                {t('inventory.nincsElerhetoCelTelephely')}
              </p>
            )}
          {transferTargetsError && (
            <p className="mt-2 text-xs text-red-700">
              {t('inventory.celTelephelyListaBetoltesiHiba')}
              {i18n.t('literals.lit-22')}
              {transferTargetsError}
            </p>
          )}
        </div>
        <div className="grid gap-3 p-3 md:grid-cols-2 xl:grid-cols-4">
          <div className="rounded border border-gray-200 bg-white p-3">
            <div className="text-xs uppercase text-gray-500">
              {i18n.t('literals.sajat-penztarkeszlet')}
            </div>
            <div className="mt-1 text-xl font-bold text-secondary-900">
              {branchStockRows.length}
            </div>
            <div className="mt-1 text-xs text-gray-600">
              {branchStockRows[0]
                ? `${branchStockRows[0].currencyCode ?? '-'}: ${formatAmount(branchStockRows[0].currentBalance, branchStockRows[0].currencyCode)}`
                : 'Nincs sor'}
            </div>
          </div>
          <div className="rounded border border-gray-200 bg-white p-3">
            <div className="text-xs uppercase text-gray-500">
              {i18n.t('literals.keszletmatrix')}
            </div>
            <div className="mt-1 text-xl font-bold text-secondary-900">
              {stockMatrixInfo.branches}
              {i18n.t('literals.lit-10')}
              {stockMatrixInfo.currencies}
            </div>
            <div className="mt-1 text-xs text-gray-600">{i18n.t('literals.telephely-valuta')}</div>
          </div>
          <div className="rounded border border-gray-200 bg-white p-3">
            <div className="text-xs uppercase text-gray-500">
              {i18n.t('literals.napi-egyenleg')}
            </div>
            <div className="mt-1 text-xl font-bold text-secondary-900">
              {formatAmount(dailyBalance?.closingBalance, dailyBalance?.currencyCode)}
            </div>
            <div className="mt-1 text-xs text-gray-600">
              {i18n.t('literals.be')}
              {formatAmount(dailyBalance?.totalIn, dailyBalance?.currencyCode)}
              {i18n.t('literals.ki')}{' '}
              {formatAmount(dailyBalance?.totalOut, dailyBalance?.currencyCode)}
            </div>
          </div>
          <div className="rounded border border-gray-200 bg-white p-3">
            <div className="text-xs uppercase text-gray-500">
              {i18n.t('literals.utolso-regeneralas')}
            </div>
            <div className="mt-1 text-xl font-bold text-secondary-900">
              {lastRegeneration?.discrepancyCount ?? 0}
              {i18n.t('literals.elteres')}
            </div>
            <div className="mt-1 text-xs text-gray-600">
              {i18n.t('literals.javitva')}
              {lastRegeneration?.correctedCount ?? 0}
            </div>
            <button
              type="button"
              onClick={() => void runInventoryRegeneration()}
              disabled={regenerationRunning}
              className="mt-2 rounded border border-gray-200 bg-gray-50 px-2 py-1 text-xs font-semibold text-gray-700 disabled:opacity-60"
            >
              {regenerationRunning ? 'Regenerálás...' : 'Regenerálás futtatása'}
            </button>
          </div>
        </div>
        <div className="grid gap-3 border-t border-gray-200 p-3 lg:grid-cols-2">
          <div>
            <div className="mb-2 text-xs font-semibold uppercase text-gray-500">
              {i18n.t('literals.mozgasok')}
            </div>
            <div className="space-y-2">
              {movementRows.slice(0, 3).map((movement, idx) => (
                <div
                  key={movement.id ?? idx}
                  className="rounded border border-gray-200 bg-white px-3 py-2 text-xs"
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-semibold text-secondary-900">
                      {movement.currencyCode ?? '-'}
                    </span>
                    <span className="font-mono">
                      {formatAmount(movement.amount, movement.currencyCode)}
                    </span>
                  </div>
                  <div className="mt-1 flex items-center justify-between gap-2 text-gray-600">
                    <span>
                      {movement.movementTypeDisplay ?? movement.movementType ?? 'Mozgás'}
                      {i18n.t('literals.lit-29')} {movement.statusDisplay ?? movement.status ?? '-'}
                    </span>
                    {movement.id != null && (
                      <button
                        type="button"
                        onClick={() => void loadMovementDetail(movement.id)}
                        disabled={movementDetailLoadingId === movement.id}
                        className="rounded border border-gray-200 bg-gray-50 px-2 py-1 font-semibold text-gray-700 disabled:opacity-60"
                      >
                        {movementDetailLoadingId === movement.id ? 'Betöltés...' : 'Részlet'}
                      </button>
                    )}
                  </div>
                  {movement.id != null && (
                    <div className="mt-2 grid grid-cols-3 gap-2">
                      <button
                        type="button"
                        onClick={() => void runMovementAction(movement, 'approve')}
                        disabled={
                          movement.status !== 'PENDING' ||
                          movementActionId === `${movement.id}:approve`
                        }
                        className="rounded border border-gray-200 bg-gray-50 px-2 py-1 font-semibold text-gray-700 disabled:opacity-50"
                        aria-label={`Készletmozgás #${movement.id} jóváhagyása`}
                      >
                        {i18n.t('literals.jovahagy')}
                      </button>
                      <button
                        type="button"
                        onClick={() => void runMovementAction(movement, 'receive')}
                        disabled={
                          !['IN_TRANSIT', 'APPROVED'].includes(movement.status ?? '') ||
                          movementActionId === `${movement.id}:receive`
                        }
                        className="rounded border border-gray-200 bg-gray-50 px-2 py-1 font-semibold text-gray-700 disabled:opacity-50"
                        aria-label={`Készletmozgás #${movement.id} fogadása`}
                      >
                        {i18n.t('literals.fogad')}
                      </button>
                      <button
                        type="button"
                        onClick={() => void runMovementAction(movement, 'cancel')}
                        disabled={
                          movement.status !== 'PENDING' ||
                          movementActionId === `${movement.id}:cancel`
                        }
                        className="rounded border border-gray-200 bg-gray-50 px-2 py-1 font-semibold text-gray-700 disabled:opacity-50"
                        aria-label={`Készletmozgás #${movement.id} visszavonása`}
                      >
                        {i18n.t('literals.visszavon')}
                      </button>
                    </div>
                  )}
                </div>
              ))}
              {movementRows.length === 0 && (
                <div className="text-xs text-gray-500">{i18n.t('literals.nincs-mozgas-adat')}</div>
              )}
            </div>
            {selectedMovementDetail && (
              <div
                className="mt-3 rounded border border-blue-200 bg-blue-50 px-3 py-2 text-xs text-blue-950"
                data-testid="inventory-movement-detail"
              >
                <div className="font-semibold">
                  {i18n.t('literals.mozgas-reszlete')}
                  {selectedMovementDetail.id}
                </div>
                <div className="mt-1 grid gap-1 sm:grid-cols-2">
                  <span>
                    {i18n.t('literals.valuta-2')}
                    {selectedMovementDetail.currencyCode ?? '-'}
                  </span>
                  <span>
                    {i18n.t('literals.osszeg-2')}{' '}
                    {formatAmount(
                      selectedMovementDetail.amount,
                      selectedMovementDetail.currencyCode,
                    )}
                  </span>
                  <span>
                    {i18n.t('literals.statusz-2')}{' '}
                    {selectedMovementDetail.statusDisplay ?? selectedMovementDetail.status ?? '-'}
                  </span>
                  <span>
                    {i18n.t('literals.tipus-2')}{' '}
                    {selectedMovementDetail.movementTypeDisplay ??
                      selectedMovementDetail.movementType ??
                      '-'}
                  </span>
                </div>
              </div>
            )}
          </div>
          <div>
            <div className="mb-2 text-xs font-semibold uppercase text-gray-500">
              {i18n.t('literals.napi-mozgasnaplo')}
            </div>
            <div className="space-y-2">
              {movementLogRows.slice(0, 3).map((movement, idx) => (
                <div
                  key={movement.id ?? idx}
                  className="rounded border border-gray-200 bg-white px-3 py-2 text-xs"
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-semibold text-secondary-900">
                      {movement.currencyCode ?? '-'}
                    </span>
                    <span className="font-mono">
                      {formatAmount(movement.amount, movement.currencyCode)}
                    </span>
                  </div>
                  <div className="mt-1 text-gray-600">
                    {(movement.fromBranchName ?? '-') + ' -> ' + (movement.toBranchName ?? '-')}
                  </div>
                </div>
              ))}
              {movementLogRows.length === 0 && (
                <div className="text-xs text-gray-500">
                  {i18n.t('literals.nincs-napi-mozgasnaplo-adat')}
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Vault flow tábla */}
      <div className="form-panel p-0">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[640px] text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr className="text-xs uppercase text-gray-600">
                <th className="px-3 py-2 text-left w-20">{t('common.code')}</th>
                <th className="px-3 py-2 text-left">{t('display.megnevezes')}</th>
                <th className="px-3 py-2 text-right w-28">{t('inventory.nyitokeszlet')}</th>
                <th className="px-3 py-2 text-right w-28">{t('inventory.atvettIn')}</th>
                <th className="px-3 py-2 text-right w-28">{t('inventory.atadottOut')}</th>
                <th className="px-3 py-2 text-right w-28">{t('inventory.zarokeszlet')}</th>
              </tr>
            </thead>
            <tbody>
              {loading && rows.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-3 py-8 text-center text-sm text-gray-500">
                    {i18n.t('literals.betoltes')}
                  </td>
                </tr>
              ) : rows.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-3 py-8 text-center text-sm text-gray-500">
                    <div className="flex flex-col items-center gap-2">
                      <Info className="h-5 w-5 text-gray-400" />
                      <div>{t('inventory.nincsErtektariKeszletBejegyzes')}</div>
                      <div className="text-xs text-gray-400">
                        {t(
                          'inventory.azErtektariKeszletACollectionDistributionBankTranzakciokSoranToltodikFel',
                        )}
                      </div>
                    </div>
                  </td>
                </tr>
              ) : (
                rows.map((row, idx) => {
                  // FR-5: pozitív záróegyenlegű sor enyhe zöld tónussal kiemelve (a 0-egyenlegtől
                  // elkülönítve); FR-4: a többi sor zebra-csíkozással (páros/páratlan).
                  const positive = (row.closing ?? 0) > 0
                  const rowBg = positive ? 'bg-emerald-50' : idx % 2 === 1 ? 'bg-gray-50' : ''
                  return (
                    <tr
                      key={row.currencyCode}
                      className={`${rowBg} hover:bg-blue-50 border-b border-gray-100 last:border-0`}
                    >
                      <td className="px-3 py-1.5 font-mono font-bold text-blue-700">
                        {row.currencyCode}
                      </td>
                      <td className="px-3 py-1.5">{row.currencyName}</td>
                      <td className="px-3 py-1.5 text-right font-mono text-gray-700">
                        {formatCurrency(row.opening, row.currencyCode)}
                      </td>
                      <td className="px-3 py-1.5 text-right font-mono text-green-700">
                        {formatCurrency(row.received, row.currencyCode)}
                      </td>
                      <td className="px-3 py-1.5 text-right font-mono text-red-700">
                        {formatCurrency(row.issued, row.currencyCode)}
                      </td>
                      <td className="px-3 py-1.5 text-right font-mono font-bold text-secondary-900">
                        {formatCurrency(row.closing, row.currencyCode)}
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <section className="form-panel p-0">
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-gray-200 bg-gray-50 px-3 py-2">
          <div>
            <h2 className="text-sm font-bold text-secondary-900">
              {i18n.t('literals.cimletszintu-ertektari-keszlet')}
            </h2>
            <div className="text-xs text-gray-500">
              {i18n.t('literals.backend-banknote-inventory-sajat-telephe')}
            </div>
          </div>
          <div className="flex flex-wrap gap-2 text-xs">
            <span className="rounded border border-gray-200 bg-white px-2 py-1">
              {banknoteRows.length}
              {i18n.t('literals.cimlet-2')}
            </span>
            {lowStockRows.length > 0 && (
              <span className="rounded border border-amber-300 bg-amber-50 px-2 py-1 text-amber-800">
                {i18n.t('literals.alacsony')}
                {lowStockRows.length}
              </span>
            )}
            {overStockRows.length > 0 && (
              <span className="rounded border border-blue-300 bg-blue-50 px-2 py-1 text-blue-800">
                {i18n.t('literals.tul-magas')}
                {overStockRows.length}
              </span>
            )}
          </div>
        </div>
        {banknoteRows.length > 0 && (
          <div className="no-print border-b border-gray-200 bg-white px-3 py-3">
            <div className="grid gap-2 lg:grid-cols-[minmax(220px,1fr)_120px_minmax(220px,1fr)_auto] lg:items-end">
              <label className="block">
                <span className="form-label">{i18n.t('literals.cimletsor')}</span>
                <select
                  className="form-input w-full"
                  value={selectedBanknote?.id ?? ''}
                  onChange={(event) => setSelectedBanknoteId(Number(event.target.value))}
                  aria-label="Címletszintű készletsor kiválasztása"
                >
                  {banknoteRows.map((row) => (
                    <option key={row.id} value={row.id}>
                      {row.currencyCode} {formatCurrency(row.faceValue, row.currencyCode)}
                      {i18n.t('literals.lit-29')} {row.quantity}
                      {i18n.t('literals.db')}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="form-label">{i18n.t('literals.darab')}</span>
                <input
                  className="form-input w-full font-mono"
                  inputMode="numeric"
                  value={banknoteQuantity}
                  onChange={(event) => setBanknoteQuantity(event.target.value)}
                  placeholder="Darab"
                />
              </label>
              <div className="grid grid-cols-2 gap-2">
                <label className="block">
                  <span className="form-label">{i18n.t('literals.min')}</span>
                  <input
                    className="form-input w-full font-mono"
                    inputMode="numeric"
                    value={thresholdMin}
                    onChange={(event) => setThresholdMin(event.target.value)}
                    placeholder="Min."
                  />
                </label>
                <label className="block">
                  <span className="form-label">{i18n.t('literals.max')}</span>
                  <input
                    className="form-input w-full font-mono"
                    inputMode="numeric"
                    value={thresholdMax}
                    onChange={(event) => setThresholdMax(event.target.value)}
                    placeholder="Max."
                  />
                </label>
              </div>
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  className="form-button h-8 text-xs"
                  disabled={banknoteActionLoading}
                  onClick={() => void runBanknoteAction('add')}
                >
                  {i18n.t('literals.bevet')}
                </button>
                <button
                  type="button"
                  className="form-button h-8 text-xs"
                  disabled={banknoteActionLoading}
                  onClick={() => void runBanknoteAction('remove')}
                >
                  {i18n.t('literals.kiad')}
                </button>
                <button
                  type="button"
                  className="form-button h-8 text-xs"
                  disabled={banknoteActionLoading}
                  onClick={() => void runBanknoteAction('count')}
                >
                  {i18n.t('literals.leltardarab')}
                </button>
                <button
                  type="button"
                  className="form-button-primary h-8 text-xs"
                  disabled={banknoteActionLoading}
                  onClick={() => void runBanknoteAction('thresholds')}
                >
                  {i18n.t('literals.kuszob-mentese')}
                </button>
              </div>
            </div>
            {banknoteActionMessage && (
              <p className="mt-2 text-xs text-gray-600">{banknoteActionMessage}</p>
            )}
          </div>
        )}
        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px] text-sm">
            <thead className="border-b border-gray-200 bg-white text-xs uppercase text-gray-600">
              <tr>
                <th className="px-3 py-2 text-left">{i18n.t('literals.valuta')}</th>
                <th className="px-3 py-2 text-right">{i18n.t('literals.cimlet')}</th>
                <th className="px-3 py-2 text-right">{i18n.t('literals.darab')}</th>
                <th className="px-3 py-2 text-right">{i18n.t('literals.osszesen')}</th>
                <th className="px-3 py-2 text-right">{i18n.t('literals.min')}</th>
                <th className="px-3 py-2 text-right">{i18n.t('literals.max')}</th>
                <th className="px-3 py-2 text-left">{i18n.t('literals.statusz')}</th>
              </tr>
            </thead>
            <tbody>
              {banknoteRows.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-3 py-6 text-center text-sm text-gray-500">
                    {i18n.t('literals.nincs-cimletszintu-banknote-inventory-ad')}
                  </td>
                </tr>
              ) : (
                banknoteRows.map((row, idx) => {
                  const status = row.lowStock ? 'Alacsony' : row.overStock ? 'Túl magas' : 'Rendben'
                  const statusClass = row.lowStock
                    ? 'border-amber-300 bg-amber-50 text-amber-800'
                    : row.overStock
                      ? 'border-blue-300 bg-blue-50 text-blue-800'
                      : 'border-emerald-200 bg-emerald-50 text-emerald-800'
                  return (
                    <tr
                      key={row.id}
                      className={`${idx % 2 === 1 ? 'bg-gray-50' : ''} border-b border-gray-100 last:border-0`}
                    >
                      <td className="px-3 py-1.5 font-mono font-bold text-blue-700">
                        {row.currencyCode}
                      </td>
                      <td className="px-3 py-1.5 text-right font-mono">
                        {formatCurrency(row.faceValue, row.currencyCode)}
                      </td>
                      <td className="px-3 py-1.5 text-right font-mono">
                        {row.quantity.toLocaleString('hu-HU')}
                      </td>
                      <td className="px-3 py-1.5 text-right font-mono font-semibold">
                        {formatCurrency(row.totalValue, row.currencyCode)}
                      </td>
                      <td className="px-3 py-1.5 text-right font-mono text-gray-600">
                        {row.minQuantity ?? '-'}
                      </td>
                      <td className="px-3 py-1.5 text-right font-mono text-gray-600">
                        {row.maxQuantity ?? '-'}
                      </td>
                      <td className="px-3 py-1.5">
                        <span
                          className={`rounded border px-2 py-1 text-xs font-semibold ${statusClass}`}
                        >
                          {status}
                        </span>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </section>

      {rows.length > 0 && rows[0]?.opening == null && (
        <div className="no-print form-panel bg-amber-50 border-amber-200 flex items-start gap-2 text-xs text-amber-900">
          <Info className="h-4 w-4 mt-0.5 flex-shrink-0" />
          <span>
            <strong>{t('components.megjegyzes')}</strong>
            {t('inventory.aNyitoAtvettAtadottNapiErtekek')}
            {t('inventory.kovetesehezAV250SprintbenKerulImplementalasraADailySnapshotMechanizmus')}
            {t('inventory.jelenlegCsakAZaroJelenlegiKeszletErhetoEl')}
          </span>
        </div>
      )}
    </div>
  )
}
