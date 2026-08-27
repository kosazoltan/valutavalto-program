import { useState, useEffect, useCallback } from 'react'
import { Users, Plus, ArrowLeft, Pencil, Trash2, X } from 'lucide-react'
import {
  rateWorkgroupApi,
  rateCreationApi,
  currencyApi,
  type RateWorkgroupDTO,
  type RateWorkgroupSaveDTO,
  type BranchListItem,
  type Currency,
} from '../../services/api/index'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { sortWorkgroupsBySequence } from '../rates/workgroupOrdering'
import {
  DEFAULT_TILE,
  tileClasses,
  WorkgroupEditor,
  ConfirmDialog,
  type ConfirmState,
} from '../rates/workgroupMaintenance'
import i18n from '../../i18n'

// FK-02 pont 4: alapértelmezett táblázatstruktúra (J–S oszlopok). A részletes működés (képletezés,
// árfolyamvédelem, kedvezménysávok) külön fejlesztési kérés — itt csak a struktúrát jelenítjük meg.
const SHEET_COLUMNS: { col: string; label: string }[] = [
  { col: 'J', label: 'Elszámoló árfolyam' },
  { col: 'K', label: 'Valuta (ISO)' },
  { col: 'L', label: 'Alap vételi' },
  { col: 'M', label: 'Alap eladási' },
  { col: 'N', label: '1. kedv. vételi' },
  { col: 'O', label: '1. kedv. eladási' },
  { col: 'P', label: '2. kedv. vételi' },
  { col: 'Q', label: '2. kedv. eladási' },
  { col: 'R', label: 'Saját h. vételi' },
  { col: 'S', label: 'Saját h. eladási' },
]

