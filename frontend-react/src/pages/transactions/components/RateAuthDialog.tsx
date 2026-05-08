import { useState, useEffect, useRef } from 'react'
import { ShieldCheck, X } from 'lucide-react'
import { generateChallenge, validateResponse } from '../../../utils/rateAuthCode'

interface RateAuthDialogProps {
  isOpen: boolean
  onSuccess: () => void
  onCancel: () => void
  customRate: number
  currencyCode: string
  mode: 'buy' | 'sell'
}

export default function RateAuthDialog({
  isOpen,
  onSuccess,
  onCancel,
  customRate,
  currencyCode,
  mode,
}: RateAuthDialogProps) {
  const [challenge, setChallenge] = useState('')
  const [response, setResponse] = useState('')
  const [error, setError] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (isOpen) {
      setChallenge(generateChallenge())
      setResponse('')
      setError('')
      setTimeout(() => inputRef.current?.focus(), 100)
    }
  }, [isOpen])

  if (!isOpen) return null

  const handleSubmit = () => {
    const num = parseInt(response, 10)
    if (isNaN(num)) {
      setError('Kérem adjon meg egy számot!')
      return
    }
    if (validateResponse(challenge, num)) {
      onSuccess()
    } else {
      setError('Hibás engedélyezési kód! Kérje újra az értéktárostól.')
      setResponse('')
      inputRef.current?.focus()
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-2xl p-6 w-[420px] space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <ShieldCheck size={22} className="text-amber-500" />
            Egyedi árfolyam engedélyezés
          </h3>
          <button onClick={onCancel} className="text-gray-400 hover:text-gray-600">
            <X size={20} />
          </button>
        </div>

        <div className="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 rounded-lg p-3 text-sm">
          <p className="font-semibold text-amber-800 dark:text-amber-200">
            {mode === 'buy' ? 'Vételi' : 'Eladási'} árfolyam: {customRate.toFixed(2)} HUF/{currencyCode}
          </p>
          <p className="text-amber-700 dark:text-amber-300 mt-1">
            A sávon kívüli árfolyamhoz értéktárosi/főértéktárosi engedély szükséges.
          </p>
        </div>

        <div className="text-center space-y-2">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            Olvassa fel az alábbi kódot az értéktárosnak:
          </p>
          <div className="text-4xl font-mono font-black tracking-[0.3em] text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 rounded-lg py-3 select-all">
            {challenge}
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            Értéktáros válaszkódja:
          </label>
          <input
            ref={inputRef}
            type="text"
            inputMode="numeric"
            value={response}
            onChange={(e) => { setResponse(e.target.value); setError('') }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSubmit()
              if (e.key === 'Escape') onCancel()
            }}
            className="w-full h-12 text-center text-2xl font-mono font-bold rounded-lg border-2 border-gray-300 dark:border-gray-600 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            placeholder="—"
            autoComplete="off"
          />
          {error && (
            <p className="mt-1 text-sm text-red-600 dark:text-red-400 font-medium">{error}</p>
          )}
        </div>

        <div className="flex gap-2">
          <button
            onClick={handleSubmit}
            disabled={!response.trim()}
            className="flex-1 py-2.5 rounded-lg text-white font-semibold disabled:opacity-50 disabled:cursor-not-allowed"
            style={{ backgroundColor: 'var(--primary)' }}
          >
            Ellenőrzés
          </button>
          <button
            onClick={onCancel}
            className="flex-1 py-2.5 rounded-lg border border-gray-300 dark:border-gray-600 font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            Mégse
          </button>
        </div>
      </div>
    </div>
  )
}
