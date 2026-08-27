import { useState, useEffect, useMemo } from 'react'
import { Users, Search, ChevronDown, ChevronRight } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { roleDisplayName } from '../../utils/appModeRoles'
import type { components } from '@valuta/shared-api'
import i18n from '../../i18n'

// FK-026: read-only Dolgozói Törzs Adatbázis lista. A backend GET /api/v1/workers
// most már tartalmazza a region és roleCodes mezőket (WorkerDto bővítés).
// Copilot #1124: az OpenAPI WorkerDto minden mezője opcionális; a WorkerPage-hez hasonló
// "local kontraktus" — a stabil mezőket (id/workerCode/fullName) nem-null-ként kezeljük.
type WorkerDto = components['schemas']['WorkerDto']
type Worker = Required<Pick<WorkerDto, 'id' | 'workerCode' | 'fullName'>> & Partial<WorkerDto>

interface GroupDef {
  key: string
  label: string
  codes: string[]
}

// FK-026 §2: a 14 kanonikus munkakör-kód 3 megjelenítési csoportba sorolva.
// Tisztán frontend-oldali csoportosítás (nem adatbázis-mező).
const GROUPS: GroupDef[] = [
  { key: 'operativ', label: 'Operatív', codes: ['penztar', 'ertektar', 'ertekszallito'] },
  {
    key: 'vezetoi',
    label: 'Vezetői/Felügyeleti',
    codes: [
      'foertektar',
      'teruleti_vezeto',
      'csoportvezeto',
      'irodavezeto',
      'ugyvezeto',
      'biztonsagi_vezeto',
      'penzugyi_vezeto',
      'belso_ellenor',
    ],
  },
  {
    key: 'egyeb',
    label: 'Egyéb/Háttér',
    codes: ['irodai_dolgozo', 'berszamfejto', 'arfolyam_nezo'],
  },
]

const EGYEB_KEY = 'egyeb'

// Munkakör-kód → csoportkulcs gyors keresés.
const CODE_TO_GROUP: Record<string, string> = (() => {
  const map: Record<string, string> = {}
  for (const g of GROUPS) for (const c of g.codes) map[c] = g.key
  return map
})()

/**
 * FK-026: egy dolgozó munkakör-kódjait csoportokra bontja, a roleCodes sorrendjét
 * megtartva. FR-10: üres roleCodes → az "Egyéb/Háttér" csoportban jelenik meg (üres
 * kódlistával, ami "–"-ként renderelődik). Ismeretlen (csoportba nem sorolt) kód
 * defenzív fallbackként szintén az Egyéb/Háttérbe kerül, hogy senki ne tűnjön el.
 */
function groupedRolesFor(worker: Worker): Record<string, string[]> {
  const result: Record<string, string[]> = {}
  const codes = worker.roleCodes ?? []
  if (codes.length === 0) {
    result[EGYEB_KEY] = []
    return result
  }
  for (const code of codes) {
    const gk = CODE_TO_GROUP[code] ?? EGYEB_KEY
    ;(result[gk] ??= []).push(code)
  }
  return result
}

/** FR-7/FR-9/FR-10: a csoporthoz tartozó munkakör-kódok magyar neve, vesszővel; üres → "–". */
function roleColumn(codes: string[]): string {
  if (codes.length === 0) return '–'
  return codes.map(roleDisplayName).join(', ')
}

interface GroupSectionProps {
  group: GroupDef
  rows: { worker: Worker; codes: string[] }[]
}

