import { describe, it, expect, vi } from 'vitest';

// Mock react-router-dom
vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}));

// Mock API client
vi.mock('@/api/client', () => ({
  default: {
    get: vi.fn().mockResolvedValue({ data: [] }),
    put: vi.fn().mockResolvedValue({ data: {} }),
  },
}));

// Mock toast
vi.mock('@/hooks/useToast', () => ({
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
    info: vi.fn(),
  },
}));

// Mock auth store
vi.mock('@/stores/authStore', () => ({
  useAuthStore: () => ({
    user: { id: 1, username: 'test', role: 'ADMIN', branchCode: 'BP01', companyId: 1 },
    companyType: 'BEST_CHANGE',
  }),
}));

describe('CompanyAdminPage', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../CompanyAdminPage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../CompanyAdminPage');
    expect(typeof mod.default).toBe('function');
  });
});
