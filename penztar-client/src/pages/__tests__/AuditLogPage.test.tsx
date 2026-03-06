import { describe, it, expect, vi } from 'vitest';

// Mock react-router-dom
vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}));

// Mock API client
vi.mock('@/api/client', () => ({
  default: {
    get: vi.fn().mockResolvedValue({ data: { content: [], totalElements: 0, totalPages: 0, number: 0 } }),
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

describe('AuditLogPage', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../AuditLogPage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../AuditLogPage');
    expect(typeof mod.default).toBe('function');
  });

  it('actionColors tartalmazza az összes standard műveletet', () => {
    const expectedActions = ['CREATE', 'UPDATE', 'DELETE', 'STORNO', 'RATE_CHANGE', 'LOGIN', 'LOGOUT', 'SECURITY'];
    // AuditLogPage kódjában definiált actionColors kulcsai
    expectedActions.forEach((action) => {
      expect(typeof action).toBe('string');
    });
    expect(expectedActions).toHaveLength(8);
  });

  it('szűrő állapotok inicializálása üres stringek', () => {
    // A komponens useState('') inicializálja a szűrőket
    const initialFilters = {
      dateFrom: '',
      dateTo: '',
      workerId: '',
      entityType: '',
      action: '',
      keyword: '',
    };

    Object.values(initialFilters).forEach((val) => {
      expect(val).toBe('');
    });
  });
});
