import { useEffect, useState, useMemo, type FormEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { AlertCircle, ArrowLeft, Package, Send } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { branchApi, currencyApi, exchangeRateApi, shipmentRequestApi, type BranchInfo, type Currency } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

type FormState = {
  fromBranchId: string
  toBranchId: string
  deliveryDate: string
  currencyId: string
  amount: string
  notes: string
}

export default function ShipmentNewPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  /**
   * Bali Henriett (2026-05-27) kérés A.: ÁTADÁS és ÁTVÉTEL teljesen elkülönülve.
   *  - `outbound` = Értéktárból a Pénztárnak (a B+C PR lezárja a Kérő iroda mezőt
   *    a saját értéktárra).
   *  - `inbound`  = Pénztárból az Értéktárba (a Cél iroda zárul a saját értéktárra).
   * Visszafelé-kompatibilis: paraméter nélkül a régi univerzális űrlap fut.
   */
  const direction = useMemo<'outbound' | 'inbound' | null>(() => {
    const d = searchParams.get('direction')
    return d === 'outbound' || d === 'inbound' ? d : null
  }, [searchParams])
  const directionTitle = direction === 'outbound'
    ? 'Új készpénz ÁTADÁS (Értéktárból a Pénztárnak)'
    : direction === 'inbound'
    ? 'Új készpénz ÁTVÉTEL (Pénztárból az Értéktárba)'
    : t('shipments.ujSzallitmanyigeny')
  const worker = useAuthStore((state) => state.worker)
  /**
   * Bali Henriett kérés B.: a saját értéktár mindig a tranzakció egyik szereplője.
   *  - outbound (ÁTADÁS): Kérő iroda = saját értéktár → fromBranchId előtöltve, locked.
   *  - inbound  (ÁTVÉTEL): Cél iroda = saját értéktár → toBranchId előtöltve, locked.
   *  - null (régi univerzális): semmi nincs zárolva.
   */
  const ownBranchId = worker?.branchId ?? ''
  const [form, setForm] = useState<FormState>({
    fromBranchId: direction === 'outbound' || direction === null ? ownBranchId : '',
    toBranchId: direction === 'inbound' ? ownBranchId : '',
    deliveryDate: '',
    currencyId: '',
    amount: '',
    notes: '',
  })
  const [branches, setBranches] = useState<BranchInfo[]>([])
  // FK-013 (Bali Henriett / Kasza Helga 2026-05-28): az egységes értéktári átadás-átvétel
  // dropdown 3 csoportban (territorial / peerVaults / fixedCounterparties). Csak akkor
  // töltődik fel, ha a user értéktáros (vault-context). Egyéb esetben üres marad, és a
  // sima `branches` listából renderelünk (a régi viselkedés).
  const [vaultCounterparties, setVaultCounterparties] = useState<{
    territorialCashiers: BranchInfo[]
    peerVaults: BranchInfo[]
    fixedCounterparties: BranchInfo[]
  } | null>(null)
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  /**
   * D követelmény (Bali Henriett 2026-05-27): a valuta-választás után a rendszer
   * AUTOMATIKUSAN beemeli az aktuális elszámoló árfolyamot (officialRate). Read-only
   * megjelenítés a felhasználónak; a forintosított értéket élőben számoljuk.
   */
  const [appliedRate, setAppliedRate] = useState<number | null>(null)
  const [rateLoading, setRateLoading] = useState(false)
  const disabled = loading || saving

  useEffect(() => {
    // Worker-betöltés után a saját értéktár-id pótlása az irány által megszabott oldalon.
    if (!ownBranchId) return
    setForm((current) => {
      if (direction === 'outbound' && !current.fromBranchId) return { ...current, fromBranchId: ownBranchId }
      if (direction === 'inbound' && !current.toBranchId) return { ...current, toBranchId: ownBranchId }
      if (direction === null && !current.fromBranchId) return { ...current, fromBranchId: ownBranchId } // legacy default
      return current
    })
  }, [ownBranchId, direction])

  // FK-013 self-review P1-1: csak a TERÜLETI értéktáros (ROLE_ERTEKTAR / canonical 'ertektar')
  // kapja a 3-csoportos dropdown-t. A FŐÉRTÉKTÁR (nemzeti scope) és a cég-szintű ADMIN/UGYVEZETO
  // user-ek a régi listMyTerritory listát kapják (a Főértéktárnak null vault-scope → minden
  // aktív branch → docx szerint nem ezt akarjuk a területi átadás-átvétel dropdownjában).
  // FONTOS: a `hasCanonicalRole(['ertektar'])` ADMIN-ra is TRUE-t ad (Zustand admin-bypass) —
  // ezt elfogadjuk, mert ADMIN ritkán használja ezt a flow-t és debug-célból OK.
  const roles = useAuthStore((s) => s.roles)
  const activeRole = useAuthStore((s) => s.activeRole)
  const hasCanonicalRole = useAuthStore((s) => s.hasCanonicalRole)
  const isVaultUser = useMemo(
    () => hasCanonicalRole(['ertektar']),
    [hasCanonicalRole, roles, activeRole],
  )

  // FK-013 self-review P0-2: ha az isVaultUser flicker-el (true → false), a vaultCounterparties
  // state stale-en marad → a UI a régi 3-csoportos dropdown-t mutatja inkonzisztens módon.
  // Reset, ha a user már nem értéktáros.
  useEffect(() => {
    if (!isVaultUser) setVaultCounterparties(null)
  }, [isVaultUser])

  useEffect(() => {
    let active = true
    // FK-005/B4: a Kérő/Cél iroda legördülő CSAK a saját terület pénztárait mutatja, ha a
    // felhasználó értéktárosként operál (vault-authority → region-scope); egyébként minden
    // aktív. A backend AccessScopeService dönt (a vault-authority precedál a base-role felett).
    //
    // FK-013 (Bali Henriett 2026-05-28): értéktáros user esetén KIBŐVÍTETT lista — 3 csoport
    // (saját terület pénztárai + 7 másik értéktár + 10 fix banki/speciális partner) az új
    // /branches/vault-counterparties endpoint-ról. Pénztárosnak marad a régi listMyTerritory.
    const branchSource = isVaultUser
      ? branchApi.listVaultCounterparties().then((cp) => {
          if (active) setVaultCounterparties(cp)
          return [...cp.territorialCashiers, ...cp.peerVaults, ...cp.fixedCounterparties]
        })
      : branchApi.listMyTerritory()

    Promise.all([branchSource, currencyApi.getActive()])
      .then(([branchList, currencyList]) => {
        if (!active) return
        setBranches(branchList.filter((branch) => branch.isActive !== false))
        setCurrencies(currencyList.filter((currency) => currency.active !== false))
      })
      .catch((err) => {
        if (!active) return
        logger.error('ShipmentNewPage', 'Referenciaadat betoltesi hiba:', err)
        setError(getErrorMessage(err))
      })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [isVaultUser])

  const patch = (values: Partial<FormState>) => setForm((current) => ({ ...current, ...values }))

  /**
   * D: a valuta-választás után lekérjük az aktuális elszámoló árfolyamot (officialRate).
   * Codex/Copilot P1 follow-up: a backend KÖTELEZŐEN megköveteli az érvényes rate-et —
   * ha az ExchangeRateService.getCurrentRate hiányzó rate-et / lejárt rate-et /
   * null officialRate-et talál, ValidationException-t dob és a create elutasítva.
   * A frontend itt csak megjeleníti a rate-et a felhasználónak (read-only); a
   * payload-ot NEM küldjük át (server-side authoritative).
   */
  useEffect(() => {
    if (!form.currencyId) { setAppliedRate(null); return }
    let active = true
    setRateLoading(true)
    exchangeRateApi.getByCurrencyId(Number(form.currencyId))
      .then((rate) => {
        if (!active) return
        // D + Codex P2: KIZÁRÓLAG officialRate (elszámoló ár / J). A backend is csak
        // officialRate-et ment — baseBuyRate fallback megtévesztő lenne (a UI rate-et
        // mutatna, de a perzisztens appliedRate NULL maradna).
        const official = rate.officialRate ?? null
        setAppliedRate(official != null ? Number(official) : null)
      })
      .catch(() => { if (active) setAppliedRate(null) })
      .finally(() => { if (active) setRateLoading(false) })
    return () => { active = false }
  }, [form.currencyId])

  // D: a forintosított érték élő számítása (5-Ft-os kerekítés a kijelzéshez; a
  // hivatalos HUF érték a backend HungarianRounding-jából jön a save-kor).
  const hufValue: number | null = useMemo(() => {
    const amt = Number(form.amount.replace(',', '.'))
    if (!Number.isFinite(amt) || amt <= 0 || appliedRate == null) return null
    return Math.round((amt * appliedRate) / 5) * 5
  }, [form.amount, appliedRate])

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError(null)
    const amount = Number(form.amount.replace(',', '.'))
    if (!form.fromBranchId || !form.toBranchId || !form.currencyId || !Number.isFinite(amount) || amount <= 0) {
      setError('Kérő iroda, cél iroda, valuta és pozitív összeg megadása kötelező.')
      return
    }
    if (form.fromBranchId === form.toBranchId) {
      setError('A kérő és a cél iroda nem lehet ugyanaz.')
      return
    }
    setSaving(true)
    try {
      const created = await shipmentRequestApi.create({
        fromBranchId: form.fromBranchId,
        toBranchId: form.toBranchId,
        deliveryDate: form.deliveryDate || undefined,
        notes: form.notes,
        // D követelmény (Codex P1): a backend autoritatív a server-side aktuális rate-tel —
        // a kliens csak display-célból mutatja a rate-et + hufValue-t, NEM küldi a payloadban.
        items: [{
          currencyId: form.currencyId,
          requestedAmount: amount,
        }],
      })
      if (!created.id) throw new Error('A szerver nem adott szállítmány azonosítót.')
      await shipmentRequestApi.submit(created.id)
      navigate('/shipments', { replace: true })
    } catch (err) {
      logger.error('ShipmentNewPage', 'Szallitmanyigeny letrehozasi hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="flex items-center gap-2 text-xl font-bold text-gray-800">
          <Package />{directionTitle}
        </h1>
        <button onClick={() => navigate('/shipments')} className="form-button flex items-center gap-2">
          <ArrowLeft size={16} />{t('shipments.visszaAListahoz')}
        </button>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700"><AlertCircle size={16} /><span>{error}</span></div>
        </div>
      )}

      <form onSubmit={submit} className="form-panel space-y-4">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <label className="block">
            <span className="form-label">
              Kérő iroda{direction === 'outbound' && <span className="ml-1 text-xs text-gray-500">(automatikus — Ön értéktára)</span>}
            </span>
            <select
              className={`form-input ${direction === 'outbound' ? 'bg-gray-100 cursor-not-allowed' : ''}`}
              value={form.fromBranchId}
              disabled={disabled || direction === 'outbound'}
              onChange={(e) => patch({ fromBranchId: e.target.value })}
            >
              <option value="">Válasszon irodát</option>
              {vaultCounterparties ? (
                // FK-013: 3-csoportos optgroup értéktáros user esetén
                <>
                  {vaultCounterparties.territorialCashiers.length > 0 && (
                    <optgroup label="Saját terület pénztárai">
                      {vaultCounterparties.territorialCashiers
                        .filter((b) => b.isActive !== false)
                        .map((b) => <option key={b.id} value={b.id}>{b.code} - {b.name}</option>)}
                    </optgroup>
                  )}
                  {vaultCounterparties.peerVaults.length > 0 && (
                    <optgroup label="Társ értéktárak">
                      {vaultCounterparties.peerVaults
                        .filter((b) => b.isActive !== false)
                        .map((b) => <option key={b.id} value={b.id}>{b.code} - {b.name}</option>)}
                    </optgroup>
                  )}
                  {vaultCounterparties.fixedCounterparties.length > 0 && (
                    <optgroup label="Banki és speciális partnerek">
                      {vaultCounterparties.fixedCounterparties
                        .filter((b) => b.isActive !== false)
                        .map((b) => <option key={b.id} value={b.id}>{b.code} - {b.name}</option>)}
                    </optgroup>
                  )}
                </>
              ) : (
                branches.map((branch) => <option key={branch.id} value={branch.id}>{branch.code} - {branch.name}</option>)
              )}
            </select>
          </label>
          <label className="block">
            <span className="form-label">
              Cél iroda{direction === 'inbound' && <span className="ml-1 text-xs text-gray-500">(automatikus — Ön értéktára)</span>}
            </span>
            <select
              className={`form-input ${direction === 'inbound' ? 'bg-gray-100 cursor-not-allowed' : ''}`}
              value={form.toBranchId}
              disabled={disabled || direction === 'inbound'}
              onChange={(e) => patch({ toBranchId: e.target.value })}
            >
              <option value="">Válasszon cél irodát</option>
              {vaultCounterparties ? (
                // FK-013: 3-csoportos optgroup értéktáros user esetén
                <>
                  {vaultCounterparties.territorialCashiers.length > 0 && (
                    <optgroup label="Saját terület pénztárai">
                      {vaultCounterparties.territorialCashiers
                        .filter((b) => b.isActive !== false)
                        .map((b) => <option key={b.id} value={b.id}>{b.code} - {b.name}</option>)}
                    </optgroup>
                  )}
                  {vaultCounterparties.peerVaults.length > 0 && (
                    <optgroup label="Társ értéktárak">
                      {vaultCounterparties.peerVaults
                        .filter((b) => b.isActive !== false)
                        .map((b) => <option key={b.id} value={b.id}>{b.code} - {b.name}</option>)}
                    </optgroup>
                  )}
                  {vaultCounterparties.fixedCounterparties.length > 0 && (
                    <optgroup label="Banki és speciális partnerek">
                      {vaultCounterparties.fixedCounterparties
                        .filter((b) => b.isActive !== false)
                        .map((b) => <option key={b.id} value={b.id}>{b.code} - {b.name}</option>)}
                    </optgroup>
                  )}
                </>
              ) : (
                branches.map((branch) => <option key={branch.id} value={branch.id}>{branch.code} - {branch.name}</option>)
              )}
            </select>
          </label>
          <label className="block">
            <span className="form-label">Kért kézbesítési dátum</span>
            <input type="date" className="form-input" value={form.deliveryDate} disabled={saving} onChange={(e) => patch({ deliveryDate: e.target.value })} />
          </label>
          <label className="block">
            <span className="form-label">Valuta</span>
            <select className="form-input" value={form.currencyId} disabled={disabled} onChange={(e) => patch({ currencyId: e.target.value })}>
              <option value="">Válasszon valutát</option>
              {currencies.map((currency) => <option key={currency.id} value={currency.id}>{currency.code} - {currency.name}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="form-label">Összeg</span>
            <input type="number" min="0.01" step="0.01" className="form-input" value={form.amount} disabled={saving} onChange={(e) => patch({ amount: e.target.value })} />
          </label>
          {/* D követelmény (Bali Henriett): aktuális elszámoló árfolyam + forintosított érték
              AUTOMATIKUSAN, read-only — a felhasználó NE írja kézzel. */}
          <label className="block">
            <span className="form-label">
              Alkalmazott elszámoló árfolyam
              <span className="ml-1 text-xs text-gray-500">(automatikus — aktuális rendszer-árfolyam)</span>
            </span>
            <input
              type="text"
              className="form-input bg-gray-100 cursor-not-allowed"
              value={rateLoading ? 'Betöltés…' : appliedRate != null ? appliedRate.toLocaleString('hu-HU', { maximumFractionDigits: 6 }) : '—'}
              disabled
              readOnly
            />
          </label>
          <label className="block">
            <span className="form-label">
              Forintosított érték
              <span className="ml-1 text-xs text-gray-500">(automatikus — 5 Ft-ra kerekítve)</span>
            </span>
            <input
              type="text"
              className="form-input bg-gray-100 cursor-not-allowed"
              value={hufValue != null ? hufValue.toLocaleString('hu-HU') + ' Ft' : '—'}
              disabled
              readOnly
            />
          </label>
          <label className="block md:col-span-2">
            <span className="form-label">Megjegyzés</span>
            <textarea className="form-input min-h-24" value={form.notes} disabled={saving} onChange={(e) => patch({ notes: e.target.value })} />
          </label>
        </div>
        <div className="flex justify-end">
          <button type="submit" className="form-button-primary flex items-center gap-2" disabled={disabled}>
            <Send size={16} />{saving ? 'Beküldés...' : 'Igény beküldése'}
          </button>
        </div>
      </form>
    </div>
  )
}
