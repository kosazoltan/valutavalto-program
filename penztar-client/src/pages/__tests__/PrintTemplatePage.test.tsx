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

// Mock print templates API
vi.mock('@/api/printTemplates', () => ({
  getTemplates: vi.fn().mockResolvedValue([]),
  createTemplate: vi.fn().mockResolvedValue({}),
  updateTemplate: vi.fn().mockResolvedValue({}),
  previewTemplate: vi.fn().mockResolvedValue(''),
}));

describe('PrintTemplatePage', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../PrintTemplatePage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../PrintTemplatePage');
    expect(typeof mod.default).toBe('function');
  });
});
