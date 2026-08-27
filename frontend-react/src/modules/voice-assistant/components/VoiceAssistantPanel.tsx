import { useVoiceAssistant } from '../context/VoiceAssistantProvider'
import type { VoiceMode } from '../hooks/useVoiceMode'
import i18n from '../../../i18n'

/**
 * Felhasználói label a belso `VoiceMode` enum-hoz.
 *
 * <p>Copilot PR #689 P2 finding: korábban `Aktív (${mode})` formátum a
 * felhasználónak a technikai "unified" stringet jelenítette meg. Ehelyett
 * az aktiv mod neve magyar, beszedes szoveg.
 */
const VOICE_MODE_LABEL: Record<Exclude<VoiceMode, 'idle'>, string> = {
  unified: 'Beszélgetés',
  install: 'Telepítés',
  test: 'Tesztelés',
  support: 'Hibajelzés',
}

/**
 * EBC Hangsegéd lebegő panel a jobb alsó sarokban.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §9 +
 * Kósa Zoltán user-direktíva 2026-05-18: "ne legyen külön Telepítés /
 * Tesztelés / Hibajelzés mód — egy gomb minden kérdésre válaszol".
 *
 * <p>Méret-csökkentés (Kósa Zoltán 2026-05-18): w-72 → w-56, kisebb padding +
 * kompaktabb tipográfia, hogy ne takarja a háttér-UI-t.
 */
export function VoiceAssistantPanel() {
  const { mode, isActive, isConnecting, error, start, stop } = useVoiceAssistant()

  return (
    <div
      className="fixed bottom-3 right-3 z-50 w-56 rounded-lg border border-slate-300 bg-white p-2.5 shadow-md dark:border-slate-700 dark:bg-slate-900"
      role="dialog"
      aria-label="EBC Hangsegéd"
    >
      <div className="mb-1.5 flex items-center justify-between">
        <h3 className="text-xs font-semibold text-slate-700 dark:text-slate-200">
          {i18n.t('literals.ebc-hangseged')}
        </h3>
        <span
          className={`inline-block h-2 w-2 rounded-full ${
            isActive ? 'bg-green-500' : 'bg-slate-400'
          }`}
          aria-label={isActive ? 'Aktív' : 'Inaktív'}
        />
      </div>

      {error && (
        <div className="mb-1.5 rounded bg-red-50 p-1.5 text-[11px] leading-tight text-red-700 dark:bg-red-900/40 dark:text-red-200">
          {error}
        </div>
      )}

      <div className="mb-1.5 text-[11px] leading-tight text-slate-500 dark:text-slate-400">
        {/* Copilot PR #692 P2: `isActive` mindig `mode !== 'idle'`, a dual-branch
            felesleges volt. A `useVoiceAssistant` kontraktja szerint `mode === 'idle'`
            akkor es csak akkor, ha NEM active — tehat eleg a `mode` checkje. */}
        {isConnecting
          ? 'Kapcsolódás…'
          : mode !== 'idle'
            ? `Aktív — ${VOICE_MODE_LABEL[mode]}`
            : 'Indítsd a beszélgetést.'}
      </div>

      {!isActive ? (
        <button
          type="button"
          className="w-full rounded bg-emerald-600 px-2 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:cursor-not-allowed disabled:opacity-50"
          disabled={isConnecting}
          onClick={() => start('unified')}
        >
          {i18n.t('literals.beszelgetes-inditasa')}
        </button>
      ) : (
        <button
          type="button"
          className="w-full rounded bg-red-600 px-2 py-1.5 text-xs font-semibold text-white hover:bg-red-700"
          onClick={stop}
        >
          {i18n.t('literals.beszelgetes-befejezese')}
        </button>
      )}
    </div>
  )
}
