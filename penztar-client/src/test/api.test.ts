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

  it('trades API modul importálható', async () => {
    const mod = await import('@/api/trades');
    expect(mod).toBeDefined();
    expect(mod.proposeTrade).toBeDefined();
    expect(typeof mod.proposeTrade).toBe('function');
  });

  it('sync API modul importálható', async () => {
    const mod = await import('@/api/sync');
    expect(mod).toBeDefined();
    expect(mod.syncRates).toBeDefined();
    expect(typeof mod.syncRates).toBe('function');
  });

  it('dashboard API modul importálható', async () => {
    const mod = await import('@/api/dashboard');
    expect(mod).toBeDefined();
    expect(mod.getDashboardSummary).toBeDefined();
    expect(typeof mod.getDashboardSummary).toBe('function');
  });

  it('monitoring API modul importálható', async () => {
    const mod = await import('@/api/monitoring');
    expect(mod).toBeDefined();
    expect(mod.sendHeartbeat).toBeDefined();
    expect(typeof mod.sendHeartbeat).toBe('function');
  });

  it('backup API modul importálható', async () => {
    const mod = await import('@/api/backup');
    expect(mod).toBeDefined();
    expect(mod.createBackup).toBeDefined();
    expect(typeof mod.createBackup).toBe('function');
  });

  it('license API modul importálható', async () => {
    const mod = await import('@/api/license');
    expect(mod).toBeDefined();
    expect(mod.getLicenseStatus).toBeDefined();
    expect(typeof mod.getLicenseStatus).toBe('function');
  });
});
