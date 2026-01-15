import { useState, useEffect } from 'react'
import { Bell, CheckCircle } from 'lucide-react'
import { notificationApi, Notification } from '../../services/api'

export default function NotificationPage() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      setNotifications(await notificationApi.list())
    } catch (err) {
      console.error('Értesítések betöltési hiba:', err)
      setError('Hiba az értesítések betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleMarkAsRead = async (id: string) => {
    try {
      setError(null)
      await notificationApi.markAsRead(id)
      await loadData()
    } catch (err) {
      console.error('Olvasottnak jelölés hiba:', err)
      setError('Hiba történt az olvasottnak jelölés során')
    }
  }

  const handleMarkAllAsRead = async () => {
    try {
      setError(null)
      await notificationApi.markAllAsRead()
      await loadData()
    } catch (err) {
      console.error('Összes olvasottnak jelölés hiba:', err)
      setError('Hiba történt')
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><Bell />Értesítések</h1>
        <button onClick={handleMarkAllAsRead} className="form-button">
          Összes olvasottnak jelölése
        </button>
      </div>
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Cím</th><th>Üzenet</th><th>Típus</th><th>Dátum</th><th>Olvasva</th><th>Műveletek</th></tr></thead>
            <tbody>
              {notifications.map(n => (
                <tr key={n.id} className={!n.isRead ? 'bg-blue-50' : ''}>
                  <td>{n.title}</td>
                  <td>{n.message}</td>
                  <td><span className="badge badge-blue">{n.type}</span></td>
                  <td>{new Date(n.createdAt).toLocaleString('hu-HU')}</td>
                  <td><span className={`badge ${n.isRead ? 'badge-green' : 'badge-yellow'}`}>{n.isRead ? 'Olvasva' : 'Olvasatlan'}</span></td>
                  <td>{!n.isRead && <button onClick={() => handleMarkAsRead(n.id)} className="form-button text-xs"><CheckCircle size={12} />Olvasott</button>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
