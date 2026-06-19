import { useState, useEffect, useMemo } from 'react'
import { Calculator, Search, Calendar } from 'lucide-react'
import { contributionApi, Contribution } from '../../services/api/index'
import { formatInteger } from '../../utils/numberFormat'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger';
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'

export default function ContributionPage() {
  const { t } = useTranslation()
  const branchId = useAuthStore((state) => state.worker?.branchId ?? '')
  const [contributions, setContributions] = useState<Contribution[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')

  const filteredContributions = useMemo(() => {
    if (!searchTerm) return contributions
    const term = searchTerm.toLowerCase()
    return contributions.filter(c =>
      c.workerFullName?.toLowerCase().includes(term) ||
      c.branchName?.toLowerCase().includes(term)
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

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
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
        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="form-label">{t('common.startDate')}</label>
            <input type="date" className="form-input" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
          </div>
          <div>
            <label className="form-label">{t('common.endDate')}</label>
            <input type="date" className="form-input" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
          </div>
          <div className="flex items-end">
            <button onClick={handleFilterByPeriod} className="form-button-primary flex items-center gap-2">
              <Calendar size={16} />
              {t('common.filter')}
            </button>
          </div>
          <div>
            <label className="form-label">{t('common.search')}</label>
            <div className="relative">
              <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
              <input type="text" className="form-input pl-8" placeholder="Dolgozó vagy fiók..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
            </div>
          </div>
        </div>
      </div>

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('commissions.dolgozo')}</th>
              <th>{t('commissions.fok')}</th>
              <th>{t('common.period')}</th>
              <th>{t('common.type')}</th>
              <th>{t('contributions.alapOsszeg')}</th>
              <th>{t('contributions.szamitottOsszeg')}</th>
              <th>{t('common.status')}</th>
            </tr>
          </thead>
          <tbody>
            {filteredContributions.length === 0 ? (
              <tr><td colSpan={7} className="text-center text-gray-500 py-4">{t('common.noResult')}</td></tr>
            ) : (
              filteredContributions.map((c) => (
                <tr key={c.id}>
                  <td>{c.workerFullName}</td>
                  <td>{c.branchName || '-'}</td>
                  <td>{c.periodStart} - {c.periodEnd}</td>
                  <td>{c.contributionTypeName}</td>
                  <td className="font-mono">{c.baseAmount ? formatInteger(c.baseAmount) : '0'} {c.currencyCode}</td>
                  <td className="font-bold font-mono">{c.calculatedAmount ? formatInteger(c.calculatedAmount) : '0'} {c.currencyCode}</td>
                  <td>
                    <span className={`badge ${c.statusName === 'Jóváhagyva' ? 'badge-green' : 'badge-yellow'}`}>
                      {c.statusName}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

