import { useState, useEffect, useCallback } from 'react'
import { FileCheck2, Search, RefreshCw, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

interface TransferDocumentItem {
  id: string | number
  documentNumber?: string
  fromBranchName?: string
  toBranchName?: string
  amount?: number
  status?: string
  createdAt?: string
}

export default function TransferDocumentPage() {
  const [items, setItems] = useState<TransferDocumentItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<TransferDocumentItem[]>('/transfer-documents')
      setItems(Array.isArray(response.data) ? response.data : [])
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('TransferDocumentPage', 'Betoltesi hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = items.filter(item => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some(v =>
      v != null && String(v).toLowerCase().includes(term)
    )
  })

  return (
    <div className="space-y-4 p-4">
      <div className="flex items-center justify-between">
        <h1 className="flex items-center gap-2 text-xl font-bold">
          <FileCheck2 className="h-6 w-6" />
          Atutalasi bizonylatok
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="rounded bg-gray-100 p-2 hover:bg-gray-200" title="Frissites">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Kereses..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="w-full rounded border border-gray-300 py-2 pl-10 pr-3 text-sm focus:border-blue-500 focus:outline-none"
          />
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded bg-red-50 p-3 text-sm text-red-700">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="overflow-x-auto rounded border">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Bizonylat szam</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Forraspenztar</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Celpenztar</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Osszeg</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Allapot</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Datum</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">Betoltes...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">Nincs adat</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.documentNumber ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.fromBranchName ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.toBranchName ?? '-'}</td>
                <td className="px-4 py-3 text-sm text-right font-mono">{typeof item.amount === 'number' ? item.amount.toLocaleString('hu-HU') : item.amount ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.status ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.createdAt ? new Date(item.createdAt).toLocaleString('hu-HU') : '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        Osszes: {filtered.length} / {items.length}
      </div>
    </div>
  )
}
