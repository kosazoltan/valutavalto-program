import { useState, useEffect, useCallback } from 'react'
import { Users, Plus, ArrowLeft, Pencil, Trash2, Save, X, Check } from 'lucide-react'
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

// FK-02: 10 választható csempeszín — paletta-kulcs → Tailwind osztályok. A kulcsot tároljuk a
// backendben (tile_color), így a megjelenítés független a nyers hex-től, és témázható.
const TILE_PALETTE: { key: string; label: string; tile: string; swatch: string }[] = [
  { key: 'slate', label: 'Szürke', tile: 'bg-slate-100 border-slate-300 text-slate-800', swatch: 'bg-slate-400' },
  { key: 'red', label: 'Piros', tile: 'bg-red-100 border-red-300 text-red-800', swatch: 'bg-red-400' },
  { key: 'orange', label: 'Narancs', tile: 'bg-orange-100 border-orange-300 text-orange-800', swatch: 'bg-orange-400' },
  { key: 'amber', label: 'Borostyán', tile: 'bg-amber-100 border-amber-300 text-amber-800', swatch: 'bg-amber-400' },
  { key: 'green', label: 'Zöld', tile: 'bg-green-100 border-green-300 text-green-800', swatch: 'bg-green-400' },
  { key: 'teal', label: 'Türkiz', tile: 'bg-teal-100 border-teal-300 text-teal-800', swatch: 'bg-teal-400' },
  { key: 'sky', label: 'Égkék', tile: 'bg-sky-100 border-sky-300 text-sky-800', swatch: 'bg-sky-400' },
  { key: 'indigo', label: 'Indigó', tile: 'bg-indigo-100 border-indigo-300 text-indigo-800', swatch: 'bg-indigo-400' },
  { key: 'purple', label: 'Lila', tile: 'bg-purple-100 border-purple-300 text-purple-800', swatch: 'bg-purple-400' },
  { key: 'pink', label: 'Rózsaszín', tile: 'bg-pink-100 border-pink-300 text-pink-800', swatch: 'bg-pink-400' },
]
const DEFAULT_TILE = TILE_PALETTE[0]!

function tileClasses(colorKey: string | null | undefined): string {
  return (TILE_PALETTE.find(p => p.key === colorKey) ?? DEFAULT_TILE).tile
}

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

interface ConfirmState {
  title: string
  message: string
  confirmLabel: string
  danger?: boolean
  onConfirm: () => void | Promise<void>
}

