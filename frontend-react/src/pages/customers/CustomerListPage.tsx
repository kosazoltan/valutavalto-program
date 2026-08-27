import { useState, useEffect, useCallback } from 'react'
import { Link } from 'react-router-dom'
import {
  Users,
  Search,
  Plus,
  Edit,
  Eye,
  AlertCircle,
  Loader2,
  Star,
  Trophy,
  UserCheck,
} from 'lucide-react'
import { customerApi, Customer, CustomerRanking } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface CustomerHighlights {
  vip: Customer[]
  frequent: CustomerRanking[]
  top: CustomerRanking[]
}

export default function CustomerListPage() {
  const { t } = useTranslation()
  const [search, setSearch] = useState('')
  const [customerCodeSearch, setCustomerCodeSearch] = useState('')
  const [pendingOnly, setPendingOnly] = useState(false)
  const [customers, setCustomers] = useState<Customer[]>([])
  const [highlights, setHighlights] = useState<CustomerHighlights>({
    vip: [],
    frequent: [],
    top: [],
  })
  const [highlightsLoading, setHighlightsLoading] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadCustomers = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = pendingOnly
        ? await customerApi.getPendingReview()
        : search.trim()
          ? await customerApi.search(search.trim())
          : await customerApi.getActive()
      setCustomers(data)
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('CustomerListPage', 'Failed to load customers:', err)
    } finally {
      setLoading(false)
    }
  }, [pendingOnly, search])

  useEffect(() => {
    const timer = setTimeout(
      () => {
        void loadCustomers()
      },
      search ? 400 : 0,
    )
    return () => clearTimeout(timer)
  }, [loadCustomers, search])

  useEffect(() => {
    const loadHighlights = async () => {
      try {
        setHighlightsLoading(true)
        const [vip, frequent, top] = await Promise.all([
          customerApi.getVip(),
          customerApi.getFrequent({ minTx: 5 }),
          customerApi.getTop({ limit: 5 }),
        ])
        setHighlights({ vip, frequent, top })
      } catch (err) {
        logger.error('CustomerListPage', 'Failed to load customer highlights:', err)
      } finally {
        setHighlightsLoading(false)
      }
    }

    void loadHighlights()
  }, [])

  const handleDeactivate = async (id: number) => {
    if (!confirm('Biztosan inaktiválja az ügyfelet?')) return
    try {
      await customerApi.deactivate(id)
      void loadCustomers()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleActivate = async (id: number) => {
    if (!confirm('Biztosan aktiválja az ügyfelet?')) return
    try {
      await customerApi.activate(id)
      void loadCustomers()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleNameSearch = async () => {
    const name = search.trim()
    if (!name) return
    try {
      setLoading(true)
      setError(null)
      const data = await customerApi.searchByName(name)
      setCustomers(data)
    } catch (err) {
      setCustomers([])
      setError(getErrorMessage(err))
      logger.error('CustomerListPage', 'Failed to load customer search by name:', err)
    } finally {
      setLoading(false)
    }
  }

  const handlePendingReviewFilter = () => {
    setPendingOnly(true)
  }

  const handleCustomerCodeSearch = async () => {
    const code = customerCodeSearch.trim()
    if (!code) return
    try {
      setLoading(true)
      setError(null)
      const customer = await customerApi.getByCode(code)
      setCustomers([customer])
    } catch (err) {
      setCustomers([])
      setError(getErrorMessage(err))
      logger.error('CustomerListPage', 'Failed to load customer by code:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Users />
          {t('archiving.ugyfelek')}
        </h1>
        <Link to="/customers/new" className="form-button-primary flex items-center gap-1">
          <Plus size={16} />
          {t('misc.ujUgyfel')}
        </Link>
      </div>

      {/* Search */}
      <div className="form-panel">
        <div className="grid gap-3 md:grid-cols-2">
          <div className="flex gap-1">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="form-input flex-1"
              placeholder="Keresés név vagy okmányszám alapján..."
            />
            <button
              onClick={() => void loadCustomers()}
              className="form-button"
              aria-label={t('common.search')}
            >
              <Search size={16} />
            </button>
            <button
              onClick={() => void handleNameSearch()}
              className="form-button"
              aria-label={t('customers.nameSearch')}
              title={t('customers.nameSearch')}
            >
              <Users size={16} />
            </button>
          </div>
          <div className="flex gap-1">
            <input
              type="text"
              value={customerCodeSearch}
              onChange={(e) => setCustomerCodeSearch(e.target.value)}
              className="form-input flex-1"
              placeholder={t('customers.customerCodeSearchPlaceholder')}
            />
            <button
              onClick={() => void handleCustomerCodeSearch()}
              className="form-button"
              aria-label={t('customers.customerCodeSearch')}
            >
              <Search size={16} />
            </button>
          </div>
        </div>
        <div className="mt-3 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => handlePendingReviewFilter()}
            className={`form-button ${pendingOnly ? 'border-amber-300 bg-amber-50 text-amber-800' : ''}`}
          >
            {i18n.t('literals.atnezesre-varo')}
          </button>
          {pendingOnly && (
            <button
              type="button"
              onClick={() => {
                setPendingOnly(false)
                void loadCustomers()
              }}
              className="form-button"
            >
              {i18n.t('literals.osszes-aktiv')}
            </button>
          )}
        </div>
      </div>

      <div className="grid gap-3 md:grid-cols-3" data-testid="customer-highlight-panel">
        <div className="rounded border border-yellow-200 bg-yellow-50 p-3">
          <div className="flex items-center gap-2 text-sm font-semibold text-yellow-800">
            <Star size={16} />
            {t('customers.vipCustomers')}
          </div>
          <div className="mt-2 text-2xl font-bold text-gray-900" data-testid="customer-vip-count">
            {highlightsLoading ? '-' : highlights.vip.length}
          </div>
          <div className="text-xs text-gray-600 truncate">
            {highlights.vip[0]?.name || t('customers.noHighlightedCustomer')}
          </div>
        </div>
        <div className="rounded border border-blue-200 bg-blue-50 p-3">
          <div className="flex items-center gap-2 text-sm font-semibold text-blue-800">
            <Users size={16} />
            {t('customers.frequentCustomers')}
          </div>
          <div
            className="mt-2 text-2xl font-bold text-gray-900"
            data-testid="customer-frequent-count"
          >
            {highlightsLoading ? '-' : highlights.frequent.length}
          </div>
          <div className="text-xs text-gray-600 truncate">
            {highlights.frequent[0]?.customerName || t('customers.noHighlightedCustomer')}
          </div>
        </div>
        <div className="rounded border border-emerald-200 bg-emerald-50 p-3">
          <div className="flex items-center gap-2 text-sm font-semibold text-emerald-800">
            <Trophy size={16} />
            {t('customers.topCustomers')}
          </div>
          <div className="mt-2 text-2xl font-bold text-gray-900" data-testid="customer-top-count">
            {highlightsLoading ? '-' : highlights.top.length}
          </div>
          <div className="text-xs text-gray-600 truncate">
            {highlights.top[0]?.customerName || t('customers.noHighlightedCustomer')}
          </div>
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="form-panel p-0">
        {loading ? (
          <div className="flex items-center justify-center py-8 text-gray-500 gap-2">
            <Loader2 size={18} className="animate-spin" />
            {i18n.t('literals.betoltes')}
          </div>
        ) : customers.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            {search ? 'Nincs találat' : 'Nincsenek ügyfelek'}
          </div>
        ) : (
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{t('common.name')}</th>
                <th>{t('customers.customerCode')}</th>
                <th>{t('common.birthDate')}</th>
                <th>{t('common.nationality')}</th>
                <th>{t('customers.okmanyTipus')}</th>
                <th>{t('common.documentNumber')}</th>
                <th>{t('common.phone')}</th>
                <th>{t('common.status')}</th>
                <th className="w-24">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {customers.map((c) => (
                <tr key={c.id}>
                  <td className="font-semibold">
                    {c.name}
                    {c.isVip && (
                      <span className="ml-1 text-xs bg-yellow-100 text-yellow-700 px-1 rounded">
                        {i18n.t('literals.vip')}
                      </span>
                    )}
                    {c.reviewStatus === 'PENDING_REVIEW' && (
                      <span className="ml-1 text-xs bg-amber-100 text-amber-800 px-1 rounded">
                        {i18n.t('literals.atnezesre-var')}
                      </span>
                    )}
                  </td>
                  <td className="font-mono text-sm">{c.customerCode || '-'}</td>
                  <td>{c.birthDate ? new Date(c.birthDate).toLocaleDateString('hu-HU') : '-'}</td>
                  <td>{c.nationality || '-'}</td>
                  <td>{c.documentType || '-'}</td>
                  <td className="font-mono text-sm">{c.documentNumber || '-'}</td>
                  <td className="font-mono text-sm">{c.phone || '-'}</td>
                  <td>
                    <span
                      className={`px-2 py-1 text-xs rounded ${
                        c.active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
                      }`}
                    >
                      {c.active ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-1">
                      <Link
                        to={`/customers/${c.id}`}
                        className="toolbar-button"
                        title="Megtekintés"
                      >
                        <Eye size={14} />
                      </Link>
                      <Link
                        to={`/customers/${c.id}`}
                        className="toolbar-button"
                        title="Szerkesztés"
                      >
                        <Edit size={14} />
                      </Link>
                      {c.active && (
                        <button
                          onClick={() => handleDeactivate(c.id)}
                          className="toolbar-button text-red-500"
                          title="Inaktiválás"
                        >
                          {i18n.t('literals.lit-34')}
                        </button>
                      )}
                      {!c.active && (
                        <button
                          onClick={() => handleActivate(c.id)}
                          className="toolbar-button text-emerald-600"
                          title="Aktiválás"
                        >
                          <UserCheck size={14} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Footer */}
      <div className="form-panel">
        <span className="text-sm">
          {customers.length} {t('customers.ugyfel')}
        </span>
      </div>
    </div>
  )
}
