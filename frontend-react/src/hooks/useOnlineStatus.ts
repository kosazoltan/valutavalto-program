import { useState, useEffect, useCallback, useRef } from 'react';
import { isElectron } from '../utils/electron';
import { api } from '../services/api/index';

const HEALTH_CHECK_INTERVAL_MS = 30_000;

/**
 * Online állapot hook — dual-platform (böngésző + Electron).
 *
 * Böngészőben: navigator.onLine alapján működik, backend health check aktív.
 * Electronban: navigator.onLine + 30 másodperces backend health check.
 *
 * Visszatérés: { isOnline, isNetworkOnline, isBackendReachable, lastCheckedAt }
 */
export function useOnlineStatus() {
  const [isNetworkOnline, setIsNetworkOnline] = useState(
    typeof navigator !== 'undefined' ? navigator.onLine : true
  );
  const [isBackendReachable, setIsBackendReachable] = useState(true);
  const [lastCheckedAt, setLastCheckedAt] = useState<Date | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Electronban futunk-e?
  const inElectron = isElectron();

  const checkBackend = useCallback(async () => {
    try {
      await api.get('/actuator/health', { timeout: 5_000 });
      setIsBackendReachable(true);
    } catch {
      setIsBackendReachable(false);
    }
    setLastCheckedAt(new Date());
  }, []);

  // Navigator online/offline események
  useEffect(() => {
    const handleOnline = () => {
      setIsNetworkOnline(true);
      // Azonnal ellenőrzés
      void checkBackend();
    };
    const handleOffline = () => {
      setIsNetworkOnline(false);
      setIsBackendReachable(false);
      setLastCheckedAt(new Date());
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [checkBackend]);

  // Periodikus backend health check — Electronban mindig, böngészőben opcionális
  useEffect(() => {
    if (!inElectron) {
      // Böngészőben is futtatunk egy kezdeti ellenőrzést, de nem pollozunk
      void checkBackend();
      return;
    }

    void checkBackend();
    intervalRef.current = setInterval(() => {
      void checkBackend();
    }, HEALTH_CHECK_INTERVAL_MS);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [checkBackend, inElectron]);

  return {
    isOnline: isNetworkOnline && isBackendReachable,
    isNetworkOnline,
    isBackendReachable,
    lastCheckedAt,
  };
}
