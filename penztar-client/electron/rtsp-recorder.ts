/**
 * RtspRecorder — IP kamera RTSP stream rögzítése ffmpeg-gel.
 *
 * Az Electron pénztárgép kliens helyi IP kamerákhoz csatlakozik RTSP-n.
 * Szegmensekre bont, titkosít, SHA-256 hash chain-be fűz.
 *
 * Két kameraszint (legacy kompatibilis):
 * - Public (pénztári kamera) — tranzakciókhoz kötött
 * - Private (intim kamera) — biztonsági, korlátozott hozzáférés
 */

import { spawn, ChildProcess } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { EventEmitter } from 'node:events';
import { encryptFile, computeFileHash, type EncryptionConfig } from './camera-encryption';

export interface RtspCameraConfig {
  id: string;
  name: string;
  rtspUrl: string;
  type: 'public' | 'private';
  fps: number;
  resolution: { width: number; height: number };
  segmentDurationSeconds: number;
  retentionDays: number;
}

export interface RecordingSegment {
  cameraId: string;
  segmentPath: string;
  startTime: Date;
  endTime?: Date;
  fileSizeBytes: number;
  sha256Hash?: string;
  encrypted: boolean;
  nonce?: string;
}

const DEFAULT_CAMERA_DIR = 'C:/valuta/camera';
const FFMPEG_PATH = 'ffmpeg'; // PATH-ban kell legyen, vagy teljes elérési út

export class RtspRecorder extends EventEmitter {
  private processes = new Map<string, ChildProcess>();
  private cameras = new Map<string, RtspCameraConfig>();
  private activeSegments = new Map<string, RecordingSegment>();
  private segmentTimers = new Map<string, NodeJS.Timeout>();
  private hashChain = new Map<string, string>(); // cameraId → utolsó hash
  private running = false;
  private encryptionConfig: EncryptionConfig;
  private storageRoot: string;

  constructor(
    storageRoot: string = DEFAULT_CAMERA_DIR,
    encryptionConfig: EncryptionConfig = { enabled: false, masterKeyBase64: '' },
  ) {
    super();
    this.storageRoot = storageRoot;
    this.encryptionConfig = encryptionConfig;
  }

  /**
   * Kamera regisztrálása.
   */
  addCamera(config: RtspCameraConfig): void {
    this.cameras.set(config.id, config);
  }

  /**
   * Összes regisztrált kamera indítása.
   */
  startAll(): void {
    if (this.running) return;
    this.running = true;
    for (const [id] of this.cameras) {
      this.startCamera(id);
    }
  }

  /**
   * Egy kamera rögzítésének indítása.
   */
  startCamera(cameraId: string): void {
    const config = this.cameras.get(cameraId);
    if (!config) throw new Error(`Ismeretlen kamera: ${cameraId}`);

    if (this.processes.has(cameraId)) {
      this.stopCamera(cameraId);
    }

    this.startNewSegment(config);
  }

  /**
   * Összes kamera leállítása.
   */
  stopAll(): void {
    this.running = false;
    for (const [id] of this.cameras) {
      this.stopCamera(id);
    }
  }

  /**
   * Egy kamera rögzítésének leállítása.
   */
  stopCamera(cameraId: string): void {
    const timer = this.segmentTimers.get(cameraId);
    if (timer) {
      clearTimeout(timer);
      this.segmentTimers.delete(cameraId);
    }

    const proc = this.processes.get(cameraId);
    if (proc && !proc.killed) {
      proc.kill('SIGINT'); // ffmpeg graceful stop
      this.processes.delete(cameraId);
    }

    // Szegmens véglegesítése
    const segment = this.activeSegments.get(cameraId);
    if (segment) {
      void this.finalizeSegment(cameraId, segment);
      this.activeSegments.delete(cameraId);
    }
  }

  /**
   * Aktív kamerák státusza.
   */
  getStatus(): Array<{
    cameraId: string;
    name: string;
    type: 'public' | 'private';
    recording: boolean;
    currentSegment?: RecordingSegment;
  }> {
    const result: Array<{
      cameraId: string;
      name: string;
      type: 'public' | 'private';
      recording: boolean;
      currentSegment?: RecordingSegment;
    }> = [];
    for (const [id, config] of this.cameras) {
      result.push({
        cameraId: id,
        name: config.name,
        type: config.type,
        recording: this.processes.has(id) && !this.processes.get(id)!.killed,
        currentSegment: this.activeSegments.get(id),
      });
    }
    return result;
  }

