import { create } from 'zustand';
import type { DailySession } from '@/types';
import { getCurrentSession } from '@/api/sessions';

interface SessionState {
  currentSession: DailySession | null;
  isSessionOpen: boolean;
  isOnline: boolean;
  currentTime: string;

  fetchSession: () => Promise<void>;
  setSession: (session: DailySession | null) => void;
  setOnline: (online: boolean) => void;
  updateTime: () => void;
}

function formatTime(): string {
  return new Date().toLocaleString('hu-HU', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

export const useSessionStore = create<SessionState>((set) => ({
  currentSession: null,
  isSessionOpen: false,
  isOnline: navigator.onLine,
  currentTime: formatTime(),

  fetchSession: async () => {
    try {
      const session = await getCurrentSession();
      set({
        currentSession: session,
        isSessionOpen: session?.status === 'OPEN',
      });
    } catch {
      set({ currentSession: null, isSessionOpen: false });
    }
  },

  setSession: (session) => {
    set({
      currentSession: session,
      isSessionOpen: session?.status === 'OPEN',
    });
  },

  setOnline: (online) => {
    set({ isOnline: online });
  },

  updateTime: () => {
    set({ currentTime: formatTime() });
  },
}));
