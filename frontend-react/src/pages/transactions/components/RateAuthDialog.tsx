import { useState, useEffect, useRef } from 'react'
import { ShieldCheck, X } from 'lucide-react'
import { generateChallenge, validateResponse } from '../../../utils/rateAuthCode'
import i18n from '../../../i18n'

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
  const [challengeDate, setChallengeDate] = useState<Date>(new Date())
  const [response, setResponse] = useState('')
  const [error, setError] = useState('')
  const [attempts, setAttempts] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)

  const MAX_ATTEMPTS = 5

  useEffect(() => {
    if (isOpen) {
      const now = new Date()
      setChallenge(generateChallenge())
      setChallengeDate(now)
      setResponse('')
      setError('')
      setAttempts(0)
      setTimeout(() => inputRef.current?.focus(), 100)
    }
  }, [isOpen])

  if (!isOpen) return null

  const handleSubmit = () => {
    if (attempts >= MAX_ATTEMPTS) {
      setError(`Túl sok próbálkozás (${MAX_ATTEMPTS}). Zárja be és próbálja újra.`)
      return
    }
    const num = parseInt(response, 10)
    if (isNaN(num)) {
      setError('Kérem adjon meg egy számot!')
      return
    }
    if (validateResponse(challenge, num, challengeDate)) {
      onSuccess()
    } else {
      const remaining = MAX_ATTEMPTS - attempts - 1
      setAttempts((a) => a + 1)
      setError(
        remaining > 0
          ? `Hibás engedélyezési kód! Még ${remaining} próbálkozás.`
          : `Túl sok próbálkozás (${MAX_ATTEMPTS}). Zárja be és próbálja újra.`,
      )
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
            {i18n.t('literals.egyedi-arfolyam-engedelyezes')}
          </h3>
          <button onClick={onCancel} className="text-gray-400 hover:text-gray-600">
            <X size={20} />
          </button>
        </div>

        <div className="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 rounded-lg p-3 text-sm">
          <p className="font-semibold text-amber-800 dark:text-amber-200">
            {mode === 'buy' ? 'Vételi' : 'Eladási'}
            {i18n.t('literals.arfolyam-4')}
            {customRate.toFixed(2)}
            {i18n.t('literals.huf-4')}
            {currencyCode}
          </p>
          <p className="text-amber-700 dark:text-amber-300 mt-1">
            {i18n.t('literals.a-savon-kivuli-arfolyamhoz-ertektarosi-f')}
          </p>
        </div>

        <div className="text-center space-y-2">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            {i18n.t('literals.olvassa-fel-az-alabbi-kodot-az-ertektaro')}
          </p>
          <div className="text-4xl font-mono font-black tracking-[0.3em] text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 rounded-lg py-3 select-all">
            {challenge}
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            {i18n.t('literals.ertektaros-valaszkodja')}
          </label>
          <input
            ref={inputRef}
            type="text"
            inputMode="numeric"
            value={response}
            onChange={(e) => {
              setResponse(e.target.value)
              setError('')
            }}
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
            {i18n.t('literals.ellenorzes')}
          </button>
          <button
            onClick={onCancel}
            className="flex-1 py-2.5 rounded-lg border border-gray-300 dark:border-gray-600 font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            {i18n.t('literals.megse')}
          </button>
        </div>
      </div>
    </div>
  )
}
