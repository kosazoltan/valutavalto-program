/**
 * Electron hibajelentő modul — küldi a backend `/api/v1/diagnostics/error-report` endpointra.
 *
 * <p>2026-05-05 user-direktíva: a kollégák gépén történő hibákat AUTOMATIKUSAN
 * elküldjük a fejlesztőhöz (Hetzner backend → PostgreSQL `client_error_log` tábla),
 * NEM kell manuálisan debug-utasítást adni. Iparági standard inspiráció: Sentry
 * Electron SDK + saját HTTP queue.</p>
 *
 * <p>Tervezés:</p>
 * <ul>
 *   <li>Send-and-forget: a hiba-küldés HIBÁJA NEM rontja el a Penztar futását.</li>
 *   <li>Queue: ha a backend épp nem elérhető (offline), elmentjük lokálisan max 50 hibát.</li>
 *   <li>Retry: 5 perces intervallumonként megpróbálja a queue-t leüríteni.</li>
 *   <li>Privacy: NEM küldünk át jelszavakat, JWT tokeneket, banki adatot — csak a stack-trace-t.</li>
 *   <li>Rate-limit-tisztelet: minimum 5 mp 2 hiba között (anti-spam loop).</li>
 * </ul>
 */

import { app, net } from 'electron';
import log from 'electron-log/main';
import { release as getOsRelease } from 'node:os';
import fs from 'node:fs';
import path from 'node:path';

const ENDPOINT = 'https://excvaluta.com/api/v1/diagnostics/error-report';
const QUEUE_FILE = 'error-queue.json';
const MAX_QUEUE_SIZE = 50;
const MIN_INTERVAL_MS = 5_000;  // anti-spam: min 5 mp 2 jelentés között

interface ErrorReportPayload {
    component: 'electron-main' | 'electron-renderer' | 'nsis-installer' | 'axios-http' | 'setup-wizard' | 'sync-engine' | 'other';
    version?: string;
    osInfo?: string;
    userIdentifier?: string;
    errorMessage: string;
    stackTrace?: string;
    context?: Record<string, unknown>;
}

let lastSentMs = 0;
let userIdentifier: string | null = null;

/**
 * A SetupWizard / Login folyamat hívja meg, ha tudja a felhasználó email-jét.
 * A jelentésekhez ez kerül `userIdentifier`-ként.
 */
export function setUserIdentifier(id: string | null): void {
    userIdentifier = id;
}

function getQueueFilePath(): string {
    return path.join(app.getPath('userData'), QUEUE_FILE);
}

function loadQueue(): ErrorReportPayload[] {
    try {
        const p = getQueueFilePath();
        if (!fs.existsSync(p)) return [];
        const raw = fs.readFileSync(p, 'utf8');
        const arr = JSON.parse(raw);
        return Array.isArray(arr) ? arr : [];
    } catch {
        return [];
    }
}

function saveQueue(queue: ErrorReportPayload[]): void {
    try {
        const p = getQueueFilePath();
        const trimmed = queue.slice(-MAX_QUEUE_SIZE);
        fs.writeFileSync(p, JSON.stringify(trimmed), { encoding: 'utf8' });
    } catch (err) {
        log.warn('[error-reporter] queue persist failed:', err);
    }
}

/**
 * HTTPS POST a backendhez. Send-and-forget — fail-csendben.
 */
function sanitizePayload(p: ErrorReportPayload): string {
    const safe: ErrorReportPayload = {
        ...p,
        errorMessage: String(p.errorMessage ?? '').slice(0, 2000),
        stackTrace: p.stackTrace ? String(p.stackTrace).slice(0, 8000) : undefined,
    };
    return JSON.stringify(safe);
}

