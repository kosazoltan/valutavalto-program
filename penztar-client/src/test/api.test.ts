import { describe, it, expect } from 'vitest';

describe('API modulok importálhatóság', () => {
  it('commissions API modul importálható', async () => {
    const mod = await import('@/api/commissions');
    expect(mod.calculateCommission).toBeDefined();
    expect(typeof mod.calculateCommission).toBe('function');
  });

  it('booking API modul importálható', async () => {
    const mod = await import('@/api/booking');
    expect(mod).toBeDefined();
  });

  it('profit API modul importálható', async () => {
    const mod = await import('@/api/profit');
    expect(mod).toBeDefined();
  });

  it('supervisor API modul importálható', async () => {
    const mod = await import('@/api/supervisor');
    expect(mod).toBeDefined();
  });

  it('stamps API modul importálható', async () => {
    const mod = await import('@/api/stamps');
    expect(mod).toBeDefined();
  });

  it('police API modul importálható', async () => {
    const mod = await import('@/api/police');
    expect(mod).toBeDefined();
  });

  it('rateApproval API modul importálható', async () => {
    const mod = await import('@/api/rateApproval');
    expect(mod).toBeDefined();
  });

  it('dailyReport API modul importálható', async () => {
    const mod = await import('@/api/dailyReport');
    expect(mod).toBeDefined();
  });
});
