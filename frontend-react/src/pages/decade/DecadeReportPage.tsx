import { useState, useEffect, useCallback } from 'react'
import {
  FileSpreadsheet,
  CheckCircle,
  XCircle,
  Clock,
  Lock,
  Calendar,
  AlertTriangle,
  TrendingUp,
  TrendingDown,
} from 'lucide-react'
import { decadeReportApi, DecadeReportDto, GenerateDecadeDto } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'

const STATUS_LABELS: Record<string, { label: string; color: string; icon: typeof CheckCircle }> = {
  OPEN: { label: 'Nyitott', color: 'bg-blue-100 text-blue-700', icon: Clock },
  CLOSED: { label: 'Lezárt', color: 'bg-green-100 text-green-700', icon: Lock },
  FAILED: { label: 'Hibás', color: 'bg-red-100 text-red-700', icon: XCircle },
}

function formatNum(n?: number) {
  return n != null ? n.toLocaleString('hu-HU') : '—'
}

function decadeLabel(decade: number): string {
  if (decade === 1) return '1–10.'
  if (decade === 2) return '11–20.'
  return '21–hó vége'
}

export default function DecadeReportPage() {
  const worker = useAuthStore((s) => s.worker)
  const branchId = worker?.branchId || ''

  const [year, setYear] = useState(() => new Date().getFullYear())
  const [reports, setReports] = useState<DecadeReportDto[]>([])
  const [selected, setSelected] = useState<DecadeReportDto | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  // generate form
  const [genDecade, setGenDecade] = useState<number>(1)

  const loadReports = useCallback(async () => {
    if (!branchId) return
    setLoading(true)
    setError('')
    try {
      const res = await decadeReportApi.list(branchId, year)
      setReports(res.data?.content ?? [])
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('DecadeReportPage', 'Failed to load reports:', err)
    } finally {
      setLoading(false)
    }
  }, [branchId, year])

  useEffect(() => {
    loadReports()
  }, [loadReports])

  const handleGenerate = async () => {
    if (!branchId) return
    setLoading(true)
    setError('')
    try {
      const dto: GenerateDecadeDto = { branchId, year, decade: genDecade }
      const res = await decadeReportApi.generate(dto)
      setSelected(res.data)
      toast.success('Dekádjelentés generálva', `${year}/${genDecade}. dekád`)
      loadReports()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      toast.error('Generálás sikertelen', msg)
    } finally {
      setLoading(false)
    }
  }

  const handleClose = async (id: string) => {
    try {
      const res = await decadeReportApi.close(id)
      setSelected(res.data)
      toast.success('Dekádjelentés lezárva')
      loadReports()
    } catch (err) {
      const msg = getErrorMessage(err)
      toast.error('Lezárás sikertelen', msg)
    }
  }

  const StatusBadge = ({ status }: { status: string }) => {
    const s = STATUS_LABELS[status] ?? STATUS_LABELS.OPEN!
    const Icon = s!.icon
    return (
      <span
        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${s!.color}`}
      >
        <Icon size={12} />
        {s!.label}
      </span>
    )
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileSpreadsheet /> Dekád jelentések
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle size={16} />
          {error}
        </div>
      )}

      {/* Filters + Generate */}
      <div className="flex gap-3 items-end flex-wrap">
        <div>
          <label className="text-xs text-gray-500">Év</label>
          <input
            type="number"
            value={year}
            onChange={(e) => setYear(Number(e.target.value))}
            min={2020}
            max={2099}
            className="input-field text-sm w-24"
          />
        </div>
        <div className="border-l pl-3 flex gap-2 items-end">
          <div>
            <label className="text-xs text-gray-500">Dekád</label>
            <select
              value={genDecade}
              onChange={(e) => setGenDecade(Number(e.target.value))}
              className="input-field text-sm"
            >
              <option value={1}>1. dekád (1–10.)</option>
              <option value={2}>2. dekád (11–20.)</option>
              <option value={3}>3. dekád (21–hó vége)</option>
            </select>
          </div>
          <button
            onClick={handleGenerate}
            disabled={loading || !branchId}
            className="btn-primary text-sm flex items-center gap-1"
          >
            <FileSpreadsheet size={14} /> Generálás
          </button>
        </div>
      </div>

      {loading && <div className="text-center py-8 text-gray-400">Betöltés...</div>}

      {!loading && (
        <div className="grid grid-cols-3 gap-3">
          {/* Report list */}
          <div className="col-span-2 space-y-1">
            {reports.length === 0 && (
              <div className="text-gray-400 text-sm py-4 text-center">
                Nincs dekádjelentés ebben az évben
              </div>
            )}
            {reports.map((r) => (
              <div
                key={r.id}
                role="button"
                tabIndex={0}
                onClick={() => setSelected(r)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault()
                    setSelected(r)
                  }
                }}
                className={`p-3 rounded border cursor-pointer hover:bg-gray-50 transition ${
                  selected?.id === r.id ? 'border-blue-400 bg-blue-50' : 'border-gray-200'
                }`}
              >
                <div className="flex justify-between items-center">
                  <div className="flex items-center gap-2">
                    <Calendar size={14} className="text-gray-400" />
                    <span className="font-medium text-sm">
                      {r.year}. {decadeLabel(r.decade)}
                    </span>
                    <StatusBadge status={r.status} />
                  </div>
                  <div className="text-xs text-gray-500">{r.transactionCount} tranzakció</div>
                </div>
                <div className="flex gap-4 mt-1 text-xs text-gray-500">
                  <span>Vétel: {formatNum(r.totalBuyHuf)} Ft</span>
                  <span>Eladás: {formatNum(r.totalSellHuf)} Ft</span>
                  <span
                    className={
                      r.decadeProfitHuf >= 0 ? 'text-green-600 font-medium' : 'text-red-600 font-medium'
                    }
                  >
                    Haszon: {formatNum(r.decadeProfitHuf)} Ft
                  </span>
                </div>
              </div>
            ))}
          </div>

          {/* Detail panel */}
          <div className="space-y-2">
            {selected ? (
              <div className="p-3 border rounded space-y-2">
                <h3 className="font-medium text-sm">
                  Részletek — {selected.year}. {decadeLabel(selected.decade)}
                </h3>
                <div className="text-xs space-y-1">
                  <div>
                    Státusz: <StatusBadge status={selected.status} />
                  </div>
                  <div>Tranzakciók: {selected.transactionCount}</div>
                  <div>Kezelési díj: {formatNum(selected.totalHandlingFee)} Ft</div>
                  <div className="flex items-center gap-1">
                    {selected.decadeProfitHuf >= 0 ? (
                      <TrendingUp size={12} className="text-green-500" />
                    ) : (
                      <TrendingDown size={12} className="text-red-500" />
                    )}
                    Haszon: {formatNum(selected.decadeProfitHuf)} Ft
                  </div>
                  <div className="border-t pt-1 mt-1">
                    <div>Nyitó készletérték: {formatNum(selected.openingInventoryValueHuf)} Ft</div>
                    <div>Záró készletérték: {formatNum(selected.closingInventoryValueHuf)} Ft</div>
                  </div>
                  <div className="border-t pt-1 mt-1">
                    <div>Forint nyitó: {formatNum(selected.forintOpening)} Ft</div>
                    <div>Forint bevétel: {formatNum(selected.forintTotalIncome)} Ft</div>
                    <div>Forint kiadás: {formatNum(selected.forintTotalExpense)} Ft</div>
                    <div>Forint záró: {formatNum(selected.forintClosing)} Ft</div>
                    <div
                      className={
                        selected.forintControlValid ? 'text-green-600' : 'text-red-600 font-medium'
                      }
                    >
                      {selected.forintControlValid ? (
                        <span className="flex items-center gap-1">
                          <CheckCircle size={12} /> Forint kontroll OK
                        </span>
                      ) : (
                        <span className="flex items-center gap-1">
                          <XCircle size={12} /> Eltérés: {formatNum(selected.forintControlDiff)} Ft
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="border-t pt-1 mt-1">
                    <div>Első bizonylat: {selected.firstReceiptNumber || '—'}</div>
                    <div>Utolsó bizonylat: {selected.lastReceiptNumber || '—'}</div>
                    <div>Kártyás fizetés: {formatNum(selected.cardPaymentTotal)} Ft</div>
                  </div>
                  {selected.closedAt && (
                    <div className="border-t pt-1 mt-1 text-gray-500">
                      Lezárva: {new Date(selected.closedAt).toLocaleString('hu-HU')}
                    </div>
                  )}
                </div>

                {/* Actions */}
                {selected.status === 'OPEN' && (
                  <div className="pt-2 border-t">
                    <button
                      onClick={() => handleClose(selected.id)}
                      className="btn-primary text-xs flex items-center gap-1"
                    >
                      <Lock size={12} /> Lezárás
                    </button>
                  </div>
                )}

                {/* Lines */}
                {selected.lines && selected.lines.length > 0 && (
                  <div className="pt-2 border-t">
                    <h4 className="text-xs font-medium mb-1">Valuta sorok</h4>
                    <div className="max-h-60 overflow-y-auto">
                      <table className="w-full text-[10px]">
                        <thead className="bg-gray-50">
                          <tr>
                            <th className="text-left p-1">Valuta</th>
                            <th className="text-right p-1">Vétel db</th>
                            <th className="text-right p-1">Eladás db</th>
                            <th className="text-right p-1">Vétel Ft</th>
                            <th className="text-right p-1">Eladás Ft</th>
                            <th className="text-right p-1">MNB árfolyam</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selected.lines.map((l) => (
                            <tr key={l.currencyCode} className="border-t">
                              <td className="p-1 font-medium">{l.currencyCode}</td>
                              <td className="p-1 text-right">{l.buyCount}</td>
                              <td className="p-1 text-right">{l.sellCount}</td>
                              <td className="p-1 text-right">{formatNum(l.buyHuf)}</td>
                              <td className="p-1 text-right">{formatNum(l.sellHuf)}</td>
                              <td className="p-1 text-right">{l.mnbRate?.toFixed(2) ?? '—'}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="text-gray-400 text-sm text-center py-8">Válasszon egy jelentést</div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
