import { useState, useEffect, useMemo } from 'react'
import { Calculator, Search, Calendar } from 'lucide-react'
import { contributionApi, Contribution } from '../../services/api/index'
import { formatInteger } from '../../utils/numberFormat'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'
import i18n from '../../i18n'

export default function ContributionPage() {
  const { t } = useTranslation()
  const branchId = useAuthStore((state) => state.worker?.branchId ?? '')
  const [contributions, setContributions] = useState<Contribution[]>([])
  const [selectedContribution, setSelectedContribution] = useState<Contribution | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')

  const filteredContributions = useMemo(() => {
    if (!searchTerm) return contributions
    const term = searchTerm.toLowerCase()
    return contributions.filter(
      (c) =>
        c.workerFullName?.toLowerCase().includes(term) ||
        c.branchName?.toLowerCase().includes(term),
    )
  }, [contributions, searchTerm])

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      const data = await contributionApi.list()
      setContributions(data)
    } catch (error) {
      logger.error('ContributionPage', 'Hiba az adatok betöltésekor:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleFilterByPeriod = async () => {
    if (!branchId) {
      toast.warning('Hiányzó fiók', 'A járulék időszakos szűréséhez fiók azonosító szükséges')
      return
    }
    if (!startDate || !endDate) {
      toast.warning('Hiányzó adatok', 'Kérjük, adja meg az időszakot')
      return
    }
    try {
      const data = await contributionApi.getByPeriod(branchId, startDate, endDate)
      setContributions(data)
    } catch (error) {
      logger.error('ContributionPage', 'Hiba a szűréskor:', error)
    }
  }

  const handleCalculatePeriod = async () => {
    if (!branchId) {
      toast.warning('Hiányzó fiók', 'A járulékszámításhoz fiók azonosító szükséges')
      return
    }
    if (!startDate || !endDate) {
      toast.warning('Hiányzó adatok', 'Kérjük, adja meg az időszakot')
      return
    }
    try {
      const data = await contributionApi.calculate(branchId, startDate, endDate)
      setContributions(data)
    } catch (error) {
      logger.error('ContributionPage', 'Hiba a járulékszámításkor:', error)
    }
  }

  const handleShowDetails = async (id: string) => {
    try {
      setDetailLoadingId(id)
      setSelectedContribution(await contributionApi.getById(id))
    } catch (error) {
      logger.error('ContributionPage', 'Hiba a járulék részletek betöltésekor:', error)
      toast.warning(
        'Részletek betöltése sikertelen',
        'A kiválasztott járulék részletei nem tölthetők be',
      )
    } finally {
      setDetailLoadingId(null)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">{i18n.t('literals.betoltes')}</div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Calculator />
          {t('contributions.jarulekok')}
        </h1>
      </div>

      <div className="form-panel space-y-4">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
          <div>
            <label className="form-label">{t('common.startDate')}</label>
            <input
              type="date"
              className="form-input"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
            />
          </div>
          <div>
            <label className="form-label">{t('common.endDate')}</label>
            <input
              type="date"
              className="form-input"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-2 sm:flex-row md:items-end">
            <button
              onClick={handleFilterByPeriod}
              className="form-button-primary flex min-h-10 items-center justify-center gap-2"
            >
              <Calendar size={16} />
              {t('common.filter')}
            </button>
            <button
              onClick={handleCalculatePeriod}
              className="form-button flex min-h-10 items-center justify-center gap-2"
            >
              <Calculator size={16} />
              {i18n.t('literals.idoszaki-szamitas')}
            </button>
          </div>
          <div>
            <label className="form-label">{t('common.search')}</label>
            <div className="relative">
              <Search
                className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={16}
              />
              <input
                type="text"
                className="form-input pl-8"
                placeholder="Dolgozó vagy fiók..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="form-panel">
        <div className="overflow-x-auto">
          <table className="data-grid min-w-[860px] w-full">
            <thead>
              <tr>
                <th>{t('commissions.dolgozo')}</th>
                <th>{t('commissions.fok')}</th>
                <th>{t('common.period')}</th>
                <th>{t('common.type')}</th>
                <th>{t('contributions.alapOsszeg')}</th>
                <th>{t('contributions.szamitottOsszeg')}</th>
                <th>{t('common.status')}</th>
                <th>{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredContributions.length === 0 ? (
                <tr>
                  <td colSpan={8} className="text-center text-gray-500 py-4">
                    {t('common.noResult')}
                  </td>
                </tr>
              ) : (
                filteredContributions.map((c) => (
                  <tr key={c.id}>
                    <td>{c.workerFullName}</td>
                    <td>{c.branchName || '-'}</td>
                    <td>
                      {c.periodStart}
                      {i18n.t('literals.lit-17')}
                      {c.periodEnd}
                    </td>
                    <td>{c.contributionTypeName}</td>
                    <td className="font-mono">
                      {c.baseAmount ? formatInteger(c.baseAmount) : '0'} {c.currencyCode}
                    </td>
                    <td className="font-bold font-mono">
                      {c.calculatedAmount ? formatInteger(c.calculatedAmount) : '0'}{' '}
                      {c.currencyCode}
                    </td>
                    <td>
                      <span
                        className={`badge ${c.statusName === 'Jóváhagyva' ? 'badge-green' : 'badge-yellow'}`}
                      >
                        {c.statusName}
                      </span>
                    </td>
                    <td>
                      <button
                        type="button"
                        className="form-button h-8 text-xs"
                        onClick={() => void handleShowDetails(c.id)}
                        disabled={detailLoadingId === c.id}
                      >
                        {detailLoadingId === c.id ? 'Betöltés...' : 'Részletek'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {selectedContribution && (
        <div className="form-panel" data-testid="contribution-detail-panel">
          <div className="mb-3 flex items-center justify-between gap-2">
            <h2 className="text-base font-semibold text-gray-800">
              {i18n.t('literals.jarulek-reszletei')}
            </h2>
            <button
              type="button"
              className="form-button h-8 text-xs"
              onClick={() => setSelectedContribution(null)}
            >
              {i18n.t('literals.bezaras')}
            </button>
          </div>
          <dl className="grid grid-cols-1 gap-3 text-sm md:grid-cols-3">
            <div>
              <dt className="text-gray-500">{i18n.t('literals.dolgozo-2')}</dt>
              <dd className="font-medium text-gray-900">{selectedContribution.workerFullName}</dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.idoszak')}</dt>
              <dd className="font-medium text-gray-900">
                {selectedContribution.periodStart}
                {i18n.t('literals.lit-17')}
                {selectedContribution.periodEnd}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.statusz')}</dt>
              <dd className="font-medium text-gray-900">{selectedContribution.statusName}</dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.tranzakciok')}</dt>
              <dd className="font-mono text-gray-900">
                {formatInteger(selectedContribution.transactionCount ?? 0)}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.teljes-volumen')}</dt>
              <dd className="font-mono text-gray-900">
                {formatInteger(selectedContribution.totalVolume ?? 0)}{' '}
                {selectedContribution.currencyCode}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.szamitas-datuma')}</dt>
              <dd className="font-medium text-gray-900">{selectedContribution.calculationDate}</dd>
            </div>
          </dl>
          {selectedContribution.calculationDetails && (
            <div className="mt-3 rounded border border-gray-200 bg-gray-50 p-3 text-sm text-gray-700">
              {selectedContribution.calculationDetails}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
