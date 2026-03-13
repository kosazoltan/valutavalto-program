import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { getTemplates, createTemplate, updateTemplate, previewTemplate } from '@/api/printTemplates';
import type { PrintTemplateData, PrintTemplateType } from '@/types';

const TEMPLATE_TYPES: { value: PrintTemplateType; label: string }[] = [
  { value: 'RECEIPT', label: 'Bizonylat' },
  { value: 'REPORT', label: 'Jelentés' },
  { value: 'LABEL', label: 'Címke' },
  { value: 'CLOSING', label: 'Záróbizonylat' },
];

export default function PrintTemplatePage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [templates, setTemplates] = useState<PrintTemplateData[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [filterType, setFilterType] = useState<string>('');

  // Szerkesztő mezők
  const [editName, setEditName] = useState('');
  const [editType, setEditType] = useState<string>('RECEIPT');
  const [editContent, setEditContent] = useState('');
  const [editIsDefault, setEditIsDefault] = useState(false);

  const [previewHtml, setPreviewHtml] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const loadTemplates = useCallback(async () => {
    try {
      const data = await getTemplates(filterType || undefined);
      setTemplates(data);
    } catch {
      console.error('[PrintTemplatePage] Betöltési hiba:', err);
      setError('Sablonok betöltése sikertelen.');
    } finally {
      setLoading(false);
    }
  }, [filterType]);

  useEffect(() => {
    void loadTemplates();
  }, [loadTemplates]);

  const handleSelect = useCallback((tpl: PrintTemplateData) => {
    setSelectedId(tpl.id);
    setEditName(tpl.name);
    setEditType(tpl.templateType);
    setEditContent(tpl.content ?? '');
    setEditIsDefault(tpl.isDefault);
    setPreviewHtml('');
    setError('');
    setSuccess('');
  }, []);

  const handleNew = useCallback(() => {
    setSelectedId(null);
    setEditName('');
    setEditType('RECEIPT');
    setEditContent('');
    setEditIsDefault(false);
    setPreviewHtml('');
    setError('');
    setSuccess('');
  }, []);

  const handleSave = useCallback(async () => {
    if (saving) return;
    setSaving(true);
    setError('');
    setSuccess('');

    try {
      const payload = {
        name: editName,
        templateType: editType,
        content: editContent,
        isDefault: editIsDefault,
      };

      if (selectedId) {
        await updateTemplate(selectedId, payload);
        setSuccess('✅ Sablon frissítve!');
      } else {
        const created = await createTemplate(payload);
        setSelectedId(created.id);
        setSuccess('✅ Sablon létrehozva!');
      }
      await loadTemplates();
    } catch {
      console.error('[PrintTemplatePage] Mentés hiba:', err);
      setError('Sablon mentése sikertelen.');
    } finally {
      setSaving(false);
    }
  }, [saving, selectedId, editName, editType, editContent, editIsDefault, loadTemplates]);

  const handlePreview = useCallback(async () => {
    if (!selectedId) return;
    setError('');

    try {
      const sampleData: Record<string, unknown> = {
        receiptNumber: 'BC-2026-001234',
        date: '2026.03.06',
        amount: '100.00 EUR',
        hufAmount: '40 050 HUF',
        cashierName: 'Teszt Pénztáros',
        branchName: 'Budapest I.',
      };
      const rendered = await previewTemplate(selectedId, sampleData);
      setPreviewHtml(rendered);
    } catch {
      console.error('[PrintTemplatePage] Előnézet hiba:', err);
      setError('Előnézet generálása sikertelen.');
    }
  }, [selectedId]);

  const handleSetDefault = useCallback(async () => {
    if (!selectedId) return;
    setEditIsDefault(true);
    // Azonnal mentjük
    setSaving(true);
    setError('');
    setSuccess('');

    try {
      await updateTemplate(selectedId, {
        name: editName,
        templateType: editType,
        content: editContent,
        isDefault: true,
      });
      setSuccess('✅ Alapértelmezetté téve!');
      await loadTemplates();
    } catch {
      console.error('[PrintTemplatePage] Alapértelmezett beállítás hiba:', err);
      setError('Alapértelmezetté tétel sikertelen.');
    } finally {
      setSaving(false);
    }
  }, [selectedId, editName, editType, editContent, loadTemplates]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/settings');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🖨️ Nyomtatási sablonok</h1>
          <button
            onClick={() => navigate('/settings')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto grid max-w-6xl grid-cols-1 gap-6 lg:grid-cols-3">
          {/* Bal oldal — sablon lista */}
          <div className="rounded-xl border bg-white p-4">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-700">Sablonok</h2>
              <button
                onClick={handleNew}
                className={`rounded-lg px-3 py-1 text-sm text-white ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'}`}
              >
                + Új
              </button>
            </div>

            {/* Típus szűrő */}
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              className="input-field mb-3 text-sm"
            >
              <option value="">Összes típus</option>
              {TEMPLATE_TYPES.map((t) => (
                <option key={t.value} value={t.value}>{t.label}</option>
              ))}
            </select>

            {loading ? (
              <p className="text-gray-500 text-sm">⏳ Betöltés...</p>
            ) : templates.length === 0 ? (
              <p className="text-gray-400 text-sm">Nincs sablon.</p>
            ) : (
              <ul className="space-y-1">
                {templates.map((tpl) => (
                  <li key={tpl.id}>
                    <button
                      onClick={() => handleSelect(tpl)}
                      className={`w-full rounded-lg p-2 text-left text-sm hover:bg-gray-100 ${
                        selectedId === tpl.id ? 'bg-blue-50 border border-blue-300' : ''
                      }`}
                    >
                      <div className="font-medium">
                        {tpl.name}
                        {tpl.isDefault && <span className="ml-1 text-xs text-green-600">⭐ alapért.</span>}
                      </div>
                      <div className="text-xs text-gray-400">
                        {TEMPLATE_TYPES.find((t) => t.value === tpl.templateType)?.label ?? tpl.templateType}
                      </div>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>

          {/* Jobb oldal — szerkesztő */}
          <div className="col-span-1 space-y-4 lg:col-span-2">
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-semibold text-gray-700">
                {selectedId ? '✏️ Sablon szerkesztése' : '➕ Új sablon'}
              </h2>

              <div className="space-y-3">
                <div>
                  <label className="mb-1 block text-sm text-gray-500">Név</label>
                  <input
                    type="text"
                    value={editName}
                    onChange={(e) => setEditName(e.target.value)}
                    className="input-field"
                    placeholder="Sablon neve..."
                  />
                </div>

                <div>
                  <label className="mb-1 block text-sm text-gray-500">Típus</label>
                  <select
                    value={editType}
                    onChange={(e) => setEditType(e.target.value)}
                    className="input-field"
                  >
                    {TEMPLATE_TYPES.map((t) => (
                      <option key={t.value} value={t.value}>{t.label}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="mb-1 block text-sm text-gray-500">
                    Tartalom (HTML / ESC/POS)
                  </label>
                  <textarea
                    value={editContent}
                    onChange={(e) => setEditContent(e.target.value)}
                    className="input-field font-mono text-xs"
                    rows={12}
                    placeholder="<html>&#10;  <body>&#10;    <h1>{{receiptNumber}}</h1>&#10;    <p>Dátum: {{date}}</p>&#10;  </body>&#10;</html>"
                  />
                </div>

                {/* Gombok */}
                <div className="flex flex-wrap gap-3">
                  <button
                    onClick={() => void handleSave()}
                    disabled={saving || !editName}
                    className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'} disabled:opacity-50`}
                  >
                    {saving ? '⏳ Mentés...' : '💾 Mentés'}
                  </button>

                  {selectedId && (
                    <>
                      <button
                        onClick={() => void handlePreview()}
                        className="rounded-lg border bg-gray-100 px-4 py-2 text-sm hover:bg-gray-200"
                      >
                        👁️ Előnézet
                      </button>
                      {!editIsDefault && (
                        <button
                          onClick={() => void handleSetDefault()}
                          className="rounded-lg border bg-green-50 px-4 py-2 text-sm text-green-700 hover:bg-green-100"
                        >
                          ⭐ Alapértelmezetté tesz
                        </button>
                      )}
                    </>
                  )}
                </div>
              </div>

              {/* Üzenetek */}
              {success && (
                <div className="mt-3 rounded-lg bg-green-50 p-3 text-sm text-green-700">{success}</div>
              )}
              {error && (
                <div className="mt-3 rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>
              )}
            </div>

            {/* Előnézet */}
            {previewHtml && (
              <div className="rounded-xl border bg-white p-6">
                <h3 className="mb-3 text-md font-semibold text-gray-700">👁️ Előnézet</h3>
                <div
                  className="rounded border bg-gray-50 p-4 text-sm"
                  dangerouslySetInnerHTML={{ __html: previewHtml }}
                />
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

