import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { Users, Plus, Eye, AlertCircle, Loader2, ArrowLeft } from 'lucide-react'
import { authorizedRepresentativeApi, AuthorizedRepresentative } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

export default function RepresentativeListPage() {
  const { customerId } = useParams<{ customerId: string }>()
  const navigate = useNavigate()
  const [representatives, setRepresentatives] = useState<AuthorizedRepresentative[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadRepresentatives = useCallback(async (): Promise<void> => {
    if (!customerId) return
    try {
      setLoading(true)
      setError(null)
      const data = await authorizedRepresentativeApi.findByCustomer(customerId)
      setRepresentatives(data)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      logger.error('RepresentativeListPage', 'Failed to load representatives:', err)
    } finally {
      setLoading(false)
    }
  }, [customerId])

  useEffect(() => {
    if (customerId) {
      void loadRepresentatives()
    }
  }, [customerId, loadRepresentatives])

  if (!customerId) {
    return (
      <div className="form-panel">
        <div className="text-center text-gray-500 py-8">
          Ügyfél ID hiányzik
        </div>
      </div>
    )
  }

  const customerName = representatives.length > 0 ? representatives[0]?.customerName : undefined

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-3">
          <Link to={`/customers/${customerId}`} className="toolbar-button">
            <ArrowLeft size={18} />
          </Link>
          <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
            <Users />
            Meghatalmazottak
            {customerName && <span className="text-base font-normal text-gray-500">— {customerName}</span>}
          </h1>
        </div>
        <Link
          to={`/customers/${customerId}/representatives/new`}
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          Új meghatalmazott
        </Link>
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
        <div className="form-panel flex items-center justify-center py-8 text-gray-500 gap-2">
          <Loader2 size={18} className="animate-spin" />
          Betöltés...
        </div>
      ) : representatives.length === 0 ? (
        <div className="form-panel text-center py-8 text-gray-500">
          Nincsenek meghatalmazottak
        </div>
      ) : (
        <div className="form-panel p-0">
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>Név</th>
                <th>Okmányszám</th>
                <th>Okmány típus</th>
                <th>Kapcsolat</th>
                <th>Érvényes</th>
                <th>Státusz</th>
                <th className="w-24">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {representatives.map((rep) => (
                <tr key={rep.id}>
                  <td className="font-semibold">{rep.fullName}</td>
                  <td className="font-mono text-sm">{rep.documentNumber || '-'}</td>
                  <td>{rep.documentTypeDid || '-'}</td>
                  <td>{rep.relationshipDid || '-'}</td>
                  <td className="text-sm text-gray-600">
                    {rep.registeredAt ? new Date(rep.registeredAt).toLocaleDateString('hu-HU') : '-'}
                  </td>
                  <td>
                    <span className={`px-2 py-1 text-xs rounded ${
                      rep.isActive
                        ? 'bg-green-100 text-green-700'
                        : 'bg-gray-100 text-gray-700'
                    }`}>
                      {rep.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-1">
                      <button
                        onClick={() => navigate(`/customers/${customerId}/representatives/${rep.id}`)}
                        className="toolbar-button"
                        title="Részletek"
                      >
                        <Eye size={14} />
                      </button>
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
