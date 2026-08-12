import { app, BrowserWindow, dialog, Notification } from 'electron';
import { autoUpdater } from 'electron-updater';
import log from 'electron-log';

/**
 * Electron auto-update modul (vezerlokonyv par.29) — LEGACY, INAKTIV FEED.
 *
 * === FIGYELEM: EZ A MODUL JELENLEG NEM TUD FRISSITENI ===
 * A penztar-telepitesek `app-update.yml`-je a `penztar` channelt keresi a GitHub
 * Releases-ben, de oda `penztar.yml` SOSEM kerul fel — es ez TUDATOS dontes, nem
 * hiany. Indok (`docs/auto-update-terv-es-vegrehajtas.md` 3.2 szakasz):
 * az electron-updater NSIS-frissitoje a sajat electron-builder GUID-alapu
 * registry-kulcsabol oldja fel a telepitesi konyvtarat, a penztar viszont a kezzel
 * irt `installer/Penztar-Setup.nsi`-vel telepul (`ValutavaltoPenztar` kulcs, lapos
 * `$PROGRAMFILES64` layout, NSSM service-ek). Ha ide feedet adnank, az update-installer
 * egy MASODIK, parhuzamos telepitest hozna letre, mikozben a suite tobbi resze
 * (backend JAR, jlink JRE, PostgreSQL, NSSM service-ek, parancsikonok) a regi helyen,
 * regi verzion maradna -> kliens/lokalis-backend verzio-szetcsuszas.
 *
 * A `windows-signed-release.yml` publish jobja gepi kapuval tiltja a `penztar.yml` /
 * `latest.yml` felkerulesert ("TILOS update-manifest a release-ben").
 *
 * === MI LESZ A HELYETTE ===
 * A penztar frissitesi EGYSEGE a TELJES aláírt suite-telepito. A tervezett
 * `suite-update.ts` (2. fazis) a `update-manifest.json`-t figyeli, letolti a teljes
 * `Penztar-Setup-*.exe`-t, SHA-256 + Authenticode ellenorzes utan `/S` csendes
 * upgrade-kent futtatja — es a telepites CSAK allapotvezerelt ablakban indul
 * (napnyitas ELOTT vagy napzaras UTAN, munka kozben sosem; 3.6 szakasz).
 *
 * === HASZNALJ INKABB ===
 * Uj updater-bekotesnel a kozos platform-modult: `initElectronUpdater` /
 * `isInRollout` a `packages/electron-platform/src/auto-update.ts`-bol (a KOZPONTI
 * kliens ezt hasznalja, mert tiszta electron-builder NSIS telepitoje van).
 * Az itteni staged-rollout hash logikaja onnan elerheto `isInRollout` neven.
 *
 * Mukodes (amig a feed nem letezik, a check csak `update-not-available`/hiba):
 *  1. App inditasakor +10 mp, majd 4 oranként ellenorzi a GitHub Releases-et.
 *  2. Ha van uj verzio: hatterben letolti.
 *  3. Letoltes utan modal dialog kerdez a user-tol.
 *  4. Elfogadas eseten: telepites + auto-restart.
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
    log.info(
      `[autoUpdate] download ${Math.round(p.percent)}% (${Math.round(p.bytesPerSecond / 1024)} KB/s)`,
    );
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
  setTimeout(() => autoUpdater.checkForUpdates().catch((e) => log.error(e)), 10_000);
  // Utana minden 4 oraban
  setInterval(() => autoUpdater.checkForUpdates().catch((e) => log.error(e)), 4 * 60 * 60 * 1000);
}
