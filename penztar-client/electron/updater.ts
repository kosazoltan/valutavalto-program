import { app, ipcMain } from 'electron';

ipcMain.handle('restart-app', () => {
  app.relaunch();
  app.exit(0);
});
