/**
 * SyncEngine — Offline → Online szinkronizáció.
 *
 * Feladatai:
 * 1. Pending tranzakciók szinkronizálása (30s intervallum)
 * 2. Árfolyamok letöltése és SQLite cache frissítése
 * 3. Körlevelek letöltése
 *
 * Életciklus:
 * - app.whenReady() → syncEngine.start()
 * - app.on('will-quit') → syncEngine.stop()
 */

import {
  getPendingTransactions,
  markTransactionSynced,
  getConfig,
  setConfig,
  getDb,
  type PendingTransactionRow,
} from './sqlite';

// --- Típusok ---

export interface SyncResult {
  synced: number;
  failed: number;
  errors: string[];
}

interface SyncStatus {
  lastSyncAt: string | null;
  lastSyncResult: SyncResult | null;
  isRunning: boolean;
}

interface RateResponse {
  currencyCode: string;
  buyRate: number;
  sellRate: number;
  unit: number;
  updatedAt: string;
}

interface CircularResponse {
  id: number;
  subject: string;
  body: string;
  sender: string;
  sentAt: string;
}

// --- HTTP kliens (lightweight, nincs axios az electron main-ben) ---

async function httpGet<T>(url: string, token: string | null): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    method: 'GET',
    headers,
    signal: AbortSignal.timeout(10_000),
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json() as Promise<T>;
}

async function httpPost<T>(url: string, body: Record<string, unknown>, token: string | null): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(15_000),
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json() as Promise<T>;
}

// --- SyncEngine ---

export class SyncEngine {
  private intervalId: ReturnType<typeof setInterval> | null = null;
  private status: SyncStatus = {
    lastSyncAt: null,
    lastSyncResult: null,
    isRunning: false,
  };

  private getServerUrl(): string {
    const stored = getConfig('server_url');
    return stored ?? 'http://localhost:8080/api/v1';
  }

  private getAuthToken(): string | null {
    return getConfig('auth_token');
  }

  /**
   * Szinkronizáció indítása — periodikus (alapértelmezetten 30s).
   */
  start(intervalMs: number = 30_000): void {
    if (this.intervalId) {
      console.log('[SyncEngine] Már fut, újraindítás...');
      this.stop();
    }

    console.log(`[SyncEngine] Indítás — ${intervalMs}ms intervallum`);

    // Első futtatás kis késéssel (5s) — várjuk meg az app inicializálását
    setTimeout(() => {
      void this.runSync();
    }, 5_000);

    this.intervalId = setInterval(() => {
      void this.runSync();
    }, intervalMs);
  }

