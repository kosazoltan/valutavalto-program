import { ipcMain, dialog } from 'electron';
import fs from 'node:fs';
import path from 'node:path';
import { RtspRecorder, type RtspCameraConfig, type RecordingSegment } from './rtsp-recorder';
import { type EncryptionConfig, encryptFile, decryptFile, computeFileHash, generateNewKey } from './camera-encryption';

const CAMERA_DIR = 'C:/valuta/camera';

// --- RTSP Recorder singleton ---
let rtspRecorder: RtspRecorder | null = null;
const completedSegments: RecordingSegment[] = [];
const MAX_SEGMENT_HISTORY = 500;

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

function getDirSize(dirPath: string): number {
  if (!fs.existsSync(dirPath)) return 0;
  let size = 0;
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      size += getDirSize(fullPath);
    } else if (entry.isFile()) {
      try { size += fs.statSync(fullPath).size; } catch { /* skip */ }
    }
  }
  return size;
}

export function registerCameraHandlers(): void {
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

  ipcMain.handle('camera-local-storage-stats', async () => {
    if (!fs.existsSync(CAMERA_DIR)) {
      return { totalUsageBytes: 0, availableSpaceBytes: 0, totalRecordings: 0, oldestDate: null, newestDate: null };
    }

    const totalUsageBytes = getDirSize(CAMERA_DIR);
    const allFiles = collectFiles(CAMERA_DIR);
    const dateDirs = listDirectories(CAMERA_DIR).sort();

    let availableSpaceBytes = 0;
    try {
      const stats = fs.statfsSync(CAMERA_DIR);
      availableSpaceBytes = Number(stats.bavail) * Number(stats.bsize);
    } catch {
      // statfsSync nem minden platformon elérhető
    }

    return {
      totalUsageBytes,
      availableSpaceBytes,
      totalRecordings: allFiles.length,
      oldestDate: dateDirs.length > 0 ? dateDirs[0] : null,
      newestDate: dateDirs.length > 0 ? dateDirs[dateDirs.length - 1] : null,
    };
  });

  ipcMain.handle('camera-local-recordings-by-date', async (
    _event,
    dateFrom: string,
    dateTo: string,
  ) => {
    if (!fs.existsSync(CAMERA_DIR)) return [];

    const from = new Date(dateFrom);
    const to = new Date(dateTo);
    if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) return [];

    const results: Array<{
      date: string;
      transactionId: string;
      filePath: string;
      fileSizeBytes: number;
      createdAt: string;
    }> = [];

    const dateDirs = listDirectories(CAMERA_DIR);
    for (const dateDir of dateDirs) {
      const dirDate = new Date(dateDir);
      if (Number.isNaN(dirDate.getTime())) continue;
      if (dirDate < from || dirDate > to) continue;

      const txDirs = listDirectories(path.join(CAMERA_DIR, dateDir));
      for (const txDir of txDirs) {
        const files = collectFiles(path.join(CAMERA_DIR, dateDir, txDir));
        for (const filePath of files) {
          try {
            const stat = fs.statSync(filePath);
            results.push({
              date: dateDir,
              transactionId: txDir,
              filePath,
              fileSizeBytes: stat.size,
              createdAt: stat.birthtime.toISOString(),
            });
          } catch { /* skip */ }
        }
      }
    }

    return results;
  });

  ipcMain.handle('camera-local-read-file', async (
    _event,
    filePath: string,
  ): Promise<string | null> => {
    const resolved = path.resolve(filePath);
    if (!resolved.startsWith(path.resolve(CAMERA_DIR))) return null;
    if (!fs.existsSync(resolved)) return null;
    return fs.readFileSync(resolved).toString('base64');
  });

  ipcMain.handle('camera-local-cleanup', async (
    _event,
    retentionDays: number,
  ): Promise<{ deletedCount: number }> => {
    if (!fs.existsSync(CAMERA_DIR)) return { deletedCount: 0 };

    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - retentionDays);
    let deletedCount = 0;

    for (const dateDir of listDirectories(CAMERA_DIR)) {
      const dirDate = new Date(dateDir);
      if (Number.isNaN(dirDate.getTime()) || dirDate >= cutoff) continue;

      const dirPath = path.join(CAMERA_DIR, dateDir);
      const fileCount = collectFiles(dirPath).length;
      try {
        fs.rmSync(dirPath, { recursive: true, force: true });
        deletedCount += fileCount;
      } catch { /* skip */ }
    }

    return { deletedCount };
  });

  // ═══════════════════════════════════════════
  // RTSP IP kamera kezelés
  // ═══════════════════════════════════════════

  /**
   * RTSP kamerákat konfigurál és indítja a rögzítést.
   */
  ipcMain.handle('camera-rtsp-start', async (
    _event,
    cameras: RtspCameraConfig[],
    encryption?: { enabled: boolean; masterKeyBase64: string },
  ): Promise<{ started: number; errors: string[] }> => {
    const encConfig: EncryptionConfig = encryption ?? { enabled: false, masterKeyBase64: '' };

    if (rtspRecorder) {
      rtspRecorder.stopAll();
    }

    rtspRecorder = new RtspRecorder(CAMERA_DIR, encConfig);
    const errors: string[] = [];

    // Szegmens események kezelése
    rtspRecorder.on('segment-completed', (segment: RecordingSegment) => {
      completedSegments.push(segment);
      if (completedSegments.length > MAX_SEGMENT_HISTORY) {
        completedSegments.splice(0, completedSegments.length - MAX_SEGMENT_HISTORY);
      }
    });

    rtspRecorder.on('segment-error', (cameraId: string, error: Error) => {
      errors.push(`${cameraId}: ${error.message}`);
    });

    for (const cam of cameras) {
      try {
        rtspRecorder.addCamera(cam);
      } catch (err) {
        errors.push(`${cam.id}: ${(err as Error).message}`);
      }
    }

    rtspRecorder.startAll();
    return { started: rtspRecorder.cameraCount, errors };
  });

  /**
   * RTSP rögzítés leállítása.
   */
  ipcMain.handle('camera-rtsp-stop', async (): Promise<{ stopped: boolean }> => {
    if (rtspRecorder) {
      rtspRecorder.stopAll();
      rtspRecorder = null;
    }
    return { stopped: true };
  });

  /**
   * RTSP kamerák státusza.
   */
  ipcMain.handle('camera-rtsp-status', async () => {
    if (!rtspRecorder) {
      return { running: false, cameras: [] };
    }
    return {
      running: rtspRecorder.isRunning,
      cameras: rtspRecorder.getStatus(),
    };
  });

  /**
   * Befejezett szegmensek lekérdezése.
   */
  ipcMain.handle('camera-rtsp-segments', async (
    _event,
    limit?: number,
  ): Promise<RecordingSegment[]> => {
    const n = limit ?? 50;
    return completedSegments.slice(-n);
  });

  // ═══════════════════════════════════════════
  // Fájl titkosítás / visszafejtés IPC
  // ═══════════════════════════════════════════

  /**
   * Egyedi fájl titkosítása.
   */
  ipcMain.handle('camera-encrypt-file', async (
    _event,
    plainPath: string,
    encryptedPath: string,
    config: EncryptionConfig,
  ): Promise<{ nonce: string }> => {
    const resolved = path.resolve(plainPath);
    if (!resolved.startsWith(path.resolve(CAMERA_DIR))) {
      throw new Error('Fájl a kamera könyvtáron kívül esik');
    }
    const nonce = await encryptFile(resolved, path.resolve(encryptedPath), config);
    return { nonce };
  });

  /**
   * Titkosított fájl visszafejtése (lejátszáshoz, exporthoz).
   */
  ipcMain.handle('camera-decrypt-file', async (
    _event,
    encryptedPath: string,
    plainPath: string,
    config: EncryptionConfig,
  ): Promise<{ success: boolean }> => {
    const resolved = path.resolve(encryptedPath);
    if (!resolved.startsWith(path.resolve(CAMERA_DIR))) {
      throw new Error('Fájl a kamera könyvtáron kívül esik');
    }
    await decryptFile(resolved, path.resolve(plainPath), config);
    return { success: true };
  });

  /**
   * Fájl integritás ellenőrzés (SHA-256).
   */
  ipcMain.handle('camera-verify-hash', async (
    _event,
    filePath: string,
    expectedHash: string,
  ): Promise<{ valid: boolean; actualHash: string }> => {
    const resolved = path.resolve(filePath);
    if (!resolved.startsWith(path.resolve(CAMERA_DIR))) {
      throw new Error('Fájl a kamera könyvtáron kívül esik');
    }
    const actualHash = computeFileHash(resolved);
    return { valid: actualHash === expectedHash, actualHash };
  });

  /**
   * Új titkosítási kulcs generálása.
   */
  ipcMain.handle('camera-generate-key', async (): Promise<{ keyBase64: string }> => {
    return { keyBase64: generateNewKey() };
  });
}
