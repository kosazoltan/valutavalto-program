import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { getEmailAccounts, getMessages } from '@/api/email';
import type { EmailSummary, EmailDetail, EmailAccount } from '@/types/email';
import EmailSidebar from '@/components/email/EmailSidebar';
import EmailList from '@/components/email/EmailList';
import EmailViewer from '@/components/email/EmailViewer';
import ComposeModal from '@/components/email/ComposeModal';

export default function EmailPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [, setAccounts] = useState<EmailAccount[]>([]);
  const [selectedFolder, setSelectedFolder] = useState('INBOX');
  const [selectedEmailId, setSelectedEmailId] = useState<string | null>(null);
  const [emails, setEmails] = useState<EmailSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [composeOpen, setComposeOpen] = useState(false);
  const [replyTo, setReplyTo] = useState<{
    messageId: string;
    to: string;
    subject: string;
    body: string;
  } | null>(null);
  const [forwardData, setForwardData] = useState<{
    messageId: string;
    subject: string;
    body: string;
  } | null>(null);
  const [hasAccounts, setHasAccounts] = useState<boolean | null>(null);

  // Fiókok betöltés
  useEffect(() => {
    const load = async () => {
      try {
        const accs = await getEmailAccounts();
        setAccounts(accs);
        setHasAccounts(accs.length > 0);
      } catch {
        setHasAccounts(false);
      }
    };
    void load();
  }, []);

  // Levelek betöltés ha van fiók
  const loadMessages = useCallback(async () => {
    if (hasAccounts === false) return;
    setLoading(true);
    try {
      const result = await getMessages(selectedFolder, 50);
      setEmails(result.messages);
    } catch {
      setEmails([]);
    } finally {
      setLoading(false);
    }
  }, [selectedFolder, hasAccounts]);

  useEffect(() => {
    if (hasAccounts) {
      void loadMessages();
    }
  }, [loadMessages, hasAccounts]);

  // Unread count
  const unreadCount = emails.filter((e) => !e.isRead).length;

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !composeOpen) navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate, composeOpen]);

  const handleReply = useCallback((detail: EmailDetail) => {
    setReplyTo({
      messageId: detail.id,
      to: detail.from,
      subject: detail.subject,
      body: detail.body,
    });
    setForwardData(null);
    setComposeOpen(true);
  }, []);

  const handleForward = useCallback((detail: EmailDetail) => {
    setForwardData({
      messageId: detail.id,
      subject: detail.subject,
      body: detail.body,
    });
    setReplyTo(null);
    setComposeOpen(true);
  }, []);

  const handleDeleted = useCallback(() => {
    setSelectedEmailId(null);
    void loadMessages();
  }, [loadMessages]);

  const handleCloseCompose = useCallback(() => {
    setComposeOpen(false);
    setReplyTo(null);
    setForwardData(null);
    void loadMessages();
  }, [loadMessages]);

  const handleNewEmail = useCallback(() => {
    setReplyTo(null);
    setForwardData(null);
    setComposeOpen(true);
  }, []);

  // Nincs fiók → beállítás link
  if (hasAccounts === false) {
    return (
      <div className="flex h-screen flex-col">
        <header className={`${headerColor} px-6 py-3 text-white`}>
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-bold">📧 Levelezés</h1>
            <button
              onClick={() => navigate('/menu')}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
            >
              ← Vissza (ESC)
            </button>
          </div>
        </header>
        <div className="flex flex-1 items-center justify-center">
          <div className="text-center">
            <p className="text-lg text-gray-600 mb-4">
              Nincs email fiók konfigurálva
            </p>
            <button
              onClick={() => navigate('/email/settings')}
              className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              ⚙️ Email fiók beállítása
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Betöltés
  if (hasAccounts === null) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📧 Levelezés</h1>
          <div className="flex items-center gap-2">
            <button
              onClick={handleNewEmail}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
            >
              ✉️ Új levél
            </button>
            <button
              onClick={loadMessages}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
            >
              🔄 Frissítés
            </button>
            <button
              onClick={() => navigate('/email/settings')}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
            >
              ⚙️ Beállítások
            </button>
            <button
              onClick={() => navigate('/menu')}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
            >
              ← Vissza (ESC)
            </button>
          </div>
        </div>
      </header>

      {/* 3 paneles layout */}
      <div className="flex flex-1 overflow-hidden">
        <EmailSidebar
          selectedFolder={selectedFolder}
          onSelectFolder={setSelectedFolder}
          unreadCount={unreadCount}
        />
        <EmailList
          emails={emails}
          selectedId={selectedEmailId}
          onSelect={setSelectedEmailId}
          loading={loading}
        />
        <EmailViewer
          emailId={selectedEmailId}
          onReply={handleReply}
          onForward={handleForward}
          onDeleted={handleDeleted}
        />
      </div>

      {/* Compose modal */}
      <ComposeModal
        isOpen={composeOpen}
        onClose={handleCloseCompose}
        replyTo={replyTo}
        forwardData={forwardData}
      />
    </div>
  );
}
