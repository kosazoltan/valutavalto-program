import {
  useCallback,
  useEffect,
  useId,
  useRef,
  useState,
  type KeyboardEvent,
  type ReactNode,
} from 'react'
import i18n from '../i18n'

/**
 * FKH-027: közös "szöveges ok bekérése" modal a natív window.prompt() kiváltására
 * (Electronban a prompt silent no-op). A11y-minta: StaleShipmentConfirmDialog
 * (role="alertdialog", fókusz-csapda, Escape, overlay-kattintásra zárás).
 *
 * Használat oldalakon a useTextReasonModal() hookkal:
 * <pre>
 * const { modal, requestReason } = useTextReasonModal()
 * ...
 * const reason = await requestReason({ title: 'Elutasítás indoka' })
 * if (!reason) return // null = megszakítva; ürességre a hívó validál
 * ...
 * return <div>...{modal}</div>
 * </pre>
 */

interface Props {
  open: boolean
  title: string
  placeholder?: string
  /** null = megszakítás (Escape/overlay/Mégse); string = OK/Enter, üres string is érvényes */
  onClose: (result: string | null) => void
}

export default function TextReasonModal({ open, title, placeholder, onClose }: Props) {
  const [value, setValue] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)
  const cancelRef = useRef<HTMLButtonElement>(null)
  const okRef = useRef<HTMLButtonElement>(null)
  const titleId = useId()

  useEffect(() => {
    if (open) {
      setValue('')
      inputRef.current?.focus()
    }
  }, [open])

  if (!open) return null

  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') {
      event.preventDefault()
      onClose(null)
      return
    }
    if (event.key !== 'Tab') return
    // Fókusz-csapda: minden Tab-ot mi kezelünk (jsdom-ban nincs natív tab-sorrend,
    // böngészőben pedig így determinisztikus a körbejárás DOM-sorrendben)
    event.preventDefault()
    const focusables = [inputRef.current, cancelRef.current, okRef.current].filter(
      (el): el is HTMLInputElement | HTMLButtonElement => el !== null,
    )
    if (focusables.length === 0) return
    const index = focusables.indexOf(document.activeElement as HTMLInputElement | HTMLButtonElement)
    const next = event.shiftKey
      ? focusables[index <= 0 ? focusables.length - 1 : index - 1]
      : focusables[index === focusables.length - 1 || index === -1 ? 0 : index + 1]
    next?.focus()
  }

  return (
    <div
      role="alertdialog"
      aria-modal="true"
      aria-labelledby={titleId}
      data-testid="text-reason-modal-overlay"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onKeyDown={handleKeyDown}
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose(null)
      }}
    >
      <div className="w-full max-w-md rounded-lg bg-white p-6 shadow-xl">
        <h2 id={titleId} className="text-lg font-bold text-gray-800">
          {title}
        </h2>
        <input
          ref={inputRef}
          type="text"
          value={value}
          placeholder={placeholder}
          onChange={(event) => setValue(event.target.value)}
          onKeyDown={(event) => {
            if (event.key === 'Enter') {
              event.preventDefault()
              onClose(value)
            }
          }}
          className="mt-4 w-full rounded border border-gray-300 px-3 py-2 text-sm focus:border-blue-400 focus:outline-none"
        />
        <div className="mt-4 flex justify-end gap-2">
          <button
            ref={cancelRef}
            type="button"
            onClick={() => onClose(null)}
            className="form-button-secondary text-sm"
          >
            {i18n.t('literals.megse')}
          </button>
          <button
            ref={okRef}
            type="button"
            onClick={() => onClose(value)}
            className="form-button-primary text-sm"
          >
            {i18n.t('literals.ok')}
          </button>
        </div>
      </div>
    </div>
  )
}

interface PendingRequest {
  title: string
  placeholder?: string
  resolve: (value: string | null) => void
}

/**
 * Promise-alapú wrapper: requestReason() megnyitja a modált, és a Promise
 * a beírt stringgel (OK/Enter — üres string is érvényes) vagy null-lal
 * (Escape/overlay/Mégse) teljesül. Átfedő hívásnál az előző kérés Promise-a
 * null-lal záródik le, hogy soha ne maradjon örökre függőben.
 */
export function useTextReasonModal(): {
  modal: ReactNode
  requestReason: (opts: { title: string; placeholder?: string }) => Promise<string | null>
} {
  const [pending, setPending] = useState<PendingRequest | null>(null)
  // A state render-tükre: átfedő requestReason-hívásnál innen érhető el az
  // előző kérés, hogy a Promise-a null-lal lezárható legyen (Bugbot-fix, PR #1524)
  const pendingRef = useRef<PendingRequest | null>(null)

  const requestReason = useCallback(
    (opts: { title: string; placeholder?: string }) =>
      new Promise<string | null>((resolve) => {
        pendingRef.current?.resolve(null)
        const next = { title: opts.title, placeholder: opts.placeholder, resolve }
        pendingRef.current = next
        setPending(next)
      }),
    [],
  )

  const modal = pending ? (
    <TextReasonModal
      open
      title={pending.title}
      placeholder={pending.placeholder}
      onClose={(result) => {
        // Elavult closure-ból érkező zárás nem lőheti ki az újabb kérést
        if (pendingRef.current !== pending) return
        pendingRef.current = null
        setPending(null)
        pending.resolve(result)
      }}
    />
  ) : null

  return { modal, requestReason }
}
