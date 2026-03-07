import type { EmailSummary } from '@/types/email';

interface EmailListProps {
  emails: EmailSummary[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  loading: boolean;
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const isToday =
    date.getFullYear() === now.getFullYear() &&
    date.getMonth() === now.getMonth() &&
    date.getDate() === now.getDate();

  if (isToday) {
    return `ma ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  const yesterday = new Date(now);
  yesterday.setDate(now.getDate() - 1);
  const isYesterday =
    date.getFullYear() === yesterday.getFullYear() &&
    date.getMonth() === yesterday.getMonth() &&
    date.getDate() === yesterday.getDate();

  if (isYesterday) {
    return 'tegnap';
  }

  const months = [
    'jan.', 'febr.', 'márc.', 'ápr.', 'máj.', 'jún.',
    'júl.', 'aug.', 'szept.', 'okt.', 'nov.', 'dec.',
  ];

  if (date.getFullYear() !== now.getFullYear()) {
    return `${date.getFullYear()}. ${months[date.getMonth()]} ${date.getDate()}.`;
  }

  return `${months[date.getMonth()]} ${date.getDate()}.`;
}

export default function EmailList({
  emails,
  selectedId,
  onSelect,
  loading,
}: EmailListProps) {
  if (loading) {
    return (
      <div className="flex w-96 items-center justify-center border-r border-gray-200">
        <div className="text-center">
          <div className="animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full mx-auto mb-2" />
          <p className="text-sm text-gray-500">Betöltés...</p>
        </div>
      </div>
    );
  }

  if (emails.length === 0) {
    return (
      <div className="flex w-96 items-center justify-center border-r border-gray-200">
        <p className="text-sm text-gray-400">Nincsenek levelek ebben a mappában</p>
      </div>
    );
  }

  return (
    <div className="w-96 overflow-y-auto border-r border-gray-200">
      {emails.map((email) => {
        const isSelected = selectedId === email.id;
        return (
          <button
            key={email.id}
            onClick={() => onSelect(email.id)}
            className={`w-full text-left px-4 py-3 border-b border-gray-100 transition-colors ${
              isSelected
                ? 'bg-blue-50 border-l-4 border-l-blue-500'
                : 'hover:bg-gray-50 border-l-4 border-l-transparent'
            }`}
          >
            <div className="flex items-center justify-between mb-1">
              <span
                className={`text-sm truncate max-w-[200px] ${
                  !email.isRead ? 'font-semibold text-gray-900' : 'text-gray-600'
                }`}
              >
                {email.sender}
              </span>
              <span className="text-xs text-gray-400 flex-shrink-0 ml-2">
                {formatDate(email.receivedAt)}
              </span>
            </div>
            <div className="flex items-center gap-1">
              <p
                className={`text-sm truncate ${
                  !email.isRead ? 'font-semibold text-gray-800' : 'text-gray-600'
                }`}
              >
                {email.subject || '(Nincs tárgy)'}
              </p>
              {email.hasAttachments && (
                <span className="flex-shrink-0 text-gray-400" title="Csatolmány">
                  📎
                </span>
              )}
            </div>
            <p className="text-xs text-gray-400 truncate mt-0.5">
              {email.snippet}
            </p>
          </button>
        );
      })}
    </div>
  );
}
