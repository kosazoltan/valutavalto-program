import { useEffect, useRef } from 'react'

interface Props {
  title: string
  text: string
  onConfirm: () => void
  onCancel: () => void
}

/**
 * FK-096 WU-10 — publikálás-megerősítő párbeszéd (a StaleShipmentConfirmDialog
 * alakjának másolata): role="alertdialog", focus-trap, Esc = megszakítás.
 */
export default function FeeConfirmDialog({ title, text, onConfirm, onCancel }: Props) {
  const cancelRef = useRef<HTMLButtonElement>(null)
  const confirmRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    cancelRef.current?.focus()
  }, [])

  const handleKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') {
      event.preventDefault()
      onCancel()
      return
    }
    if (event.key !== 'Tab') return

    const activeElement = document.activeElement
    if (event.shiftKey && activeElement === cancelRef.current) {
      event.preventDefault()
      confirmRef.current?.focus()
    } else if (!event.shiftKey && activeElement === confirmRef.current) {
      event.preventDefault()
      cancelRef.current?.focus()
    }
  }

  return (
    <div
      role="alertdialog"
      aria-modal="true"
      aria-labelledby="fee-confirm-dialog-title"
      aria-describedby="fee-confirm-dialog-description"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onKeyDown={handleKeyDown}
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onCancel()
      }}
    >
      <div className="w-full max-w-lg rounded-lg bg-white p-6 shadow-xl">
        <h2 id="fee-confirm-dialog-title" className="text-lg font-bold text-amber-900">
          {title}
        </h2>
        <p id="fee-confirm-dialog-description" className="mt-3 text-sm text-gray-700">
          {text}
        </p>
        <div className="mt-6 flex justify-end gap-3">
          <button
            ref={cancelRef}
            type="button"
            onClick={onCancel}
            className="rounded border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            Mégse
          </button>
          <button
            ref={confirmRef}
            type="button"
            onClick={onConfirm}
            className="rounded bg-amber-600 px-4 py-2 text-sm font-medium text-white hover:bg-amber-700"
          >
            Küldés megerősítése
          </button>
        </div>
      </div>
    </div>
  )
}
