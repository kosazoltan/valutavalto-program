import { useState, useCallback, useEffect, useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  AlertTriangle,
  Lock,
  Check,
  X,
  Loader2,
  Minus,
  ChevronLeft,
  Coins,
  RefreshCw,
} from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import {
  closingWizardApi,
  dailySessionApi,
  currencyApi,
  denominationApi,
} from '../../services/api/index'
import type {
  ClosingWizard,
  ClosingWizardDifference,
  ClosingWizardReport,
  ClosingWizardStep,
  DailyClosingValidation,
} from '../../services/api/transactions'
import type { Currency } from '../../services/api/exchange-rates'
import type { Denomination } from '../../services/api/settings'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { isAllowedFaceValue } from '../../utils/denominationRules'
import { localIsoDate } from '../../utils/dateFormat'
import { useTranslation } from 'react-i18next'
import {
  resolveWizardResumeAction,
  type WizardResumeAction,
  type WizardStatusValue,
} from './wizardStatusPolicy'

/** HUF cimletek — csökkeno sorrendben */
const HUF_DENOMINATIONS = [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5] as const

/**
 * Napzaras wizard — backend-driven ellenorzesi lanc.
 *
 * Legacy: NAPZAR.DLL
 * A backend closingWizardApi vezérli a lépéseket — NINCS lokális szimuláció.
 *
 * Flow:
 *   Step 1 (MTCN) fut automatikusan →
 *   PAUSE: felhasználó kitölti a címletezést és rögzíti →
 *   Steps 2-9 futnak automatikusan →
 *   Finalize (csak ha denomSubmitted + minden step PASS)
 */

type StepStatus = 'pending' | 'running' | 'done' | 'failed' | 'skipped'

interface ClosingStep {
  id: number
  label: string
  status: StepStatus
  message?: string
  completedAt?: string
}

const INITIAL_STEPS: ClosingStep[] = [
  { id: 1, label: 'MTCN szám ellenőrzés (Western Union)', status: 'pending' },
  { id: 2, label: 'Esti pénztár címletezése', status: 'pending' },
  { id: 3, label: 'Kezelési díj címletezés', status: 'pending' },
  { id: 4, label: 'Western Union címletezés', status: 'pending' },
  { id: 5, label: 'ÁFA címletezés', status: 'pending' },
  { id: 6, label: 'Foglaló címletezés', status: 'pending' },
  { id: 7, label: 'E-kereskedelem címletezés', status: 'pending' },
  { id: 8, label: 'Egyéb címletezések (AXA/MoneyGram)', status: 'pending' },
  { id: 9, label: 'NAV kontroll és napi jelentés', status: 'pending' },
]

