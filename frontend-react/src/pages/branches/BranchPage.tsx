import { useState, useEffect, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Building2, Plus, Edit, Trash2, Search } from 'lucide-react'
import { api, branchApi } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface Branch {
  id: string
  code: string
  name: string
  city?: string
  address?: string
  phone?: string
  email?: string
  companyId?: string
  companyName?: string
  isActive: boolean
  /** v2.5.1-E B6: ÉRTÉKTÁRI fiók-e (admin/foertektar állítja be). */
  isVault?: boolean
  vaultTerritoryId?: number | null
  // FK-020: terület (display). A region a szöveges terület-azonosító (pl. SZEGED),
  // a regionCode a numerikus scope-kód. A lista "Terület" oszlopa + szűrője a region-t használja.
  region?: string
  regionCode?: string
  // 2026-05-15 HIBA #2: kotelezo szervezeti mezok
  bankCode?: string
  zipCode?: string
  branchTypeId?: string
  branchTypeCode?: string
  countryId?: string
  branchStatusId?: string
  openingDate?: string
  // Pénztár Törzs alapmodul (V293): rövid név + szolgáltatás-flagek + nyitvatartás.
  shortName?: string
  hasAfa?: boolean
  hasWu?: boolean
  hasMg?: boolean
  hasPos?: boolean
  closedSaturday?: boolean
  closedSunday?: boolean
  workerCount?: number
  dailyTurnoverHuf?: number
  lastSyncAt?: string | null
  syncStatus?: string
}

interface AdminBranchStats {
  id: string
  workerCount?: number
  dailyTurnoverHuf?: number
  lastSyncAt?: string | null
  syncStatus?: string
}

interface BranchBackendSummary {
  roots: Branch[]
  vaults: Branch[]
  territorialCashiers: Branch[]
  peerVaults: Branch[]
  fixedCounterparties: Branch[]
}

const EMPTY_BRANCH_BACKEND_SUMMARY: BranchBackendSummary = {
  roots: [],
  vaults: [],
  territorialCashiers: [],
  peerVaults: [],
  fixedCounterparties: [],
}

/** FK-020: szolgáltatás-jelölő badge a lista soraiban. Aktív = színes, inaktív = szürke. */
function ServiceBadge({ label, active }: { label: string; active: boolean }) {
  return (
    <span
      className={`inline-block px-1.5 py-0.5 rounded text-xs font-semibold ${
        active ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-400'
      }`}
      title={active ? `${label}: aktív` : `${label}: nincs`}
      // Copilot #1056 a11y: a státusz csak színnel nem megbízható (képernyőolvasó/billentyűzet),
      // ezért aria-label is hordozza ugyanazt az információt, mint a tooltip.
      aria-label={active ? `${label}: aktív` : `${label}: nincs`}
    >
      {label}
    </span>
  )
}

