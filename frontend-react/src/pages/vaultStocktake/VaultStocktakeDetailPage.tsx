import { useEffect, useState, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ArrowLeft, Save, CheckCircle2, XCircle, FileCheck, Ban, AlertTriangle } from 'lucide-react'
import { vaultStocktakeApi, VaultStocktakeSession, VaultStocktakeItem, StocktakeStatus } from '../../services/api/vaultStocktake'
import { logger } from '../../utils/logger'

const STATUS_LABELS: Record<StocktakeStatus, string> = {
    OPEN: 'Nyitva',
    IN_PROGRESS: 'Felvetel alatt',
    REVIEW: 'Ellenorzes',
    CLOSED: 'Lezarva',
    CANCELLED: 'Megszakitva',
}

export default function VaultStocktakeDetailPage() {
    const { id } = useParams<{ id: string }>()
    const navigate = useNavigate()
    const [session, setSession] = useState<VaultStocktakeSession | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const [saving, setSaving] = useState<string | null>(null)  // itemId lementve
    const [editValues, setEditValues] = useState<Record<string, string>>({})

    const load = useCallback(async () => {
        if (!id) return
        setLoading(true)
        try {
            const data = await vaultStocktakeApi.get(id)
            setSession(data)
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err)
            setError(msg)
        } finally {
            setLoading(false)
        }
    }, [id])

    useEffect(() => { load() }, [id, load])

    const handleCountItem = async (item: VaultStocktakeItem) => {
        const val = editValues[item.id]
        if (val === undefined || val === '') return
        const actualQuantity = parseInt(val, 10)
        if (isNaN(actualQuantity) || actualQuantity < 0) {
            setError('Invalid mennyiseg')
            return
        }
        setSaving(item.id)
        setError(null)
        try {
            await vaultStocktakeApi.countItem(item.id, { actualQuantity })
            logger.info('vault-stocktake', 'Tetel felveve: ' + item.id + ' qty=' + actualQuantity)
            setEditValues(prev => { const p = { ...prev }; delete p[item.id]; return p })
            await load()
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err)
            setError(msg)
        } finally {
            setSaving(null)
        }
    }

    const handleMoveToReview = async () => {
        if (!id) return
        if (!confirm('Biztos REVIEW-ba valtod? Ellenorzes utan mar csak lezarni vagy torolni lehet.')) return
        try {
            await vaultStocktakeApi.review(id)
            await load()
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err)
            setError(msg)
        }
    }

    const handleClose = async () => {
        if (!id) return
        if (!confirm('Biztos lezarod? A lezaras vegleges, csak FOERTEKTAR+/MANAGER/ADMIN tehet meg.')) return
        try {
            await vaultStocktakeApi.close(id)
            await load()
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err)
            setError(msg)
        }
    }

    const handleCancel = async () => {
        if (!id) return
        const reason = prompt('Megszakitas oka:')
        if (!reason) return
        try {
            await vaultStocktakeApi.cancel(id, reason)
            await load()
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err)
            setError(msg)
        }
    }

    if (loading || !session) {
        return (
            <div className="max-w-5xl mx-auto">
                <div className="text-gray-500">Toltodik...</div>
            </div>
        )
    }

    const items = session.items || []
    const countedItems = items.filter(i => i.actualQuantity !== null).length
    const totalDiscrepancy = items.reduce((sum, i) => sum + (i.discrepancyValue || 0), 0)
    const isEditable = session.status === 'OPEN' || session.status === 'IN_PROGRESS'
    const canReview = isEditable && countedItems === items.length && items.length > 0
    const canClose = session.status === 'REVIEW'

    return (
        <div className="max-w-6xl mx-auto">
            <button
                onClick={() => navigate('/vault-stocktake')}
                className="flex items-center gap-1 text-xs text-gray-600 hover:text-gray-800 mb-2"
            >
                <ArrowLeft className="w-3.5 h-3.5" />
                Vissza a listahoz
            </button>

            <div className="bg-white shadow rounded p-2 mb-2">
                <div className="flex justify-between items-start mb-2">
                    <div>
                        <h1 className="text-base font-bold">{session.sessionName}</h1>
                        <div className="text-xs text-gray-600">
                            Status: <span className="font-medium">{STATUS_LABELS[session.status]}</span>
                            {' - '}Inditotta: {session.startedBy}
                            {' - '}{new Date(session.startedAt).toLocaleString('hu-HU')}
                        </div>
                    </div>
                    <div className="flex gap-2">
                        {canReview && (
                            <button
                                onClick={handleMoveToReview}
                                className="flex items-center gap-1 px-3 py-2 bg-purple-600 text-white rounded text-sm hover:bg-purple-700"
                            >
                                <FileCheck className="w-4 h-4" /> REVIEW-ba
                            </button>
                        )}
                        {canClose && (
                            <button
                                onClick={handleClose}
                                className="flex items-center gap-1 px-3 py-2 bg-green-600 text-white rounded text-sm hover:bg-green-700"
                            >
                                <CheckCircle2 className="w-4 h-4" /> Lezaras
                            </button>
                        )}
                        {session.status !== 'CLOSED' && session.status !== 'CANCELLED' && (
                            <button
                                onClick={handleCancel}
                                className="flex items-center gap-1 px-3 py-2 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
                            >
                                <Ban className="w-4 h-4" /> Megszakitas
                            </button>
                        )}
                    </div>
                </div>

                <div className="grid grid-cols-3 gap-4 mt-4">
                    <div className="bg-gray-50 rounded p-3">
                        <div className="text-xs text-gray-600">Tetel osszesen</div>
                        <div className="text-lg font-bold">{items.length}</div>
                    </div>
                    <div className="bg-blue-50 rounded p-3">
                        <div className="text-xs text-blue-700">Felveve</div>
                        <div className="text-lg font-bold">{countedItems} / {items.length}</div>
                    </div>
                    <div className="bg-yellow-50 rounded p-3">
                        <div className="text-xs text-yellow-700">Elteres osszesen (HUF)</div>
                        <div className={`text-lg font-bold ${totalDiscrepancy < 0 ? 'text-red-600' : totalDiscrepancy > 0 ? 'text-green-600' : ''}`}>
                            {totalDiscrepancy.toLocaleString('hu-HU')}
                        </div>
                    </div>
                </div>

                {session.note && (
                    <div className="mt-3 p-2 bg-gray-50 rounded text-sm whitespace-pre-line">{session.note}</div>
                )}
            </div>

            {error && (
                <div className="bg-red-50 border border-red-200 rounded p-3 mb-4 text-red-700 flex items-center gap-2">
                    <XCircle className="w-5 h-5" />
                    {error}
                </div>
            )}

            {/* Items table */}
            <div className="bg-white shadow rounded overflow-hidden">
                <table className="w-full text-sm">
                    <thead className="bg-gray-100">
                        <tr>
                            <th className="px-4 py-3 text-left">Valuta</th>
                            <th className="px-4 py-3 text-right">Cimlet</th>
                            <th className="px-4 py-3 text-right">Varhato</th>
                            <th className="px-4 py-3 text-right">Tenyleges</th>
                            <th className="px-4 py-3 text-right">Elteres</th>
                            <th className="px-4 py-3 text-right">Elteres HUF</th>
                            <th className="px-4 py-3">Muvelet</th>
                        </tr>
                    </thead>
                    <tbody>
                        {items.map(item => {
                            const hasDisc = item.discrepancy !== null && item.discrepancy !== 0
                            return (
                                <tr key={item.id} className={`border-t ${hasDisc ? 'bg-yellow-50' : ''}`}>
                                    <td className="px-4 py-3 font-medium">{item.currencyCode}</td>
                                    <td className="px-4 py-3 text-right font-mono">{item.faceValue}</td>
                                    <td className="px-4 py-3 text-right font-mono">{item.expectedQuantity}</td>
                                    <td className="px-4 py-3 text-right">
                                        {isEditable ? (
                                            <input
                                                type="number"
                                                min={0}
                                                value={editValues[item.id] ?? (item.actualQuantity?.toString() ?? '')}
                                                onChange={e => setEditValues(prev => ({ ...prev, [item.id]: e.target.value }))}
                                                className="w-24 border rounded px-2 py-1 text-right font-mono"
                                                disabled={saving === item.id}
                                            />
                                        ) : (
                                            <span className="font-mono">{item.actualQuantity ?? '-'}</span>
                                        )}
                                    </td>
                                    <td className={`px-4 py-3 text-right font-mono ${hasDisc ? 'text-red-600 font-bold' : ''}`}>
                                        {item.discrepancy ?? '-'}
                                    </td>
                                    <td className={`px-4 py-3 text-right font-mono ${hasDisc ? 'font-bold' : ''}`}>
                                        {(item.discrepancyValue ?? 0).toLocaleString('hu-HU')}
                                    </td>
                                    <td className="px-4 py-3 text-center">
                                        {isEditable && editValues[item.id] !== undefined && (
                                            <button
                                                onClick={() => handleCountItem(item)}
                                                disabled={saving === item.id}
                                                className="inline-flex items-center gap-1 text-blue-600 hover:text-blue-800 text-xs"
                                            >
                                                <Save className="w-3 h-3" />
                                                Mentes
                                            </button>
                                        )}
                                        {hasDisc && (
                                            <span title="Elteres"><AlertTriangle className="inline w-4 h-4 text-yellow-600 ml-1" /></span>
                                        )}
                                    </td>
                                </tr>
                            )
                        })}
                        {items.length === 0 && (
                            <tr>
                                <td colSpan={7} className="px-4 py-8 text-center text-gray-500">
                                    Nincs tetel - valoszinuleg nincs banknote_inventory a branch-en.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    )
}