  /**
   * Új szegmens indítása ffmpeg-gel.
   */
  private startNewSegment(config: RtspCameraConfig): void {
    const now = new Date();
    const dateStr = now.toISOString().slice(0, 10);
    const timeStr = now.toISOString().slice(11, 19).replace(/:/g, '-');
    const dir = path.join(this.storageRoot, dateStr, config.id);
    fs.mkdirSync(dir, { recursive: true });

    const filename = `${config.id}_${timeStr}.mp4`;
    const segmentPath = path.join(dir, filename);

    const segment: RecordingSegment = {
      cameraId: config.id,
      segmentPath,
      startTime: now,
      fileSizeBytes: 0,
      encrypted: false,
    };

    // ffmpeg parancs: RTSP → MP4 szegmens
    const ffmpegArgs = [
      '-rtsp_transport', 'tcp',
      '-i', config.rtspUrl,
      '-c:v', 'copy',          // codec másolás (nem újrakódol)
      '-an',                    // audio nélkül (opcionális, kameránként)
      '-f', 'mp4',
      '-movflags', '+frag_keyframe+empty_moov+faststart',
      '-t', String(config.segmentDurationSeconds),
      '-y',                     // felülírás
      segmentPath,
    ];

    const proc = spawn(FFMPEG_PATH, ffmpegArgs, {
      stdio: ['pipe', 'pipe', 'pipe'],
      windowsHide: true,
    });

    this.processes.set(config.id, proc);
    this.activeSegments.set(config.id, segment);

    proc.on('error', (err) => {
      this.emit('segment-error', config.id, err);
      this.processes.delete(config.id);
      // Újracsatlakozási kísérlet 5 mp múlva
      if (this.running) {
        setTimeout(() => this.startNewSegment(config), 5000);
      }
    });

    proc.on('close', (code) => {
      if (code === 0 || code === 255) {
        // Sikeres lezárás (0) vagy SIGINT (255)
        void this.finalizeSegment(config.id, segment).then(() => {
          this.activeSegments.delete(config.id);
          // Következő szegmens indítása ha fut
          if (this.running && this.cameras.has(config.id)) {
            this.startNewSegment(config);
          }
        });
      } else {
        this.emit('segment-error', config.id, new Error(`ffmpeg kilépett: code=${code}`));
        this.activeSegments.delete(config.id);
        // Retry 5s
        if (this.running) {
          setTimeout(() => this.startNewSegment(config), 5000);
        }
      }
    });

    this.emit('segment-started', segment);
    this.emit('camera-connected', config.id);

    // Timeout biztonsági háló — ha ffmpeg nem áll le időben
    const timer = setTimeout(() => {
      if (proc && !proc.killed) {
        proc.kill('SIGINT');
      }
    }, (config.segmentDurationSeconds + 10) * 1000);
    this.segmentTimers.set(config.id, timer);
  }

  /**
   * Szegmens véglegesítése: titkosítás + hash chain.
   */
  private async finalizeSegment(cameraId: string, segment: RecordingSegment): Promise<void> {
    segment.endTime = new Date();

    if (!fs.existsSync(segment.segmentPath)) {
      this.emit('segment-error', cameraId, new Error('Szegmens fájl nem található'));
      return;
    }

    try {
      const stats = fs.statSync(segment.segmentPath);
      segment.fileSizeBytes = stats.size;

      // Skip empty segments
      if (segment.fileSizeBytes === 0) {
        fs.unlinkSync(segment.segmentPath);
        return;
      }

      // Titkosítás
      if (this.encryptionConfig.enabled) {
        const encPath = segment.segmentPath + '.enc';
        const nonce = await encryptFile(segment.segmentPath, encPath, this.encryptionConfig);
        fs.unlinkSync(segment.segmentPath); // Sima fájl törlése
        segment.segmentPath = encPath;
        segment.encrypted = true;
        segment.nonce = nonce;
        segment.fileSizeBytes = fs.statSync(encPath).size;
      }

      // Hash chain
      const fileHash = computeFileHash(segment.segmentPath);
      const prevHash = this.hashChain.get(cameraId) || '0'.repeat(64);
      const chainHash = computeChainHash(prevHash, fileHash);
      this.hashChain.set(cameraId, chainHash);
      segment.sha256Hash = fileHash;

      this.emit('segment-completed', segment);
    } catch (err) {
      this.emit('segment-error', cameraId, err instanceof Error ? err : new Error(String(err)));
    }
  }

  /**
   * Konfigurált kamerák számát adja.
   */
  get cameraCount(): number {
    return this.cameras.size;
  }

  /**
   * Fut-e a rögzítés?
   */
  get isRunning(): boolean {
    return this.running;
  }
}

/**
 * Hash chain: SHA-256(previousHash + currentFileHash).
 */
function computeChainHash(previousHash: string, currentFileHash: string): string {
  const crypto = require('node:crypto');
  return crypto.createHash('sha256').update(previousHash + currentFileHash).digest('hex');
}
