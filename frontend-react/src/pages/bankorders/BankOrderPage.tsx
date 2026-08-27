/**
 * E-B8 Banki rendelés workflow oldal — v2.5.31 működő implementáció.
 *
 * Backend: BankOrderController (`/api/v1/bank-orders`) — V187 migráció.
 * GitHub issue: https://github.com/kosazoltan/valutavalto-program/issues/279
 *
 * Workflow: PENDING → APPROVED (ügyvezető) → EXECUTED (értéktár), vagy CANCELLED.
 */

import { useEffect, useState, type FormEvent } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Building2, Eye, Plus, RefreshCw, X } from 'lucide-react'
import {
  bankOrdersApi,
  BankOrder,
  BankOrderStatus,
  BankOrderUrgency,
} from '../../services/api/bankOrders'
import { api } from '../../services/api'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTextReasonModal } from '../../components/TextReasonModal'
import { toast } from '../../components/ui/toaster'
import i18n from '../../i18n'

const STATUS_LABELS: Record<BankOrderStatus, string> = {
  PENDING: 'Függőben',
  APPROVED: 'Jóváhagyva',
  EXECUTED: 'Teljesítve',
  CANCELLED: 'Visszavonva',
}

const STATUS_COLORS: Record<BankOrderStatus, string> = {
  PENDING: 'bg-yellow-100 text-yellow-800',
  APPROVED: 'bg-blue-100 text-blue-800',
  EXECUTED: 'bg-green-100 text-green-800',
  CANCELLED: 'bg-gray-100 text-gray-700',
}

interface BranchOption {
  id: string
  code: string
  name: string
  isActive?: boolean
}

interface CurrencyOption {
  id: number
  code: string
  name: string
  isActive?: boolean
}

interface CreateForm {
  branchId: string
  currencyId: string
  amount: string
  urgency: BankOrderUrgency
  notes: string
}

interface WuDailyLimit {
  businessDate: string
  currencyCode: string
  dailyLimit: number
  usedAmount: number
  remainingAmount: number
  usagePercent: number
  resetAt?: string
}

const EMPTY_CREATE_FORM: CreateForm = {
  branchId: '',
  currencyId: '',
  amount: '',
  urgency: 'NORMAL',
  notes: '',
}

