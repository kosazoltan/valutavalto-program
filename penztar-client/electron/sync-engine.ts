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
  getDb,
  saveDatabase,
  getPendingDistributions,
  markDistributionSynced,
  getPendingTransfers,
  markTransferSynced,
  getPendingCollections,
  markCollectionSynced,
  saveCachedBranchStatus,
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
  officialRate?: number | null;
  limit1Amount?: number | null;
  limit1BuyRate?: number | null;
  limit1SellRate?: number | null;
  limit2Amount?: number | null;
  limit2BuyRate?: number | null;
  limit2SellRate?: number | null;
  limit3Amount?: number | null;
  limit3BuyRate?: number | null;
  limit3SellRate?: number | null;
}

interface CircularResponse {
  id: number;
  subject: string;
  body: string;
  sender: string;
  sentAt: string;
}

interface BranchStatusResponse {
  code: string;
  name: string;
  companyId: number;
  lastSyncAt: string | null;
  onlineStatus: string;
  totalHufValue: number;
  dailyTurnover: number;
  cashBalances: unknown[];
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
        // 3. Értéktár szinkronizáció
        await this.syncDistributions();
        await this.syncTransfers();
        await this.syncCollections();
        await this.cacheBranchStatus();
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
   *
   * Legacy: ArfolyamBeolvasas — FTP szerveren lévő NR*.DAT fájl letöltése
   * és a helyi ARFOLYAM tábla frissítése.
   * Új rendszer: REST API-n keresztül kéri le az aktuális árfolyamokat.
   */
  async syncRates(): Promise<void> {
    try {
      const serverUrl = this.getServerUrl();
      const token = this.getAuthToken();

      const rates = await httpGet<RateResponse[]>(
        `${serverUrl}/exchange-rates/pos-current`,
        token,
      );

      const db = getDb();
      if (!db || !Array.isArray(rates)) return;

      for (const rate of rates) {
        db.run(
          `INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at,
             official_rate, limit1_amount, limit1_buy_rate, limit1_sell_rate,
             limit2_amount, limit2_buy_rate, limit2_sell_rate,
             limit3_amount, limit3_buy_rate, limit3_sell_rate)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(currency_code) DO UPDATE SET
             buy_rate = excluded.buy_rate,
             sell_rate = excluded.sell_rate,
             unit = excluded.unit,
             updated_at = excluded.updated_at,
             official_rate = excluded.official_rate,
             limit1_amount = excluded.limit1_amount,
             limit1_buy_rate = excluded.limit1_buy_rate,
             limit1_sell_rate = excluded.limit1_sell_rate,
             limit2_amount = excluded.limit2_amount,
             limit2_buy_rate = excluded.limit2_buy_rate,
             limit2_sell_rate = excluded.limit2_sell_rate,
             limit3_amount = excluded.limit3_amount,
             limit3_buy_rate = excluded.limit3_buy_rate,
             limit3_sell_rate = excluded.limit3_sell_rate`,
          [
            rate.currencyCode, rate.buyRate, rate.sellRate, rate.unit, rate.updatedAt,
            rate.officialRate ?? null, rate.limit1Amount ?? null, rate.limit1BuyRate ?? null,
            rate.limit1SellRate ?? null, rate.limit2Amount ?? null, rate.limit2BuyRate ?? null,
            rate.limit2SellRate ?? null, rate.limit3Amount ?? null, rate.limit3BuyRate ?? null,
            rate.limit3SellRate ?? null,
          ],
        );
      }

      saveDatabase();
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
        saveDatabase();
        console.log(`[SyncEngine] ${circulars.length} körlevél szinkronizálva`);
      }
    } catch (err) {
      console.warn('[SyncEngine] Körlevél sync hiba:', err instanceof Error ? err.message : err);
    }
  }

  /**
   * Értéktár: Pending distributions szinkronizálása.
   */
  async syncDistributions(): Promise<void> {
    try {
      const pending = getPendingDistributions();
      if (pending.length === 0) return;

      const serverUrl = this.getServerUrl();
      const token = this.getAuthToken();
      if (!token) return;

      for (const dist of pending) {
        try {
          const body: Record<string, unknown> = {
            targetBranchCode: dist.target_branch_code,
            currencyCode: dist.currency_code,
            amount: dist.amount,
          };
          if (dist.denominations) {
            try { body['denominations'] = JSON.parse(dist.denominations); } catch { /* skip */ }
          }
          if (dist.note) body['note'] = dist.note;

          await httpPost(`${serverUrl}/ertektar/distribution`, body, token);
          markDistributionSynced(dist.id);
        } catch (err) {
          console.warn(`[SyncEngine] Distribution #${dist.id} sync hiba:`, err instanceof Error ? err.message : err);
          break; // Hálózati hiba → kilépés
        }
      }
    } catch (err) {
      console.warn('[SyncEngine] Distribution sync hiba:', err instanceof Error ? err.message : err);
    }
  }

  /**
   * Értéktár: Pending transfers szinkronizálása.
   */
  async syncTransfers(): Promise<void> {
    try {
      const pending = getPendingTransfers();
      if (pending.length === 0) return;

      const serverUrl = this.getServerUrl();
      const token = this.getAuthToken();
      if (!token) return;

      for (const tx of pending) {
        try {
          const body: Record<string, unknown> = {
            targetBranchCode: tx.target_branch_code,
            currencyCode: tx.currency_code,
            amount: tx.amount,
          };
          if (tx.denominations) {
            try { body['denominations'] = JSON.parse(tx.denominations); } catch { /* skip */ }
          }
          if (tx.note) body['note'] = tx.note;

          await httpPost(`${serverUrl}/transfers`, body, token);
          markTransferSynced(tx.id);
        } catch (err) {
          console.warn(`[SyncEngine] Transfer #${tx.id} sync hiba:`, err instanceof Error ? err.message : err);
          break;
        }
      }
    } catch (err) {
      console.warn('[SyncEngine] Transfer sync hiba:', err instanceof Error ? err.message : err);
    }
  }

  /**
   * Értéktár: Pending collections szinkronizálása.
   */
  async syncCollections(): Promise<void> {
    try {
      const pending = getPendingCollections();
      if (pending.length === 0) return;

      const serverUrl = this.getServerUrl();
      const token = this.getAuthToken();
      if (!token) return;

      for (const col of pending) {
        try {
          const body: Record<string, unknown> = {
            sourceBranchCode: col.source_branch_code,
            currencyCode: col.currency_code,
            amount: col.amount,
          };
          if (col.note) body['note'] = col.note;

          await httpPost(`${serverUrl}/ertektar/collections`, body, token);
          markCollectionSynced(col.id);
        } catch (err) {
          console.warn(`[SyncEngine] Collection #${col.id} sync hiba:`, err instanceof Error ? err.message : err);
          break;
        }
      }
    } catch (err) {
      console.warn('[SyncEngine] Collection sync hiba:', err instanceof Error ? err.message : err);
    }
  }

  /**
   * Értéktár: Pénztár státuszok cache-elése.
   */
  async cacheBranchStatus(): Promise<void> {
    try {
      const serverUrl = this.getServerUrl();
      const token = this.getAuthToken();

      const branches = await httpGet<BranchStatusResponse[]>(
        `${serverUrl}/ertektar/branches/status`,
        token,
      );

      if (!Array.isArray(branches)) return;

      for (const branch of branches) {
        saveCachedBranchStatus(
          branch.code,
          branch.name,
          branch.companyId,
          branch.lastSyncAt,
          branch.onlineStatus,
          branch.totalHufValue,
          branch.dailyTurnover,
          branch.cashBalances ? JSON.stringify(branch.cashBalances) : null,
        );
      }

      if (branches.length > 0) {
        console.log(`[SyncEngine] ${branches.length} pénztár státusz cache-elve`);
      }
    } catch (err) {
      console.warn('[SyncEngine] Branch status cache hiba:', err instanceof Error ? err.message : err);
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
