import type { ReactNode } from 'react'
import { Save, X, Check } from 'lucide-react'
import type { RateWorkgroupSaveDTO } from '../../services/api/index'
import i18n from '../../i18n'

/**
 * FK-02 — megosztott munkacsoport-karbantartó primitívek.
 *
 * Egyetlen forrás a csempeszín-palettához, a megerősítő/overlay modálokhoz és a
 * létrehozás/átnevezés-szerkesztőhöz. Fogyasztói:
 *  - admin: `pages/ratemanagement/WorkgroupManager.tsx` (már erről olvas)
 *  - árfolyamkészítő: `pages/rates/RateCreationPage.tsx` (csempés kezelő nézet — a
 *    karbantartó funkciókat bekötő követő PR áll rá)
 *
 * Korábban mindkét helyen külön (drifteltt) másolat élt — ez a modul szünteti meg
 * a duplikációt, hogy a paletta-kulcsok és a szerkesztő-mezők egységesek legyenek.
 */

// FK-02: 10 választható csempeszín — paletta-kulcs → Tailwind osztályok. A kulcsot tároljuk a
// backendben (tile_color), így a megjelenítés független a nyers hex-től, és témázható.
export interface TilePaletteEntry {
  key: string
  label: string
  /** Csempe-háttér + keret + szöveg + hover (a csempés gombokhoz). */
  tile: string
  /** Színkorong a szerkesztő paletta-választójához. */
  swatch: string
}

export const TILE_PALETTE: TilePaletteEntry[] = [
  {
    key: 'slate',
    label: 'Szürke',
    tile: 'bg-slate-100 border-slate-300 text-slate-800 hover:bg-slate-200',
    swatch: 'bg-slate-400',
  },
  {
    key: 'red',
    label: 'Piros',
    tile: 'bg-red-100 border-red-300 text-red-800 hover:bg-red-200',
    swatch: 'bg-red-400',
  },
  {
    key: 'orange',
    label: 'Narancs',
    tile: 'bg-orange-100 border-orange-300 text-orange-800 hover:bg-orange-200',
    swatch: 'bg-orange-400',
  },
  {
    key: 'amber',
    label: 'Borostyán',
    tile: 'bg-amber-100 border-amber-300 text-amber-800 hover:bg-amber-200',
    swatch: 'bg-amber-400',
  },
  {
    key: 'green',
    label: 'Zöld',
    tile: 'bg-green-100 border-green-300 text-green-800 hover:bg-green-200',
    swatch: 'bg-green-400',
  },
  {
    key: 'teal',
    label: 'Türkiz',
    tile: 'bg-teal-100 border-teal-300 text-teal-800 hover:bg-teal-200',
    swatch: 'bg-teal-400',
  },
  {
    key: 'sky',
    label: 'Égkék',
    tile: 'bg-sky-100 border-sky-300 text-sky-800 hover:bg-sky-200',
    swatch: 'bg-sky-400',
  },
  {
    key: 'indigo',
    label: 'Indigó',
    tile: 'bg-indigo-100 border-indigo-300 text-indigo-800 hover:bg-indigo-200',
    swatch: 'bg-indigo-400',
  },
  {
    key: 'purple',
    label: 'Lila',
    tile: 'bg-purple-100 border-purple-300 text-purple-800 hover:bg-purple-200',
    swatch: 'bg-purple-400',
  },
  {
    key: 'pink',
    label: 'Rózsaszín',
    tile: 'bg-pink-100 border-pink-300 text-pink-800 hover:bg-pink-200',
    swatch: 'bg-pink-400',
  },
]

export const DEFAULT_TILE = TILE_PALETTE[0]!

/** Paletta-kulcs → Tailwind csempe-osztályok; ismeretlen/null kulcs → alapértelmezett. */
export function tileClasses(colorKey: string | null | undefined): string {
  return (TILE_PALETTE.find((p) => p.key === colorKey) ?? DEFAULT_TILE).tile
}

export interface ConfirmState {
  title: string
  message: string
  confirmLabel: string
  danger?: boolean
  onConfirm: () => void | Promise<void>
}

/** Sötétített modal-háttér; háttér-kattintásra bezár, a panel-kattintás nem propagál. */
export function Overlay({ children, onCancel }: { children: ReactNode; onCancel: () => void }) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-md rounded-lg bg-white p-4 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        {children}
      </div>
    </div>
  )
}

/** Megerősítő párbeszédablak (FK-02 §3: minden karbantartó művelet előtt). */
export function ConfirmDialog({ state, onCancel }: { state: ConfirmState; onCancel: () => void }) {
  return (
    <Overlay onCancel={onCancel}>
      <h3 className="text-base font-semibold mb-2">{state.title}</h3>
      <p className="text-sm text-gray-600 mb-4">{state.message}</p>
      <div className="flex justify-end gap-2">
        <button className="form-button-secondary px-3 py-1.5 text-sm" onClick={onCancel}>
          {i18n.t('literals.megse')}
        </button>
        <button
          className={`px-3 py-1.5 text-sm rounded-md text-white ${state.danger ? 'bg-red-600 hover:bg-red-700' : 'bg-primary hover:bg-primary/90'}`}
          onClick={() => {
            void state.onConfirm()
          }}
        >
          {state.confirmLabel}
        </button>
      </div>
    </Overlay>
  )
}

