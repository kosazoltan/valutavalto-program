import { useState, useEffect, useCallback, useMemo } from 'react'
import { Package, Search, RefreshCw, AlertTriangle, Wallet, MapPin } from 'lucide-react'
import { api, branchApi } from '../../services/api/index'
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
  const [branchMeta, setBranchMeta] = useState<Map<string, { region: string; isVault: boolean }>>(new Map())
  const [vaultByRegion, setVaultByRegion] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<InventoryItem[]>('/inventory/stock')
      setItems(safeArray<InventoryItem>(response.data))
      // FK-002: terület-besoroláshoz a fiók-törzsadat region mezője (név → régió).
      try {
        const branches = await branchApi.listActive()
        const meta = new Map<string, { region: string; isVault: boolean }>()
        const vaults = new Map<string, string>()
        for (const b of branches) {
          meta.set(b.name, { region: b.region ?? '', isVault: b.isVault === true })
          if (b.isVault === true && b.region && !vaults.has(b.region)) vaults.set(b.region, b.name)
        }
        setBranchMeta(meta)
        setVaultByRegion(vaults)
      } catch (branchErr) {
        // A területi besorolás csak kiegészítés — ha nincs branch-adat, marad az egy-szekciós nézet.
        logger.warn('CashierStocksPage', 'Branch törzsadat betöltése sikertelen (területi csoportosítás kihagyva)', branchErr)
      }
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

  // FK-002: területenként csoportosítás (8 terület = 1 értéktár + pénztárai).
  const territories = useMemo(() => {
    const map = new Map<string, { regionKey: string; vaultName: string; groups: BranchGroup[]; hufTotal: number }>()
    for (const group of branchGroups) {
      const region = branchMeta.get(group.branchName)?.region || 'BESOROLATLAN'
      let terr = map.get(region)
      if (!terr) {
        terr = { regionKey: region, vaultName: vaultByRegion.get(region) ?? '', groups: [], hufTotal: 0 }
        map.set(region, terr)
      }
      terr.groups.push(group)
      terr.hufTotal += group.hufTotal
    }
    return Array.from(map.values()).sort((a, b) => b.hufTotal - a.hufTotal)
  }, [branchGroups, branchMeta, vaultByRegion])

  // Akkor csoportosítunk terület szerint, ha van értelmes besorolás (van branch-meta és
  // nem csak a "BESOROLATLAN" szekció létezik). Különben marad a sima, egy-grides nézet.
  const groupByTerritory = branchMeta.size > 0
    && !(territories.length === 1 && territories[0]?.regionKey === 'BESOROLATLAN')

  return (
    <div className="space-y-2">
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

      {/* Összesen — kompakt sáv */}
      <div className="rounded-lg bg-gradient-to-br from-primary-50 to-primary-100 border border-primary-200 px-4 py-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Wallet className="h-4 w-4 text-primary-700" />
            <span className="text-sm text-primary-700 font-medium">{t('inventory.osszesenHufKeszlet')}</span>
            <span className="text-xl font-bold font-mono text-primary-900">
              {grandTotalHuf.toLocaleString('hu-HU', { maximumFractionDigits: 0 })} {t('common.ft')}
            </span>
          </div>
          <span className="text-xs text-primary-600">
            <strong>{totalBranches}</strong> {t('inventory.penztar')} · {totalNonZero} {t('inventory.aktivTetel')}
          </span>
        </div>
      </div>

      {/* Pénztáranként kártyák */}
      {loading && branchGroups.length === 0 ? (
        <div className="form-panel text-center text-sm text-gray-500 py-8">Betöltés...</div>
      ) : branchGroups.length === 0 ? (
        <div className="form-panel text-center text-sm text-gray-500 py-8">{t('common.noData')}</div>
      ) : groupByTerritory ? (
        /* FK-002: területi szekciók (terület / értéktár neve fejléccel) */
        <div className="space-y-4">
          {territories.map(terr => (
            <section key={terr.regionKey}>
              <div className="flex items-center gap-2 mb-1 px-1 py-1 border-b-2 border-primary-200">
                <MapPin className="h-4 w-4 text-primary-700" />
                <h2 className="font-bold text-secondary-900 text-sm">
                  {terr.regionKey}
                  {terr.vaultName && <span className="font-normal text-gray-500"> · {terr.vaultName}</span>}
                </h2>
                <span className="ml-auto text-xs text-primary-700 font-mono">
                  {terr.hufTotal.toLocaleString('hu-HU', { maximumFractionDigits: 0 })} {t('common.ft')}
                  <span className="text-gray-400"> · {terr.groups.length} {t('inventory.penztar')}</span>
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-2">
                {terr.groups.map(group => (
                  <BranchCard key={group.branchName} group={group} />
                ))}
              </div>
            </section>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-2">
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
    <div className="form-panel p-2 hover:shadow-md transition-shadow">
      <div className="flex items-center justify-between mb-1 pb-1 border-b border-gray-200">
        <h3 className="font-bold text-secondary-900 text-sm truncate flex-1" title={group.branchName}>
          {group.branchName}
        </h3>
        <span className="text-[10px] text-gray-500 ml-1">
          {group.items.length} {t('inventory.valuta')}
        </span>
      </div>
      <table className="w-full text-xs">
        <tbody>
          {group.items.map(item => {
            const isZero = !item.currentBalance || item.currentBalance === 0
            return (
              <tr key={`${item.id}`} className={isZero ? 'text-gray-400' : ''}>
                <td className="py-px font-mono font-semibold w-10">{item.currencyCode ?? '-'}</td>
                <td className={`py-px text-right font-mono ${isZero ? '' : 'text-secondary-900 font-semibold'}`}>
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
