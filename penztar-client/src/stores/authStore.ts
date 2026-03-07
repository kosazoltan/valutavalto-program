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
  /** V57: aktív operatív szerepkör kódja */
  activeRole: string | null;
  /** V57: aktív role-hoz tartozó permission kódok */
  permissions: string[];

  setAuth: (user: User, token: string, refreshToken: string) => void;
  clearAuth: () => void;
  setBranchCode: (code: string) => void;
  /** V57: operatív role és permissions beállítása (select-role után) */
  setRoleAndPermissions: (activeRole: string, permissions: string[], token: string) => void;
  /** V57: permission ellenőrzés */
  hasPermission: (permissionCode: string) => boolean;
}

function resolveCompanyType(branchCode: string): CompanyType {
  const code = parseInt(branchCode, 10);
  return code < 151 ? 'BEST_CHANGE' : 'EXPRESSZ';
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: null,
  refreshToken: null,
  branchCode: import.meta.env.VITE_BRANCH_CODE ?? '101',
  companyType: resolveCompanyType(import.meta.env.VITE_BRANCH_CODE ?? '101'),
  isAuthenticated: false,
  activeRole: null,
  permissions: [],

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
      activeRole: user.activeRole ?? null,
      permissions: user.permissions ?? [],
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
      activeRole: null,
      permissions: [],
    });
  },

  setBranchCode: (code) => {
    set({
      branchCode: code,
      companyType: resolveCompanyType(code),
    });
  },

  setRoleAndPermissions: (activeRole, permissions, token) => {
    setAuthToken(token);
    void persistToken(token);
    set((state) => ({
      token,
      activeRole,
      permissions,
      user: state.user ? { ...state.user, activeRole, permissions } : null,
    }));
  },

  hasPermission: (permissionCode) => {
    const { permissions, activeRole } = get();
    // DIRECTOR mindenhez hozzáfér
    if (activeRole === 'DIRECTOR') return true;
    return permissions.includes(permissionCode);
  },
}));
