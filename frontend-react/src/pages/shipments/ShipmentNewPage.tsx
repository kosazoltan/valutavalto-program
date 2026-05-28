import { useEffect, useState, useMemo, type FormEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { AlertCircle, ArrowLeft, Package, Send } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { branchApi, currencyApi, shipmentRequestApi, type BranchInfo, type Currency } from '../../services/api/index'
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
  const [form, setForm] = useState<FormState>({
    fromBranchId: worker?.branchId ?? '',
    toBranchId: '',
    deliveryDate: '',
    currencyId: '',
    amount: '',
    notes: '',
  })
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const disabled = loading || saving

  useEffect(() => {
    setForm((current) => current.fromBranchId ? current : { ...current, fromBranchId: worker?.branchId ?? '' })
  }, [worker?.branchId])

  useEffect(() => {
    let active = true
    // FK-005/B4: a Kérő/Cél iroda legördülő CSAK a saját terület pénztárait mutatja, ha a
    // felhasználó értéktárosként operál (vault-authority → region-scope); egyébként minden
    // aktív. A backend AccessScopeService dönt (a vault-authority precedál a base-role felett).
    Promise.all([branchApi.listMyTerritory(), currencyApi.getActive()])
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
  }, [])

  const patch = (values: Partial<FormState>) => setForm((current) => ({ ...current, ...values }))

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
        items: [{ currencyId: form.currencyId, requestedAmount: amount }],
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
            <span className="form-label">Kérő iroda</span>
            <select className="form-input" value={form.fromBranchId} disabled={disabled} onChange={(e) => patch({ fromBranchId: e.target.value })}>
              <option value="">Válasszon irodát</option>
              {branches.map((branch) => <option key={branch.id} value={branch.id}>{branch.code} - {branch.name}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="form-label">Cél iroda</span>
            <select className="form-input" value={form.toBranchId} disabled={disabled} onChange={(e) => patch({ toBranchId: e.target.value })}>
              <option value="">Válasszon cél irodát</option>
              {branches.map((branch) => <option key={branch.id} value={branch.id}>{branch.code} - {branch.name}</option>)}
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
