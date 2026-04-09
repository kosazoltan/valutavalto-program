import { useState, useEffect, useCallback } from 'react'
import { Bell, CheckCircle, Send, Megaphone, Mail, AlertTriangle, Info, Filter } from 'lucide-react'
import { notificationApi, Notification } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'

export default function NotificationPage() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showSend, setShowSend] = useState(false)
  const [sendForm, setSendForm] = useState({ title: '', message: '', type: 'INFO', targetWorkerIds: '' })
  const [filterType, setFilterType] = useState<string>('')
  const [filterRead, setFilterRead] = useState<string>('')

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const [all, count] = await Promise.all([
        notificationApi.list(),
        notificationApi.unreadCount().catch(() => 0),
      ])
      setNotifications(all)
      setUnreadCount(count as number)
    } catch (err) {
      logger.error('NotificationPage', 'Értesítések betöltési hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { void loadData() }, [loadData])

  const handleMarkAsRead = async (id: string) => {
    try {
      await notificationApi.markAsRead(id)
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleMarkAllAsRead = async () => {
    try {
      await notificationApi.markAllAsRead()
      toast.success('Összes értesítés olvasottnak jelölve')
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleSend = async () => {
    if (!sendForm.title || !sendForm.message) { toast.warning('Cím és üzenet kötelező'); return }
    try {
      setError(null)
      await notificationApi.send({ ...sendForm })
      toast.success('Értesítés elküldve')
      setShowSend(false)
      setSendForm({ title: '', message: '', type: 'INFO', targetWorkerIds: '' })
      await loadData()
    } catch (err) {
      toast.error('Küldési hiba', getErrorMessage(err))
    }
  }

  const handleBroadcast = async () => {
    if (!sendForm.title || !sendForm.message) { toast.warning('Cím és üzenet kötelező'); return }
    if (!confirm('Biztosan küld körlevelet minden dolgozónak?')) return
    try {
      await notificationApi.broadcast({ title: sendForm.title, message: sendForm.message, type: sendForm.type })
      toast.success('Körlevél elküldve')
      setShowSend(false)
      await loadData()
    } catch (err) {
      toast.error('Küldési hiba', getErrorMessage(err))
    }
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'WARNING': return <AlertTriangle size={14} className="text-yellow-500" />
      case 'ERROR': return <AlertTriangle size={14} className="text-red-500" />
      case 'SUCCESS': return <CheckCircle size={14} className="text-green-500" />
      default: return <Info size={14} className="text-blue-500" />
    }
  }

  const filtered = safeArray<Notification>(notifications).filter(n => {
    if (filterType && n.type !== filterType) return false
    if (filterRead === 'unread' && n.isRead) return false
    if (filterRead === 'read' && !n.isRead) return false
    return true
  })

  const types = [...new Set(notifications.map(n => n.type))].sort()

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Bell />Értesítések
          {unreadCount > 0 && <span className="badge badge-red text-xs">{unreadCount} olvasatlan</span>}
        </h1>
        <div className="flex gap-2">
          <button onClick={() => void handleMarkAllAsRead()} className="form-button"><CheckCircle size={16} /> Mind olvasott</button>
          <button onClick={() => setShowSend(true)} className="form-button-primary"><Send size={16} /> Új értesítés</button>
        </div>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>}

      {/* Send form */}
      {showSend && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">Értesítés küldése</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">Cím *</label>
              <input className="form-input" value={sendForm.title} onChange={e => setSendForm({ ...sendForm, title: e.target.value })} />
            </div>
            <div>
              <label className="form-label">Típus</label>
              <select className="form-input" value={sendForm.type} onChange={e => setSendForm({ ...sendForm, type: e.target.value })}>
                <option value="INFO">Információ</option>
                <option value="WARNING">Figyelmeztetés</option>
                <option value="ERROR">Hiba</option>
                <option value="SUCCESS">Siker</option>
              </select>
            </div>
          </div>
          <div>
            <label className="form-label">Üzenet *</label>
            <textarea className="form-input" rows={3} value={sendForm.message} onChange={e => setSendForm({ ...sendForm, message: e.target.value })} />
          </div>
          <div>
            <label className="form-label">Címzett dolgozó ID-k (vesszővel elválasztva, üres = saját)</label>
            <input className="form-input" value={sendForm.targetWorkerIds} onChange={e => setSendForm({ ...sendForm, targetWorkerIds: e.target.value })} placeholder="pl. 1,2,3" />
          </div>
          <div className="flex gap-2">
            <button onClick={() => void handleSend()} className="form-button-primary"><Mail size={16} /> Küldés</button>
            <button onClick={() => void handleBroadcast()} className="form-button"><Megaphone size={16} /> Körlevél mindenkinek</button>
            <button onClick={() => setShowSend(false)} className="form-button">Mégse</button>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="form-panel flex gap-3 items-end">
        <Filter size={16} className="text-gray-400" />
        <div>
          <label className="form-label">Típus</label>
          <select className="form-input" value={filterType} onChange={e => setFilterType(e.target.value)}>
            <option value="">Mind</option>
            {types.map(t => <option key={t} value={t}>{t}</option>)}
          </select>
        </div>
        <div>
          <label className="form-label">Státusz</label>
          <select className="form-input" value={filterRead} onChange={e => setFilterRead(e.target.value)}>
            <option value="">Mind</option>
            <option value="unread">Olvasatlan</option>
            <option value="read">Olvasott</option>
          </select>
        </div>
        <span className="text-sm text-gray-500">{filtered.length} értesítés</span>
      </div>

      {/* Table */}
      <div className="form-panel">
        {loading ? <div>Betöltés...</div> : filtered.length === 0 ? (
          <div className="text-center text-gray-500 py-4">Nincs értesítés</div>
        ) : (
          <table className="data-grid w-full">
            <thead><tr><th>Típus</th><th>Cím</th><th>Üzenet</th><th>Dátum</th><th>Státusz</th><th>Műveletek</th></tr></thead>
            <tbody>
              {filtered.map(n => (
                <tr key={n.id} className={n.isRead ? '' : 'bg-blue-50 font-medium'}>
                  <td>{getTypeIcon(n.type)} <span className="text-sm">{n.type}</span></td>
                  <td>{n.title}</td>
                  <td className="text-sm max-w-xs truncate">{n.message}</td>
                  <td className="text-sm">{new Date(n.createdAt).toLocaleString('hu-HU')}</td>
                  <td><span className={`badge ${n.isRead ? 'badge-green' : 'badge-yellow'}`}>{n.isRead ? 'Olvasva' : 'Új'}</span></td>
                  <td>{!n.isRead && <button onClick={() => void handleMarkAsRead(n.id)} className="form-button text-xs"><CheckCircle size={12} /> Olvasott</button>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
