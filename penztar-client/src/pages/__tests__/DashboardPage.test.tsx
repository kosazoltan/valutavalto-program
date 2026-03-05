import { describe, it, expect } from 'vitest';

describe('DashboardPage modul', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../DashboardPage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../DashboardPage');
    expect(typeof mod.default).toBe('function');
  });
});
