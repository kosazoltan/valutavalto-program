import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '@/api/client';
import { toast } from '@/hooks/useToast';

// --- Típusok ---
interface AuditEntry {
  id: string;
  action: string;
  entityType: string;
  entityId: string | null;
  userId: string | null;
  userName: string | null;
  branchId: string | null;
  branchName: string | null;
  changes: string | null;
  oldValue: string | null;
  newValue: string | null;
  reason: string | null;
  ipAddress: string | null;
  userAgent: string | null;
  createdAt: string;
}

interface PageResponse {
  content: AuditEntry[];
  totalElements: number;
  totalPages: number;
  number: number;
}

// --- Szín kódolás akció szerint ---
const actionColors: Record<string, string> = {
  CREATE: 'bg-green-100 text-green-800 border-green-300',
  UPDATE: 'bg-blue-100 text-blue-800 border-blue-300',
  DELETE: 'bg-red-100 text-red-800 border-red-300',
  STORNO: 'bg-red-100 text-red-800 border-red-300',
  RATE_CHANGE: 'bg-yellow-100 text-yellow-800 border-yellow-300',
  LOGIN: 'bg-purple-100 text-purple-800 border-purple-300',
  LOGOUT: 'bg-gray-100 text-gray-800 border-gray-300',
  SECURITY: 'bg-orange-100 text-orange-800 border-orange-300',
};

function getActionColor(action: string): string {
  return actionColors[action] ?? 'bg-gray-100 text-gray-700 border-gray-300';
}

/**
 * AuditLogPage — Audit napló keresés, idővonal megjelenítés, CSV export.
 */