export default function WorkgroupManager() {
  const [workgroups, setWorkgroups] = useState<RateWorkgroupDTO[]>([])
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState<RateWorkgroupDTO | null>(null)
  const [error, setError] = useState<string | null>(null)

  // Modálok
  const [editorOpen, setEditorOpen] = useState(false)
  const [editorMode, setEditorMode] = useState<'create' | 'rename'>('create')
  const [draft, setDraft] = useState<RateWorkgroupSaveDTO>({
    name: '',
    code: '',
    active: true,
    tileColor: DEFAULT_TILE.key,
  })
  const [confirm, setConfirm] = useState<ConfirmState | null>(null)

  const fetchWorkgroups = useCallback(async () => {
    try {
      setLoading(true)
      const list = await rateWorkgroupApi.list()
      // FK02-D (FR-14): a csempék mindig sorszám szerint növekvő sorrendben.
      setWorkgroups(
        sortWorkgroupsBySequence(safeArray<RateWorkgroupDTO>(list).filter((w) => w.active)),
      )
    } catch (err) {
      logger.error('WorkgroupManager', 'Lekérés sikertelen:', err)
      setError('A munkacsoportok betöltése sikertelen.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void fetchWorkgroups()
  }, [fetchWorkgroups])

  const openCreate = () => {
    setEditorMode('create')
    // FK02-E (FR-1, FR-2): a kódot ÉS (üres esetén) a sorszámot a szerver osztja ki a teljes
    // cég-scope alapján (inaktív csoportok sorszámát is figyelembe véve) → nincs ütközési hiba.
    setDraft({
      name: '',
      code: '',
      legacyGroupNumber: undefined,
      active: true,
      tileColor: DEFAULT_TILE.key,
      limit1Boundary: null,
      limit2Boundary: null,
      limit3Boundary: null,
    })
    setEditorOpen(true)
  }

  const openRename = (wg: RateWorkgroupDTO) => {
    setEditorMode('rename')
    setDraft({
      name: wg.name,
      code: wg.code,
      legacyGroupNumber: wg.legacyGroupNumber,
      active: wg.active,
      tileColor: wg.tileColor ?? DEFAULT_TILE.key,
      limit1Boundary: wg.limit1Boundary ?? null,
      limit2Boundary: wg.limit2Boundary ?? null,
      limit3Boundary: wg.limit3Boundary ?? null,
    })
    setEditorOpen(true)
  }

  const saveEditor = async () => {
    // FK02-E (FR-1): a kód és (üres esetén) a sorszám a szerveren képződik — csak a név kötelező.
    if (!draft.name.trim()) {
      setError('A név megadása kötelező.')
      return
    }
    try {
      if (editorMode === 'create') {
        await rateWorkgroupApi.create(draft)
      } else if (selected) {
        const updated = await rateWorkgroupApi.update(selected.id, draft)
        setSelected(updated)
      }
      setEditorOpen(false)
      setError(null)
      await fetchWorkgroups()
    } catch (err) {
      logger.error('WorkgroupManager', 'Mentés sikertelen:', err)
      setError('A mentés sikertelen (a kód már létezhet).')
    }
  }

  /**
   * FK-04/E.1: csempe jobb felső sarok árfolyamvédelem-checkbox toggle.
   * A backend `rate_workgroup.protection_enabled` flag-jét frissíti. A
   * tényleges save-validáció külön PR (E.2) — ez itt csak a flag perzisztálás.
   * Optimistic UI: helyi state azonnal frissül; hiba esetén visszaállít.
   */
  const toggleProtection = async (wg: RateWorkgroupDTO, next: boolean) => {
    const prev = wg.protectionEnabled ?? true
    // Optimistic: cseréljük a workgroups listában
    setWorkgroups((list) =>
      list.map((w) => (w.id === wg.id ? { ...w, protectionEnabled: next } : w)),
    )
    try {
      await rateWorkgroupApi.update(wg.id, {
        name: wg.name,
        code: wg.code,
        legacyGroupNumber: wg.legacyGroupNumber,
        active: wg.active,
        tileColor: wg.tileColor ?? null,
        protectionEnabled: next,
      })
    } catch (err) {
      logger.error('WorkgroupManager', 'Árfolyamvédelem-toggle sikertelen:', err)
      setError('A védelem mentése sikertelen — visszaállítva.')
      setWorkgroups((list) =>
        list.map((w) => (w.id === wg.id ? { ...w, protectionEnabled: prev } : w)),
      )
    }
  }

  const requestDelete = (wg: RateWorkgroupDTO) => {
    setConfirm({
      title: 'Munkacsoport törlése',
      message: `Biztosan törli a(z) "${wg.name}" munkacsoportot? A hozzárendelt pénztárak felszabadulnak, az árfolyam-előzmények megmaradnak.`,
      confirmLabel: 'Törlés',
      danger: true,
      onConfirm: async () => {
        try {
          await rateWorkgroupApi.remove(wg.id)
          setConfirm(null)
          setSelected(null)
          await fetchWorkgroups()
        } catch (err) {
          logger.error('WorkgroupManager', 'Törlés sikertelen:', err)
          setError('A törlés sikertelen.')
          setConfirm(null)
        }
      },
    })
  }

  // ---- Csempés lista nézet ----
  if (!selected) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold flex items-center gap-2">
            <Users className="h-5 w-5" />
            {i18n.t('literals.munkacsoportok')}
          </h2>
          <button
            className="form-button inline-flex items-center gap-1 px-3 py-1.5 text-sm"
            onClick={openCreate}
          >
            <Plus className="h-4 w-4" />
            {i18n.t('literals.uj-munkacsoport')}
          </button>
        </div>

        {error && <div className="form-error">{error}</div>}

        {loading ? (
          <p>{i18n.t('literals.betoltes-3')}</p>
        ) : workgroups.length === 0 ? (
          <p className="text-gray-500">
            {i18n.t('literals.meg-nincs-munkacsoport-hozzon-letre-egye')}
          </p>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
            {workgroups.map((wg) => {
              const protectionOn = wg.protectionEnabled ?? true
              return (
                <button
                  key={wg.id}
                  onClick={() => setSelected(wg)}
                  className={`text-left rounded-lg border-2 p-3 hover:shadow-md transition-shadow ${tileClasses(wg.tileColor)}`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="text-2xl font-bold leading-none">
                      {wg.legacyGroupNumber ?? '—'}
                    </div>
                    {/* FK-04 A.3 / E: jobb felső árfolyamvédelem checkbox.
                        stopPropagation, hogy a csempe-kattintás (megnyit) ne triggerelődjön. */}
                    <label
                      className="inline-flex items-center gap-1 text-[10px] font-medium cursor-pointer select-none"
                      title="Árfolyamvédelem: ha be van kapcsolva, a csoport-lap mentése blokkolja a hibás (vételi > J vagy eladási < J) értékeket."
                      onClick={(e) => e.stopPropagation()}
                    >
                      <input
                        type="checkbox"
                        checked={protectionOn}
                        onChange={(e) => {
                          e.stopPropagation()
                          void toggleProtection(wg, e.target.checked)
                        }}
                        className="h-3.5 w-3.5"
                        aria-label={`Árfolyamvédelem a(z) ${wg.name} csoporton`}
                      />
                      {i18n.t('literals.vedelem')}
                    </label>
                  </div>
                  <div className="mt-2 text-sm font-medium truncate" title={wg.name}>
                    {wg.name}
                  </div>
                  <div className="text-xs opacity-70">{wg.code}</div>
                </button>
              )
            })}
          </div>
        )}

        {editorOpen && (
          <WorkgroupEditor
            mode={editorMode}
            draft={draft}
            setDraft={setDraft}
            onSave={saveEditor}
            onCancel={() => {
              setEditorOpen(false)
              setError(null)
            }}
          />
        )}
        {confirm && <ConfirmDialog state={confirm} onCancel={() => setConfirm(null)} />}
      </div>
    )
  }

  // ---- Megnyitott munkacsoport (detail) nézet ----
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-2 flex-wrap">
        <div className="flex items-center gap-2">
          <button
            className="form-button-secondary inline-flex items-center gap-1 px-3 py-1.5 text-sm"
            onClick={() => setSelected(null)}
          >
            <ArrowLeft className="h-4 w-4" />
            {i18n.t('literals.vissza')}
          </button>
          <span
            className={`inline-flex items-center rounded px-2 py-1 text-sm font-bold border ${tileClasses(selected.tileColor)}`}
          >
            {selected.legacyGroupNumber ?? '—'}
          </span>
          <h2 className="text-lg font-semibold">{selected.name}</h2>
          <span className="text-sm text-gray-500">
            {i18n.t('literals.lit-19')}
            {selected.code}
            {i18n.t('literals.lit-2')}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <button
            className="form-button-secondary inline-flex items-center gap-1 px-3 py-1.5 text-sm"
            onClick={() => openRename(selected)}
          >
            <Pencil className="h-4 w-4" />
            {i18n.t('literals.atnevezes-szin')}
          </button>
          <button
            className="inline-flex items-center gap-1 rounded-md border border-red-300 bg-red-50 px-3 py-1.5 text-sm text-red-700 hover:bg-red-100"
            onClick={() => requestDelete(selected)}
          >
            <Trash2 className="h-4 w-4" />
            {i18n.t('literals.torles-2')}
          </button>
        </div>
      </div>

      {error && <div className="form-error">{error}</div>}

      <BranchAssignment workgroup={selected} onError={setError} confirm={setConfirm} />

      <DefaultRateTable />

      {editorOpen && (
        <WorkgroupEditor
          mode={editorMode}
          draft={draft}
          setDraft={setDraft}
          onSave={saveEditor}
          onCancel={() => {
            setEditorOpen(false)
            setError(null)
          }}
        />
      )}
      {confirm && <ConfirmDialog state={confirm} onCancel={() => setConfirm(null)} />}
    </div>
  )
}

