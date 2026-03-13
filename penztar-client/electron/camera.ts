import { ipcMain, dialog } from 'electron';
import fs from 'node:fs';
import path from 'node:path';

const CAMERA_DIR = 'C:/valuta/camera';

function sanitizeId(id: string): string {
  const clean = id.replace(/[^a-zA-Z0-9_-]/g, '');
  if (!clean || clean !== id) throw new Error('Invalid transactionId: ' + id);
  return clean;
}

function listDirectories(root: string): string[] {
  if (!fs.existsSync(root)) return [];
  return fs.readdirSync(root).filter((entry) => {
    const fullPath = path.join(root, entry);
    return fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory();
  });
}

function collectFiles(root: string): string[] {
  if (!fs.existsSync(root)) return [];
  const result: string[] = [];
  const entries = fs.readdirSync(root, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      result.push(...collectFiles(fullPath));
    } else if (entry.isFile()) {
      result.push(fullPath);
    }
  }
  return result;
}

function copyDirectoryWithCount(sourceDir: string, targetDir: string): number {
  if (!fs.existsSync(sourceDir)) return 0;
  fs.mkdirSync(targetDir, { recursive: true });
  let count = 0;
  const entries = fs.readdirSync(sourceDir, { withFileTypes: true });
  for (const entry of entries) {
    const src = path.join(sourceDir, entry.name);
    const dest = path.join(targetDir, entry.name);
    if (entry.isDirectory()) {
      count += copyDirectoryWithCount(src, dest);
    } else if (entry.isFile()) {
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.copyFileSync(src, dest);
      count += 1;
    }
  }
  return count;
}

ipcMain.handle('camera-save-recording', async (
  _event,
  transactionId: string,
  videoBuffer: ArrayBuffer,
  extension: string,
): Promise<string> => {
  const date = new Date().toISOString().slice(0, 10);
  const safeId = sanitizeId(transactionId);
  const dir = path.join(CAMERA_DIR, date, safeId);
  fs.mkdirSync(dir, { recursive: true });
  const filename = `recording_${Date.now()}.${extension}`;
  const filepath = path.join(dir, filename);
  fs.writeFileSync(filepath, Buffer.from(videoBuffer));
  return filepath;
});

ipcMain.handle('camera-export-to-usb', async (
  _event,
  dateFrom: string,
  dateTo: string,
): Promise<{ success: boolean; exported: number; error?: string }> => {
  const result = await dialog.showOpenDialog({
    title: 'Válaszd ki az USB meghajtót',
    properties: ['openDirectory'],
    buttonLabel: 'Exportálás ide',
  });

  if (result.canceled || !result.filePaths[0]) {
    return { success: false, exported: 0, error: 'Megszakítva' };
  }

  const from = new Date(dateFrom);
  const to = new Date(dateTo);
  if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
    return { success: false, exported: 0, error: 'Érvénytelen dátum' };
  }
  if (from > to) {
    return { success: false, exported: 0, error: 'A dátumtartomány hibás' };
  }

  try {
    const targetDir = path.join(result.filePaths[0], 'valuta_kamera_export');
    fs.mkdirSync(targetDir, { recursive: true });

    let exported = 0;
    const dateDirs = listDirectories(CAMERA_DIR);
    for (const dateDir of dateDirs) {
      const dateValue = new Date(dateDir);
      if (Number.isNaN(dateValue.getTime())) continue;
      if (dateValue < from || dateValue > to) continue;

      const sourceDir = path.join(CAMERA_DIR, dateDir);
      const destinationDir = path.join(targetDir, dateDir);
      exported += copyDirectoryWithCount(sourceDir, destinationDir);
    }

    return { success: true, exported };
  } catch (err) {
    return { success: false, exported: 0, error: `Írási hiba: ${(err as Error).message}` };
  }
});

ipcMain.handle('camera-list-recordings', async (
  _event,
  transactionId?: string,
): Promise<string[]> => {
  if (!fs.existsSync(CAMERA_DIR)) return [];

  if (transactionId) {
    const recordings: string[] = [];
    const safeId = sanitizeId(transactionId);
    const dateDirs = listDirectories(CAMERA_DIR);
    for (const dateDir of dateDirs) {
      const candidateDir = path.join(CAMERA_DIR, dateDir, safeId);
      recordings.push(...collectFiles(candidateDir));
    }
    return recordings;
  }

  return collectFiles(CAMERA_DIR);
});
