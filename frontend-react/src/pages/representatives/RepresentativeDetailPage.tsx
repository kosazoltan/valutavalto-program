import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { ArrowLeft, User, FileText, AlertCircle, Loader2, Shield } from 'lucide-react'
import { authorizedRepresentativeApi, AuthorizedRepresentative, Authorization } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

export default function RepresentativeDetailPage() {
  const { customerId, representativeId } = useParams<{ customerId: string; representativeId: string }>()
  const [rep, setRep] = useState<AuthorizedRepresentative | null>(null)
  const [authorizations, setAuthorizations] = useState<Authorization[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!representativeId) return
    const load = async () => {
      try {
        setLoading(true)
        const found = await authorizedRepresentativeApi.getById(representativeId)
        setRep(found)
        if (found) {
          try {
            const auths = await authorizedRepresentativeApi.findAuthorizations(found.id)
            setAuthorizations(auths)
          } catch {
            // Authorizations may not exist yet
          }
        }
      } catch (err) {
        setError(getErrorMessage(err))
        logger.error('RepresentativeDetailPage', 'Failed to load representative:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [customerId, representativeId])

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12 text-gray-500 gap-2">
        <Loader2 size={20} className="animate-spin" />
        Betöltés...
      </div>
    )
  }

  if (!rep) {
    return (
      <div className="form-panel text-center py-8">
        <AlertCircle className="inline mr-2" size={16} />
        {error || 'Meghatalmazott nem található'}
        <div className="mt-4">
          <Link to={`/customers/${customerId}/representatives`} className="form-button">Vissza</Link>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-3">
        <Link to={`/customers/${customerId}/representatives`} className="toolbar-button">
          <ArrowLeft size={18} />
        </Link>
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <User />
          {rep.fullName}
          <span className={`px-2 py-1 text-xs rounded ${
            rep.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
          }`}>
            {rep.isActive ? 'Aktív' : 'Inaktív'}
          </span>
        </h1>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      <div className="grid grid-cols-2 gap-3">
        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2"><User size={16} /> Személyes adatok</h2>
          <dl className="space-y-2">
            <div className="flex justify-between">
              <dt className="text-gray-500 text-sm">Teljes név</dt>
              <dd className="font-semibold">{rep.fullName}</dd>
            </div>
            {rep.birthDate && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Születési dátum</dt>
                <dd>{new Date(rep.birthDate).toLocaleDateString('hu-HU')}</dd>
              </div>
            )}
            {rep.birthPlace && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Születési hely</dt>
                <dd>{rep.birthPlace}</dd>
              </div>
            )}
            {rep.nationalityDid && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Állampolgárság</dt>
                <dd>{rep.nationalityDid}</dd>
              </div>
            )}
            {rep.address && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Cím</dt>
                <dd>{rep.address}</dd>
              </div>
            )}
            {rep.phone && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Telefon</dt>
                <dd className="font-mono">{rep.phone}</dd>
              </div>
            )}
            {rep.email && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">E-mail</dt>
                <dd>{rep.email}</dd>
              </div>
            )}
            {rep.relationshipDid && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Kapcsolat</dt>
                <dd>{rep.relationshipDid}</dd>
              </div>
            )}
            {rep.representativeTypeDid && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Típus</dt>
                <dd>{rep.representativeTypeDid}</dd>
              </div>
            )}
          </dl>
        </div>

        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2"><FileText size={16} /> Okmány adatok</h2>
          <dl className="space-y-2">
            <div className="flex justify-between">
              <dt className="text-gray-500 text-sm">Okmány típus</dt>
              <dd>{rep.documentTypeDid || '-'}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-gray-500 text-sm">Okmányszám</dt>
              <dd className="font-mono font-semibold">{rep.documentNumber || '-'}</dd>
            </div>
            {rep.documentValidFrom && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Érvényes -tól</dt>
                <dd>{new Date(rep.documentValidFrom).toLocaleDateString('hu-HU')}</dd>
              </div>
            )}
            {rep.documentValidTo && (
              <div className="flex justify-between">
                <dt className="text-gray-500 text-sm">Érvényes -ig</dt>
                <dd>{new Date(rep.documentValidTo).toLocaleDateString('hu-HU')}</dd>
              </div>
            )}
            <div className="flex justify-between">
              <dt className="text-gray-500 text-sm">Regisztrálva</dt>
              <dd>{rep.registeredAt ? new Date(rep.registeredAt).toLocaleString('hu-HU') : '-'}</dd>
            </div>
          </dl>
        </div>
      </div>

      {/* Authorizations */}
      <div className="form-panel">
        <h2 className="section-title flex items-center gap-2"><Shield size={16} /> Meghatalmazások</h2>
        {authorizations.length === 0 ? (
          <div className="text-center py-4 text-gray-500">Nincsenek meghatalmazások rögzítve</div>
        ) : (
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>Típus</th>
                <th>Státusz</th>
                <th>Érvényes -tól</th>
                <th>Érvényes -ig</th>
                <th>Max összeg</th>
                <th>Tranzakciók</th>
              </tr>
            </thead>
            <tbody>
              {authorizations.map(auth => (
                <tr key={auth.id}>
                  <td>{auth.authorizationTypeDid || '-'}</td>
                  <td>
                    <span className={`px-2 py-1 text-xs rounded ${
                      auth.statusDid === 'ACTIVE' ? 'bg-green-100 text-green-700' :
                      auth.statusDid === 'SUSPENDED' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-gray-100 text-gray-700'
                    }`}>
                      {auth.statusDid || 'N/A'}
                    </span>
                  </td>
                  <td>{auth.startDate ? new Date(auth.startDate).toLocaleDateString('hu-HU') : '-'}</td>
                  <td>{auth.expiryDate ? new Date(auth.expiryDate).toLocaleDateString('hu-HU') : 'Határozatlan'}</td>
                  <td>{auth.maxAmount ? `${auth.maxAmount.toLocaleString('hu-HU')} Ft` : '-'}</td>
                  <td>{auth.usedTransactionCount ?? 0} / {auth.maxTransactionCount ?? '∞'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
