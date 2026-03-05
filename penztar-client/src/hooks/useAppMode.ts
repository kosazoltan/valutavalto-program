import { useState, useEffect } from 'react';
import { loadAppMode, type AppMode } from '@/config/appMode';

/**
 * React hook — app mód betöltése (penztar / ertektar).
 * Visszatérés: { mode, isLoading }
 */
export function useAppMode(): { mode: AppMode; isLoading: boolean } {
  const [mode, setMode] = useState<AppMode>('penztar');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      try {
        const loaded = await loadAppMode();
        if (!cancelled) {
          setMode(loaded);
        }
      } catch (err) {
        console.error('[useAppMode] Hiba:', err);
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    };

    void load();

    return () => {
      cancelled = true;
    };
  }, []);

  return { mode, isLoading };
}
