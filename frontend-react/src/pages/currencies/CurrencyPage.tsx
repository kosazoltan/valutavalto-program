import { useState, useEffect, useMemo } from 'react'
import { Coins, Search } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface Currency {
  id: number
  code: string
  name: string
  numericCode?: string
  decimalPlaces?: number
  symbol?: string
  isActive: boolean
}

export default function CurrencyPage() {
  const { t } = useTranslation()
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const filtered = useMemo(() => {
    if (!searchTerm) return currencies
    const t = searchTerm.toLowerCase()
    return currencies.filter(
      (c) => c.code.toLowerCase().includes(t) || c.name.toLowerCase().includes(t),
    )
  }, [currencies, searchTerm])

  const load = async () => {
    try {
      setLoading(true)
      setError(null)
      const res = await api.get('/currencies/all')
      setCurrencies(safeArray<Currency>(res.data))
    } catch (err) {
      logger.error('CurrencyPage', 'load error', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">{i18n.t('literals.betoltes')}</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Coins />
          {t('stockSnapshot.currencies')}
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel">
        <div className="relative">
          <Search
            className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
            size={16}
          />
          <input
            type="text"
            className="form-input pl-8"
            placeholder="Keresés kódban, névben..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('common.code')}</th>
              <th>{t('common.name')}</th>
              <th>{t('currencies.szimbolum')}</th>
              <th>{t('currencies.numerikusKod')}</th>
              <th>{t('currencies.tizedeshelyek')}</th>
              <th>{t('common.status')}</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filtered.map((c) => (
                <tr key={c.id}>
                  <td className="font-mono font-bold">{c.code}</td>
                  <td>{c.name}</td>
                  <td>{c.symbol ?? '-'}</td>
                  <td className="font-mono text-sm">{c.numericCode ?? '-'}</td>
                  <td className="text-center">{c.decimalPlaces ?? 2}</td>
                  <td>
                    <span className={`badge ${c.isActive ? 'badge-green' : 'badge-red'}`}>
                      {c.isActive ? 'Aktív' : 'Inaktív'}
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
