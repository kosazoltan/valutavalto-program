import { useState, useEffect, useCallback } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { Package, Plus, Eye, CheckCircle, XCircle, AlertCircle } from 'lucide-react'
import { shipmentRequestApi, ShipmentRequest } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger';
import { useTranslation } from 'react-i18next'

export default function ShipmentListPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''

  const [shipments, setShipments] = useState<ShipmentRequest[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [statusFilter, setStatusFilter] = useState<string>('SUBMITTED')

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

  const formatDate = (value?: string): string => {
    if (!value) return '-'
    const date = new Date(value)
    return Number.isNaN(date.getTime()) ? '-' : date.toLocaleDateString('hu-HU')
  }

  const formatDateTime = (value?: string): string => {
    if (!value) return '-'
    const date = new Date(value)
    return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString('hu-HU')
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Package />
          {t('shipments.atadasAtvetelSzallitmanyigenyek')}
        </h1>
        <Link
          to="/shipments/new"
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          {t('shipments.ujSzallitmanyigeny')}
        </Link>
      </div>

      {/* Filters */}
      <div className="form-panel">
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
                <th className="w-32">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {shipments.map((shipment) => (
                <tr key={shipment.id}>
                  <td className="font-mono font-semibold">{shipment.requestNumber ?? '-'}</td>
                  <td>{shipment.requestingBranchName ?? shipment.requestingBranchId ?? '-'}</td>
                  <td>{shipment.targetBranchName ?? shipment.targetBranchId ?? '-'}</td>
                  <td>
                    {formatDate(shipment.requestedDeliveryDate)}
                  </td>
                  <td>{getStatusBadge(shipment.requestStatus ?? '-')}</td>
                  <td className="text-sm text-gray-600">
                    <div>{shipment.requestedByWorkerName ?? shipment.requestedByWorkerId ?? '-'}</div>
                    <div className="text-xs">
                      {formatDateTime(shipment.requestedAt)}
                    </div>
                  </td>
                  <td>
                    <div className="flex gap-1">
                      <button
                        onClick={() => navigate(`/shipments/${shipment.id}`)}
                        className="toolbar-button"
                        title="Részletek"
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
                      {shipment.requestStatus === 'APPROVED' && (
                        <button
                          onClick={() => navigate(`/shipments/${shipment.id}/prepare`)}
                          className="toolbar-button text-blue-600"
                          title="Előkészítés"
                        >
                          <Package size={14} />
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

