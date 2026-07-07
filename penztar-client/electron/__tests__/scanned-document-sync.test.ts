/**
 * FS-5 SLICE 3 — scanned-document-sync unit tests.
 *
 * Harness: mockolt sqlite modul + mockolt scanner modul + mockolt global.fetch,
 * a sync-engine.test.ts mintájára. A syncScannedDocuments() metódust közvetlenül
 * hívja — nincs runSync()/token-validation overheadd.
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock electron
vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => '/tmp/test-valuta'),
    getAppPath: vi.fn(() => '/tmp/test-valuta-app'),
    isPackaged: false,
  },
  safeStorage: {
    isEncryptionAvailable: vi.fn(() => false),
    encryptString: vi.fn(),
    decryptString: vi.fn(),
  },
}));

// Mock sqlite module — a sync-engine.test.ts mintájára
vi.mock('../sqlite', () => ({
  getConfig: vi.fn(),
  setConfig: vi.fn(),
  deleteConfig: vi.fn(),
  getDb: vi.fn(() => null),
  saveDatabase: vi.fn(),
  getPendingTransactions: vi.fn(() => []),
  getPendingConversions: vi.fn(() => []),
  getPendingBankTransactions: vi.fn(() => []),
  getPendingStornos: vi.fn(() => []),
  getPendingDistributions: vi.fn(() => []),
  getPendingTransfers: vi.fn(() => []),
  getPendingTransferStornos: vi.fn(() => []),
  getPendingCircularReplies: vi.fn(() => []),
  getPendingCollections: vi.fn(() => []),
  getPendingHandoverOperations: vi.fn(() => []),
  getPendingStocktakeItems: vi.fn(() => []),
  getReassertableTransactions: vi.fn(() => []),
  getReassertableConversions: vi.fn(() => []),
  getReassertableStornos: vi.fn(() => []),
  getReassertableBankTransactions: vi.fn(() => []),
  getPendingScannedDocuments: vi.fn(() => []),
  markTransactionSynced: vi.fn(),
  markTransactionSyncError: vi.fn(),
  markConversionSynced: vi.fn(),
  markBankTransactionSynced: vi.fn(),
  markStornoSynced: vi.fn(),
  markDistributionSynced: vi.fn(),
  markTransferSynced: vi.fn(),
  markTransferStornoSynced: vi.fn(),
  markCircularReplySynced: vi.fn(),
  markCollectionSynced: vi.fn(),
  markHandoverOperationSynced: vi.fn(),
  markStocktakeItemSynced: vi.fn(),
  markStocktakeItemError: vi.fn(),
  markScannedDocumentSynced: vi.fn(),
  markScannedDocumentSyncError: vi.fn(),
  saveCachedBranchStatus: vi.fn(),
  saveCachedCashDesk: vi.fn(),
  saveCachedWorker: vi.fn(),
}));

// Mock scanner module — readDecryptedScan + deleteScanFiles
vi.mock('../scanner', () => ({
  registerScannerHandlers: vi.fn(),
  readDecryptedScan: vi.fn(() => Buffer.from('fake-image-data')),
  deleteScanFiles: vi.fn(),
}));

import { SyncEngine } from '../sync-engine';
import {
  getConfig,
  getPendingScannedDocuments,
  markScannedDocumentSynced,
  markScannedDocumentSyncError,
} from '../sqlite';
import { readDecryptedScan, deleteScanFiles } from '../scanner';

const mockedGetConfig = vi.mocked(getConfig);
const mockedGetPendingScannedDocuments = vi.mocked(getPendingScannedDocuments);
const mockedMarkScannedDocumentSynced = vi.mocked(markScannedDocumentSynced);
const mockedMarkScannedDocumentSyncError = vi.mocked(markScannedDocumentSyncError);
const mockedReadDecryptedScan = vi.mocked(readDecryptedScan);
const mockedDeleteScanFiles = vi.mocked(deleteScanFiles);

const FRONT_PATH = 'C:/valuta/scan/2026-07-07/tx1/szemelyi_front_123.enc';
const BACK_PATH = 'C:/valuta/scan/2026-07-07/tx1/szemelyi_back_124.enc';

function makePendingDoc(
  overrides: Partial<{
    id: number;
    customer_id: number;
    document_type: string;
    front_path: string;
    back_path: string;
    notes: string | null;
    idempotency_key: string | null;
    company_code: string | null;
  }> = {},
) {
  return {
    id: 1,
    customer_id: 42,
    document_type: 'szemelyi',
    front_path: FRONT_PATH,
    back_path: BACK_PATH,
    notes: null,
    idempotency_key: 'idem-key-1',
    company_code: null,
    created_at: '2026-07-07 10:00:00',
    synced: 0,
    ...overrides,
  };
}

describe('SyncEngine.syncScannedDocuments', () => {
  let engine: SyncEngine;

  beforeEach(() => {
    vi.clearAllMocks();
    engine = new SyncEngine();
    mockedGetConfig.mockImplementation((key: string) => {
      if (key === 'server_url') return 'http://localhost:8080/api/v1';
      if (key === 'auth_token') return 'test-token-123';
      return null;
    });
  });

  afterEach(() => {
    engine.stop();
  });

  // T3.1 Case 1: pending + 200 → multipart POST, synced=1, files deleted (fail-closed ordering)
  it('uploads pending scan via multipart POST on HTTP 200, marks synced, then deletes files', async () => {
    mockedGetPendingScannedDocuments.mockReturnValue([makePendingDoc()]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    // Track call order for fail-closed invariant verification
    const callOrder: string[] = [];
    mockedMarkScannedDocumentSynced.mockImplementation(() => {
      callOrder.push('markSynced');
    });
    mockedDeleteScanFiles.mockImplementation(() => {
      callOrder.push('deleteFiles');
    });

    await engine.syncScannedDocuments();

    // 1 fetch call to /scanned-documents/upload-pair
    expect(mockFetch).toHaveBeenCalledTimes(1);
    const [url, options] = mockFetch.mock.calls[0]!;
    expect(url).toBe('http://localhost:8080/api/v1/scanned-documents/upload-pair');

    // Body is FormData with correct fields
    const formData = (options as RequestInit).body;
    expect(formData).toBeInstanceOf(FormData);
    const fd = formData as FormData;
    expect(fd.get('documentType')).toBe('ID_CARD');
    expect(fd.get('customerId')).toBe('42');
    expect(fd.get('front')).toBeInstanceOf(Blob);
    expect(fd.get('back')).toBeInstanceOf(Blob);

    // readDecryptedScan called for both front and back
    expect(mockedReadDecryptedScan).toHaveBeenCalledWith(FRONT_PATH);
    expect(mockedReadDecryptedScan).toHaveBeenCalledWith(BACK_PATH);

    // markScannedDocumentSynced called
    expect(mockedMarkScannedDocumentSynced).toHaveBeenCalledWith(1);

    // deleteScanFiles called for both front and back (4 files: .enc + .meta each)
    expect(mockedDeleteScanFiles).toHaveBeenCalledWith(FRONT_PATH);
    expect(mockedDeleteScanFiles).toHaveBeenCalledWith(BACK_PATH);
    expect(mockedDeleteScanFiles).toHaveBeenCalledTimes(2);

    // FAIL-CLOSED ordering: markSynced BEFORE deleteFiles
    expect(callOrder[0]).toBe('markSynced');
    expect(callOrder[1]).toBe('deleteFiles');
    expect(callOrder[2]).toBe('deleteFiles');

    // No sync error
    expect(mockedMarkScannedDocumentSyncError).not.toHaveBeenCalled();

    vi.unstubAllGlobals();
  });

  // T3.1 Case 2: 500 → synced=0, NO file deleted (fail-closed)
  it('keeps files and marks sync error on HTTP 500 (fail-closed, no data loss)', async () => {
    // Two pending items to verify loop breaks
    mockedGetPendingScannedDocuments.mockReturnValue([
      makePendingDoc({ id: 1 }),
      makePendingDoc({
        id: 2,
        front_path: 'C:/valuta/scan/2026-07-07/tx2/front.enc',
        back_path: 'C:/valuta/scan/2026-07-07/tx2/back.enc',
      }),
    ]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error',
    });
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncScannedDocuments();

    // Only 1 fetch call — loop breaks on 500
    expect(mockFetch).toHaveBeenCalledTimes(1);

    // markScannedDocumentSynced NOT called
    expect(mockedMarkScannedDocumentSynced).not.toHaveBeenCalled();

    // deleteScanFiles NOT called (fail-closed)
    expect(mockedDeleteScanFiles).not.toHaveBeenCalled();

    // markScannedDocumentSyncError called with the error
    expect(mockedMarkScannedDocumentSyncError).toHaveBeenCalledWith(
      1,
      expect.stringContaining('500'),
    );

    vi.unstubAllGlobals();
  });

  // T3.1 Case 3: network-error → same + loop breaks
  it('keeps files and breaks loop on network error (fail-closed)', async () => {
    mockedGetPendingScannedDocuments.mockReturnValue([
      makePendingDoc({ id: 1 }),
      makePendingDoc({
        id: 2,
        front_path: 'C:/valuta/scan/2026-07-07/tx2/front.enc',
        back_path: 'C:/valuta/scan/2026-07-07/tx2/back.enc',
      }),
    ]);

    const mockFetch = vi.fn().mockRejectedValue(new TypeError('fetch failed'));
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncScannedDocuments();

    // Only 1 fetch call — loop breaks on network error
    expect(mockFetch).toHaveBeenCalledTimes(1);

    // markScannedDocumentSynced NOT called
    expect(mockedMarkScannedDocumentSynced).not.toHaveBeenCalled();

    // deleteScanFiles NOT called (fail-closed)
    expect(mockedDeleteScanFiles).not.toHaveBeenCalled();

    // markScannedDocumentSyncError called
    expect(mockedMarkScannedDocumentSyncError).toHaveBeenCalledWith(
      1,
      expect.stringContaining('fetch'),
    );

    vi.unstubAllGlobals();
  });

  // T3.1 Case 4: doctype map szemelyi→ID_CARD, utlevel→PASSPORT, jogositvany→DRIVERS_LICENSE, egyeb→OTHER
  it('maps local document types to server enum correctly', async () => {
    mockedGetPendingScannedDocuments.mockReturnValue([
      makePendingDoc({
        id: 1,
        document_type: 'szemelyi',
        front_path: 'C:/valuta/scan/d1/f.enc',
        back_path: 'C:/valuta/scan/d1/b.enc',
      }),
      makePendingDoc({
        id: 2,
        document_type: 'utlevel',
        front_path: 'C:/valuta/scan/d2/f.enc',
        back_path: 'C:/valuta/scan/d2/b.enc',
      }),
      makePendingDoc({
        id: 3,
        document_type: 'jogositvany',
        front_path: 'C:/valuta/scan/d3/f.enc',
        back_path: 'C:/valuta/scan/d3/b.enc',
      }),
      makePendingDoc({
        id: 4,
        document_type: 'egyeb',
        front_path: 'C:/valuta/scan/d4/f.enc',
        back_path: 'C:/valuta/scan/d4/b.enc',
      }),
    ]);

    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ success: true }),
    });
    vi.stubGlobal('fetch', mockFetch);

    await engine.syncScannedDocuments();

    expect(mockFetch).toHaveBeenCalledTimes(4);

    const expectedMappings: Record<number, string> = {
      1: 'ID_CARD',
      2: 'PASSPORT',
      3: 'DRIVERS_LICENSE',
      4: 'OTHER',
    };

    for (let i = 0; i < 4; i++) {
      const [, options] = mockFetch.mock.calls[i]!;
      const fd = (options as RequestInit).body as FormData;
      const docId = i + 1;
      expect(fd.get('documentType')).toBe(expectedMappings[docId]);
    }

    // All 4 synced + files deleted
    expect(mockedMarkScannedDocumentSynced).toHaveBeenCalledTimes(4);
    expect(mockedDeleteScanFiles).toHaveBeenCalledTimes(8); // 4 docs × 2 (front+back)

    vi.unstubAllGlobals();
  });
});