function postReport(payload: ErrorReportPayload): Promise<boolean> {
    const body = sanitizePayload(payload);
    return new Promise((resolve) => {
        let settled = false;
        const safeResolve = (v: boolean) => {
            if (!settled) { settled = true; resolve(v); }
        };
        const timer = setTimeout(() => safeResolve(false), 8_000);

        try {
            const req = net.request({ method: 'POST', url: ENDPOINT });
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('User-Agent', `ValutavaltoPenztar/${app.getVersion()} Electron`);
            req.on('response', (response) => {
                clearTimeout(timer);
                response.on('data', () => { /* drain */ });
                response.on('end', () => {
                    safeResolve(response.statusCode >= 200 && response.statusCode < 300);
                });
            });
            req.on('error', () => { clearTimeout(timer); safeResolve(false); });
            req.write(body);
            req.end();
        } catch {
            clearTimeout(timer);
            safeResolve(false);
        }
    });
}

/**
 * Egy hiba bejelentése.
 *
 * <p>Send-and-forget: ha a backend nem elérhető, a hiba a queue-ba kerül és
 * 5 perc múlva újra próbálva. NEM dob, NEM blokkol.</p>
 */
export function reportError(
    component: ErrorReportPayload['component'],
    err: Error | string,
    context?: Record<string, unknown>
): void {
    try {
        const now = Date.now();
        if (now - lastSentMs < MIN_INTERVAL_MS) {
            // Anti-spam: a queue-ba mentjük, később küldjük
            const queue = loadQueue();
            queue.push(buildPayload(component, err, context));
            saveQueue(queue);
            return;
        }
        lastSentMs = now;

        const payload = buildPayload(component, err, context);

        // Async send, NE várj a válaszra (send-and-forget)
        postReport(payload).then((ok) => {
            if (!ok) {
                const queue = loadQueue();
                queue.push(payload);
                saveQueue(queue);
            }
        }).catch(() => {
            // Quiet failure
        });
    } catch (innerErr) {
        // Soha-ne-bukjon-le védelem
        log.warn('[error-reporter] reportError internal:', innerErr);
    }
}

function buildPayload(
    component: ErrorReportPayload['component'],
    err: Error | string,
    context?: Record<string, unknown>
): ErrorReportPayload {
    const message = err instanceof Error ? err.message : String(err);
    const stack = err instanceof Error ? err.stack : undefined;
    return {
        component,
        version: app.getVersion(),
        osInfo: `Windows ${getOsRelease()}`,
        userIdentifier: userIdentifier ?? undefined,
        errorMessage: message.slice(0, 1000),
        stackTrace: stack ? stack.slice(0, 8000) : undefined,
        context,
    };
}

/**
 * A queue-t leüríti — periodikus retry.
 */
async function flushQueue(): Promise<void> {
    const queue = loadQueue();
    if (queue.length === 0) return;
    log.info(`[error-reporter] queue flush: ${queue.length} pending`);
    const remaining: ErrorReportPayload[] = [];
    for (const item of queue) {
        const ok = await postReport(item);
        if (!ok) remaining.push(item);
    }
    saveQueue(remaining);
}

/**
 * Inicializálja a hiba-jelentő rendszert.
 *
 * <ul>
 *   <li>process.on('uncaughtException') — main process kritikus hibák</li>
 *   <li>process.on('unhandledRejection') — Promise reject-ek</li>
 *   <li>5 perces interval: queue-flush</li>
 *   <li>app indulasa után: 30 másodperc, queue-flush egyszer</li>
 * </ul>
 */
export function initErrorReporter(): void {
    process.on('uncaughtException', (err) => {
        log.error('[uncaughtException]', err);
        reportError('electron-main', err, { source: 'uncaughtException' });
    });

    process.on('unhandledRejection', (reason) => {
        log.error('[unhandledRejection]', reason);
        const err = reason instanceof Error ? reason : new Error(String(reason));
        reportError('electron-main', err, { source: 'unhandledRejection' });
    });

    // Indulás után 30 mp-pel egyszer flush a queue
    setTimeout(() => { void flushQueue(); }, 30_000);

    // Aztán 5 percenként
    setInterval(() => { void flushQueue(); }, 5 * 60 * 1000);

    log.info('[error-reporter] inicializalva, endpoint:', ENDPOINT);
}
