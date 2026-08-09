import { Fragment, useState, useEffect, useCallback, type ChangeEvent } from 'react'
import { Navigate } from 'react-router-dom'
import {
  TrendingUp,
  RefreshCw,
  Edit,
  Save,
  X,
  Clock,
  Download,
  Eye,
  Calculator,
  Upload,
  ShieldCheck,
} from 'lucide-react'
import {
  exchangeRateApi,
  exchangeRatePollingApi,
  ExchangeRate,
  rateApprovalApi,
  rateCreationApi,
  currencyApi,
  Currency,
  type BankRateDTO,
  type CompetitorRateDTO,
  type ExchangeRatePollingSource,
  type ExchangeRatePollingStatus,
  roundingRuleApi,
  type RoundingDirection,
  type RoundingResult,
  type RoundingRule,
  currencyCalculatorApi,
  type CalculatorDirection,
  type CurrencyCalculationResult,
  type CurrencyExchangeMatrix,
  type CurrencyReverseResult,
  type ParsedRateFile,
  type TerritoryWorkgroupRateDTO,
} from '../../services/api/index'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'
import { recordLocalAuditEvent } from '../../utils/electronTransactions'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useAppMode } from '../../hooks/useAppMode'
import { useTranslation } from 'react-i18next'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'

// 2026-04-29 B2 fix: a /rates oldalt a penztaros (mode='penztar') NEM
// szerkesztheti — csak a foertektar/ugyvezeto az ARFOLYAM/Arfolyam.exe legacy
// szerepkor szerint. Ld. D:\valutavalto-vault\references\legacy-anti-system.md §2.3
const RATE_EDITOR_ROLES = ['foertektar', 'ugyvezeto'] as const

interface RateRow {
  id: number
  code: string
  name: string
  buyRate: number
  sellRate: number
  mnbRate: number
  lastUpdate: string
  /** FKH-032 FR-6: elavult árfolyam — feltűnő, aktív vizuális jelzést kap a táblában. */
  isStale: boolean
  /** FKH-032 FR-6: az árfolyam kora órában, a jelzés melletti magyarázathoz. */
  ageHours?: number
  currencyId: number
  /** FK-006: false = aktív valuta, de még NINCS rögzített árfolyama (üres sorként jelenik meg). */
  hasRate: boolean
  limit1Amount?: number
  limit1BuyRate?: number
  limit1SellRate?: number
  limit2Amount?: number
  limit2BuyRate?: number
  limit2SellRate?: number
  limit3Amount?: number
  limit3BuyRate?: number
  limit3SellRate?: number
}

/**
 * FKH-031 FR-5: az árfolyam érvényességi dátumának magyar formázása (2026.08.08).
 * A backend `validDate` ISO (YYYY-MM-DD) formában érkezik; hiányzó/érvénytelen érték
 * esetén üres sztringet adunk vissza, hogy a felirat ne törjön el.
 */
function formatRateDate(validDate: string | null | undefined): string {
  if (!validDate) return ''
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(validDate)
  if (!match) return ''
  return `${match[1]}.${match[2]}.${match[3]}`
}

function mapExchangeRateToRow(rate: ExchangeRate): RateRow {
  return {
    id: rate.id,
    code: rate.currencyCode,
    name: rate.currencyName,
    buyRate: rate.baseBuyRate,
    sellRate: rate.baseSellRate,
    mnbRate: rate.officialRate ?? 0,
    // FKH-031 FR-5: a "frissítve" felirat DÁTUMOT és időt is tartalmaz — egy elavult
    // árfolyam így önmagában is felismerhető, nem csak a HH:MM látszik.
    lastUpdate: rate.validTime
      ? `${formatRateDate(rate.validDate)} ${rate.validTime.substring(0, 5)}`.trim()
      : new Date(rate.createdAt).toLocaleString('hu-HU', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
        }),
    // FKH-032 FR-6: a szerver által számított elavulás-jelzés (exchange-rate.max-age-hours).
    isStale: rate.stale === true,
    ageHours: rate.ageHours,
    currencyId: rate.currencyId,
    limit1Amount: rate.limit1Amount ?? undefined,
    limit1BuyRate: rate.limit1BuyRate ?? undefined,
    limit1SellRate: rate.limit1SellRate ?? undefined,
    limit2Amount: rate.limit2Amount ?? undefined,
    limit2BuyRate: rate.limit2BuyRate ?? undefined,
    limit2SellRate: rate.limit2SellRate ?? undefined,
    limit3Amount: rate.limit3Amount ?? undefined,
    limit3BuyRate: rate.limit3BuyRate ?? undefined,
    limit3SellRate: rate.limit3SellRate ?? undefined,
    hasRate: true,
  }
}

/**
 * FK-006: a táblát a valutanem-TÖRZSBŐL építjük (aktív valuták, display_order sorrendben),
 * és minden valutához hozzákötjük a legfrissebb árfolyamát; amelyikhez még nincs, az ÜRES
 * sorként jelenik meg (a főértéktáros így látja, mihez kell még árfolyamot adni).
 * A HUF (bázisdeviza) a rátatáblában nem külön sor (FK-006 #3 — listákban/legördülőkben szerepel).
 */
function buildRows(currencies: Currency[], rates: ExchangeRate[]): RateRow[] {
  const rateByCurrencyId = new Map<number, ExchangeRate>()
  for (const r of rates) rateByCurrencyId.set(r.currencyId, r)
  return currencies
    .filter((c) => c.code !== 'HUF')
    .map((c) => {
      const r = rateByCurrencyId.get(c.id)
      if (r) return mapExchangeRateToRow(r)
      return {
        id: -c.id,
        code: c.code,
        name: c.name,
        buyRate: 0,
        sellRate: 0,
        mnbRate: 0,
        lastUpdate: '',
        // FKH-032 FR-6: nincs rögzített árfolyam -> nincs mit elavultként jelezni.
        isStale: false,
        currencyId: c.id,
        hasRate: false,
      }
    })
}

function formatHuf(amount: number | null | undefined): string {
  // Null-safe (mint a numberFormat.ts társai): a hívók ma őrzött nem-null értéket adnak, de a
  // sávhatár-összegek típusa number|null|undefined — egy jövőbeli őr-lazítás ne dönthesse el a nézetet.
  return amount == null ? '—' : amount.toLocaleString('hu-HU')
}

function numericAmount(value: number | string | null | undefined): number {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').replace(',', '.'))
  return Number.isFinite(parsed) ? parsed : 0
}

/** Check if ANY rate in the dataset has a given tier */
function anyHasTier(rates: RateRow[], tier: 1 | 2 | 3): boolean {
  return rates.some((r) => {
    if (tier === 1)
      return r.limit1Amount != null && (r.limit1BuyRate != null || r.limit1SellRate != null)
    if (tier === 2)
      return r.limit2Amount != null && (r.limit2BuyRate != null || r.limit2SellRate != null)
    return r.limit3Amount != null && (r.limit3BuyRate != null || r.limit3SellRate != null)
  })
}

