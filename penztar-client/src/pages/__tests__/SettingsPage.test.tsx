import { describe, it, expect, vi } from 'vitest';

// Mock react-router-dom
vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}));

// Mock auth store
vi.mock('@/stores/authStore', () => ({
  useAuthStore: () => ({
    user: { id: 1, username: 'test', role: 'ADMIN', branchCode: 'BP01', companyId: 1 },
    companyType: 'BEST_CHANGE',
    branchCode: 'BP01',
    clearAuth: vi.fn(),
  }),
}));

// Mock system params API
vi.mock('@/api/systemParams', () => ({
  getAllSystemParams: vi.fn().mockResolvedValue([]),
  updateSystemParam: vi.fn().mockResolvedValue({}),
}));

describe('SettingsPage', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../SettingsPage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../SettingsPage');
    expect(typeof mod.default).toBe('function');
  });
});