export default function ClosingWizardPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const { wizardId: routeWizardId } = useParams<{ wizardId?: string }>()
  const worker = useAuthStore((s) => s.worker)
  const activeRole = useAuthStore((s) => s.activeRole)
  const [steps, setSteps] = useState<ClosingStep[]>(INITIAL_STEPS)
  const [isRunning, setIsRunning] = useState(false)
  const [wizardId, setWizardId] = useState<string | null>(null)
  // G10: zárás-típus választó (a backend ClosingWizardSteps DAILY/DECADE/MONTHLY/POS-t támogat).
  // A típust a backend/API által definiált ClosingWizard['closingType']-ból vesszük (nincs duplikáció).
  const [closingType, setClosingType] = useState<ClosingWizard['closingType']>('DAILY')

  // Denomination input state
  const [currencyDenominations, setCurrencyDenominations] = useState<Record<string, number[]>>({})
  // FK-063 FR-2: pénztár módban a becímletezendő pénznemek a backend
  // currencies-with-balance végpontból jönnek (HUF mindig kötelező).
  const [cashierCurrencies, setCashierCurrencies] = useState<string[]>(['HUF'])
  const [cashierDenominations, setCashierDenominations] = useState<Record<string, number[]>>({})
  const [denomQuantities, setDenomQuantities] = useState<Record<string, number>>(() =>
    Object.fromEntries(HUF_DENOMINATIONS.map((d) => [`HUF:${d}`, 0])),
  )
  const denomKey = (currencyCode: string, faceValue: number) => `${currencyCode}:${faceValue}`
  const normalizedRole = (activeRole ?? worker?.role ?? '').toString().toLowerCase()
  const isVaultContext =
    normalizedRole.includes('ertektar') ||
    normalizedRole.includes('vault') ||
    normalizedRole.includes('foertektar')
  const denominationSections = useMemo(
    () =>
      // FK-072: az 1 alatti (tört) névértékű sor SEMMILYEN formában nem kerülhet a
      // kirajzolásba — a szűrés itt, az egyetlen közös ponton fut, így a vault- és a
      // pénztár-ág (és a HUF-fallback) is azonos elven védett (NFR-2).
      (isVaultContext
        ? Object.entries(currencyDenominations)
            .map(([currencyCode, faceValues]) => ({ currencyCode, faceValues }))
            .sort((a, b) => a.currencyCode.localeCompare(b.currencyCode))
        : // FK-063 FR-2: dinamikus, cash_balance-alapú szekciók — HUF mindig,
          // a többi pénznem csak akkor, ha van belőle készlet. A címletlista a
          // denomination törzsből jön; HUF-ra a beépített lista a fallback.
          // PR #1483 review: a címlettörzs-hiányos, de készleten lévő pénznem NEM
          // eshet ki (üres szekcióként blokkolja a továbblépést, nem tűnik el).
          cashierCurrencies.map((currencyCode) => ({
            currencyCode,
            faceValues:
              currencyCode === 'HUF'
                ? cashierDenominations['HUF']?.length
                  ? cashierDenominations['HUF']
                  : [...HUF_DENOMINATIONS]
                : (cashierDenominations[currencyCode] ?? []),
          }))
      ).map(({ currencyCode, faceValues }) => ({
        currencyCode,
        faceValues: faceValues.filter(isAllowedFaceValue),
      })),
    [currencyDenominations, isVaultContext, cashierCurrencies, cashierDenominations],
  )
  const denominationTotals = useMemo(
    () =>
      Object.fromEntries(
        denominationSections.map(({ currencyCode, faceValues }) => [
          currencyCode,
          faceValues.reduce(
            (sum, faceValue) =>
              sum + faceValue * (denomQuantities[denomKey(currencyCode, faceValue)] ?? 0),
            0,
          ),
        ]),
      ) as Record<string, number>,
    [denominationSections, denomQuantities],
  )
  const denomTotal = useMemo(
    () => Object.values(denominationTotals).reduce((sum, value) => sum + value, 0),
    [denominationTotals],
  )
  const [denomSubmitted, setDenomSubmitted] = useState(false)
  const [closingDifferences, setClosingDifferences] = useState<ClosingWizardDifference[]>([])
  const [closingReport, setClosingReport] = useState<ClosingWizardReport | null>(null)
  const [reportLoading, setReportLoading] = useState(false)
  const [closingValidation, setClosingValidation] = useState<DailyClosingValidation | null>(null)
  const [validationLoading, setValidationLoading] = useState(false)
  const [validationError, setValidationError] = useState<string | null>(null)
  const [wizardLoading, setWizardLoading] = useState(false)
  const [currentStepDetail, setCurrentStepDetail] = useState<ClosingWizardStep | null>(null)

  // Wizard pauses after step 1 for denomination input
  const [waitingForDenom, setWaitingForDenom] = useState(false)

  // FK-065 FR-3: mountkor felderített beragadt zárási munkamenet (resume =
  // IN_PROGRESS, restart-only = EXPIRED); statusPolicyError = ismeretlen státusz
  // (exhaustiveness-throw a wizardStatusPolicy-ból) — semleges, perzisztens jelzés.
  const [staleWizard, setStaleWizard] = useState<{
    id: string
    action: Exclude<WizardResumeAction, 'none'>
  } | null>(null)
  const [statusPolicyError, setStatusPolicyError] = useState(false)
  // Bugbot Medium fix: a beragadt munkamenet megszakításának hibája — konkrét,
  // bannerben megjelenő üzenet (nem általános toast), a banner megtartása mellett.
  const [staleActionError, setStaleActionError] = useState<string | null>(null)

  const completedCount = steps.filter((s) => s.status === 'done' || s.status === 'skipped').length
  const failedCount = steps.filter((s) => s.status === 'failed').length
  const progress = (completedCount / steps.length) * 100

  // Finalize requires ALL steps PASS **and** denomination submitted
  const canFinalize = completedCount === steps.length && failedCount === 0 && denomSubmitted

  // FK-063 FR-7: pénznemenkénti kitöltöttség — a Tovább gomb minden kötelező
  // pénznemre (HUF + készleten lévő devizák) nem-nulla részösszeget vár.
  const allSectionsFilled = useMemo(
    () =>
      denominationSections.length > 0 &&
      denominationSections.every(({ currencyCode }) => (denominationTotals[currencyCode] ?? 0) > 0),
    [denominationSections, denominationTotals],
  )

  // FK-064 Fázis 1: egységes "zárás-készenlét" derived állapot a 3 UI-forrásból
  // (A: closingValidation zöld/borostyán panel, B: steps piros checklist,
  //  C: closingDifferences eltérés-táblázat). N pénznem-sorra agnosztikus.
  const closingReadiness = useMemo<{ ready: boolean; blockingSources: string[] }>(() => {
    const blockingSources: string[] = []
    if (!closingValidation?.allValid) {
      blockingSources.push(t('closing.forrasElokontroll'))
    }
    if (failedCount > 0 || completedCount !== steps.length || !denomSubmitted) {
      blockingSources.push(t('closing.forrasChecklist'))
    }
    if (closingDifferences.some(isBlockingDifference)) {
      blockingSources.push(t('closing.forrasElteresTablazat'))
    }
    return { ready: blockingSources.length === 0, blockingSources }
  }, [
    closingValidation,
    failedCount,
    completedCount,
    steps.length,
    denomSubmitted,
    closingDifferences,
    t,
  ])

  const loadClosingValidation = useCallback(async () => {
    setValidationLoading(true)
    setValidationError(null)
    try {
      setClosingValidation(await dailySessionApi.validateClosing())
    } catch (err) {
      setClosingValidation(null)
      setValidationError(getErrorMessage(err))
    } finally {
      setValidationLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadClosingValidation()
  }, [loadClosingValidation])

  // FK-065 FR-3: beragadt zárási munkamenet felderítése — mountkor MINDIG lefut.
  // Egyhívásos szerződés: az activeWizardId + activeWizardStatus a getStatus
  // válaszából jön, külön get(activeWizardId) hívás TILOS.
  useEffect(() => {
    let cancelled = false
    const checkStaleWizard = async () => {
      try {
        // Időzóna-biztos lokális dátum (Sourcery-javaslat: közös util, nem lokális helper)
        const status = await closingWizardApi.getStatus(localIsoDate())
        if (cancelled || !status?.activeWizardId || !status?.activeWizardStatus) return
        try {
          const action = resolveWizardResumeAction(status.activeWizardStatus as WizardStatusValue)
          if (!cancelled && action !== 'none') {
            setStaleWizard({ id: status.activeWizardId, action })
          }
        } catch (policyErr) {
          // Ismeretlen státusz (pl. verzió-eltérés kliens és backend közt): a
          // wizardStatusPolicy szándékosan dob — itt semleges, perzisztens inline
          // jelzésre váltunk, a normál indítás elérhető marad.
          logger.error('ClosingWizardPage', 'Ismeretlen wizard státusz:', policyErr)
          if (!cancelled) setStatusPolicyError(true)
        }
      } catch {
        // A státusz-lekérdezés hibája nem blokkolhatja a normál zárás-indítást.
      }
    }
    void checkStaleWizard()
    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    if (!isVaultContext) return

    let cancelled = false
    const loadDenominations = async () => {
      try {
        const [currencies, denominations] = await Promise.all([
          currencyApi.getActive(),
          denominationApi.list(),
        ])
        if (cancelled) return

        const activeCodes = new Set(currencies.map((currency: Currency) => currency.code))
        const grouped: Record<string, number[]> = {}
        denominations.forEach((denomination: Denomination) => {
          if (!activeCodes.has(denomination.currencyCode)) return
          if (!grouped[denomination.currencyCode]) {
            grouped[denomination.currencyCode] = []
          }
          grouped[denomination.currencyCode]!.push(denomination.faceValue)
        })
        Object.keys(grouped).forEach((code) => {
          grouped[code] = [...new Set(grouped[code])].sort((a, b) => b - a)
        })
        setCurrencyDenominations(grouped)
      } catch (err) {
        if (!cancelled) {
          logger.error('ClosingWizardPage', 'Valuta címlettörzs betöltési hiba:', err)
          toast.error('Címlettörzs hiba', getErrorMessage(err))
        }
      }
    }

    void loadDenominations()
    return () => {
      cancelled = true
    }
  }, [isVaultContext])

  // FK-063 FR-2: pénztár módban a készleten lévő pénznemek + címlettörzs betöltése.
  // A HUF mindig kötelező (a backend garantálja); a nem-HUF szekciók csak akkor
  // jelennek meg, ha van belőlük nem-nulla cash_balance készlet.
  useEffect(() => {
    if (isVaultContext) return

    let cancelled = false
    const loadCashierCurrencies = async () => {
      try {
        const [currencies, denominations] = await Promise.all([
          closingWizardApi.getCurrenciesWithBalance(),
          denominationApi.list(),
        ])
        if (cancelled) return

        const wanted = new Set(currencies)
        const grouped: Record<string, number[]> = {}
        denominations.forEach((denomination: Denomination) => {
          if (!wanted.has(denomination.currencyCode)) return
          if (!grouped[denomination.currencyCode]) {
            grouped[denomination.currencyCode] = []
          }
          grouped[denomination.currencyCode]!.push(denomination.faceValue)
        })
        Object.keys(grouped).forEach((code) => {
          grouped[code] = [...new Set(grouped[code])].sort((a, b) => b - a)
        })
        setCashierCurrencies(currencies.includes('HUF') ? currencies : ['HUF', ...currencies])
        setCashierDenominations(grouped)
      } catch (err) {
        if (!cancelled) {
          // Fallback: HUF-only forma (offline / végpont-hiba esetén sem blokkolja a zárást)
          logger.error('ClosingWizardPage', 'Készleten lévő pénznemek betöltési hiba:', err)
          toast.error(t('closing.keszletPenznemHiba'), getErrorMessage(err))
        }
      }
    }

    void loadCashierCurrencies()
    return () => {
      cancelled = true
    }
  }, [isVaultContext, t])

  useEffect(() => {
    if (!routeWizardId) return

    let cancelled = false
    const loadExistingWizard = async () => {
      setWizardLoading(true)
      try {
        const wizard = await closingWizardApi.get(routeWizardId)
        if (cancelled) return
        setWizardId(wizard.id)
        setClosingType(wizard.closingType)
        setSteps((prev) =>
          prev.map((step) => {
            const backendStep = wizard.steps?.find((item) => item.stepNumber === step.id)
            if (!backendStep) return step
            return {
              ...step,
              label: backendStep.stepTitle || step.label,
              status: backendStep.completed ? 'done' : 'pending',
              message: backendStep.completed ? 'Rendben' : backendStep.stepDescription,
            }
          }),
        )

        const stepNumber = wizard.currentStep || 1
        const stepDetail = await closingWizardApi.getStep(wizard.id, stepNumber)
        if (!cancelled) setCurrentStepDetail(stepDetail)
      } catch (err) {
        if (!cancelled) toast.error('Zárási varázsló betöltése sikertelen', getErrorMessage(err))
      } finally {
        if (!cancelled) setWizardLoading(false)
      }
    }

    void loadExistingWizard()
    return () => {
      cancelled = true
    }
  }, [routeWizardId])

  /** Run backend steps from `from` to `to` (0-indexed). Returns true if all passed. */
  const runSteps = useCallback(
    async (wizId: string, from: number, to: number): Promise<boolean> => {
      for (let i = from; i <= to; i++) {
        setSteps((prev) =>
          prev.map((s, idx) => (idx === i ? { ...s, status: 'running' as StepStatus } : s)),
        )

        try {
          const result = await closingWizardApi.navigate(wizId, i + 1)
          const stepData = result.steps?.find((s) => s.stepNumber === i + 1)
          const now = new Date().toLocaleTimeString('hu-HU')
          const passed = stepData ? stepData.completed : true

          setSteps((prev) =>
            prev.map((s, idx) =>
              idx === i
                ? {
                    ...s,
                    status: passed ? 'done' : 'failed',
                    // Issue #117: a backend stepData.message mezo tartalmazza a valodi hibauzenetet,
                    // NEM a stepDescription (ami a lepes leirasa). Priority: stepData.message -> stepDescription -> fallback.
                    message: passed
                      ? 'Rendben'
                      : ((typeof stepData?.stepData?.message === 'string'
                          ? stepData.stepData.message
                          : undefined) ??
                        stepData?.stepDescription ??
                        'Eltérés találva!'),
                    completedAt: now,
                  }
                : s,
            ),
          )

          if (!passed) return false
        } catch (stepError) {
          const now = new Date().toLocaleTimeString('hu-HU')
          const errorMsg = stepError instanceof Error ? stepError.message : 'Ismeretlen hiba'

          setSteps((prev) =>
            prev.map((s, idx) =>
              idx === i ? { ...s, status: 'failed', message: errorMsg, completedAt: now } : s,
            ),
          )
          return false
        }
      }
      return true
    },
    [],
  )

  /** Phase 1: start wizard + run step 1, then pause for denomination input */
  const runClosing = useCallback(async () => {
    // 2026-04-29 v2.3.10 (Sourcery PR #271): structured logger használata console helyett
    logger.info(
      'ClosingWizardPage',
      'runClosing started, worker=',
      worker?.workerCode,
      worker?.branchId,
    )

    if (!worker) {
      toast.error('Hiba', 'Nincs bejelentkezett felhasználó!')
      return
    }

    setIsRunning(true)
    setClosingReport(null)
    setClosingDifferences([])
    setReportLoading(false)
    toast.info('Napzárás indítása', 'Wizard indítása folyamatban...')

    // FK-065 FR-4: a hiba-ágakban (step-1 bukás, kivétel) az elindított wizard
    // megszakítandó, hogy ne maradjon beragadt IN_PROGRESS sor.
    let startedWizardId: string | null = null
    try {
      const transactionErrors = await closingWizardApi.validateTransactions()
      if (transactionErrors.length > 0) {
        const errorMsg = transactionErrors.join('\n')
        const now = new Date().toLocaleTimeString('hu-HU')
        setSteps((prev) =>
          prev.map((s, idx) =>
            idx === 0 ? { ...s, status: 'failed', message: errorMsg, completedAt: now } : s,
          ),
        )
        toast.warning('Nyitott tranzakció validáció sikertelen', errorMsg)
        setIsRunning(false)
        return
      }

      const wizard = await closingWizardApi.start(
        worker.branchId,
        undefined,
        closingType,
        String(worker.id),
      )
      logger.info('ClosingWizardPage', 'wizard started, id=', wizard.id)
      startedWizardId = wizard.id
      setWizardId(wizard.id)

      // Run step 1 (MTCN check)
      const step1Ok = await runSteps(wizard.id, 0, 0)
      if (!step1Ok) {
        // FK-065 FR-4: bukó indítás → wizard-megszakítás a hibaüzenet előtt
        try {
          await closingWizardApi.cancel(wizard.id)
        } catch {
          // cancel-hiba nem blokkoló
        }
        toast.warning('Step 1 sikertelen', 'A MTCN ellenőrzés nem ment át')
        setIsRunning(false)
        return
      }

      toast.success(
        'Step 1 OK',
        isVaultContext
          ? 'Most rögzítsd a valutánkénti címletezést'
          : 'Most rögzítsd a HUF címletezést',
      )

      // Pause: wait for denomination input before continuing
      setIsRunning(false)
      setWaitingForDenom(true)
    } catch (err) {
      // FK-065 FR-4: kivétel esetén sem maradhat beragadt IN_PROGRESS sor
      if (startedWizardId) {
        try {
          await closingWizardApi.cancel(startedWizardId)
        } catch {
          // cancel-hiba nem blokkoló
        }
      }
      logger.error('ClosingWizardPage', 'start failed:', err)
      toast.error('Napzárás hiba', getErrorMessage(err))
      setIsRunning(false)
    }
  }, [worker, runSteps, closingType, isVaultContext])

  // FK-065 FR-3: beragadt munkamenet folytatása — a meglévő route-alapú betöltési
  // útra visz (/closing/wizard/:wizardId), új API-felület nélkül.
  const handleResumeStale = useCallback(() => {
    if (staleWizard) {
      navigate(`/closing/wizard/${staleWizard.id}`)
    }
  }, [staleWizard, navigate])

  // FK-065 FR-3: megszakítás/új zárás — IN_PROGRESS sort előbb megszakítjuk;
  // EXPIRED sorra a backend cancel-t úgyis elutasítaná, ott csak új zárás indul.
  const handleRestartStale = useCallback(async () => {
    if (!staleWizard) return
    setStaleActionError(null)
    if (staleWizard.action === 'resume') {
      try {
        await closingWizardApi.cancel(staleWizard.id)
      } catch (err) {
        // Bugbot Medium fix: bukó cancel után NEM indulhat új zárás (a backend
        // start-guardja a még aktív mai wizard miatt úgyis elutasítaná) és a
        // banner sem tűnhet el. Konkrét hibaüzenet + státusz-frissítés: ha
        // időközben más úton (pl. auto-expiry) megoldódott, a banner ahhoz igazodik.
        logger.error('ClosingWizardPage', 'Beragadt wizard megszakítása sikertelen:', err)
        setStaleActionError('A korábbi munkamenet megszakítása sikertelen, próbáld újra')
        try {
          const status = await closingWizardApi.getStatus(localIsoDate())
          if (!status?.activeWizardId || !status?.activeWizardStatus) {
            // Időközben megszűnt az aktív munkamenet — a banner okafogyottá vált.
            setStaleWizard(null)
          } else {
            const action = resolveWizardResumeAction(status.activeWizardStatus as WizardStatusValue)
            setStaleWizard(action !== 'none' ? { id: status.activeWizardId, action } : null)
          }
        } catch {
          // A frissítés hibája nem ronthat tovább: a meglévő banner marad.
        }
        return
      }
    }
    setStaleWizard(null)
    setStaleActionError(null)
    await runClosing()
  }, [staleWizard, runClosing])

  /** Phase 2: user submitted denomination → persist to backend, then continue steps 2-9 */
  const continueAfterDenom = useCallback(async () => {
    if (!wizardId) return

    setIsRunning(true)

    const denominationPayload = Object.fromEntries(
      denominationSections.map(({ currencyCode, faceValues }) => [
        currencyCode,
        Object.fromEntries(
          faceValues
            // Codex P1 (PR #1483): csak a ténylegesen kitöltött tételek mennek a
            // payloadba — a 0 darabos (pl. tört címletű) sorok kihagyása megvédi a
            // backend Map<Integer,Integer> szerződését és nem hoz létre üres rekordot.
            .filter((faceValue) => (denomQuantities[denomKey(currencyCode, faceValue)] ?? 0) > 0)
            .map((faceValue) => [
              faceValue,
              denomQuantities[denomKey(currencyCode, faceValue)] ?? 0,
            ]),
        ),
      ]),
    )

    // Submit denomination data to backend before continuing
    try {
      await closingWizardApi.submitDenominations(wizardId, denominationPayload)
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Cimletezés rögzítés sikertelen'
      toast.error('Cimletezés hiba', errorMsg)
      setIsRunning(false)
      return
    }

    try {
      setClosingDifferences(
        await closingWizardApi.calculateDifferences(wizardId, denominationTotals),
      )
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : t('closing.elteresEllenorzesHiba')
      toast.error(t('closing.elteresEllenorzesHiba'), errorMsg)
      setIsRunning(false)
      return
    }

    setDenomSubmitted(true)
    setWaitingForDenom(false)

    // Run steps 2-9
    const stepsOk = await runSteps(wizardId, 1, steps.length - 1)
    if (stepsOk) {
      setReportLoading(true)
      try {
        setClosingReport(await closingWizardApi.getReport(wizardId))
        await loadClosingValidation()
      } catch (err) {
        toast.error('Zárási riport hiba', getErrorMessage(err))
        setClosingReport(null)
      } finally {
        setReportLoading(false)
      }
    } else {
      setClosingReport(null)
    }
    setIsRunning(false)
  }, [
    wizardId,
    denominationSections,
    denomQuantities,
    denominationTotals,
    steps.length,
    runSteps,
    loadClosingValidation,
    t,
  ])

  const handleFinalize = useCallback(async () => {
    if (!closingReadiness.ready || !canFinalize || !wizardId || !worker) return

    try {
      await closingWizardApi.finalize(wizardId, String(worker.id))
      toast.success('Napzárás végrehajtva', 'A nap lezárva.')
      navigate('/')
    } catch (err) {
      // getErrorMessage a backend response.data.message-t adja (AxiosError-nál az
      // err.message csak "Request failed with status code 400" lenne) — Sourcery/Copilot #791.
      const errorMsg = getErrorMessage(err)
      // G3 (FR-13): ha az eltérés-gate magyarázatot kér, inline modallal kérjük be és újrapróbáljuk.
      // NEM window.prompt: az Electron rendererben nem támogatott (a penztar-client is ezt az oldalt
      // futtatja) — V307-tel a gate éles, prompt-tal a zárás beragadna.
      if (/eltérés/i.test(errorMsg) && /magyarázat/i.test(errorMsg)) {
        setDiscrepancyPrompt({ message: errorMsg, explanation: '' })
        return
      }
      toast.error('Hiba', errorMsg)
    }
  }, [closingReadiness.ready, canFinalize, wizardId, worker, navigate])

  // G3 (FR-13): eltérés-magyarázat modal állapota (null = zárva).
  const [discrepancyPrompt, setDiscrepancyPrompt] = useState<{
    message: string
    explanation: string
  } | null>(null)
  const [discrepancySubmitting, setDiscrepancySubmitting] = useState(false)

  const handleDiscrepancySubmit = useCallback(async () => {
    if (!discrepancyPrompt || !wizardId || !worker) return
    const explanation = discrepancyPrompt.explanation.trim()
    if (!explanation) return
    setDiscrepancySubmitting(true)
    try {
      await closingWizardApi.finalize(wizardId, String(worker.id), explanation)
      toast.success('Napzárás végrehajtva', 'A nap lezárva (eltérés-magyarázattal).')
      setDiscrepancyPrompt(null)
      navigate('/')
    } catch (retryErr) {
      toast.error('Hiba', getErrorMessage(retryErr))
    } finally {
      setDiscrepancySubmitting(false)
    }
  }, [discrepancyPrompt, wizardId, worker, navigate])

  const handleCancel = useCallback(async () => {
    if (wizardId) {
      try {
        await closingWizardApi.cancel(wizardId)
      } catch {
        // Wizard cancel hiba nem blokkoló
      }
    }
    setSteps(INITIAL_STEPS)
    setWizardId(null)
    setWaitingForDenom(false)
    setDenomSubmitted(false)
    setClosingReport(null)
    setClosingDifferences([])
    setReportLoading(false)
    setDenomQuantities(Object.fromEntries(HUF_DENOMINATIONS.map((d) => [`HUF:${d}`, 0])))
  }, [wizardId])

  const statusIcon = (status: StepStatus) => {
    switch (status) {
      case 'done':
        return <Check className="w-5 h-5 text-green-500" />
      case 'failed':
        return <X className="w-5 h-5 text-red-500" />
      case 'running':
        return <Loader2 className="w-5 h-5 text-blue-500 animate-spin" />
      case 'skipped':
        return <Minus className="w-5 h-5 text-gray-400" />
      default:
        return (
          <div className="w-5 h-5 rounded-full border-2 border-gray-300 dark:border-gray-600" />
        )
    }
  }

  const statusText = (step: ClosingStep) => {
    switch (step.status) {
      case 'done':
        return (
          <span className="text-green-600 dark:text-green-400 font-medium">
            {t('closing.rendben')}
            {step.completedAt})
          </span>
        )
      case 'failed':
        return (
          <span className="text-red-600 dark:text-red-400 font-medium">
            {t('closing.hiba')}
            {step.message}
          </span>
        )
      case 'running':
        return (
          <span className="text-blue-600 dark:text-blue-400 font-medium animate-pulse">
            FOLYAMATBAN...
          </span>
        )
      case 'skipped':
        return <span className="text-gray-400">KIHAGYVA</span>
      default:
        return <span className="text-gray-400">{t('closing.var')}</span>
    }
  }

  // Denomination inputs enabled only when waiting for denom input
  const denomEditable = waitingForDenom && !denomSubmitted && !isRunning

  return (
    <div className="max-w-4xl mx-auto space-y-2">
      {/* FEJLEC */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate('/')}
            className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <Lock className="w-5 h-5 text-[var(--primary)]" />
          <h1 className="text-lg font-bold text-gray-900 dark:text-white">
            {t('closing.napzarasWizard')}
          </h1>
        </div>
        <span className="text-xs font-semibold bg-gray-200 dark:bg-gray-700 px-2 py-1 rounded">
          {completedCount} / {steps.length} {t('common.kesz')}
        </span>
      </div>

      {/* FK-064 Fázis 3: egységes "Kész a beküldésre" / "Van teendő" jelzés */}
      <div
        data-testid="closing-readiness-banner"
        className={`flex items-start gap-2 rounded-md border p-2 text-sm ${
          closingReadiness.ready
            ? 'border-green-200 bg-green-50 text-green-800 dark:border-green-900/60 dark:bg-green-950/30 dark:text-green-200'
            : 'border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/30 dark:text-amber-200'
        }`}
      >
        {closingReadiness.ready ? (
          <Check className="mt-0.5 h-4 w-4 shrink-0" />
        ) : (
          <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
        )}
        <span>
          {closingReadiness.ready
            ? t('closing.keszABekuldesre')
            : `${t('closing.vanTeendo')} (${closingReadiness.blockingSources.join(', ')})`}
        </span>
      </div>

      {/* PROGRESS BAR */}
      <div>
        <div className="flex justify-between text-xs text-gray-600 dark:text-gray-400 mb-0.5">
          <span>{t('closing.elorehaladas')}</span>
          <span>{Math.round(progress)}%</span>
        </div>
        <div className="h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-green-500 to-emerald-600 transition-all duration-500"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      <div className="rounded-lg border border-gray-200 bg-white p-3 dark:border-gray-700 dark:bg-gray-800">
        <div className="mb-3 flex items-start justify-between gap-2">
          <div>
            <h2 className="text-sm font-bold text-gray-900 dark:text-white">
              Napi zárás előellenőrzés
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              Címletezési és zárási készültség
            </p>
          </div>
          <button
            type="button"
            onClick={() => void loadClosingValidation()}
            disabled={validationLoading}
            className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-60 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-700"
            aria-label="Napi zárás előellenőrzés frissítése"
          >
            <RefreshCw className={`h-4 w-4 ${validationLoading ? 'animate-spin' : ''}`} />
          </button>
        </div>

        {validationError ? (
          <div className="flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50 p-2 text-sm text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/30 dark:text-amber-200">
            <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{validationError}</span>
          </div>
        ) : closingValidation ? (
          <>
            {/* FK-064 Fázis 2 (FR-3): a panel a closingReadiness-t is figyeli — nem mutat
                "minden rendben"-t, ha az eltérés-táblázatban megoldatlan eltérés van. */}
            <div
              className={`mb-2 rounded-md border p-2 text-sm ${
                closingValidation.allValid && !closingDifferences.some(isBlockingDifference)
                  ? 'border-green-200 bg-green-50 text-green-800 dark:border-green-900/60 dark:bg-green-950/30 dark:text-green-200'
                  : 'border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/30 dark:text-amber-200'
              }`}
            >
              {closingValidation.allValid && closingDifferences.some(isBlockingDifference)
                ? t('closing.megoldatlanElteresVan')
                : closingValidation.errorMessage ||
                  (closingValidation.allValid
                    ? 'Minden címletezés rendben'
                    : 'Zárási ellenőrzés nem teljes')}
            </div>
            <div className="grid grid-cols-2 gap-2 text-xs sm:grid-cols-5">
              <ValidationPill label="Valuta" ok={closingValidation.currencyDenominationOk} />
              <ValidationPill
                label="Kezelési díj"
                ok={closingValidation.handlingFeeDenominationOk}
              />
              <ValidationPill
                label="Western Union"
                ok={closingValidation.westernUnionDenominationOk}
              />
              <ValidationPill label="ÁFA" ok={closingValidation.vatDenominationOk} />
              <ValidationPill
                label="E-kereskedelem"
                ok={closingValidation.ecommerceDenominationOk}
              />
            </div>
          </>
        ) : (
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <Loader2 className="h-4 w-4 animate-spin" />
            Előellenőrzés betöltése...
          </div>
        )}
      </div>

      {(wizardLoading || currentStepDetail) && (
        <div
          className="rounded-lg border border-blue-200 bg-blue-50 p-3 text-sm text-blue-900 dark:border-blue-900/60 dark:bg-blue-950/30 dark:text-blue-200"
          data-testid="closing-wizard-current-step"
        >
          <div className="mb-1 flex items-center gap-2 font-semibold">
            {wizardLoading && <Loader2 className="h-4 w-4 animate-spin" />}
            Betöltött zárási varázsló
          </div>
          {currentStepDetail && (
            <div className="space-y-1">
              <div>
                Aktuális lépés: {currentStepDetail.stepNumber}. {currentStepDetail.stepTitle}
              </div>
              {currentStepDetail.stepDescription && (
                <div className="text-xs opacity-80">{currentStepDetail.stepDescription}</div>
              )}
            </div>
          )}
        </div>
      )}

      {/* ELLENORZESI LISTA */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        {steps.map((step) => (
          <div
            key={step.id}
            className={`flex items-center justify-between px-3 py-1.5 border-b border-gray-100 dark:border-gray-700 last:border-b-0 transition-colors ${
              step.status === 'running' ? 'bg-blue-50 dark:bg-blue-950/20' : ''
            } ${step.status === 'failed' ? 'bg-red-50 dark:bg-red-950/20' : ''}`}
          >
            <div className="flex items-center gap-2">
              <span className="w-6 h-6 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-xs font-bold text-gray-600 dark:text-gray-300">
                {step.id}
              </span>
              {statusIcon(step.status)}
              <span className="text-sm font-medium text-gray-900 dark:text-white">
                {step.label}
              </span>
            </div>
            <div className="text-sm">{statusText(step)}</div>
          </div>
        ))}
      </div>

      {/* ZARO CIMLETEZÉS — visible after step 1 completes */}
      {(waitingForDenom || denomSubmitted) && (
        <div
          className={`bg-white dark:bg-gray-800 rounded-lg border-2 p-2 transition-colors ${
            waitingForDenom && !denomSubmitted
              ? 'border-amber-400 dark:border-amber-500 ring-2 ring-amber-200 dark:ring-amber-800'
              : 'border-gray-200 dark:border-gray-700'
          }`}
        >
          <div className="flex items-center gap-2 mb-1">
            <Coins className="w-4 h-4 text-amber-500" />
            <h2 className="text-sm font-bold text-gray-900 dark:text-white">
              {t('closing.estiPenztarCimletezese')}
            </h2>
            {waitingForDenom && !denomSubmitted && (
              <span className="text-[10px] font-semibold text-amber-600 dark:text-amber-400 bg-amber-100 dark:bg-amber-900/30 px-1.5 py-0.5 rounded">
                {t('closing.kitoltesSzukseges')}
              </span>
            )}
          </div>
          {!denomSubmitted ? (
            <>
              <div className="space-y-3">
                {denominationSections.map(({ currencyCode, faceValues }) => (
                  <div key={currencyCode}>
                    {(isVaultContext || denominationSections.length > 1) && (
                      <div className="mb-1 text-xs font-semibold text-gray-700 dark:text-gray-300">
                        {currencyCode}
                      </div>
                    )}
                    <div className="grid grid-cols-3 sm:grid-cols-4 gap-x-2 gap-y-0.5">
                      {faceValues.map((faceValue) => (
                        <div
                          key={`${currencyCode}-${faceValue}`}
                          className="flex items-center gap-1"
                        >
                          <span className="w-16 text-right text-xs font-medium text-gray-700 dark:text-gray-300">
                            {faceValue.toLocaleString('hu-HU')}
                          </span>
                          <input
                            type="number"
                            min={0}
                            value={denomQuantities[denomKey(currencyCode, faceValue)] || ''}
                            onChange={(e) => {
                              const val = Math.max(0, parseInt(e.target.value) || 0)
                              setDenomQuantities((prev) => ({
                                ...prev,
                                [denomKey(currencyCode, faceValue)]: val,
                              }))
                            }}
                            className="w-14 rounded border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-1 py-0.5 text-center text-xs focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                            placeholder="0"
                            disabled={!denomEditable}
                          />
                        </div>
                      ))}
                    </div>
                    {(isVaultContext || denominationSections.length > 1) && (
                      <div className="mt-1 text-right text-xs font-semibold text-gray-600 dark:text-gray-300">
                        {currencyCode}:{' '}
                        {(denominationTotals[currencyCode] ?? 0).toLocaleString('hu-HU')}
                      </div>
                    )}
                  </div>
                ))}
              </div>
              {/* FK-063 FR-7: pénznemenkénti részösszeg — több pénznemnél nem egyetlen
                  összevont "… Ft" szám, hanem pénznemenkénti bontás. */}
              <div className="mt-1 flex items-center justify-between border-t border-gray-200 dark:border-gray-700 pt-1">
                <span className="text-sm font-bold text-gray-800 dark:text-gray-200">
                  {t('cashdesk.osszesen')}
                </span>
                <span className="text-base font-bold text-blue-900 dark:text-blue-300">
                  {formatDenominationTotals(
                    denominationSections,
                    denominationTotals,
                    t('common.ft'),
                    denomTotal,
                  )}
                </span>
              </div>
              <button
                onClick={continueAfterDenom}
                disabled={
                  (!isVaultContext && !allSectionsFilled) ||
                  !denomEditable ||
                  denominationSections.length === 0
                }
                className="mt-1 w-full rounded bg-amber-600 py-1.5 text-sm font-bold text-white hover:bg-amber-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                {t('closing.cimletezesRogziteseEsTovabblepes')}
              </button>
            </>
          ) : (
            <div className="flex items-center gap-2 rounded bg-green-50 dark:bg-green-900/20 p-2">
              <Check className="h-4 w-4 text-green-600" />
              <span className="text-xs font-medium text-green-800 dark:text-green-300">
                {t('closing.cimletezesRogzitve')}
                {formatDenominationTotals(
                  denominationSections,
                  denominationTotals,
                  t('common.ft'),
                  denomTotal,
                )}
              </span>
            </div>
          )}
        </div>
      )}

      {closingDifferences.length > 0 && (
        <div className="rounded-lg border border-gray-200 bg-white p-3 dark:border-gray-700 dark:bg-gray-800">
          <div className="mb-3">
            <h2 className="text-sm font-bold text-gray-900 dark:text-white">
              {t('closing.elteresEllenorzes')}
            </h2>
            <p className="text-xs text-gray-500 dark:text-gray-400">
              {t('closing.elteresEllenorzesLeiras')}
            </p>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-xs" data-testid="closing-differences-table">
              <thead className="bg-gray-50 text-gray-500 dark:bg-gray-900/40 dark:text-gray-400">
                <tr>
                  <th className="px-2 py-1 font-semibold">{t('common.currency')}</th>
                  <th className="px-2 py-1 text-right font-semibold">{t('closing.elvart')}</th>
                  <th className="px-2 py-1 text-right font-semibold">{t('closing.tenyleges')}</th>
                  <th className="px-2 py-1 text-right font-semibold">{t('closing.elteres')}</th>
                  <th className="px-2 py-1 text-right font-semibold">{t('closing.statusz')}</th>
                </tr>
              </thead>
              <tbody>
                {closingDifferences.map((item) => (
                  <tr
                    key={item.currencyCode}
                    className="border-t border-gray-100 dark:border-gray-700"
                  >
                    <td className="px-2 py-1 font-semibold">{item.currencyCode}</td>
                    <td className="px-2 py-1 text-right">{formatAmount(item.expected)}</td>
                    <td className="px-2 py-1 text-right">{formatAmount(item.actual)}</td>
                    <td
                      className={`px-2 py-1 text-right font-semibold ${item.status === 'OK' ? 'text-green-700' : 'text-amber-700'}`}
                    >
                      {formatAmount(item.difference)}
                    </td>
                    <td className="px-2 py-1 text-right">
                      {item.status === 'OK' ? t('closing.nincsElteres') : item.status}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {(reportLoading || closingReport) && (
        <div className="rounded-lg border border-gray-200 bg-white p-3 dark:border-gray-700 dark:bg-gray-800">
          <div className="mb-3 flex items-center justify-between gap-2">
            <div>
              <h2 className="text-sm font-bold text-gray-900 dark:text-white">
                Zárási riport előnézet
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Backend riport a véglegesítés előtti ellenőrzéshez
              </p>
            </div>
            {reportLoading && <Loader2 className="h-4 w-4 animate-spin text-blue-500" />}
          </div>

          {closingReport && (
            <>
              <div className="grid grid-cols-2 gap-2 text-sm md:grid-cols-4">
                <ReportMetric label="Iroda" value={closingReport.branchName} />
                <ReportMetric label="Zárás dátuma" value={closingReport.closingDate} />
                <ReportMetric label="Típus" value={closingReport.closingType} />
                <ReportMetric label="Tranzakció" value={closingReport.transactionCount ?? 0} />
                <ReportMetric label="Vétel" value={closingReport.buyCount ?? 0} />
                <ReportMetric label="Eladás" value={closingReport.sellCount ?? 0} />
                <ReportMetric label="Sztornó" value={closingReport.reversalCount ?? 0} />
                <ReportMetric
                  label="Kezelési díj"
                  value={`${formatHuf(closingReport.handlingFeeTotal)} Ft`}
                />
                <ReportMetric
                  label="Vételi forgalom"
                  value={`${formatHuf(closingReport.buyTurnoverHuf)} Ft`}
                />
                <ReportMetric
                  label="Eladási forgalom"
                  value={`${formatHuf(closingReport.sellTurnoverHuf)} Ft`}
                />
                <ReportMetric
                  label="Nyitó HUF"
                  value={`${formatHuf(closingReport.openingBalanceHuf)} Ft`}
                />
                <ReportMetric
                  label="Záró HUF"
                  value={`${formatHuf(closingReport.closingBalanceHuf)} Ft`}
                />
              </div>

              {closingReport.inventory && closingReport.inventory.length > 0 && (
                <div className="mt-3 overflow-x-auto">
                  <table className="min-w-full text-left text-xs">
                    <thead className="bg-gray-50 text-gray-500 dark:bg-gray-900/40 dark:text-gray-400">
                      <tr>
                        <th className="px-2 py-1 font-semibold">Valuta</th>
                        <th className="px-2 py-1 text-right font-semibold">Nyitó</th>
                        <th className="px-2 py-1 text-right font-semibold">Aktuális</th>
                        <th className="px-2 py-1 text-right font-semibold">Változás</th>
                      </tr>
                    </thead>
                    <tbody>
                      {closingReport.inventory.slice(0, 8).map((item) => (
                        <tr
                          key={item.currencyCode}
                          className="border-t border-gray-100 dark:border-gray-700"
                        >
                          <td className="px-2 py-1 font-semibold">{item.currencyCode}</td>
                          <td className="px-2 py-1 text-right">
                            {formatNumber(item.openingBalance)}
                          </td>
                          <td className="px-2 py-1 text-right">
                            {formatNumber(item.currentBalance)}
                          </td>
                          <td className="px-2 py-1 text-right">{formatNumber(item.dailyChange)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {/* FK-065 FR-3: ismeretlen wizard-státusz — semleges, perzisztens jelzés (nem toast) */}
      {statusPolicyError && !wizardId && (
        <div className="flex items-center justify-center gap-2 mb-2 p-3 rounded-lg border border-amber-300 bg-amber-50 text-amber-800 dark:border-amber-700 dark:bg-amber-900/30 dark:text-amber-200 text-sm">
          <AlertTriangle className="w-4 h-4 shrink-0" />
          <span>Állapot lekérdezése sikertelen, frissítsd az oldalt</span>
        </div>
      )}

      {/* FK-065 FR-3: beragadt zárási munkamenet — folytatás vagy újraindítás */}
      {staleWizard && !wizardId && !isRunning && (
        <div className="mb-2 p-3 rounded-lg border border-blue-300 bg-blue-50 text-blue-900 dark:border-blue-700 dark:bg-blue-900/30 dark:text-blue-100">
          {staleActionError && (
            <p className="text-sm text-center font-medium text-red-600 dark:text-red-400 mb-2">
              {staleActionError}
            </p>
          )}
          {staleWizard.action === 'resume' ? (
            <>
              <p className="text-sm text-center mb-2">
                Beragadt zárási munkamenet található a mai napra.
              </p>
              <div className="flex justify-center gap-2">
                <button
                  onClick={handleResumeStale}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-bold rounded-lg shadow transition-colors"
                >
                  Folytatás
                </button>
                <button
                  onClick={() => void handleRestartStale()}
                  className="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white text-sm font-bold rounded-lg shadow transition-colors"
                >
                  Megszakítás és újraindítás
                </button>
              </div>
            </>
          ) : (
            <>
              <p className="text-sm text-center mb-2">
                A korábbi zárási munkamenet lejárt (időtúllépés), nem folytatható.
              </p>
              <div className="flex justify-center">
                <button
                  onClick={() => void handleRestartStale()}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-bold rounded-lg shadow transition-colors"
                >
                  Új zárás indítása
                </button>
              </div>
            </>
          )}
        </div>
      )}

      {/* G10: ZÁRÁS TÍPUS VÁLASZTÓ (csak indítás előtt) */}
      {!wizardId && !isRunning && completedCount === 0 && !waitingForDenom && (
        <div className="flex items-center justify-center gap-2 mb-2">
          <label htmlFor="closing-type-select" className="text-sm font-medium">
            {t('closing.zarasTipusa')}
          </label>
          <select
            id="closing-type-select"
            value={closingType}
            onChange={(e) => setClosingType(e.target.value as ClosingWizard['closingType'])}
            className="p-2 border rounded"
          >
            <option value="DAILY">{t('closing.napiZaras')}</option>
            <option value="DECADE">{t('closing.dekadZaras')}</option>
            <option value="MONTHLY">{t('closing.haviZaras')}</option>
            <option value="POS">{t('closing.posZaras')}</option>
          </select>
        </div>
      )}

      {/* GOMBOK */}
      <div className="flex justify-center gap-2">
        {/* Bugbot Low fix: aktív stale-banner mellett a normál indítás rejtett —
            a felhasználó csak a Folytatás / Megszakítás és újraindítás úton léphet tovább. */}
        {!isRunning && completedCount === 0 && !waitingForDenom && !staleWizard && (
          <button
            onClick={runClosing}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-base font-bold rounded-lg shadow transition-colors"
          >
            {t('closing.ellenorzesInditasa')}
          </button>
        )}

        {failedCount > 0 && !isRunning && (
          <button
            onClick={handleCancel}
            className="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white text-base font-bold rounded-lg shadow transition-colors"
          >
            {t('closing.ujra')}
          </button>
        )}

        <button
          onClick={handleFinalize}
          disabled={!closingReadiness.ready || !canFinalize}
          className={`px-5 py-2 text-base font-bold rounded-lg shadow transition-all ${
            closingReadiness.ready && canFinalize
              ? 'bg-gradient-to-r from-green-600 to-emerald-700 hover:from-green-700 hover:to-emerald-800 text-white'
              : 'bg-gray-300 dark:bg-gray-700 text-gray-500 dark:text-gray-400 cursor-not-allowed'
          }`}
        >
          {closingReadiness.ready && canFinalize ? (
            <span className="flex items-center gap-2">
              <Check className="w-4 h-4" />
              {t('closing.rendbenNapzarasVegrehajtasa')}
            </span>
          ) : (
            'Minden lépés szükséges a napzáráshoz'
          )}
        </button>
      </div>

      {/* G3 (FR-13): eltérés-magyarázat modal — Electron-kompatibilis (nem window.prompt) */}
      {discrepancyPrompt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl p-6 w-full max-w-lg mx-4">
            <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-2">
              Eltérés-magyarázat szükséges
            </h3>
            <p className="text-sm text-gray-700 dark:text-gray-300 mb-4 whitespace-pre-wrap">
              {discrepancyPrompt.message}
            </p>
            <textarea
              autoFocus
              rows={3}
              value={discrepancyPrompt.explanation}
              onChange={(e) =>
                setDiscrepancyPrompt((p) => (p ? { ...p, explanation: e.target.value } : p))
              }
              placeholder="Adja meg az eltérés magyarázatát…"
              className="w-full border border-gray-300 dark:border-gray-600 rounded-lg p-2 text-sm bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100"
            />
            <div className="flex justify-end gap-2 mt-4">
              <button
                onClick={() => setDiscrepancyPrompt(null)}
                disabled={discrepancySubmitting}
                className="px-4 py-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 text-sm font-bold rounded-lg transition-colors"
              >
                Mégsem
              </button>
              <button
                onClick={handleDiscrepancySubmit}
                disabled={discrepancySubmitting || !discrepancyPrompt.explanation.trim()}
                className={`px-4 py-2 text-sm font-bold rounded-lg transition-colors ${
                  discrepancyPrompt.explanation.trim() && !discrepancySubmitting
                    ? 'bg-green-600 hover:bg-green-700 text-white'
                    : 'bg-gray-300 dark:bg-gray-700 text-gray-500 cursor-not-allowed'
                }`}
              >
                {discrepancySubmitting ? 'Küldés…' : 'Zárás magyarázattal'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function formatNumber(value: number | undefined | null): string {
  return (value ?? 0).toLocaleString('hu-HU')
}

/**
 * FK-073 (FR-2): blokkoló-e egy eltérés-sor? A backend által visszaadott,
 * tolerancia-alapú {@code status} mező dönt ({@code status !== 'OK'} blokkol).
 * A korábbi, kézzel bedrótozott HUF ≤1 kivétel megszűnt: a tolerancia egyetlen
 * forrása a backend ClosingTolerance.blocks() kiértékelése, így az eltérés-táblázat
 * és a véglegesítés-gomb mindig ugyanazt az eredményt adja (NFR-1).
 */
function isBlockingDifference(d: ClosingWizardDifference): boolean {
  return d.status !== 'OK'
}

/**
 * FK-063 FR-7 / PR #1483 review: közös összesen-formázó — több pénznemnél
 * pénznemenkénti bontás, egy pénznemnél a megszokott "… Ft".
 */
function formatDenominationTotals(
  sections: { currencyCode: string }[],
  totals: Record<string, number>,
  ftLabel: string,
  singleTotal: number,
): string {
  if (sections.length > 1) {
    return sections
      .map(
        ({ currencyCode }) =>
          `${(totals[currencyCode] ?? 0).toLocaleString('hu-HU')} ${currencyCode}`,
      )
      .join(' + ')
  }
  return `${singleTotal.toLocaleString('hu-HU')} ${ftLabel}`
}

function formatAmount(value: number | string | undefined | null): string {
  if (value === null || value === undefined) return '0'
  const parsed = typeof value === 'number' ? value : Number(String(value).replace(',', '.'))
  return Number.isFinite(parsed) ? parsed.toLocaleString('hu-HU') : String(value)
}

function formatHuf(value: number | undefined | null): string {
  return formatNumber(value)
}

function ReportMetric({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="min-w-0 rounded-md bg-gray-50 p-2 dark:bg-gray-900/40">
      <div className="text-[11px] leading-tight text-gray-500 dark:text-gray-400">{label}</div>
      <div className="mt-1 break-words text-sm font-semibold leading-tight text-gray-900 dark:text-gray-100">
        {value}
      </div>
    </div>
  )
}

function ValidationPill({ label, ok }: { label: string; ok: boolean }) {
  return (
    <div
      className={`flex min-h-9 items-center justify-between gap-2 rounded-md border px-2 py-1 ${
        ok
          ? 'border-green-200 bg-green-50 text-green-800 dark:border-green-900/60 dark:bg-green-950/30 dark:text-green-200'
          : 'border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-900/60 dark:bg-amber-950/30 dark:text-amber-200'
      }`}
    >
      <span className="min-w-0 truncate font-medium">{label}</span>
      {ok ? <Check className="h-3.5 w-3.5 shrink-0" /> : <X className="h-3.5 w-3.5 shrink-0" />}
    </div>
  )
}
