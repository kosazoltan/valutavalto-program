import { useState, useEffect, useCallback } from 'react';
import { getMessage, markAsRead, deleteMessage, getAttachmentUrl } from '@/api/email';
import type { EmailDetail } from '@/types/email';

interface EmailViewerProps {
  emailId: string | null;
  onReply: (detail: EmailDetail) => void;
  onForward: (detail: EmailDetail) => void;
  onDeleted: () => void;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function formatDateTime(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleString('hu-HU', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export default function EmailViewer({
  emailId,
  onReply,
  onForward,
  onDeleted,
}: EmailViewerProps) {
  const [detail, setDetail] = useState<EmailDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const loadEmail = useCallback(async (id: string) => {
    setLoading(true);
    setError('');
    try {
      const data = await getMessage(id);
      setDetail(data);
      if (!data.isRead) {
        await markAsRead(id);
      }
    } catch {
      setError('Nem sikerült betölteni a levelet.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (emailId) {
      void loadEmail(emailId);
    } else {
      setDetail(null);
    }
  }, [emailId, loadEmail]);

  const handleDelete = useCallback(async () => {
    if (!emailId) return;
    if (!window.confirm('Biztosan törölni szeretné ezt a levelet?')) return;
    try {
      await deleteMessage(emailId);
      onDeleted();
    } catch {
      alert('Hiba történt a törlés során.');
    }
  }, [emailId, onDeleted]);

  const handleMarkRead = useCallback(async () => {
    if (!emailId) return;
    try {
      await markAsRead(emailId);
      setDetail((prev) => (prev ? { ...prev, isRead: true } : null));
    } catch {
      // silent
    }
  }, [emailId]);

  if (!emailId) {
    return (
      <div className="flex flex-1 items-center justify-center">
        <p className="text-gray-400 text-sm">Válasszon ki egy levelet</p>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex flex-1 items-center justify-center">
        <div className="animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-1 items-center justify-center">
        <p className="text-red-500 text-sm">{error}</p>
      </div>
    );
  }

  if (!detail) return null;

  return (
    <div className="flex flex-1 flex-col overflow-hidden">
      {/* Fejléc */}
      <div className="border-b border-gray-200 p-4">
        <h2 className="text-lg font-semibold text-gray-900 mb-2">
          {detail.subject || '(Nincs tárgy)'}
        </h2>
        <div className="text-sm text-gray-600 space-y-1">
          <p>
            <span className="font-medium">Feladó:</span> {detail.from}
          </p>
          <p>
            <span className="font-medium">Címzett:</span>{' '}
            {detail.to.join(', ')}
          </p>
          {detail.cc.length > 0 && (
            <p>
              <span className="font-medium">Másolat:</span>{' '}
              {detail.cc.join(', ')}
            </p>
          )}
          <p>
            <span className="font-medium">Dátum:</span>{' '}
            {formatDateTime(detail.receivedAt)}
          </p>
        </div>

        {/* Gombok */}
        <div className="flex gap-2 mt-3">
          <button
            onClick={() => onReply(detail)}
            className="px-3 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            ↩️ Válasz
          </button>
          <button
            onClick={() => onForward(detail)}
            className="px-3 py-1.5 text-sm bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
          >
            ➡️ Továbbítás
          </button>
          <button
            onClick={handleDelete}
            className="px-3 py-1.5 text-sm bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors"
          >
            🗑️ Törlés
          </button>
          {!detail.isRead && (
            <button
              onClick={handleMarkRead}
              className="px-3 py-1.5 text-sm bg-gray-100 text-gray-600 rounded-lg hover:bg-gray-200 transition-colors"
            >
              ✓ Olvasottnak jelölés
            </button>
          )}
        </div>
      </div>

      {/* Csatolmányok */}
      {detail.attachments.length > 0 && (
        <div className="border-b border-gray-200 px-4 py-2 bg-gray-50">
          <p className="text-xs font-medium text-gray-500 mb-1">
            📎 Csatolmányok ({detail.attachments.length})
          </p>
          <div className="flex flex-wrap gap-2">
            {detail.attachments.map((att) => (
              <a
                key={att.id}
                href={getAttachmentUrl(detail.id, att.id)}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1 px-2 py-1 bg-white border border-gray-200 rounded text-xs text-blue-600 hover:bg-blue-50 transition-colors"
              >
                📄 {att.filename}
                <span className="text-gray-400">
                  ({formatFileSize(att.size)})
                </span>
              </a>
            ))}
          </div>
        </div>
      )}

      {/* Body — sandboxed iframe */}
      <div className="flex-1 overflow-auto p-4">
        {detail.htmlBody ? (
          <iframe
            sandbox=""
            srcDoc={detail.htmlBody}
            title="Email tartalom"
            className="w-full h-full border-0 min-h-[400px]"
          />
        ) : (
          <pre className="whitespace-pre-wrap text-sm text-gray-700 font-sans">
            {detail.body}
          </pre>
        )}
      </div>
    </div>
  );
}
