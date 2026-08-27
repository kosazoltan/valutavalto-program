import React, { useState, useEffect, useCallback } from 'react'
import { api, reservationsApi } from '@/services/api/index'
import { customerApi, type Customer } from '@/services/api/transactions'
import { useAuthStore } from '@/stores/authStore'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'
import { downloadBlob } from '../../utils/downloadBlob'
import { useTextReasonModal } from '../../components/TextReasonModal'
import { toast } from '../../components/ui/toaster'
import i18n from '../../i18n'

// A backend ReservationDto részleges leképezése (a UI által használt mezők) —
// backend/.../dto/reservation/ReservationDto.java.
interface Reservation {
  id: number
  customerId: number | null
  customerName: string | null
  branchId: string
  branchName: string | null
  currencyCode: string
  reservedAmount: number
  exchangeRate: number
  depositAmount: number
  status: string
  expiresAt: string
  createdAt: string
  fulfilledAt: string | null
  cancelledAt: string | null
  receiptNumber: string | null
  cancellationReason: string | null
  refundAmount: number | null
  notes: string | null
  expired: boolean
}

interface ReservedStock {
  currencyCode: string
  reservedAmount: number
  activeCount: number
}

// Backend ReservationStatus enum értékei.
const statusColors: Record<string, string> = {
  ACTIVE: 'bg-blue-500',
  FULFILLED: 'bg-green-500',
  CANCELLED_BY_CUSTOMER: 'bg-red-500',
  CANCELLED_BY_COMPANY: 'bg-orange-500',
  EXPIRED: 'bg-gray-500',
}

const statusLabels: Record<string, string> = {
  ACTIVE: 'Aktív',
  FULFILLED: 'Teljesítve',
  CANCELLED_BY_CUSTOMER: 'Ügyfél lemondta',
  CANCELLED_BY_COMPANY: 'EBC lemondta',
  EXPIRED: 'Lejárt',
}

const EXPIRING_SOON_HOURS = 4

