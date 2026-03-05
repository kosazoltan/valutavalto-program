import { useState, useEffect, useCallback, useRef } from 'react';
import {
  getUnreadCount,
  getUnreadNotifications,
  markAsRead,
  markAllAsRead,
  type NotificationData,
} from '@/api/notifications';

export default function NotificationBell() {
  const [count, setCount] = useState(0);
  const [open, setOpen] = useState(false);
  const [notifications, setNotifications] = useState<NotificationData[]>([]);
  const [loading, setLoading] = useState(false);
  const panelRef = useRef<HTMLDivElement>(null);

  const loadCount = useCallback(async () => {
    try {
      const c = await getUnreadCount();
      setCount(c);
    } catch {
      // silent
    }
  }, []);

  const loadNotifications = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getUnreadNotifications();
      setNotifications(data);
      setCount(data.length);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  }, []);

  // Poll every 30 seconds
  useEffect(() => {
    void loadCount();
    const interval = setInterval(() => void loadCount(), 30_000);
    return () => clearInterval(interval);
  }, [loadCount]);

  // Load full list when opened
  useEffect(() => {
    if (open) void loadNotifications();
  }, [open, loadNotifications]);

  // Close on outside click
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (panelRef.current && !panelRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    if (open) document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, [open]);

  const handleMarkRead = async (id: string) => {
    try {
      await markAsRead(id);
      setNotifications((prev) => prev.filter((n) => n.id !== id));
      setCount((c) => Math.max(0, c - 1));
    } catch {
      // silent
    }
  };

  const handleMarkAllRead = async () => {
    try {
      await markAllAsRead();
      setNotifications([]);
      setCount(0);
    } catch {
      // silent
    }
  };

  const typeIcon = (type: string) => {
    switch (type) {
      case 'WARNING': return '⚠️';
      case 'ALERT': return '🚨';
      case 'RATE_CHANGE': return '📊';
      case 'CIRCULAR': return '📨';
      case 'SYSTEM': return '⚙️';
      default: return 'ℹ️';
    }
  };

  return (
    <div className="relative" ref={panelRef}>
      <button
        onClick={() => setOpen(!open)}
        className="relative rounded-lg bg-white/20 px-3 py-2 text-sm text-white hover:bg-white/30"
      >
        🔔
        {count > 0 && (
          <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-xs font-bold text-white">
            {count > 99 ? '99+' : count}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 top-full z-50 mt-2 w-80 rounded-xl border bg-white shadow-xl">
          <div className="flex items-center justify-between border-b px-4 py-3">
            <h3 className="font-semibold text-gray-700">🔔 Értesítések</h3>
            {notifications.length > 0 && (
              <button
                onClick={() => void handleMarkAllRead()}
                className="text-xs text-blue-600 hover:underline"
              >
                Mind olvasott
              </button>
            )}
          </div>

          <div className="max-h-80 overflow-y-auto">
            {loading ? (
              <p className="p-4 text-center text-sm text-gray-400">⏳ Betöltés...</p>
            ) : notifications.length === 0 ? (
              <p className="p-4 text-center text-sm text-gray-400">Nincs új értesítés.</p>
            ) : (
              notifications.map((n) => (
                <div
                  key={n.id}
                  className="flex items-start gap-2 border-b px-4 py-3 hover:bg-gray-50 cursor-pointer"
                  onClick={() => void handleMarkRead(n.id)}
                >
                  <span className="mt-0.5 text-lg">{typeIcon(n.type)}</span>
                  <div className="flex-1">
                    <div className="text-sm font-medium text-gray-800">{n.title}</div>
                    <div className="text-xs text-gray-500 line-clamp-2">{n.message}</div>
                    <div className="mt-1 text-xs text-gray-400">
                      {new Date(n.createdAt).toLocaleString('hu-HU')}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}
