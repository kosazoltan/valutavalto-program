import { describe, it, expect } from 'vitest';

describe('TradePage modul', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../TradePage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../TradePage');
    expect(typeof mod.default).toBe('function');
  });
});
