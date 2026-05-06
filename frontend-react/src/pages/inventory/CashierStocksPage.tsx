import { useState, useEffect, useCallback, useMemo } from 'react'
import { Package, Search, RefreshCw, AlertTriangle, Wallet } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'

interface InventoryItem {
  id: string | number
  currencyCode?: string
  branchName?: string
  currentBalance?: number
  lastUpdated?: string
}

interface BranchGroup {
  branchName: string
  items: InventoryItem[]
  hufTotal: number
  nonZeroCount: number
}

function formatBalance(value: number | undefined, currencyCode: string | undefined): string {
  if (typeof value !== 'number') return value ?? '-'
  if (currencyCode === 'HUF') return value.toLocaleString('hu-HU', { maximumFractionDigits: 0 })
  return value.toLocaleString('hu-HU', { maximumFractionDigits: 2 })
}

export default function CashierStocksPage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<InventoryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<InventoryItem[]>('/inventory/stock')
      setItems(safeArray<InventoryItem>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('CashierStocksPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = useMemo(() => {
    if (!searchTerm) return items
    const term = searchTerm.toLowerCase()
    return items.filter(item =>
      Object.values(item).some(v => v != null && String(v).toLowerCase().includes(term))
    )
  }, [items, searchTerm])

  const branchGroups: BranchGroup[] = useMemo(() => {
    const map = new Map<string, BranchGroup>()
    for (const item of filtered) {
      const name = item.branchName ?? '(ismeretlen)'
      let group = map.get(name)
      if (!group) {
        group = { branchName: name, items: [], hufTotal: 0, nonZeroCount: 0 }
        map.set(name, group)
      }
      group.items.push(item)
      if (item.currencyCode === 'HUF' && typeof item.currentBalance === 'number') {
        group.hufTotal += item.currentBalance
      }
      if (typeof item.currentBalance === 'number' && item.currentBalance !== 0) {
        group.nonZeroCount += 1
      }
    }
    for (const group of map.values()) {
      group.items.sort((a, b) => (a.currencyCode ?? '').localeCompare(b.currencyCode ?? ''))
    }
    return Array.from(map.values()).sort((a, b) => b.hufTotal - a.hufTotal)
  }, [filtered])

  const grandTotalHuf = branchGroups.reduce((sum, g) => sum + g.hufTotal, 0)
  const totalBranches = branchGroups.length
  const totalNonZero = branchGroups.reduce((sum, g) => sum + g.nonZeroCount, 0)

  return (
    <div className="space-y-3">
      {/* Header + kereső */}
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <h1 className="form-title flex items-center gap-2 text-lg">
          <Package className="h-5 w-5" />
          {t('inventory.penztariKeszletek')}
        </h1>
        <div className="flex items-center gap-2 flex-1 max-w-md">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Keresés (valuta, pénztár)..."
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              className="form-input w-full pl-10 h-8 text-sm"
            />
          </div>
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {/* Összesen — kiemelt nagy kártya legfelül */}
      <div className="rounded-lg bg-gradient-to-br from-primary-50 to-primary-100 border-2 border-primary-200 p-5 shadow-sm">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-lg bg-primary-100 text-primary-700">
              <Wallet className="h-6 w-6" />
            </div>
            <div>
              <div className="text-sm text-primary-700 font-medium">{t('inventory.osszesenHufKeszlet')}</div>
              <div className="text-3xl font-bold font-mono text-primary-900">
                {grandTotalHuf.toLocaleString('hu-HU', { maximumFractionDigits: 0 })} {t('common.ft')}
              </div>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm text-primary-700">
              <strong>{totalBranches}</strong>{t('inventory.penztar')}
            </div>
            <div className="text-xs text-primary-600">
              {totalNonZero} {t('inventory.aktivTetel')} {filtered.length} {t('common.sor')}
            </div>
          </div>
        </div>
      </div>

      {/* Pénztáranként kártyák */}
      {loading && branchGroups.length === 0 ? (
        <div className="form-panel text-center text-sm text-gray-500 py-8">Betöltés...</div>
      ) : branchGroups.length === 0 ? (
        <div className="form-panel text-center text-sm text-gray-500 py-8">{t('common.noData')}</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {branchGroups.map(group => (
            <BranchCard key={group.branchName} group={group} />
          ))}
        </div>
      )}
    </div>
  )
}

function BranchCard({ group }: { group: BranchGroup }) {
  const { t } = useTranslation()
  return (
    <div className="form-panel p-3 hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between mb-2 pb-2 border-b border-gray-200">
        <h3 className="font-bold text-secondary-900 truncate flex-1" title={group.branchName}>
          {group.branchName}
        </h3>
        <span className="text-xs text-gray-500 ml-2">
          {group.items.length} {t('inventory.valuta')}
        </span>
      </div>
      <table className="w-full text-sm">
        <tbody>
          {group.items.map(item => {
            const isZero = !item.currentBalance || item.currentBalance === 0
            return (
              <tr key={`${item.id}`} className={isZero ? 'text-gray-400' : ''}>
                <td className="py-0.5 font-mono font-semibold w-12">{item.currencyCode ?? '-'}</td>
                <td className={`py-0.5 text-right font-mono ${isZero ? '' : 'text-secondary-900 font-semibold'}`}>
                  {formatBalance(item.currentBalance, item.currencyCode)}
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