function GroupSection({ group, rows }: GroupSectionProps) {
  const [open, setOpen] = useState(true)
  return (
    <div className="form-panel" data-testid={`group-${group.key}`}>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex items-center gap-2 w-full text-left font-bold text-gray-800 mb-2"
        aria-expanded={open}
        aria-label={`${group.label} szekció`}
      >
        {open ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
        {group.label}
        <span className="text-sm font-normal text-gray-500">
          {i18n.t('literals.lit-19')}
          {rows.length}
          {i18n.t('literals.dolgozo-3')}
        </span>
      </button>
      {open && (
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{i18n.t('literals.kod-3')}</th>
              <th>{i18n.t('literals.teljes-nev')}</th>
              <th>{i18n.t('literals.terulet')}</th>
              <th>{i18n.t('literals.munkakor')}</th>
              <th>{i18n.t('literals.statusz')}</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td colSpan={5} className="text-center text-gray-500 py-4">
                  {i18n.t('literals.nincs-dolgozo-ebben-a-csoportban')}
                </td>
              </tr>
            ) : (
              rows.map(({ worker, codes }) => (
                <tr key={`${group.key}-${worker.id}`}>
                  <td className="font-mono text-sm">{worker.workerCode ?? '–'}</td>
                  <td>{worker.fullName ?? '–'}</td>
                  <td className="text-sm">
                    {worker.region && worker.region.trim() ? worker.region : 'Nincs megadva'}
                  </td>
                  <td className="text-sm">{roleColumn(codes)}</td>
                  <td>
                    <span className={`badge ${worker.active ? 'badge-green' : 'badge-red'}`}>
                      {worker.active ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      )}
    </div>
  )
}

export default function WorkersDatabasePage() {
  const [workers, setWorkers] = useState<Worker[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  // FK-026 FR-11: területi szűrő a region mező alapján.
  const [territoryFilter, setTerritoryFilter] = useState('')

  // FK-026: a területi szűrő legördülő dinamikusan a betöltött adatból épül.
  const territories = useMemo(() => {
    const set = new Set<string>()
    for (const w of workers) {
      if (w.region && w.region.trim()) set.add(w.region.trim())
    }
    return Array.from(set).sort((a, z) => a.localeCompare(z, 'hu'))
  }, [workers])

  const filteredWorkers = useMemo(() => {
    const term = searchTerm.trim().toLowerCase()
    return workers.filter((w) => {
      if (territoryFilter && (w.region?.trim() ?? '') !== territoryFilter) return false
      if (!term) return true
      return (
        (w.fullName ?? '').toLowerCase().includes(term) ||
        (w.workerCode ?? '').toLowerCase().includes(term)
      )
    })
  }, [workers, searchTerm, territoryFilter])

  // FK-026 FR-5/FR-8/FR-9: csoportonkénti sorok. Egy dolgozó több csoportban is
  // megjelenhet (különböző csoportba eső munkakörökkel), csoporton belül egy sorként.
  const rowsByGroup = useMemo(() => {
    const out: Record<string, { worker: Worker; codes: string[] }[]> = {}
    for (const g of GROUPS) out[g.key] = []
    for (const w of filteredWorkers) {
      const grouped = groupedRolesFor(w)
      for (const g of GROUPS) {
        const codes = grouped[g.key]
        if (codes) (out[g.key] ??= []).push({ worker: w, codes })
      }
    }
    return out
  }, [filteredWorkers])

  const load = async () => {
    try {
      setLoading(true)
      setError(null)
      // FK-026 (Codex #1124 P1): dedikált read-only directory végpont, amely a kanonikus
      // olvasó szerepköröknek (foertektar/belso_ellenor/ugyvezeto) is elérhető — a sima
      // /workers SUPERVISOR/MANAGER/ADMIN-ra korlátoz, így 403 lenne 2 szerepkörnél.
      const res = await api.get('/workers/directory')
      setWorkers(safeArray<Worker>(res.data))
    } catch (err) {
      logger.error('WorkersDatabasePage', 'load error', err)
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
          <Users />
          {i18n.t('literals.dolgozoi-torzs-adatbazis')}
          <span className="text-sm font-normal text-gray-500" data-testid="worker-count">
            {i18n.t('literals.lit-19')}
            {filteredWorkers.length}
            {i18n.t('literals.dolgozo-3')}
          </span>
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[220px]">
            <Search
              className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
              size={16}
            />
            <input
              type="text"
              className="form-input pl-8 w-full"
              placeholder="Keresés névben, kódban..."
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
            <option value="">{i18n.t('literals.osszes-terulet')}</option>
            {territories.map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </select>
        </div>
      </div>

      {GROUPS.map((g) => (
        <GroupSection key={g.key} group={g} rows={rowsByGroup[g.key] ?? []} />
      ))}
    </div>
  )
}
