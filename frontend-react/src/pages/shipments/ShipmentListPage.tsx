import { useState, useEffect, useCallback } from 'react'
import { Link } from 'react-router-dom'
import { Package, Eye, CheckCircle, XCircle, AlertCircle, ArrowUpFromLine, ArrowDownToLine, Printer, Pencil, Save } from 'lucide-react'
import { shipmentRequestApi, ShipmentRequest, ShipmentUpdateRequest } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger';
import { useTranslation } from 'react-i18next'

interface ShipmentEditDraft {
  deliveryDate: string
  carrierName: string
  sealNumber: string
  notes: string
}

export default function ShipmentListPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''

  const [shipments, setShipments] = useState<ShipmentRequest[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [statusFilter, setStatusFilter] = useState<string>('SUBMITTED')
  const [selectedShipment, setSelectedShipment] = useState<ShipmentRequest | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [editDraft, setEditDraft] = useState<ShipmentEditDraft | null>(null)

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

  useEffect(() => {
    void loadShipments()
  }, [loadShipments])

  const handleApprove = async (shipmentId: string): Promise<void> => {
    if (!worker?.id) return
    if (!confirm('Biztosan jóváhagyja ezt a szállítmány igényt?')) return

    try {
      setLoading(true)
      await shipmentRequestApi.approve(shipmentId, String(worker.id))
      await loadShipments()
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('ShipmentListPage', 'Failed to approve shipment:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleReject = async (shipmentId: string): Promise<void> => {
    if (!worker?.id) return
    const reason = prompt('Elutasítás oka:')
    if (!reason) return

    try {
      setLoading(true)
      await shipmentRequestApi.reject(shipmentId, String(worker.id), reason)
      await loadShipments()
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('ShipmentListPage', 'Failed to reject shipment:', err)
    } finally {
      setLoading(false)
    }
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

  const handleDeliver = async (shipmentId: string): Promise<void> => {
    if (!confirm('Biztosan kézbesítettként jelöli ezt a szállítmány igényt?')) return

    try {
      setLoading(true)
      await shipmentRequestApi.deliver(shipmentId)
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
    if (!confirm('Biztosan visszavonja ezt a szállítmány igényt?')) return

    try {
      setLoading(true)
      await shipmentRequestApi.cancel(shipmentId)
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

  const canCancel = (status: string): boolean => status !== 'DELIVERED' && status !== 'CANCELLED'
  const canDeliver = (status: string): boolean => status === 'APPROVED' || status === 'IN_TRANSIT'
  const canEdit = (status: string): boolean => status === 'DRAFT'

  // Backend enum: DRAFT, SUBMITTED, APPROVED, IN_TRANSIT, DELIVERED, CANCELLED (ShipmentRequestStatus.java)
  const getStatusBadge = (status: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      DRAFT: { label: 'Vázlat', className: 'bg-gray-100 text-gray-700' },
      SUBMITTED: { label: 'Kérve', className: 'bg-yellow-100 text-yellow-700' },
      APPROVED: { label: 'Jóváhagyva', className: 'bg-green-100 text-green-700' },
      IN_TRANSIT: { label: 'Úton', className: 'bg-indigo-100 text-indigo-700' },
      DELIVERED: { label: 'Kézbesítve', className: 'bg-green-100 text-green-700' },
      CANCELLED: { label: 'Megszakítva', className: 'bg-red-100 text-red-700' }
    }
    const statusInfo = statusMap[status] || { label: status, className: 'bg-gray-100 text-gray-700' }
    return (
      <span className={`px-2 py-1 text-xs rounded ${statusInfo.className}`}>
        {statusInfo.label}
      </span>
    )
  }

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
            Új ÁTADÁS
          </Link>
          <Link
            to="/shipments/new?direction=inbound"
            className="form-button-primary flex items-center gap-2"
            title="Új készpénz ÁTVÉTEL — Pénztárból az Értéktárba"
          >
            <ArrowDownToLine size={16} />
            Új ÁTVÉTEL
          </Link>
        </div>
      </div>

      {/* Filters */}
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
              <option value="APPROVED">{t('shipments.jovahagyva')}</option>
              <option value="IN_TRANSIT">{t('shipments.uton')}</option>
              <option value="DELIVERED">{t('shipments.kezbesitve')}</option>
              <option value="CANCELLED">{t('shipments.megszakitva')}</option>
            </select>
          </div>
          <button
            onClick={loadShipments}
            className="form-button"
            disabled={loading}
          >
            {t('common.refresh')}
          </button>
        </div>
      </div>

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
                {t('shipments.szallitmanyReszletei', { requestNumber: selectedShipment.requestNumber })}
              </h2>
              <p className="text-sm text-blue-900">
                {selectedShipment.requestingBranchName || selectedShipment.requestingBranchId} → {selectedShipment.targetBranchName || selectedShipment.targetBranchId}
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
            <DetailLine label="Kézbesítés" value={formatDate(selectedShipment.requestedDeliveryDate)} />
            <DetailLine label="Szállító" value={selectedShipment.carrierName || '-'} />
            <DetailLine label="Plomba" value={selectedShipment.sealNumber || '-'} />
          </div>
          {selectedShipment.notes && (
            <div className="mt-3 rounded border border-blue-100 bg-white px-3 py-2 text-sm text-blue-950">
              {selectedShipment.notes}
            </div>
          )}
          {canEdit(selectedShipment.requestStatus) && (
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
                        onChange={(event) => setEditDraft({ ...editDraft, deliveryDate: event.target.value })}
                      />
                    </label>
                    <label className="form-label">
                      {t('shipments.szallito')}
                      <input
                        type="text"
                        className="form-input mt-1"
                        value={editDraft.carrierName}
                        data-testid="shipment-edit-carrier"
                        onChange={(event) => setEditDraft({ ...editDraft, carrierName: event.target.value })}
                      />
                    </label>
                    <label className="form-label">
                      {t('shipments.plomba')}
                      <input
                        type="text"
                        className="form-input mt-1"
                        value={editDraft.sealNumber}
                        data-testid="shipment-edit-seal"
                        onChange={(event) => setEditDraft({ ...editDraft, sealNumber: event.target.value })}
                      />
                    </label>
                  </div>
                  <label className="form-label block">
                    {t('common.note')}
                    <textarea
                      className="form-input mt-1 min-h-20"
                      value={editDraft.notes}
                      data-testid="shipment-edit-notes"
                      onChange={(event) => setEditDraft({ ...editDraft, notes: event.target.value })}
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
                      <td className="text-right">{formatAmount(item.requestedAmount ?? item.amount)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {loading ? (
        <div className="form-panel text-center py-8 text-gray-500">
          Betöltés...
        </div>
      ) : shipments.length === 0 ? (
        <div className="form-panel text-center py-8 text-gray-500">
          {t('shipments.nincsenekSzallitmanyigenyek')}
        </div>
      ) : (
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
            <tbody>
              {shipments.map((shipment) => (
                <tr key={shipment.id}>
                  <td className="font-mono font-semibold">{shipment.requestNumber}</td>
                  <td>{shipment.requestingBranchName}</td>
                  <td>{shipment.targetBranchName}</td>
                  <td>
                    {new Date(shipment.requestedDeliveryDate).toLocaleDateString('hu-HU')}
                  </td>
                  <td>{getStatusBadge(shipment.requestStatus)}</td>
                  <td className="text-sm text-gray-600">
                    <div>{shipment.requestedByWorkerName}</div>
                    <div className="text-xs">
                      {new Date(shipment.requestedAt).toLocaleString('hu-HU')}
                    </div>
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
                      {shipment.requestStatus === 'SUBMITTED' && (
                        <>
                          <button
                            onClick={() => handleApprove(shipment.id)}
                            className="toolbar-button text-green-600"
                            title="Jóváhagyás"
                            disabled={loading}
                          >
                            <CheckCircle size={14} />
                          </button>
                          <button
                            onClick={() => handleReject(shipment.id)}
                            className="toolbar-button text-red-600"
                            title="Elutasítás"
                            disabled={loading}
                          >
                            <XCircle size={14} />
                          </button>
                        </>
                      )}
                      {canDeliver(shipment.requestStatus) && (
                        <button
                          onClick={() => void handleDeliver(shipment.id)}
                          className="toolbar-button text-blue-600"
                          title="Kézbesítés"
                          disabled={loading}
                        >
                          <Package size={14} />
                        </button>
                      )}
                      {canCancel(shipment.requestStatus) && (
                        <button
                          onClick={() => void handleCancel(shipment.id)}
                          className="toolbar-button text-red-700"
                          title="Visszavonás"
                          disabled={loading}
                        >
                          <XCircle size={14} />
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
  )
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