export default function BankOrderPage() {
  const [orders, setOrders] = useState<BankOrder[]>([])
  const [statusFilter, setStatusFilter] = useState<BankOrderStatus | ''>('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionInProgress, setActionInProgress] = useState<string | null>(null)
  const [selectedOrder, setSelectedOrder] = useState<BankOrder | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [detailError, setDetailError] = useState<string | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [createForm, setCreateForm] = useState<CreateForm>(EMPTY_CREATE_FORM)
  const [branches, setBranches] = useState<BranchOption[]>([])
  const [currencies, setCurrencies] = useState<CurrencyOption[]>([])
  const [createError, setCreateError] = useState<string | null>(null)
  const [createSaving, setCreateSaving] = useState(false)
  const [referenceLoading, setReferenceLoading] = useState(false)
  const [wuLimit, setWuLimit] = useState<WuDailyLimit | null>(null)
  const [wuLimitError, setWuLimitError] = useState<string | null>(null)
  const [wuLimitUseAmount, setWuLimitUseAmount] = useState('')
  const [wuLimitUseSaving, setWuLimitUseSaving] = useState(false)
  const [searchParams, setSearchParams] = useSearchParams()
  // FKH-027 B-csoport: a natív window.prompt() kiváltása (Electronban silent no-op)
  const { modal: reasonModal, requestReason } = useTextReasonModal()

  // E-B8 (#279): a Készlet pillanatkép „Sürgősségi banki kivét" gombja
  // ?create=1&urgency=EMERGENCY paraméterekkel nyitja elő a formot.
  useEffect(() => {
    if (searchParams.get('create') !== '1') return
    const urgencyParam = searchParams.get('urgency')
    const urgency: BankOrderUrgency =
      urgencyParam === 'EMERGENCY' || urgencyParam === 'URGENT' ? urgencyParam : 'NORMAL'
    setCreateForm({ ...EMPTY_CREATE_FORM, urgency })
    setCreateError(null)
    setShowCreate(true)
    void loadReferenceData()
    setSearchParams({}, { replace: true })
    // Copilot review: searchParams dependency kell, hogy route-on belüli param-változás
    // (back/forward, ismételt gomb-kattintás) is megnyissa a formot. Nem loopol: a
    // param-törlés utáni újrafutás a create!=1 ágon azonnal kilép.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams])

  const load = async (statusOverride?: BankOrderStatus | '') => {
    setLoading(true)
    setError(null)
    try {
      const effectiveStatus = statusOverride ?? statusFilter
      const result = await bankOrdersApi.list(effectiveStatus || undefined, 0, 100)
      setOrders(result?.content ?? [])
    } catch (err) {
      logger.error('BankOrderPage', 'Lista hiba:', err)
      setError(err instanceof Error ? err.message : 'Ismeretlen hiba')
    } finally {
      setLoading(false)
    }
  }

  const loadWuLimit = async () => {
    setWuLimitError(null)
    try {
      const response = await api.get<WuDailyLimit>('/western-union/daily-limit')
      setWuLimit(response.data)
    } catch (err) {
      logger.error('BankOrderPage', 'WU napi keret hiba:', err)
      setWuLimitError(getErrorMessage(err))
    }
  }

  const handleUseWuLimit = async () => {
    const amountUsd = Number(wuLimitUseAmount.replace(/\s/g, '').replace(',', '.'))
    if (!Number.isFinite(amountUsd) || amountUsd <= 0) {
      setWuLimitError('Pozitív USD összeget kell megadni a WU napi keret kézi felhasználásához.')
      return
    }
    if (!confirm(`Biztosan rögzíti a WU napi keret kézi felhasználását: ${amountUsd} USD?`)) {
      return
    }

    setWuLimitUseSaving(true)
    setWuLimitError(null)
    try {
      await api.post('/western-union/daily-limit/use', {
        amountUsd,
        businessDate: wuLimit?.businessDate,
      })
      setWuLimitUseAmount('')
      await loadWuLimit()
    } catch (err) {
      logger.error('BankOrderPage', 'WU napi keret kézi felhasználás hiba:', err)
      setWuLimitError(getErrorMessage(err))
    } finally {
      setWuLimitUseSaving(false)
    }
  }

  useEffect(() => {
    void load()
    void loadWuLimit()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter])

  const handleApprove = async (id: string) => {
    if (!confirm('Biztosan jóváhagyja ezt a banki rendelést?')) return
    setActionInProgress(id)
    try {
      await bankOrdersApi.approve(id)
      await load()
    } catch (err) {
      toast.error('Hiba a jóváhagyásnál', err instanceof Error ? err.message : '')
    } finally {
      setActionInProgress(null)
    }
  }

  const handleExecute = async (id: string) => {
    const ref = await requestReason({ title: 'Bank hivatkozási szám (opcionális):' })
    // A null (Mégse) és az üres string (OK üresen) itt szándékosan KÜLÖNBÖZIK:
    // üres referenciával is végrehajtható a rendelés (ref || undefined lent).
    if (ref === null) return
    setActionInProgress(id)
    try {
      await bankOrdersApi.execute(id, ref || undefined)
      await load()
    } catch (err) {
      toast.error('Hiba a teljesítésnél', err instanceof Error ? err.message : '')
    } finally {
      setActionInProgress(null)
    }
  }

  const handleCancel = async (id: string) => {
    const reason = await requestReason({ title: 'Visszavonás indoklása:' })
    if (!reason) return
    setActionInProgress(id)
    try {
      await bankOrdersApi.cancel(id, reason)
      await load()
    } catch (err) {
      toast.error('Hiba a visszavonásnál', err instanceof Error ? err.message : '')
    } finally {
      setActionInProgress(null)
    }
  }

  const handleOpenDetails = async (id: string) => {
    setDetailLoadingId(id)
    setDetailError(null)
    try {
      setSelectedOrder(await bankOrdersApi.get(id))
    } catch (err) {
      logger.error('BankOrderPage', 'Részletek hiba:', err)
      setDetailError(getErrorMessage(err))
    } finally {
      setDetailLoadingId(null)
    }
  }

  const loadReferenceData = async () => {
    setReferenceLoading(true)
    setCreateError(null)
    try {
      const [branchResponse, currencyResponse] = await Promise.all([
        api.get('/branches'),
        api.get('/currencies'),
      ])
      setBranches(safeArray<BranchOption>(branchResponse.data).filter((b) => b.isActive !== false))
      setCurrencies(
        safeArray<CurrencyOption>(currencyResponse.data).filter(
          (c) => c.isActive !== false && c.code !== 'HUF',
        ),
      )
    } catch (err) {
      logger.error('BankOrderPage', 'Referenciaadat hiba:', err)
      setCreateError(getErrorMessage(err))
    } finally {
      setReferenceLoading(false)
    }
  }

  const openCreate = () => {
    setCreateForm(EMPTY_CREATE_FORM)
    setCreateError(null)
    setShowCreate(true)
    if (branches.length === 0 || currencies.length === 0) {
      void loadReferenceData()
    }
  }

  const handleCreate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setCreateError(null)
    const amount = Number(createForm.amount.replace(',', '.'))
    if (!createForm.branchId || !createForm.currencyId || !Number.isFinite(amount) || amount <= 0) {
      setCreateError('Iroda, valuta és pozitív összeg megadása kötelező.')
      return
    }
    setCreateSaving(true)
    try {
      await bankOrdersApi.create({
        branchId: createForm.branchId,
        currencyId: Number(createForm.currencyId),
        amount,
        urgency: createForm.urgency,
        notes: createForm.notes.trim() || undefined,
      })
      setShowCreate(false)
      setCreateForm(EMPTY_CREATE_FORM)
      setStatusFilter('')
      await load('')
    } catch (err) {
      logger.error('BankOrderPage', 'Létrehozási hiba:', err)
      setCreateError(getErrorMessage(err))
    } finally {
      setCreateSaving(false)
    }
  }

  return (
    <div className="space-y-4 p-4">
      <div className="flex items-center gap-2">
        <Building2 className="h-6 w-6 text-blue-600" />
        <h1 className="text-xl font-bold text-gray-800">{i18n.t('literals.banki-rendelesek')}</h1>
      </div>

      <div className="flex items-center gap-3">
        <label className="text-sm font-semibold">{i18n.t('literals.statusz-szuro')}</label>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as BankOrderStatus | '')}
          className="rounded border px-2 py-1 text-sm"
        >
          <option value="">{i18n.t('literals.mind')}</option>
          <option value="PENDING">{i18n.t('literals.fuggoben')}</option>
          <option value="APPROVED">{i18n.t('literals.jovahagyva')}</option>
          <option value="EXECUTED">{i18n.t('literals.teljesitve')}</option>
          <option value="CANCELLED">{i18n.t('literals.visszavonva')}</option>
        </select>
        <button
          onClick={() => void load()}
          className="flex items-center gap-1 rounded border px-3 py-1 text-sm hover:bg-gray-50"
        >
          <RefreshCw className="h-4 w-4" />
          {i18n.t('literals.frissit')}
        </button>
        <button
          onClick={openCreate}
          className="ml-auto flex items-center gap-1 rounded bg-blue-600 px-3 py-1 text-sm text-white hover:bg-blue-700"
        >
          <Plus className="h-4 w-4" />
          {i18n.t('literals.uj-rendeles')}
        </button>
      </div>

      <section className="rounded border border-gray-200 bg-white p-4">
        <div className="mb-2 flex items-center justify-between gap-3">
          <div>
            <h2 className="text-sm font-semibold text-gray-800">
              {i18n.t('literals.western-union-napi-keret')}
            </h2>
            {wuLimit && (
              <p className="text-xs text-gray-500">
                {wuLimit.businessDate}
                {i18n.t('literals.reset')}{' '}
                {wuLimit.resetAt ? new Date(wuLimit.resetAt).toLocaleString('hu-HU') : '00:00'}
              </p>
            )}
          </div>
          <button
            type="button"
            onClick={() => void loadWuLimit()}
            className="rounded border px-2 py-1 text-xs hover:bg-gray-50"
          >
            {i18n.t('literals.frissit')}
          </button>
        </div>
        {wuLimitError && <div className="text-sm text-red-700">{wuLimitError}</div>}
        {!wuLimitError && wuLimit && (
          <div>
            <div className="mb-1 flex justify-between text-xs text-gray-600">
              <span>
                {Number(wuLimit.usedAmount).toLocaleString('hu-HU')} {wuLimit.currencyCode}{' '}
                {i18n.t('literals.felhasznalva')}
              </span>
              <span>
                {Number(wuLimit.remainingAmount).toLocaleString('hu-HU')} {wuLimit.currencyCode}{' '}
                {i18n.t('literals.maradt')}
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded bg-gray-100">
              <div
                className="h-full bg-blue-600"
                style={{ width: `${Math.min(Number(wuLimit.usagePercent) || 0, 100)}%` }}
              />
            </div>
            <div className="mt-1 text-right text-xs text-gray-500">
              {Number(wuLimit.dailyLimit).toLocaleString('hu-HU')} {wuLimit.currencyCode}
              {i18n.t('literals.napi-limit')}
            </div>
          </div>
        )}
        <div className="mt-3 flex flex-col gap-2 border-t border-gray-100 pt-3 sm:flex-row sm:items-end">
          <label className="block text-sm">
            <span className="mb-1 block text-xs font-semibold text-gray-600">
              {i18n.t('literals.kezi-fallback-felhasznalas-usd')}
            </span>
            <input
              value={wuLimitUseAmount}
              onChange={(event) => setWuLimitUseAmount(event.target.value)}
              inputMode="decimal"
              className="w-full rounded border px-3 py-2 text-sm sm:w-56"
              placeholder="0.00"
            />
          </label>
          <button
            type="button"
            onClick={() => void handleUseWuLimit()}
            disabled={wuLimitUseSaving}
            className="rounded bg-blue-600 px-3 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {wuLimitUseSaving ? 'Rögzítés...' : 'Keret felhasználás'}
          </button>
        </div>
      </section>

      {error && (
        <div className="rounded border border-red-300 bg-red-50 p-3 text-sm text-red-800">
          {i18n.t('literals.hiba')}
          {error}
        </div>
      )}

      {loading && <div className="text-sm text-gray-500">{i18n.t('literals.betoltes-3')}</div>}

      {!loading && orders.length === 0 && (
        <div className="rounded border border-gray-200 bg-gray-50 p-6 text-center text-sm text-gray-600">
          {i18n.t('literals.nincs-banki-rendeles-a-kivalasztott-szur')}
        </div>
      )}

      {!loading && orders.length > 0 && (
        <div className="overflow-x-auto rounded border border-gray-200">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-left">
              <tr>
                <th className="p-2">{i18n.t('literals.ido-2')}</th>
                <th className="p-2">{i18n.t('literals.iroda')}</th>
                <th className="p-2">{i18n.t('literals.valuta')}</th>
                <th className="p-2 text-right">{i18n.t('literals.osszeg')}</th>
                <th className="p-2">{i18n.t('literals.surgosseg')}</th>
                <th className="p-2">{i18n.t('literals.statusz')}</th>
                <th className="p-2">{i18n.t('literals.kerte')}</th>
                <th className="p-2">{i18n.t('literals.jovahagyta')}</th>
                <th className="p-2"></th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => (
                <tr key={o.id} className="border-t hover:bg-gray-50">
                  <td className="p-2 whitespace-nowrap">
                    {new Date(o.requestedAt).toLocaleString('hu-HU')}
                  </td>
                  <td className="p-2">{o.branchCode}</td>
                  <td className="p-2 font-mono">{o.currencyCode}</td>
                  <td className="p-2 text-right font-mono">
                    {Number(o.amount).toLocaleString('hu-HU')}
                  </td>
                  <td className="p-2">{o.urgency}</td>
                  <td className="p-2">
                    <span
                      className={`rounded px-2 py-0.5 text-xs font-semibold ${STATUS_COLORS[o.status]}`}
                    >
                      {STATUS_LABELS[o.status]}
                    </span>
                  </td>
                  <td className="p-2 text-xs">{o.requestedByWorkerName ?? '-'}</td>
                  <td className="p-2 text-xs">{o.approvedByWorkerName ?? '-'}</td>
                  <td className="p-2 space-x-1 whitespace-nowrap">
                    <button
                      disabled={detailLoadingId === o.id}
                      onClick={() => void handleOpenDetails(o.id)}
                      className="inline-flex items-center gap-1 rounded border px-2 py-0.5 text-xs hover:bg-gray-50 disabled:opacity-50"
                    >
                      <Eye className="h-3 w-3" />
                      {i18n.t('literals.reszletek-2')}
                    </button>
                    {o.status === 'PENDING' && (
                      <>
                        <button
                          disabled={actionInProgress === o.id}
                          onClick={() => void handleApprove(o.id)}
                          className="rounded bg-blue-600 px-2 py-0.5 text-xs text-white hover:bg-blue-700 disabled:opacity-50"
                        >
                          {i18n.t('literals.jovahagy')}
                        </button>
                        <button
                          disabled={actionInProgress === o.id}
                          onClick={() => void handleCancel(o.id)}
                          className="rounded bg-gray-200 px-2 py-0.5 text-xs hover:bg-gray-300 disabled:opacity-50"
                        >
                          {i18n.t('literals.visszavon')}
                        </button>
                      </>
                    )}
                    {o.status === 'APPROVED' && (
                      <>
                        <button
                          disabled={actionInProgress === o.id}
                          onClick={() => void handleExecute(o.id)}
                          className="rounded bg-green-600 px-2 py-0.5 text-xs text-white hover:bg-green-700 disabled:opacity-50"
                        >
                          {i18n.t('literals.teljesit')}
                        </button>
                        <button
                          disabled={actionInProgress === o.id}
                          onClick={() => void handleCancel(o.id)}
                          className="rounded bg-gray-200 px-2 py-0.5 text-xs hover:bg-gray-300 disabled:opacity-50"
                        >
                          {i18n.t('literals.visszavon')}
                        </button>
                      </>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <p className="text-xs text-gray-500">
        {i18n.t('literals.a-banki-rendeles-workflow-es-a-western-u')}
      </p>

      {(selectedOrder || detailError) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-2xl rounded bg-white shadow-xl">
            <div className="flex items-center justify-between border-b p-4">
              <h2 className="text-lg font-semibold">
                {i18n.t('literals.banki-rendeles-reszletei')}
              </h2>
              <button
                type="button"
                onClick={() => {
                  setSelectedOrder(null)
                  setDetailError(null)
                }}
                className="rounded p-1 hover:bg-gray-100"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="grid grid-cols-1 gap-3 p-4 text-sm sm:grid-cols-2">
              {detailError && (
                <div className="rounded border border-red-300 bg-red-50 p-3 text-red-800 sm:col-span-2">
                  {detailError}
                </div>
              )}
              {selectedOrder && (
                <>
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.iroda')}
                    </div>
                    <div>
                      {selectedOrder.branchCode}
                      {i18n.t('literals.lit-17')}
                      {selectedOrder.branchName}
                    </div>
                  </div>
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.valuta-es-osszeg')}
                    </div>
                    <div className="font-mono">
                      {selectedOrder.currencyCode}{' '}
                      {Number(selectedOrder.amount).toLocaleString('hu-HU')}
                    </div>
                  </div>
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.statusz')}
                    </div>
                    <span
                      className={`inline-block rounded px-2 py-0.5 text-xs font-semibold ${STATUS_COLORS[selectedOrder.status]}`}
                    >
                      {STATUS_LABELS[selectedOrder.status]}
                    </span>
                  </div>
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.surgosseg')}
                    </div>
                    <div>{selectedOrder.urgency}</div>
                  </div>
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.kerte')}
                    </div>
                    <div>{selectedOrder.requestedByWorkerName ?? '-'}</div>
                  </div>
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.jovahagyta')}
                    </div>
                    <div>{selectedOrder.approvedByWorkerName ?? '-'}</div>
                  </div>
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.teljesitette')}
                    </div>
                    <div>{selectedOrder.executedByWorkerName ?? '-'}</div>
                  </div>
                  <div>
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.bank-referencia')}
                    </div>
                    <div>{selectedOrder.bankReference ?? '-'}</div>
                  </div>
                  <div className="sm:col-span-2">
                    <div className="text-xs font-semibold uppercase text-gray-500">
                      {i18n.t('literals.megjegyzes')}
                    </div>
                    <div>{selectedOrder.notes ?? '-'}</div>
                  </div>
                  {selectedOrder.cancellationReason && (
                    <div className="sm:col-span-2">
                      <div className="text-xs font-semibold uppercase text-gray-500">
                        {i18n.t('literals.visszavonas-indoka')}
                      </div>
                      <div>{selectedOrder.cancellationReason}</div>
                    </div>
                  )}
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <form onSubmit={handleCreate} className="w-full max-w-2xl rounded bg-white shadow-xl">
            <div className="flex items-center justify-between border-b p-4">
              <h2 className="text-lg font-semibold">{i18n.t('literals.uj-banki-rendeles')}</h2>
              <button
                type="button"
                onClick={() => setShowCreate(false)}
                className="rounded p-1 hover:bg-gray-100"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="grid grid-cols-1 gap-4 p-4 md:grid-cols-2">
              <label className="block text-sm">
                <span className="mb-1 block font-medium text-gray-700">
                  {i18n.t('literals.iroda')}
                </span>
                <select
                  value={createForm.branchId}
                  onChange={(e) => setCreateForm((f) => ({ ...f, branchId: e.target.value }))}
                  disabled={referenceLoading}
                  className="w-full rounded border px-3 py-2"
                >
                  <option value="">{i18n.t('literals.valasszon-irodat')}</option>
                  {branches.map((branch) => (
                    <option key={branch.id} value={branch.id}>
                      {branch.code}
                      {i18n.t('literals.lit-18')}
                      {branch.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block text-sm">
                <span className="mb-1 block font-medium text-gray-700">
                  {i18n.t('literals.valuta')}
                </span>
                <select
                  value={createForm.currencyId}
                  onChange={(e) => setCreateForm((f) => ({ ...f, currencyId: e.target.value }))}
                  disabled={referenceLoading}
                  className="w-full rounded border px-3 py-2"
                >
                  <option value="">{i18n.t('literals.valasszon-valutat')}</option>
                  {currencies.map((currency) => (
                    <option key={currency.id} value={currency.id}>
                      {currency.code}
                      {i18n.t('literals.lit-18')}
                      {currency.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block text-sm">
                <span className="mb-1 block font-medium text-gray-700">
                  {i18n.t('literals.osszeg')}
                </span>
                <input
                  type="number"
                  min="0.01"
                  step="0.01"
                  value={createForm.amount}
                  onChange={(e) => setCreateForm((f) => ({ ...f, amount: e.target.value }))}
                  className="w-full rounded border px-3 py-2"
                />
              </label>
              <label className="block text-sm">
                <span className="mb-1 block font-medium text-gray-700">
                  {i18n.t('literals.surgosseg')}
                </span>
                <select
                  value={createForm.urgency}
                  onChange={(e) =>
                    setCreateForm((f) => ({ ...f, urgency: e.target.value as BankOrderUrgency }))
                  }
                  className="w-full rounded border px-3 py-2"
                >
                  <option value="NORMAL">{i18n.t('literals.normal')}</option>
                  <option value="URGENT">{i18n.t('literals.surgos')}</option>
                  <option value="EMERGENCY">{i18n.t('literals.azonnali')}</option>
                </select>
              </label>
              <label className="block text-sm md:col-span-2">
                <span className="mb-1 block font-medium text-gray-700">
                  {i18n.t('literals.megjegyzes')}
                </span>
                <textarea
                  value={createForm.notes}
                  onChange={(e) => setCreateForm((f) => ({ ...f, notes: e.target.value }))}
                  rows={3}
                  className="w-full rounded border px-3 py-2"
                />
              </label>
              {createError && (
                <div className="rounded border border-red-300 bg-red-50 p-3 text-sm text-red-800 md:col-span-2">
                  {createError}
                </div>
              )}
            </div>
            <div className="flex items-center justify-end gap-2 border-t p-4">
              <button
                type="button"
                onClick={() => setShowCreate(false)}
                className="rounded border px-4 py-2 text-sm hover:bg-gray-50"
              >
                {i18n.t('literals.megse')}
              </button>
              <button
                type="submit"
                disabled={createSaving || referenceLoading}
                className="rounded bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700 disabled:opacity-50"
              >
                {createSaving ? 'Mentés…' : 'Rendelés létrehozása'}
              </button>
            </div>
          </form>
        </div>
      )}
      {reasonModal}
    </div>
  )
}
