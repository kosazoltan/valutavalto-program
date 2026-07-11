import { test, expect, type Page, type ElectronApplication } from '@playwright/test';
import { _electron as electron } from 'playwright';
import path from 'node:path';
import fs from 'node:fs';

const MAIN_JS = path.join(__dirname, '..', 'dist-electron', 'main.js');
const PROJECT_ROOT = path.join(__dirname, '..');
const ELECTRON_EXE = path.join(PROJECT_ROOT, 'node_modules', 'electron', 'dist', 'electron.exe');
const USER_DATA = path.join(__dirname, '..', '.e2e-userdata-ctrlp');

let electronApp: ElectronApplication;
let page: Page;

test.describe.configure({ mode: 'serial' });

test.beforeAll(async () => {
  if (fs.existsSync(USER_DATA)) fs.rmSync(USER_DATA, { recursive: true, force: true });
  electronApp = await electron.launch({
    executablePath: ELECTRON_EXE,
    args: [MAIN_JS],
    env: {
      ...process.env,
      NODE_ENV: 'production',
      ELECTRON_FORCE_PACKAGED: '1',
      ELECTRON_DEV_USER_DATA: USER_DATA,
    },
  });
  page = await electronApp.firstWindow();
  await page.waitForLoadState('domcontentloaded');
});

test.afterAll(async () => {
  if (electronApp) await electronApp.close();
});

test('Ctrl+P: a renderer nem kap keydown-t és nem nyílik új ablak', async () => {
  const windowsBefore = await electronApp.evaluate(({ BrowserWindow }) => {
    return BrowserWindow.getAllWindows().length;
  });

  await page.evaluate(() => {
    (window as unknown as { __ctrlPSeen: number }).__ctrlPSeen = 0;
    window.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'p') {
        (window as unknown as { __ctrlPSeen: number }).__ctrlPSeen++;
      }
    });
  });

  await electronApp.evaluate(({ BrowserWindow }) => {
    const mainWindow = BrowserWindow.getAllWindows()[0];
    if (!mainWindow) throw new Error('A fő Electron-ablak nem érhető el a Ctrl+P teszthez.');
    mainWindow.webContents.sendInputEvent({
      type: 'keyDown',
      keyCode: 'P',
      modifiers: ['control'],
    });
    mainWindow.webContents.sendInputEvent({
      type: 'keyUp',
      keyCode: 'P',
      modifiers: ['control'],
    });
  });
  await page.waitForTimeout(1000);

  const seen = await page.evaluate(
    () => (window as unknown as { __ctrlPSeen: number }).__ctrlPSeen,
  );
  expect(seen).toBe(0); // preventDefault → a page-keydown SEM érkezik meg

  const windowsAfter = await electronApp.evaluate(({ BrowserWindow }) => {
    return BrowserWindow.getAllWindows().length;
  });
  expect(windowsAfter).toBe(windowsBefore); // nem nyílt print/save ablak
});

test('production módban az application menu null (default accelerator-ok tiltva)', async () => {
  const menuIsNull = await electronApp.evaluate(({ Menu }) => {
    return Menu.getApplicationMenu() === null;
  });
  expect(menuIsNull).toBe(true);
});
