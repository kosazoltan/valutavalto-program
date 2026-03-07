interface EmailSidebarProps {
  selectedFolder: string;
  onSelectFolder: (folder: string) => void;
  unreadCount: number;
}

const FOLDERS = [
  { key: 'INBOX', label: '📥 Beérkezett', icon: '📥' },
  { key: 'SENT', label: '📤 Elküldött', icon: '📤' },
  { key: 'DRAFT', label: '📝 Piszkozatok', icon: '📝' },
  { key: 'TRASH', label: '🗑️ Kuka', icon: '🗑️' },
];

export default function EmailSidebar({
  selectedFolder,
  onSelectFolder,
  unreadCount,
}: EmailSidebarProps) {
  return (
    <div className="flex w-56 flex-col bg-gray-50 border-r border-gray-200">
      <div className="p-4">
        <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide">
          Mappák
        </h2>
      </div>
      <nav className="flex-1 px-2">
        {FOLDERS.map((folder) => {
          const isSelected = selectedFolder === folder.key;
          return (
            <button
              key={folder.key}
              onClick={() => onSelectFolder(folder.key)}
              className={`w-full text-left px-3 py-2 rounded-lg mb-1 text-sm flex items-center justify-between transition-colors ${
                isSelected
                  ? 'bg-blue-100 text-blue-700 font-medium'
                  : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <span>{folder.label}</span>
              {folder.key === 'INBOX' && unreadCount > 0 && (
                <span className="bg-blue-600 text-white text-xs rounded-full px-2 py-0.5 min-w-[20px] text-center">
                  {unreadCount}
                </span>
              )}
            </button>
          );
        })}
      </nav>
    </div>
  );
}
