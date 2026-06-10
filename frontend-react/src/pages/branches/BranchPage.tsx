import { useState, useEffect, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Building2, Plus, Edit, Trash2, Search } from 'lucide-react'
import { api } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'

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
      const res = await api.get('/branches', { params: { clientType: 'CENTRAL' } })
      setBranches(safeArray<Branch>(res.data))
    } catch (err) {
      logger.error('BranchPage', 'load error', err)
      setError(getErrorMessage(err))
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
      toast.success(next ? `${b.code}: értéktárként megjelölve` : `${b.code}: pénztárként megjelölve`)
      await load()
    } catch (err) {
      toast.error('Hiba az is_vault frissítésekor', getErrorMessage(err))
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Betöltés...</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Building2 />
          Pénztár Törzs Adatbázis
          <span className="text-sm font-normal text-gray-500" data-testid="branch-count">
            ({filtered.length} pénztár)
          </span>
        </h1>
        <button onClick={() => navigate('/admin/branches/new')} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          Új pénztár
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      <div className="form-panel">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[220px]">
            <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
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
            className="form-input w-auto"
            value={territoryFilter}
            onChange={(e) => setTerritoryFilter(e.target.value)}
            aria-label="Területi szűrő"
          >
            <option value="">Minden terület</option>
            {territories.map((r) => (
              <option key={r} value={r}>{r}</option>
            ))}
          </select>
          <label className="inline-flex items-center gap-2 cursor-pointer whitespace-nowrap">
            <input
              type="checkbox"
              className="form-checkbox h-4 w-4"
              checked={showInactive}
              onChange={(e) => setShowInactive(e.target.checked)}
            />
            <span className="text-sm">Inaktívak is</span>
          </label>
        </div>
      </div>

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('common.code')}</th>
              <th>Pénztár neve</th>
              <th>Terület</th>
              <th>Szolgáltatások</th>
              <th>Kontakt</th>
              <th>{t('common.status')}</th>
              <th>{t('branches.ertektar')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center text-gray-500 py-4">{t('common.noResult')}</td>
              </tr>
            ) : (
              filtered.map((b) => (
                <tr key={b.id}>
                  <td className="font-mono text-sm">{b.code}</td>
                  <td>{b.name}{b.shortName ? <span className="text-gray-400 text-xs ml-1">({b.shortName})</span> : null}</td>
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
                    {b.email ? <div className="truncate max-w-[180px]" title={b.email}>{b.email}</div> : null}
                    {b.phone ? <div className="text-gray-500">{b.phone}</div> : null}
                    {!b.email && !b.phone ? <span className="text-gray-400">-</span> : null}
                  </td>
                  <td>
                    <span className={`badge ${b.isActive ? 'badge-green' : 'badge-red'}`}>
                      {b.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td>
                    <label className="inline-flex items-center gap-2 cursor-pointer" title="Értéktári fiók">
                      <input
                        type="checkbox"
                        checked={b.isVault ?? false}
                        onChange={() => void handleToggleVault(b)}
                        className="form-checkbox h-4 w-4"
                      />
                      <span className={`text-xs font-semibold ${b.isVault ? 'text-blue-700' : 'text-gray-400'}`}>
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
    </div>
  )
}
