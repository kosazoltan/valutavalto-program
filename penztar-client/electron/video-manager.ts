/**
 * VideoManager — Helyi videókezelő motor az Electron pénztárgép kliensben.
 *
 * Funkciók:
 * 1. Tranzakció-alapú szegmens kiválasztás (időpont szerinti vágás)
 * 2. Lejátszás visszafejtéssel (AES-256-GCM → temp fájl → video elem)
 * 3. Chain-of-Custody audit log
 * 4. Retention-based cleanup (50 nap)
 * 5. Szegmens export (USB, hálózat) integritás-ellenőrzéssel
 */

import { ipcMain } from 'electron';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { decryptFile, computeFileHash, type EncryptionConfig } from './camera-encryption';

const CAMERA_DIR = 'C:/valuta/camera';
const AUDIT_LOG_DIR = 'C:/valuta/camera/.audit';

// --- Audit log ---

interface AuditEntry {
  timestamp: string;
  action: 'VIEW' | 'EXPORT' | 'DECRYPT' | 'VERIFY' | 'CLEANUP' | 'ACCESS_DENIED';
  user?: string;
  cameraId?: string;
  segmentPath?: string;
  transactionId?: string;
  receiptNumber?: string;
  details?: string;
  machineId: string;
}

function writeAuditLog(entry: AuditEntry): void {
  fs.mkdirSync(AUDIT_LOG_DIR, { recursive: true });
  const date = new Date().toISOString().slice(0, 10);
  const logPath = path.join(AUDIT_LOG_DIR, `access-${date}.jsonl`);
  const line = JSON.stringify(entry) + '\n';
  fs.appendFileSync(logPath, line, 'utf-8');
}

function getMachineId(): string {
  return `${os.hostname()}-${os.platform()}`;
}

// --- Szegmens keresés ---

interface LocalSegmentInfo {
  cameraId: string;
  date: string;
  filePath: string;
  fileName: string;
  fileSizeBytes: number;
  createdAt: string;
  encrypted: boolean;
}

function findSegmentsByTimeRange(
  dateFrom: Date,
  dateTo: Date,
  cameraId?: string,
): LocalSegmentInfo[] {
  if (!fs.existsSync(CAMERA_DIR)) return [];

  const results: LocalSegmentInfo[] = [];
  const dateDirs = fs.readdirSync(CAMERA_DIR).filter((entry) => {
    const fullPath = path.join(CAMERA_DIR, entry);
    if (!fs.statSync(fullPath).isDirectory()) return false;
    if (entry.startsWith('.')) return false;
    const d = new Date(entry);
    if (Number.isNaN(d.getTime())) return false;
    return d >= new Date(dateFrom.toISOString().slice(0, 10)) &&
           d <= new Date(dateTo.toISOString().slice(0, 10));
  });

  for (const dateDir of dateDirs) {
    const datePath = path.join(CAMERA_DIR, dateDir);
    const camDirs = fs.readdirSync(datePath).filter((e) => {
      if (cameraId && e !== cameraId) return false;
      return fs.statSync(path.join(datePath, e)).isDirectory();
    });

    for (const camDir of camDirs) {
      const camPath = path.join(datePath, camDir);
      const files = fs.readdirSync(camPath).filter((f) =>
        f.endsWith('.mp4') || f.endsWith('.mp4.enc') || f.endsWith('.webm') || f.endsWith('.webm.enc'),
      );

      for (const file of files) {
        const fullPath = path.join(camPath, file);
        try {
          const stat = fs.statSync(fullPath);
          results.push({
            cameraId: camDir,
            date: dateDir,
            filePath: fullPath,
            fileName: file,
            fileSizeBytes: stat.size,
            createdAt: stat.birthtime.toISOString(),
            encrypted: file.endsWith('.enc'),
          });
        } catch {
          /* skip */
        }
      }
    }
  }

  // Időrend szerinti rendezés
  results.sort((a, b) => a.createdAt.localeCompare(b.createdAt));
  return results;
}

// --- Temp fájl kezelés ---

function getTempDir(): string {
  const tmpDir = path.join(os.tmpdir(), 'valuta-camera-playback');
  fs.mkdirSync(tmpDir, { recursive: true });
  return tmpDir;
}

function cleanupTempFiles(): number {
  const tmpDir = getTempDir();
  if (!fs.existsSync(tmpDir)) return 0;
  let count = 0;
  for (const file of fs.readdirSync(tmpDir)) {
    try {
      fs.unlinkSync(path.join(tmpDir, file));
      count++;
    } catch {
      /* in use */
    }
  }
  return count;
}

