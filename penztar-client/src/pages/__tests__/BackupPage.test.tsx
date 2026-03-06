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
  }),
}));

// Mock backup API
vi.mock('@/api/backup', () => ({
  createBackup: vi.fn().mockResolvedValue({}),
  restoreBackup: vi.fn().mockResolvedValue({}),
  getBackupHistory: vi.fn().mockResolvedValue({ content: [], totalPages: 0 }),
}));

describe('BackupPage', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../BackupPage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../BackupPage');
    expect(typeof mod.default).toBe('function');
  });
});
