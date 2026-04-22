import { Link, useLocation } from 'react-router-dom'
import { FileQuestion, Home, ArrowLeft } from 'lucide-react'

/**
 * PR #116: 404 NotFound oldal.
 *
 * Korábban az ismeretlen URL-ek üres fehér képernyőt adtak (silent failure) —
 * most tiszta 404 + visszanavigálás + home link.
 */
export default function NotFoundPage() {
  const location = useLocation()

  return (
    <div className="flex items-center justify-center min-h-[60vh] p-8">
      <div className="text-center max-w-md">
        <FileQuestion size={96} className="mx-auto text-gray-400 mb-4" />
        <h1 className="text-4xl font-bold text-gray-800 mb-2">404</h1>
        <h2 className="text-2xl font-semibold text-gray-700 mb-4">Oldal nem található</h2>
        <p className="text-gray-600 mb-6">
          A keresett URL (<code className="bg-gray-100 px-2 py-1 rounded">{location.pathname}</code>) nem létezik.
          Lehet, hogy:
        </p>
        <ul className="text-left text-sm text-gray-600 mb-6 space-y-1">
          <li>• A hivatkozás elavult vagy hibás</li>
          <li>• Az oldalt átnevezték / áthelyezték</li>
          <li>• Kézzel gépelted be és elírtál valamit</li>
        </ul>
        <div className="flex gap-3 justify-center">
          <button
            onClick={() => window.history.back()}
            className="flex items-center gap-2 px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded"
          >
            <ArrowLeft size={16} /> Vissza
          </button>
          <Link
            to="/dashboard"
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded"
          >
            <Home size={16} /> Főoldal
          </Link>
        </div>
      </div>
    </div>
  )
}
