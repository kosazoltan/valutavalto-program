import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
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
  const [createdRequestId, setCreatedRequestId] = useState<string | null>(null)
  const formDisabled = loading || saving

  useEffect(() => {
    setForm((current) => current.fromBranchId ? current : { ...current, fromBranchId: worker?.branchId ?? '' })
  }, [worker?.branchId])

  useEffect(() => {
    let active = true
    Promise.all([branchApi.listActive(), currencyApi.getActive()])
      .then(([branchList, currencyList]) => {
        if (!active) return
        setBranches(branchList.filter((branch) => branch.isActive !== false))
        setCurrencies(currencyList.filter((currency) => currency.active !== false))
      })
      .catch((err) => {
        if (!active) return
        logger.error('ShipmentNewPage', t('shipments.referenciaadatBetoltesiHiba'), err)
        setError(getErrorMessage(err))
      })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [t])

  const patch = (values: Partial<FormState>) => {
    setCreatedRequestId(null)
    setForm((current) => ({ ...current, ...values }))
  }

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError(null)
    const amount = Number(form.amount.replace(',', '.'))
    if (!form.fromBranchId || !form.toBranchId || !form.currencyId || !Number.isFinite(amount) || amount <= 0) {
      setError(t('shipments.kotelezoMezokPozitivOsszeg'))
      return
    }
    if (form.fromBranchId === form.toBranchId) {
      setError(t('shipments.keroEsCelIrodaNemLehetUgyanaz'))
      return
    }
    setSaving(true)
    try {
      let requestId = createdRequestId
      if (!requestId) {
        const created = await shipmentRequestApi.create({
          fromBranchId: form.fromBranchId,
          toBranchId: form.toBranchId,
          deliveryDate: form.deliveryDate || undefined,
          notes: form.notes,
          items: [{ currencyId: form.currencyId, requestedAmount: amount }],
        })
        if (!created.id) throw new Error(t('shipments.hianyzoSzallitmanyAzonosito'))
        requestId = created.id
        setCreatedRequestId(requestId)
      }
      await shipmentRequestApi.submit(requestId)
      setCreatedRequestId(null)
      navigate('/shipments', { replace: true })
    } catch (err) {
      logger.error('ShipmentNewPage', t('shipments.szallitmanyigenyLetrehozasiHiba'), err)
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="flex items-center gap-2 text-xl font-bold text-gray-800">
          <Package />{t('shipments.ujSzallitmanyigeny')}
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
            <span className="form-label">{t('shipments.keroIroda')}</span>
            <select className="form-input" value={form.fromBranchId} disabled={formDisabled} onChange={(e) => patch({ fromBranchId: e.target.value })}>
              <option value="">{t('shipments.valasszonIrodat')}</option>
              {branches.map((branch) => <option key={branch.id} value={branch.id}>{branch.code} - {branch.name}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="form-label">{t('shipments.celIroda')}</span>
            <select className="form-input" value={form.toBranchId} disabled={formDisabled} onChange={(e) => patch({ toBranchId: e.target.value })}>
              <option value="">{t('shipments.valasszonCelIrodat')}</option>
              {branches.map((branch) => <option key={branch.id} value={branch.id}>{branch.code} - {branch.name}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="form-label">{t('shipments.kertKezbesitesiDatum')}</span>
            <input type="date" className="form-input" value={form.deliveryDate} disabled={formDisabled} onChange={(e) => patch({ deliveryDate: e.target.value })} />
          </label>
          <label className="block">
            <span className="form-label">{t('common.currency')}</span>
            <select className="form-input" value={form.currencyId} disabled={formDisabled} onChange={(e) => patch({ currencyId: e.target.value })}>
              <option value="">{t('shipments.valasszonValutat')}</option>
              {currencies.map((currency) => <option key={currency.id} value={currency.id}>{currency.code} - {currency.name}</option>)}
            </select>
          </label>
          <label className="block">
            <span className="form-label">{t('common.amount')}</span>
            <input type="number" min="0.01" step="0.01" className="form-input" value={form.amount} disabled={formDisabled} onChange={(e) => patch({ amount: e.target.value })} />
          </label>
          <label className="block md:col-span-2">
            <span className="form-label">{t('common.note')}</span>
            <textarea className="form-input min-h-24" value={form.notes} disabled={formDisabled} onChange={(e) => patch({ notes: e.target.value })} />
          </label>
        </div>
        <div className="flex justify-end">
          <button type="submit" className="form-button-primary flex items-center gap-2" disabled={formDisabled}>
            <Send size={16} />{saving ? t('shipments.bekuldesFolyamatban') : t('shipments.igenyBekuldese')}
          </button>
        </div>
      </form>
    </div>
  )
}