export default function BranchPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [branches, setBranches] = useState<Branch[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [exactCode, setExactCode] = useState('')
  const [exactCodeResult, setExactCodeResult] = useState<Branch | null>(null)
  const [exactCodeLoading, setExactCodeLoading] = useState(false)
  const [backendSummary, setBackendSummary] = useState<BranchBackendSummary>(
    EMPTY_BRANCH_BACKEND_SUMMARY,
  )
  // FK-020: területi szűrő (region) + inaktívak megjelenítése (alapból csak aktív).
  const [territoryFilter, setTerritoryFilter] = useState('')
  const [showInactive, setShowInactive] = useState(false)

  // FK-020: a területi szűrő legördülő dinamikusan a betöltött adatból épül (nem hardcode),
  // így mindig a valós region-értékeket mutatja. "Minden terület" + az előforduló területek.
  const territories = useMemo(() => {
    const set = new Set<string>()
    for (const b of branches) {
      if (b.region && b.region.trim()) set.add(b.region.trim())
    }
    return Array.from(set).sort((a, z) => a.localeCompare(z, 'hu'))
  }, [branches])

  // FK-020: szabad szöveges keresés (név/kód/cím/város) + területi szűrő + aktív/inaktív.
  const filtered = useMemo(() => {
    const t = searchTerm.trim().toLowerCase()
    return branches.filter((b) => {
      if (!showInactive && !b.isActive) return false
      // Sourcery/Copilot #1056: a territories-halmaz trimelt region-t tárol, ezért a
      // szűrésnél is trimelni kell, különben " SZEGED " sosem egyezne a dropdown "SZEGED"-jével.
      if (territoryFilter && (b.region?.trim() ?? '') !== territoryFilter) return false
      if (!t) return true
      return (
        b.name.toLowerCase().includes(t) ||
        b.code.toLowerCase().includes(t) ||
        (b.address ?? '').toLowerCase().includes(t) ||
        (b.city ?? '').toLowerCase().includes(t)
      )
    })
  }, [branches, searchTerm, territoryFilter, showInactive])

  const load = async () => {
    try {
      setLoading(true)
      setError(null)
      // FK-020 / FK-016: a Központi Munkaállomás (clientType=CENTRAL) kizárja a virtuális
      // partnereket -> a 65 pénztár + 8 értéktár (73 valós iroda) jelenik meg.
      const [
        branchesResult,
        adminStatsResult,
        rootsResult,
        vaultsResult,
        vaultCounterpartiesResult,
      ] = await Promise.allSettled([
        api.get('/branches', { params: { clientType: 'CENTRAL' } }),
        api.get<AdminBranchStats[]>('/admin/branches'),
        branchApi.listRoots(),
        branchApi.listVaultOnly(),
        branchApi.listVaultCounterparties(),
      ])

      if (branchesResult.status === 'rejected') {
        throw branchesResult.reason
      }

      const statsById = new Map(
        adminStatsResult.status === 'fulfilled'
          ? safeArray<AdminBranchStats>(adminStatsResult.value.data).map((item) => [item.id, item])
          : [],
      )
      if (adminStatsResult.status === 'rejected') {
        logger.error('BranchPage', 'admin branch stats load error', adminStatsResult.reason)
      }
      if (rootsResult.status === 'rejected') {
        logger.error('BranchPage', 'root branch list load error', rootsResult.reason)
      }
      if (vaultsResult.status === 'rejected') {
        logger.error('BranchPage', 'vault branch list load error', vaultsResult.reason)
      }
      if (vaultCounterpartiesResult.status === 'rejected') {
        logger.error(
          'BranchPage',
          'vault counterparties load error',
          vaultCounterpartiesResult.reason,
        )
      }

      const vaultCounterparties =
        vaultCounterpartiesResult.status === 'fulfilled'
          ? vaultCounterpartiesResult.value
          : EMPTY_BRANCH_BACKEND_SUMMARY
      setBackendSummary({
        roots: rootsResult.status === 'fulfilled' ? safeArray<Branch>(rootsResult.value) : [],
        vaults: vaultsResult.status === 'fulfilled' ? safeArray<Branch>(vaultsResult.value) : [],
        territorialCashiers: safeArray<Branch>(vaultCounterparties.territorialCashiers),
        peerVaults: safeArray<Branch>(vaultCounterparties.peerVaults),
        fixedCounterparties: safeArray<Branch>(vaultCounterparties.fixedCounterparties),
      })

      setBranches(
        safeArray<Branch>(branchesResult.value.data).map((branch) => ({
          ...branch,
          ...statsById.get(branch.id),
        })),
      )
    } catch (err) {
      logger.error('BranchPage', 'load error', err)
      setError(getErrorMessage(err))
      setBackendSummary(EMPTY_BRANCH_BACKEND_SUMMARY)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  // FK-022: a szerkesztés a dedikált, FK-021-formátumú szerkesztő oldalon történik
  // (előtöltött 5 csoport, read-only kód, státuszváltás megerősítéssel).
  const openEdit = (b: Branch) => {
    navigate(`/admin/branches/${b.id}/edit`)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törli ezt a fiókot?')) return
    try {
      await api.delete(`/branches/${id}`)
      toast.success('Fiók törölve!')
      await load()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  /**
   * v2.5.1-E B6: is_vault flag toggle.
   * Csak admin/foertektar/ugyvezeto használhatja (backend PreAuthorize).
   */
  const handleToggleVault = async (b: Branch) => {
    const next = !(b.isVault ?? false)
    try {
      await api.patch(`/branches/${b.id}/is-vault`, { isVault: next })
      toast.success(
        next ? `${b.code}: értéktárként megjelölve` : `${b.code}: pénztárként megjelölve`,
      )
      await load()
    } catch (err) {
      toast.error('Hiba az is_vault frissítésekor', getErrorMessage(err))
    }
  }

  const handleExactCodeLookup = async () => {
    const code = exactCode.trim()
    if (!code) {
      setExactCodeResult(null)
      return
    }
    try {
      setExactCodeLoading(true)
      setError(null)
      const branch = await branchApi.getByCode(code)
      setExactCodeResult(branch as Branch)
    } catch (err) {
      setExactCodeResult(null)
      toast.error('Pénztárkód keresési hiba', getErrorMessage(err))
    } finally {
      setExactCodeLoading(false)
    }
  }

  const renderStats = (b: Branch) => (
    <div className="text-sm">
      <div>{b.workerCount != null ? `${b.workerCount} fő` : '-'}</div>
      <div className="text-xs text-gray-500">
        {b.syncStatus === 'SYNCED'
          ? `Sync: ${b.lastSyncAt ? new Date(b.lastSyncAt).toLocaleDateString('hu-HU') : 'rendben'}`
          : b.syncStatus === 'NEVER'
            ? 'Sync: nincs'
            : 'Sync: -'}
      </div>
    </div>
  )

  const counterpartiesCount =
    backendSummary.territorialCashiers.length +
    backendSummary.peerVaults.length +
    backendSummary.fixedCounterparties.length

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">{i18n.t('literals.betoltes')}</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="flex items-center gap-2 text-xl font-bold text-gray-800">
          <Building2 />
          {i18n.t('literals.penztar-torzs-adatbazis')}
          <span className="text-sm font-normal text-gray-500" data-testid="branch-count">
            {i18n.t('literals.lit-19')}
            {filtered.length}
            {i18n.t('literals.penztar-3')}
          </span>
        </h1>
        <button
          onClick={() => navigate('/admin/branches/new')}
          className="form-button-primary flex min-h-10 items-center justify-center gap-2"
        >
          <Plus size={16} />
          {i18n.t('literals.uj-penztar')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel">
        <div className="flex flex-wrap items-end gap-3">
          <div className="relative flex-1 min-w-[220px]">
            <Search
              className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
              size={16}
            />
            <input
              type="text"
              className="form-input pl-8 w-full"
              placeholder="Keresés névben, kódban, címben..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              aria-label="Keresés"
            />
          </div>
          <select
            className="form-input w-full sm:w-auto"
            value={territoryFilter}
            onChange={(e) => setTerritoryFilter(e.target.value)}
            aria-label="Területi szűrő"
          >
            <option value="">{i18n.t('literals.minden-terulet')}</option>
            {territories.map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </select>
          <label className="inline-flex items-center gap-2 cursor-pointer whitespace-nowrap">
            <input
              type="checkbox"
              className="form-checkbox h-4 w-4"
              checked={showInactive}
              onChange={(e) => setShowInactive(e.target.checked)}
            />
            <span className="text-sm">{i18n.t('literals.inaktivak-is')}</span>
          </label>
          <div className="flex min-w-[220px] flex-1 gap-2 sm:flex-none">
            <div className="relative flex-1">
              <Search
                className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={16}
              />
              <input
                type="text"
                className="form-input pl-8 w-full"
                placeholder="Pontos pénztárkód"
                value={exactCode}
                onChange={(e) => setExactCode(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') void handleExactCodeLookup()
                }}
                aria-label="Pontos pénztárkód"
              />
            </div>
            <button
              type="button"
              className="form-button min-h-10 whitespace-nowrap"
              onClick={() => void handleExactCodeLookup()}
              disabled={exactCodeLoading || !exactCode.trim()}
            >
              {exactCodeLoading ? 'Keresés...' : 'Kód keresés'}
            </button>
          </div>
        </div>
        {exactCodeResult && (
          <div
            className="mt-3 rounded border border-blue-200 bg-blue-50 p-3 text-sm"
            data-testid="branch-code-result"
          >
            <div className="font-semibold text-blue-900">{t('branches.pontosKodTalalat')}</div>
            <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-blue-900">
              <span className="font-mono">{exactCodeResult.code}</span>
              <span>{exactCodeResult.name}</span>
              <span>{exactCodeResult.region ?? exactCodeResult.city ?? '-'}</span>
              <span>{exactCodeResult.isActive ? 'Aktív' : 'Inaktív'}</span>
            </div>
          </div>
        )}
        <div
          className="mt-3 grid gap-2 text-sm sm:grid-cols-3"
          data-testid="branch-backend-summary"
        >
          <div className="rounded border border-gray-200 bg-gray-50 px-3 py-2">
            <div className="text-xs font-semibold uppercase text-gray-500">
              {t('branches.gyokerIrodak')}
            </div>
            <div className="text-lg font-bold text-gray-900" data-testid="branch-roots-count">
              {backendSummary.roots.length}
            </div>
          </div>
          <div className="rounded border border-gray-200 bg-gray-50 px-3 py-2">
            <div className="text-xs font-semibold uppercase text-gray-500">
              {t('branches.ertektarak')}
            </div>
            <div className="text-lg font-bold text-gray-900" data-testid="branch-vaults-count">
              {backendSummary.vaults.length}
            </div>
          </div>
          <div className="rounded border border-gray-200 bg-gray-50 px-3 py-2">
            <div className="text-xs font-semibold uppercase text-gray-500">
              {t('branches.ertektariCelpartnerek')}
            </div>
            <div
              className="text-lg font-bold text-gray-900"
              data-testid="branch-counterparties-count"
            >
              {counterpartiesCount}
            </div>
          </div>
        </div>
      </div>

      <div className="form-panel hidden md:block">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('common.code')}</th>
              <th>{i18n.t('literals.penztar-neve')}</th>
              <th>{i18n.t('literals.terulet')}</th>
              <th>{i18n.t('literals.szolgaltatasok')}</th>
              <th>{i18n.t('literals.kontakt')}</th>
              <th>{i18n.t('literals.admin-stat')}</th>
              <th>{t('common.status')}</th>
              <th>{t('branches.ertektar')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={9} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filtered.map((b) => (
                <tr key={b.id}>
                  <td className="font-mono text-sm">{b.code}</td>
                  <td>
                    {b.name}
                    {b.shortName ? (
                      <span className="text-gray-400 text-xs ml-1">
                        {i18n.t('literals.lit-19')}
                        {b.shortName}
                        {i18n.t('literals.lit-2')}
                      </span>
                    ) : null}
                  </td>
                  <td className="text-sm">{b.region ?? '-'}</td>
                  <td>
                    <div className="flex gap-1 flex-wrap">
                      <ServiceBadge label="ÁFA" active={b.hasAfa ?? false} />
                      <ServiceBadge label="WU" active={b.hasWu ?? false} />
                      <ServiceBadge label="MG" active={b.hasMg ?? false} />
                      <ServiceBadge label="POS" active={b.hasPos ?? false} />
                    </div>
                  </td>
                  <td className="text-sm">
                    {b.email ? (
                      <div className="truncate max-w-[180px]" title={b.email}>
                        {b.email}
                      </div>
                    ) : null}
                    {b.phone ? <div className="text-gray-500">{b.phone}</div> : null}
                    {!b.email && !b.phone ? (
                      <span className="text-gray-400">{i18n.t('literals.lit-15')}</span>
                    ) : null}
                  </td>
                  <td>{renderStats(b)}</td>
                  <td>
                    <span className={`badge ${b.isActive ? 'badge-green' : 'badge-red'}`}>
                      {b.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <label
                      className="inline-flex items-center gap-2 cursor-pointer"
                      title="Értéktári fiók"
                    >
                      <input
                        type="checkbox"
                        checked={b.isVault ?? false}
                        onChange={() => void handleToggleVault(b)}
                        className="form-checkbox h-4 w-4"
                      />
                      <span
                        className={`text-xs font-semibold ${b.isVault ? 'text-blue-700' : 'text-gray-400'}`}
                      >
                        {b.isVault ? 'IGEN' : 'nem'}
                      </span>
                    </label>
                  </td>
                  <td>
                    <div className="flex gap-1 flex-wrap">
                      <button
                        onClick={() => openEdit(b)}
                        className="form-button text-xs flex items-center gap-1"
                      >
                        <Edit size={12} />
                        {t('common.edit')}
                      </button>
                      <button
                        onClick={() => handleDelete(b.id)}
                        className="form-button text-xs text-red-600 flex items-center gap-1"
                      >
                        <Trash2 size={12} />
                        {t('common.delete')}
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="grid gap-3 md:hidden">
        {filtered.length === 0 ? (
          <div className="form-panel text-center text-gray-500">{t('common.noResult')}</div>
        ) : (
          filtered.map((b) => (
            <div key={b.id} className="form-panel space-y-3" data-testid="branch-mobile-card">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="font-mono text-xs text-blue-700">{b.code}</div>
                  <div className="font-semibold text-gray-900">{b.name}</div>
                  {b.shortName ? <div className="text-xs text-gray-500">{b.shortName}</div> : null}
                </div>
                <span className={`badge ${b.isActive ? 'badge-green' : 'badge-red'}`}>
                  {b.isActive ? 'Aktív' : 'Inaktív'}
                </span>
              </div>

              <div className="grid grid-cols-2 gap-3 text-sm">
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.terulet')}
                  </div>
                  <div>{b.region ?? '-'}</div>
                </div>
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.admin-stat')}
                  </div>
                  {renderStats(b)}
                </div>
                <div className="col-span-2">
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.kontakt')}
                  </div>
                  {b.email ? <div className="break-all">{b.email}</div> : null}
                  {b.phone ? <div className="text-gray-500">{b.phone}</div> : null}
                  {!b.email && !b.phone ? (
                    <span className="text-gray-400">{i18n.t('literals.lit-15')}</span>
                  ) : null}
                </div>
              </div>

              <div className="flex flex-wrap gap-1">
                <ServiceBadge label="ÁFA" active={b.hasAfa ?? false} />
                <ServiceBadge label="WU" active={b.hasWu ?? false} />
                <ServiceBadge label="MG" active={b.hasMg ?? false} />
                <ServiceBadge label="POS" active={b.hasPos ?? false} />
              </div>

              <label
                className="inline-flex items-center gap-2 cursor-pointer"
                title="Értéktári fiók"
              >
                <input
                  type="checkbox"
                  checked={b.isVault ?? false}
                  onChange={() => void handleToggleVault(b)}
                  className="form-checkbox h-4 w-4"
                />
                <span
                  className={`text-xs font-semibold ${b.isVault ? 'text-blue-700' : 'text-gray-400'}`}
                >
                  {i18n.t('literals.ertektar-2')}
                  {b.isVault ? 'IGEN' : 'nem'}
                </span>
              </label>

              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={() => openEdit(b)}
                  className="form-button flex min-h-10 items-center justify-center gap-1 text-xs"
                >
                  <Edit size={12} />
                  {t('common.edit')}
                </button>
                <button
                  onClick={() => handleDelete(b.id)}
                  className="form-button flex min-h-10 items-center justify-center gap-1 text-xs text-red-600"
                >
                  <Trash2 size={12} />
                  {t('common.delete')}
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
