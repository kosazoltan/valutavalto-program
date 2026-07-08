import type { ReactNode } from 'react'

/**
 * FK-021/FK-022: az iroda-felrögzítő és -szerkesztő form közös építőelemei —
 * az 5 logikai csoport kerete (Section) és a jelölőnégyzet-sor (Check).
 */

/** Logikai csoport-keret a formon. */
export function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <fieldset className="border border-gray-200 rounded-lg p-4">
      <legend className="px-2 text-sm font-semibold text-gray-700">{title}</legend>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">{children}</div>
    </fieldset>
  )
}

export function Check({
  label,
  checked,
  onChange,
  hint,
}: {
  label: string
  checked: boolean
  onChange: (v: boolean) => void
  hint?: string
}) {
  return (
    <label className="inline-flex items-start gap-2 cursor-pointer">
      <input
        type="checkbox"
        className="form-checkbox h-4 w-4 mt-0.5"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
      />
      <span className="text-sm">
        {label}
        {hint ? <span className="block text-xs text-gray-500">{hint}</span> : null}
      </span>
    </label>
  )
}
