import { describe, it, expect } from 'vitest';

describe('MainMenu modul', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../MainMenu');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens', async () => {
    const mod = await import('../MainMenu');
    expect(typeof mod.default).toBe('function');
  });
});