  /**
   * Szinkronizáció leállítása.
   */
  stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
      console.log('[SyncEngine] Leállítva');
    }
  }

  /**
   * Teljes szinkronizálási ciklus futtatása.
   */
  private async runSync(): Promise<void> {
    if (this.status.isRunning) {
      console.log('[SyncEngine] Előző sync még fut, kihagyás');
      return;
    }

    this.status.isRunning = true;

    try {
      // 1. Tranzakciók szinkronizálása
      const result = await this.syncAll();
      this.status.lastSyncResult = result;

      if (result.synced > 0) {
        console.log(`[SyncEngine] ${result.synced} tranzakció szinkronizálva`);
      }
      if (result.failed > 0) {
        console.warn(`[SyncEngine] ${result.failed} tranzakció SIKERTELEN:`, result.errors);
      }

      // 2. Árfolyamok frissítése (csak ha van token)
      if (this.getAuthToken()) {
        await this.syncRates();
        await this.syncCirculars();
      }

      this.status.lastSyncAt = new Date().toISOString();
    } catch (err) {
      console.error('[SyncEngine] Sync hiba:', err);
    } finally {
      this.status.isRunning = false;
    }
  }

  /**
   * Pending tranzakciók szinkronizálása a szerverrel.
   */
  async syncAll(): Promise<SyncResult> {
    const result: SyncResult = { synced: 0, failed: 0, errors: [] };

    const pending = getPendingTransactions();
    if (pending.length === 0) {
      return result;
    }

    const serverUrl = this.getServerUrl();
    const token = this.getAuthToken();

    if (!token) {
      result.errors.push('Nincs auth token — bejelentkezés szükséges');
      result.failed = pending.length;
      return result;
    }

    for (const tx of pending) {
      try {
        await this.syncTransaction(serverUrl, token, tx);
        markTransactionSynced(tx.id);
        result.synced++;
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        result.failed++;
        result.errors.push(`TX #${tx.id} (${tx.type} ${tx.currency_code}): ${errorMsg}`);
        // Ha hálózati hiba, a többi se fog menni — megszakítjuk
        if (errorMsg.includes('fetch') || errorMsg.includes('network') || errorMsg.includes('timeout')) {
          result.errors.push('Hálózati hiba — további próbálkozások leállítva');
          result.failed += pending.length - result.synced - result.failed;
          break;
        }
      }
    }

    return result;
  }

  /**
   * Egyedi tranzakció szinkronizálása.
   */
  private async syncTransaction(
    serverUrl: string,
    token: string,
    tx: PendingTransactionRow,
  ): Promise<void> {
    const endpoint = tx.type === 'SELL'
      ? `${serverUrl}/transactions/sell`
      : `${serverUrl}/transactions/buy`;

    const body: Record<string, unknown> = {
      currencyCode: tx.currency_code,
      foreignAmount: tx.foreign_amount,
      hufAmount: tx.huf_amount,
      roundedHufAmount: tx.rounded_huf_amount,
      rate: tx.rate,
    };

    if (tx.customer_id !== null) {
      body['customerId'] = tx.customer_id;
    }

    if (tx.denominations !== null) {
      try {
        body['denominations'] = JSON.parse(tx.denominations);
      } catch {
        // Ha nem parsable, string-ként küldjük
        body['denominations'] = tx.denominations;
      }
    }

    await httpPost(endpoint, body, token);
  }

  /**
   * Árfolyamok letöltése és SQLite cache frissítése.
   */
  async syncRates(): Promise<void> {
    try {
      const serverUrl = this.getServerUrl();
      const token = this.getAuthToken();

      const rates = await httpGet<RateResponse[]>(
        `${serverUrl}/rates`,
        token,
      );

      const db = getDb();
      if (!db || !Array.isArray(rates)) return;

      for (const rate of rates) {
        db.run(
          `INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at)
           VALUES (?, ?, ?, ?, ?)
           ON CONFLICT(currency_code) DO UPDATE SET
             buy_rate = excluded.buy_rate,
             sell_rate = excluded.sell_rate,
             unit = excluded.unit,
             updated_at = excluded.updated_at`,
          [rate.currencyCode, rate.buyRate, rate.sellRate, rate.unit, rate.updatedAt],
        );
      }

      console.log(`[SyncEngine] ${rates.length} árfolyam frissítve`);
    } catch (err) {
      // Nem kritikus hiba — legközelebb újrapróbáljuk
      console.warn('[SyncEngine] Árfolyam sync hiba:', err instanceof Error ? err.message : err);
    }
  }

  /**
   * Körlevelek letöltése és SQLite-ba mentése.
   */
  async syncCirculars(): Promise<void> {
    try {
      const serverUrl = this.getServerUrl();
      const token = this.getAuthToken();

      const circulars = await httpGet<CircularResponse[]>(
        `${serverUrl}/circulars`,
        token,
      );

      const db = getDb();
      if (!db || !Array.isArray(circulars)) return;

      // Biztosítsuk, hogy a tábla létezik
      db.run(`
        CREATE TABLE IF NOT EXISTS cached_circulars (
          id INTEGER PRIMARY KEY,
          subject TEXT NOT NULL,
          body TEXT NOT NULL,
          sender TEXT NOT NULL,
          sent_at TEXT NOT NULL,
          acknowledged INTEGER DEFAULT 0,
          cached_at TEXT DEFAULT (datetime('now'))
        )
      `);

      for (const circular of circulars) {
        db.run(
          `INSERT INTO cached_circulars (id, subject, body, sender, sent_at)
           VALUES (?, ?, ?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET
             subject = excluded.subject,
             body = excluded.body,
             sender = excluded.sender,
             sent_at = excluded.sent_at`,
          [circular.id, circular.subject, circular.body, circular.sender, circular.sentAt],
        );
      }

      if (circulars.length > 0) {
        console.log(`[SyncEngine] ${circulars.length} körlevél szinkronizálva`);
      }
    } catch (err) {
      console.warn('[SyncEngine] Körlevél sync hiba:', err instanceof Error ? err.message : err);
    }
  }

  /**
   * Aktuális szinkronizáció státusz lekérdezése.
   */
  getStatus(): SyncStatus {
    return { ...this.status };
  }
}

/**
 * Globális SyncEngine példány — az electron main process-ben használjuk.
 */
export const syncEngine = new SyncEngine();
