import { useState, useEffect, useCallback } from 'react'
import { Bell, CheckCircle, Send, Megaphone, Mail, AlertTriangle, Info, Filter } from 'lucide-react'
import { notificationApi, Notification } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function NotificationPage() {
  const { t } = useTranslation()
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showSend, setShowSend] = useState(false)
  const [sendForm, setSendForm] = useState({
    title: '',
    message: '',
    type: 'INFO',
    workerId: '',
    channel: 'email',
  })
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

  useEffect(() => {
    void loadData()
  }, [loadData])

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
    if (!sendForm.title || !sendForm.message) {
      toast.warning('Cím és üzenet kötelező')
      return
    }
    const workerId = Number(sendForm.workerId)
    if (!Number.isInteger(workerId) || workerId <= 0) {
      toast.warning('Címzett dolgozó ID kötelező')
      return
    }
    try {
      setError(null)
      if (sendForm.channel === 'in-app') {
        await notificationApi.sendInApp({
          userId: String(workerId),
          title: sendForm.title,
          message: sendForm.message,
          type: sendForm.type,
        })
      } else {
        await notificationApi.send({
          workerId,
          title: sendForm.title,
          message: sendForm.message,
          type: sendForm.type,
        })
      }
      toast.success('Értesítés elküldve')
      setShowSend(false)
      setSendForm({ title: '', message: '', type: 'INFO', workerId: '', channel: 'email' })
      await loadData()
    } catch (err) {
      toast.error('Küldési hiba', getErrorMessage(err))
    }
  }

  const handleBroadcast = async () => {
    if (!sendForm.title || !sendForm.message) {
      toast.warning('Cím és üzenet kötelező')
      return
    }
    if (!confirm('Biztosan küld körlevelet minden dolgozónak?')) return
    try {
      await notificationApi.broadcast({
        title: sendForm.title,
        message: sendForm.message,
        type: sendForm.type,
      })
      toast.success('Körlevél elküldve')
      setShowSend(false)
      await loadData()
    } catch (err) {
      toast.error('Küldési hiba', getErrorMessage(err))
    }
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'WARNING':
        return <AlertTriangle size={14} className="text-yellow-500" />
      case 'ERROR':
        return <AlertTriangle size={14} className="text-red-500" />
      case 'SUCCESS':
        return <CheckCircle size={14} className="text-green-500" />
      default:
        return <Info size={14} className="text-blue-500" />
    }
  }

  const filtered = safeArray<Notification>(notifications).filter((n) => {
    if (filterType && n.type !== filterType) return false
    if (filterRead === 'unread' && n.isRead) return false
    if (filterRead === 'read' && !n.isRead) return false
    return true
  })

  const types = [...new Set(notifications.map((n) => n.type))].sort()

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Bell />
          {t('notifications.ertesitesek')}
          {unreadCount > 0 && (
            <span className="badge badge-red text-xs">
              {unreadCount} {t('notifications.olvasatlan')}
            </span>
          )}
        </h1>
        <div className="flex gap-2">
          <button onClick={() => void handleMarkAllAsRead()} className="form-button">
            <CheckCircle size={16} />
            {t('notifications.mindOlvasott')}
          </button>
          <button onClick={() => setShowSend(true)} className="form-button-primary">
            <Send size={16} />
            {t('notifications.ujErtesites')}
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Send form */}
      {showSend && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">{t('notifications.ertesitesKuldese')}</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">{t('circulars.cim')}</label>
              <input
                className="form-input"
                value={sendForm.title}
                onChange={(e) => setSendForm({ ...sendForm, title: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.type')}</label>
              <select
                className="form-input"
                value={sendForm.type}
                onChange={(e) => setSendForm({ ...sendForm, type: e.target.value })}
              >
                <option value="INFO">{t('notifications.informacio')}</option>
                <option value="WARNING">{t('notifications.figyelmeztetes')}</option>
                <option value="ERROR">{t('common.error')}</option>
                <option value="SUCCESS">{t('notifications.siker')}</option>
              </select>
            </div>
          </div>
          <div>
            <label className="form-label">{t('notifications.uzenet')}</label>
            <textarea
              className="form-input"
              rows={3}
              value={sendForm.message}
              onChange={(e) => setSendForm({ ...sendForm, message: e.target.value })}
            />
          </div>
          <div>
            <label className="form-label">{t('notifications.cimzettDolgozoId')}</label>
            <input
              className="form-input"
              value={sendForm.workerId}
              onChange={(e) => setSendForm({ ...sendForm, workerId: e.target.value })}
              placeholder="pl. 1"
            />
          </div>
          <div>
            <label className="form-label">{i18n.t('literals.kuldesi-mod')}</label>
            <select
              className="form-input"
              value={sendForm.channel}
              onChange={(e) => setSendForm({ ...sendForm, channel: e.target.value })}
              data-testid="notification-channel"
            >
              <option value="email">{i18n.t('literals.in-app-email')}</option>
              <option value="in-app">{i18n.t('literals.csak-in-app')}</option>
            </select>
          </div>
          <div className="flex gap-2">
            <button onClick={() => void handleSend()} className="form-button-primary">
              <Mail size={16} />
              {t('common.send')}
            </button>
            <button onClick={() => void handleBroadcast()} className="form-button">
              <Megaphone size={16} />
              {t('notifications.korlevelMindenkinek')}
            </button>
            <button onClick={() => setShowSend(false)} className="form-button">
              {t('common.cancel')}
            </button>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="form-panel flex gap-3 items-end">
        <Filter size={16} className="text-gray-400" />
        <div>
          <label className="form-label">{t('common.type')}</label>
          <select
            className="form-input"
            value={filterType}
            onChange={(e) => setFilterType(e.target.value)}
          >
            <option value="">{t('common.all')}</option>
            {types.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="form-label">{t('common.status')}</label>
          <select
            className="form-input"
            value={filterRead}
            onChange={(e) => setFilterRead(e.target.value)}
          >
            <option value="">{t('common.all')}</option>
            <option value="unread">{t('notifications.olvasatlan')}</option>
            <option value="read">{t('notifications.olvasott')}</option>
          </select>
        </div>
        <span className="text-sm text-gray-500">
          {filtered.length} {t('notifications.ertesites')}
        </span>
      </div>

      {/* Table */}
      <div className="form-panel">
        {loading ? (
          <div>{i18n.t('literals.betoltes')}</div>
        ) : filtered.length === 0 ? (
          <div className="text-center text-gray-500 py-4">{t('notifications.nincsErtesites')}</div>
        ) : (
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{t('common.type')}</th>
                <th>{t('common.address')}</th>
                <th>{t('notifications.uzenet2')}</th>
                <th>{t('common.date')}</th>
                <th>{t('common.status')}</th>
                <th>{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((n) => (
                <tr key={n.id} className={n.isRead ? '' : 'bg-blue-50 font-medium'}>
                  <td>
                    {getTypeIcon(n.type)} <span className="text-sm">{n.type}</span>
                  </td>
                  <td>{n.title}</td>
                  <td className="text-sm max-w-xs truncate">{n.message}</td>
                  <td className="text-sm">{new Date(n.createdAt).toLocaleString('hu-HU')}</td>
                  <td>
                    <span className={`badge ${n.isRead ? 'badge-green' : 'badge-yellow'}`}>
                      {n.isRead ? 'Olvasva' : 'Új'}
                    </span>
                  </td>
                  <td>
                    {!n.isRead && (
                      <button
                        onClick={() => void handleMarkAsRead(n.id)}
                        className="form-button text-xs"
                      >
                        <CheckCircle size={12} /> {t('notifications.olvasott')}
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