export default function ReservationPage() {
  const { t } = useTranslation()
  const [reservations, setReservations] = useState<Reservation[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'active' | 'expiring' | 'expired'>('active')
  const [searchTerm, setSearchTerm] = useState('')
  const [showCreateDialog, setShowCreateDialog] = useState(false)
  const [reservedStock, setReservedStock] = useState<ReservedStock[]>([])
  const [selectedReservation, setSelectedReservation] = useState<Reservation | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<number | null>(null)
  const workerBranchId = useAuthStore((state) => state.worker?.branchId ?? '')
  // FKH-027 B-csoport: a natív window.prompt() kiváltása (Electronban silent no-op)
  const { modal: reasonModal, requestReason } = useTextReasonModal()

  const loadReservations = useCallback(async () => {
    setLoading(true)
    try {
      const branchId = workerBranchId || localStorage.getItem('branchId') || ''
      if (branchId) {
        try {
          const stock = (await reservationsApi.reservedStock(
            branchId,
          )) as unknown as ReservedStock[]
          setReservedStock(safeArray<ReservedStock>(stock))
        } catch {
          setReservedStock([])
        }
      } else {
        setReservedStock([])
      }
      let data: Reservation[] = []
      if (activeTab === 'expired') {
        data = (await reservationsApi.list({ status: 'EXPIRED' })) as unknown as Reservation[]
      } else {
        // A backend UUID branchId-t vár; üres érték → 400. Ilyenkor üres lista (nincs hívás).
        if (!branchId) {
          setReservations([])
          return
        }
        // active + expiring egyaránt az aktív listából (a backend nem ad külön végpontot)
        data = (await reservationsApi.list({ branchId })) as unknown as Reservation[]
        if (activeTab === 'expiring') {
          const limit = Date.now() + EXPIRING_SOON_HOURS * 3600 * 1000
          data = safeArray<Reservation>(data).filter(
            (r) => new Date(r.expiresAt).getTime() <= limit,
          )
        }
      }
      setReservations(data)
    } catch {
      setReservations([])
      setReservedStock([])
    } finally {
      setLoading(false)
    }
  }, [activeTab, workerBranchId])

  useEffect(() => {
    void loadReservations()
  }, [loadReservations])

  // Codex P2 (#1032): a teljesítés utáni auto-letöltés HIBÁJÁNÁL maradjon retry-út — különben a FULFILLED
  // foglaló a listából eltűnik, és a pénztáros sosem tudja kinyomtatni a kötelező beszámítási bizonylatot.
  const [failedReceiptId, setFailedReceiptId] = useState<number | null>(null)

  // G14: Foglaló-bizonylat (átvétel / visszafizetés) PDF letöltése. Visszaad: sikeres volt-e (retry-hez).
  const handleDownloadReceipt = useCallback(
    async (id: number, refund: boolean): Promise<boolean> => {
      try {
        const blob = await reservationsApi.receipt(id, refund)
        downloadBlob(blob, `foglalo-${refund ? 'visszafizetes' : 'atvetel'}-${id}.pdf`)
        return true
      } catch {
        // A hiba-visszajelzést a backend toast adja; a hívó dönt a retry-útról.
        return false
      }
    },
    [],
  )

  const handleFulfill = useCallback(
    async (id: number) => {
      try {
        await reservationsApi.fulfill(id)
        // Codex P2 (#1032): a teljesített foglaló a listából eltűnik (csak ACTIVE/expired töltődik), ezért a
        // kötelező BESZÁMÍTÁSI bizonylatot (FR-14, refund=false) RÖGTÖN a teljesítés után letöltjük — ez az
        // egyetlen elérhető nyomtatási út a FULFILLED állapotú foglalóhoz a termék-flow-ban. Ha a letöltés
        // elhasal (hálózat/blob), megjegyezzük az id-t és retry-bannert mutatunk (a foglaló már teljesítve van).
        const ok = await handleDownloadReceipt(id, false)
        setFailedReceiptId(ok ? null : id)
        void loadReservations()
      } catch {
        // A teljesítés maga hasalt el (nem a letöltés) — a lista látható marad, a hibát a backend toast adja.
      }
    },
    [loadReservations, handleDownloadReceipt],
  )

  // Retry: a sikertelen beszámítási bizonylat újra-letöltése (a FULFILLED foglaló id-jával).
  const handleRetryReceipt = useCallback(async () => {
    if (failedReceiptId == null) return
    const ok = await handleDownloadReceipt(failedReceiptId, false)
    if (ok) setFailedReceiptId(null)
  }, [failedReceiptId, handleDownloadReceipt])

  const handleShowDetails = useCallback(async (id: number) => {
    try {
      setDetailLoadingId(id)
      setSelectedReservation((await reservationsApi.getById(String(id))) as unknown as Reservation)
    } catch {
      setSelectedReservation(null)
    } finally {
      setDetailLoadingId(null)
    }
  }, [])

  const handleCancelByCustomer = useCallback(
    async (id: number) => {
      const reason = await requestReason({
        title: 'Lemondás oka (ügyfél miatt — a letét nem jár vissza):',
      })
      if (reason === null || !reason.trim()) return
      try {
        await reservationsApi.cancel(id, reason.trim())
        void loadReservations()
      } catch {
        // noop
      }
    },
    [loadReservations, requestReason],
  )

  const handleCancelByCompany = useCallback(
    async (id: number) => {
      const reason = await requestReason({
        title: 'Lemondás oka (EBC miatt — dupla letét-visszafizetés, supervisor jóváhagyás):',
      })
      if (reason === null || !reason.trim()) return
      const supervisorWorkerId = Number(localStorage.getItem('workerId')) || undefined
      if (!supervisorWorkerId) {
        // A backend kötelezővé teszi a supervisorWorkerId-t az EBC-stornóhoz.
        toast.warning('Hiányzó supervisor azonosító', 'Jelentkezzen be újra a jóváhagyáshoz.')
        return
      }
      try {
        await reservationsApi.cancelByCompany(id, { reason: reason.trim(), supervisorWorkerId })
        void loadReservations()
      } catch {
        // noop
      }
    },
    [loadReservations, requestReason],
  )

  const filteredReservations = safeArray<Reservation>(reservations).filter((r) => {
    const term = searchTerm.toLowerCase()
    return (
      (r.receiptNumber || '').toLowerCase().includes(term) ||
      (r.customerName || '').toLowerCase().includes(term) ||
      String(r.id).includes(term)
    )
  })

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3">
        <h1 className="text-lg font-bold">{t('reservations.foglalokKezelese')}</h1>
        <button
          onClick={() => setShowCreateDialog(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {t('reservations.ujFoglalo')}
        </button>
      </div>

      {failedReceiptId != null && (
        // Codex P2 (#1032): retry-út a sikertelen beszámítási bizonylat-letöltéshez (a foglaló már teljesítve).
        <div className="mb-3 flex items-center justify-between rounded border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
          <span>
            {i18n.t('literals.a-beszamitasi-bizonylat-letoltese-nem-si')}
            {failedReceiptId}
            {i18n.t('literals.probalja-ujra')}
          </span>
          <button
            onClick={() => void handleRetryReceipt()}
            className="ml-3 rounded bg-amber-600 px-3 py-1 text-xs font-semibold text-white hover:bg-amber-700"
          >
            {i18n.t('literals.bizonylat-letoltese-ujra')}
          </button>
        </div>
      )}

      <div className="mb-3">
        <input
          type="text"
          placeholder="Keresés szám vagy ügyfél alapján..."
          value={searchTerm}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
          className="w-full p-2 border rounded"
        />
      </div>

      {reservedStock.length > 0 && (
        <section
          className="mb-4 rounded border bg-white p-3"
          aria-label={t('reservations.foglaltKeszletOsszesito')}
        >
          <div className="mb-3 text-sm font-semibold text-gray-800">
            {t('reservations.foglaltKeszletValutanemenkent')}
          </div>
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-4">
            {reservedStock.map((stock) => (
              <div key={stock.currencyCode} className="rounded bg-blue-50 p-3">
                <div className="text-xs font-semibold text-blue-700">{stock.currencyCode}</div>
                <div className="mt-1 text-lg font-bold text-gray-900">
                  {stock.reservedAmount.toLocaleString('hu-HU')}
                </div>
                <div className="text-xs text-gray-600">
                  {t('reservations.aktivFoglalo')}
                  {i18n.t('literals.lit-22')}
                  {stock.activeCount.toLocaleString('hu-HU')}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      <div className="mb-4 flex gap-2">
        {[
          { key: 'active' as const, label: 'Aktív foglalók' },
          { key: 'expiring' as const, label: `Hamarosan lejáró (${EXPIRING_SOON_HOURS}h)` },
          { key: 'expired' as const, label: 'Lejárt foglalók' },
        ].map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`px-4 py-2 rounded ${
              activeTab === tab.key ? 'bg-blue-600 text-white' : 'bg-gray-100 hover:bg-gray-200'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className="bg-white rounded border">
        {loading ? (
          <div className="text-center py-8">{i18n.t('literals.betoltes')}</div>
        ) : filteredReservations.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            {t('reservations.nincsenekFoglalokEbbenAKategoriaban')}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-[980px] w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="p-3 text-left">{t('reservations.foglaloSzam')}</th>
                  <th className="p-3 text-left">{t('common.customer')}</th>
                  <th className="p-3 text-left">{t('common.amount')}</th>
                  <th className="p-3 text-left">{t('cashier.exchangeRate')}</th>
                  <th className="p-3 text-left">{t('reservations.letet')}</th>
                  <th className="p-3 text-left">{t('components.lejarat')}</th>
                  <th className="p-3 text-left">{t('common.status')}</th>
                  <th className="p-3 text-left">{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filteredReservations.map((reservation) => (
                  <tr key={reservation.id} className="border-t hover:bg-gray-50">
                    <td className="p-3 font-mono">
                      {reservation.receiptNumber || `#${reservation.id}`}
                    </td>
                    <td className="p-3">{reservation.customerName || '-'}</td>
                    <td className="p-3">
                      {reservation.reservedAmount?.toLocaleString('hu-HU')}{' '}
                      {reservation.currencyCode}
                    </td>
                    <td className="p-3">{reservation.exchangeRate?.toFixed(4)}</td>
                    <td className="p-3">
                      {reservation.depositAmount?.toLocaleString('hu-HU')} {t('components.ft')}
                    </td>
                    <td className="p-3">
                      {reservation.expiresAt
                        ? new Date(reservation.expiresAt).toLocaleString('hu-HU')
                        : '-'}
                    </td>
                    <td className="p-3">
                      <span
                        className={`px-2 py-1 text-xs text-white rounded ${statusColors[reservation.status] || 'bg-gray-400'}`}
                      >
                        {statusLabels[reservation.status] || reservation.status}
                      </span>
                    </td>
                    <td className="p-3">
                      <div className="flex gap-2 flex-wrap">
                        <button
                          onClick={() => void handleShowDetails(reservation.id)}
                          disabled={detailLoadingId === reservation.id}
                          className="px-2 py-1 text-xs bg-gray-700 text-white rounded hover:bg-gray-800 disabled:opacity-60"
                        >
                          {detailLoadingId === reservation.id ? 'Betöltés...' : 'Részletek'}
                        </button>
                        {reservation.status === 'ACTIVE' && (
                          <>
                            <button
                              onClick={() => handleFulfill(reservation.id)}
                              className="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700"
                            >
                              {t('reservations.teljesit')}
                            </button>
                            <button
                              onClick={() => handleCancelByCustomer(reservation.id)}
                              className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700"
                            >
                              {t('reservations.ugyfelLemondas')}
                            </button>
                            <button
                              onClick={() => handleCancelByCompany(reservation.id)}
                              className="px-2 py-1 text-xs bg-orange-600 text-white rounded hover:bg-orange-700"
                            >
                              {t('reservations.ebcLemondas')}
                            </button>
                            <button
                              onClick={() => handleDownloadReceipt(reservation.id, false)}
                              className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                            >
                              {t('reservations.bizonylat')}
                            </button>
                          </>
                        )}
                        {(reservation.status === 'CANCELLED_BY_CUSTOMER' ||
                          reservation.status === 'CANCELLED_BY_COMPANY' ||
                          reservation.status === 'EXPIRED') && (
                          <button
                            onClick={() => handleDownloadReceipt(reservation.id, true)}
                            className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                          >
                            {t('reservations.visszafizetesBizonylat')}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedReservation && (
        <section
          className="mt-4 rounded border bg-white p-4"
          data-testid="reservation-detail-panel"
        >
          <div className="mb-3 flex items-center justify-between gap-2">
            <h2 className="text-base font-semibold text-gray-800">
              {i18n.t('literals.foglalo-reszletei')}
            </h2>
            <button
              onClick={() => setSelectedReservation(null)}
              className="rounded bg-gray-100 px-3 py-1 text-xs font-semibold text-gray-700 hover:bg-gray-200"
            >
              {i18n.t('literals.bezaras')}
            </button>
          </div>
          <dl className="grid grid-cols-1 gap-3 text-sm md:grid-cols-3">
            <div>
              <dt className="text-gray-500">{i18n.t('literals.ugyfel-2')}</dt>
              <dd className="font-medium text-gray-900">
                {selectedReservation.customerName || '-'}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.foglalo-szam')}</dt>
              <dd className="font-mono text-gray-900">
                {selectedReservation.receiptNumber || `#${selectedReservation.id}`}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.statusz')}</dt>
              <dd className="font-medium text-gray-900">
                {statusLabels[selectedReservation.status] || selectedReservation.status}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.valutaosszeg')}</dt>
              <dd className="font-mono text-gray-900">
                {selectedReservation.reservedAmount?.toLocaleString('hu-HU')}{' '}
                {selectedReservation.currencyCode}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.letet')}</dt>
              <dd className="font-mono text-gray-900">
                {selectedReservation.depositAmount?.toLocaleString('hu-HU')} {t('components.ft')}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.lejarat')}</dt>
              <dd className="font-medium text-gray-900">
                {selectedReservation.expiresAt
                  ? new Date(selectedReservation.expiresAt).toLocaleString('hu-HU')
                  : '-'}
              </dd>
            </div>
          </dl>
          {selectedReservation.notes && (
            <div className="mt-3 rounded border border-gray-200 bg-gray-50 p-3 text-sm text-gray-700">
              {selectedReservation.notes}
            </div>
          )}
        </section>
      )}

      {showCreateDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">{t('reservations.ujFoglaloLetrehozasa')}</h2>
            <CreateReservationForm
              onSuccess={() => {
                setShowCreateDialog(false)
                void loadReservations()
              }}
              onCancel={() => setShowCreateDialog(false)}
            />
          </div>
        </div>
      )}
      {reasonModal}
    </div>
  )
}

interface CurrencyOption {
  code?: string
  currencyCode?: string
  name?: string
}

function CreateReservationForm({
  onSuccess,
  onCancel,
}: {
  onSuccess: () => void
  onCancel: () => void
}) {
  const { t } = useTranslation()
  const [customerSearch, setCustomerSearch] = useState('')
  const [customerResults, setCustomerResults] = useState<Customer[]>([])
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null)
  const [currencies, setCurrencies] = useState<CurrencyOption[]>([])
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    currencyCode: '',
    amount: '',
    exchangeRate: '',
    validityHours: '24',
    notes: '',
  })

  useEffect(() => {
    void (async () => {
      try {
        const response = await api.get('/currencies')
        setCurrencies(safeArray<CurrencyOption>(response?.data))
      } catch {
        setCurrencies([])
      }
    })()
  }, [])

  useEffect(() => {
    if (!customerSearch.trim()) {
      setCustomerResults([])
      return
    }
    const timer = setTimeout(() => {
      void (async () => {
        try {
          const results = await customerApi.search(customerSearch.trim())
          setCustomerResults(safeArray<Customer>(results))
        } catch {
          setCustomerResults([])
        }
      })()
    }, 400)
    return () => clearTimeout(timer)
  }, [customerSearch])

  const toLocalDateTime = (hoursAhead: number): string => {
    const d = new Date(Date.now() + hoursAhead * 3600 * 1000)
    const pad = (n: number) => String(n).padStart(2, '0')
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:00`
  }

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setError(null)
    if (!selectedCustomer) {
      setError('Válasszon ügyfelet a keresőből!')
      return
    }
    setSubmitting(true)
    try {
      await reservationsApi.create({
        customerId: selectedCustomer.id,
        currencyCode: formData.currencyCode,
        amount: parseFloat(formData.amount),
        exchangeRate: parseFloat(formData.exchangeRate),
        expiresAt: toLocalDateTime(parseInt(formData.validityHours, 10)),
        notes: formData.notes || undefined,
      })
      onSuccess()
    } catch {
      setError('A foglaló létrehozása sikertelen. Ellenőrizze az adatokat.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && <div className="p-2 bg-red-100 text-red-700 rounded text-sm">{error}</div>}

      <div>
        <label className="block text-sm font-medium mb-1">{t('pep.ugyfelNeve')}</label>
        {selectedCustomer ? (
          <div className="flex items-center justify-between p-2 border rounded bg-green-50">
            <span>
              {selectedCustomer.name}{' '}
              {selectedCustomer.customerCode ? `(${selectedCustomer.customerCode})` : ''}
            </span>
            <button
              type="button"
              onClick={() => setSelectedCustomer(null)}
              className="text-xs text-red-600"
            >
              {t('common.cancel')}
            </button>
          </div>
        ) : (
          <>
            <input
              type="text"
              value={customerSearch}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                setCustomerSearch(e.target.value)
              }
              placeholder="Ügyfél keresése név alapján..."
              className="w-full p-2 border rounded"
            />
            {customerResults.length > 0 && (
              <ul className="border rounded mt-1 max-h-40 overflow-y-auto">
                {customerResults.map((c) => (
                  <li key={c.id}>
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedCustomer(c)
                        setCustomerResults([])
                        setCustomerSearch('')
                      }}
                      className="w-full text-left p-2 hover:bg-gray-100"
                    >
                      {c.name} {c.customerCode ? `(${c.customerCode})` : ''}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </>
        )}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium mb-1">{t('common.currency')}</label>
          <select
            value={formData.currencyCode}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, currencyCode: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          >
            <option value="">{i18n.t('literals.lit-8')}</option>
            {currencies.map((c) => {
              const code = c.code || c.currencyCode || ''
              return code ? (
                <option key={code} value={code}>
                  {code}
                  {c.name ? ` – ${c.name}` : ''}
                </option>
              ) : null
            })}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('cashier.amount')}</label>
          <input
            type="number"
            step="0.01"
            value={formData.amount}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, amount: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">
            {t('reservations.garantaltArfolyam')}
          </label>
          <input
            type="number"
            step="0.0001"
            value={formData.exchangeRate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, exchangeRate: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">
            {t('reservations.ervenyessegOra')}
          </label>
          <select
            value={formData.validityHours}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, validityHours: e.target.value })
            }
            className="w-full p-2 border rounded"
          >
            <option value="4">{t('reservations.4Ora')}</option>
            <option value="8">{t('reservations.8Ora')}</option>
            <option value="24">{t('reservations.24Ora')}</option>
            <option value="48">{t('reservations.48Ora')}</option>
          </select>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium mb-1">{t('reservations.megjegyzes')}</label>
        <input
          type="text"
          value={formData.notes}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setFormData({ ...formData, notes: e.target.value })
          }
          className="w-full p-2 border rounded"
        />
      </div>

      <div className="flex justify-end gap-2">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          {t('common.cancel')}
        </button>
        <button
          type="submit"
          disabled={submitting}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
        >
          {t('common.create')}
        </button>
      </div>
    </form>
  )
}
