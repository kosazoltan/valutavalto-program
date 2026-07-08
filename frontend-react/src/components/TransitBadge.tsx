import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Package } from 'lucide-react'
import { transitApi } from '../services/api/index'

/**
 * Kis kedvelt "uton levo csomagok" badge a topbar-ba.
 * - 30 masodperces auto-poll (mint a /transit oldal)
 * - Kattintasra /transit-re navigal
 * - Csak akkor jelenik meg, ha van legalabb 1 pending item
 */
export default function TransitBadge() {
  const [count, setCount] = useState(0)
  const navigate = useNavigate()
  const branchCode =
    String(import.meta.env.VITE_BRANCH_CODE ?? '')
      .trim()
      .toUpperCase() || undefined

  const poll = useCallback(async () => {
    try {
      const items = await transitApi.getIncoming(branchCode)
      setCount(items.length)
    } catch {
      setCount(0)
    }
  }, [branchCode])

  useEffect(() => {
    void poll()
    const id = setInterval(() => void poll(), 30000)
    return () => clearInterval(id)
  }, [poll])

  if (count === 0) return null

  return (
    <button
      onClick={() => navigate('/transit')}
      title={'Úton lévő csomagok: ' + count + ' db - kattints az átvételhez'}
      className="relative p-2 hover:bg-secondary-100 rounded-lg transition-colors"
    >
      <Package size={18} className="text-amber-600" />
      <span className="absolute -top-1 -right-1 bg-amber-500 text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center">
        {count > 9 ? '9+' : count}
      </span>
    </button>
  )
}
