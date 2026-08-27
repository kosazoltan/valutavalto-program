import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { Users, Plus, Eye, AlertCircle, Loader2, ArrowLeft } from 'lucide-react'
import {
  authorizedRepresentativeApi,
  AuthorizedRepresentative,
} from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function RepresentativeListPage() {
  const { t } = useTranslation()
  const { customerId } = useParams<{ customerId: string }>()
  const navigate = useNavigate()
  const isCustomerScoped = Boolean(customerId)
  const [representatives, setRepresentatives] = useState<AuthorizedRepresentative[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadRepresentatives = useCallback(async (): Promise<void> => {
    try {
      setLoading(true)
      setError(null)
      const data = customerId
        ? await authorizedRepresentativeApi.findByCustomer(customerId)
        : await authorizedRepresentativeApi.list()
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
    void loadRepresentatives()
  }, [customerId, loadRepresentatives])

  const customerName = representatives.length > 0 ? representatives[0]?.customerName : undefined
  const detailPath = (rep: AuthorizedRepresentative) =>
    `/customers/${rep.customerId}/representatives/${rep.id}`

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-3">
          {isCustomerScoped && (
            <Link to={`/customers/${customerId}`} className="toolbar-button">
              <ArrowLeft size={18} />
            </Link>
          )}
          <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
            <Users />
            {t('customers.meghatalmazottak')}
            {customerName && (
              <span className="text-base font-normal text-gray-500">
                {i18n.t('literals.lit-55')}
                {customerName}
              </span>
            )}
          </h1>
        </div>
        {isCustomerScoped && (
          <Link
            to={`/customers/${customerId}/representatives/new`}
            className="form-button-primary flex items-center gap-2"
          >
            <Plus size={16} />
            {t('representatives.ujMeghatalmazott')}
          </Link>
        )}
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
          {i18n.t('literals.betoltes')}
        </div>
      ) : representatives.length === 0 ? (
        <div className="form-panel text-center py-8 text-gray-500">
          {t('representatives.nincsenekMeghatalmazottak')}
        </div>
      ) : (
        <div className="form-panel">
          <div className="space-y-3 md:hidden">
            {representatives.map((rep) => (
              <article
                key={rep.id}
                className="rounded border border-gray-200 bg-white p-3 shadow-sm"
              >
                <div className="mb-3 flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="truncate text-lg font-bold text-gray-900">{rep.fullName}</p>
                    {!isCustomerScoped && (
                      <p className="text-sm text-gray-500">
                        {i18n.t('literals.ugyfel-id')}
                        <span className="font-mono">{rep.customerId}</span>
                      </p>
                    )}
                  </div>
                  <span
                    className={`px-2 py-1 text-xs rounded ${
                      rep.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    {rep.isActive ? 'Aktív' : 'Inaktív'}
                  </span>
                </div>
                <dl className="grid grid-cols-2 gap-x-3 gap-y-2 text-sm">
                  <div>
                    <dt className="text-gray-500">{t('common.documentNumber')}</dt>
                    <dd className="font-mono text-gray-900">{rep.documentNumber || '-'}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{t('customers.okmanyTipus')}</dt>
                    <dd className="text-gray-900">{rep.documentTypeDid || '-'}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{t('display.kapcsolat')}</dt>
                    <dd className="text-gray-900">{rep.relationshipDid || '-'}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">{t('rates.ervenyes')}</dt>
                    <dd className="text-gray-900">
                      {rep.authorizationStart
                        ? new Date(rep.authorizationStart).toLocaleDateString('hu-HU')
                        : '-'}
                      {rep.authorizationEnd
                        ? ` — ${new Date(rep.authorizationEnd).toLocaleDateString('hu-HU')}`
                        : rep.authorizationStart
                          ? ' — ∞'
                          : ''}
                    </dd>
                  </div>
                </dl>
                <button
                  type="button"
                  onClick={() => navigate(detailPath(rep))}
                  className="form-button mt-3 flex w-full items-center justify-center gap-2"
                >
                  <Eye size={14} />
                  {t('common.details')}
                </button>
              </article>
            ))}
          </div>

          <div className="hidden overflow-x-auto md:block">
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('common.name')}</th>
                  {!isCustomerScoped && <th>{i18n.t('literals.ugyfel-id-2')}</th>}
                  <th>{t('common.documentNumber')}</th>
                  <th>{t('customers.okmanyTipus')}</th>
                  <th>{t('display.kapcsolat')}</th>
                  <th>{t('rates.ervenyes')}</th>
                  <th>{t('common.status')}</th>
                  <th className="w-24">{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {representatives.map((rep) => (
                  <tr key={rep.id}>
                    <td className="font-semibold">{rep.fullName}</td>
                    {!isCustomerScoped && <td className="font-mono text-sm">{rep.customerId}</td>}
                    <td className="font-mono text-sm">{rep.documentNumber || '-'}</td>
                    <td>{rep.documentTypeDid || '-'}</td>
                    <td>{rep.relationshipDid || '-'}</td>
                    <td className="text-sm text-gray-600">
                      {rep.authorizationStart
                        ? new Date(rep.authorizationStart).toLocaleDateString('hu-HU')
                        : '-'}
                      {rep.authorizationEnd
                        ? ` — ${new Date(rep.authorizationEnd).toLocaleDateString('hu-HU')}`
                        : rep.authorizationStart
                          ? ' — ∞'
                          : ''}
                    </td>
                    <td>
                      <span
                        className={`px-2 py-1 text-xs rounded ${
                          rep.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
                        }`}
                      >
                        {rep.isActive ? 'Aktív' : 'Inaktív'}
                      </span>
                    </td>
                    <td>
                      <div className="flex gap-1">
                        <button
                          onClick={() => navigate(detailPath(rep))}
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
        </div>
      )}
    </div>
  )
}
