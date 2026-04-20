import { useState } from "react"
import { X, Upload, Loader2, Check } from "lucide-react"
import { api } from "../services/api/index"

interface Props {
  open: boolean
  onClose: () => void
  onSuccess: () => void
}

interface BulkResult {
  updated: number
  skipped: number
  errors: string[]
}

export default function BulkEmailModal({ open, onClose, onSuccess }: Props) {
  const [csvText, setCsvText] = useState("")
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<BulkResult | null>(null)
  const [parseError, setParseError] = useState<string | null>(null)

  if (!open) return null

  const parse = (text: string): { workerCode: string; email: string }[] => {
    const rows: { workerCode: string; email: string }[] = []
    for (const rawLine of text.split(/\r?\n/)) {
      const line = rawLine.trim()
      if (!line || line.startsWith("#")) continue
      const parts = line.split(/[;,\t]/).map((p) => p.trim())
      if (parts.length < 2) continue
      const [code, email] = parts
      if (!code) continue
      rows.push({ workerCode: code, email: email || "" })
    }
    return rows
  }

  const handleSubmit = async () => {
    setParseError(null)
    const rows = parse(csvText)
    if (rows.length === 0) {
      setParseError("Nincs feldolgozhato sor. Format: workerCode;email soronkent.")
      return
    }
    setLoading(true)
    setResult(null)
    try {
      const r = await api.patch<BulkResult>("/workers/bulk-email", rows)
      setResult(r.data)
      if (r.data.updated > 0) onSuccess()
    } catch (err) {
      setParseError(err instanceof Error ? err.message : String(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-2xl">
        <div className="flex items-center justify-between p-4 border-b border-secondary-200">
          <div className="flex items-center gap-2">
            <Upload size={20} className="text-primary-600" />
            <h3 className="text-lg font-bold text-secondary-900">Dolgozoi email-ek tomeges importja</h3>
          </div>
          <button onClick={onClose} className="p-1 hover:bg-secondary-100 rounded">
            <X size={18} />
          </button>
        </div>

        <div className="p-4 space-y-3">
          <p className="text-sm text-secondary-600">
            Illeszd be az Excel-bol / szoveges forrasbol a dolgozoi kodokat es email cimeket
            <b> workerCode;email </b> formatumban, soronkent egy. Ures email = torol.
          </p>
          <pre className="text-xs bg-secondary-50 p-2 rounded border border-secondary-200">
{`# Pelda format (workerCode;email):
W007570;borsi.tamas@gmail.com
W005043;dora.bognarne@ebc.hu
W014517;barabas.marietta@ebc.hu`}
          </pre>
          <textarea
            value={csvText}
            onChange={(e) => setCsvText(e.target.value)}
            placeholder="W007570;name@example.com"
            rows={12}
            className="w-full p-3 border border-secondary-300 rounded font-mono text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
          />

          {parseError && (
            <div className="p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
              {parseError}
            </div>
          )}

          {result && (
            <div className="p-3 bg-green-50 border border-green-200 rounded text-sm">
              <div className="flex items-center gap-2 font-semibold text-green-700 mb-1">
                <Check size={16} />
                Siker: {result.updated} dolgozo emailje frissitve, {result.skipped} kihagyva.
              </div>
              {result.errors.length > 0 && (
                <div className="mt-2 max-h-40 overflow-y-auto text-xs text-red-600">
                  <b>Hibak ({result.errors.length}):</b>
                  <ul className="list-disc list-inside">
                    {result.errors.slice(0, 20).map((e, i) => <li key={i}>{e}</li>)}
                    {result.errors.length > 20 && <li>...tovabbi {result.errors.length - 20} sor</li>}
                  </ul>
                </div>
              )}
            </div>
          )}
        </div>

        <div className="flex items-center justify-end gap-2 p-4 border-t border-secondary-200">
          <button
            onClick={onClose}
            className="px-4 py-2 border border-secondary-300 rounded hover:bg-secondary-50 text-sm"
          >
            Bezaras
          </button>
          <button
            onClick={handleSubmit}
            disabled={loading || !csvText.trim()}
            className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded hover:bg-primary-700 text-sm font-medium disabled:opacity-50"
          >
            {loading ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />}
            Import
          </button>
        </div>
      </div>
    </div>
  )
}
