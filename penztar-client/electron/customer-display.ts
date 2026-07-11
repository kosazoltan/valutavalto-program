/**
 * VFD (Vacuum Fluorescent Display) ügyfélkijelző — második Electron BrowserWindow
 * a tranzakció részleteinek megjelenítésére az ügyfélnek.
 *
 * Két konfiguráció:
 *  - Egy monitoros: ablak-keret nélkül, mindig-felül flag, kicsi méret
 *  - Két monitoros: a nem-elsődleges kijelzőn full-screen
 *
 * Hivatkozás: D:\valutavalto-vault\references\p2-features-design-2026-05-06.md (P2-1)
 */

import { BrowserWindow, screen } from 'electron';
import { createBeforeInputHandler } from './input-guard';

export interface CustomerDisplayPayload {
  transactionType?: 'BUY' | 'SELL' | 'CONVERSION' | 'STORNO';
  currencyCode?: string;
  amount?: number;
  hufAmount?: number;
  rate?: number;
  handlingFee?: number;
  totalHuf?: number;
  message?: string; // pl. "Üdvözöljük!", "Köszönjük!"
}

let displayWindow: BrowserWindow | null = null;

/**
 * Az ügyfélkijelző-ablak létrehozása. Ha már létezik egy nyitott ablak,
 * azt visszaadjuk (idempotens hívás).
 *
 * @param rendererUrl  A renderer alap-URL (dev: http://127.0.0.1:3000, prod: app://localhost/)
 * @param preferSecondMonitor  Ha true és van második monitor → full-screen a másik kijelzőn.
 */
export function createCustomerDisplay(
  rendererUrl: string,
  preferSecondMonitor = true,
): BrowserWindow {
  // Ha már nyitott ablakunk van, ne hozzunk létre újat — egyszerűen visszaadjuk
  if (displayWindow && !displayWindow.isDestroyed()) {
    return displayWindow;
  }

  const displays = screen.getAllDisplays();
  const primary = screen.getPrimaryDisplay();
  const secondary = displays.find((d) => d.id !== primary.id);

  const useSecondary = preferSecondMonitor && secondary != null;
  const target = useSecondary ? secondary : primary;

  displayWindow = new BrowserWindow({
    width: useSecondary ? target.bounds.width : 600,
    height: useSecondary ? target.bounds.height : 400,
    x: useSecondary ? target.bounds.x : primary.bounds.width - 620,
    y: useSecondary ? target.bounds.y : primary.bounds.height - 420,
    frame: !useSecondary,
    alwaysOnTop: !useSecondary,
    fullscreen: useSecondary,
    resizable: !useSecondary,
    title: 'Ügyfélkijelző',
    autoHideMenuBar: true,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  // A renderer customer-display útvonalra navigál (HashRouter-kompatibilis URL)
  const url = `${rendererUrl}#/customer-display`;
  void displayWindow.loadURL(url);

  // Böngésző-print (Ctrl+P) tiltása az ügyfélkijelzőn is — ugyanaz az input-őr,
  // mint a fő ablakon (DevTools-toggle nélkül).
  displayWindow.webContents.on('before-input-event', createBeforeInputHandler());

  displayWindow.on('closed', () => {
    displayWindow = null;
  });

  return displayWindow;
}

/**
 * Az aktuális tranzakció-állapot átadása a customer-display renderer-nek
 * IPC csatornán keresztül. Ha az ablak nincs nyitva, no-op.
 */
export function updateCustomerDisplay(payload: CustomerDisplayPayload): void {
  if (!displayWindow || displayWindow.isDestroyed()) return;
  displayWindow.webContents.send('customer-display:update', payload);
}

/**
 * Az ügyfélkijelző ablakának bezárása.
 */
export function hideCustomerDisplay(): void {
  if (displayWindow && !displayWindow.isDestroyed()) {
    displayWindow.close();
  }
  displayWindow = null;
}

/**
 * Visszaadja, hogy van-e jelenleg nyitott ügyfélkijelző-ablak.
 */
export function isCustomerDisplayActive(): boolean {
  return displayWindow != null && !displayWindow.isDestroyed();
}
