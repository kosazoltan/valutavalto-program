import { create } from 'zustand';
import type { User, CompanyType } from '@/types';
import { setAuthToken, persistToken, clearPersistedToken } from '@/api/client';

interface AuthState {
  user: User | null;
  token: string | null;
  refreshToken: string | null;
  branchCode: string;
  companyType: CompanyType;
  isAuthenticated: boolean;

  setAuth: (user: User, token: string, refreshToken: string) => void;
  clearAuth: () => void;
  setBranchCode: (code: string) => void;
}

function resolveCompanyType(branchCode: string): CompanyType {
  const code = parseInt(branchCode, 10);
  return code < 151 ? 'BEST_CHANGE' : 'EXPRESSZ';
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  refreshToken: null,
  branchCode: import.meta.env.VITE_BRANCH_CODE ?? '101',
  companyType: resolveCompanyType(import.meta.env.VITE_BRANCH_CODE ?? '101'),
  isAuthenticated: false,

  setAuth: (user, token, refreshToken) => {
    setAuthToken(token);
    // M1: JWT token persist — mentés SQLite-ba
    void persistToken(token);
    set({
      user,
      token,
      refreshToken,
      branchCode: user.branchCode,
      companyType: resolveCompanyType(user.branchCode),
      isAuthenticated: true,
    });
  },

  clearAuth: () => {
    setAuthToken(null);
    // M1: JWT token persist — törlés SQLite-ból
    void clearPersistedToken();
    set({
      user: null,
      token: null,
      refreshToken: null,
      isAuthenticated: false,
    });
  },

  setBranchCode: (code) => {
    set({
      branchCode: code,
      companyType: resolveCompanyType(code),
    });
  },
}));
