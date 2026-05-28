import { useCallback, useEffect, useMemo, useState } from "react"
import { transitApi, type TransitItem } from "../../services/api/index"
import { Package, ArrowRight, ArrowLeft, RefreshCw, CheckCircle2, Loader2 } from "lucide-react"
import { getErrorMessage } from "../../utils/errorHandling"
import { toast } from "../../components/ui/toaster"
import { useAuthStore } from "../../stores/authStore"
import { useTranslation } from 'react-i18next'

type Tab = "incoming" | "outgoing"

export default function TransitPage() {
  const { t } = useTranslation()
  const [tab, setTab] = useState<Tab>("incoming")
  const [items, setItems] = useState<TransitItem[]>([])
  const [loading, setLoading] = useState(false)
  const [ackingId, setAckingId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const worker = useAuthStore((s) => s.worker)

  // v2.3.37 (B29 audit fix): branchCode-ot a logged-in worker-bol toltjuk,
  // NEM a VITE_BRANCH_CODE env var-bol (amit a Vercel build NEM mindig set-ol).
  // Ha hianyzik, az incoming tab MINDEN COLLECTION-t mutatott (cashier mode-ban
  // is "Bejövő"-n maradt a sajat csomagja), a Kimenő tab pedig ures volt.
  // Fallback sorrend: explicit worker.branchCode -> env var -> undefined (no filter).
  const branchCode = useMemo(
    () => {
      const fromWorker = worker?.branchCode?.trim().toUpperCase()
      if (fromWorker) return fromWorker
      const fromEnv = String(import.meta.env.VITE_BRANCH_CODE ?? "").trim().toUpperCase()
      return fromEnv || undefined
    },
    [worker?.branchCode],
  )

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = tab === "incoming"
        ? await transitApi.getIncoming(branchCode)
        : await transitApi.getOutgoing(branchCode)
      setItems(data)
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [tab, branchCode])

  useEffect(() => {
    void load()
    const id = setInterval(() => void load(), 30000)
    return () => clearInterval(id)
  }, [load])

  const handleAcknowledge = async (item: TransitItem) => {
    const ackKey = item.type + "-" + item.id
    setAckingId(ackKey)
    try {
      if (item.type === "DISTRIBUTION" && item.distributionId) {
        await transitApi.acknowledgeDistribution(item.distributionId)
      } else if (item.type === "COLLECTION") {
        await transitApi.acknowledgeCollection(item.id)
      }
      toast.success("Atvetel validalva", item.documentNumber + " - " + item.amount.toLocaleString("hu-HU") + " " + item.currencyCode)
      await load()
    } catch (err) {
      toast.error("Atvetel hiba", getErrorMessage(err))
    } finally {
      setAckingId(null)
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <Package size={18} className="text-primary-600" />
          <h1 className="text-base font-bold text-secondary-900">{t('transit.utonLevoCsomagok')}</h1>
          {branchCode && (
            <span className="ml-3 px-2 py-1 bg-secondary-100 rounded text-sm text-secondary-600">
              {branchCode}
            </span>
          )}
        </div>
        <button
          onClick={() => void load()}
          disabled={loading}
          className="flex items-center gap-2 px-3 py-1.5 border border-secondary-300 rounded-lg hover:bg-secondary-50 transition-colors text-sm"
        >
          <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
          {t('common.refresh')}
        </button>
      </div>

      <div className="flex gap-1 border-b border-secondary-200 mb-4">
        <button
          onClick={() => setTab("incoming")}
          className={"px-4 py-2 text-sm font-medium border-b-2 transition-colors " + (tab === "incoming" ? "border-primary-600 text-primary-700" : "border-transparent text-secondary-600 hover:text-secondary-800")}
        >
          <ArrowRight size={14} className="inline mr-1" />
          {t('transit.bejovoErkezo')}
        </button>
        <button
          onClick={() => setTab("outgoing")}
          className={"px-4 py-2 text-sm font-medium border-b-2 transition-colors " + (tab === "outgoing" ? "border-primary-600 text-primary-700" : "border-transparent text-secondary-600 hover:text-secondary-800")}
        >
          <ArrowLeft size={14} className="inline mr-1" />
          {t('transit.kimenoSajatKuldes')}
        </button>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {error}
        </div>
      )}

      {items.length === 0 && !loading ? (
        <div className="text-center py-12 text-secondary-500">
          <Package size={40} className="mx-auto mb-2 text-secondary-300" />
          {/* v2.5.54 #17 fix: hiányzó szóköz → "nincsérkező". A két kifejezés közé szóköz kerül. */}
          <p>{t('rate-management.nincs')} {tab === "incoming" ? "érkező" : "kimenő"} {t('transit.utonLevoCsomag')}</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-secondary-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-secondary-50 border-b border-secondary-200">
              <tr className="text-left text-xs font-semibold text-secondary-600 uppercase tracking-wider">
                <th className="px-4 py-2">{t('reports.bizonylat')}</th>
                <th className="px-4 py-2">{t('common.type')}</th>
                <th className="px-4 py-2">{t('transit.felado')}</th>
                <th className="px-4 py-2">{t('transit.cimzett')}</th>
                <th className="px-4 py-2 text-right">{t('common.amount')}</th>
                <th className="px-4 py-2">{t('common.deviza')}</th>
                <th className="px-4 py-2">{t('common.status')}</th>
                <th className="px-4 py-2">{t('transit.inditva')}</th>
                <th className="px-4 py-2">{t('common.operation')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-secondary-100">
              {items.map((item) => {
                const ackKey = item.type + "-" + item.id
                const isAcking = ackingId === ackKey
                return (
                  <tr key={ackKey} className="hover:bg-secondary-50">
                    <td className="px-4 py-2 font-mono text-sm">{item.documentNumber}</td>
                    <td className="px-4 py-2 text-sm">
                      {item.type === "DISTRIBUTION" ? "Értéktár → Pénztár" : "Pénztár → Értéktár"}
                    </td>
                    <td className="px-4 py-2 text-sm">{item.fromBranchName ?? item.fromBranchCode ?? "—"}</td>
                    <td className="px-4 py-2 text-sm">{item.toBranchName ?? item.toBranchCode ?? "—"}</td>
                    <td className="px-4 py-2 text-right font-mono text-sm">
                      {item.amount.toLocaleString("hu-HU", { maximumFractionDigits: 2 })}
                    </td>
                    <td className="px-4 py-2 text-sm font-medium">{item.currencyCode}</td>
                    <td className="px-4 py-2 text-xs">
                      <span className={item.status === "IN_PROGRESS" ? "px-2 py-0.5 bg-amber-100 text-amber-800 rounded-full" : "px-2 py-0.5 bg-secondary-100 text-secondary-700 rounded-full"}>
                        {item.status === "REQUESTED" ? "Beindítva" : item.status === "IN_PROGRESS" ? "Úton" : item.status}
                      </span>
                    </td>
                    <td className="px-4 py-2 text-xs text-secondary-600">
                      {new Date(item.createdAt).toLocaleString("hu-HU", { year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit" })}
                    </td>
                    <td className="px-4 py-2">
                      {tab === "incoming" ? (
                        <button
                          onClick={() => void handleAcknowledge(item)}
                          disabled={isAcking}
                          className="flex items-center gap-1 px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700 text-xs font-medium disabled:opacity-50"
                        >
                          {isAcking ? <Loader2 size={12} className="animate-spin" /> : <CheckCircle2 size={12} />}
                          {t('transit.atvetel')}
                        </button>
                      ) : (
                        <span className="text-xs text-secondary-400">—</span>
                      )}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      <p className="mt-4 text-xs text-secondary-500">
        {t('transit.automatikusFrissites30MasodpercenkentAtvetelKattintassalValidalhatoEzzelCsokkentjukACsomagveszitesKockazatat')}
      </p>
    </div>
  )
}