export default function WorkgroupManager() {
  const [workgroups, setWorkgroups] = useState<RateWorkgroupDTO[]>([])
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState<RateWorkgroupDTO | null>(null)
  const [error, setError] = useState<string | null>(null)

  // Modálok
  const [editorOpen, setEditorOpen] = useState(false)
  const [editorMode, setEditorMode] = useState<'create' | 'rename'>('create')
  const [draft, setDraft] = useState<RateWorkgroupSaveDTO>({ name: '', code: '', active: true, tileColor: DEFAULT_TILE.key })
  const [confirm, setConfirm] = useState<ConfirmState | null>(null)

  const fetchWorkgroups = useCallback(async () => {
    try {
      setLoading(true)
      const list = await rateWorkgroupApi.list()
      setWorkgroups(safeArray<RateWorkgroupDTO>(list).filter(w => w.active))
    } catch (err) {
      logger.error('WorkgroupManager', 'Lekérés sikertelen:', err)
      setError('A munkacsoportok betöltése sikertelen.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { void fetchWorkgroups() }, [fetchWorkgroups])

  const openCreate = () => {
    setEditorMode('create')
    setDraft({ name: '', code: '', legacyGroupNumber: undefined, active: true, tileColor: DEFAULT_TILE.key })
    setEditorOpen(true)
  }

  const openRename = (wg: RateWorkgroupDTO) => {
    setEditorMode('rename')
    setDraft({ name: wg.name, code: wg.code, legacyGroupNumber: wg.legacyGroupNumber, active: wg.active, tileColor: wg.tileColor ?? DEFAULT_TILE.key })
    setEditorOpen(true)
  }

  const saveEditor = async () => {
    if (!draft.name.trim() || !draft.code.trim()) {
      setError('A név és a kód megadása kötelező.')
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
            Munkacsoportok
          </h2>
          <button className="form-button inline-flex items-center gap-1 px-3 py-1.5 text-sm" onClick={openCreate}>
            <Plus className="h-4 w-4" /> Új munkacsoport
          </button>
        </div>

        {error && <div className="form-error">{error}</div>}

        {loading ? (
          <p>Betöltés…</p>
        ) : workgroups.length === 0 ? (
          <p className="text-gray-500">Még nincs munkacsoport. Hozzon létre egyet az „Új munkacsoport” gombbal.</p>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
            {workgroups.map(wg => (
              <button
                key={wg.id}
                onClick={() => setSelected(wg)}
                className={`text-left rounded-lg border-2 p-3 hover:shadow-md transition-shadow ${tileClasses(wg.tileColor)}`}
              >
                <div className="text-2xl font-bold leading-none">{wg.legacyGroupNumber ?? '—'}</div>
                <div className="mt-2 text-sm font-medium truncate" title={wg.name}>{wg.name}</div>
                <div className="text-xs opacity-70">{wg.code}</div>
              </button>
            ))}
          </div>
        )}

        {editorOpen && (
          <WorkgroupEditor
            mode={editorMode}
            draft={draft}
            setDraft={setDraft}
            onSave={saveEditor}
            onCancel={() => { setEditorOpen(false); setError(null) }}
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
          <button className="form-button-secondary inline-flex items-center gap-1 px-3 py-1.5 text-sm" onClick={() => setSelected(null)}>
            <ArrowLeft className="h-4 w-4" /> Vissza
          </button>
          <span className={`inline-flex items-center rounded px-2 py-1 text-sm font-bold border ${tileClasses(selected.tileColor)}`}>
            {selected.legacyGroupNumber ?? '—'}
          </span>
          <h2 className="text-lg font-semibold">{selected.name}</h2>
          <span className="text-sm text-gray-500">({selected.code})</span>
        </div>
        <div className="flex items-center gap-2">
          <button className="form-button-secondary inline-flex items-center gap-1 px-3 py-1.5 text-sm" onClick={() => openRename(selected)}>
            <Pencil className="h-4 w-4" /> Átnevezés / szín
          </button>
          <button className="inline-flex items-center gap-1 rounded-md border border-red-300 bg-red-50 px-3 py-1.5 text-sm text-red-700 hover:bg-red-100" onClick={() => requestDelete(selected)}>
            <Trash2 className="h-4 w-4" /> Törlés
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
          onCancel={() => { setEditorOpen(false); setError(null) }}
        />
      )}
      {confirm && <ConfirmDialog state={confirm} onCancel={() => setConfirm(null)} />}
    </div>
  )
}

// ============ Szerkesztő modal (létrehozás / átnevezés + szín) ============
function WorkgroupEditor({ mode, draft, setDraft, onSave, onCancel }: {
  mode: 'create' | 'rename'
  draft: RateWorkgroupSaveDTO
  setDraft: (d: RateWorkgroupSaveDTO) => void
  onSave: () => void
  onCancel: () => void
}) {
  return (
    <Overlay onCancel={onCancel}>
      <h3 className="text-base font-semibold mb-3">{mode === 'create' ? 'Új munkacsoport' : 'Munkacsoport átnevezése'}</h3>
      <div className="space-y-3">
        <div>
          <label className="text-sm font-medium">Név</label>
          <input className="form-input w-full" value={draft.name} placeholder="pl. Budapest központ"
            onChange={e => setDraft({ ...draft, name: e.target.value })} />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="text-sm font-medium">Kód</label>
            <input className="form-input w-full" value={draft.code} placeholder="pl. WG01" disabled={mode === 'rename'}
              onChange={e => setDraft({ ...draft, code: e.target.value })} />
          </div>
          <div>
            <label className="text-sm font-medium">Sorszám</label>
            <input className="form-input w-full" type="number" value={draft.legacyGroupNumber ?? ''}
              onChange={e => setDraft({ ...draft, legacyGroupNumber: e.target.value === '' ? undefined : parseInt(e.target.value, 10) })} />
          </div>
        </div>
        <div>
          <label className="text-sm font-medium">Csempeszín</label>
          <div className="flex flex-wrap gap-2 mt-1">
            {TILE_PALETTE.map(p => (
              <button key={p.key} type="button" title={p.label}
                onClick={() => setDraft({ ...draft, tileColor: p.key })}
                className={`h-7 w-7 rounded-full ${p.swatch} flex items-center justify-center ring-2 ${draft.tileColor === p.key ? 'ring-gray-800' : 'ring-transparent'}`}>
                {draft.tileColor === p.key && <Check className="h-4 w-4 text-white" />}
              </button>
            ))}
          </div>
        </div>
      </div>
      <div className="flex justify-end gap-2 mt-4">
        <button className="form-button-secondary inline-flex items-center gap-1 px-3 py-1.5 text-sm" onClick={onCancel}>
          <X className="h-4 w-4" /> Mégse
        </button>
        <button className="form-button inline-flex items-center gap-1 px-3 py-1.5 text-sm" onClick={onSave}>
          <Save className="h-4 w-4" /> Mentés
        </button>
      </div>
    </Overlay>
  )
}

// ============ Pénztár-hozzárendelés (felvétel / törlés / áthelyezés) ============
function BranchAssignment({ workgroup, onError, confirm }: {
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

  useEffect(() => { void load() }, [load])

  const assigned = branches.filter(b => b.assignedToCurrentWorkgroup)

  // A teljes-halmaz-csere (updateWorkgroupBranches) stale-state ellen: a megerősítéskor FRISSEN
  // lekért hozzárendelésből számoljuk a célhalmazt, nem a dialógus megnyitásakori closure-ből.
  const persistMutation = async (mutate: (assignedIds: string[]) => string[]) => {
    const fresh = await rateCreationApi.getBranches(workgroup.id)
    const assignedIds = safeArray<BranchListItem>(fresh).filter(b => b.assignedToCurrentWorkgroup).map(b => b.id)
    await rateCreationApi.updateWorkgroupBranches(workgroup.id, mutate(assignedIds))
    await load()
  }

  const addBranch = (b: BranchListItem) => confirm({
    title: 'Pénztár felvétele',
    message: `Felveszi a(z) "${b.name}" pénztárt ebbe a munkacsoportba? Ha máshol szerepel, onnan átkerül ide.`,
    confirmLabel: 'Felvétel',
    onConfirm: async () => { await persistMutation(ids => Array.from(new Set([...ids, b.id]))); },
  })

  const removeBranch = (b: BranchListItem) => confirm({
    title: 'Pénztár eltávolítása',
    message: `Eltávolítja a(z) "${b.name}" pénztárt ebből a munkacsoportból?`,
    confirmLabel: 'Eltávolítás',
    danger: true,
    onConfirm: async () => { await persistMutation(ids => ids.filter(x => x !== b.id)); },
  })

  if (loading) return <p className="text-sm text-gray-500">Pénztárak betöltése…</p>

  return (
    <div className="rounded-lg border bg-card p-3">
      <h3 className="text-sm font-semibold mb-2">Pénztárak ({assigned.length})</h3>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-1">
        {branches.map(b => (
          <div key={b.id} className={`flex items-center justify-between rounded border px-2 py-1 text-sm ${b.assignedToCurrentWorkgroup ? 'bg-green-50 border-green-200' : 'bg-gray-50'}`}>
            <span className="truncate" title={`${b.name} (${b.city})`}>{b.name}</span>
            {b.assignedToCurrentWorkgroup ? (
              <button className="text-red-600 hover:text-red-800 shrink-0" title="Eltávolítás" onClick={() => removeBranch(b)}>
                <X className="h-4 w-4" />
              </button>
            ) : (
              <button className="text-green-600 hover:text-green-800 shrink-0" title="Felvétel" onClick={() => addBranch(b)}>
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
    currencyApi.list()
      .then(list => setCurrencies(safeArray<Currency>(list)))
      .catch(err => logger.warn('WorkgroupManager', 'Valutalista betöltése sikertelen', err))
  }, [])

  return (
    <div className="rounded-lg border bg-card p-3 overflow-x-auto">
      <h3 className="text-sm font-semibold mb-2">Árfolyamlap-struktúra ({currencies.length} valuta)</h3>
      <p className="text-xs text-gray-500 mb-2">A részletes képletezés és árfolyamvédelem külön fejlesztési kérés tárgya lesz.</p>
      <table className="w-full text-xs border-collapse">
        <thead>
          <tr className="bg-gray-100">
            {SHEET_COLUMNS.map(c => (
              <th key={c.col} className="border px-2 py-1 text-left whitespace-nowrap">
                <span className="font-mono text-gray-400">{c.col}</span> {c.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {currencies.map(cur => (
            <tr key={cur.id}>
              {SHEET_COLUMNS.map(c => (
                <td key={c.col} className="border px-2 py-1 whitespace-nowrap">
                  {c.col === 'K' ? <span className="font-mono font-semibold">{cur.code}</span> : <span className="text-gray-300">—</span>}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// ============ Megerősítő párbeszédablak ============
function ConfirmDialog({ state, onCancel }: { state: ConfirmState; onCancel: () => void }) {
  return (
    <Overlay onCancel={onCancel}>
      <h3 className="text-base font-semibold mb-2">{state.title}</h3>
      <p className="text-sm text-gray-600 mb-4">{state.message}</p>
      <div className="flex justify-end gap-2">
        <button className="form-button-secondary px-3 py-1.5 text-sm" onClick={onCancel}>Mégse</button>
        <button
          className={`px-3 py-1.5 text-sm rounded-md text-white ${state.danger ? 'bg-red-600 hover:bg-red-700' : 'bg-primary hover:bg-primary/90'}`}
          onClick={() => { void state.onConfirm() }}
        >
          {state.confirmLabel}
        </button>
      </div>
    </Overlay>
  )
}

function Overlay({ children, onCancel }: { children: React.ReactNode; onCancel: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onCancel}>
      <div className="w-full max-w-md rounded-lg bg-white p-4 shadow-xl" onClick={e => e.stopPropagation()}>
        {children}
      </div>
    </div>
  )
}