export default function RatesPage() {
  const { t } = useTranslation()
  const [rates, setRates] = useState<RateRow[]>([])
  // FK-041: a terület munkacsoportonkénti árfolyam-variánsai (read-only értéktár nézet).
  const [territoryGroups, setTerritoryGroups] = useState<TerritoryWorkgroupRateDTO[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastRefresh, setLastRefresh] = useState<string>('')
  const [editingCode, setEditingCode] = useState<string | null>(null)
  const [editValues, setEditValues] = useState({ buyRate: 0, sellRate: 0 })
  const [rateApprovalLoadingCode, setRateApprovalLoadingCode] = useState<string | null>(null)
  const [rateApprovalMessage, setRateApprovalMessage] = useState<string | null>(null)
  const [rateApprovalError, setRateApprovalError] = useState<string | null>(null)
  const [calculatorAmount, setCalculatorAmount] = useState('100')
  const [calculatorFrom, setCalculatorFrom] = useState('EUR')
  const [calculatorTo, setCalculatorTo] = useState('HUF')
  const [calculatorDirection, setCalculatorDirection] = useState<CalculatorDirection>('BUY')
  const [calculatorResult, setCalculatorResult] = useState<CurrencyCalculationResult | null>(null)
  const [calculatorLoading, setCalculatorLoading] = useState(false)
  const [calculatorError, setCalculatorError] = useState<string | null>(null)
  const [reverseCurrency, setReverseCurrency] = useState('EUR')
  const [reverseHufAmount, setReverseHufAmount] = useState('100000')
  const [reverseResult, setReverseResult] = useState<CurrencyReverseResult | null>(null)
  const [reverseLoading, setReverseLoading] = useState(false)
  const [matrix, setMatrix] = useState<CurrencyExchangeMatrix>({})
  const [pollingStatus, setPollingStatus] = useState<ExchangeRatePollingStatus | null>(null)
  const [pollingSources, setPollingSources] = useState<ExchangeRatePollingSource[]>([])
  const [pollingError, setPollingError] = useState<string | null>(null)
  const [pollingActionMessage, setPollingActionMessage] = useState<string | null>(null)
  const [pollingActionError, setPollingActionError] = useState<string | null>(null)
  const [pollingActionLoading, setPollingActionLoading] = useState<string | null>(null)
  const [marginCurrencyId, setMarginCurrencyId] = useState<number | ''>('')
  const [marginSpread, setMarginSpread] = useState('2.5')
  const [ecbRates, setEcbRates] = useState<Record<string, number | string>>({})
  const [ecbRateError, setEcbRateError] = useState<string | null>(null)
  const [bankRates, setBankRates] = useState<BankRateDTO[]>([])
  const [competitorRates, setCompetitorRates] = useState<CompetitorRateDTO[]>([])
  const [marketRateError, setMarketRateError] = useState<string | null>(null)
  const [roundingRules, setRoundingRules] = useState<RoundingRule[]>([])
  const [roundingCurrency, setRoundingCurrency] = useState('EUR')
  const [roundingAmount, setRoundingAmount] = useState('123.456')
  const [roundingDirection, setRoundingDirection] = useState<RoundingDirection>('BUY')
  const [roundingRule, setRoundingRule] = useState<RoundingRule | null>(null)
  const [roundingResult, setRoundingResult] = useState<RoundingResult | null>(null)
  const [roundingLoading, setRoundingLoading] = useState(false)
  const [roundingError, setRoundingError] = useState<string | null>(null)
  const [rateFile, setRateFile] = useState<File | null>(null)
  const [parsedRateFile, setParsedRateFile] = useState<ParsedRateFile | null>(null)
  const [rateFileLoading, setRateFileLoading] = useState(false)
  const [rateFileMessage, setRateFileMessage] = useState<string | null>(null)
  const [rateFileError, setRateFileError] = useState<string | null>(null)

  const { mode: appMode } = useAppMode()
  const worker = useAuthStore((state) => state.worker)
  const hasCanonicalRole = useAuthStore((state) => state.hasCanonicalRole)
  const canEdit = appMode === 'full' && hasCanonicalRole([...RATE_EDITOR_ROLES])
  // FK-041/II: az árfolyam néző (és csak ő) nem láthatja a belső területi árfolyamokat — sem a
  // renderelt nézetet, sem a háttér-fetchet (defenzív, a route-on túl is).
  const isRateWatcherOnly =
    hasCanonicalRole(['arfolyam_nezo']) && !hasCanonicalRole([...RATE_EDITOR_ROLES])

  useEffect(() => {
    if (!canEdit && editingCode !== null) {
      setEditingCode(null)
      setEditValues({ buyRate: 0, sellRate: 0 })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canEdit])

  const loadRates = useCallback(async () => {
    // FK-041/II: az árfolyam néző NEM kér le belső területi árfolyamot (a render is átirányít).
    if (isRateWatcherOnly) {
      setLoading(false)
      return
    }
    setLoading(true)
    setError(null)
    try {
      // FK-006: a valutalistát a központi valutanem-törzsből kérjük (aktív + display_order),
      // az árfolyamokat külön, majd összefűzzük — így az inaktív valuták (DKK/NOK/SEK) nem
      // jelennek meg, az új aktív valuták (BAM/BRL/ILS/MXN/NZD/THB) pedig üres sorként igen.
      const [currenciesRaw, ratesRaw] = await Promise.all([
        currencyApi.list(),
        exchangeRateApi.list(),
      ])
      const currencies = safeArray<Currency>(currenciesRaw)
      const rates = safeArray<ExchangeRate>(ratesRaw)
      const loadedRows = buildRows(currencies, rates)
      setRates(loadedRows)
      setMarginCurrencyId((current) => {
        if (current !== '' && loadedRows.some((rate) => rate.currencyId === current)) return current
        return loadedRows[0]?.currencyId ?? ''
      })
      setLastRefresh(new Date().toLocaleString('hu-HU'))
      // FK-041: az editor-only metrikák/eszközök adatait (mátrix, polling, ECB, piaci összehasonlítás,
      // kerekítési szabályok) CSAK szerkesztő (full + főértéktár) módban töltjük. A read-only értéktár-
      // nézethez elég a tiszta árfolyam-táblázat — felesleges háttér-hívások nélkül, gyorsabban.
      if (canEdit) {
        // A szerkesztő-nézet a sűrű (szerkeszthető) táblát használja, nem a területi nézetet.
        setTerritoryGroups([])
        try {
          setMatrix(await currencyCalculatorApi.matrix())
        } catch (matrixErr) {
          logger.warn('RatesPage', 'Átváltási mátrix nem elérhető:', matrixErr)
          setMatrix({})
        }
        try {
          const [status, sources] = await Promise.all([
            exchangeRatePollingApi.status(),
            exchangeRatePollingApi.sources(),
          ])
          setPollingStatus(status)
          setPollingSources(safeArray<ExchangeRatePollingSource>(sources))
          setPollingError(null)
        } catch (pollingErr) {
          logger.warn('RatesPage', 'Árfolyam polling státusz nem elérhető:', pollingErr)
          setPollingStatus(null)
          setPollingSources([])
          setPollingError(getErrorMessage(pollingErr))
        }
        try {
          setEcbRates(await exchangeRatePollingApi.ecbRates())
          setEcbRateError(null)
        } catch (ecbErr) {
          logger.warn('RatesPage', 'ECB árfolyam snapshot nem elérhető:', ecbErr)
          setEcbRates({})
          setEcbRateError(getErrorMessage(ecbErr))
        }
        try {
          const [bankRateRows, competitorRateRows] = await Promise.all([
            rateCreationApi.getBankRates(),
            rateCreationApi.getCompetitorRates(),
          ])
          setBankRates(safeArray<BankRateDTO>(bankRateRows))
          setCompetitorRates(safeArray<CompetitorRateDTO>(competitorRateRows))
          setMarketRateError(null)
        } catch (marketErr) {
          logger.warn('RatesPage', 'Bank/versenytárs árfolyamok nem elérhetők:', marketErr)
          setBankRates([])
          setCompetitorRates([])
          setMarketRateError(getErrorMessage(marketErr))
        }
        try {
          const rules = safeArray<RoundingRule>(await roundingRuleApi.list())
          setRoundingRules(rules)
          setRoundingError(null)
          setRoundingCurrency((current) =>
            rules.length > 0 && !rules.some((rule) => rule.currencyCode === current)
              ? (rules[0]?.currencyCode ?? current)
              : current,
          )
        } catch (roundingErr) {
          logger.warn('RatesPage', 'Kerekítési szabályok nem elérhetők:', roundingErr)
          setRoundingRules([])
          setRoundingError(getErrorMessage(roundingErr))
        }
      } else {
        setMatrix({})
        setPollingStatus(null)
        setPollingSources([])
        setPollingError(null)
        setEcbRates({})
        setEcbRateError(null)
        setBankRates([])
        setCompetitorRates([])
        setMarketRateError(null)
        setRoundingRules([])
        setRoundingRule(null)
        setRoundingResult(null)
        setRoundingError(null)
        // FK-041: a read-only értéktár nézethez a terület munkacsoportonkénti árfolyam-variánsai
        // (régió-scope-olt; a backend AccessScopeService szűr). Hiba esetén a sima tábla a fallback.
        try {
          setTerritoryGroups(await rateCreationApi.getTerritoryWorkgroupRates())
        } catch (twgErr) {
          logger.warn('RatesPage', 'Területi munkacsoport-árfolyamok nem elérhetők:', twgErr)
          setTerritoryGroups([])
        }
      }
    } catch (err) {
      logger.error('RatesPage', 'Árfolyamok betöltési hiba:', err)
      setError('Hiba az árfolyamok betöltésekor. Kérjük, próbálja újra!')
    } finally {
      setLoading(false)
    }
  }, [canEdit, isRateWatcherOnly])

  useEffect(() => {
    void loadRates()
  }, [loadRates])

  const startEdit = (rate: RateRow) => {
    setEditingCode(rate.code)
    setEditValues({ buyRate: rate.buyRate, sellRate: rate.sellRate })
  }

  const saveEdit = async (code: string) => {
    const rate = rates.find((r) => r.code === code)
    if (!rate) return

    if (editValues.buyRate >= editValues.sellRate) {
      toast.warning('A vételi árfolyamnak kisebbnek kell lennie az eladásinál!')
      return
    }

    try {
      await exchangeRateApi.create({
        currencyId: rate.currencyId,
        baseBuyRate: editValues.buyRate,
        baseSellRate: editValues.sellRate,
        officialRate: rate.mnbRate || undefined,
      })
      await recordLocalAuditEvent({
        entityType: 'EXCHANGE_RATE',
        eventType: 'UPDATE',
        entityId: String(rate.currencyId),
        referenceNumber: rate.code,
        payload: {
          currencyId: rate.currencyId,
          currencyCode: rate.code,
          baseBuyRate: editValues.buyRate,
          baseSellRate: editValues.sellRate,
          officialRate: rate.mnbRate || null,
        },
        rateSnapshot: {
          currencyCode: rate.code,
          buyRate: editValues.buyRate,
          sellRate: editValues.sellRate,
          officialRate: rate.mnbRate || null,
        },
        status: 'SERVER_FORWARDED',
      })
      setEditingCode(null)
      void loadRates()
    } catch (err) {
      logger.error('RatesPage', 'Árfolyam mentési hiba:', err)
      toast.error('Hiba az árfolyam mentésekor!')
    }
  }

  const requestRateApproval = async (code: string) => {
    const rate = rates.find((r) => r.code === code)
    if (!rate) return

    if (editValues.buyRate >= editValues.sellRate) {
      toast.warning('A vételi árfolyamnak kisebbnek kell lennie az eladásinál!')
      return
    }

    if (!worker?.branchId) {
      setRateApprovalMessage(null)
      setRateApprovalError(
        'Árfolyam jóváhagyási kérelemhez hiányzik a bejelentkezett iroda azonosítója.',
      )
      return
    }

    try {
      setRateApprovalLoadingCode(code)
      setRateApprovalMessage(null)
      setRateApprovalError(null)
      const approval = await rateApprovalApi.request({
        branchId: worker.branchId,
        currencyCode: rate.code,
        newBuyRate: editValues.buyRate,
        newSellRate: editValues.sellRate,
        reason: `Árfolyam módosítási kérelem: ${rate.code}`,
      })
      setRateApprovalMessage(
        `${approval.currencyCode} jóváhagyási kérelem elküldve (${approval.status ?? 'PENDING'}).`,
      )
      setEditingCode(null)
    } catch (err) {
      logger.error('RatesPage', 'Árfolyam jóváhagyási kérelem sikertelen:', err)
      setRateApprovalMessage(null)
      setRateApprovalError(getErrorMessage(err))
    } finally {
      setRateApprovalLoadingCode(null)
    }
  }

  const cancelEdit = () => {
    setEditingCode(null)
  }

  const handleTriggerPolling = async () => {
    if (!canEdit) return
    setPollingActionLoading('trigger')
    setPollingActionMessage(null)
    setPollingActionError(null)
    try {
      const result = await exchangeRatePollingApi.trigger()
      setPollingActionMessage(result.message)
      await loadRates()
    } catch (err) {
      logger.error('RatesPage', 'Kézi MNB polling sikertelen:', err)
      setPollingActionError(getErrorMessage(err))
    } finally {
      setPollingActionLoading(null)
    }
  }

  const handleApplyMargins = async () => {
    if (!canEdit) return
    const spread = parsePositiveAmount(marginSpread)
    if (!marginCurrencyId || !spread) {
      setPollingActionMessage(null)
      setPollingActionError('Válassz devizanemet és adj meg pozitív spread értéket.')
      return
    }

    setPollingActionLoading('apply-margins')
    setPollingActionMessage(null)
    setPollingActionError(null)
    try {
      const result = await exchangeRatePollingApi.applyMargins({
        currencyId: marginCurrencyId,
        spread,
      })
      setPollingActionMessage(result.message)
      await loadRates()
    } catch (err) {
      logger.error('RatesPage', 'Margin alkalmazás sikertelen:', err)
      setPollingActionError(getErrorMessage(err))
    } finally {
      setPollingActionLoading(null)
    }
  }

  const handleUpdatePollingSource = async (
    source: ExchangeRatePollingSource,
    data: { active?: boolean; pollIntervalMinutes?: number },
  ) => {
    if (!canEdit) return
    setPollingActionLoading(`source-${source.id}`)
    setPollingActionMessage(null)
    setPollingActionError(null)
    try {
      const updated = await exchangeRatePollingApi.updateSource(source.id, data)
      setPollingSources((current) =>
        current.map((item) => (item.id === updated.id ? updated : item)),
      )
      setPollingActionMessage(`${updated.name} forrás frissítve`)
    } catch (err) {
      logger.error('RatesPage', 'Árfolyam forrás frissítés sikertelen:', err)
      setPollingActionError(getErrorMessage(err))
    } finally {
      setPollingActionLoading(null)
    }
  }

  const parsePositiveAmount = (value: string): number | null => {
    const parsed = Number(value.replace(/\s/g, '').replace(',', '.'))
    return Number.isFinite(parsed) && parsed > 0 ? parsed : null
  }

  const handleConvert = async () => {
    const amount = parsePositiveAmount(calculatorAmount)
    if (!amount || !calculatorFrom || !calculatorTo) {
      setCalculatorError('Adj meg pozitív összeget és két devizanemet.')
      setCalculatorResult(null)
      return
    }

    setCalculatorLoading(true)
    setCalculatorError(null)
    try {
      setCalculatorResult(
        await currencyCalculatorApi.convert({
          fromCurrency: calculatorFrom,
          toCurrency: calculatorTo,
          amount,
          direction: calculatorDirection,
        }),
      )
    } catch (err) {
      logger.error('RatesPage', 'Átváltás kalkuláció sikertelen:', err)
      setCalculatorResult(null)
      setCalculatorError(getErrorMessage(err))
    } finally {
      setCalculatorLoading(false)
    }
  }

  const handleReverse = async () => {
    const hufAmount = parsePositiveAmount(reverseHufAmount)
    if (!hufAmount || !reverseCurrency) {
      setCalculatorError('Adj meg pozitív HUF összeget és devizanemet.')
      setReverseResult(null)
      return
    }

    setReverseLoading(true)
    setCalculatorError(null)
    try {
      setReverseResult(
        await currencyCalculatorApi.reverse({
          currency: reverseCurrency,
          hufAmount,
        }),
      )
    } catch (err) {
      logger.error('RatesPage', 'Fordított kalkuláció sikertelen:', err)
      setReverseResult(null)
      setCalculatorError(getErrorMessage(err))
    } finally {
      setReverseLoading(false)
    }
  }

  const handleRoundingProbe = async () => {
    const amount = parsePositiveAmount(roundingAmount)
    if (!amount || !roundingCurrency) {
      setRoundingError('Adj meg pozitív összeget és devizanemet.')
      setRoundingRule(null)
      setRoundingResult(null)
      return
    }

    setRoundingLoading(true)
    setRoundingError(null)
    try {
      const [rule, result] = await Promise.all([
        roundingRuleApi.getByCurrencyCode(roundingCurrency, amount),
        roundingRuleApi.round(roundingCurrency, amount, roundingDirection),
      ])
      setRoundingRule(rule)
      setRoundingResult(result)
    } catch (err) {
      logger.error('RatesPage', 'Kerekítési próba sikertelen:', err)
      setRoundingRule(null)
      setRoundingResult(null)
      setRoundingError(getErrorMessage(err))
    } finally {
      setRoundingLoading(false)
    }
  }

  const handleRateFileChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0] ?? null
    setRateFile(file)
    setParsedRateFile(null)
    setRateFileMessage(null)
    setRateFileError(null)
  }

  const handleRateFilePreview = async () => {
    if (!canEdit || !rateFile) {
      setRateFileError('Válassz GETARF árfolyamfájlt az előnézethez.')
      return
    }

    setRateFileLoading(true)
    setRateFileMessage(null)
    setRateFileError(null)
    try {
      const parsed = await exchangeRateApi.uploadRateFile(rateFile)
      setParsedRateFile(parsed)
      setRateFileMessage(
        `${parsed.parsedLineCount} feldolgozott sor, ${parsed.skippedLineCount} kihagyott sor.`,
      )
    } catch (err) {
      logger.error('RatesPage', 'Árfolyamfájl előnézet sikertelen:', err)
      setParsedRateFile(null)
      setRateFileError(getErrorMessage(err))
    } finally {
      setRateFileLoading(false)
    }
  }

  const handleRateFileImport = async () => {
    if (!canEdit || !rateFile) {
      setRateFileError('Válassz GETARF árfolyamfájlt az importhoz.')
      return
    }

    setRateFileLoading(true)
    setRateFileMessage(null)
    setRateFileError(null)
    try {
      const imported = await exchangeRateApi.importRateFile(rateFile)
      setRateFileMessage(`${imported.length} árfolyam importálva.`)
      setParsedRateFile(null)
      await loadRates()
    } catch (err) {
      logger.error('RatesPage', 'Árfolyamfájl import sikertelen:', err)
      setRateFileError(getErrorMessage(err))
    } finally {
      setRateFileLoading(false)
    }
  }

  // Determine which tiers to show (only show columns if any currency uses that tier)
  const showTier1 = anyHasTier(rates, 1)
  const showTier2 = anyHasTier(rates, 2)
  const showTier3 = anyHasTier(rates, 3)

  // Count dynamic tier column pairs for colSpan calculations
  const tierCount = (showTier1 ? 1 : 0) + (showTier2 ? 1 : 0) + (showTier3 ? 1 : 0)
  const currencyCodes = rates.map((rate) => rate.code)
  const currencyLabel = (code: string) => {
    if (code === 'HUF') return 'HUF - Magyar forint'
    const rate = rates.find((item) => item.code === code)
    return rate ? `${rate.code} - ${rate.name}` : code
  }
  const matrixPreview = Object.entries(matrix)
    .flatMap(([from, row]) => Object.entries(row).map(([to, value]) => ({ from, to, value })))
    .slice(0, 4)
  const activePollingSources = pollingSources.filter((source) => source.active).length
  const ecbRateEntries = Object.entries(ecbRates).slice(0, 4)
  const currentBankRates = bankRates.filter((rate) => rate.isCurrent !== false)
  const latestBankRate = currentBankRates[0] ?? bankRates[0]
  const latestCompetitorRate = competitorRates[0]
  const marketCurrencyCount = new Set([
    ...bankRates.map((rate) => rate.currencyCode).filter(Boolean),
    ...competitorRates.map((rate) => rate.currencyCode).filter(Boolean),
  ]).size
  const roundingCurrencyOptions = Array.from(
    new Set([...roundingRules.map((rule) => rule.currencyCode), ...currencyCodes]),
  ).filter(Boolean)
  const pollingStatusLabel = pollingStatus
    ? pollingStatus.lastPollSuccess
      ? 'Sikeres'
      : 'Hibás'
    : pollingError
      ? 'Nem elérhető'
      : 'Betöltés alatt'
  const pollingStatusClass = pollingStatus?.lastPollSuccess
    ? 'badge-green'
    : pollingStatus || pollingError
      ? 'badge-red'
      : 'badge-gray'

  // FK-041/II: az árfolyam néző NEM látja a belső területi árfolyamokat — a dedikált versenytárs-árfolyam
  // beíró oldalra irányítjuk (külön szkóp; a /rates-et más szerepköröknek nem szabályozzuk).
  if (isRateWatcherOnly) {
    return <Navigate to="/competitor-rates" replace />
  }

  return (
    <div className="space-y-1">
      {/* Compact header */}
      <div className="flex justify-between items-center gap-2 flex-wrap">
        <h1 className="text-sm font-bold text-gray-800 flex items-center gap-1.5">
          <TrendingUp size={16} />
          {t('cashier.rates')}
          {!canEdit && (
            <span className="text-[10px] text-gray-500 font-normal">{t('rates.nezet')}</span>
          )}
          {!canEdit && (
            <span className="text-[10px] text-blue-700 font-normal flex items-center gap-0.5 ml-1">
              <Eye size={10} />
              {t('rates.csakFoertektarSzerkesztheti')}
            </span>
          )}
          {lastRefresh && (
            <span className="text-[10px] text-gray-500 font-normal flex items-center gap-0.5 ml-1">
              <Clock size={10} />
              {t('rates.utolsoFrissites')} {lastRefresh}
              {rates.length > 0 && ` · ${rates.length} valuta`}
            </span>
          )}
        </h1>
        <div className="flex gap-1.5">
          {canEdit && (
            <button
              type="button"
              className="form-button flex items-center gap-1 h-6 text-[10px] px-2"
              onClick={() => void handleTriggerPolling()}
              disabled={pollingActionLoading === 'trigger'}
            >
              <Download size={12} />
              {t('rates.mnbLetoltes')}
            </button>
          )}
          <button
            className="form-button-primary flex items-center gap-1 h-6 text-[10px] px-2"
            onClick={() => void loadRates()}
            disabled={loading}
          >
            <RefreshCw size={12} className={loading ? 'animate-spin' : ''} />
            {t('common.refresh')}
          </button>
        </div>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200 text-red-700 px-2 py-1 text-xs rounded">
          {error}
        </div>
      )}

      {(rateApprovalMessage || rateApprovalError) && (
        <div
          className={`form-panel px-2 py-1 text-xs rounded ${rateApprovalError ? 'bg-red-50 border-red-200 text-red-700' : 'bg-emerald-50 border-emerald-200 text-emerald-800'}`}
        >
          {rateApprovalError || rateApprovalMessage}
        </div>
      )}

      {loading && rates.length === 0 && (
        <div className="flex items-center justify-center h-24">
          <RefreshCw className="animate-spin text-blue-600" size={28} />
        </div>
      )}

      {/* FK-041 — read-only (értéktár) TERÜLETI nézet: valutánként egy sor, és munkacsoportonként
          (árfolyam-variánsonként) egy oszlopcsoport a hozzá tartozó pénztárnevekkel a címsorban;
          a cellában az alap vétel/eladás + a kedvezmény-sávok. A főértéktáros a területen belül a
          pénztáraknak eltérő árfolyamot ad → minden eltérő variáns külön oszlopcsoport. */}
      {!canEdit &&
        territoryGroups.length > 0 &&
        (() => {
          // A sor-gerinc az ELSŐ munkacsoport valutalistája. Biztonságos, mert a backend MINDEN
          // munkacsoporthoz UGYANAZT az aktív valutalistát építi (findByActiveTrueOrderByDisplayOrderAsc),
          // így a currencyId-halmaz és a sorrend csoportonként azonos (TerritoryWorkgroupRateDTO).
          const spine = territoryGroups[0]?.currencies ?? []
          const findRate = (g: TerritoryWorkgroupRateDTO, currencyId: number) =>
            g.currencies.find((c) => c.currencyId === currencyId)
          const fmtRate = (v: number | null | undefined) =>
            v != null ? formatDecimal(v, 2, 2) : '—'
          return (
            <Fragment>
              {/* Munkacsoportonkénti oszlopcsoportok. A read-only nézet elsődleges fogyasztója a
                  local-first desktop értéktár-kliens; szűk web/PWA képernyőn vízszintes görgetés. */}
              <div className="form-panel overflow-x-auto p-0" data-testid="rates-territory-table">
                <table className="w-full border-collapse text-sm">
                  <thead>
                    <tr className="border-b border-gray-300 bg-gray-100 text-gray-600">
                      <th
                        scope="col"
                        rowSpan={2}
                        className="sticky left-0 z-10 bg-gray-100 px-3 py-2 text-left align-bottom font-semibold uppercase tracking-wide"
                      >
                        Valuta
                      </th>
                      {territoryGroups.map((g) => (
                        <th
                          key={g.workgroupId}
                          scope="colgroup"
                          colSpan={2}
                          className="border-r border-gray-300 px-3 py-2 text-left align-bottom"
                        >
                          <div className="font-semibold text-gray-800">{g.workgroupName}</div>
                          {g.branchNames.length > 0 && (
                            <div className="text-[11px] font-normal text-gray-500">
                              {g.branchNames.join(' · ')}
                            </div>
                          )}
                        </th>
                      ))}
                      <th
                        scope="col"
                        rowSpan={2}
                        className="px-3 py-2 text-right align-bottom font-semibold uppercase tracking-wide text-gray-400"
                      >
                        MNB
                      </th>
                    </tr>
                    <tr className="border-b-2 border-gray-300 bg-gray-50">
                      {territoryGroups.map((g) => (
                        <Fragment key={g.workgroupId}>
                          <th
                            scope="col"
                            className="px-3 py-1 text-right text-[11px] font-medium uppercase text-green-700"
                          >
                            {t('rates.vetel')}
                          </th>
                          <th
                            scope="col"
                            className="border-r border-gray-300 px-3 py-1 text-right text-[11px] font-medium uppercase text-red-700"
                          >
                            {t('rates.eladas')}
                          </th>
                        </Fragment>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {spine.map((s, idx) => {
                      const anyRate = territoryGroups
                        .map((g) => findRate(g, s.currencyId))
                        .find((c) => c?.hasRate)
                      return (
                        <tr
                          key={s.currencyId}
                          className={`${idx % 2 === 1 ? 'bg-gray-50' : 'bg-white'} border-b border-gray-100 last:border-0 hover:bg-blue-50/60`}
                        >
                          <td className="sticky left-0 z-10 whitespace-nowrap bg-inherit px-3 py-2 align-top">
                            <span className="font-mono text-base font-bold text-blue-800">
                              {s.currencyCode}
                            </span>
                            <span className="ml-2 text-gray-500">{s.currencyName}</span>
                          </td>
                          {territoryGroups.map((g) => {
                            const cr = findRate(g, s.currencyId)
                            return (
                              <td
                                key={g.workgroupId}
                                colSpan={2}
                                className="border-r border-gray-200 px-3 py-2 align-top"
                              >
                                {cr?.hasRate ? (
                                  <>
                                    <div className="font-mono text-base font-semibold tabular-nums">
                                      <span className="text-green-700">
                                        {fmtRate(cr.baseBuyRate)}
                                      </span>
                                      <span className="mx-1 text-gray-300">/</span>
                                      <span className="text-red-700">
                                        {fmtRate(cr.baseSellRate)}
                                      </span>
                                    </div>
                                    <div className="mt-1 space-y-0.5">
                                      {cr.limit1Amount != null &&
                                        (cr.limit1BuyRate != null || cr.limit1SellRate != null) && (
                                          <div className="whitespace-nowrap font-mono text-[10.5px] text-gray-500">
                                            ≥{formatHuf(cr.limit1Amount)}{' '}
                                            {fmtRate(cr.limit1BuyRate)} /{' '}
                                            {fmtRate(cr.limit1SellRate)}
                                          </div>
                                        )}
                                      {cr.limit2Amount != null &&
                                        (cr.limit2BuyRate != null || cr.limit2SellRate != null) && (
                                          <div className="whitespace-nowrap font-mono text-[10.5px] text-gray-500">
                                            ≥{formatHuf(cr.limit2Amount)}{' '}
                                            {fmtRate(cr.limit2BuyRate)} /{' '}
                                            {fmtRate(cr.limit2SellRate)}
                                          </div>
                                        )}
                                      {cr.limit3Amount != null &&
                                        (cr.limit3BuyRate != null || cr.limit3SellRate != null) && (
                                          <div className="whitespace-nowrap font-mono text-[10.5px] text-gray-500">
                                            ≥{formatHuf(cr.limit3Amount)}{' '}
                                            {fmtRate(cr.limit3BuyRate)} /{' '}
                                            {fmtRate(cr.limit3SellRate)}
                                          </div>
                                        )}
                                    </div>
                                    {cr.validTime && (
                                      <div className="mt-1 text-[10px] text-gray-400">
                                        frissítve {cr.validTime}
                                      </div>
                                    )}
                                  </>
                                ) : (
                                  <span className="text-gray-300">—</span>
                                )}
                              </td>
                            )
                          })}
                          <td className="px-3 py-2 text-right align-top font-mono tabular-nums text-gray-500">
                            {anyRate?.officialRate != null
                              ? formatDecimal(anyRate.officialRate, 2, 2)
                              : '—'}
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </Fragment>
          )
        })()}

      {/* FK-041 fallback — ha nincs területi munkacsoport-adat: egyszerű, gyorsan olvasható
          per-valuta táblázat (a korábbi read-only nézet). */}
      {!canEdit && !loading && territoryGroups.length === 0 && rates.length > 0 && (
        <>
          {/* Desktop: tiszta árfolyam-táblázat */}
          <div
            className="form-panel hidden overflow-x-auto p-0 md:block"
            data-testid="rates-readonly-table"
          >
            <table className="w-full border-collapse text-sm">
              <thead>
                <tr className="border-b-2 border-gray-300 bg-gray-100 text-gray-600">
                  <th className="px-3 py-2 text-left font-semibold uppercase tracking-wide">
                    Valuta
                  </th>
                  <th className="px-3 py-2 text-right font-semibold uppercase tracking-wide text-green-700">
                    {t('rates.vetel')}
                  </th>
                  <th className="px-3 py-2 text-right font-semibold uppercase tracking-wide text-red-700">
                    {t('rates.eladas')}
                  </th>
                  {showTier1 && (
                    <th className="px-3 py-2 text-right font-semibold uppercase tracking-wide text-emerald-700">
                      {t('rates.sav1')}
                    </th>
                  )}
                  {showTier2 && (
                    <th className="px-3 py-2 text-right font-semibold uppercase tracking-wide text-amber-700">
                      {t('rates.sav2')}
                    </th>
                  )}
                  {showTier3 && (
                    <th className="px-3 py-2 text-right font-semibold uppercase tracking-wide text-purple-700">
                      {t('rates.sav3')}
                    </th>
                  )}
                  <th className="px-3 py-2 text-right font-semibold uppercase tracking-wide text-gray-400">
                    MNB
                  </th>
                  <th className="px-3 py-2 text-right font-semibold uppercase tracking-wide text-gray-400">
                    Frissítve
                  </th>
                </tr>
              </thead>
              <tbody>
                {rates.map((rate, idx) => (
                  <tr
                    key={rate.id}
                    data-testid={rate.isStale ? `rate-row-stale-${rate.code}` : undefined}
                    className={`${
                      // FKH-032 FR-6: elavult árfolyam feltűnő, aktív jelzése — az ügyfél a
                      // teljes táblát látja, a problémának első pillantásra ki kell tűnnie.
                      rate.isStale
                        ? 'bg-red-100 ring-1 ring-inset ring-red-400'
                        : idx % 2 === 1
                          ? 'bg-gray-50/70'
                          : 'bg-white'
                    } border-b border-gray-100 last:border-0 hover:bg-blue-50/60`}
                  >
                    <td className="whitespace-nowrap px-3 py-2">
                      <span className="font-mono text-base font-bold text-blue-800">
                        {rate.code}
                      </span>
                      <span className="ml-2 text-gray-500">{rate.name}</span>
                      {rate.isStale && (
                        <span className="badge badge-red ml-2 align-middle">
                          Elavult árfolyam
                          {typeof rate.ageHours === 'number' ? ` (${rate.ageHours} órás)` : ''}
                        </span>
                      )}
                    </td>
                    <td className="px-3 py-2 text-right font-mono text-base font-semibold tabular-nums text-green-700">
                      {rate.hasRate ? (
                        formatDecimal(rate.buyRate, 2, 2)
                      ) : (
                        <span className="text-gray-300">—</span>
                      )}
                    </td>
                    <td className="px-3 py-2 text-right font-mono text-base font-semibold tabular-nums text-red-700">
                      {rate.hasRate ? (
                        formatDecimal(rate.sellRate, 2, 2)
                      ) : (
                        <span className="text-gray-300">—</span>
                      )}
                    </td>
                    {showTier1 && (
                      <td
                        className="px-3 py-2 text-right font-mono tabular-nums text-gray-700"
                        title={
                          rate.limit1Amount != null ? `≥ ${formatHuf(rate.limit1Amount)} Ft` : ''
                        }
                      >
                        {rate.limit1BuyRate != null || rate.limit1SellRate != null
                          ? `${rate.limit1BuyRate != null ? formatDecimal(rate.limit1BuyRate, 2, 2) : '—'} / ${rate.limit1SellRate != null ? formatDecimal(rate.limit1SellRate, 2, 2) : '—'}`
                          : '—'}
                      </td>
                    )}
                    {showTier2 && (
                      <td
                        className="px-3 py-2 text-right font-mono tabular-nums text-gray-700"
                        title={
                          rate.limit2Amount != null ? `≥ ${formatHuf(rate.limit2Amount)} Ft` : ''
                        }
                      >
                        {rate.limit2BuyRate != null || rate.limit2SellRate != null
                          ? `${rate.limit2BuyRate != null ? formatDecimal(rate.limit2BuyRate, 2, 2) : '—'} / ${rate.limit2SellRate != null ? formatDecimal(rate.limit2SellRate, 2, 2) : '—'}`
                          : '—'}
                      </td>
                    )}
                    {showTier3 && (
                      <td
                        className="px-3 py-2 text-right font-mono tabular-nums text-gray-700"
                        title={
                          rate.limit3Amount != null ? `≥ ${formatHuf(rate.limit3Amount)} Ft` : ''
                        }
                      >
                        {rate.limit3BuyRate != null || rate.limit3SellRate != null
                          ? `${rate.limit3BuyRate != null ? formatDecimal(rate.limit3BuyRate, 2, 2) : '—'} / ${rate.limit3SellRate != null ? formatDecimal(rate.limit3SellRate, 2, 2) : '—'}`
                          : '—'}
                      </td>
                    )}
                    <td className="px-3 py-2 text-right font-mono tabular-nums text-gray-500">
                      {rate.mnbRate > 0 ? formatDecimal(rate.mnbRate, 2, 2) : '—'}
                    </td>
                    <td className="whitespace-nowrap px-3 py-2 text-right text-xs text-gray-400">
                      {rate.lastUpdate || '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Mobil: egyszerű, soronkénti árfolyam-lista */}
          <div className="space-y-1.5 md:hidden">
            {rates.map((rate) => (
              <div
                key={rate.id}
                className="form-panel flex items-center justify-between gap-3 py-2"
                data-testid="rates-readonly-row"
              >
                <div className="min-w-0">
                  <div className="font-mono text-base font-bold text-blue-800">{rate.code}</div>
                  <div className="truncate text-xs text-gray-500">{rate.name}</div>
                </div>
                <div className="flex shrink-0 items-center gap-4 text-right">
                  <div>
                    <div className="text-[10px] uppercase text-gray-400">{t('rates.vetel')}</div>
                    <div className="font-mono text-base font-semibold text-green-700">
                      {rate.hasRate ? formatDecimal(rate.buyRate, 2, 2) : '—'}
                    </div>
                  </div>
                  <div>
                    <div className="text-[10px] uppercase text-gray-400">{t('rates.eladas')}</div>
                    <div className="font-mono text-base font-semibold text-red-700">
                      {rate.hasRate ? formatDecimal(rate.sellRate, 2, 2) : '—'}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {/* FK-041: a metrika-kártyák (polling/ECB/piaci) + vezérlés CSAK szerkesztőnek. */}
      {canEdit && rates.length > 0 && (
        <div className="form-panel">
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
            <div className="rounded border border-gray-200 bg-white p-3">
              <div className="mb-1 flex items-center justify-between gap-2">
                <span className="text-xs font-semibold uppercase text-gray-500">
                  Polling státusz
                </span>
                <span className={`badge ${pollingStatusClass}`}>{pollingStatusLabel}</span>
              </div>
              <div className="text-sm text-gray-900">
                Forrás: {pollingStatus?.lastPollSource || '-'}
              </div>
              <div className="text-xs text-gray-500">
                Utolsó futás:{' '}
                {pollingStatus?.lastPollTime
                  ? new Date(pollingStatus.lastPollTime).toLocaleString('hu-HU')
                  : '-'}
              </div>
              {pollingStatus?.lastPollError && (
                <div className="mt-1 text-xs text-red-700">{pollingStatus.lastPollError}</div>
              )}
              {pollingError && <div className="mt-1 text-xs text-red-700">{pollingError}</div>}
            </div>
            <div className="rounded border border-gray-200 bg-white p-3">
              <div className="text-xs font-semibold uppercase text-gray-500">
                Frissített tételek
              </div>
              <div className="mt-1 text-2xl font-bold text-gray-900">
                {pollingStatus?.lastPollUpdatedCount ?? 0}
              </div>
              <div className="text-xs text-gray-500">utolsó polling futásban</div>
            </div>
            <div className="rounded border border-gray-200 bg-white p-3">
              <div className="text-xs font-semibold uppercase text-gray-500">Árfolyam források</div>
              <div className="mt-1 text-2xl font-bold text-gray-900">
                {activePollingSources} / {pollingSources.length}
              </div>
              <div className="mt-2 flex flex-wrap gap-1">
                {pollingSources.length === 0 ? (
                  <span className="text-xs text-gray-500">Nincs forrásadat.</span>
                ) : (
                  pollingSources.slice(0, 4).map((source) => (
                    <span
                      key={source.id}
                      className={`badge ${source.active ? 'badge-green' : 'badge-gray'}`}
                    >
                      {source.name}
                    </span>
                  ))
                )}
              </div>
            </div>
            <div
              className="rounded border border-gray-200 bg-white p-3"
              data-testid="ecb-rate-snapshot"
            >
              <div className="mb-1 flex items-center justify-between gap-2">
                <span className="text-xs font-semibold uppercase text-gray-500">
                  {t('rates.ecbSnapshot')}
                </span>
                <span
                  className={`badge ${ecbRateError ? 'badge-red' : ecbRateEntries.length > 0 ? 'badge-green' : 'badge-gray'}`}
                >
                  {ecbRateError ? 'Nem elérhető' : `${Object.keys(ecbRates).length} deviza`}
                </span>
              </div>
              {ecbRateError ? (
                <div className="text-xs text-red-700">{ecbRateError}</div>
              ) : ecbRateEntries.length === 0 ? (
                <div className="text-xs text-gray-500">{t('rates.nincsEcbAdat')}</div>
              ) : (
                <div className="mt-2 grid grid-cols-2 gap-1 text-xs">
                  {ecbRateEntries.map(([currency, value]) => (
                    <div key={currency} className="rounded bg-emerald-50 px-2 py-1">
                      <div className="text-[10px] font-semibold uppercase text-emerald-700">
                        {currency}
                      </div>
                      <div className="font-semibold text-emerald-900">
                        {formatDecimal(numericAmount(value), 2, 4)}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div
              className="rounded border border-gray-200 bg-white p-3"
              data-testid="market-rate-snapshot"
            >
              <div className="mb-1 flex items-center justify-between gap-2">
                <span className="text-xs font-semibold uppercase text-gray-500">
                  Piaci összehasonlítás
                </span>
                <span className={`badge ${marketRateError ? 'badge-red' : 'badge-green'}`}>
                  {marketRateError ? 'Nem elérhető' : `${marketCurrencyCount} deviza`}
                </span>
              </div>
              {marketRateError ? (
                <div className="text-xs text-red-700">{marketRateError}</div>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div className="rounded bg-blue-50 px-2 py-1">
                      <div className="text-[10px] uppercase text-blue-700">Bank ráták</div>
                      <div className="font-semibold text-blue-900">
                        {currentBankRates.length} / {bankRates.length}
                      </div>
                    </div>
                    <div className="rounded bg-amber-50 px-2 py-1">
                      <div className="text-[10px] uppercase text-amber-700">Versenytárs</div>
                      <div className="font-semibold text-amber-900">{competitorRates.length}</div>
                    </div>
                  </div>
                  <div className="mt-2 space-y-1 text-xs text-gray-600">
                    <div>
                      Bank:{' '}
                      {latestBankRate
                        ? `${latestBankRate.bankCode ?? latestBankRate.bankName} ${latestBankRate.currencyCode} ${formatDecimal(numericAmount(latestBankRate.buyRate), 2, 4)} / ${formatDecimal(numericAmount(latestBankRate.sellRate), 2, 4)}`
                        : '-'}
                    </div>
                    <div>
                      Versenytárs:{' '}
                      {latestCompetitorRate
                        ? `${latestCompetitorRate.competitorCode ?? latestCompetitorRate.competitorName} ${latestCompetitorRate.currencyCode} ${formatDecimal(numericAmount(latestCompetitorRate.buyRate), 2, 4)} / ${formatDecimal(numericAmount(latestCompetitorRate.sellRate), 2, 4)}`
                        : '-'}
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>
          {canEdit && (
            <div
              className="mt-3 rounded border border-gray-200 bg-gray-50 p-3"
              data-testid="rate-polling-control-panel"
            >
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    Árfolyam polling vezérlés
                  </div>
                  <div className="text-xs text-gray-600">
                    MNB polling indítás, margin alkalmazás és forráskonfiguráció.
                  </div>
                </div>
                <button
                  type="button"
                  className="form-button-primary h-9 whitespace-nowrap"
                  onClick={() => void handleTriggerPolling()}
                  disabled={pollingActionLoading === 'trigger'}
                >
                  {pollingActionLoading === 'trigger' ? 'Indítás...' : 'MNB polling indítása'}
                </button>
              </div>

              <div className="mt-3 grid gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)]">
                <div className="rounded border border-gray-200 bg-white p-3">
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    Margin alkalmazás
                  </div>
                  <div className="mt-2 grid gap-2 sm:grid-cols-[minmax(0,1fr)_110px_auto] sm:items-end lg:grid-cols-1 xl:grid-cols-[minmax(0,1fr)_110px_auto]">
                    <div>
                      <label className="form-label">Devizanem</label>
                      <select
                        className="form-input h-9"
                        value={marginCurrencyId}
                        onChange={(event) =>
                          setMarginCurrencyId(event.target.value ? Number(event.target.value) : '')
                        }
                      >
                        {rates.map((rate) => (
                          <option key={rate.currencyId} value={rate.currencyId}>
                            {rate.code} - {rate.name}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="form-label" htmlFor="polling-margin-spread">
                        Spread
                      </label>
                      <NumberInput
                        id="polling-margin-spread"
                        value={marginSpread}
                        onChange={setMarginSpread}
                        className="form-input h-9 font-mono"
                        allowDecimals
                        allowNegative={false}
                        min={0}
                      />
                    </div>
                    <button
                      type="button"
                      className="form-button h-9 whitespace-nowrap"
                      onClick={() => void handleApplyMargins()}
                      disabled={pollingActionLoading === 'apply-margins'}
                    >
                      Alkalmaz
                    </button>
                  </div>
                </div>

                <div className="rounded border border-gray-200 bg-white p-3">
                  <div className="text-xs font-semibold uppercase text-gray-500">Források</div>
                  <div className="mt-2 space-y-2">
                    {pollingSources.length === 0 ? (
                      <div className="text-xs text-gray-500">Nincs módosítható polling forrás.</div>
                    ) : (
                      pollingSources.map((source) => (
                        <div
                          key={source.id}
                          className="grid gap-2 rounded border border-gray-100 bg-gray-50 p-2 text-xs sm:grid-cols-[minmax(0,1fr)_110px_110px] sm:items-center"
                        >
                          <div className="min-w-0">
                            <div className="font-semibold text-gray-900">{source.name}</div>
                            <div className="truncate text-gray-500">
                              {source.url ?? 'Nincs URL'}
                            </div>
                          </div>
                          <label className="inline-flex items-center gap-2 font-semibold text-gray-700">
                            <input
                              type="checkbox"
                              checked={source.active}
                              disabled={pollingActionLoading === `source-${source.id}`}
                              onChange={(event) =>
                                void handleUpdatePollingSource(source, {
                                  active: event.target.checked,
                                })
                              }
                            />
                            Aktív
                          </label>
                          <select
                            className="form-input h-8 text-xs"
                            value={source.pollIntervalMinutes ?? ''}
                            disabled={pollingActionLoading === `source-${source.id}`}
                            aria-label={`${source.name} polling intervallum`}
                            onChange={(event) =>
                              void handleUpdatePollingSource(source, {
                                pollIntervalMinutes: Number(event.target.value),
                              })
                            }
                          >
                            {[15, 30, 60, 180, 360, 720, 1440].map((minutes) => (
                              <option key={minutes} value={minutes}>
                                {minutes} perc
                              </option>
                            ))}
                          </select>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </div>

              {(pollingActionMessage || pollingActionError) && (
                <div
                  className={`mt-3 rounded px-3 py-2 text-xs ${pollingActionError ? 'border border-red-200 bg-red-50 text-red-700' : 'border border-emerald-200 bg-emerald-50 text-emerald-800'}`}
                >
                  {pollingActionError || pollingActionMessage}
                </div>
              )}

              <div
                className="mt-3 rounded border border-gray-200 bg-white p-3"
                data-testid="rate-file-import-panel"
              >
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      GETARF árfolyamfájl
                    </div>
                    <div className="text-xs text-gray-600">
                      Legacy árfolyamfájl előnézet és célzott import a backend parseren keresztül.
                    </div>
                  </div>
                  <span className={`badge ${parsedRateFile ? 'badge-green' : 'badge-gray'}`}>
                    {parsedRateFile ? `${parsedRateFile.rates.length} deviza` : 'Nincs előnézet'}
                  </span>
                </div>
                <div className="mt-3 grid gap-2 md:grid-cols-[minmax(0,1fr)_auto_auto] md:items-end">
                  <div>
                    <label className="form-label" htmlFor="rate-file-input">
                      Árfolyamfájl
                    </label>
                    <input
                      id="rate-file-input"
                      type="file"
                      className="form-input h-9"
                      accept=".dat,.txt,.csv"
                      onChange={handleRateFileChange}
                      data-testid="rate-file-input"
                    />
                    {rateFile && <div className="mt-1 text-xs text-gray-500">{rateFile.name}</div>}
                  </div>
                  <button
                    type="button"
                    className="form-button h-9 whitespace-nowrap"
                    onClick={() => void handleRateFilePreview()}
                    disabled={rateFileLoading || !rateFile}
                  >
                    <Eye size={14} />
                    Előnézet
                  </button>
                  <button
                    type="button"
                    className="form-button-primary h-9 whitespace-nowrap"
                    onClick={() => void handleRateFileImport()}
                    disabled={rateFileLoading || !rateFile}
                  >
                    <Upload size={14} />
                    Import
                  </button>
                </div>
                {(rateFileMessage || rateFileError) && (
                  <div
                    className={`mt-3 rounded px-3 py-2 text-xs ${rateFileError ? 'border border-red-200 bg-red-50 text-red-700' : 'border border-emerald-200 bg-emerald-50 text-emerald-800'}`}
                  >
                    {rateFileError || rateFileMessage}
                  </div>
                )}
                {parsedRateFile && (
                  <div className="mt-3 overflow-x-auto">
                    <table className="data-grid min-w-full text-xs">
                      <thead>
                        <tr>
                          <th>Deviza</th>
                          <th>Vétel</th>
                          <th>Eladás</th>
                          <th>MNB</th>
                          <th>Kedv. vétel</th>
                          <th>Kedv. eladás</th>
                        </tr>
                      </thead>
                      <tbody>
                        {parsedRateFile.rates.slice(0, 8).map((rate) => (
                          <tr key={rate.currencyCode}>
                            <td className="font-mono font-semibold">{rate.currencyCode}</td>
                            <td className="font-mono">
                              {formatDecimal(numericAmount(rate.buyRate), 2, 4)}
                            </td>
                            <td className="font-mono">
                              {formatDecimal(numericAmount(rate.sellRate), 2, 4)}
                            </td>
                            <td className="font-mono">
                              {formatDecimal(numericAmount(rate.mnbRate), 2, 4)}
                            </td>
                            <td className="font-mono">
                              {formatDecimal(numericAmount(rate.discountBuy), 2, 4)}
                            </td>
                            <td className="font-mono">
                              {formatDecimal(numericAmount(rate.discountSell), 2, 4)}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      )}

      {/* FK-041: a kalkulátor CSAK szerkesztőnek (a read-only értéktár-nézet egyszerű marad). */}
      {canEdit && rates.length > 0 && (
        <div className="form-panel">
          <div className="mb-2 flex items-center gap-2 text-sm font-bold text-gray-800">
            <Calculator size={16} />
            Árfolyam kalkulátor
          </div>
          <div className="grid gap-3 xl:grid-cols-[1.4fr_1fr_1fr]">
            <div className="grid gap-2 sm:grid-cols-[1fr_110px_110px_90px_auto] sm:items-end">
              <div>
                <label className="form-label">Összeg</label>
                <NumberInput
                  value={calculatorAmount}
                  onChange={setCalculatorAmount}
                  className="form-input h-9 font-mono"
                  allowDecimals
                  allowNegative={false}
                  min={0}
                />
              </div>
              <div>
                <label className="form-label">Forrás</label>
                <select
                  className="form-input h-9"
                  value={calculatorFrom}
                  onChange={(event) => setCalculatorFrom(event.target.value)}
                >
                  {currencyCodes.map((code) => (
                    <option key={code} value={code}>
                      {currencyLabel(code)}
                    </option>
                  ))}
                  <option value="HUF">{currencyLabel('HUF')}</option>
                </select>
              </div>
              <div>
                <label className="form-label">Cél</label>
                <select
                  className="form-input h-9"
                  value={calculatorTo}
                  onChange={(event) => setCalculatorTo(event.target.value)}
                >
                  <option value="HUF">{currencyLabel('HUF')}</option>
                  {currencyCodes.map((code) => (
                    <option key={code} value={code}>
                      {currencyLabel(code)}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="form-label">Irány</label>
                <select
                  className="form-input h-9"
                  value={calculatorDirection}
                  onChange={(event) =>
                    setCalculatorDirection(event.target.value as CalculatorDirection)
                  }
                >
                  <option value="BUY">BUY</option>
                  <option value="SELL">SELL</option>
                </select>
              </div>
              <button
                type="button"
                className="form-button-primary h-9 whitespace-nowrap"
                onClick={() => void handleConvert()}
                disabled={calculatorLoading}
              >
                Számol
              </button>
            </div>

            <div className="grid gap-2 sm:grid-cols-[1fr_110px_auto] sm:items-end xl:grid-cols-[1fr_90px_auto]">
              <div>
                <label className="form-label">HUF keret</label>
                <NumberInput
                  value={reverseHufAmount}
                  onChange={setReverseHufAmount}
                  className="form-input h-9 font-mono"
                  allowDecimals
                  allowNegative={false}
                  min={0}
                />
              </div>
              <div>
                <label className="form-label">Deviza</label>
                <select
                  className="form-input h-9"
                  value={reverseCurrency}
                  onChange={(event) => setReverseCurrency(event.target.value)}
                >
                  {currencyCodes.map((code) => (
                    <option key={code} value={code}>
                      {currencyLabel(code)}
                    </option>
                  ))}
                </select>
              </div>
              <button
                type="button"
                className="form-button h-9 whitespace-nowrap"
                onClick={() => void handleReverse()}
                disabled={reverseLoading}
              >
                Fordított
              </button>
            </div>

            <div className="rounded-md border border-gray-200 bg-gray-50 p-2 text-xs">
              <div className="font-semibold text-gray-700">Cross-rate mátrix</div>
              {matrixPreview.length === 0 ? (
                <div className="mt-1 text-gray-500">Nincs mátrix adat.</div>
              ) : (
                <div className="mt-1 grid grid-cols-2 gap-1">
                  {matrixPreview.map((item) => (
                    <div key={`${item.from}-${item.to}`} className="font-mono text-gray-700">
                      {item.from}/{item.to}: {formatDecimal(Number(item.value), 6, 6)}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {(calculatorResult || reverseResult || calculatorError) && (
            <div className="mt-3 grid gap-2 text-xs md:grid-cols-2">
              {calculatorResult && (
                <div className="rounded-md border border-blue-200 bg-blue-50 px-3 py-2 text-blue-900">
                  <div className="font-semibold">Átváltás eredménye</div>
                  <div>
                    {calculatorResult.fromAmount} {calculatorResult.fromCurrency} →{' '}
                    {formatDecimal(Number(calculatorResult.toAmount), 2, 4)}{' '}
                    {calculatorResult.toCurrency}
                  </div>
                  <div>
                    Árfolyam: {formatDecimal(Number(calculatorResult.appliedRate), 2, 6)} · Díj:{' '}
                    {formatDecimal(Number(calculatorResult.commission), 0, 0)} Ft
                  </div>
                </div>
              )}
              {reverseResult && (
                <div className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-emerald-900">
                  <div className="font-semibold">Fordított kalkuláció</div>
                  <div>
                    {formatDecimal(Number(reverseResult.hufAmount), 0, 0)} HUF →{' '}
                    {formatDecimal(Number(reverseResult.foreignAmount), 2, 4)}{' '}
                    {reverseResult.currency}
                  </div>
                </div>
              )}
              {calculatorError && (
                <div className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-amber-800">
                  {calculatorError}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {canEdit && rates.length > 0 && (
        <div className="form-panel" data-testid="rounding-rules-panel">
          <div className="mb-2 flex items-center gap-2 text-sm font-bold text-gray-800">
            <Calculator size={16} />
            Kerekítési szabályok
          </div>
          <div className="grid gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(280px,360px)]">
            <div className="space-y-2">
              <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-3">
                {roundingRules.length === 0 ? (
                  <div className="rounded border border-gray-200 bg-white p-3 text-xs text-gray-500">
                    Nincs kerekítési szabályadat.
                  </div>
                ) : (
                  roundingRules.slice(0, 6).map((rule) => (
                    <div
                      key={rule.id ?? rule.currencyCode}
                      className="rounded border border-gray-200 bg-white p-3"
                      data-testid="rounding-rule-mobile-card"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="font-mono text-sm font-bold text-blue-700">
                          {rule.currencyCode}
                        </div>
                        <span className="badge badge-gray">
                          {formatDecimal(numericAmount(rule.precisionValue), 0, 4)}
                        </span>
                      </div>
                      <div className="mt-2 grid grid-cols-2 gap-2 text-xs">
                        <div className="rounded bg-emerald-50 px-2 py-1">
                          <div className="text-[10px] uppercase text-emerald-700">Kis összeg</div>
                          <div className="font-mono font-semibold text-emerald-900">
                            &lt; {formatDecimal(numericAmount(rule.smallThreshold), 0, 2)}
                          </div>
                          <div className="text-[11px] text-emerald-700">{rule.smallRounding}</div>
                        </div>
                        <div className="rounded bg-amber-50 px-2 py-1">
                          <div className="text-[10px] uppercase text-amber-700">Nagy összeg</div>
                          <div className="font-mono font-semibold text-amber-900">
                            &gt; {formatDecimal(numericAmount(rule.largeThreshold), 0, 2)}
                          </div>
                          <div className="text-[11px] text-amber-700">{rule.largeRounding}</div>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
              {roundingRules.length > 6 && (
                <div className="text-[11px] text-gray-500">
                  További szabályok: {roundingRules.length - 6}
                </div>
              )}
            </div>

            <div className="rounded border border-gray-200 bg-gray-50 p-3">
              <div className="text-xs font-semibold uppercase text-gray-500">Kerekítési próba</div>
              <div className="mt-2 grid gap-2 sm:grid-cols-[1fr_92px_92px] lg:grid-cols-1">
                <div>
                  <label className="form-label">Összeg</label>
                  <NumberInput
                    value={roundingAmount}
                    onChange={setRoundingAmount}
                    className="form-input h-9 font-mono"
                    allowDecimals
                    allowNegative={false}
                    min={0}
                  />
                </div>
                <div>
                  <label className="form-label">Deviza</label>
                  <select
                    className="form-input h-9"
                    value={roundingCurrency}
                    onChange={(event) => setRoundingCurrency(event.target.value)}
                  >
                    {(roundingCurrencyOptions.length > 0
                      ? roundingCurrencyOptions
                      : currencyCodes
                    ).map((code) => (
                      <option key={code} value={code}>
                        {currencyLabel(code)}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="form-label">Irány</label>
                  <select
                    className="form-input h-9"
                    value={roundingDirection}
                    onChange={(event) =>
                      setRoundingDirection(event.target.value as RoundingDirection)
                    }
                  >
                    <option value="BUY">BUY</option>
                    <option value="SELL">SELL</option>
                  </select>
                </div>
              </div>
              <button
                type="button"
                className="form-button-primary mt-2 h-9 w-full"
                onClick={() => void handleRoundingProbe()}
                disabled={roundingLoading}
              >
                Kerekítés próba
              </button>
              {(roundingRule || roundingResult || roundingError) && (
                <div className="mt-3 space-y-2 text-xs">
                  {roundingRule && (
                    <div className="rounded border border-blue-200 bg-blue-50 px-3 py-2 text-blue-900">
                      <div className="font-semibold">
                        Aktív szabály: {roundingRule.currencyCode}
                      </div>
                      <div>
                        Precízió: {formatDecimal(numericAmount(roundingRule.precisionValue), 0, 4)}
                      </div>
                    </div>
                  )}
                  {roundingResult && (
                    <div className="rounded border border-emerald-200 bg-emerald-50 px-3 py-2 text-emerald-900">
                      <div className="font-semibold">Kerekített eredmény</div>
                      <div>
                        {formatDecimal(numericAmount(roundingResult.original), 0, 4)}
                        {' → '}
                        {formatDecimal(numericAmount(roundingResult.rounded), 0, 4)}
                      </div>
                    </div>
                  )}
                  {roundingError && (
                    <div className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-amber-800">
                      {roundingError}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Dense editor table (mobile cards) — CSAK szerkesztőnek; a read-only nézet a fenti
          tiszta táblát/listát használja (FK-041). */}
      {canEdit && rates.length > 0 && (
        <div className="grid gap-2 md:hidden">
          {rates.map((rate) => (
            <div key={rate.id} className="form-panel space-y-2" data-testid="rate-mobile-card">
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <div className="font-mono text-sm font-bold text-blue-700">
                    {rate.code} - {rate.name}
                  </div>
                  <div className="text-[11px] text-gray-500">
                    Frissítve: {rate.lastUpdate || '-'}
                  </div>
                </div>
                {!rate.hasRate && <span className="badge badge-gray">Nincs árfolyam</span>}
              </div>
              <div className="grid grid-cols-3 gap-2 text-xs">
                <div className="rounded border border-gray-200 bg-white px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">Vétel</div>
                  <div className="font-mono font-semibold text-green-700">
                    {rate.hasRate ? formatDecimal(rate.buyRate, 2, 2) : '-'}
                  </div>
                </div>
                <div className="rounded border border-gray-200 bg-white px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">Eladás</div>
                  <div className="font-mono font-semibold text-red-700">
                    {rate.hasRate ? formatDecimal(rate.sellRate, 2, 2) : '-'}
                  </div>
                </div>
                <div className="rounded border border-gray-200 bg-white px-2 py-1">
                  <div className="text-[10px] uppercase text-gray-500">MNB</div>
                  <div className="font-mono font-semibold text-gray-700">
                    {rate.mnbRate > 0 ? formatDecimal(rate.mnbRate, 2, 2) : '-'}
                  </div>
                </div>
              </div>
              {(showTier1 || showTier2 || showTier3) && (
                <div className="grid gap-1 text-[11px] text-gray-600">
                  {showTier1 && (
                    <div className="flex justify-between rounded bg-emerald-50 px-2 py-1">
                      <span>
                        1. sáv{' '}
                        {rate.limit1Amount != null ? `>= ${formatHuf(rate.limit1Amount)} Ft` : ''}
                      </span>
                      <span className="font-mono">
                        {rate.limit1BuyRate != null ? formatDecimal(rate.limit1BuyRate, 2, 2) : '-'}{' '}
                        /{' '}
                        {rate.limit1SellRate != null
                          ? formatDecimal(rate.limit1SellRate, 2, 2)
                          : '-'}
                      </span>
                    </div>
                  )}
                  {showTier2 && (
                    <div className="flex justify-between rounded bg-amber-50 px-2 py-1">
                      <span>
                        2. sáv{' '}
                        {rate.limit2Amount != null ? `>= ${formatHuf(rate.limit2Amount)} Ft` : ''}
                      </span>
                      <span className="font-mono">
                        {rate.limit2BuyRate != null ? formatDecimal(rate.limit2BuyRate, 2, 2) : '-'}{' '}
                        /{' '}
                        {rate.limit2SellRate != null
                          ? formatDecimal(rate.limit2SellRate, 2, 2)
                          : '-'}
                      </span>
                    </div>
                  )}
                  {showTier3 && (
                    <div className="flex justify-between rounded bg-purple-50 px-2 py-1">
                      <span>
                        3. sáv{' '}
                        {rate.limit3Amount != null ? `>= ${formatHuf(rate.limit3Amount)} Ft` : ''}
                      </span>
                      <span className="font-mono">
                        {rate.limit3BuyRate != null ? formatDecimal(rate.limit3BuyRate, 2, 2) : '-'}{' '}
                        /{' '}
                        {rate.limit3SellRate != null
                          ? formatDecimal(rate.limit3SellRate, 2, 2)
                          : '-'}
                      </span>
                    </div>
                  )}
                </div>
              )}
              {canEdit && (
                <button
                  type="button"
                  onClick={() => startEdit(rate)}
                  className="form-button flex h-8 w-full items-center justify-center gap-1 text-xs"
                >
                  <Edit size={12} />
                  Szerkesztés
                </button>
              )}
            </div>
          ))}
        </div>
      )}

      {canEdit && rates.length > 0 && (
        <div className="form-panel hidden p-0 overflow-x-auto md:block">
          <table className="w-full border-collapse" style={{ fontSize: '11px' }}>
            {/* Two-row header: tier group names + buy/sell sub-headers */}
            <thead>
              {/* Row 1: grouped tier headers */}
              <tr className="bg-gray-100 border-b border-gray-300">
                <th
                  rowSpan={2}
                  className="px-1 py-0.5 text-left text-[10px] uppercase text-gray-500 border-r border-gray-200 w-10 font-semibold"
                >
                  {t('common.code')}
                </th>
                <th
                  colSpan={2}
                  className="px-1 py-0.5 text-center text-[10px] uppercase font-semibold border-r border-gray-300 bg-blue-50 text-blue-800"
                >
                  {t('rates.alap')}
                </th>
                {showTier1 && (
                  <th
                    colSpan={2}
                    className="px-1 py-0.5 text-center text-[10px] uppercase font-semibold border-r border-gray-300 bg-emerald-50 text-emerald-800"
                  >
                    {t('rates.sav1')}
                  </th>
                )}
                {showTier2 && (
                  <th
                    colSpan={2}
                    className="px-1 py-0.5 text-center text-[10px] uppercase font-semibold border-r border-gray-300 bg-amber-50 text-amber-800"
                  >
                    {t('rates.sav2')}
                  </th>
                )}
                {showTier3 && (
                  <th
                    colSpan={2}
                    className="px-1 py-0.5 text-center text-[10px] uppercase font-semibold border-r border-gray-300 bg-purple-50 text-purple-800"
                  >
                    {t('rates.sav3')}
                  </th>
                )}
                <th
                  rowSpan={2}
                  className="px-1 py-0.5 text-center text-[10px] uppercase text-gray-500 w-14 font-semibold"
                >
                  MNB
                </th>
                {canEdit && (
                  <th
                    rowSpan={2}
                    className="px-0.5 py-0.5 text-center text-[10px] uppercase text-gray-500 w-10 font-semibold"
                  >
                    <Edit size={10} className="mx-auto" />
                  </th>
                )}
              </tr>
              {/* Row 2: buy/sell sub-headers */}
              <tr className="bg-gray-50 border-b border-gray-300">
                {/* Alap buy/sell */}
                <th className="px-1 py-0.5 text-right text-[9px] uppercase text-green-700 font-medium border-r border-gray-100 bg-blue-50/50">
                  {t('rates.vetel')}
                </th>
                <th className="px-1 py-0.5 text-right text-[9px] uppercase text-red-700 font-medium border-r border-gray-200 bg-blue-50/50">
                  {t('rates.eladas')}
                </th>
                {/* Tier 1 buy/sell */}
                {showTier1 && (
                  <>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-green-700 font-medium border-r border-gray-100 bg-emerald-50/50">
                      {t('rates.vetel')}
                    </th>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-red-700 font-medium border-r border-gray-200 bg-emerald-50/50">
                      {t('rates.eladas')}
                    </th>
                  </>
                )}
                {/* Tier 2 buy/sell */}
                {showTier2 && (
                  <>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-green-700 font-medium border-r border-gray-100 bg-amber-50/50">
                      {t('rates.vetel')}
                    </th>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-red-700 font-medium border-r border-gray-200 bg-amber-50/50">
                      {t('rates.eladas')}
                    </th>
                  </>
                )}
                {/* Tier 3 buy/sell */}
                {showTier3 && (
                  <>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-green-700 font-medium border-r border-gray-100 bg-purple-50/50">
                      {t('rates.vetel')}
                    </th>
                    <th className="px-1 py-0.5 text-right text-[9px] uppercase text-red-700 font-medium border-r border-gray-200 bg-purple-50/50">
                      {t('rates.eladas')}
                    </th>
                  </>
                )}
              </tr>
            </thead>
            <tbody>
              {rates.map((rate, idx) => (
                <tr
                  key={rate.id}
                  className={`${idx % 2 === 1 ? 'bg-gray-50/70' : ''} hover:bg-blue-50/60 border-b border-gray-100 last:border-0`}
                  title={`${rate.name} — Frissítve: ${rate.lastUpdate}`}
                >
                  {/* Currency code */}
                  <td className="px-1 py-px border-r border-gray-100">
                    <span
                      className="font-mono font-bold text-blue-700 text-[11px]"
                      title={rate.name}
                    >
                      {rate.code}
                    </span>
                  </td>

                  {/* Base buy rate */}
                  <td className="px-1 py-px text-right border-r border-gray-100">
                    {editingCode === rate.code && canEdit ? (
                      <NumberInput
                        value={editValues.buyRate.toString().replace('.', ',')}
                        onChange={(val) =>
                          setEditValues({
                            ...editValues,
                            buyRate: parseFloat(val.replace(',', '.')) || 0,
                          })
                        }
                        className="form-input w-16 text-right text-[11px] py-0 px-0.5"
                        allowDecimals={true}
                        allowNegative={false}
                        step="0.01"
                        disabled={!canEdit}
                      />
                    ) : rate.hasRate ? (
                      <span className="font-mono text-green-700 font-semibold">
                        {formatDecimal(rate.buyRate, 2, 2)}
                      </span>
                    ) : (
                      <span className="text-gray-300">&mdash;</span>
                    )}
                  </td>

                  {/* Base sell rate */}
                  <td className="px-1 py-px text-right border-r border-gray-200">
                    {editingCode === rate.code && canEdit ? (
                      <NumberInput
                        value={editValues.sellRate.toString().replace('.', ',')}
                        onChange={(val) =>
                          setEditValues({
                            ...editValues,
                            sellRate: parseFloat(val.replace(',', '.')) || 0,
                          })
                        }
                        className="form-input w-16 text-right text-[11px] py-0 px-0.5"
                        allowDecimals={true}
                        allowNegative={false}
                        step="0.01"
                        disabled={!canEdit}
                      />
                    ) : rate.hasRate ? (
                      <span className="font-mono text-red-700 font-semibold">
                        {formatDecimal(rate.sellRate, 2, 2)}
                      </span>
                    ) : (
                      <span className="text-gray-300">&mdash;</span>
                    )}
                  </td>

                  {/* Tier 1 buy */}
                  {showTier1 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-100"
                      title={
                        rate.limit1Amount != null ? `≥ ${formatHuf(rate.limit1Amount)} Ft` : ''
                      }
                    >
                      {rate.limit1BuyRate != null ? (
                        <span className="text-green-600">
                          {formatDecimal(rate.limit1BuyRate, 2, 2)}
                        </span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}
                  {/* Tier 1 sell */}
                  {showTier1 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-200"
                      title={
                        rate.limit1Amount != null ? `≥ ${formatHuf(rate.limit1Amount)} Ft` : ''
                      }
                    >
                      {rate.limit1SellRate != null ? (
                        <span className="text-red-600">
                          {formatDecimal(rate.limit1SellRate, 2, 2)}
                        </span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}

                  {/* Tier 2 buy */}
                  {showTier2 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-100"
                      title={
                        rate.limit2Amount != null ? `≥ ${formatHuf(rate.limit2Amount)} Ft` : ''
                      }
                    >
                      {rate.limit2BuyRate != null ? (
                        <span className="text-green-600">
                          {formatDecimal(rate.limit2BuyRate, 2, 2)}
                        </span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}
                  {/* Tier 2 sell */}
                  {showTier2 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-200"
                      title={
                        rate.limit2Amount != null ? `≥ ${formatHuf(rate.limit2Amount)} Ft` : ''
                      }
                    >
                      {rate.limit2SellRate != null ? (
                        <span className="text-red-600">
                          {formatDecimal(rate.limit2SellRate, 2, 2)}
                        </span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}

                  {/* Tier 3 buy */}
                  {showTier3 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-100"
                      title={
                        rate.limit3Amount != null ? `≥ ${formatHuf(rate.limit3Amount)} Ft` : ''
                      }
                    >
                      {rate.limit3BuyRate != null ? (
                        <span className="text-green-600">
                          {formatDecimal(rate.limit3BuyRate, 2, 2)}
                        </span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}
                  {/* Tier 3 sell */}
                  {showTier3 && (
                    <td
                      className="px-1 py-px text-right font-mono border-r border-gray-200"
                      title={
                        rate.limit3Amount != null ? `≥ ${formatHuf(rate.limit3Amount)} Ft` : ''
                      }
                    >
                      {rate.limit3SellRate != null ? (
                        <span className="text-red-600">
                          {formatDecimal(rate.limit3SellRate, 2, 2)}
                        </span>
                      ) : (
                        <span className="text-gray-300">&mdash;</span>
                      )}
                    </td>
                  )}

                  {/* MNB official rate */}
                  <td className="px-1 py-px text-right font-mono text-gray-600 text-[10px]">
                    {rate.mnbRate > 0 ? formatDecimal(rate.mnbRate, 2, 2) : '—'}
                  </td>

                  {/* Edit button (only for foertektar/ugyvezeto) */}
                  {canEdit && (
                    <td className="px-0.5 py-px text-center">
                      {editingCode === rate.code ? (
                        <div className="flex gap-0.5 justify-center">
                          <button
                            onClick={() => void saveEdit(rate.code)}
                            className="toolbar-button text-green-600 p-0.5"
                            title="Mentés"
                          >
                            <Save size={10} />
                          </button>
                          <button
                            onClick={() => void requestRateApproval(rate.code)}
                            className="toolbar-button text-blue-700 p-0.5"
                            title="Jóváhagyás kérés"
                            disabled={rateApprovalLoadingCode === rate.code}
                          >
                            {rateApprovalLoadingCode === rate.code ? (
                              <RefreshCw size={10} className="animate-spin" />
                            ) : (
                              <ShieldCheck size={10} />
                            )}
                          </button>
                          <button
                            onClick={cancelEdit}
                            className="toolbar-button text-red-600 p-0.5"
                            title="Mégse"
                          >
                            <X size={10} />
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => startEdit(rate)}
                          className="toolbar-button p-0.5 mx-auto block"
                          title="Szerkesztés"
                        >
                          <Edit size={10} />
                        </button>
                      )}
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>

          {/* Tier threshold legend — compact, at bottom */}
          {tierCount > 0 && (
            <div className="px-2 py-1 bg-gray-50 border-t border-gray-200 text-[9px] text-gray-500 flex flex-wrap gap-x-4 gap-y-0.5">
              <span className="font-semibold uppercase">{t('rates.kedvezmenySavokMinOsszeg')}</span>
              {rates
                .filter(
                  (r) => r.limit1Amount != null || r.limit2Amount != null || r.limit3Amount != null,
                )
                .map((r) => (
                  <span key={r.code} className="font-mono">
                    {r.code}:
                    {r.limit1Amount != null && (
                      <span className="text-emerald-700 ml-0.5">
                        1.≥{formatHuf(r.limit1Amount)}
                      </span>
                    )}
                    {r.limit2Amount != null && (
                      <span className="text-amber-700 ml-0.5">2.≥{formatHuf(r.limit2Amount)}</span>
                    )}
                    {r.limit3Amount != null && (
                      <span className="text-purple-700 ml-0.5">3.≥{formatHuf(r.limit3Amount)}</span>
                    )}
                  </span>
                ))}
            </div>
          )}
        </div>
      )}

      {!loading && rates.length === 0 && territoryGroups.length === 0 && !error && (
        <div className="form-panel text-center text-gray-500 py-6 text-xs">
          {t(
            'rates.nincsenekElerhetoArfolyamokKerjukHozzonLetreArfolyamotAzArfolyamkeszitesOldalon',
          )}
        </div>
      )}
    </div>
  )
}
