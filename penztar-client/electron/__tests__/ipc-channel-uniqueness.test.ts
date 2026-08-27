import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

describe('IPC channel uniqueness', () => {
  it('registers restart-app exactly once across Electron main sources', () => {
    const electronDir = path.resolve(__dirname, '..');
    const files = ['main.ts', 'updater.ts'];

    const restartRegistrations = files.reduce((count, file) => {
      const source = fs.readFileSync(path.join(electronDir, file), 'utf8');
      const matches = source.match(/ipcMain\.handle\('restart-app'/g);
      return count + (matches?.length ?? 0);
    }, 0);

    expect(restartRegistrations).toBe(1);
  });

  // FK-097 WU-14: az iroda-szintű díj-konfiguráció cache-olvasó csatorna (FR-3)
  // pontosan egyszer regisztrált a main + updater forrásokban.
  it('registers get-cached-handling-fee-config exactly once across Electron main sources', () => {
    const electronDir = path.resolve(__dirname, '..');
    const files = ['main.ts', 'updater.ts'];

    const registrations = files.reduce((count, file) => {
      const source = fs.readFileSync(path.join(electronDir, file), 'utf8');
      const matches = source.match(/ipcMain\.handle\('get-cached-handling-fee-config'/g);
      return count + (matches?.length ?? 0);
    }, 0);

    expect(registrations).toBe(1);
  });
});
