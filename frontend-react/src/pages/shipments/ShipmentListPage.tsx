import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { Link } from 'react-router-dom'
import {
  Package,
  Eye,
  XCircle,
  AlertCircle,
  ArrowUpFromLine,
  ArrowDownToLine,
  Printer,
  Pencil,
  Save,
} from 'lucide-react'
import {
  shipmentRequestApi,
  ShipmentRequest,
  ShipmentUpdateRequest,
} from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import { ReceiptPreviewModal } from '../../components/electron'
import { isElectron } from '../../utils/electron'
import { toast } from '../../components/ui/toaster'
import { getCompanyType } from '../../utils/localQueue'
import type { PrintReceiptData } from '../../types/receipt'
import ShipmentCalendarPanel from './ShipmentCalendarPanel'
import StaleShipmentConfirmDialog from '../../components/shipments/StaleShipmentConfirmDialog'
import i18n from '../../i18n'

interface ShipmentEditDraft {
  deliveryDate: string
  carrierName: string
  sealNumber: string
  notes: string
}

type ShipmentTab = 'today' | 'past'

const CANCELLABLE_STATUSES = new Set(['DRAFT', 'SUBMITTED', 'APPROVED', 'IN_TRANSIT'])

/** A `requestedDeliveryDate` (LocalDate vagy ISO datetime) → 'YYYY-MM-DD'. */
function dateOnly(value: string | undefined): string {
  return value ? value.slice(0, 10) : ''
}

/** A mai nap 'YYYY-MM-DD' Europe/Budapest időzóna szerint (NFR-4). */
function budapestToday(): string {
  return new Intl.DateTimeFormat('sv-SE', { timeZone: 'Europe/Budapest' }).format(new Date())
}

