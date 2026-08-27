import { useState, useEffect, useCallback } from 'react'
import { X, Plus, Check, Ban, RefreshCw, Search } from 'lucide-react'
import { toast } from '../../../components/ui/toaster'
import { logger } from '../../../utils/logger'
import { currencyApi } from '../../../services/api/exchange-rates'
import { getErrorMessage } from '../../../utils/errorHandling'
import type { Currency } from '../../../services/api/exchange-rates'
import CurrencyDenominationImagesPanel from './CurrencyDenominationImagesPanel'
import i18n from '../../../i18n'

/**
 * V238 (2026-05-19) — Currency Manager modal.
 *
 * <p>Kosa Zoltan user-direktiva: az Arfolyamkeszitobe legyen UI ahonnan
 * a foertekitaros uj valutat hozzaadhat, illetve meglevot inaktivalhat /
 * reaktivalhat. <b>NEM TOROL</b> az adatbazisbol — csak `is_active` flag valt
 * (Pmt./NAV 8-eves megorzes).</p>
 *
 * <p>Backend endpoint-ok:
 * <ul>
 *   <li>GET /api/v1/currencies/all — osszes (aktiv+inaktiv) valuta</li>
 *   <li>GET /api/v1/currencies/{id} — kijelolt valuta stabil ID szerinti reszlete</li>
 *   <li>GET /api/v1/currencies/code/{code} — kód szerinti backend ellenorzes</li>
 *   <li>POST /api/v1/currencies — uj valuta hozzaadasa (admin/manager only)</li>
 *   <li>PATCH /api/v1/currencies/{id}/active — aktivalas/deaktivalas</li>
 * </ul></p>
 *
 * <p>Minden modositast a backend a `currency_audit_log` tablaba ir (V238
 * Flyway migration). 8 evig megorizve.</p>
 */
interface CurrencyManagerModalProps {
  isOpen: boolean
  onClose: () => void
  onCurrencyChanged?: () => void // ertesites a parent-nek hogy ujra-toltse a listat
}

/**
 * FK04 (FR-8): az "Új valuta" form alapértelmezett megjelenítési sorrendje a
 * jelenlegi legnagyobb displayOrder + 1 (a korábbi fix 99 a V318 UNIQUE constraint
 * mellett a második felvételnél 409-et okozna). Üres lista → 1.
 */
export function computeNextDisplayOrder(currencies: Array<{ displayOrder?: number }>): number {
  if (currencies.length === 0) return 1
  return Math.max(...currencies.map((c) => c.displayOrder ?? 0)) + 1
}

function sortCurrencies(currencies: Currency[]): Currency[] {
  return [...currencies].sort((a, b) => {
    if (a.active !== b.active) return a.active ? -1 : 1
    return (a.displayOrder ?? 0) - (b.displayOrder ?? 0)
  })
}