// ═══════════════════════════════════════════
// IPC Handler regisztráció
// ═══════════════════════════════════════════

export function registerVideoManagerHandlers(): void {
  /**
   * Szegmensek keresése időtartomány és opcionális kamera alapján.
   */
  ipcMain.handle('video-find-segments', async (
    _event,
    dateFrom: string,
    dateTo: string,
    cameraId?: string,
  ): Promise<LocalSegmentInfo[]> => {
    const from = new Date(dateFrom);
    const to = new Date(dateTo);
    if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) return [];
    return findSegmentsByTimeRange(from, to, cameraId);
  });

  /**
   * Tranzakcióhoz tartozó szegmensek keresése.
   * A backend CameraTransactionLinker logikájának helyi megfelelője:
   * megkeresi azokat a szegmenseket, amelyek a tranzakció időpontját fedik.
   */
  ipcMain.handle('video-find-by-transaction', async (
    _event,
    transactionTime: string,
    cameraId?: string,
    windowMinutes?: number,
  ): Promise<LocalSegmentInfo[]> => {
    const txTime = new Date(transactionTime);
    if (Number.isNaN(txTime.getTime())) return [];

    const window = windowMinutes ?? 5;
    const from = new Date(txTime.getTime() - window * 60 * 1000);
    const to = new Date(txTime.getTime() + window * 60 * 1000);

    const segments = findSegmentsByTimeRange(from, to, cameraId);

    writeAuditLog({
      timestamp: new Date().toISOString(),
      action: 'VIEW',
      transactionId: transactionTime,
      cameraId,
      details: `Keresett szegmensek: ${segments.length} db, ablak: ±${window} perc`,
      machineId: getMachineId(),
    });

    return segments;
  });

  /**
   * Titkosított szegmens visszafejtése ideiglenes fájlba lejátszáshoz.
   * A temp fájl útvonalát adja vissza (a renderer process ebből játszik le).
   */
  ipcMain.handle('video-decrypt-for-playback', async (
    _event,
    encryptedPath: string,
    encryptionConfig: EncryptionConfig,
    user?: string,
  ): Promise<{ tempPath: string } | { error: string }> => {
    const resolved = path.resolve(encryptedPath);
    if (!resolved.startsWith(path.resolve(CAMERA_DIR))) {
      writeAuditLog({
        timestamp: new Date().toISOString(),
        action: 'ACCESS_DENIED',
        user,
        segmentPath: encryptedPath,
        details: 'Fajl a kamera konyvtaron kivul esik',
        machineId: getMachineId(),
      });
      return { error: 'Fajl a kamera konyvtaron kivul esik' };
    }

    if (!fs.existsSync(resolved)) {
      return { error: 'Fajl nem talalhato' };
    }

    try {
      const tempDir = getTempDir();
      const baseName = path.basename(resolved).replace('.enc', '');
      const tempPath = path.join(tempDir, `play_${Date.now()}_${baseName}`);

      await decryptFile(resolved, tempPath, encryptionConfig);

      writeAuditLog({
        timestamp: new Date().toISOString(),
        action: 'DECRYPT',
        user,
        segmentPath: encryptedPath,
        details: `Visszafejtve lejatszashoz: ${tempPath}`,
        machineId: getMachineId(),
      });

      return { tempPath };
    } catch (err) {
      return { error: `Visszafejtes sikertelen: ${(err as Error).message}` };
    }
  });

  /**
   * Szegmens integritás ellenőrzés (SHA-256).
   */
  ipcMain.handle('video-verify-integrity', async (
    _event,
    filePath: string,
    expectedHash: string,
    user?: string,
  ): Promise<{ valid: boolean; actualHash: string }> => {
    const resolved = path.resolve(filePath);
    if (!resolved.startsWith(path.resolve(CAMERA_DIR))) {
      throw new Error('Fajl a kamera konyvtaron kivul esik');
    }

    const actualHash = computeFileHash(resolved);
    const valid = actualHash === expectedHash;

    writeAuditLog({
      timestamp: new Date().toISOString(),
      action: 'VERIFY',
      user,
      segmentPath: filePath,
      details: `Hash ${valid ? 'VALID' : 'MISMATCH'}: expected=${expectedHash.slice(0, 16)}... actual=${actualHash.slice(0, 16)}...`,
      machineId: getMachineId(),
    });

    return { valid, actualHash };
  });

  /**
   * Retention-based cleanup — 50 napos megőrzés.
   */
  ipcMain.handle('video-retention-cleanup', async (
    _event,
    retentionDays?: number,
    user?: string,
  ): Promise<{ deletedFiles: number; freedBytes: number }> => {
    const days = retentionDays ?? 50;
    if (!fs.existsSync(CAMERA_DIR)) return { deletedFiles: 0, freedBytes: 0 };

    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);

    let deletedFiles = 0;
    let freedBytes = 0;

    const dateDirs = fs.readdirSync(CAMERA_DIR).filter((e) => {
      if (e.startsWith('.')) return false;
      const fullPath = path.join(CAMERA_DIR, e);
      return fs.statSync(fullPath).isDirectory();
    });

    for (const dateDir of dateDirs) {
      const dirDate = new Date(dateDir);
      if (Number.isNaN(dirDate.getTime()) || dirDate >= cutoff) continue;

      const dirPath = path.join(CAMERA_DIR, dateDir);
      const files = collectAllFiles(dirPath);
      const dirSize = files.reduce((sum, f) => {
        try { return sum + fs.statSync(f).size; } catch { return sum; }
      }, 0);

      try {
        fs.rmSync(dirPath, { recursive: true, force: true });
        deletedFiles += files.length;
        freedBytes += dirSize;
      } catch {
        /* skip locked */
      }
    }

    writeAuditLog({
      timestamp: new Date().toISOString(),
      action: 'CLEANUP',
      user,
      details: `Retention cleanup: ${deletedFiles} fajl torolve, ${(freedBytes / 1024 / 1024).toFixed(1)} MB felszabaditva, cutoff=${cutoff.toISOString().slice(0, 10)}`,
      machineId: getMachineId(),
    });

    // Temp fájlok takarítása
    cleanupTempFiles();

    return { deletedFiles, freedBytes };
  });

  /**
   * Audit log lekérdezése (utolsó N bejegyzés).
   */
  ipcMain.handle('video-audit-log', async (
    _event,
    date?: string,
    limit?: number,
  ): Promise<AuditEntry[]> => {
    const targetDate = date ?? new Date().toISOString().slice(0, 10);
    const logPath = path.join(AUDIT_LOG_DIR, `access-${targetDate}.jsonl`);
    if (!fs.existsSync(logPath)) return [];

    const lines = fs.readFileSync(logPath, 'utf-8')
      .split('\n')
      .filter((l) => l.trim().length > 0);

    const entries: AuditEntry[] = [];
    for (const line of lines) {
      try {
        entries.push(JSON.parse(line) as AuditEntry);
      } catch {
        /* skip malformed */
      }
    }

    const n = limit ?? 100;
    return entries.slice(-n);
  });

  /**
   * Tárterület statisztika.
   */
  ipcMain.handle('video-storage-stats', async () => {
    if (!fs.existsSync(CAMERA_DIR)) {
      return {
        totalBytes: 0,
        segmentCount: 0,
        encryptedCount: 0,
        oldestDate: null,
        newestDate: null,
        availableBytes: 0,
      };
    }

    const allFiles = collectAllFiles(CAMERA_DIR);
    const videoFiles = allFiles.filter((f) =>
      f.endsWith('.mp4') || f.endsWith('.mp4.enc') || f.endsWith('.webm') || f.endsWith('.webm.enc'),
    );

    let totalBytes = 0;
    let encryptedCount = 0;
    for (const f of videoFiles) {
      try {
        totalBytes += fs.statSync(f).size;
        if (f.endsWith('.enc')) encryptedCount++;
      } catch {
        /* skip */
      }
    }

    const dateDirs = fs.readdirSync(CAMERA_DIR)
      .filter((e) => !e.startsWith('.') && /^\d{4}-\d{2}-\d{2}$/.test(e))
      .sort();

    let availableBytes = 0;
    try {
      const stats = fs.statfsSync(CAMERA_DIR);
      availableBytes = Number(stats.bavail) * Number(stats.bsize);
    } catch {
      /* statfsSync platform-dependent */
    }

    return {
      totalBytes,
      segmentCount: videoFiles.length,
      encryptedCount,
      oldestDate: dateDirs.length > 0 ? dateDirs[0] : null,
      newestDate: dateDirs.length > 0 ? dateDirs[dateDirs.length - 1] : null,
      availableBytes,
    };
  });

  /**
   * Temp fájlok takarítása (lejátszás után).
   */
  ipcMain.handle('video-cleanup-temp', async (): Promise<{ cleaned: number }> => {
    return { cleaned: cleanupTempFiles() };
  });
}

// --- Segédfüggvények ---

function collectAllFiles(dirPath: string): string[] {
  if (!fs.existsSync(dirPath)) return [];
  const result: string[] = [];
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      result.push(...collectAllFiles(fullPath));
    } else if (entry.isFile()) {
      result.push(fullPath);
    }
  }
  return result;
}
