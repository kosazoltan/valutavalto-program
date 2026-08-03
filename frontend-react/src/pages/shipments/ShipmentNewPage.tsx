import { useEffect, useState, useMemo, type FormEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { AlertCircle, ArrowLeft, Package, Plus, Send, Trash2 } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import {
  branchApi,
  currencyApi,
  exchangeRateApi,
  shipmentRequestApi,
  type BranchInfo,
  type Currency,
  type ShipmentRequest,
} from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { FRACTIONAL_FACE_VALUE_ERROR, isAllowedFaceValue } from '../../utils/denominationRules'
import { validateCarrierSeal } from '../transfers/transferRules'
import { ReceiptPreviewModal } from '../../components/electron'
import { isElectron } from '../../utils/electron'
import { toast } from '../../components/ui/toaster'
import { getCompanyType } from '../../utils/localQueue'
import { localIsoDate } from '../../utils/dateFormat'
import type { PrintReceiptData } from '../../types/receipt'

type FormState = {
  fromBranchId: string
  toBranchId: string
  deliveryDate: string
  currencyId: string
  amount: string
  notes: string
  carrierName: string
  sealNumber: string
}

type DenominationFormLine = {
  quantity: string
  faceValue: string
}

export default function ShipmentNewPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  /**
   * Bali Henriett (2026-05-27) kérés A.: ÁTADÁS és ÁTVÉTEL teljesen elkülönülve.
   *  - `outbound` = Értéktárból a Pénztárnak (a B+C PR lezárja az Átadó mezőt
   *    a saját értéktárra).
   *  - `inbound`  = Pénztárból az Értéktárba (az Átvevő mező zárul a saját értéktárra).
   * Visszafelé-kompatibilis: paraméter nélkül a régi univerzális űrlap fut.
   */
  const direction = useMemo<'outbound' | 'inbound' | null>(() => {
    const d = searchParams.get('direction')
    return d === 'outbound' || d === 'inbound' ? d : null
  }, [searchParams])
  const directionTitle =
    direction === 'outbound'
      ? 'Új készpénz ÁTADÁS (Értéktárból a Pénztárnak)'
      : direction === 'inbound'
        ? 'Új készpénz ÁTVÉTEL (Pénztárból az Értéktárba)'
        : t('shipments.ujSzallitmanyigeny')
  const worker = useAuthStore((state) => state.worker)
  /**
   * Bali Henriett kérés B.: a saját értéktár mindig a tranzakció egyik szereplője.
   *  - outbound (ÁTADÁS): Átadó = saját értéktár → fromBranchId előtöltve, locked.
   *  - inbound  (ÁTVÉTEL): Átvevő = saját értéktár → toBranchId előtöltve, locked.
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
    carrierName: '',
    sealNumber: '',
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
  // FR-1..5 (átadás-nyomtatás): sikeres rögzítés után „Bizonylat Előnézet" modal — a meglévő
  // ReceiptPreviewModal `transfer` típussal. A modal bezárásakor navigálunk a listára. A nyomtatás
  // KIZÁRÓLAG itt, frissen rögzített tételnél érhető el (a listanézet nem nyit modalt).
  const [printReceiptData, setPrintReceiptData] = useState<PrintReceiptData | null>(null)
  const [showReceiptModal, setShowReceiptModal] = useState(false)
  /**
   * D követelmény (Bali Henriett 2026-05-27): a valuta-választás után a rendszer
   * AUTOMATIKUSAN beemeli az aktuális elszámoló árfolyamot (officialRate). Read-only
   * megjelenítés a felhasználónak; a forintosított értéket élőben számoljuk.
   */
  const [appliedRate, setAppliedRate] = useState<number | null>(null)
  const [rateLoading, setRateLoading] = useState(false)
  const [denominations, setDenominations] = useState<DenominationFormLine[]>([])
  const [calculatedHandlingFee, setCalculatedHandlingFee] = useState<number | null>(null)
  const disabled = loading || saving
  const selectedCurrency = useMemo(
    () => currencies.find((currency) => String(currency.id) === form.currencyId),
    [currencies, form.currencyId],
  )
  const ownBranchOption = useMemo<BranchInfo | null>(() => {
    if (!ownBranchId || !worker?.branchName) return null
    return {
      id: ownBranchId,
      code: worker.branchCode || '',
      name: worker.branchName,
      isActive: true,
      isVault: true,
    }
  }, [ownBranchId, worker?.branchCode, worker?.branchName])

  useEffect(() => {
    // Worker-betöltés után a saját értéktár-id pótlása az irány által megszabott oldalon.
    if (!ownBranchId) return
    setForm((current) => {
      if (direction === 'outbound' && !current.fromBranchId)
        return { ...current, fromBranchId: ownBranchId }
      if (direction === 'inbound' && !current.toBranchId)
        return { ...current, toBranchId: ownBranchId }
      if (direction === null && !current.fromBranchId)
        return { ...current, fromBranchId: ownBranchId } // legacy default
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
  // FK-013 PÉNZTÁRI OLDAL (2026-05-28): a pénztáros (CASHIER/PENZTAR canonical role)
  // a 3-elemes szűkített listát kapja (saját értéktár + TH + 1-es főpénztár).
  // A docx: "A pénztári programban az átadás-átvétel menü (F4) marad a jelenlegi
  // működés szerint – ott csak az alábbiak szerepelnek".
  const isCashierUser = useMemo(
    () => hasCanonicalRole(['penztar']) && !hasCanonicalRole(['ertektar', 'foertektar']),
    [hasCanonicalRole, roles, activeRole],
  )
  // FKH-018: a kezelési költség tételtípust a backend RBAC-jával azonos értéktáros
  // szerepkörök rögzíthetik. A hasCanonicalRole ADMIN-bypass-a szándékos paritás.
  const [itemType, setItemType] = useState<'currency' | 'handlingFee'>('currency')
  const canRecordHandlingFee = useMemo(
    () => hasCanonicalRole(['ertektar', 'foertektar']),
    [hasCanonicalRole, roles, activeRole],
  )
  const isHandlingFee = itemType === 'handlingFee' && canRecordHandlingFee

  // FK-013 self-review P0-2: ha az isVaultUser flicker-el (true → false), a vaultCounterparties
  // state stale-en marad → a UI a régi 3-csoportos dropdown-t mutatja inkonzisztens módon.
  // Reset, ha a user már nem értéktáros.
  useEffect(() => {
    if (!isVaultUser) setVaultCounterparties(null)
  }, [isVaultUser])

  useEffect(() => {
    let active = true
    // FK-005/B4: az Átadó/Átvevő legördülő CSAK a saját terület pénztárait mutatja, ha a
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
      : isCashierUser
        ? // FK-013 pénztári oldal: szűkített 3-elemes lista (saját értéktár + TH + FOP1)
          branchApi.listCashierShipmentTargets()
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
      .finally(() => {
        if (active) setLoading(false)
      })
    return () => {
      active = false
    }
  }, [isVaultUser, isCashierUser])

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
    if (!form.currencyId) {
      setAppliedRate(null)
      return
    }
    if (selectedCurrency?.code?.toUpperCase() === 'HUF') {
      setRateLoading(false)
      setAppliedRate(1)
      return
    }
    let active = true
    setRateLoading(true)
    exchangeRateApi
      .getByCurrencyId(Number(form.currencyId))
      .then((rate) => {
        if (!active) return
        // D + Codex P2: KIZÁRÓLAG officialRate (elszámoló ár / J). A backend is csak
        // officialRate-et ment — baseBuyRate fallback megtévesztő lenne (a UI rate-et
        // mutatna, de a perzisztens appliedRate NULL maradna).
        const official = rate.officialRate ?? null
        setAppliedRate(official != null ? Number(official) : null)
      })
      .catch(() => {
        if (active) setAppliedRate(null)
      })
      .finally(() => {
        if (active) setRateLoading(false)
      })
    return () => {
      active = false
    }
  }, [form.currencyId, selectedCurrency?.code])

  // D: a forintosított érték élő számítása (5-Ft-os kerekítés a kijelzéshez; a
  // hivatalos HUF érték a backend HungarianRounding-jából jön a save-kor).
  const hufValue: number | null = useMemo(() => {
    const amt = Number(form.amount.replace(',', '.'))
    if (!Number.isFinite(amt) || amt <= 0 || appliedRate == null) return null
    return Math.round((amt * appliedRate) / 5) * 5
  }, [form.amount, appliedRate])
  const roundedHandlingFeeAmount: number | null = useMemo(() => {
    const amount = Number(form.amount.replace(',', '.'))
    if (!Number.isFinite(amount) || amount <= 0) return null
    return Math.round(amount / 5) * 5
  }, [form.amount])

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError(null)
    const amount = Number(form.amount.replace(',', '.'))
    if (!form.fromBranchId || !form.toBranchId || !Number.isFinite(amount) || amount <= 0) {
      setError(
        isHandlingFee
          ? 'Átadó, átvevő és pozitív összeg megadása kötelező.'
          : 'Átadó, átvevő, valuta és pozitív összeg megadása kötelező.',
      )
      return
    }
    if (!isHandlingFee && !form.currencyId) {
      setError('Átadó, átvevő, valuta és pozitív összeg megadása kötelező.')
      return
    }
    if (form.fromBranchId === form.toBranchId) {
      setError('Az átadó és az átvevő nem lehet ugyanaz.')
      return
    }
    // FK02 (FR-1..3, NFR-1,2): szállító + plombaszám kötelező + hossz/formátum — közös validátor
    // (a TransferPage/MovementManagerrel és a backend Bean Validationnel egyező egyetlen forrás).
    const carrierSealError = validateCarrierSeal(form.carrierName, form.sealNumber)
    if (carrierSealError) {
      setError(carrierSealError)
      return
    }
    if (isHandlingFee && amount % 5 !== 0) {
      setError(t('shipments.kezelesiKoltsegOsszegHiba'))
      return
    }
    const normalizedDenominations = denominations
      .map((line) => {
        const quantity = Number(line.quantity)
        const faceValue = Number(line.faceValue.replace(',', '.'))
        return {
          quantity,
          faceValue,
          currencyCode: isHandlingFee ? 'HUF' : (selectedCurrency?.code ?? ''),
          lineTotal: quantity * faceValue,
        }
      })
      .filter((line) => line.quantity > 0 || line.faceValue > 0)
    if (
      normalizedDenominations.some(
        (line) =>
          !Number.isInteger(line.quantity) ||
          line.quantity <= 0 ||
          !Number.isFinite(line.faceValue) ||
          line.faceValue <= 0,
      )
    ) {
      setError(
        'A címletezésben minden sorhoz pozitív egész darabszám és pozitív névleges érték szükséges.',
      )
      return
    }
    // FK-072 (FR-5, kliens-oldal): 1 alatti (tört) névleges érték nem küldhető be —
    // közös szabály az összes címletező felülettel (NFR-2).
    if (normalizedDenominations.some((line) => !isAllowedFaceValue(line.faceValue))) {
      setError(FRACTIONAL_FACE_VALUE_ERROR)
      return
    }
    const denominationTotal = normalizedDenominations.reduce((sum, line) => sum + line.lineTotal, 0)
    if (normalizedDenominations.length > 0 && Math.abs(denominationTotal - amount) > 0.0001) {
      setError('A címletezés összegének egyeznie kell az átadás-átvétel összegével.')
      return
    }
    const buildAndShowReceipt = (
      created: ShipmentRequest,
      submitted: ShipmentRequest,
      options: {
        currencyCode: string
        rate?: number
        foreignAmount: number
        roundedHufAmount?: number
        transferNote?: string
      },
    ) => {
      const receiptShipment = { ...created, ...submitted }
      // Elsődleges forrás: backend DTO from/to branch kód+név. Csak régi/hiányos válasznál
      // esünk vissza a már betöltött listára (a cél lehet virtuális partner is).
      const allBranches: BranchInfo[] = [
        ...branches,
        ...(vaultCounterparties
          ? [
              ...vaultCounterparties.territorialCashiers,
              ...vaultCounterparties.peerVaults,
              ...vaultCounterparties.fixedCounterparties,
            ]
          : []),
      ]
      const branchLabelFromBackend = (code?: string, name?: string): string => {
        if (code && name) return `${code} - ${name}`
        return name || code || ''
      }
      const branchLabel = (id: string, fallbackName?: string, fallbackCode?: string): string => {
        const serverLabel = branchLabelFromBackend(fallbackCode, fallbackName)
        if (serverLabel) return serverLabel
        const branch = allBranches.find((candidate) => candidate.id === id)
        return branch ? `${branch.code} - ${branch.name}` : ''
      }
      const now = new Date()
      setPrintReceiptData({
        type: 'transfer',
        companyType: getCompanyType(worker),
        receiptNumber: receiptShipment.requestNumber || receiptShipment.id,
        branchCode: branchLabel(
          form.fromBranchId,
          receiptShipment.fromBranchName || receiptShipment.requestingBranchName,
          receiptShipment.fromBranchCode,
        ),
        cashierName: receiptShipment.requestedByWorkerName || worker?.fullName || '',
        date: receiptShipment.requestedAt?.slice(0, 10) || localIsoDate(),
        time: now.toTimeString().slice(0, 8),
        currencyCode: options.currencyCode,
        rate: options.rate,
        foreignAmount: options.foreignAmount,
        roundedHufAmount: options.roundedHufAmount,
        deliveryDate: receiptShipment.requestedDeliveryDate || form.deliveryDate || undefined,
        transferTarget: branchLabel(
          form.toBranchId,
          receiptShipment.toBranchName || receiptShipment.targetBranchName,
          receiptShipment.toBranchCode,
        ),
        vaultAddress: receiptShipment.vaultAddress,
        vaultPhone: receiptShipment.vaultPhone,
        transferDocType: direction === 'inbound' ? 'receipt' : 'handover',
        transferNote: options.transferNote ?? (receiptShipment.notes || form.notes || undefined),
        carrierName: receiptShipment.carrierName || form.carrierName.trim(),
        sealNumber: receiptShipment.sealNumber || form.sealNumber.trim(),
        denominations: normalizedDenominations.length > 0 ? normalizedDenominations : undefined,
      })
      setShowReceiptModal(true)
    }

    setSaving(true)
    try {
      if (isHandlingFee) {
        const { shipment: created, handlingFee } = await shipmentRequestApi.createHandlingFee({
          fromBranchId: form.fromBranchId,
          toBranchId: form.toBranchId,
          hufAmount: amount,
          deliveryDate: form.deliveryDate || undefined,
          notes: form.notes,
          carrierName: form.carrierName.trim(),
          sealNumber: form.sealNumber.trim(),
        })
        if (!created.id) throw new Error('A szerver nem adott szállítmány azonosítót.')
        const submitted = await shipmentRequestApi.submit(created.id)
        setCalculatedHandlingFee(handlingFee.calculatedFee)
        const handlingFeeNote = `${t('shipments.kezelesiKoltsegAtvetel')} — ${t('shipments.szamitottKezelesiDij')}: ${handlingFee.calculatedFee.toLocaleString('hu-HU')} Ft${form.notes ? `\n${form.notes}` : ''}`
        buildAndShowReceipt(created, submitted, {
          currencyCode: 'HUF',
          rate: 1,
          foreignAmount: amount,
          roundedHufAmount: amount,
          transferNote: handlingFeeNote,
        })
        return
      }

      const created = await shipmentRequestApi.create({
        fromBranchId: form.fromBranchId,
        toBranchId: form.toBranchId,
        deliveryDate: form.deliveryDate || undefined,
        notes: form.notes,
        carrierName: form.carrierName.trim(),
        sealNumber: form.sealNumber.trim(),
        // D követelmény (Codex P1): a backend autoritatív a server-side aktuális rate-tel —
        // a kliens csak display-célból mutatja a rate-et + hufValue-t, NEM küldi a payloadban.
        items: [{ currencyId: form.currencyId, requestedAmount: amount }],
      })
      if (!created.id) throw new Error('A szerver nem adott szállítmány azonosítót.')
      const submitted = await shipmentRequestApi.submit(created.id)
      buildAndShowReceipt(created, submitted, {
        currencyCode: selectedCurrency?.code ?? '',
        rate: appliedRate ?? undefined,
        foreignAmount: amount,
        roundedHufAmount: hufValue ?? undefined,
      })
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
          <Package />
          {directionTitle}
        </h1>
        <button
          onClick={() => navigate('/shipments')}
          className="form-button flex items-center gap-2"
        >
          <ArrowLeft size={16} />
          {t('shipments.visszaAListahoz')}
        </button>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      <form onSubmit={submit} noValidate className="form-panel space-y-4">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <label className="block">
            <span className="form-label">
              Átadó
              {direction === 'outbound' && (
                <span className="ml-1 text-xs text-gray-500">(automatikus — Ön értéktára)</span>
              )}
            </span>
            <select
              className={`form-input ${direction === 'outbound' ? 'bg-gray-100 cursor-not-allowed' : ''}`}
              value={form.fromBranchId}
              disabled={disabled || direction === 'outbound'}
              onChange={(e) => patch({ fromBranchId: e.target.value })}
            >
              <option value="">Válasszon átadót</option>
              {vaultCounterparties ? (
                // FK-013: 3-csoportos optgroup értéktáros user esetén
                // Audit follow-up: defenzív `?? []` — ha a backend Jackson kihagy egy null
                // mezőt (Include.NON_NULL), a frontend ne crash-eljen `undefined.length` miatt.
                <>
                  {ownBranchOption && form.fromBranchId === ownBranchId && (
                    <optgroup label="Saját értéktár">
                      <option value={ownBranchOption.id}>
                        {ownBranchOption.code
                          ? `${ownBranchOption.code} - ${ownBranchOption.name}`
                          : ownBranchOption.name}
                      </option>
                    </optgroup>
                  )}
                  {(vaultCounterparties.territorialCashiers ?? []).length > 0 && (
                    <optgroup label="Helyi Pénztárak">
                      {(vaultCounterparties.territorialCashiers ?? [])
                        .filter((b) => b.isActive !== false)
                        .map((b) => (
                          <option key={b.id} value={b.id}>
                            {b.code} - {b.name}
                          </option>
                        ))}
                    </optgroup>
                  )}
                  {(vaultCounterparties.peerVaults ?? []).length > 0 && (
                    <optgroup label="Társ értéktárak">
                      {(vaultCounterparties.peerVaults ?? [])
                        .filter((b) => b.isActive !== false)
                        .map((b) => (
                          <option key={b.id} value={b.id}>
                            {b.code} - {b.name}
                          </option>
                        ))}
                    </optgroup>
                  )}
                  {(vaultCounterparties.fixedCounterparties ?? []).length > 0 && (
                    <optgroup label="Banki és speciális partnerek">
                      {(vaultCounterparties.fixedCounterparties ?? [])
                        .filter((b) => b.isActive !== false)
                        .map((b) => (
                          <option key={b.id} value={b.id}>
                            {b.code} - {b.name}
                          </option>
                        ))}
                    </optgroup>
                  )}
                </>
              ) : (
                branches.map((branch) => (
                  <option key={branch.id} value={branch.id}>
                    {branch.code} - {branch.name}
                  </option>
                ))
              )}
            </select>
          </label>
          <label className="block">
            <span className="form-label">
              Átvevő
              {direction === 'inbound' && (
                <span className="ml-1 text-xs text-gray-500">(automatikus — Ön értéktára)</span>
              )}
            </span>
            <select
              className={`form-input ${direction === 'inbound' ? 'bg-gray-100 cursor-not-allowed' : ''}`}
              value={form.toBranchId}
              disabled={disabled || direction === 'inbound'}
              onChange={(e) => patch({ toBranchId: e.target.value })}
            >
              <option value="">Válasszon átvevőt</option>
              {vaultCounterparties ? (
                // FK-013: 3-csoportos optgroup értéktáros user esetén
                // Audit follow-up: defenzív `?? []` — ha a backend Jackson kihagy egy null
                // mezőt (Include.NON_NULL), a frontend ne crash-eljen `undefined.length` miatt.
                <>
                  {ownBranchOption && form.toBranchId === ownBranchId && (
                    <optgroup label="Saját értéktár">
                      <option value={ownBranchOption.id}>
                        {ownBranchOption.code
                          ? `${ownBranchOption.code} - ${ownBranchOption.name}`
                          : ownBranchOption.name}
                      </option>
                    </optgroup>
                  )}
                  {(vaultCounterparties.territorialCashiers ?? []).length > 0 && (
                    <optgroup label="Helyi Pénztárak">
                      {(vaultCounterparties.territorialCashiers ?? [])
                        .filter((b) => b.isActive !== false)
                        .map((b) => (
                          <option key={b.id} value={b.id}>
                            {b.code} - {b.name}
                          </option>
                        ))}
                    </optgroup>
                  )}
                  {(vaultCounterparties.peerVaults ?? []).length > 0 && (
                    <optgroup label="Társ értéktárak">
                      {(vaultCounterparties.peerVaults ?? [])
                        .filter((b) => b.isActive !== false)
                        .map((b) => (
                          <option key={b.id} value={b.id}>
                            {b.code} - {b.name}
                          </option>
                        ))}
                    </optgroup>
                  )}
                  {(vaultCounterparties.fixedCounterparties ?? []).length > 0 && (
                    <optgroup label="Banki és speciális partnerek">
                      {(vaultCounterparties.fixedCounterparties ?? [])
                        .filter((b) => b.isActive !== false)
                        .map((b) => (
                          <option key={b.id} value={b.id}>
                            {b.code} - {b.name}
                          </option>
                        ))}
                    </optgroup>
                  )}
                </>
              ) : (
                branches.map((branch) => (
                  <option key={branch.id} value={branch.id}>
                    {branch.code} - {branch.name}
                  </option>
                ))
              )}
            </select>
          </label>
          <label className="block">
            <span className="form-label">Kért kézbesítési dátum</span>
            <input
              type="date"
              className="form-input"
              value={form.deliveryDate}
              disabled={saving}
              onChange={(e) => patch({ deliveryDate: e.target.value })}
            />
          </label>
          {canRecordHandlingFee && (
            <label className="block">
              <span className="form-label">{t('shipments.tetelTipusa')}</span>
              <select
                className="form-input"
                value={itemType}
                disabled={disabled}
                onChange={(event) => {
                  setItemType(event.target.value as 'currency' | 'handlingFee')
                  setCalculatedHandlingFee(null)
                }}
              >
                <option value="currency">{t('shipments.tetelTipusValuta')}</option>
                <option value="handlingFee">{t('shipments.tetelTipusKezelesiKoltseg')}</option>
              </select>
            </label>
          )}
          {!isHandlingFee && (
            <label className="block">
              <span className="form-label">Valuta</span>
              <select
                className="form-input"
                value={form.currencyId}
                disabled={disabled}
                onChange={(e) => patch({ currencyId: e.target.value })}
              >
                <option value="">Válasszon valutát</option>
                {currencies.map((currency) => (
                  <option key={currency.id} value={currency.id}>
                    {currency.code} - {currency.name}
                  </option>
                ))}
              </select>
            </label>
          )}
          <label className="block">
            <span className="form-label">
              {isHandlingFee ? t('shipments.kezelesiKoltsegOsszegeFt') : 'Összeg'}
            </span>
            <input
              type="number"
              min={isHandlingFee ? '5' : '0.01'}
              step={isHandlingFee ? '5' : '0.01'}
              className="form-input"
              value={form.amount}
              disabled={saving}
              onChange={(event) => {
                patch({ amount: event.target.value })
                setCalculatedHandlingFee(null)
              }}
            />
          </label>
          {/* D követelmény (Bali Henriett): aktuális elszámoló árfolyam + forintosított érték
              AUTOMATIKUSAN, read-only — a felhasználó NE írja kézzel. */}
          {!isHandlingFee && (
            <label className="block">
              <span className="form-label">
                Alkalmazott elszámoló árfolyam
                <span className="ml-1 text-xs text-gray-500">
                  (automatikus — aktuális rendszer-árfolyam)
                </span>
              </span>
              <input
                type="text"
                className="form-input bg-gray-100 cursor-not-allowed"
                value={
                  rateLoading
                    ? 'Betöltés…'
                    : appliedRate != null
                      ? appliedRate.toLocaleString('hu-HU', { maximumFractionDigits: 6 })
                      : '—'
                }
                disabled
                readOnly
              />
            </label>
          )}
          <label className="block">
            <span className="form-label">
              {isHandlingFee ? 'Kerekített összeg' : 'Forintosított érték'}
              <span className="ml-1 text-xs text-gray-500">(automatikus — 5 Ft-ra kerekítve)</span>
              {isHandlingFee && calculatedHandlingFee != null && (
                <span className="ml-1 text-xs text-gray-500">
                  — {t('shipments.szamitottKezelesiDij')}:{' '}
                  {calculatedHandlingFee.toLocaleString('hu-HU')} Ft
                </span>
              )}
            </span>
            <input
              type="text"
              className="form-input bg-gray-100 cursor-not-allowed"
              value={
                (isHandlingFee ? roundedHandlingFeeAmount : hufValue) != null
                  ? `${(isHandlingFee ? roundedHandlingFeeAmount : hufValue)?.toLocaleString('hu-HU')} Ft`
                  : '—'
              }
              disabled
              readOnly
            />
          </label>
          {/* FK02 (FR-1..3): szállító neve + plombaszám — KÖTELEZŐ az átadás-átvételnél. */}
          <label className="block">
            <span className="form-label">
              Szállító neve <span className="text-red-500">*</span>
            </span>
            <input
              type="text"
              maxLength={128}
              className="form-input"
              placeholder="Szállító neve..."
              value={form.carrierName}
              disabled={saving}
              onChange={(e) => patch({ carrierName: e.target.value })}
            />
          </label>
          <label className="block">
            <span className="form-label">
              Plombaszám <span className="text-red-500">*</span>
            </span>
            <input
              type="text"
              maxLength={64}
              className="form-input"
              placeholder="Plombaszám..."
              value={form.sealNumber}
              disabled={saving}
              onChange={(e) => patch({ sealNumber: e.target.value })}
            />
          </label>
          <label className="block md:col-span-2">
            <span className="form-label">Megjegyzés</span>
            <textarea
              className="form-input min-h-24"
              value={form.notes}
              disabled={saving}
              onChange={(e) => patch({ notes: e.target.value })}
            />
          </label>
          <div className="md:col-span-2 rounded border border-gray-200 p-3">
            <div className="mb-2 flex items-center justify-between gap-3">
              <span className="form-label mb-0">Címletezés</span>
              <button
                type="button"
                className="form-button flex items-center gap-2"
                disabled={saving}
                onClick={() =>
                  setDenominations((current) => [...current, { quantity: '', faceValue: '' }])
                }
              >
                <Plus size={16} /> Sor hozzáadása
              </button>
            </div>
            {denominations.length > 0 && (
              <div className="space-y-2">
                {denominations.map((line, index) => {
                  const quantity = Number(line.quantity)
                  const faceValue = Number(line.faceValue.replace(',', '.'))
                  const lineTotal =
                    Number.isFinite(quantity) && Number.isFinite(faceValue)
                      ? quantity * faceValue
                      : 0
                  return (
                    <div key={index} className="grid grid-cols-[1fr_1fr_1fr_auto] gap-2">
                      <input
                        type="number"
                        min="1"
                        step="1"
                        className="form-input"
                        placeholder="Darab"
                        value={line.quantity}
                        disabled={saving}
                        onChange={(e) =>
                          setDenominations((current) =>
                            current.map((item, i) =>
                              i === index ? { ...item, quantity: e.target.value } : item,
                            ),
                          )
                        }
                      />
                      <input
                        type="number"
                        min="0.01"
                        step="0.01"
                        className="form-input"
                        placeholder="Névleges érték"
                        value={line.faceValue}
                        disabled={saving}
                        onChange={(e) =>
                          setDenominations((current) =>
                            current.map((item, i) =>
                              i === index ? { ...item, faceValue: e.target.value } : item,
                            ),
                          )
                        }
                      />
                      <input
                        type="text"
                        className="form-input bg-gray-100"
                        value={
                          lineTotal > 0
                            ? `${lineTotal.toLocaleString('hu-HU')} ${isHandlingFee ? 'HUF' : (selectedCurrency?.code ?? '')}`
                            : '—'
                        }
                        disabled
                        readOnly
                      />
                      <button
                        type="button"
                        className="toolbar-button text-red-600"
                        title="Címletsor törlése"
                        disabled={saving}
                        onClick={() =>
                          setDenominations((current) => current.filter((_, i) => i !== index))
                        }
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
        <div className="flex justify-end">
          <button
            type="submit"
            className="form-button-primary flex items-center gap-2"
            disabled={disabled}
          >
            <Send size={16} />
            {saving ? 'Beküldés...' : 'Igény beküldése'}
          </button>
        </div>
      </form>

      {/* FR-1..5: Bizonylat Előnézet + nyomtatás — kizárólag frissen rögzített átadás-átvételnél.
          A modal bezárása (nyomtatás után vagy mégse) navigál a szállítmány-listára. */}
      <ReceiptPreviewModal
        isOpen={showReceiptModal}
        onClose={() => {
          setShowReceiptModal(false)
          navigate('/shipments', { replace: true })
        }}
        receiptData={printReceiptData}
        qrCodeDataUrl={null}
        allowPrint={isElectron()}
        printLabel="Nyomtatás"
        onPrint={async () => {
          if (!printReceiptData) return
          if (!window.electronAPI?.printReceipt) {
            toast.warning(
              'Nyomtatás nem elérhető',
              isElectron()
                ? 'Electron preload/electronAPI hiba — indítsa újra a klienst.'
                : 'A nyomtatás csak az asztali (Electron) kliensben érhető el.',
            )
            return
          }
          try {
            const ok = await window.electronAPI.printReceipt(JSON.stringify(printReceiptData))
            if (ok)
              toast.success(
                'Nyomtatás elindítva',
                `Bizonylat: ${printReceiptData.receiptNumber ?? '—'}`,
              )
            else toast.error('Nyomtatás sikertelen', 'A nyomtató nem válaszolt.')
          } catch (e) {
            toast.error('Nyomtatás hiba', getErrorMessage(e))
          }
        }}
      />
    </div>
  )
}
