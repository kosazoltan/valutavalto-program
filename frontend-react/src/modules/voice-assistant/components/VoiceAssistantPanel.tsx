import { useVoiceAssistant } from '../context/VoiceAssistantProvider'

/**
 * EBC Hangsegéd lebegő panel a jobb alsó sarokban.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §9
 *
 * <p>Phase 3 = skeleton — három üzemmód-választó gomb + állapot-kijelző.
 * A bizonylat-export, hibajelentés-űrlap, transcript-megjelenítés a
 * további fázisokban (4-9) kerül implementálásra.
 */
export function VoiceAssistantPanel() {
  const { mode, isActive, isConnecting, error, start, stop } = useVoiceAssistant()

  return (
    <div
      className="fixed bottom-4 right-4 z-50 w-72 rounded-xl border border-slate-300 bg-white p-4 shadow-lg dark:border-slate-700 dark:bg-slate-900"
      role="dialog"
      aria-label="EBC Hangsegéd"
    >
      <div className="mb-2 flex items-center justify-between">
        <h3 className="text-sm font-semibold text-slate-700 dark:text-slate-200">
          EBC Hangsegéd
        </h3>
        <span
          className={`inline-block h-2 w-2 rounded-full ${
            isActive ? 'bg-green-500' : 'bg-slate-400'
          }`}
          aria-label={isActive ? 'Aktív' : 'Inaktív'}
        />
      </div>

      {error && (
        <div className="mb-2 rounded bg-red-50 p-2 text-xs text-red-700 dark:bg-red-900/40 dark:text-red-200">
          {error}
        </div>
      )}

      <div className="mb-2 text-xs text-slate-500 dark:text-slate-400">
        {isConnecting
          ? 'Kapcsolódás…'
          : isActive
            ? `Aktív mód: ${mode}`
            : 'Válassz üzemmódot a beszélgetés indításához.'}
      </div>

      {!isActive ? (
        <div className="grid grid-cols-3 gap-2">
          <ModeButton label="Telepítés" disabled={isConnecting} onClick={() => start('install')} />
          <ModeButton label="Tesztelés" disabled={isConnecting} onClick={() => start('test')} />
          <ModeButton label="Hibajelzés" disabled={isConnecting} onClick={() => start('support')} />
        </div>
      ) : (
        <button
          type="button"
          className="w-full rounded bg-red-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-red-700"
          onClick={stop}
        >
          Beszélgetés befejezése
        </button>
      )}
    </div>
  )
}

function ModeButton({
  label,
  disabled,
  onClick,
}: {
  label: string
  disabled: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      className="rounded border border-slate-300 px-2 py-1 text-xs font-medium hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-600 dark:hover:bg-slate-800"
      disabled={disabled}
      onClick={onClick}
    >
      {label}
    </button>
  )
}
