import { autoUpdater } from 'electron-updater';
import { BrowserWindow, dialog } from 'electron';
import log from 'electron-log';

// Auto-updater logging
autoUpdater.logger = log;
// @ts-ignore
autoUpdater.logger.transports.file.level = 'info';

/**
 * Auto-updater inicializálás
 * - GitHub releases-ből tölti le az új verziókat
 * - Felhasználói jóváhagyás szükséges a frissítéshez
 */
export function setupAutoUpdater(mainWindow: BrowserWindow): void {
  // Ne automatikusan töltse le az új verziót
  autoUpdater.autoDownload = false;
  autoUpdater.autoInstallOnAppQuit = true;

  // Új verzió elérhető
  autoUpdater.on('update-available', (info) => {
    log.info('✅ Új verzió elérhető:', info.version);
    
    // Küldd el az információt a renderer-nek
    mainWindow.webContents.send('update-available', {
      version: info.version,
      releaseDate: info.releaseDate,
      releaseNotes: info.releaseNotes,
    });

    // Dialog: "Új verzió elérhető"
    dialog
      .showMessageBox(mainWindow, {
        type: 'info',
        title: 'Frissítés Elérhető',
        message: `Új verzió elérhető: v${info.version}`,
        detail: 'Szeretnéd most letölteni és telepíteni?',
        buttons: ['Igen, frissítés most', 'Később'],
        defaultId: 0,
        cancelId: 1,
      })
      .then((result) => {
        if (result.response === 0) {
          // Felhasználó jóváhagyása → letöltés indítása
          autoUpdater.downloadUpdate();
        }
      });
  });

  // Letöltés folyamatban
  autoUpdater.on('download-progress', (progressObj) => {
    log.info(`Letöltés folyamatban: ${progressObj.percent.toFixed(2)}%`);
    mainWindow.webContents.send('update-download-progress', progressObj.percent);
  });

  // Letöltés kész
  autoUpdater.on('update-downloaded', (info) => {
    log.info('✅ Frissítés letöltve, telepítés indítható');
    
    // Dialog: "Frissítés telepítése most?"
    dialog
      .showMessageBox(mainWindow, {
        type: 'info',
        title: 'Frissítés Kész',
        message: 'Az új verzió letöltve. Telepítés most?',
        detail: 'Az alkalmazás újraindul a telepítés után.',
        buttons: ['Újraindítás és telepítés', 'Később'],
        defaultId: 0,
        cancelId: 1,
      })
      .then((result) => {
        if (result.response === 0) {
          // Telepítés + újraindítás
          autoUpdater.quitAndInstall(false, true);
        }
      });
  });

  // Nincs új verzió
  autoUpdater.on('update-not-available', () => {
    log.info('ℹ️ Nincs új verzió');
  });

  // Hiba
  autoUpdater.on('error', (err) => {
    log.error('❌ Auto-updater hiba:', err);
    mainWindow.webContents.send('update-error', err.message);
  });

  // Frissítés ellenőrzés indítás (app ready után)
  log.info('🔍 Auto-updater inicializálva');
}

/**
 * Frissítés ellenőrzés manuális trigger
 */
export function checkForUpdates(): void {
  autoUpdater.checkForUpdates();
}
