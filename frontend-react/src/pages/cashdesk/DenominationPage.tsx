import { useState, useEffect, useCallback, useMemo } from 'react'
import { Coins, Save, RefreshCw, Calculator, AlertCircle } from 'lucide-react'
import {
  denominationBalanceApi,
  DenominationBalanceDTO,
  denominationCalculatorApi,
  denominationOptimizationApi,
  denominationApi,
  currencyApi,
  Denomination,
  Currency,
  type DenominationSummary,
  type DenominationOptimization,
  type DenominationRule,
  type DenominationRuleSelectionPreview,
  type DenominationRuleType,
  type OptimizationStrategy,
} from '../../services/api/index'
import { NumberInput } from '../../components/NumberInput'
import { toast } from '../../components/ui/toaster'
import { formatInteger, formatDecimal } from '../../utils/numberFormat'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import { getErrorMessage } from '../../utils/errorHandling'
import { isAllowedFaceValue } from '../../utils/denominationRules'

interface DenominationQuantityUpdateRequest {
  denominationId: string
  quantity: number
}

const STRATEGY_OPTIONS: OptimizationStrategy[] = [
  'GREEDY',
  'DYNAMIC',
  'MIN_COINS',
  'MIN_BANKNOTES',
  'MIN_TOTAL',
  'CUSTOM',
  'BRANCH_SPECIFIC',
]
const RULE_TYPE_OPTIONS: DenominationRuleType[] = [
  'FIXED',
  'AMOUNT_BASED',
  'CUSTOMER_TYPE',
  'TRANSACTION_TYPE',
  'BRANCH_DEFAULT',
  'TIME_BASED',
  'AVAILABILITY',
  'PRIORITY',
]
const DENOMINATION_CONFIG_ROLES = new Set(['ADMIN', 'MANAGER', 'MAIN_TREASURY'])
const denominationSummaryLabels = {
  saved: 'Mentett:',
  rows: 'Sorok:',
  separator: '/',
  difference: 'Eltérés:',
  masterRows: 'Törzs:',
  lowStock: 'Alacsony készlet:',
  currencySummary: 'Valuta összesítő:',
  codeCheck: 'Kód ellenőrzés:',
  optimalChangeButton: 'Optimális visszajáró',
  optimalChangeTitle: 'Optimális visszajáró:',
  noOptimalChange: 'Nincs kiadható visszajáró ehhez az összeghez.',
}

