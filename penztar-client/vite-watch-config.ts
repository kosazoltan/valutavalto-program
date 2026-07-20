import type { ServerOptions } from 'vite';

export const ELECTRON_DEV_WATCH_IGNORED: readonly string[] = Object.freeze([
  '**/.dev-user-data/**',
  '**/.dev-app/**',
  '**/local.db',
  '**/local.db-wal',
  '**/local.db-shm',
]);

export function createElectronDevServerConfig(): ServerOptions {
  return {
    watch: {
      // Vite's mutable array type is narrower than the frozen runtime value.
      ignored: ELECTRON_DEV_WATCH_IGNORED as string[],
    },
  };
}

export function createElectronDevLaunchArgs(tmpAppDir: string): [string] {
  return [tmpAppDir];
}