export default function AuditLogPage() {
  const navigate = useNavigate();

  // Szűrők
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [workerId, setWorkerId] = useState('');
  const [entityType, setEntityType] = useState('');
  const [action, setAction] = useState('');
  const [keyword, setKeyword] = useState('');

  // Eredmény
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [totalElements, setTotalElements] = useState(0);
  const [currentPage, setCurrentPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [isLoading, setIsLoading] = useState(false);

  // Részlet dialog
  const [selectedEntry, setSelectedEntry] = useState<AuditEntry | null>(null);

  const fetchResults = useCallback(
    async (page = 0) => {
      setIsLoading(true);
      try {
        const params: Record<string, string> = {
          page: String(page),
          size: '50',
        };
        if (dateFrom) params['dateFrom'] = new Date(dateFrom).toISOString();
        if (dateTo) params['dateTo'] = new Date(dateTo).toISOString();
        if (workerId) params['workerId'] = workerId;
        if (entityType) params['entityType'] = entityType;
        if (action) params['action'] = action;
        if (keyword) params['keyword'] = keyword;

        const res = await apiClient.get<PageResponse>('/audit/search', { params });
        setEntries(res.data.content);
        setTotalElements(res.data.totalElements);
        setTotalPages(res.data.totalPages);
        setCurrentPage(res.data.number);
      } catch (err: unknown) {
        console.error('[AuditLogPage] Keresési hiba:', err);
        toast.error('Hiba az audit napló lekérdezésekor');
      } finally {
        setIsLoading(false);
      }
    },
    [dateFrom, dateTo, workerId, entityType, action, keyword],
  );

  const handleSearch = () => {
    void fetchResults(0);
  };

  const handleExport = async () => {
    try {
      const params: Record<string, string> = {};
      if (dateFrom) params['dateFrom'] = new Date(dateFrom).toISOString();
      if (dateTo) params['dateTo'] = new Date(dateTo).toISOString();

      const res = await apiClient.get('/audit/export', {
        params,
        responseType: 'blob',
      });

      const url = URL.createObjectURL(new Blob([res.data as BlobPart]));
      const a = document.createElement('a');
      a.href = url;
      a.download = `audit_export_${new Date().toISOString().slice(0, 10)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
      toast.success('CSV exportálva');
    } catch (err: unknown) {
      console.error('[AuditLogPage] Export hiba:', err);
      toast.error('Hiba a CSV exportáláskor');
    }
  };

  const formatDate = (iso: string) => {
    try {
      const d = new Date(iso);
      return d.toLocaleString('hu-HU', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
      });
    } catch (err: unknown) {
      return iso;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h1 className="text-xl font-bold text-gray-800">📋 Audit Napló</h1>
        <button
          onClick={() => navigate('/menu')}
          className="px-3 py-1.5 bg-gray-200 rounded hover:bg-gray-300 text-sm"
        >
          ← Vissza
        </button>
      </div>

      {/* Szűrő panel */}
      <div className="bg-white rounded-lg shadow p-4 mb-4">
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          <div>
            <label className="block text-xs text-gray-500 mb-1">Dátumtól</label>
            <input
              type="datetime-local"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="w-full border rounded px-2 py-1.5 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Dátumig</label>
            <input
              type="datetime-local"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="w-full border rounded px-2 py-1.5 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Dolgozó ID</label>
            <input
              type="text"
              value={workerId}
              onChange={(e) => setWorkerId(e.target.value)}
              placeholder="pl. 12"
              className="w-full border rounded px-2 py-1.5 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Entitás típus</label>
            <select
              value={entityType}
              onChange={(e) => setEntityType(e.target.value)}
              className="w-full border rounded px-2 py-1.5 text-sm"
            >
              <option value="">Mind</option>
              <option value="TRANSACTION">Tranzakció</option>
              <option value="EXCHANGE_RATE">Árfolyam</option>
              <option value="WORKER">Dolgozó</option>
              <option value="SESSION">Session</option>
              <option value="SECURITY">Biztonság</option>
              <option value="BRANCH">Iroda</option>
            </select>
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Művelet</label>
            <select
              value={action}
              onChange={(e) => setAction(e.target.value)}
              className="w-full border rounded px-2 py-1.5 text-sm"
            >
              <option value="">Mind</option>
              <option value="CREATE">Létrehozás</option>
              <option value="UPDATE">Módosítás</option>
              <option value="DELETE">Törlés</option>
              <option value="STORNO">Stornó</option>
              <option value="RATE_CHANGE">Árfolyam változás</option>
              <option value="LOGIN">Bejelentkezés</option>
              <option value="LOGOUT">Kijelentkezés</option>
            </select>
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">Szabad szöveg</label>
            <input
              type="text"
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
              placeholder="Keresés..."
              className="w-full border rounded px-2 py-1.5 text-sm"
            />
          </div>
        </div>
        <div className="flex gap-2 mt-3">
          <button
            onClick={handleSearch}
            disabled={isLoading}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 text-sm disabled:opacity-50"
          >
            {isLoading ? '⏳ Keresés...' : '🔍 Keresés'}
          </button>
          <button
            onClick={() => void handleExport()}
            className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 text-sm"
          >
            📥 CSV Export
          </button>
        </div>
      </div>

      {/* Eredmény szám */}
      {totalElements > 0 && (
        <p className="text-sm text-gray-500 mb-2">
          Összesen {totalElements} bejegyzés | Oldal {currentPage + 1}/{totalPages}
        </p>
      )}

      {/* Idővonal stílusú lista */}
      <div className="space-y-2">
        {entries.map((entry) => (
          <div
            key={entry.id}
            className="bg-white rounded-lg shadow-sm border hover:shadow-md transition-shadow cursor-pointer"
            onClick={() => setSelectedEntry(entry)}
          >
            <div className="flex items-start p-3 gap-3">
              {/* Bal oldal: idő */}
              <div className="flex-shrink-0 w-36 text-xs text-gray-400 pt-0.5">
                {formatDate(entry.createdAt)}
              </div>

              {/* Közép: esemény */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span
                    className={`px-2 py-0.5 rounded text-xs font-medium border ${getActionColor(entry.action)}`}
                  >
                    {entry.action}
                  </span>
                  <span className="text-xs text-gray-500">{entry.entityType}</span>
                  {entry.entityId && (
                    <span className="text-xs text-gray-400 font-mono">{entry.entityId}</span>
                  )}
                </div>
                {entry.changes && (
                  <p className="text-sm text-gray-600 truncate">{entry.changes}</p>
                )}
              </div>

              {/* Jobb oldal: user info */}
              <div className="flex-shrink-0 text-right text-xs text-gray-400">
                {entry.userName && <p>{entry.userName}</p>}
                {entry.branchName && <p>{entry.branchName}</p>}
              </div>
            </div>
          </div>
        ))}

        {entries.length === 0 && !isLoading && (
          <div className="text-center text-gray-400 py-12">
            Nincs találat. Használd a szűrőket a kereséshez.
          </div>
        )}
      </div>

      {/* Lapozás */}
      {totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-4">
          <button
            disabled={currentPage === 0}
            onClick={() => void fetchResults(currentPage - 1)}
            className="px-3 py-1.5 bg-gray-200 rounded text-sm disabled:opacity-50 hover:bg-gray-300"
          >
            ← Előző
          </button>
          <span className="px-3 py-1.5 text-sm text-gray-600">
            {currentPage + 1} / {totalPages}
          </span>
          <button
            disabled={currentPage >= totalPages - 1}
            onClick={() => void fetchResults(currentPage + 1)}
            className="px-3 py-1.5 bg-gray-200 rounded text-sm disabled:opacity-50 hover:bg-gray-300"
          >
            Következő →
          </button>
        </div>
      )}

      {/* Részlet dialog */}
      {selectedEntry && (
        <div
          className="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
          onClick={() => setSelectedEntry(null)}
        >
          <div
            className="bg-white rounded-lg shadow-xl max-w-lg w-full mx-4 max-h-[80vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-4 border-b flex items-center justify-between">
              <h2 className="font-bold text-gray-800">Audit bejegyzés részletei</h2>
              <button
                onClick={() => setSelectedEntry(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>
            <div className="p-4 space-y-3 text-sm">
              <DetailRow label="ID" value={selectedEntry.id} />
              <DetailRow label="Művelet" value={selectedEntry.action} />
              <DetailRow label="Entitás típus" value={selectedEntry.entityType} />
              <DetailRow label="Entitás ID" value={selectedEntry.entityId} />
              <DetailRow label="Felhasználó" value={selectedEntry.userName} />
              <DetailRow label="Felhasználó ID" value={selectedEntry.userId} />
              <DetailRow label="Iroda" value={selectedEntry.branchName} />
              <DetailRow label="Iroda ID" value={selectedEntry.branchId} />
              <DetailRow label="Változások" value={selectedEntry.changes} />
              <DetailRow label="Régi érték" value={selectedEntry.oldValue} />
              <DetailRow label="Új érték" value={selectedEntry.newValue} />
              <DetailRow label="Indok" value={selectedEntry.reason} />
              <DetailRow label="IP cím" value={selectedEntry.ipAddress} />
              <DetailRow label="User Agent" value={selectedEntry.userAgent} />
              <DetailRow label="Időpont" value={formatDate(selectedEntry.createdAt)} />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function DetailRow({ label, value }: { label: string; value: string | null | undefined }) {
  if (!value) return null;
  return (
    <div>
      <span className="text-gray-400 text-xs block">{label}</span>
      <span className="text-gray-800 break-all">{value}</span>
    </div>
  );
}