export default function DenominationPage() {
  const { t } = useTranslation()
  const worker = useAuthStore(
    (s: { worker: { branchId: string; role?: string } | null }) => s.worker,
  )
  const activeRole = useAuthStore((s: { activeRole?: string | null }) => s.activeRole)
  const selectedCashDeskId = worker?.branchId ?? ''
  const canManageDenominationConfig = DENOMINATION_CONFIG_ROLES.has(
    activeRole ?? worker?.role ?? '',
  )
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [selectedCurrencyId, setSelectedCurrencyId] = useState<number | null>(null)
  const [denominations, setDenominations] = useState<Denomination[]>([])
  const [denominationBalances, setDenominationBalances] = useState<DenominationBalanceDTO[]>([])
  const [allDenominationBalances, setAllDenominationBalances] = useState<DenominationBalanceDTO[]>(
    [],
  )
  const [serverCalculatedTotal, setServerCalculatedTotal] = useState<number | null>(null)
  const [allMasterDenominations, setAllMasterDenominations] = useState<Denomination[]>([])
  const [lowStockDenominations, setLowStockDenominations] = useState<Denomination[]>([])
  const [codeDenominations, setCodeDenominations] = useState<Denomination[]>([])
  const [denominationSummary, setDenominationSummary] = useState<DenominationSummary | null>(null)
  const [editingQuantities, setEditingQuantities] = useState<Record<number, number>>({})
  const [loading, setLoading] = useState(false)
  // FK-077 (FR-3): látható, magyar nyelvű betöltési hibaüzenet a csendes kiürülés helyett.
  const [loadErrorMessage, setLoadErrorMessage] = useState<string | null>(null)
  const [suggestionAmount, setSuggestionAmount] = useState('')
  const [suggestionLoading, setSuggestionLoading] = useState(false)
  const [suggestionMessage, setSuggestionMessage] = useState<string | null>(null)
  const [suggestionUsesStock, setSuggestionUsesStock] = useState(false)
  const [validationExpectedBalance, setValidationExpectedBalance] = useState('')
  const [validationLoading, setValidationLoading] = useState(false)
  const [validationMessage, setValidationMessage] = useState<string | null>(null)
  const [optimalChange, setOptimalChange] = useState<Record<number, number> | null>(null)
  const [optimalChangeLoading, setOptimalChangeLoading] = useState(false)
  const [optimalChangeMessage, setOptimalChangeMessage] = useState<string | null>(null)
  const [optimizations, setOptimizations] = useState<DenominationOptimization[]>([])
  const [rules, setRules] = useState<DenominationRule[]>([])
  const [optimizationError, setOptimizationError] = useState<string | null>(null)
  const [previewAmount, setPreviewAmount] = useState('')
  const [previewLoading, setPreviewLoading] = useState(false)
  const [previewResult, setPreviewResult] = useState<DenominationRuleSelectionPreview | null>(null)
  const [previewMessage, setPreviewMessage] = useState<string | null>(null)
  const [configSaving, setConfigSaving] = useState(false)
  const [optimizationForm, setOptimizationForm] = useState({
    id: '',
    name: '',
    description: '',
    strategy: 'GREEDY' as OptimizationStrategy,
    isDefault: false,
    minCoins: false,
    minBanknotes: false,
    minTotalCount: false,
  })
  const [ruleForm, setRuleForm] = useState({
    ruleName: '',
    ruleType: 'AMOUNT_BASED' as DenominationRuleType,
    minAmount: '',
    maxAmount: '',
    priority: '100',
    optimizationId: '',
    branchScoped: true,
  })
  // Copilot #1109: az összesítő DERIVÁLT érték a szerkesztett darabszámokból — state-ként
  // tartva versenyhelyzetes/elcsúszó újraszámításokra volt érzékeny.
  // FK-079 (FR-3): a tört névértékű sorok kimaradnak az összegzésből, hogy az összeg
  // konzisztens legyen azzal, amit a felhasználó a táblázatban ténylegesen lát
  // (a render is isAllowedFaceValue-vel szűr, FK-072 v2 óta).
  const calculatedTotal = useMemo(
    () =>
      denominations
        .filter((d) => d.currencyId === selectedCurrencyId && isAllowedFaceValue(d.faceValue))
        .reduce((sum, d) => sum + d.faceValue * (editingQuantities[d.id] ?? 0), 0),
    [denominations, selectedCurrencyId, editingQuantities],
  )

  // Batch2-A (Fabulya-teszt 2026-06-12): a címletek ÉS a mentett egyenlegek betöltése
  // EGY szekvenciális folyamatban. Korábban két párhuzamos hívás versenyzett ugyanazon
  // a state-en (az egyik mindent 0-ra resetelt, a másik a mentett értékeket írta be,
  // teljes-csere set-tel) — ha a 0-reset futott be utoljára, a mentett címletezés
  // 0-ként jelent meg, „nem rögzíthető" tünetet okozva.
  const loadAll = useCallback(async () => {
    if (!selectedCashDeskId || !selectedCurrencyId) return
    setLoading(true)
    setLoadErrorMessage(null)
    const selectedCurrencyCode = currencies.find((c) => c.id === selectedCurrencyId)?.code
    // FK-077 (FR-3): Promise.all helyett allSettled — korábban az ELSŐ elutasított hívás
    // (pl. a requireOwnCashDesk 404-e) az egész oldalt csendben kiürítette, hibaüzenet
    // nélkül. Most a sikeres részeredmények megjelennek, a hibáról a felhasználó
    // magyar nyelvű, látható üzenetet kap.
    const results = await Promise.allSettled([
      denominationApi.getByCurrencyId(selectedCurrencyId),
      denominationBalanceApi.getCashDeskDenominations(selectedCashDeskId),
      denominationBalanceApi.getCashDeskDenominationsByCurrency(
        selectedCashDeskId,
        String(selectedCurrencyId),
      ),
      denominationBalanceApi.calculateTotalFromDenominations(
        selectedCashDeskId,
        String(selectedCurrencyId),
      ),
      denominationApi.list(),
      denominationApi.getLowStockAlerts(),
      denominationApi.getSummary(selectedCurrencyId),
      selectedCurrencyCode
        ? denominationApi.getByCurrencyCode(selectedCurrencyCode)
        : Promise.resolve([] as Denomination[]),
    ])

    const valueOf = <T,>(index: number, fallback: T): T => {
      const r = results[index]
      return r && r.status === 'fulfilled' ? (r.value as T) : fallback
    }
    const failures = results.filter((r): r is PromiseRejectedResult => r.status === 'rejected')

    const denoms = valueOf<Denomination[]>(0, [])
    const allBalances = valueOf<DenominationBalanceDTO[]>(1, [])
    const balances = valueOf<DenominationBalanceDTO[]>(2, [])

    setDenominations(denoms)
    setAllDenominationBalances(allBalances)
    setDenominationBalances(balances)
    setServerCalculatedTotal(valueOf<number | null>(3, null))
    setAllMasterDenominations(valueOf<Denomination[]>(4, []))
    setLowStockDenominations(valueOf<Denomination[]>(5, []))
    setDenominationSummary(valueOf<DenominationSummary | null>(6, null))
    setCodeDenominations(valueOf<Denomination[]>(7, []))

    // Egyetlen, determinisztikus state-írás: minden címlet 0, felülírva a mentettekkel.
    // (Az összesítő ebből DERIVÁLT useMemo — külön nem kell beállítani.)
    const quantities: Record<number, number> = {}
    denoms.forEach((d: Denomination) => {
      quantities[d.id] = 0
    })
    balances.forEach((balance) => {
      quantities[Number(balance.denominationId)] = balance.quantity
    })
    setEditingQuantities(quantities)

    if (failures.length > 0) {
      failures.forEach((f) =>
        logger.error('DenominationPage', 'Címletezés részleges betöltési hiba:', f.reason),
      )
      setLoadErrorMessage(
        `A címletezés adatainak egy része nem tölthető be (${failures.length} hívás sikertelen). ` +
          `Részlet: ${getErrorMessage(failures[0]?.reason)}`,
      )
    }
    setLoading(false)
  }, [currencies, selectedCashDeskId, selectedCurrencyId])

  useEffect(() => {
    void loadCurrencies()
    void loadOptimizationConfig()
  }, [])

  useEffect(() => {
    if (selectedCurrencyId && selectedCashDeskId) {
      void loadAll()
    }
  }, [selectedCurrencyId, selectedCashDeskId, loadAll])

  const loadCurrencies = async () => {
    try {
      const data = await currencyApi.getActive()
      setCurrencies(data)
      if (data.length > 0) {
        setSelectedCurrencyId(data[0]?.id ?? null)
      }
    } catch (error) {
      logger.error('DenominationPage', 'Valuták betöltése sikertelen:', error)
    }
  }

  const handleQuantityChange = (denominationId: number, quantityStr: string) => {
    // Darabszám = egész szám (a backend DTO Integer) — tört darab nem értelmezhető.
    const quantity = Math.max(0, parseInt(quantityStr.replace(/\s/g, ''), 10) || 0)
    // Copilot #1109: funkcionális update — gyors egymás utáni input-eseményeknél a
    // spread-es minta a stale snapshot miatt frissítést veszíthetne. Az összesítő
    // derivált érték (useMemo), külön újraszámítás nem kell.
    setEditingQuantities((prev) => ({ ...prev, [denominationId]: quantity }))
  }

  const loadOptimizationConfig = async () => {
    try {
      setOptimizationError(null)
      const [optimizationList, ruleList] = await Promise.all([
        denominationOptimizationApi.listOptimizations(),
        denominationOptimizationApi.listRules(),
      ])
      setOptimizations(optimizationList)
      setRules(ruleList)
    } catch (error) {
      logger.warn('DenominationPage', 'Címletezési szabálymotor nem elérhető:', error)
      setOptimizations([])
      setRules([])
      setOptimizationError(getErrorMessage(error))
    }
  }

  const handleApplySuggestion = async () => {
    const selectedCurrencyCode = selectedCurrency?.code
    const amount = Number(suggestionAmount.replace(/\s/g, '').replace(',', '.'))
    if (!selectedCurrencyCode || !Number.isFinite(amount) || amount <= 0) {
      setSuggestionMessage('Adj meg pozitív összeget a címletjavaslathoz.')
      return
    }

    setSuggestionLoading(true)
    setSuggestionMessage(null)
    try {
      // FK-079 (FR-1): a javaslat feldolgozásából a tört névértékű sorok kimaradnak —
      // tört címlethez semmilyen úton nem kerülhet nem-nulla mennyiség a state-be.
      const currentDenominations = denominations.filter(
        (d) => d.currencyId === selectedCurrencyId && d.active && isAllowedFaceValue(d.faceValue),
      )
      const suggestion = suggestionUsesStock
        ? await denominationCalculatorApi.suggestBalanced({
            currencyCode: selectedCurrencyCode,
            amount,
            availableStock: Object.fromEntries(
              currentDenominations.map((d) => [String(d.faceValue), editingQuantities[d.id] ?? 0]),
            ),
          })
        : await denominationCalculatorApi.suggest(selectedCurrencyCode, amount)
      const nextQuantities: Record<number, number> = {}
      currentDenominations.forEach((d) => {
        nextQuantities[d.id] = 0
      })

      const unmatched: string[] = []
      Object.entries(suggestion.denominations).forEach(([faceValue, quantity]) => {
        const matching = currentDenominations.find((d) => Number(d.faceValue) === Number(faceValue))
        if (matching) {
          nextQuantities[matching.id] = Number(quantity) || 0
        } else {
          unmatched.push(faceValue)
        }
      })

      setEditingQuantities((prev) => ({ ...prev, ...nextQuantities }))
      const details: string[] = []
      if (Number(suggestion.remainder) > 0) {
        details.push(
          `maradék: ${formatDecimal(Number(suggestion.remainder), 2, 2)} ${selectedCurrencyCode}`,
        )
      }
      if (unmatched.length > 0) {
        details.push(`nem ismert címlet: ${unmatched.join(', ')}`)
      }
      const prefix = suggestionUsesStock
        ? 'Készletfigyelő címletjavaslat alkalmazva'
        : 'Címletjavaslat alkalmazva'
      setSuggestionMessage(details.length > 0 ? `${prefix}, ${details.join('; ')}.` : `${prefix}.`)
    } catch (error) {
      logger.error('DenominationPage', 'Címletjavaslat sikertelen:', error)
      setSuggestionMessage(getErrorMessage(error))
    } finally {
      setSuggestionLoading(false)
    }
  }

  const handleOptimalChange = async () => {
    const amount = Number(suggestionAmount.replace(/\s/g, '').replace(',', '.'))
    if (!selectedCurrencyId || !Number.isFinite(amount) || amount <= 0) {
      setOptimalChange(null)
      setOptimalChangeMessage('Adj meg pozitív összeget az optimális visszajáróhoz.')
      return
    }

    setOptimalChangeLoading(true)
    setOptimalChangeMessage(null)
    try {
      const result = await denominationApi.getOptimalChange(selectedCurrencyId, amount)
      setOptimalChange(result)
      setOptimalChangeMessage(
        Object.keys(result).length === 0 ? denominationSummaryLabels.noOptimalChange : null,
      )
    } catch (error) {
      logger.error('DenominationPage', 'Optimális visszajáró számítás sikertelen:', error)
      setOptimalChange(null)
      setOptimalChangeMessage(getErrorMessage(error))
    } finally {
      setOptimalChangeLoading(false)
    }
  }

  const handleValidateDenominations = async () => {
    const expectedBalance = Number(validationExpectedBalance.replace(/\s/g, '').replace(',', '.'))
    if (!selectedCurrencyId || !Number.isFinite(expectedBalance) || expectedBalance < 0) {
      setValidationMessage('Adj meg nem negatív elvárt egyenleget a címletvalidáláshoz.')
      return
    }

    setValidationLoading(true)
    setValidationMessage(null)
    try {
      const result = await denominationApi.validate(selectedCurrencyId, expectedBalance)
      const difference = formatDecimal(Number(result.difference), 2, 2)
      setValidationMessage(
        result.isValid
          ? `Címletezés rendben: ${formatDecimal(Number(result.actualBalance), 2, 2)} ${result.currencyCode}.`
          : `Eltérés: ${difference} ${result.currencyCode}. Tényleges: ${formatDecimal(Number(result.actualBalance), 2, 2)}.`,
      )
    } catch (error) {
      logger.error('DenominationPage', 'Címletvalidálás sikertelen:', error)
      setValidationMessage(getErrorMessage(error))
    } finally {
      setValidationLoading(false)
    }
  }

  const handlePreviewSelection = async () => {
    const amount = Number(previewAmount.replace(/\s/g, '').replace(',', '.'))
    if (!selectedCashDeskId || !selectedCurrencyId || !Number.isFinite(amount) || amount <= 0) {
      setPreviewResult(null)
      setPreviewMessage('Adj meg pozitív HUF összeget a szabályteszthez.')
      return
    }

    setPreviewLoading(true)
    setPreviewMessage(null)
    try {
      const result = await denominationOptimizationApi.previewSelection({
        branchId: selectedCashDeskId,
        currencyId: selectedCurrencyId,
        hufAmount: amount,
      })
      setPreviewResult(result)
    } catch (error) {
      logger.error('DenominationPage', 'Címletezési szabályteszt sikertelen:', error)
      setPreviewResult(null)
      setPreviewMessage(getErrorMessage(error))
    } finally {
      setPreviewLoading(false)
    }
  }

  const handleOptimizationSelect = (id: string) => {
    const selected = optimizations.find((opt) => opt.id === id)
    if (!selected) {
      setOptimizationForm({
        id: '',
        name: '',
        description: '',
        strategy: 'GREEDY',
        isDefault: false,
        minCoins: false,
        minBanknotes: false,
        minTotalCount: false,
      })
      return
    }
    setOptimizationForm({
      id: selected.id,
      name: selected.name,
      description: selected.description ?? '',
      strategy: selected.strategy,
      isDefault: Boolean(selected.isDefault),
      minCoins: Boolean(selected.minCoins),
      minBanknotes: Boolean(selected.minBanknotes),
      minTotalCount: Boolean(selected.minTotalCount),
    })
  }

  const handleSaveOptimizationConfig = async () => {
    if (!canManageDenominationConfig) {
      toast.warning(
        'Nincs jogosultság',
        'A címletezési stratégiák módosításához vezetői jogosultság szükséges.',
      )
      return
    }
    const name = optimizationForm.name.trim()
    if (!name) {
      toast.warning('Hiányzó stratégianév', 'Adj meg nevet a címletezési stratégiához.')
      return
    }
    const request = {
      name,
      description: optimizationForm.description.trim() || null,
      strategy: optimizationForm.strategy,
      priorityOrderJson: null,
      minCoins: optimizationForm.minCoins,
      minBanknotes: optimizationForm.minBanknotes,
      minTotalCount: optimizationForm.minTotalCount,
      isDefault: optimizationForm.isDefault,
    }

    setConfigSaving(true)
    try {
      if (optimizationForm.id) {
        await denominationOptimizationApi.updateOptimization(optimizationForm.id, request)
      } else {
        await denominationOptimizationApi.createOptimization(request)
      }
      toast.success('Címletezési stratégia mentve')
      handleOptimizationSelect('')
      await loadOptimizationConfig()
    } catch (error) {
      logger.error('DenominationPage', 'Címletezési stratégia mentése sikertelen:', error)
      toast.error('Címletezési stratégia mentési hiba', getErrorMessage(error))
    } finally {
      setConfigSaving(false)
    }
  }

  const handleCreateRuleConfig = async () => {
    if (!canManageDenominationConfig) {
      toast.warning(
        'Nincs jogosultság',
        'A címletezési szabályok módosításához vezetői jogosultság szükséges.',
      )
      return
    }
    if (!selectedCurrencyId || !ruleForm.optimizationId || !ruleForm.ruleName.trim()) {
      toast.warning('Hiányzó szabályadat', 'Valuta, stratégia és szabálynév kötelező.')
      return
    }
    const minAmount = ruleForm.minAmount.trim()
      ? Number(ruleForm.minAmount.replace(/\s/g, '').replace(',', '.'))
      : null
    const maxAmount = ruleForm.maxAmount.trim()
      ? Number(ruleForm.maxAmount.replace(/\s/g, '').replace(',', '.'))
      : null
    const priority = ruleForm.priority.trim() ? Number.parseInt(ruleForm.priority, 10) : 100
    if (
      (minAmount !== null && !Number.isFinite(minAmount)) ||
      (maxAmount !== null && !Number.isFinite(maxAmount))
    ) {
      toast.warning('Hibás összeghatár', 'Az összeghatárok csak számok lehetnek.')
      return
    }

    setConfigSaving(true)
    try {
      await denominationOptimizationApi.createRule({
        ruleName: ruleForm.ruleName.trim(),
        currencyId: selectedCurrencyId,
        ruleType: ruleForm.ruleType,
        minAmount,
        maxAmount,
        branchId: ruleForm.branchScoped ? selectedCashDeskId : null,
        optimizationId: ruleForm.optimizationId,
        ruleConfigJson: null,
        priority: Number.isFinite(priority) ? priority : 100,
      })
      toast.success('Címletezési szabály létrehozva')
      setRuleForm((prev) => ({ ...prev, ruleName: '', minAmount: '', maxAmount: '' }))
      await loadOptimizationConfig()
    } catch (error) {
      logger.error('DenominationPage', 'Címletezési szabály létrehozása sikertelen:', error)
      toast.error('Címletezési szabály mentési hiba', getErrorMessage(error))
    } finally {
      setConfigSaving(false)
    }
  }

  const handleDeleteRuleConfig = async (ruleId: string) => {
    if (!canManageDenominationConfig) {
      toast.warning(
        'Nincs jogosultság',
        'A címletezési szabály törléséhez vezetői jogosultság szükséges.',
      )
      return
    }
    setConfigSaving(true)
    try {
      await denominationOptimizationApi.deleteRule(ruleId)
      toast.success('Címletezési szabály inaktiválva')
      await loadOptimizationConfig()
    } catch (error) {
      logger.error('DenominationPage', 'Címletezési szabály törlése sikertelen:', error)
      toast.error('Címletezési szabály törlési hiba', getErrorMessage(error))
    } finally {
      setConfigSaving(false)
    }
  }

  const handleSave = async () => {
    if (!selectedCashDeskId) {
      toast.warning('Hiányzó adat', 'Válassz pénztárat!')
      return
    }

    try {
      // Batch2-A: a 0 darabszámot IS elküldjük — korábban a qty>0 szűrő miatt egy
      // címlet 0-ra állítása (korábbi érték törlése) sosem perzisztálódott.
      // Csak az aktuálisan kiválasztott valuta címleteit küldjük.
      // FK-079 (FR-2): a beküldött lista tört névértékű sort NEM tartalmazhat — akkor sem,
      // ha bármilyen úton (korábbi mentés, javaslat) nem-nulla mennyiség került a state-be.
      const currentIds = new Set(
        denominations
          .filter((d) => d.currencyId === selectedCurrencyId && isAllowedFaceValue(d.faceValue))
          .map((d) => d.id),
      )
      const updates: DenominationQuantityUpdateRequest[] = Object.entries(editingQuantities)
        .filter(([id]) => currentIds.has(Number(id)))
        .map(([denominationId, quantity]) => ({
          denominationId,
          quantity,
        }))

      await denominationBalanceApi.setDenominationQuantities(selectedCashDeskId, updates)
      toast.success('Címletezés sikeresen mentve!')
      void loadAll()
    } catch (error) {
      logger.error('DenominationPage', 'Mentés sikertelen:', error)
      toast.error('Hiba történt a mentés során')
    }
  }

  const selectedCurrency = currencies.find((c) => c.id === selectedCurrencyId)
  const selectedCurrencySavedBalanceCount = denominationBalances.length
  const serverTotalDiff =
    serverCalculatedTotal === null ? null : calculatedTotal - serverCalculatedTotal
  const defaultOptimization = optimizations.find((opt) => opt.isDefault)
  const activeRuleCount = rules.filter((rule) => rule.isActive !== false).length
  const visibleRules = rules
    .filter((rule) => rule.isActive !== false)
    .slice()
    .sort((a, b) => (a.priority ?? 100) - (b.priority ?? 100))
    .slice(0, 3)

  return (
    <div className="space-y-2">
      {/* FK-077 FR-3: látható betöltési hibaüzenet — csendes üres képernyő helyett. */}
      {loadErrorMessage && (
        <div
          role="alert"
          data-testid="denomination-load-error"
          className="flex items-start gap-2 rounded-lg border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-800"
        >
          <AlertCircle size={16} className="mt-0.5 shrink-0" />
          <span>{loadErrorMessage}</span>
        </div>
      )}
      {/* Header + Currency Selector — egy sorban */}
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div className="flex items-center gap-3">
          <h1 className="text-lg font-bold text-gray-800 flex items-center gap-2">
            <Coins size={20} />
            {t('cashdesk.penztarCimletezes')}
          </h1>
          <select
            id="currency-select"
            title="Válassz valutát"
            aria-label={t('cashdesk.valutaKivalasztasa')}
            value={selectedCurrencyId ?? ''}
            onChange={(e) => setSelectedCurrencyId(e.target.value ? Number(e.target.value) : null)}
            className="form-input h-8 text-sm w-48"
          >
            <option value="">{t('cashdesk.valasszValutat')}</option>
            {currencies.map((curr) => (
              <option key={curr.id} value={curr.id}>
                {curr.code} - {curr.name}
              </option>
            ))}
          </select>
          {selectedCurrency && (
            <div className="flex flex-wrap items-center gap-2">
              <div className="flex items-center gap-2 px-3 py-1 bg-blue-50 border border-blue-200 rounded-lg">
                <Calculator className="text-blue-600" size={14} />
                <span className="text-sm text-gray-600">{t('cashdesk.osszesitettEgyenleg')}</span>
                <span className="font-bold text-base font-mono text-green-600">
                  {formatDecimal(calculatedTotal, 2, 2)} {selectedCurrency.code}
                </span>
              </div>
              <div className="px-3 py-1 bg-gray-50 border border-gray-200 rounded-lg text-xs text-gray-600">
                {denominationSummaryLabels.saved}{' '}
                <span className="font-mono font-semibold text-gray-900">
                  {serverCalculatedTotal === null
                    ? '-'
                    : formatDecimal(serverCalculatedTotal, 2, 2)}
                </span>{' '}
                {selectedCurrency.code}
              </div>
              <div className="px-3 py-1 bg-gray-50 border border-gray-200 rounded-lg text-xs text-gray-600">
                {denominationSummaryLabels.rows}{' '}
                <span className="font-semibold text-gray-900">
                  {selectedCurrencySavedBalanceCount}
                </span>
                <span className="text-gray-400"> {denominationSummaryLabels.separator} </span>
                <span className="font-semibold text-gray-900">
                  {allDenominationBalances.length}
                </span>
              </div>
              {serverTotalDiff !== null && serverTotalDiff !== 0 && (
                <div className="px-3 py-1 bg-amber-50 border border-amber-200 rounded-lg text-xs text-amber-800">
                  {denominationSummaryLabels.difference}{' '}
                  <span className="font-mono font-semibold">
                    {formatDecimal(serverTotalDiff, 2, 2)}
                  </span>{' '}
                  {selectedCurrency.code}
                </div>
              )}
              <div className="px-3 py-1 bg-gray-50 border border-gray-200 rounded-lg text-xs text-gray-600">
                {denominationSummaryLabels.masterRows}{' '}
                <span className="font-semibold text-gray-900">{allMasterDenominations.length}</span>
              </div>
              <div className="px-3 py-1 bg-orange-50 border border-orange-200 rounded-lg text-xs text-orange-800">
                {denominationSummaryLabels.lowStock}{' '}
                <span className="font-semibold">{lowStockDenominations.length}</span>
              </div>
              {denominationSummary && (
                <div className="px-3 py-1 bg-gray-50 border border-gray-200 rounded-lg text-xs text-gray-600">
                  {denominationSummaryLabels.currencySummary}{' '}
                  <span className="font-mono font-semibold text-gray-900">
                    {formatDecimal(denominationSummary.totalValue, 2, 2)}
                  </span>{' '}
                  {denominationSummary.currencyCode}
                  <span className="text-gray-400"> · </span>
                  <span className="font-semibold text-gray-900">
                    {denominationSummary.banknoteCount}/{denominationSummary.coinCount}
                  </span>
                </div>
              )}
              <div className="px-3 py-1 bg-gray-50 border border-gray-200 rounded-lg text-xs text-gray-600">
                {denominationSummaryLabels.codeCheck}{' '}
                <span className="font-semibold text-gray-900">{codeDenominations.length}</span>
              </div>
            </div>
          )}
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={loadAll}
            className="form-button flex items-center gap-1 h-8 text-sm"
            disabled={loading}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            {t('common.refresh')}
          </button>
          <button
            type="button"
            onClick={handleSave}
            className="form-button-primary flex items-center gap-1 h-8 text-sm"
            disabled={!selectedCashDeskId}
          >
            <Save size={14} />
            {t('common.save')}
          </button>
        </div>
      </div>

      {selectedCurrency && (
        <div className="form-panel flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
          <div className="min-w-0">
            <label className="form-label">Szerveroldali címletjavaslat</label>
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
              <NumberInput
                value={suggestionAmount}
                onChange={setSuggestionAmount}
                className="form-input w-full sm:w-48 font-mono"
                placeholder={`Összeg ${selectedCurrency.code}`}
                allowDecimals
                allowNegative={false}
                min={0}
              />
              <button
                type="button"
                className="form-button flex items-center gap-1 h-9 text-sm"
                onClick={() => void handleApplySuggestion()}
                disabled={suggestionLoading || !suggestionAmount.trim()}
              >
                <Calculator size={14} className={suggestionLoading ? 'animate-pulse' : ''} />
                Javaslat alkalmazása
              </button>
              <button
                type="button"
                className="form-button flex items-center gap-1 h-9 text-sm"
                onClick={() => void handleOptimalChange()}
                disabled={optimalChangeLoading || !suggestionAmount.trim()}
              >
                <Calculator size={14} className={optimalChangeLoading ? 'animate-pulse' : ''} />
                {denominationSummaryLabels.optimalChangeButton}
              </button>
            </div>
            <label className="mt-2 flex items-center gap-2 text-xs text-gray-600">
              <input
                type="checkbox"
                checked={suggestionUsesStock}
                onChange={(e) => setSuggestionUsesStock(e.target.checked)}
              />
              Készletfigyelő algoritmus az aktuális darabszámokkal
            </label>
            {suggestionMessage && <p className="mt-1 text-xs text-gray-600">{suggestionMessage}</p>}
            {optimalChange && Object.keys(optimalChange).length > 0 && (
              <div className="mt-2 rounded-md border border-blue-200 bg-blue-50 px-3 py-2 text-xs text-blue-900">
                <span className="font-semibold">
                  {denominationSummaryLabels.optimalChangeTitle}
                </span>{' '}
                {Object.entries(optimalChange)
                  .sort(([a], [b]) => Number(b) - Number(a))
                  .map(
                    ([faceValue, quantity]) =>
                      `${formatDecimal(Number(faceValue), 2, 2)} x ${quantity}`,
                  )
                  .join(', ')}
              </div>
            )}
            {optimalChangeMessage && (
              <p className="mt-1 text-xs text-amber-700">{optimalChangeMessage}</p>
            )}
          </div>
          <p className="text-xs text-gray-500 md:max-w-xs">
            A javaslat a backend címletkalkulátorából érkezik, majd a betöltött címletsorok
            darabszámait tölti.
          </p>
        </div>
      )}

      {selectedCurrency && (
        <div className="form-panel flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div className="min-w-0">
            <label className="form-label">Címletezés validálás</label>
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
              <NumberInput
                value={validationExpectedBalance}
                onChange={setValidationExpectedBalance}
                className="form-input w-full sm:w-48 font-mono"
                placeholder={`Elvárt egyenleg ${selectedCurrency.code}`}
                allowDecimals
                allowNegative={false}
                min={0}
              />
              <button
                type="button"
                className="form-button flex items-center gap-1 h-9 text-sm"
                onClick={() => void handleValidateDenominations()}
                disabled={validationLoading || !validationExpectedBalance.trim()}
              >
                <Calculator size={14} className={validationLoading ? 'animate-pulse' : ''} />
                Validálás
              </button>
            </div>
            {validationMessage && <p className="mt-1 text-xs text-gray-600">{validationMessage}</p>}
          </div>
          <p className="text-xs text-gray-500 md:max-w-xs">
            Az ellenőrzés a backend címletvalidálását hívja az aktuális valuta és a megadott elvárt
            egyenleg alapján.
          </p>
        </div>
      )}

      {selectedCurrency && (
        <div className="form-panel">
          <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
            <div className="min-w-0 flex-1">
              <h2 className="text-sm font-bold text-gray-800">Címletezési szabálymotor</h2>
              {optimizationError ? (
                <p className="mt-1 text-xs text-amber-700">
                  A szabálymotor admin API nem elérhető ehhez a felhasználóhoz vagy a backend nem
                  válaszolt.
                </p>
              ) : (
                <>
                  <div className="mt-2 grid gap-2 text-sm sm:grid-cols-3">
                    <StatusBox label="Aktív stratégia" value={optimizations.length} />
                    <StatusBox label="Alapértelmezett" value={defaultOptimization?.name ?? '-'} />
                    <StatusBox label="Aktív szabály" value={activeRuleCount} />
                  </div>
                  <div className="mt-3 space-y-2">
                    {visibleRules.length === 0 ? (
                      <p className="text-xs text-gray-500">
                        Nincs aktív címletezési szabály; a backend fallback stratégiát használ.
                      </p>
                    ) : (
                      visibleRules.map((rule) => (
                        <div
                          key={rule.id}
                          className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-xs"
                        >
                          <div className="flex items-start justify-between gap-2">
                            <div className="font-semibold text-gray-900">{rule.ruleName}</div>
                            {canManageDenominationConfig && (
                              <button
                                type="button"
                                className="text-xs font-semibold text-red-700"
                                disabled={configSaving}
                                onClick={() => void handleDeleteRuleConfig(rule.id)}
                              >
                                Inaktiválás
                              </button>
                            )}
                          </div>
                          <div className="mt-0.5 text-gray-600">
                            {rule.ruleType} · prioritás {rule.priority} ·{' '}
                            {rule.optimization?.name ?? 'nincs stratégianév'}
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                  {canManageDenominationConfig && (
                    <div className="mt-4 grid gap-3 border-t border-gray-200 pt-3 xl:grid-cols-2">
                      <div className="rounded-md border border-gray-200 bg-white p-3">
                        <h3 className="text-xs font-bold text-gray-800">Stratégia szerkesztése</h3>
                        <select
                          className="form-input mt-2 w-full"
                          value={optimizationForm.id}
                          onChange={(event) => handleOptimizationSelect(event.target.value)}
                          aria-label="Címletezési stratégia kiválasztása"
                        >
                          <option value="">Új stratégia</option>
                          {optimizations.map((opt) => (
                            <option key={opt.id} value={opt.id}>
                              {opt.name}
                            </option>
                          ))}
                        </select>
                        <input
                          className="form-input mt-2 w-full"
                          value={optimizationForm.name}
                          onChange={(event) =>
                            setOptimizationForm((prev) => ({ ...prev, name: event.target.value }))
                          }
                          placeholder="Stratégianév"
                        />
                        <select
                          className="form-input mt-2 w-full"
                          value={optimizationForm.strategy}
                          onChange={(event) =>
                            setOptimizationForm((prev) => ({
                              ...prev,
                              strategy: event.target.value as OptimizationStrategy,
                            }))
                          }
                          aria-label="Optimalizációs algoritmus"
                        >
                          {STRATEGY_OPTIONS.map((strategy) => (
                            <option key={strategy} value={strategy}>
                              {strategy}
                            </option>
                          ))}
                        </select>
                        <div className="mt-2 grid gap-2 text-xs sm:grid-cols-2">
                          <label className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={optimizationForm.isDefault}
                              onChange={(event) =>
                                setOptimizationForm((prev) => ({
                                  ...prev,
                                  isDefault: event.target.checked,
                                }))
                              }
                            />
                            Alapértelmezett
                          </label>
                          <label className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={optimizationForm.minTotalCount}
                              onChange={(event) =>
                                setOptimizationForm((prev) => ({
                                  ...prev,
                                  minTotalCount: event.target.checked,
                                }))
                              }
                            />
                            Min. darabszám
                          </label>
                          <label className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={optimizationForm.minBanknotes}
                              onChange={(event) =>
                                setOptimizationForm((prev) => ({
                                  ...prev,
                                  minBanknotes: event.target.checked,
                                }))
                              }
                            />
                            Min. bankjegy
                          </label>
                          <label className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={optimizationForm.minCoins}
                              onChange={(event) =>
                                setOptimizationForm((prev) => ({
                                  ...prev,
                                  minCoins: event.target.checked,
                                }))
                              }
                            />
                            Min. érme
                          </label>
                        </div>
                        <button
                          type="button"
                          className="form-button-primary mt-3 h-9 w-full text-sm"
                          disabled={configSaving}
                          onClick={() => void handleSaveOptimizationConfig()}
                        >
                          Stratégia mentése
                        </button>
                      </div>

                      <div className="rounded-md border border-gray-200 bg-white p-3">
                        <h3 className="text-xs font-bold text-gray-800">Szabály létrehozása</h3>
                        <input
                          className="form-input mt-2 w-full"
                          value={ruleForm.ruleName}
                          onChange={(event) =>
                            setRuleForm((prev) => ({ ...prev, ruleName: event.target.value }))
                          }
                          placeholder="Szabálynév"
                        />
                        <select
                          className="form-input mt-2 w-full"
                          value={ruleForm.optimizationId}
                          onChange={(event) =>
                            setRuleForm((prev) => ({ ...prev, optimizationId: event.target.value }))
                          }
                          aria-label="Szabály stratégiája"
                        >
                          <option value="">Válassz stratégiát</option>
                          {optimizations.map((opt) => (
                            <option key={opt.id} value={opt.id}>
                              {opt.name}
                            </option>
                          ))}
                        </select>
                        <div className="mt-2 grid gap-2 sm:grid-cols-2">
                          <select
                            className="form-input w-full"
                            value={ruleForm.ruleType}
                            onChange={(event) =>
                              setRuleForm((prev) => ({
                                ...prev,
                                ruleType: event.target.value as DenominationRuleType,
                              }))
                            }
                            aria-label="Szabály típusa"
                          >
                            {RULE_TYPE_OPTIONS.map((ruleType) => (
                              <option key={ruleType} value={ruleType}>
                                {ruleType}
                              </option>
                            ))}
                          </select>
                          <input
                            className="form-input w-full"
                            value={ruleForm.priority}
                            onChange={(event) =>
                              setRuleForm((prev) => ({ ...prev, priority: event.target.value }))
                            }
                            placeholder="Prioritás"
                          />
                          <input
                            className="form-input w-full"
                            value={ruleForm.minAmount}
                            onChange={(event) =>
                              setRuleForm((prev) => ({ ...prev, minAmount: event.target.value }))
                            }
                            placeholder="Min. HUF"
                          />
                          <input
                            className="form-input w-full"
                            value={ruleForm.maxAmount}
                            onChange={(event) =>
                              setRuleForm((prev) => ({ ...prev, maxAmount: event.target.value }))
                            }
                            placeholder="Max. HUF"
                          />
                        </div>
                        <label className="mt-2 flex items-center gap-2 text-xs text-gray-600">
                          <input
                            type="checkbox"
                            checked={ruleForm.branchScoped}
                            onChange={(event) =>
                              setRuleForm((prev) => ({
                                ...prev,
                                branchScoped: event.target.checked,
                              }))
                            }
                          />
                          Csak a bejelentkezett fiókra
                        </label>
                        <button
                          type="button"
                          className="form-button-primary mt-3 h-9 w-full text-sm"
                          disabled={configSaving}
                          onClick={() => void handleCreateRuleConfig()}
                        >
                          Szabály létrehozása
                        </button>
                      </div>
                    </div>
                  )}
                </>
              )}
            </div>

            <div className="w-full lg:w-80">
              <label className="form-label">Szabályteszt HUF összeg</label>
              <div className="flex gap-2">
                <NumberInput
                  value={previewAmount}
                  onChange={setPreviewAmount}
                  className="form-input min-w-0 flex-1 font-mono"
                  placeholder="HUF összeg"
                  allowDecimals
                  allowNegative={false}
                  min={0}
                />
                <button
                  type="button"
                  className="form-button h-9 whitespace-nowrap text-sm"
                  onClick={() => void handlePreviewSelection()}
                  disabled={previewLoading || !previewAmount.trim() || Boolean(optimizationError)}
                >
                  Teszt
                </button>
              </div>
              {previewResult && (
                <div className="mt-2 rounded-md border border-blue-200 bg-blue-50 px-3 py-2 text-xs text-blue-900">
                  <div>
                    <span className="font-semibold">Forrás:</span> {previewResult.source}
                  </div>
                  <div>
                    <span className="font-semibold">Stratégia:</span> {previewResult.strategy}
                  </div>
                  <div>
                    <span className="font-semibold">Optimalizáció:</span>{' '}
                    {previewResult.optimizationName ?? '-'}
                  </div>
                  <div>
                    <span className="font-semibold">Szabály:</span> {previewResult.ruleName ?? '-'}
                  </div>
                </div>
              )}
              {previewMessage && <p className="mt-2 text-xs text-amber-700">{previewMessage}</p>}
            </div>
          </div>
        </div>
      )}

      {/* Denominations Table */}
      {selectedCurrencyId && (
        <div className="form-panel p-0">
          <div className="overflow-x-auto">
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th className="w-32">{t('cashdesk.cimlet')}</th>
                  <th className="w-24">{t('common.type')}</th>
                  <th className="w-32">{t('cashdesk.mennyiseg')}</th>
                  <th className="text-right w-40">{t('common.amount')}</th>
                </tr>
              </thead>
              <tbody>
                {denominations
                  // FK-072: a tört (1 alatti) névértékű törzssor a kirajzolásból is
                  // hiányzik — nem disabled, hanem egyáltalán nincs a DOM-ban.
                  .filter(
                    (d) =>
                      d.currencyId === selectedCurrencyId &&
                      d.active &&
                      isAllowedFaceValue(d.faceValue),
                  )
                  .sort((a, b) => b.faceValue - a.faceValue)
                  .map((denomination) => {
                    const quantity = editingQuantities[denomination.id] || 0
                    const total = denomination.faceValue * quantity

                    return (
                      <tr key={denomination.id}>
                        <td>
                          <span className="font-mono font-bold text-sm">
                            {formatInteger(denomination.faceValue)} {selectedCurrency?.code}
                          </span>
                        </td>
                        <td>
                          <span className="text-[10px] bg-gray-100 px-1.5 py-0.5 rounded">
                            {denomination.denominationType === 'BANKNOTE' ? 'Bankjegy' : 'Érme'}
                          </span>
                        </td>
                        <td>
                          <NumberInput
                            value={quantity > 0 ? String(quantity) : ''}
                            onChange={(val) => handleQuantityChange(denomination.id, val)}
                            className="form-input w-24 text-center"
                            placeholder="0"
                            data-testid={`denomination-qty-${denomination.id}`}
                            allowDecimals={false}
                            allowNegative={false}
                            min={0}
                            step="1"
                          />
                        </td>
                        <td className="text-right">
                          <span className="font-mono font-semibold text-green-600">
                            {formatDecimal(total, 2, 2)}
                          </span>
                        </td>
                      </tr>
                    )
                  })}
              </tbody>
              <tfoot className="bg-gray-50 font-bold">
                <tr>
                  <td colSpan={3} className="text-right pr-4">
                    {t('cashdesk.osszesen2')}
                  </td>
                  <td className="text-right">
                    <span
                      className="font-mono text-base text-blue-600"
                      data-testid="denomination-calculated-total"
                    >
                      {formatDecimal(calculatedTotal, 2, 2)} {selectedCurrency?.code}
                    </span>
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Warning */}
      {!selectedCashDeskId && (
        <div className="form-panel bg-yellow-50 border-yellow-200 flex items-center gap-2">
          <AlertCircle className="text-yellow-600" size={18} />
          <span className="text-sm text-yellow-800">
            {t('cashdesk.penztarKivalasztasaSzuksegesACimletezeshez')}
          </span>
        </div>
      )}
    </div>
  )
}

function StatusBox({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-md bg-gray-50 p-2">
      <div className="text-xs text-gray-500">{label}</div>
      <div className="mt-0.5 truncate font-semibold text-gray-900" title={String(value)}>
        {value}
      </div>
    </div>
  )
}
