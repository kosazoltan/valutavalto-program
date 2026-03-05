/**
 * F-billentyuk labsor — alul rogzitett.
 * Legacy: UNIT1.PAS statusbar, F2=Vetel, F3=Eladas, F5=Storno stb.
 */

export interface HotkeyDef {
  key: string
  label: string
  onClick: () => void
  active?: boolean
  variant?: 'default' | 'danger' | 'secondary'
}

interface HotkeyBarProps {
  left: HotkeyDef[]
  right?: HotkeyDef[]
}

export function HotkeyBar({ left, right = [] }: HotkeyBarProps) {
  return (
    <footer className="fixed bottom-0 left-0 right-0 bg-gray-900 dark:bg-gray-950 border-t border-gray-700 px-6 py-3 z-50">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          {left.map((h) => (
            <HotkeyButton key={h.key} hotkey={h.key} label={h.label} onClick={h.onClick} active={h.active} variant={h.variant} />
          ))}
        </div>
        <div className="flex items-center gap-3">
          {right.map((h) => (
            <HotkeyButton key={h.key} hotkey={h.key} label={h.label} onClick={h.onClick} active={h.active} variant={h.variant} />
          ))}
        </div>
      </div>
    </footer>
  )
}

function HotkeyButton({
  hotkey,
  label,
  onClick,
  active = false,
  variant = 'default',
}: {
  hotkey: string
  label: string
  onClick: () => void
  active?: boolean
  variant?: 'default' | 'danger' | 'secondary'
}) {
  const base = 'flex items-center gap-2 px-4 py-2 rounded-lg font-semibold transition-all focus:outline-none focus:ring-2 focus:ring-white/40'
  const variants: Record<string, string> = {
    default: active
      ? 'bg-[var(--primary)] text-white shadow-lg'
      : 'bg-gray-700 hover:bg-gray-600 text-white',
    danger: 'bg-red-600 hover:bg-red-700 text-white',
    secondary: 'bg-gray-600 hover:bg-gray-500 text-white',
  }

  return (
    <button onClick={onClick} className={`${base} ${variants[variant] || variants.default}`}>
      <kbd className="px-2 py-0.5 bg-gray-800 rounded text-xs font-mono">{hotkey}</kbd>
      <span className="text-sm">{label}</span>
    </button>
  )
}
