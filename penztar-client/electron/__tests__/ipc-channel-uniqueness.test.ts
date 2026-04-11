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
});
