import { useState, useEffect, useCallback, useMemo } from 'react'
import { useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { Coins, Save, AlertCircle, CheckCircle2, XCircle, PlayCircle } from 'lucide-react'
import {
  denominationBalanceApi,
  DenominationBalanceDTO,
  denominationApi,
  currencyApi,
  Denomination,
  Currency,
  type DenominationBalanceCategory,
  type DenominationSelfCheck,
} from '../../services/api/index'
import { NumberInput } from '../../components/NumberInput'
import { toast } from '../../components/ui/toaster'
import { formatInteger, formatDecimal } from '../../utils/numberFormat'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { isAllowedFaceValue } from '../../utils/denominationRules'
import { resolveClosingDenominationExitRoute } from './closingDenominationMenu'
import i18n from '../../i18n'

/**
 * FK-078 — kozos, kategoria-tudatos becimletezo oldal.
 *
 * <p>A regi, onallo "Cimletezes" oldal (DenominationPage) helyett ez a felulet szolgalja ki
 * az "Esti zaras" (EVENING) es a "Kezelesi dij" (HANDLING_FEE) csempet. A penztaros napkozben,
 * elkotelezodes nelkul, korlatlanul menthet (FR-2); a mentes NEM indit zarasi munkamenetet.</p>
 *
 * <p>Legacy-parhuzam: a Delphi programban ugyanezt a napkozbeni, piszkozat-jellegu
 * becimletezest a CIMLETPISZKOZAT tabla szolgalta ki (KCIMLET/KESZEDIT/ATADVET modulok),
 * elkulonitve a veglegesitett CIMLETEK retegtol.</p>
 *
 * <p>FKH-039 FR-8/FR-9: önellenőrzés EVENING + HANDLING_FEE; explicit elvárt célösszeg.</p>
 *
 * <p>FK-079 orokseg (spec 9.4, kotelezo): minden cimlet-lista es minden mentes-payload
 * atmegy az isAllowedFaceValue szuresen — tort (1 alatti) nevertekhez semmilyen uton nem
 * kerulhet nem-nulla mennyiseg.</p>
 */

/** A category route-parameter ervenyes ertekei. */
const CATEGORY_TITLES: Record<DenominationBalanceCategory, string> = {
  EVENING: 'Esti zárás címletezése',
  HANDLING_FEE: 'Kezelési díj címletezése',
  VAT: 'ÁFA átadás-átvétel címletezése',
}

function parseCategory(raw: string | undefined): DenominationBalanceCategory {
  if (raw === 'HANDLING_FEE') return 'HANDLING_FEE'
  if (raw === 'VAT') return 'VAT'
  return 'EVENING'
}

export default function DenominationEntryPage() {
  const navigate = useNavigate()
  const { category: categoryParam } = useParams<{ category?: string }>()
  const category = parseCategory(categoryParam)
  // FKH-039 FR-8 / FKH-040: önellenőrzés EVENING, HANDLING_FEE és VAT kategórián.
  const selfCheckEnabled =
    category === 'EVENING' || category === 'HANDLING_FEE' || category === 'VAT'

  // FKH-036 FR-4: a hivo adja meg a visszateresi cimet (returnTo query-param).
  const [searchParams] = useSearchParams()
  /**
   * FKH-036 FR-4 + kieg. #2 FR-11: a hívó adja meg a visszatérési címet. Csak azonos-origójú,
   * relatív útvonal fogadható el (open-redirect védelem: a '//' protokol-relatív prefix és a
   * nem-'/' kezdet elutasítva); minden más esetben null.
   */
  const returnToRoute = useMemo(() => {
    const raw = searchParams.get('returnTo')
    if (raw && raw.startsWith('/') && !raw.startsWith('//')) return raw
    return null
  }, [searchParams])

  const worker = useAuthStore(
    (s: { worker: { id?: string | number; branchId: string; role?: string } | null }) => s.worker,
  )
  const hasCanonicalRole = useAuthStore(
    (s: { hasCanonicalRole?: (roles: string | string[]) => boolean }) => s.hasCanonicalRole,
  )
  /**
   * FKH-039: vault vs pénztár — explicit named feltétel a közös fájlban (FR-3).
   * Szerepkör-alapú, a ShipmentNewPage / ClosingWizard mintájára.
   */
  const isVaultContext = Boolean(hasCanonicalRole?.(['ertektar', 'foertektar']))

  const exitRoute = returnToRoute ?? resolveClosingDenominationExitRoute(isVaultContext)

  const selectedCashDeskId = worker?.branchId ?? ''

  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [selectedCurrencyId, setSelectedCurrencyId] = useState<number | null>(null)
  const [denominations, setDenominations] = useState<Denomination[]>([])
  const [editingQuantities, setEditingQuantities] = useState<Record<number, number>>({})
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [startingWizard, setStartingWizard] = useState(false)
  const [loadErrorMessage, setLoadErrorMessage] = useState<string | null>(null)
  const [selfCheck, setSelfCheck] = useState<DenominationSelfCheck[] | null>(null)

  const selectedCurrency = currencies.find((c) => c.id === selectedCurrencyId)

  /**
   * A megjelenitheto/beküldheto cimletsorok — FK-079 (FR-1/FR-2/FR-3) orokseg: a tort
   * nevertekű sor sem a tablazatba, sem az osszegzesbe, sem a payloadba nem kerul be.
   */
  const visibleDenominations = useMemo(
    () =>
      denominations
        .filter(
          (d) => d.currencyId === selectedCurrencyId && d.active && isAllowedFaceValue(d.faceValue),
        )
        .sort((a, b) => b.faceValue - a.faceValue),
    [denominations, selectedCurrencyId],
  )

  const calculatedTotal = useMemo(
    () =>
      visibleDenominations.reduce(
        (sum, d) => sum + d.faceValue * (editingQuantities[d.id] ?? 0),
        0,
      ),
    [visibleDenominations, editingQuantities],
  )

  /** FKH-042 FR-2 (D3): a kiválasztott valuta sora a már lekért self-check tömbből. */
  const selectedSelfCheckRow = useMemo(() => {
    if (!selfCheck || selectedCurrencyId === null) return null
    return (
      selfCheck.find((r) => Number(r.currencyId) === selectedCurrencyId) ??
      selfCheck.find((r) => r.currencyCode === selectedCurrency?.code) ??
      null
    )
  }, [selfCheck, selectedCurrencyId, selectedCurrency?.code])

  /** FR-5: kizárólag a DTO expectedBalance — nincs új számítási logika. */
  const expectedBalance = selectedSelfCheckRow
    ? Number(selectedSelfCheckRow.expectedBalance)
    : null
  /** FR-2 (D2): pozitív = még hiányzik a becímletezésből; a DTO.difference ELLENTÉTES előjelű és állott. */
  const liveDifference = expectedBalance === null ? null : expectedBalance - calculatedTotal

  const loadCurrencies = useCallback(async () => {
    try {
      const data = await currencyApi.getActive()
      setCurrencies(data)
      if (data.length > 0) {
        setSelectedCurrencyId((prev) => prev ?? data[0]?.id ?? null)
      }
    } catch (error) {
      logger.error('DenominationEntryPage', 'Valuták betöltése sikertelen:', error)
      setLoadErrorMessage(`A valuták nem tölthetők be. Részlet: ${getErrorMessage(error)}`)
    }
  }, [])

  const loadAll = useCallback(async () => {
    if (!selectedCashDeskId || !selectedCurrencyId) return
    setLoading(true)
    setLoadErrorMessage(null)

    // FK-077 (FR-3) minta: allSettled — egy elutasitott hivas ne uritse ki csendben az oldalt.
    const results = await Promise.allSettled([
      denominationApi.getByCurrencyId(selectedCurrencyId),
      denominationBalanceApi.getCashDeskDenominationsByCurrency(
        selectedCashDeskId,
        String(selectedCurrencyId),
        category,
      ),
    ])

    const denoms = results[0].status === 'fulfilled' ? (results[0].value as Denomination[]) : []
    const balances =
      results[1].status === 'fulfilled' ? (results[1].value as DenominationBalanceDTO[]) : []

    setDenominations(denoms)

    // Egyetlen, determinisztikus state-iras: minden cimlet 0, felulirva a mentettekkel.
    const quantities: Record<number, number> = {}
    denoms.forEach((d) => {
      quantities[d.id] = 0
    })
    balances.forEach((balance) => {
      quantities[Number(balance.denominationId)] = balance.quantity
    })
    setEditingQuantities(quantities)

    const failures = results.filter((r): r is PromiseRejectedResult => r.status === 'rejected')
    if (failures.length > 0) {
      failures.forEach((f) =>
        logger.error('DenominationEntryPage', 'Címletezés részleges betöltési hiba:', f.reason),
      )
      setLoadErrorMessage(
        `A címletezés adatainak egy része nem tölthető be (${failures.length} hívás sikertelen). ` +
          `Részlet: ${getErrorMessage(failures[0]?.reason)}`,
      )
    }
    setLoading(false)
  }, [selectedCashDeskId, selectedCurrencyId, category])

  /**
   * FKH-042 FR-1: az elvárt készlet a MEGLÉVŐ self-check DTO-ból, mountkor — Mentés nélkül.
   * FKH-038 örökség: a `category` paramétert MINDIG átadjuk (kategória-keveredés tilos).
   */
  const loadSelfCheck = useCallback(async () => {
    if (!selfCheckEnabled || !selectedCashDeskId) return
    try {
      setSelfCheck(await denominationBalanceApi.selfCheck(selectedCashDeskId, category))
    } catch (error) {
      // FKH-042 FR-1 nem blokkoló: a fejléc üres marad, a táblázat (loadAll) érintetlen.
      logger.warn('DenominationEntryPage', 'Elvárt készlet (önellenőrzés) nem elérhető:', error)
      setSelfCheck(null)
    }
  }, [selfCheckEnabled, selectedCashDeskId, category])

  useEffect(() => {
    void loadCurrencies()
  }, [loadCurrencies])

  useEffect(() => {
    void loadSelfCheck()
  }, [loadSelfCheck])

  useEffect(() => {
    if (selectedCurrencyId && selectedCashDeskId) {
      void loadAll()
    }
  }, [selectedCurrencyId, selectedCashDeskId, loadAll])

  const handleQuantityChange = (denominationId: number, quantityStr: string) => {
    // Darabszam = egesz szam (a backend DTO Integer) — tort darab nem ertelmezheto.
    const quantity = Math.max(0, parseInt(quantityStr.replace(/\s/g, ''), 10) || 0)
    setEditingQuantities((prev) => ({ ...prev, [denominationId]: quantity }))
  }

  /**
   * FR-2/FR-3/FR-4 + FKH-039 FR-8: szabad, ismetelt mentes a helyes kategoriaval, majd —
   * EVENING és HANDLING_FEE eseten — azonnali onellenorzes. A mentes SOHA nem blokkolodik.
   */
  const persist = async (): Promise<boolean> => {
    if (!selectedCashDeskId) {
      toast.warning('Hiányzó adat', 'Nincs kiválasztott pénztár!')
      return false
    }
    setSaving(true)
    try {
      // FK-079 (FR-2) orokseg: a payload tort nevertekű sort NEM tartalmazhat.
      const allowedIds = new Set(visibleDenominations.map((d) => d.id))
      const updates = Object.entries(editingQuantities)
        .filter(([id]) => allowedIds.has(Number(id)))
        .map(([denominationId, quantity]) => ({ denominationId, quantity }))

      await denominationBalanceApi.setDenominationQuantities(selectedCashDeskId, updates, category)
      toast.success('Címletezés sikeresen mentve!')

      if (selfCheckEnabled) {
        try {
          const result = await denominationBalanceApi.selfCheck(selectedCashDeskId, category)
          setSelfCheck(result)
        } catch (error) {
          // FR-4 nem blokkolo: az onellenorzes hibaja a sikeres mentest nem ronthatja el.
          logger.warn('DenominationEntryPage', 'Önellenőrzés nem elérhető:', error)
          setSelfCheck(null)
          toast.warning(
            'Önellenőrzés nem elérhető',
            'A mentés sikeres volt, az egyezés-vizsgálat viszont nem futott le.',
          )
        }
      }
      return true
    } catch (error) {
      logger.error('DenominationEntryPage', 'Mentés sikertelen:', error)
      toast.error('Hiba történt a mentés során', getErrorMessage(error))
      return false
    } finally {
      setSaving(false)
    }
  }

  /**
   * FR-2: "Mentés és visszalépés" — csak pénztári kontextusban (FKH-039 FR-3).
   * Vault-ban a gomb el van rejtve; a Kilépés ment+navigál.
   */
  const handleSaveAndReturn = async () => {
    const ok = await persist()
    if (ok) navigate('/closing/denominations-menu')
  }

  /** FR-4: mentes egyezes-jelzessel, az oldal elhagyasa nelkul (korlatlanul ismetelheto). */
  const handleSave = async () => {
    await persist()
  }

  /**
   * FKH-039 FR-1/FR-4/FR-5: vault-ban mentés után navigál; pénztárban változatlanul
   * mentés nélkül (FR-3 regresszióvédelem).
   */
  const handleExit = async () => {
    if (isVaultContext) {
      const ok = await persist()
      if (ok) navigate(exitRoute)
      return
    }
    navigate(exitRoute)
  }

  /**
   * FR-5: "Napi zárás végrehajtása" — ez, es csak ez inditja a tenyleges zaras-varazslot.
   * A varazslo belso logikaja valtozatlan (NFR-3): a /closing/wizard oldal sajat
   * "runClosing" folyamata fut le, ugyanugy, mint ma.
   *
   * FKH-036 kieg. #2 FR-11: vault-kontextusban (van valid returnTo) ez a gomb a Kilepes
   * gombbal AZONOS célpontra visz — csak visszanavigal a hivo oldalra, zaras-kuldes nelkul.
   * FR-12: returnTo nelkul valtozatlanul a varazslo.
   */
  const handleStartClosing = () => {
    if (returnToRoute) {
      navigate(returnToRoute)
      return
    }
    setStartingWizard(true)
    navigate('/closing/wizard')
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <Coins className="text-blue-600" size={20} />
        <div>
          <h1
            className="text-lg font-bold text-secondary-900"
            data-testid="denomination-entry-title"
          >
            {CATEGORY_TITLES[category]}
          </h1>
          <p className="text-sm text-secondary-500 mt-0.5">
            {i18n.t('literals.napkozben-korlatlanul-mentheto-a-mentes')}
          </p>
        </div>
      </div>

      {loadErrorMessage && (
        <div
          role="alert"
          data-testid="denomination-entry-load-error"
          className="flex items-start gap-2 rounded-lg border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-800"
        >
          <AlertCircle size={16} className="mt-0.5 shrink-0" />
          <span>{loadErrorMessage}</span>
        </div>
      )}

      {!selectedCashDeskId && (
        <div className="form-panel bg-yellow-50 border-yellow-200 flex items-center gap-2">
          <AlertCircle className="text-yellow-600" size={18} />
          <span className="text-sm text-yellow-800">
            {i18n.t('literals.penztar-kivalasztasa-szukseges-a-cimlete')}
          </span>
        </div>
      )}

      <div className="form-panel space-y-3">
        <div className="flex items-center gap-2">
          <label htmlFor="denomination-entry-currency" className="text-sm font-medium">
            {i18n.t('literals.valuta')}
          </label>
          <select
            id="denomination-entry-currency"
            data-testid="denomination-entry-currency"
            className="p-2 border rounded"
            value={selectedCurrencyId ?? ''}
            onChange={(e) => setSelectedCurrencyId(Number(e.target.value) || null)}
          >
            {currencies.map((c) => (
              <option key={c.id} value={c.id}>
                {c.code}
              </option>
            ))}
          </select>
        </div>

        {/* FKH-042 FR-1/FR-2: elvárt készlet + élő eltérés a táblázat FELETT, Mentés nélkül. */}
        {selfCheckEnabled && (
          <div
            data-testid="denomination-entry-expected-panel"
            className="flex flex-wrap items-center gap-4 rounded-lg border border-blue-200 bg-blue-50 px-3 py-2 text-sm"
          >
            <span className="text-secondary-700">
              {i18n.t('literals.elvart-keszlet')}{' '}
              <span
                className="font-mono font-bold text-blue-700"
                data-testid="denomination-entry-expected"
              >
                {expectedBalance === null
                  ? '—'
                  : `${formatDecimal(expectedBalance, 2, 2)} ${selectedCurrency?.code ?? ''}`}
              </span>
            </span>
            <span className="text-secondary-700">
              {i18n.t('literals.elo-elteres')}{' '}
              <span
                className={`font-mono font-bold ${liveDifference === 0 ? 'text-green-700' : 'text-red-700'}`}
                data-testid="denomination-entry-diff"
              >
                {liveDifference === null
                  ? '—'
                  : `${formatDecimal(liveDifference, 2, 2)} ${selectedCurrency?.code ?? ''}`}
              </span>
            </span>
          </div>
        )}

        {loading ? (
          <p className="text-sm text-secondary-500">{i18n.t('literals.betoltes-3')}</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50 text-left">
                  <th className="p-2">{i18n.t('literals.cimlet')}</th>
                  <th className="p-2">{i18n.t('literals.tipus')}</th>
                  <th className="p-2">{i18n.t('literals.darab')}</th>
                  <th className="p-2 text-right">{i18n.t('literals.osszeg')}</th>
                </tr>
              </thead>
              <tbody>
                {visibleDenominations.map((denomination) => {
                  const quantity = editingQuantities[denomination.id] || 0
                  return (
                    <tr key={denomination.id}>
                      <td className="p-2">
                        <span className="font-mono font-bold text-sm">
                          {formatInteger(denomination.faceValue)} {selectedCurrency?.code}
                        </span>
                      </td>
                      <td className="p-2">
                        <span className="text-[10px] bg-gray-100 px-1.5 py-0.5 rounded">
                          {denomination.denominationType === 'BANKNOTE' ? 'Bankjegy' : 'Érme'}
                        </span>
                      </td>
                      <td className="p-2">
                        <NumberInput
                          value={quantity > 0 ? String(quantity) : ''}
                          onChange={(val) => handleQuantityChange(denomination.id, val)}
                          className="form-input w-24 text-center"
                          placeholder="0"
                          data-testid={`denomination-entry-qty-${denomination.id}`}
                          allowDecimals={false}
                          allowNegative={false}
                          min={0}
                          step="1"
                        />
                      </td>
                      <td className="p-2 text-right">
                        <span className="font-mono font-semibold text-green-600">
                          {formatDecimal(denomination.faceValue * quantity, 2, 2)}
                        </span>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
              <tfoot className="bg-gray-50 font-bold">
                <tr>
                  <td colSpan={3} className="text-right pr-4 p-2">
                    {i18n.t('literals.osszesen')}
                  </td>
                  <td className="text-right p-2">
                    <span
                      className="font-mono text-base text-blue-600"
                      data-testid="denomination-entry-total"
                    >
                      {formatDecimal(calculatedTotal, 2, 2)} {selectedCurrency?.code}
                    </span>
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        )}
      </div>

      {/* FKH-039 FR-8/FR-9/FR-10: önellenőrzés EVENING + HANDLING_FEE; explicit elvárt összeg. */}
      {selfCheckEnabled && selfCheck && selfCheck.length > 0 && (
        <div className="form-panel space-y-2" data-testid="denomination-entry-selfcheck">
          <h2 className="text-sm font-bold text-secondary-900">
            {i18n.t('literals.onellenorzes')}
          </h2>
          <p className="text-xs text-secondary-500">
            {i18n.t('literals.tajekoztato-jellegu-az-elteres-a-mentest')}
          </p>
          <ul className="space-y-1">
            {selfCheck.map((row) => (
              <li
                key={row.currencyCode}
                data-testid={`denomination-entry-selfcheck-${row.currencyCode}`}
                className={`flex flex-wrap items-center gap-2 rounded px-2 py-1 text-sm ${
                  row.matches ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'
                }`}
              >
                {row.matches ? (
                  <CheckCircle2 size={16} className="shrink-0" />
                ) : (
                  <XCircle size={16} className="shrink-0" />
                )}
                <span className="font-mono font-bold">{row.currencyCode}</span>
                <span>{row.matches ? 'Egyezik' : 'Nem egyezik'}</span>
                <span className="font-mono text-xs">
                  {i18n.t('literals.becimletezett')}
                  {formatDecimal(Number(row.denominatedAmount), 2, 2)}
                  {i18n.t('literals.elvart')} {formatDecimal(Number(row.expectedBalance), 2, 2)}
                  {!row.matches ? `, eltérés: ${formatDecimal(Number(row.difference), 2, 2)}` : ''}
                  {i18n.t('literals.lit-2')}
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="flex flex-wrap items-center gap-2">
        <button
          type="button"
          onClick={() => void handleSave()}
          disabled={saving || !selectedCashDeskId}
          data-testid="denomination-entry-save"
          className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white text-sm font-bold rounded-lg shadow transition-colors flex items-center gap-2"
        >
          <Save size={16} />
          {i18n.t('literals.mentes-2')}
        </button>
        {/* FKH-039 FR-2/FR-3: Mentés és visszalépés csak pénztári kontextusban. */}
        {!isVaultContext && (
          <button
            type="button"
            onClick={() => void handleSaveAndReturn()}
            disabled={saving || !selectedCashDeskId}
            data-testid="denomination-entry-save-and-return"
            className="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white text-sm font-bold rounded-lg shadow transition-colors flex items-center gap-2"
          >
            <Save size={16} />
            {i18n.t('literals.mentes-es-visszalepes')}
          </button>
        )}
        <button
          type="button"
          onClick={handleStartClosing}
          disabled={startingWizard}
          data-testid="denomination-entry-start-closing"
          className="px-4 py-2 bg-amber-600 hover:bg-amber-700 disabled:opacity-50 text-white text-sm font-bold rounded-lg shadow transition-colors flex items-center gap-2"
        >
          <PlayCircle size={16} />
          {i18n.t('literals.napi-zaras-vegrehajtasa')}
        </button>
        <button
          type="button"
          onClick={() => void handleExit()}
          disabled={saving}
          data-testid="denomination-entry-exit"
          className="px-4 py-2 bg-gray-600 hover:bg-gray-700 disabled:opacity-50 text-white text-sm font-bold rounded-lg shadow transition-colors"
        >
          {i18n.t('literals.kilepes')}
        </button>
      </div>
    </div>
  )
}
