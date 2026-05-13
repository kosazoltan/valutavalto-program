import { useState, useEffect } from 'react';
import { isElectron } from '@/utils/electron';
import { logger } from '../utils/logger';
import { isAppMode } from '../types/appMode';
import type { AppMode } from '../types/appMode';

/**
 * App mód típus — kiterjesztve a frontend-react 'full' móddal.
 *
 * - 'full':      böngészőben futó admin felület és központi helyi munkaállomás
 * - 'penztar':   Electron pénztáros mód (F1-F12 menü)
 * - 'ertektar':  Electron értéktár / regionális központ mód
 * - 'rate-maker': Electron főértéktárosi árfolyamkészítő
 * - 'ertekszallito': Electron értékszállító mód
 */
export type { AppMode } from '../types/appMode';

/**
 * App mód betöltése:
 * - Böngészőben: mindig 'full'
 * - Electronban: 'app_mode' kulcs az SQLite config store-ból
 */
async function loadAppMode(): Promise<AppMode> {
  if (!isElectron()) {
    return 'full';
  }

  try {
    const stored = await window.electronAPI?.getConfig('app_mode');
    if (isAppMode(stored)) {
      return stored;
    }
  } catch (err) {
    logger.error('useAppMode', 'Config betöltési hiba:', err);
  }

  if (import.meta.env.VITE_APP_FLAVOR === 'rate-maker') {
    return 'rate-maker';
  }
  if (import.meta.env.VITE_APP_FLAVOR === 'central-workstation') {
    return 'full';
  }

  // Electron default: penztar
  return 'penztar';
}

/**
 * React hook — app mód lekérdezése.
 *
 * Böngészőben azonnal 'full'-t ad vissza (isLoading=false).
 * Electronban aszinkron betölti az SQLite config store-ból.
 *
 * @returns { mode, isLoading }
 */
export function useAppMode(): { mode: AppMode; isLoading: boolean } {
  // Böngészőben rögtön 'full', Electronban az adott telepített kliens módja az átmeneti állapot
  const [mode, setMode] = useState<AppMode>(() => {
    if (!isElectron()) return 'full';
    if (import.meta.env.VITE_APP_FLAVOR === 'central-workstation') return 'full';
    return import.meta.env.VITE_APP_FLAVOR === 'rate-maker' ? 'rate-maker' : 'penztar';
  });
  const [isLoading, setIsLoading] = useState(() => isElectron());

  useEffect(() => {
    if (!isElectron()) {
      // Böngészőben nincs aszinkron munka — mód már helyes az initializer-ből
      return;
    }

    let cancelled = false;

    const load = async () => {
      try {
        const loaded = await loadAppMode();
        if (!cancelled) {
          setMode(loaded);
        }
      } catch (err) {
        logger.error('useAppMode', 'Hiba:', err);
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
