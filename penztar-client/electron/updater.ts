import { app, ipcMain } from 'electron';
import log from 'electron-log/main';

export function registerUpdaterHandlers(): void {
  ipcMain.handle('restart-app', () => {
    try {
      app.relaunch();
      app.exit(0);
      return true;
    } catch (err) {
      log.error('[Updater] restart-app failed', err);
      return false;
    }
  });
}