export default function CurrencyManagerModal({
  isOpen,
  onClose,
  onCurrencyChanged,
}: CurrencyManagerModalProps) {
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [allCurrencies, setAllCurrencies] = useState<Currency[]>([])
  const [loading, setLoading] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCurrencyDetail, setSelectedCurrencyDetail] = useState<Currency | null>(null)
  const [selectedCurrencyCodeCheck, setSelectedCurrencyCodeCheck] = useState<Currency | null>(null)
  const [showAddForm, setShowAddForm] = useState(false)

  // Add-form state
  const [newCode, setNewCode] = useState('')
  const [newName, setNewName] = useState('')
  const [newSymbol, setNewSymbol] = useState('')
  const [newDecimals, setNewDecimals] = useState<number>(2)
  // FK04 (FR-8): a tényleges defaultot a form megnyitásakor számoljuk (max displayOrder + 1).
  const [newDisplayOrder, setNewDisplayOrder] = useState<number>(1)
  const [submitting, setSubmitting] = useState(false)

  // Aktivál/inaktivál megerősítés — Electron-kompatibilis (NEM window.prompt, ami
  // Electron rendererben nem támogatott és null-t ad → a kérés sosem ment el).
  const [pendingToggle, setPendingToggle] = useState<{
    currency: Currency
    active: boolean
  } | null>(null)
  const [toggleNote, setToggleNote] = useState('')
  const [togglingActive, setTogglingActive] = useState(false)

  const refresh = useCallback(async () => {
    setLoading(true)
    try {
      const list = await currencyApi.getAll()
      // Stable sort: active first, then by displayOrder
      const sorted = sortCurrencies(list)
      setCurrencies(sorted)
      setAllCurrencies(sorted)
      setSelectedCurrencyDetail(null)
      setSelectedCurrencyCodeCheck(null)
    } catch (err) {
      logger.error('CurrencyManagerModal', 'list failed', err)
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  const handleBackendSearch = useCallback(async () => {
    const query = searchTerm.trim()
    if (!query) {
      await refresh()
      return
    }

    setLoading(true)
    try {
      const results = await currencyApi.search(query)
      setCurrencies(sortCurrencies(results))
      setSelectedCurrencyDetail(null)
      setSelectedCurrencyCodeCheck(null)
    } catch (err) {
      logger.error('CurrencyManagerModal', 'search failed', err)
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [refresh, searchTerm])

  const handleOpenDetail = useCallback(async (currency: Currency) => {
    setLoading(true)
    try {
      const [detailById, detailByCode] = await Promise.all([
        currencyApi.getById(currency.id),
        currencyApi.getByCode(currency.code),
      ])
      setSelectedCurrencyDetail(detailById)
      setSelectedCurrencyCodeCheck(detailByCode)
    } catch (err) {
      logger.error('CurrencyManagerModal', 'detail lookup failed', err)
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (isOpen) {
      void refresh()
    } else {
      // Copilot #761: a megerősítő-panel state-jét töröljük záráskor, hogy
      // újranyitáskor ne maradjon stale pending-toggle.
      setPendingToggle(null)
      setToggleNote('')
      setTogglingActive(false)
      setSelectedCurrencyDetail(null)
      setSelectedCurrencyCodeCheck(null)
    }
  }, [isOpen, refresh])

  // Gomb-klikk: megerősítő-panel megnyitása (NEM azonnali API-hívás).
  const handleSetActive = useCallback((currency: Currency, active: boolean) => {
    setToggleNote('')
    setPendingToggle({ currency, active })
  }, [])

  // Megerősítés után: tényleges PATCH /currencies/{id}/active.
  const confirmToggle = useCallback(async () => {
    if (!pendingToggle || togglingActive) return // Copilot #761: dupla-kattintás védelem
    const { currency, active } = pendingToggle
    const action = active ? 'aktiválni' : 'inaktiválni'
    setTogglingActive(true)
    try {
      await currencyApi.setActive(currency.id, active, toggleNote.trim() || undefined)
      toast.success('Sikeres', `${currency.code} ${active ? 'aktiválva' : 'inaktiválva'}`)
      setPendingToggle(null)
      setToggleNote('')
      await refresh()
      onCurrencyChanged?.()
    } catch (err) {
      logger.error('CurrencyManagerModal', `setActive ${action} failed`, err)
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setTogglingActive(false)
    }
  }, [pendingToggle, togglingActive, toggleNote, refresh, onCurrencyChanged])

  const handleAdd = useCallback(async () => {
    const code = newCode.trim().toUpperCase()
    const name = newName.trim()
    if (!code || !name) {
      toast.warning('Hiányzó mező', 'Kód és Név kötelező')
      return
    }
    if (!/^[A-Z0-9]{3,10}$/.test(code)) {
      toast.warning('Érvénytelen kód', '3-10 alfanumerikus karakter (csupa nagybetű)')
      return
    }
    setSubmitting(true)
    try {
      await currencyApi.create({
        code,
        name,
        symbol: newSymbol.trim() || undefined,
        decimalPlaces: newDecimals,
        displayOrder: newDisplayOrder,
      })
      toast.success('Sikeres', `Új valuta ${code} hozzáadva`)
      setNewCode('')
      setNewName('')
      setNewSymbol('')
      setNewDecimals(2)
      setShowAddForm(false)
      await refresh()
      onCurrencyChanged?.()
    } catch (err) {
      logger.error('CurrencyManagerModal', 'create failed', err)
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setSubmitting(false)
    }
  }, [newCode, newName, newSymbol, newDecimals, newDisplayOrder, refresh, onCurrencyChanged])

  if (!isOpen) return null

  const filtered = currencies.filter((c) => {
    if (!searchTerm.trim()) return true
    const q = searchTerm.toLowerCase()
    return c.code.toLowerCase().includes(q) || (c.name?.toLowerCase().includes(q) ?? false)
  })

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow-xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col">
        <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-lg font-semibold">{i18n.t('literals.valutakezelo-v238')}</h2>
          <button
            onClick={onClose}
            className="p-1 hover:bg-gray-100 dark:hover:bg-gray-800 rounded"
          >
            <X size={20} />
          </button>
        </div>

        <div className="p-4 space-y-3 overflow-y-auto">
          <div className="flex items-center gap-2">
            <div className="flex-1 relative">
              <Search size={16} className="absolute left-2.5 top-2.5 text-gray-400" />
              <input
                type="text"
                placeholder="Keresés kód vagy név alapján..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') void handleBackendSearch()
                }}
                className="form-input w-full pl-8"
                data-testid="currency-manager-search"
              />
            </div>
            <button
              type="button"
              onClick={() => void handleBackendSearch()}
              disabled={loading}
              className="form-button flex items-center gap-1 disabled:opacity-50"
              data-testid="currency-manager-search-submit"
            >
              <Search size={16} />
              {i18n.t('literals.kereses-2')}
            </button>
            <button
              type="button"
              onClick={() => {
                // FK04 (FR-8): a form megnyitásakor a default sorrend = max(displayOrder) + 1.
                if (!showAddForm) setNewDisplayOrder(computeNextDisplayOrder(allCurrencies))
                setShowAddForm((s) => !s)
              }}
              // Verif P2: a lista betöltéséig tiltva — üres currencies-ből a default 1 lenne,
              // ami a V317 után garantáltan foglalt (EUR=1) → fals 409 a felhasználónak.
              disabled={loading}
              className="form-button-primary flex items-center gap-1 disabled:opacity-50"
              data-testid="currency-manager-toggle-add"
            >
              <Plus size={16} />
              {i18n.t('literals.uj-valuta')}
            </button>
            <button
              type="button"
              onClick={() => void refresh()}
              disabled={loading}
              className="form-button flex items-center gap-1 disabled:opacity-50"
            >
              <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
              {i18n.t('literals.frissites')}
            </button>
          </div>

          {selectedCurrencyDetail && (
            <div
              className="rounded-md border border-blue-200 bg-blue-50/70 p-3 text-sm"
              data-testid="currency-manager-detail"
            >
              <div className="font-semibold">
                {selectedCurrencyDetail.code}
                {i18n.t('literals.lit-17')}
                {selectedCurrencyDetail.name}
              </div>
              <div className="mt-1 grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs">
                <span>
                  {i18n.t('literals.szimbolum')}
                  {selectedCurrencyDetail.symbol || '-'}
                </span>
                <span>
                  {i18n.t('literals.tizedes')}
                  {selectedCurrencyDetail.decimals}
                </span>
                <span>
                  {i18n.t('literals.sorrend-2')}
                  {selectedCurrencyDetail.displayOrder ?? '-'}
                </span>
              </div>
              {selectedCurrencyCodeCheck && (
                <div
                  className="mt-2 text-xs text-blue-900"
                  data-testid="currency-manager-code-check"
                >
                  {i18n.t('literals.kod-ellenorzes')}
                  {selectedCurrencyCodeCheck.code}
                  {i18n.t('literals.lit-49')}
                  {selectedCurrencyCodeCheck.id}
                </div>
              )}
            </div>
          )}

          {showAddForm && (
            <div className="rounded-md border border-blue-200 dark:border-blue-800 bg-blue-50/60 dark:bg-blue-950/20 p-3 space-y-2">
              <div className="text-sm font-semibold">{i18n.t('literals.uj-valuta-hozzaadasa')}</div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-xs block mb-0.5">
                    {i18n.t('literals.kod-3-10-karakter-iso-elony')}
                  </label>
                  <input
                    type="text"
                    value={newCode}
                    onChange={(e) => setNewCode(e.target.value.toUpperCase())}
                    className="form-input w-full font-mono"
                    maxLength={10}
                    placeholder="pl. XYZ"
                    data-testid="new-currency-code"
                  />
                </div>
                <div>
                  <label className="text-xs block mb-0.5">{i18n.t('literals.nev-2')}</label>
                  <input
                    type="text"
                    value={newName}
                    onChange={(e) => setNewName(e.target.value)}
                    className="form-input w-full"
                    placeholder="pl. Példa Valuta"
                    data-testid="new-currency-name"
                  />
                </div>
                <div>
                  <label className="text-xs block mb-0.5">
                    {i18n.t('literals.szimbolum-opcionalis')}
                  </label>
                  <input
                    type="text"
                    value={newSymbol}
                    onChange={(e) => setNewSymbol(e.target.value)}
                    className="form-input w-full"
                    maxLength={10}
                  />
                </div>
                <div>
                  <label className="text-xs block mb-0.5">
                    {i18n.t('literals.tizedes-jegyek-default-2')}
                  </label>
                  <input
                    type="number"
                    value={newDecimals}
                    onChange={(e) => setNewDecimals(parseInt(e.target.value) || 2)}
                    className="form-input w-full"
                    min="0"
                    max="6"
                  />
                </div>
                <div className="col-span-2">
                  <label className="text-xs block mb-0.5">
                    {i18n.t('literals.megjelenitesi-sorrend-kisebb-elol')}
                  </label>
                  <input
                    type="number"
                    value={newDisplayOrder}
                    onChange={(e) => {
                      // Copilot PR #1097: explicit NaN-check — a `|| fallback` a 0-t is elnyelte
                      // (falsy), pedig a min="0" megengedi. NaN (kiürített mező) → max+1 default.
                      const v = parseInt(e.target.value, 10)
                      setNewDisplayOrder(Number.isNaN(v) ? computeNextDisplayOrder(currencies) : v)
                    }}
                    className="form-input w-full"
                    min="0"
                    data-testid="new-currency-display-order"
                  />
                </div>
              </div>
              <div className="flex gap-2 justify-end">
                <button type="button" onClick={() => setShowAddForm(false)} className="form-button">
                  {i18n.t('literals.megse')}
                </button>
                <button
                  type="button"
                  onClick={() => void handleAdd()}
                  disabled={submitting}
                  className="form-button-primary disabled:opacity-50"
                  data-testid="new-currency-submit"
                >
                  {submitting ? 'Mentés...' : 'Hozzáadás'}
                </button>
              </div>
            </div>
          )}

          {pendingToggle && (
            <div
              className="rounded-md border border-amber-300 dark:border-amber-700 bg-amber-50/70 dark:bg-amber-950/20 p-3 space-y-2"
              data-testid="currency-toggle-confirm"
            >
              <div className="text-sm font-semibold">
                {pendingToggle.active ? 'Aktiválás' : 'Inaktiválás'}
                {i18n.t('literals.megerositese')} {pendingToggle.currency.code}
                {i18n.t('literals.lit')}
                {pendingToggle.currency.name}
                {i18n.t('literals.lit-2')}
              </div>
              <p className="text-xs text-gray-600 dark:text-gray-400">
                {pendingToggle.active
                  ? 'A valuta újra megjelenik a Főlapon.'
                  : 'Az adatbázisban MARAD (Pmt./NAV 8-éves megőrzés), csak nem jelenik meg a Főlapon.'}
              </p>
              <div>
                <label className="text-xs block mb-0.5">
                  {i18n.t('literals.indoklas-opcionalis-audit-log-ba-kerul')}
                </label>
                <input
                  type="text"
                  value={toggleNote}
                  onChange={(e) => setToggleNote(e.target.value)}
                  className="form-input w-full"
                  placeholder="pl. nincs rá kereslet"
                  data-testid="currency-toggle-note"
                  autoFocus
                />
              </div>
              <div className="flex gap-2 justify-end">
                <button
                  type="button"
                  onClick={() => {
                    setPendingToggle(null)
                    setToggleNote('')
                  }}
                  disabled={togglingActive}
                  className="form-button disabled:opacity-50"
                >
                  {i18n.t('literals.megse')}
                </button>
                <button
                  type="button"
                  onClick={() => void confirmToggle()}
                  disabled={togglingActive}
                  className="form-button-primary disabled:opacity-50"
                  data-testid="currency-toggle-confirm-btn"
                >
                  {togglingActive
                    ? 'Mentés...'
                    : pendingToggle.active
                      ? 'Aktiválás'
                      : 'Inaktiválás'}
                </button>
              </div>
            </div>
          )}

          <div className="border border-gray-200 dark:border-gray-700 rounded-md overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="bg-gray-50 dark:bg-gray-800">
                <tr>
                  <th className="text-left p-2">{i18n.t('literals.kod-3')}</th>
                  <th className="text-left p-2">{i18n.t('literals.nev')}</th>
                  <th className="text-center p-2">{i18n.t('literals.szimbolum-2')}</th>
                  <th className="text-center p-2">{i18n.t('literals.tizedes-2')}</th>
                  <th className="text-center p-2">{i18n.t('literals.sorrend')}</th>
                  <th className="text-center p-2">{i18n.t('literals.allapot')}</th>
                  <th className="text-right p-2">{i18n.t('literals.muveletek')}</th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={7} className="text-center text-gray-500 p-4">
                      {loading ? 'Betöltés...' : 'Nincs találat'}
                    </td>
                  </tr>
                )}
                {filtered.map((c) => (
                  <tr
                    key={c.id}
                    className={`border-t border-gray-100 dark:border-gray-800 ${c.active ? '' : 'opacity-60'}`}
                  >
                    <td className="p-2 font-mono font-semibold">{c.code}</td>
                    <td className="p-2">{c.name}</td>
                    <td className="p-2 text-center">{c.symbol || '–'}</td>
                    <td className="p-2 text-center">{c.decimals}</td>
                    <td className="p-2 text-center">{c.displayOrder}</td>
                    <td className="p-2 text-center">
                      {c.active ? (
                        <span className="inline-flex items-center gap-1 text-green-700 dark:text-green-400">
                          <Check size={14} />
                          {i18n.t('literals.aktiv-3')}
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-gray-500">
                          <Ban size={14} />
                          {i18n.t('literals.inaktiv-2')}
                        </span>
                      )}
                    </td>
                    <td className="p-2 text-right">
                      <button
                        type="button"
                        onClick={() => void handleOpenDetail(c)}
                        className="mr-2 text-xs px-2 py-1 rounded bg-blue-100 hover:bg-blue-200 text-blue-900 dark:bg-blue-900 dark:text-blue-100"
                        data-testid={`detail-${c.code}`}
                      >
                        {i18n.t('literals.reszlet')}
                      </button>
                      {c.active ? (
                        <button
                          type="button"
                          onClick={() => void handleSetActive(c, false)}
                          className="text-xs px-2 py-1 rounded bg-amber-100 hover:bg-amber-200 text-amber-900 dark:bg-amber-900 dark:text-amber-100"
                          data-testid={`deactivate-${c.code}`}
                        >
                          {i18n.t('literals.inaktival')}
                        </button>
                      ) : (
                        <button
                          type="button"
                          onClick={() => void handleSetActive(c, true)}
                          className="text-xs px-2 py-1 rounded bg-green-100 hover:bg-green-200 text-green-900 dark:bg-green-900 dark:text-green-100"
                          data-testid={`activate-${c.code}`}
                        >
                          {i18n.t('literals.aktival')}
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="mt-2" data-testid="currency-manager-denomination-panel">
            <CurrencyDenominationImagesPanel currency={selectedCurrencyDetail} />
          </div>

          <p className="text-xs text-gray-500 dark:text-gray-400">
            <strong>{i18n.t('literals.megjegyzes-2')}</strong>
            {i18n.t('literals.az-inaktivalas-nem-torli-az-adatbazisbol')}
          </p>
        </div>
      </div>
    </div>
  )
}