export default function ShipmentListPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''
  const today = useMemo(() => budapestToday(), [])

  const [activeTab, setActiveTab] = useState<ShipmentTab>('today')
  const [shipments, setShipments] = useState<ShipmentRequest[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [statusFilter, setStatusFilter] = useState<string>('SUBMITTED')
  const [selectedShipment, setSelectedShipment] = useState<ShipmentRequest | null>(null)
  const [staleConfirmShipment, setStaleConfirmShipment] = useState<ShipmentRequest | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [editDraft, setEditDraft] = useState<ShipmentEditDraft | null>(null)
  const deliveryKeysRef = useRef(new Map<string, string>())

  // "Korábbi" fül (FR-5..FR-11): teljes (összes státuszú) lista a naptárhoz + napi listához.
  const [allShipments, setAllShipments] = useState<ShipmentRequest[]>([])
  const [pastLoading, setPastLoading] = useState(false)
  const [selectedDate, setSelectedDate] = useState<string | null>(null)

  // Újranyomtatás (FR-11): a meglévő ReceiptPreviewModal újrafelhasználása.
  const [reprintReceipt, setReprintReceipt] = useState<PrintReceiptData | null>(null)
  const [reprintLoadingId, setReprintLoadingId] = useState<string | null>(null)

  const loadShipments = useCallback(async (): Promise<void> => {
    try {
      setLoading(true)
      let data: ShipmentRequest[]
      if (statusFilter) {
        data = await shipmentRequestApi.findByStatus(statusFilter)
      } else if (branchId) {
        data = await shipmentRequestApi.findByBranch(branchId)
      } else {
        data = []
      }
      setShipments(data)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('ShipmentListPage', 'Failed to load shipments:', err)
    } finally {
      setLoading(false)
    }
  }, [statusFilter, branchId])

  // "Korábbi" fül adatforrása: a saját telephely ÖSSZES (státusztól független) bizonylata,
  // lapozva (findByBranch nem 100-cap-elt), hogy a naptár aktív napjai teljesek legyenek.
  const loadAllShipments = useCallback(async (): Promise<void> => {
    try {
      setPastLoading(true)
      const data = branchId
        ? await shipmentRequestApi.findByBranch(branchId)
        : await shipmentRequestApi.findByStatus('')
      setAllShipments(data)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('ShipmentListPage', 'Failed to load past shipments:', err)
    } finally {
      setPastLoading(false)
    }
  }, [branchId])

  useEffect(() => {
    void loadShipments()
  }, [loadShipments])

  useEffect(() => {
    if (activeTab === 'past') void loadAllShipments()
  }, [activeTab, loadAllShipments])

  const handleTabChange = (tab: ShipmentTab): void => {
    setActiveTab(tab)
    setSelectedShipment(null)
    setEditDraft(null)
    setSelectedDate(null)
  }

  const handleOpenDetails = async (shipmentId: string): Promise<void> => {
    try {
      setDetailLoadingId(shipmentId)
      setError(null)
      setSelectedShipment(await shipmentRequestApi.get(shipmentId))
      setEditDraft(null)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('ShipmentListPage', 'Failed to load shipment details:', err)
    } finally {
      setDetailLoadingId(null)
    }
  }

  const handleDeliver = async (
    shipment: ShipmentRequest,
    confirmedStale = false,
  ): Promise<void> => {
    if (shipment.staleForDelivery === true && !confirmedStale) {
      setStaleConfirmShipment(shipment)
      return
    }
    if (!confirmedStale && !confirm('Biztosan kézbesítettként jelöli ezt a szállítmány igényt?'))
      return
    const idempotencyKey =
      deliveryKeysRef.current.get(shipment.id) ?? globalThis.crypto.randomUUID()
    deliveryKeysRef.current.set(shipment.id, idempotencyKey)

    try {
      setLoading(true)
      if (confirmedStale) {
        await shipmentRequestApi.deliver(shipment.id, idempotencyKey, { confirmedStale: true })
      } else {
        await shipmentRequestApi.deliver(shipment.id, idempotencyKey)
      }
      deliveryKeysRef.current.delete(shipment.id)
      await loadShipments()
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('ShipmentListPage', 'Failed to deliver shipment:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleCancel = async (shipmentId: string): Promise<void> => {
    // FR-13: a gomb felirata "Sztornó"; a handler logikája változatlan (cancel endpoint).
    if (!confirm('Biztosan sztornózza ezt a szállítmány igényt?')) return

    try {
      setLoading(true)
      setError(null)
      const cancelled = await shipmentRequestApi.cancel(shipmentId)
      try {
        setReprintReceipt(buildStornoReceiptData(cancelled, worker))
      } catch (receiptError) {
        toast.success(
          'Sztornó sikeres',
          'A bizonylat most nem készíthető el; a bizonylat később újranyomtatható.',
        )
        logger.warn(
          'ShipmentListPage',
          'Cancelled shipment receipt data is incomplete:',
          receiptError,
        )
      }
      await loadShipments()
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('ShipmentListPage', 'Failed to cancel shipment:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleStartEdit = (shipment: ShipmentRequest): void => {
    setEditDraft({
      deliveryDate: dateInputValue(shipment.requestedDeliveryDate),
      carrierName: shipment.carrierName || '',
      sealNumber: shipment.sealNumber || '',
      notes: shipment.notes || '',
    })
  }

  const handleSaveEdit = async (): Promise<void> => {
    if (!selectedShipment || !editDraft) return
    if (selectedShipment.requestStatus !== 'DRAFT') {
      setError('Csak vázlat szállítmánykérés módosítható.')
      return
    }

    try {
      setLoading(true)
      setError(null)
      const payload: ShipmentUpdateRequest = {
        fromBranchId: selectedShipment.requestingBranchId || selectedShipment.sourceBranchId || '',
        toBranchId: selectedShipment.targetBranchId,
        deliveryDate: editDraft.deliveryDate || undefined,
        carrierName: editDraft.carrierName,
        sealNumber: editDraft.sealNumber,
        notes: editDraft.notes,
      }
      const updated = await shipmentRequestApi.update(selectedShipment.id, payload)
      setSelectedShipment(updated)
      setEditDraft(null)
      await loadShipments()
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('ShipmentListPage', 'Failed to update shipment:', err)
    } finally {
      setLoading(false)
    }
  }

  // FR-11: elveszett bizonylat újranyomtatása — friss GET /shipments/{id} (cross-tenant: idegen
  // tenant id-re a backend 404-et ad, ezt hibaként kezeljük), majd a meglévő ReceiptPreviewModal.
  const handleReprint = async (shipmentId: string): Promise<void> => {
    try {
      setReprintLoadingId(shipmentId)
      setError(null)
      const shipment = await shipmentRequestApi.get(shipmentId)
      setReprintReceipt(
        shipment.requestStatus === 'CANCELLED'
          ? buildStornoReceiptData(shipment, worker)
          : buildReprintReceiptData(shipment, worker),
      )
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      toast.error('Bizonylat betöltése sikertelen', errorMessage)
      logger.error('ShipmentListPage', 'Failed to load shipment for reprint:', err)
    } finally {
      setReprintLoadingId(null)
    }
  }

  const handleReprintPrint = async (): Promise<void> => {
    if (!reprintReceipt) return
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
      const ok = await window.electronAPI.printReceipt(JSON.stringify(reprintReceipt))
      if (ok)
        toast.success('Nyomtatás elindítva', `Bizonylat: ${reprintReceipt.receiptNumber ?? '—'}`)
      else toast.error('Nyomtatás sikertelen', 'A nyomtató nem válaszolt.')
    } catch (e) {
      toast.error('Nyomtatás hiba', getErrorMessage(e))
    }
  }

  const canCancel = (shipment: ShipmentRequest): boolean =>
    shipment.requestingBranchId === branchId && CANCELLABLE_STATUSES.has(shipment.requestStatus)
  // FR-6 (Értéktár Shipment készletkönyvelés): a "Megérkezett" (DELIVERED visszaigazolás) gombot
  // KIZÁRÓLAG az ÁTVEVŐ (target) fiók felhasználója láthatja — az átadó nem. A backend FR-4
  // hard-gate-je (403 VV-AUTH-001 az assertReceiver-ben) ezt amúgy is kikényszeríti; itt a UI-t
  // igazítjuk hozzá, hogy az átadónak a gomb meg se jelenjen (teljesen elrejtve, nem csak disabled).
  const canDeliver = (shipment: ShipmentRequest): boolean =>
    (shipment.requestStatus === 'SUBMITTED' ||
      shipment.requestStatus === 'APPROVED' ||
      shipment.requestStatus === 'IN_TRANSIT') &&
    shipment.targetBranchId === branchId
  const canEdit = (status: string): boolean => status === 'DRAFT'

  // Backend enum: DRAFT, SUBMITTED, APPROVED, IN_TRANSIT, DELIVERED, CANCELLED, REJECTED (ShipmentRequestStatus.java)
  const getStatusBadge = (status: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      DRAFT: { label: 'Vázlat', className: 'bg-gray-100 text-gray-700' },
      SUBMITTED: { label: 'Kérve', className: 'bg-yellow-100 text-yellow-700' },
      APPROVED: { label: 'Jóváhagyva', className: 'bg-green-100 text-green-700' },
      IN_TRANSIT: { label: 'Úton', className: 'bg-indigo-100 text-indigo-700' },
      DELIVERED: { label: 'Kézbesítve', className: 'bg-green-100 text-green-700' },
      CANCELLED: { label: 'Megszakítva', className: 'bg-red-100 text-red-700' },
      REJECTED: { label: 'Elutasítva', className: 'bg-red-100 text-red-700' },
    }
    const statusInfo = statusMap[status] || {
      label: status,
      className: 'bg-gray-100 text-gray-700',
    }
    return (
      <span className={`px-2 py-1 text-xs rounded ${statusInfo.className}`}>
        {statusInfo.label}
      </span>
    )
  }

  // "Ma" fül: csak a mai (Europe/Budapest) requestedDeliveryDate-ű bizonylatok (FR-2).
  const todaysShipments = useMemo(
    () => shipments.filter((s) => dateOnly(s.requestedDeliveryDate) === today),
    [shipments, today],
  )

  // Bizonylatos napok a naptárhoz (FR-7): az összes bizonylat requestedDeliveryDate-jéből.
  const activeDates = useMemo(() => {
    const set = new Set<string>()
    for (const s of allShipments) {
      const d = dateOnly(s.requestedDeliveryDate)
      if (d) set.add(d)
    }
    return set
  }, [allShipments])

  // "Korábbi" fül: a kiválasztott nap összes bizonylata, státusztól függetlenül (FR-8).
  const pastDayShipments = useMemo(
    () =>
      selectedDate
        ? allShipments.filter((s) => dateOnly(s.requestedDeliveryDate) === selectedDate)
        : [],
    [allShipments, selectedDate],
  )

  const renderRow = (shipment: ShipmentRequest, mode: ShipmentTab) => (
    <tr key={shipment.id}>
      <td className="font-mono font-semibold">{shipment.requestNumber}</td>
      <td>{shipment.requestingBranchName}</td>
      <td>{shipment.targetBranchName}</td>
      <td>{new Date(shipment.requestedDeliveryDate).toLocaleDateString('hu-HU')}</td>
      <td>{getStatusBadge(shipment.requestStatus)}</td>
      <td className="text-sm text-gray-600">
        <div>{shipment.requestedByWorkerName}</div>
        <div className="text-xs">{new Date(shipment.requestedAt).toLocaleString('hu-HU')}</div>
      </td>
      <td className="no-print">
        <div className="flex gap-1">
          <button
            onClick={() => void handleOpenDetails(shipment.id)}
            className="toolbar-button"
            title="Részletek"
            disabled={detailLoadingId === shipment.id}
          >
            <Eye size={14} />
          </button>
          {mode === 'today' ? (
            <>
              {canDeliver(shipment) && (
                <button
                  onClick={() => void handleDeliver(shipment)}
                  className="toolbar-button text-blue-600"
                  title="Megérkezett"
                  disabled={loading}
                >
                  <Package size={14} />
                </button>
              )}
              {canCancel(shipment) && (
                <button
                  onClick={() => void handleCancel(shipment.id)}
                  className="toolbar-button text-red-700"
                  title={t('shipments.sztorno')}
                  disabled={loading}
                >
                  <XCircle size={14} />
                </button>
              )}
            </>
          ) : (
            <>
              <button
                onClick={() => void handleReprint(shipment.id)}
                className="toolbar-button text-blue-700"
                title={t('shipments.ujranyomtatas')}
                disabled={reprintLoadingId === shipment.id}
              >
                <Printer size={14} />
              </button>
              {canCancel(shipment) && (
                <button
                  onClick={() => void handleCancel(shipment.id)}
                  className="toolbar-button text-red-700"
                  title={t('shipments.sztorno')}
                  disabled={loading}
                >
                  <XCircle size={14} />
                </button>
              )}
            </>
          )}
        </div>
      </td>
    </tr>
  )

  const renderTable = (rows: ShipmentRequest[], mode: ShipmentTab) => (
    <div className="form-panel p-0">
      <table className="data-grid w-full">
        <thead>
          <tr>
            <th>{t('shipments.igenySzam')}</th>
            <th>{t('shipments.keroFiok')}</th>
            <th>{t('shipments.celFiok')}</th>
            <th>{t('shipments.kezbesitesiDatum')}</th>
            <th>{t('common.status')}</th>
            <th>{t('shipments.kerve')}</th>
            <th className="no-print w-32">{t('common.actions')}</th>
          </tr>
        </thead>
        <tbody>{rows.map((shipment) => renderRow(shipment, mode))}</tbody>
      </table>
    </div>
  )

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Package />
          {t('shipments.atadasAtvetelSzallitmanyigenyek')}
        </h1>
        {/* Bali Henriett (2026-05-27) kérés A.: az átadás és az átvétel TELJESEN
            különváltan indítható — két különálló gomb, mint a legacy Anti rendszerben
            ("Pénztárak közötti pénzforgalom főmenüje"). A direction URL-paramétert a
            ShipmentNewPage olvassa és az értéktár-szereplőt zárolja (B+C követő PR). */}
        <div className="no-print flex gap-2">
          <button
            onClick={() => window.print()}
            className="form-button flex items-center gap-2"
            title={t('common.print')}
          >
            <Printer size={16} />
            {t('common.print')}
          </button>
          <Link
            to="/shipments/new?direction=outbound"
            className="form-button-primary flex items-center gap-2"
            title="Új készpénz ÁTADÁS — Értéktárból a Pénztárnak"
          >
            <ArrowUpFromLine size={16} />
            {i18n.t('literals.uj-atadas')}
          </Link>
          <Link
            to="/shipments/new?direction=inbound"
            className="form-button-primary flex items-center gap-2"
            title="Új készpénz ÁTVÉTEL — Pénztárból az Értéktárba"
          >
            <ArrowDownToLine size={16} />
            {i18n.t('literals.uj-atvetel')}
          </Link>
        </div>
      </div>

      {/* FR-1: kétfüles navigáció — alapból "Ma". */}
      <div className="no-print flex gap-1 border-b border-gray-200">
        <button
          type="button"
          onClick={() => handleTabChange('today')}
          data-testid="shipment-tab-today"
          className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px ${
            activeTab === 'today'
              ? 'border-blue-600 text-blue-700'
              : 'border-transparent text-gray-500 hover:text-gray-700'
          }`}
        >
          {t('shipments.ma')}
        </button>
        <button
          type="button"
          onClick={() => handleTabChange('past')}
          data-testid="shipment-tab-past"
          className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px ${
            activeTab === 'past'
              ? 'border-blue-600 text-blue-700'
              : 'border-transparent text-gray-500 hover:text-gray-700'
          }`}
        >
          {t('shipments.korabbi')}
        </button>
      </div>

      {/* FR-3: státuszszűrő CSAK a "Ma" fülön (FR-10: a "Korábbi" fülön nincs). */}
      {activeTab === 'today' && (
        <div className="no-print form-panel">
          <div className="flex gap-3 items-end">
            <div>
              <label className="form-label">{t('common.status')}</label>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="form-input"
              >
                <option value="">{t('common.all')}</option>
                <option value="DRAFT">{t('shipments.vazlat')}</option>
                <option value="SUBMITTED">{t('shipments.kerve')}</option>
                <option value="IN_TRANSIT">{t('shipments.uton')}</option>
                <option value="DELIVERED">{t('shipments.kezbesitve')}</option>
                <option value="REJECTED">{t('shipments.elutasitva')}</option>
                <option value="CANCELLED">{t('shipments.megszakitva')}</option>
              </select>
            </div>
            <button onClick={loadShipments} className="form-button" disabled={loading}>
              {t('common.refresh')}
            </button>
          </div>
        </div>
      )}

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      {selectedShipment && (
        <div className="form-panel border-blue-200 bg-blue-50" data-testid="shipment-detail-panel">
          <div className="mb-3 flex items-start justify-between gap-3">
            <div>
              <h2 className="text-base font-bold text-blue-950">
                {t('shipments.szallitmanyReszletei', {
                  requestNumber: selectedShipment.requestNumber,
                })}
              </h2>
              <p className="text-sm text-blue-900">
                {selectedShipment.requestingBranchName || selectedShipment.requestingBranchId}
                {i18n.t('literals.lit-37')}{' '}
                {selectedShipment.targetBranchName || selectedShipment.targetBranchId}
              </p>
            </div>
            <button
              type="button"
              onClick={() => setSelectedShipment(null)}
              className="form-button text-xs"
            >
              {t('common.close')}
            </button>
          </div>
          <div className="grid gap-2 text-sm md:grid-cols-4">
            <DetailLine label="Státusz" value={selectedShipment.requestStatus} />
            <DetailLine
              label="Kézbesítés"
              value={formatDate(selectedShipment.requestedDeliveryDate)}
            />
            <DetailLine label="Szállító" value={selectedShipment.carrierName || '-'} />
            <DetailLine label="Plomba" value={selectedShipment.sealNumber || '-'} />
          </div>
          {selectedShipment.notes && (
            <div className="mt-3 rounded border border-blue-100 bg-white px-3 py-2 text-sm text-blue-950">
              {selectedShipment.notes}
            </div>
          )}
          {/* A szerkesztés csak a "Ma" fül operatív munkafolyamatához tartozik (DRAFT). */}
          {activeTab === 'today' && canEdit(selectedShipment.requestStatus) && (
            <div className="mt-3 border-t border-blue-100 pt-3">
              {editDraft ? (
                <div className="space-y-3 rounded border border-blue-100 bg-white p-3">
                  <div className="grid gap-3 md:grid-cols-3">
                    <label className="form-label">
                      {t('shipments.kezbesitesiDatum')}
                      <input
                        type="date"
                        className="form-input mt-1"
                        value={editDraft.deliveryDate}
                        data-testid="shipment-edit-delivery-date"
                        onChange={(event) =>
                          setEditDraft({ ...editDraft, deliveryDate: event.target.value })
                        }
                      />
                    </label>
                    <label className="form-label">
                      {t('shipments.szallito')}
                      <input
                        type="text"
                        className="form-input mt-1"
                        value={editDraft.carrierName}
                        data-testid="shipment-edit-carrier"
                        onChange={(event) =>
                          setEditDraft({ ...editDraft, carrierName: event.target.value })
                        }
                      />
                    </label>
                    <label className="form-label">
                      {t('shipments.plomba')}
                      <input
                        type="text"
                        className="form-input mt-1"
                        value={editDraft.sealNumber}
                        data-testid="shipment-edit-seal"
                        onChange={(event) =>
                          setEditDraft({ ...editDraft, sealNumber: event.target.value })
                        }
                      />
                    </label>
                  </div>
                  <label className="form-label block">
                    {t('common.note')}
                    <textarea
                      className="form-input mt-1 min-h-20"
                      value={editDraft.notes}
                      data-testid="shipment-edit-notes"
                      onChange={(event) =>
                        setEditDraft({ ...editDraft, notes: event.target.value })
                      }
                    />
                  </label>
                  <div className="flex gap-2">
                    <button
                      type="button"
                      className="form-button-primary"
                      data-testid="shipment-save-edit"
                      onClick={() => void handleSaveEdit()}
                      disabled={loading}
                    >
                      <Save size={16} />
                      {t('common.save')}
                    </button>
                    <button
                      type="button"
                      className="form-button"
                      onClick={() => setEditDraft(null)}
                      disabled={loading}
                    >
                      {t('common.cancel')}
                    </button>
                  </div>
                </div>
              ) : (
                <button
                  type="button"
                  className="form-button"
                  title={t('common.edit')}
                  data-testid="shipment-start-edit"
                  onClick={() => handleStartEdit(selectedShipment)}
                >
                  <Pencil size={16} />
                  {t('common.edit')}
                </button>
              )}
            </div>
          )}
          {selectedShipment.items && selectedShipment.items.length > 0 && (
            <div className="mt-3 overflow-x-auto">
              <table className="data-grid w-full bg-white text-sm">
                <thead>
                  <tr>
                    <th>{t('common.currency')}</th>
                    <th className="text-right">{t('common.amount')}</th>
                  </tr>
                </thead>
                <tbody>
                  {selectedShipment.items.map((item) => (
                    <tr key={item.id ?? `${item.currencyId}-${item.requestedAmount}`}>
                      <td>{item.currencyCode ?? item.currencyId}</td>
                      <td className="text-right">
                        {formatAmount(item.requestedAmount ?? item.amount)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* FR-2..FR-4: "Ma" fül — csak aznapi bizonylatok, teljes műveleti paletta. */}
      {activeTab === 'today' &&
        (loading ? (
          <div className="form-panel text-center py-8 text-gray-500">
            {i18n.t('literals.betoltes')}
          </div>
        ) : todaysShipments.length === 0 ? (
          <div className="form-panel text-center py-8 text-gray-500">
            {t('shipments.nincsenekSzallitmanyigenyek')}
          </div>
        ) : (
          renderTable(todaysShipments, 'today')
        ))}

      {/* FR-5..FR-11: "Korábbi" fül — bal naptár, jobb napi lista (csak megtekintés + újranyomtatás). */}
      {activeTab === 'past' && (
        <div className="grid gap-4 md:grid-cols-5">
          <div className="md:col-span-2">
            <ShipmentCalendarPanel
              activeDates={activeDates}
              selectedDate={selectedDate}
              onSelectDate={setSelectedDate}
              today={today}
            />
          </div>
          <div className="md:col-span-3">
            {pastLoading ? (
              <div className="form-panel text-center py-8 text-gray-500">
                {i18n.t('literals.betoltes')}
              </div>
            ) : !selectedDate ? (
              <div
                className="form-panel text-center py-8 text-gray-500"
                data-testid="past-empty-state"
              >
                {t('shipments.valasszonNapotANaptarbol')}
              </div>
            ) : pastDayShipments.length === 0 ? (
              <div className="form-panel text-center py-8 text-gray-500">
                {t('shipments.nincsenekSzallitmanyigenyek')}
              </div>
            ) : (
              renderTable(pastDayShipments, 'past')
            )}
          </div>
        </div>
      )}

      <ReceiptPreviewModal
        isOpen={reprintReceipt !== null}
        onClose={() => setReprintReceipt(null)}
        receiptData={reprintReceipt}
        qrCodeDataUrl={null}
        allowPrint={isElectron()}
        printLabel={t('shipments.ujranyomtatas')}
        onPrint={handleReprintPrint}
        variant="official"
      />
      {staleConfirmShipment && (
        <StaleShipmentConfirmDialog
          shipment={staleConfirmShipment}
          onCancel={() => setStaleConfirmShipment(null)}
          onConfirm={() => {
            const shipment = staleConfirmShipment
            setStaleConfirmShipment(null)
            void handleDeliver(shipment, true)
          }}
        />
      )}
    </div>
  )
}

/** Egy ShipmentRequest → PrintReceiptData az újranyomtatáshoz (FR-11). A szállítmány-IGÉNY
 *  nem perzisztál HUF-ot/árfolyamot, ezért a bizonylat best-effort: tételsorok + fejléc-adatok. */
function buildReprintReceiptData(
  s: ShipmentRequest,
  worker: Parameters<typeof getCompanyType>[0],
): PrintReceiptData {
  const requestedAt = s.requestedAt || ''
  const branchLabel = (code?: string, name?: string): string => {
    const normalizedCode = code?.trim()
    const normalizedName = name?.trim()
    if (normalizedCode && normalizedName) return `${normalizedCode} - ${normalizedName}`
    return normalizedName || normalizedCode || ''
  }
  const lines = (s.items ?? []).map((i) => ({
    currencyCode: i.currencyCode ?? String(i.currencyId ?? ''),
    amount: Number(i.requestedAmount ?? i.amount ?? 0),
  }))
  return {
    type: 'transfer',
    companyType: getCompanyType(worker),
    receiptNumber: s.requestNumber || s.id,
    branchCode: branchLabel(
      s.fromBranchCode,
      s.fromBranchName || s.requestingBranchName || s.sourceBranchName,
    ),
    cashierName: s.requestedByWorkerName || '',
    date: requestedAt.slice(0, 10) || dateOnly(s.requestedDeliveryDate),
    time: requestedAt.length >= 19 ? requestedAt.slice(11, 19) : '',
    deliveryDate: dateOnly(s.requestedDeliveryDate) || undefined,
    transferTarget: branchLabel(s.toBranchCode, s.toBranchName || s.targetBranchName),
    vaultAddress: s.vaultAddress,
    vaultPhone: s.vaultPhone,
    transferNote: s.notes || undefined,
    carrierName: s.carrierName || undefined,
    sealNumber: s.sealNumber || undefined,
    transferDocType:
      s.requestStatus === 'DELIVERED' && worker?.branchId === s.targetBranchId
        ? 'receipt'
        : 'handover',
    transferLines: lines.length > 0 ? lines : undefined,
    currencyCode: lines[0]?.currencyCode,
    foreignAmount: lines[0]?.amount,
  }
}

function buildStornoReceiptData(
  shipment: ShipmentRequest,
  worker: Parameters<typeof getCompanyType>[0],
): PrintReceiptData {
  const receipt = buildReprintReceiptData(shipment, worker)
  const cancelledAt = shipment.cancelledAt?.trim()
  const cancelledByWorkerName = shipment.cancelledByWorkerName?.trim()
  if (!cancelledAt || !cancelledByWorkerName) {
    throw new Error('A sztornó-bizonylat hiteles auditadatai hiányoznak (sztornózó vagy időpont).')
  }
  const cancelledDate = new Date(cancelledAt)
  if (Number.isNaN(cancelledDate.getTime())) {
    throw new Error('A sztornó-bizonylat hiteles auditadatai hiányoznak (érvénytelen időpont).')
  }
  return {
    ...receipt,
    receiptNumber: `${shipment.requestNumber || shipment.id}-SZ`,
    cashierName: cancelledByWorkerName,
    date: cancelledDate.toLocaleDateString('hu-HU'),
    time: cancelledDate.toLocaleTimeString('hu-HU', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    }),
    isStorno: true,
    stornoReason: 'Küldői sztornó átvétel előtt',
  }
}

function dateInputValue(value: string | undefined): string {
  if (!value) return ''
  if (!value.includes('T')) return value
  const [datePart] = value.split('T')
  return datePart || value
}

function DetailLine({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded border border-blue-100 bg-white px-3 py-2">
      <div className="text-xs text-blue-700">{label}</div>
      <div className="mt-0.5 break-words font-semibold text-blue-950">{value}</div>
    </div>
  )
}

function formatDate(value: string | undefined): string {
  if (!value) return '-'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleDateString('hu-HU')
}

function formatAmount(value: number | undefined): string {
  return (value ?? 0).toLocaleString('hu-HU')
}
