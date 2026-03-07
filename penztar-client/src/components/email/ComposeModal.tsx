import { useState, useEffect, useCallback } from 'react';
import { sendMessage, replyToMessage, forwardMessage } from '@/api/email';
import type { ComposeEmailDto } from '@/types/email';

interface ComposeModalProps {
  isOpen: boolean;
  onClose: () => void;
  replyTo?: { messageId: string; to: string; subject: string; body: string } | null;
  forwardData?: { messageId: string; subject: string; body: string } | null;
}

export default function ComposeModal({
  isOpen,
  onClose,
  replyTo,
  forwardData,
}: ComposeModalProps) {
  const [to, setTo] = useState('');
  const [cc, setCc] = useState('');
  const [subject, setSubject] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);

  useEffect(() => {
    if (replyTo) {
      setTo(replyTo.to);
      setSubject(
        replyTo.subject.startsWith('Re:')
          ? replyTo.subject
          : `Re: ${replyTo.subject}`,
      );
      setBody(
        `\n\n---\n${replyTo.body
          .split('\n')
          .map((line) => `> ${line}`)
          .join('\n')}`,
      );
      setCc('');
    } else if (forwardData) {
      setTo('');
      setSubject(
        forwardData.subject.startsWith('Fwd:')
          ? forwardData.subject
          : `Fwd: ${forwardData.subject}`,
      );
      setBody(`\n\n--- Továbbított levél ---\n${forwardData.body}`);
      setCc('');
    } else {
      setTo('');
      setCc('');
      setSubject('');
      setBody('');
    }
  }, [replyTo, forwardData, isOpen]);

  const handleSend = useCallback(async () => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!to.trim() || !emailRegex.test(to.trim())) {
      alert('Kérem adjon meg érvényes email címet!');
      return;
    }
    if (!subject.trim()) {
      alert('Kérem adjon meg tárgyat!');
      return;
    }

    setSending(true);
    try {
      if (replyTo) {
        await replyToMessage(replyTo.messageId, body);
      } else if (forwardData) {
        await forwardMessage(forwardData.messageId, to);
      } else {
        const dto: ComposeEmailDto = {
          to: to.trim(),
          cc: cc.trim() || undefined,
          subject: subject.trim(),
          body,
        };
        await sendMessage(dto);
      }
      alert('Levél elküldve!');
      onClose();
    } catch {
      alert('Hiba történt a küldés során.');
    } finally {
      setSending(false);
    }
  }, [to, cc, subject, body, replyTo, forwardData, onClose]);

  // ESC bezárás
  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl mx-4">
        {/* Fejléc */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">
            {replyTo
              ? '↩️ Válasz'
              : forwardData
                ? '➡️ Továbbítás'
                : '✉️ Új levél'}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 text-xl"
          >
            ✕
          </button>
        </div>

        {/* Form */}
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Címzett
            </label>
            <input
              type="email"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              placeholder="pelda@gmail.com"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
              disabled={!!replyTo}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Másolat (CC)
            </label>
            <input
              type="email"
              value={cc}
              onChange={(e) => setCc(e.target.value)}
              placeholder="Opcionális"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Tárgy
            </label>
            <input
              type="text"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="Levél tárgya"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Törzs
            </label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              rows={12}
              placeholder="Írja be az üzenetet..."
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none resize-none"
            />
          </div>
        </div>

        {/* Gombok */}
        <div className="flex justify-end gap-3 px-6 py-4 border-t border-gray-200">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
            disabled={sending}
          >
            Mégse
          </button>
          <button
            onClick={handleSend}
            disabled={sending}
            className="px-4 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
          >
            {sending ? '⏳ Küldés...' : '📤 Küldés'}
          </button>
        </div>
      </div>
    </div>
  );
}
