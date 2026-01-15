import { useState, useEffect } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { Package, Plus, Eye, CheckCircle, XCircle, AlertCircle } from 'lucide-react'
import { shipmentRequestApi, ShipmentRequest } from '../../services/api'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'

export default function ShipmentListPage() {
  const navigate = useNavigate()
  const worker = useAuthStore((state) => state.worker)
  const branchId = worker?.branchId || ''

  const [shipments, setShipments] = useState<ShipmentRequest[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [statusFilter, setStatusFilter] = useState<string>('REQUESTED')

  useEffect(() => {
    let mounted = true

    const load = async (): Promise<void> => {
      await loadShipments()
    }

    load().catch(err => {
      if (mounted) {
        console.error('Failed to load shipments:', err)
      }
    })

    return () => {
      mounted = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter, branchId])

  const loadShipments = async (): Promise<void> => {
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
      console.error('Failed to load shipments:', err)
    } finally {
      setLoading(false)
    }
  }

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
      console.error('Failed to approve shipment:', err)
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
      console.error('Failed to reject shipment:', err)
    } finally {
      setLoading(false)
    }
  }

  const getStatusBadge = (status: string) => {
    const statusMap: Record<string, { label: string; className: string }> = {
      REQUESTED: { label: 'Kérve', className: 'bg-yellow-100 text-yellow-700' },
      APPROVED: { label: 'Jóváhagyva', className: 'bg-green-100 text-green-700' },
      REJECTED: { label: 'Elutasítva', className: 'bg-red-100 text-red-700' },
      PREPARING: { label: 'Előkészítés', className: 'bg-blue-100 text-blue-700' },
      READY_FOR_PICKUP: { label: 'Átvételre kész', className: 'bg-purple-100 text-purple-700' },
      IN_TRANSIT: { label: 'Úton', className: 'bg-indigo-100 text-indigo-700' },
      DELIVERED: { label: 'Kézbesítve', className: 'bg-green-100 text-green-700' },
      COMPLETED: { label: 'Befejezve', className: 'bg-gray-100 text-gray-700' }
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
          Szállítmányigények
        </h1>
        <Link
          to="/shipments/new"
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          Új szállítmány igény
        </Link>
      </div>

      {/* Filters */}
      <div className="form-panel">
        <div className="flex gap-3 items-end">
          <div>
            <label className="form-label">Státusz</label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="form-input"
            >
              <option value="">Mind</option>
              <option value="REQUESTED">Kérve</option>
              <option value="APPROVED">Jóváhagyva</option>
              <option value="REJECTED">Elutasítva</option>
              <option value="PREPARING">Előkészítés</option>
              <option value="READY_FOR_PICKUP">Átvételre kész</option>
              <option value="IN_TRANSIT">Úton</option>
              <option value="DELIVERED">Kézbesítve</option>
              <option value="COMPLETED">Befejezve</option>
            </select>
          </div>
          <button
            onClick={loadShipments}
            className="form-button"
            disabled={loading}
          >
            Frissítés
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
          Nincsenek szállítmányigények
        </div>
      ) : (
        <div className="form-panel p-0">
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>Igény szám</th>
                <th>Kérő fiók</th>
                <th>Cél fiók</th>
                <th>Kézbesítési dátum</th>
                <th>Státusz</th>
                <th>Kérve</th>
                <th className="w-32">Műveletek</th>
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
                  <td>
                    <div className="flex gap-1">
                      <button
                        onClick={() => navigate(`/shipments/${shipment.id}`)}
                        className="toolbar-button"
                        title="Részletek"
                      >
                        <Eye size={14} />
                      </button>
                      {shipment.requestStatus === 'REQUESTED' && (
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

