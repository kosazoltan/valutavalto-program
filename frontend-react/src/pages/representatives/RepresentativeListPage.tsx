import { useState, useEffect } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { Users, Plus, Eye, AlertCircle } from 'lucide-react'
import { authorizedRepresentativeApi, AuthorizedRepresentative } from '../../services/api'
import { getErrorMessage } from '../../utils/errorHandling'

export default function RepresentativeListPage() {
  const { customerId } = useParams<{ customerId: string }>()
  const navigate = useNavigate()
  const [representatives, setRepresentatives] = useState<AuthorizedRepresentative[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let mounted = true

    if (customerId) {
      const load = async (): Promise<void> => {
        await loadRepresentatives()
      }

      load().catch(err => {
        if (mounted) {
          console.error('Failed to load representatives:', err)
        }
      })
    }

    return () => {
      mounted = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [customerId])

  const loadRepresentatives = async (): Promise<void> => {
    if (!customerId) return
    try {
      setLoading(true)
      const data = await authorizedRepresentativeApi.findByCustomer(customerId)
      setRepresentatives(data)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      setError(errorMessage)
      console.error('Failed to load representatives:', err)
    } finally {
      setLoading(false)
    }
  }

  if (!customerId) {
    return (
      <div className="form-panel">
        <div className="text-center text-gray-500 py-8">
          Ügyfél ID hiányzik
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Users />
          Meghatalmazottak
        </h1>
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
        <div className="form-panel text-center py-8 text-gray-500">
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
                <th>Születési dátum</th>
                <th>Kapcsolat</th>
                <th>Státusz</th>
                <th>Regisztrálva</th>
                <th className="w-24">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {representatives.map((rep) => (
                <tr key={rep.id}>
                  <td className="font-semibold">{rep.fullName}</td>
                  <td className="font-mono text-sm">{rep.documentNumber || '-'}</td>
                  <td>{rep.birthDate ? new Date(rep.birthDate).toLocaleDateString('hu-HU') : '-'}</td>
                  <td>{rep.relationshipDid || '-'}</td>
                  <td>
                    <span className={`px-2 py-1 text-xs rounded ${
                      rep.isActive
                        ? 'bg-green-100 text-green-700'
                        : 'bg-gray-100 text-gray-700'
                    }`}>
                      {rep.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td className="text-sm text-gray-600">
                    {new Date(rep.registeredAt).toLocaleDateString('hu-HU')}
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

