import { app, BrowserWindow, dialog, Notification } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';

/**
 * Electron auto-update modul (vezerlokonyv par.29).
 *
 * Mukodes:
 *  1. App inditasakor minden 4 oraban + start-kor ellenorzi a GitHub Releases-et.
 *  2. Ha van uj verzio: torolt hatterben letolti.
 *  3. Letoltes utan modal dialog kerdez a user-tol.
 *  4. Elfogadas eseten: telepites + auto-restart.
 *
 * GitHub Releases requirement (electron-builder.json publish.provider: github):
 *  - A release-nek `latest.yml` (Windows) / `latest-mac.yml` / `latest-linux.yml`
 *    fajlt kell tartalmaznia, amit az electron-builder automatikusan general.
 *  - A build workflow peldaja: .github/workflows/build-penztar-installer.yml
 *  - GH_TOKEN env var szukseges a publish-hez (build-time).
 */

autoUpdater.logger = log;
autoUpdater.autoDownload = true;
autoUpdater.autoInstallOnAppQuit = true;

// Staged rollout - csak a felhasznalok x%-a kap updatet eloszor
// (vezerlokonyv par.29.2)
const STAGED_ROLLOUT_PERCENT = parseInt(process.env.UPDATE_ROLLOUT_PERCENT || '100', 10);

function shouldUpdate(currentVersion: string): boolean {
  if (STAGED_ROLLOUT_PERCENT >= 100) return true;
  // Determinisztikus: version+machineId alapu hash
  const input = currentVersion + (process.env.COMPUTERNAME || '');
  let hash = 0;
  for (let i = 0; i < input.length; i++) hash = ((hash << 5) - hash + input.charCodeAt(i)) | 0;
  const percentile = Math.abs(hash) % 100;
  return percentile < STAGED_ROLLOUT_PERCENT;
}

export function initAutoUpdate(mainWindow: BrowserWindow | null) {
  const currentVersion = app.getVersion();
  log.info(`[autoUpdate] Current version: ${currentVersion}`);
  log.info(`[autoUpdate] Staged rollout: ${STAGED_ROLLOUT_PERCENT}%`);

  if (!shouldUpdate(currentVersion)) {
    log.info('[autoUpdate] Staged rollout excluded this install.');
    return;
  }

  autoUpdater.on('checking-for-update', () => {
    log.info('[autoUpdate] checking-for-update');
  });

  autoUpdater.on('update-available', (info) => {
    log.info('[autoUpdate] update-available:', info.version);
    new Notification({
      title: 'Frissites elerheto',
      body: `v${info.version} letoltese megkezdodott a hatterben.`,
    }).show();
  });

  autoUpdater.on('update-not-available', () => {
    log.info('[autoUpdate] update-not-available');
  });

  autoUpdater.on('download-progress', (p) => {
    log.info(`[autoUpdate] download ${Math.round(p.percent)}% (${Math.round(p.bytesPerSecond / 1024)} KB/s)`);
    mainWindow?.webContents.send('autoUpdate:progress', p);
  });

  autoUpdater.on('update-downloaded', async (info) => {
    log.info('[autoUpdate] update-downloaded:', info.version);
    const choice = await dialog.showMessageBox(mainWindow!, {
      type: 'info',
      buttons: ['Ujraindit es telepit', 'Kesobb'],
      defaultId: 0,
      cancelId: 1,
      title: 'Frissites telepitese',
      message: `Uj verzio elerheto: v${info.version}`,
      detail: 'A telepiteshez az applikacio ujraindul. Kerjuk, mentse el a munkat.',
    });
    if (choice.response === 0) {
      autoUpdater.quitAndInstall();
    }
  });

  autoUpdater.on('error', (err) => {
    log.error('[autoUpdate] error:', err);
  });

  // Elso check 10 mp-el app indulas utan (hogy ne blokkoljunk a UI rendering-et)
  setTimeout(() => autoUpdater.checkForUpdates().catch(e => log.error(e)), 10_000);
  // Utana minden 4 oraban
  setInterval(() => autoUpdater.checkForUpdates().catch(e => log.error(e)), 4 * 60 * 60 * 1000);
}