// ============ Pénztár-hozzárendelés (felvétel / törlés / áthelyezés) ============
function BranchAssignment({
  workgroup,
  onError,
  confirm,
}: {
  workgroup: RateWorkgroupDTO
  onError: (msg: string | null) => void
  confirm: (c: ConfirmState) => void
}) {
  const [branches, setBranches] = useState<BranchListItem[]>([])
  const [loading, setLoading] = useState(true)

  const load = useCallback(async () => {
    try {
      setLoading(true)
      const list = await rateCreationApi.getBranches(workgroup.id)
      setBranches(safeArray<BranchListItem>(list))
    } catch (err) {
      logger.error('WorkgroupManager', 'Pénztárak betöltése sikertelen:', err)
      onError('A pénztárak betöltése sikertelen.')
    } finally {
      setLoading(false)
    }
  }, [workgroup.id, onError])

  useEffect(() => {
    void load()
  }, [load])

  const assigned = branches.filter((b) => b.assignedToCurrentWorkgroup)

  // A teljes-halmaz-csere (updateWorkgroupBranches) stale-state ellen: a megerősítéskor FRISSEN
  // lekért hozzárendelésből számoljuk a célhalmazt, nem a dialógus megnyitásakori closure-ből.
  const persistMutation = async (mutate: (assignedIds: string[]) => string[]) => {
    const fresh = await rateCreationApi.getBranches(workgroup.id)
    const assignedIds = safeArray<BranchListItem>(fresh)
      .filter((b) => b.assignedToCurrentWorkgroup)
      .map((b) => b.id)
    await rateCreationApi.updateWorkgroupBranches(workgroup.id, mutate(assignedIds))
    await load()
  }

  const addBranch = (b: BranchListItem) =>
    confirm({
      title: 'Pénztár felvétele',
      message: `Felveszi a(z) "${b.name}" pénztárt ebbe a munkacsoportba? Ha máshol szerepel, onnan átkerül ide.`,
      confirmLabel: 'Felvétel',
      onConfirm: async () => {
        await persistMutation((ids) => Array.from(new Set([...ids, b.id])))
      },
    })

  const removeBranch = (b: BranchListItem) =>
    confirm({
      title: 'Pénztár eltávolítása',
      message: `Eltávolítja a(z) "${b.name}" pénztárt ebből a munkacsoportból?`,
      confirmLabel: 'Eltávolítás',
      danger: true,
      onConfirm: async () => {
        await persistMutation((ids) => ids.filter((x) => x !== b.id))
      },
    })

  if (loading)
    return <p className="text-sm text-gray-500">{i18n.t('literals.penztarak-betoltese')}</p>

  return (
    <div className="rounded-lg border bg-card p-3">
      <h3 className="text-sm font-semibold mb-2">
        {i18n.t('literals.penztarak')}
        {assigned.length}
        {i18n.t('literals.lit-2')}
      </h3>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-1">
        {branches.map((b) => (
          <div
            key={b.id}
            className={`flex items-center justify-between rounded border px-2 py-1 text-sm ${b.assignedToCurrentWorkgroup ? 'bg-green-50 border-green-200' : 'bg-gray-50'}`}
          >
            <span className="truncate" title={`${b.name} (${b.city})`}>
              {b.name}
            </span>
            {b.assignedToCurrentWorkgroup ? (
              <button
                className="text-red-600 hover:text-red-800 shrink-0"
                title="Eltávolítás"
                onClick={() => removeBranch(b)}
              >
                <X className="h-4 w-4" />
              </button>
            ) : (
              <button
                className="text-green-600 hover:text-green-800 shrink-0"
                title="Felvétel"
                onClick={() => addBranch(b)}
              >
                <Plus className="h-4 w-4" />
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

// ============ Alapértelmezett táblázatstruktúra (J–S, sorok = aktív valuták) ============
function DefaultRateTable() {
  const [currencies, setCurrencies] = useState<Currency[]>([])

  useEffect(() => {
    currencyApi
      .list()
      .then((list) => setCurrencies(safeArray<Currency>(list)))
      .catch((err) => logger.warn('WorkgroupManager', 'Valutalista betöltése sikertelen', err))
  }, [])

  return (
    <div className="rounded-lg border bg-card p-3 overflow-x-auto">
      <h3 className="text-sm font-semibold mb-2">
        {i18n.t('literals.arfolyamlap-struktura')}
        {currencies.length}
        {i18n.t('literals.valuta-3')}
      </h3>
      <p className="text-xs text-gray-500 mb-2">
        {i18n.t('literals.a-reszletes-kepletezes-es-arfolyamvedele')}
      </p>
      <table className="w-full text-xs border-collapse">
        <thead>
          <tr className="bg-gray-100">
            {SHEET_COLUMNS.map((c) => (
              <th key={c.col} className="border px-2 py-1 text-left whitespace-nowrap">
                <span className="font-mono text-gray-400">{c.col}</span> {c.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {currencies.map((cur) => (
            <tr key={cur.id}>
              {SHEET_COLUMNS.map((c) => (
                <td key={c.col} className="border px-2 py-1 whitespace-nowrap">
                  {c.col === 'K' ? (
                    <span className="font-mono font-semibold">{cur.code}</span>
                  ) : (
                    <span className="text-gray-300">{i18n.t('literals.lit-8')}</span>
                  )}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
