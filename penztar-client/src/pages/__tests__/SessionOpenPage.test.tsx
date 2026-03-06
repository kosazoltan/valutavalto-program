import { describe, it, expect, vi } from 'vitest';

// Mock react-router-dom
vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}));

// Mock API
vi.mock('@/api/sessionOpen', () => ({
  openSession: vi.fn().mockResolvedValue({ sessionId: 1, status: 'OPEN' }),
  validateSessionOpen: vi.fn().mockResolvedValue([]),
}));

// Mock auth store
vi.mock('@/stores/authStore', () => ({
  useAuthStore: () => ({
    user: { id: 1, username: 'test', role: 'CASHIER', branchCode: 'BP01', companyId: 1 },
    companyType: 'BEST_CHANGE',
  }),
}));

// Mock currencies
vi.mock('@/utils/currencies', () => ({
  getCurrencyInfo: vi.fn().mockReturnValue({ code: 'EUR', name: 'Euro', flag: '🇪🇺', unit: 1 }),
}));

describe('SessionOpenPage', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../SessionOpenPage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../SessionOpenPage');
    expect(typeof mod.default).toBe('function');
  });
});