/**
 * Munkacsoport létrehozó/átnevező szerkesztő: név, kód (átnevezésnél zárolt),
 * sorszám, csempeszín-paletta és FK-04/D kedvezményhatárok.
 */
export function WorkgroupEditor({
  mode,
  draft,
  setDraft,
  onSave,
  onCancel,
}: {
  mode: 'create' | 'rename'
  draft: RateWorkgroupSaveDTO
  setDraft: (d: RateWorkgroupSaveDTO) => void
  onSave: () => void
  onCancel: () => void
}) {
  return (
    <Overlay onCancel={onCancel}>
      <h3 className="text-base font-semibold mb-3">
        {mode === 'create' ? 'Új munkacsoport' : 'Munkacsoport átnevezése'}
      </h3>
      <div className="space-y-3">
        <div>
          <label className="text-sm font-medium">{i18n.t('literals.nev')}</label>
          <input
            className="form-input w-full"
            value={draft.name}
            placeholder="pl. Budapest központ"
            onChange={(e) => setDraft({ ...draft, name: e.target.value })}
          />
        </div>
        {/* FK02-E (FR-1): a Kód mező eltávolítva — a rendszer automatikusan generálja a sorszámból
            (GROUP_NN). A felhasználó csak a sorszámot adja meg (az „Új munkacsoport"-nál előtöltve
            a következő szabad értékkel). */}
        <div>
          <label className="text-sm font-medium">{i18n.t('literals.sorszam')}</label>
          <input
            className="form-input w-full"
            type="number"
            min="1"
            placeholder="automatikus (következő szabad)"
            value={draft.legacyGroupNumber ?? ''}
            onChange={(e) => {
              const n = parseInt(e.target.value, 10)
              setDraft({
                ...draft,
                legacyGroupNumber: e.target.value.trim() === '' || Number.isNaN(n) ? undefined : n,
              })
            }}
          />
          <p className="text-xs text-gray-500 mt-1">
            {i18n.t('literals.uresen-hagyva-a-rendszer-a-kovetkezo-sza')}
            { }
            {i18n.t('literals.a-sorszambol-pl')}{' '}
            <span className="font-mono">{i18n.t('literals.group-03')}</span>
            {i18n.t('literals.lit-51')}
          </p>
        </div>
        <div>
          <label className="text-sm font-medium">{i18n.t('literals.csempeszin')}</label>
          <div className="flex flex-wrap gap-2 mt-1">
            {TILE_PALETTE.map((p) => (
              <button
                key={p.key}
                type="button"
                title={p.label}
                onClick={() => setDraft({ ...draft, tileColor: p.key })}
                className={`h-7 w-7 rounded-full ${p.swatch} flex items-center justify-center ring-2 ${draft.tileColor === p.key ? 'ring-gray-800' : 'ring-transparent'}`}
              >
                {draft.tileColor === p.key && <Check className="h-4 w-4 text-white" />}
              </button>
            ))}
          </div>
        </div>
        {/* FK-04/D: Kedvezményhatárok (3 forint-küszöb). Üres input = nincs határ
            (a backend null-ra tartja a meglévő értéket; ha 0-t küldünk, az 0 lesz). */}
        <div>
          <label className="text-sm font-medium">{i18n.t('literals.kedvezmenyhatarok-ft')}</label>
          <p className="text-xs text-gray-500 mb-1">
            {i18n.t('literals.a-kedvezmenyes-veteli-eladasi-savok-hata')}
          </p>
          <div className="grid grid-cols-3 gap-2">
            {(['limit1Boundary', 'limit2Boundary', 'limit3Boundary'] as const).map((key, idx) => (
              <div key={key}>
                <label className="text-xs text-gray-600">
                  {idx === 0 ? 'Alsó' : idx === 1 ? 'Középső' : 'Felső'}
                  {i18n.t('literals.hatar')}
                </label>
                <input
                  className="form-input w-full"
                  type="number"
                  min="0"
                  step="1"
                  value={draft[key] ?? ''}
                  placeholder={idx === 0 ? '50 000' : idx === 1 ? '300 000' : '1 000 000'}
                  onChange={(e) => {
                    const n = Number(e.target.value)
                    setDraft({
                      ...draft,
                      [key]: e.target.value.trim() === '' || !Number.isFinite(n) ? null : n,
                    })
                  }}
                />
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className="flex justify-end gap-2 mt-4">
        <button
          className="form-button-secondary inline-flex items-center gap-1 px-3 py-1.5 text-sm"
          onClick={onCancel}
        >
          <X className="h-4 w-4" />
          {i18n.t('literals.megse-2')}
        </button>
        <button
          className="form-button inline-flex items-center gap-1 px-3 py-1.5 text-sm"
          onClick={onSave}
        >
          <Save className="h-4 w-4" />
          {i18n.t('literals.mentes-3')}
        </button>
      </div>
    </Overlay>
  )
}
