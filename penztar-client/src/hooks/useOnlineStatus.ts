import { useState, useEffect, useCallback, useRef } from 'react';
import apiClient from '@/api/client';

const HEALTH_CHECK_INTERVAL_MS = 30_000;

/**
 * Online állapot hook — navigator.onLine + 30s backend health check
 * Visszatérés: { isOnline, isBackendReachable, lastCheckedAt }
 */
export function useOnlineStatus() {
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [isBackendReachable, setIsBackendReachable] = useState(true);
  const [lastCheckedAt, setLastCheckedAt] = useState<Date | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const checkBackend = useCallback(async () => {
    try {
      await apiClient.get('/health', { timeout: 5_000 });
      setIsBackendReachable(true);
    } catch {
      setIsBackendReachable(false);
    }
    setLastCheckedAt(new Date());
  }, []);

  // Navigator online/offline events
  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      // Újraellenőrzés azonnal
      void checkBackend();
    };
    const handleOffline = () => {
      setIsOnline(false);
      setIsBackendReachable(false);
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [checkBackend]);

  // 30s-os periodikus health check
  useEffect(() => {
    void checkBackend();
    intervalRef.current = setInterval(() => {
      void checkBackend();
    }, HEALTH_CHECK_INTERVAL_MS);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [checkBackend]);

  return {
    isOnline: isOnline && isBackendReachable,
    isNetworkOnline: isOnline,
    isBackendReachable,
    lastCheckedAt,
  };
}
