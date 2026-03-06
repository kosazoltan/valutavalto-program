import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import apiClient from '@/api/client';
import { toast } from '@/hooks/useToast';

// --- Típusok ---
interface BranchWithStats {
  id: string;
  code: string;
  name: string;
  city: string;
  companyName: string;
  active: boolean;
  workerCount: number;
  dailyTurnoverHuf: number;
  lastSyncAt: string | null;
  syncStatus: string;
}


export default function CompanyAdminPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();

  const [branches, setBranches] = useState<BranchWithStats[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  // Szerkesztő dialog
  const [editBranch, setEditBranch] = useState<BranchWithStats | null>(null);
  const [editName, setEditName] = useState('');
  const [editPhone, setEditPhone] = useState('');
  const [editEmail, setEditEmail] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const accentColor = isBestChange ? 'text-red-600' : 'text-orange-600';

  // Fiókok betöltése
  const loadBranches = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const response = await apiClient.get<BranchWithStats[]>('/admin/branches');
      setBranches(response.data);
    } catch (err) {
      setError('Nem sikerült betölteni a fiókokat');
      toast.error('Fiókok betöltése sikertelen');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadBranches();
  }, [loadBranches]);

  // Szerkesztés
  const handleEdit = (branch: BranchWithStats) => {
    setEditBranch(branch);
    setEditName(branch.name);
    setEditPhone('');
    setEditEmail('');
  };

  const handleSave = async () => {
    if (!editBranch) return;
    setIsSaving(true);
    try {
      await apiClient.put(`/admin/branches/${editBranch.id}`, {
        name: editName,
        phone: editPhone || undefined,
        email: editEmail || undefined,
      });
      toast.success('Fiók adatok mentve');
      setEditBranch(null);
      void loadBranches();
    } catch {
      toast.error('Mentés sikertelen');
    } finally {
      setIsSaving(false);
    }
  };

  const getSyncStatusBadge = (status: string) => {
    switch (status) {
      case 'SYNCED':
        return 'bg-green-100 text-green-800';
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Fejléc */}
      <header className={`${headerColor} text-white px-4 py-3 flex items-center`}>
        <button
          onClick={() => navigate('/menu')}
          className="mr-3 text-xl hover:opacity-80"
        >
          ←
        </button>
        <h1 className="text-lg font-bold flex-1">
          🏢 Cég / Fiók Adminisztráció
        </h1>
      </header>

      <div className="p-4 max-w-6xl mx-auto">
        {/* Összesítő kártyák */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <div className={`bg-white rounded-lg shadow p-4 border-l-4 ${isBestChange ? 'border-red-500' : 'border-orange-500'}`}>
            <h2 className={`font-bold text-lg ${accentColor}`}>
              {isBestChange ? '🔴 Best Change' : '🟠 Expressz Valuta'}
            </h2>
            <p className="text-sm text-gray-500 mt-1">
              Fiókok: {branches.filter(b => b.active).length} aktív / {branches.length} össz
            </p>
            <p className="text-sm text-gray-500">
              Dolgozók: {branches.reduce((sum, b) => sum + b.workerCount, 0)}
            </p>
          </div>
        </div>

        {/* Hiba */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4 text-red-700">
            {error}
          </div>
        )}

        {/* Fiókok táblázat */}
        {isLoading ? (
          <div className="text-center py-8 text-gray-500">⏳ Betöltés...</div>
        ) : (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-600 text-left">
                <tr>
                  <th className="px-4 py-3">Kód</th>
                  <th className="px-4 py-3">Név</th>
                  <th className="px-4 py-3">Város</th>
                  <th className="px-4 py-3">Cég</th>
                  <th className="px-4 py-3 text-center">Dolgozók</th>
                  <th className="px-4 py-3 text-right">Napi forgalom</th>
                  <th className="px-4 py-3 text-center">Sync</th>
                  <th className="px-4 py-3 text-center">Művelet</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {branches.map((branch) => (
                  <tr key={branch.id} className={`hover:bg-gray-50 ${!branch.active ? 'opacity-50' : ''}`}>
                    <td className="px-4 py-3 font-mono text-xs">{branch.code}</td>
                    <td className="px-4 py-3 font-medium">{branch.name}</td>
                    <td className="px-4 py-3">{branch.city}</td>
                    <td className="px-4 py-3 text-sm text-gray-500">{branch.companyName}</td>
                    <td className="px-4 py-3 text-center">{branch.workerCount}</td>
                    <td className="px-4 py-3 text-right font-mono">
                      {branch.dailyTurnoverHuf.toLocaleString('hu-HU')} Ft
                    </td>
                    <td className="px-4 py-3 text-center">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${getSyncStatusBadge(branch.syncStatus)}`}>
                        {branch.syncStatus}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-center">
                      <button
                        onClick={() => handleEdit(branch)}
                        className="text-blue-600 hover:text-blue-800 text-xs"
                      >
                        ✏️ Szerkesztés
                      </button>
                    </td>
                  </tr>
                ))}
                {branches.length === 0 && (
                  <tr>
                    <td colSpan={8} className="px-4 py-8 text-center text-gray-400">
                      Nincs megjeleníthető fiók
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Szerkesztő dialog */}
      {editBranch && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-md mx-4">
            <h2 className="text-lg font-bold mb-4">
              Fiók szerkesztése: {editBranch.code}
            </h2>

            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Név</label>
                <input
                  type="text"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="w-full border rounded-lg px-3 py-2"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Telefon</label>
                <input
                  type="text"
                  value={editPhone}
                  onChange={(e) => setEditPhone(e.target.value)}
                  className="w-full border rounded-lg px-3 py-2"
                  placeholder="Opcionális"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  value={editEmail}
                  onChange={(e) => setEditEmail(e.target.value)}
                  className="w-full border rounded-lg px-3 py-2"
                  placeholder="Opcionális"
                />
              </div>
            </div>

            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setEditBranch(null)}
                className="px-4 py-2 border rounded-lg text-gray-600 hover:bg-gray-50"
              >
                Mégse
              </button>
              <button
                onClick={handleSave}
                disabled={isSaving}
                className={`px-4 py-2 rounded-lg text-white ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'} disabled:opacity-50`}
              >
                {isSaving ? '⏳ Mentés...' : '💾 Mentés'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
