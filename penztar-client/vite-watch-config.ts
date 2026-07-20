import fs from 'node:fs';
import path from 'node:path';
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

type LegacyAppAsarFs = Pick<typeof fs, 'lstatSync' | 'unlinkSync'>;

type CleanupLegacyElectronDevAppAsarOptions = {
  fsOps?: LegacyAppAsarFs;
  projectRoot?: string;
};

type FsStatsLike = Pick<fs.Stats, 'isFile' | 'isSymbolicLink'>;

type ElectronDevSpawnOptions = {
  stdio: 'inherit';
  cwd: string;
  env: NodeJS.ProcessEnv;
};

type SpawnElectronDevProcessOptions<TProcess> = {
  electronExe: string;
  tmpAppDir: string;
  devUserData: string;
  cwd: string;
  env: NodeJS.ProcessEnv;
  spawnFn: (command: string, args: [string], options: ElectronDevSpawnOptions) => TProcess;
  cleanupFn?: (electronExe: string) => void;
};

const LEGACY_APP_ASAR_LABEL = 'resources/app.asar';
const DEFAULT_APP_ASAR_LABEL = 'resources/default_app.asar';
const ELECTRON_DIST_RELATIVE_PATH = 'node_modules/electron/dist';

function normalizePathForComparison(target: string): string {
  return target.replace(/\\/g, '/').replace(/\/+/g, '/').replace(/\/$/, '');
}

function formatSafeDisplayPath(target: string, projectRoot: string): string {
  const normalizedTarget = normalizePathForComparison(target);
  const normalizedProjectRoot = normalizePathForComparison(projectRoot);
  const projectPrefix = `${normalizedProjectRoot}/`;

  if (normalizedTarget.startsWith(projectPrefix)) {
    return normalizedTarget.slice(projectPrefix.length);
  }

  const segments = normalizedTarget.split('/').filter(Boolean);
  if (segments.length <= 4) {
    return normalizedTarget;
  }

  return `.../${segments.slice(-4).join('/')}`;
}

function resolveElectronResourcesDir(electronExe: string, projectRoot: string): string {
  const normalizedElectronExe = normalizePathForComparison(electronExe);
  const normalizedProjectRoot = normalizePathForComparison(projectRoot);
  const expectedElectronBase = `${normalizedProjectRoot}/${ELECTRON_DIST_RELATIVE_PATH}`;
  const expectedElectronExePaths = new Set([
    `${expectedElectronBase}/electron.exe`,
    `${expectedElectronBase}/electron`,
  ]);

  if (!expectedElectronExePaths.has(normalizedElectronExe)) {
    throw new Error(
      `Invalid electron executable path: expected ${ELECTRON_DIST_RELATIVE_PATH}/electron(.exe), got ${formatSafeDisplayPath(electronExe, projectRoot)}`,
    );
  }

  return path.join(path.dirname(electronExe), 'resources');
}

function formatFsError(error: unknown): string {
  if (typeof error === 'object' && error !== null && 'code' in error) {
    const code = (error as { code?: unknown }).code;
    if (typeof code === 'string' && code.length > 0) {
      return code;
    }
  }

  return error instanceof Error ? error.message : String(error);
}

function readPathStatus(
  targetPath: string,
  targetLabel: string,
  fsOps: LegacyAppAsarFs,
): FsStatsLike | null {
  try {
    return fsOps.lstatSync(targetPath);
  } catch (error) {
    if (typeof error === 'object' && error !== null && 'code' in error) {
      const code = (error as { code?: unknown }).code;
      if (code === 'ENOENT') {
        return null;
      }
    }

    throw new Error(`Failed to inspect ${targetLabel}: ${formatFsError(error)}`);
  }
}

export function cleanupLegacyElectronDevAppAsar(
  electronExe: string,
  options: CleanupLegacyElectronDevAppAsarOptions = {},
): void {
  const fsOps = options.fsOps ?? fs;
  const projectRoot = options.projectRoot ?? process.cwd();
  const resourcesDir = resolveElectronResourcesDir(electronExe, projectRoot);
  const legacyAppAsarPath = path.join(resourcesDir, 'app.asar');
  const defaultAppAsarPath = path.join(resourcesDir, 'default_app.asar');

  const legacyAppAsarStat = readPathStatus(legacyAppAsarPath, LEGACY_APP_ASAR_LABEL, fsOps);
  if (!legacyAppAsarStat) {
    return;
  }

  const defaultAppAsarStat = readPathStatus(defaultAppAsarPath, DEFAULT_APP_ASAR_LABEL, fsOps);
  if (!defaultAppAsarStat || !defaultAppAsarStat.isFile()) {
    throw new Error(
      `Refusing to remove legacy Electron dev app.asar without sibling regular file: ${DEFAULT_APP_ASAR_LABEL}`,
    );
  }

  if (!legacyAppAsarStat.isFile() && !legacyAppAsarStat.isSymbolicLink()) {
    throw new Error(
      `Refusing to remove unexpected legacy Electron dev app.asar target: ${LEGACY_APP_ASAR_LABEL}`,
    );
  }

  try {
    fsOps.unlinkSync(legacyAppAsarPath);
  } catch (error) {
    throw new Error(
      `Failed to remove legacy Electron dev app.asar before launch: ${LEGACY_APP_ASAR_LABEL} (${formatFsError(error)})`,
    );
  }
}

export function spawnElectronDevProcess<TProcess>({
  electronExe,
  tmpAppDir,
  devUserData,
  cwd,
  env,
  spawnFn,
  cleanupFn = cleanupLegacyElectronDevAppAsar,
}: SpawnElectronDevProcessOptions<TProcess>): TProcess {
  cleanupFn(electronExe);

  return spawnFn(electronExe, createElectronDevLaunchArgs(tmpAppDir), {
    stdio: 'inherit',
    cwd,
    env: {
      ...env,
      ELECTRON_RENDERER_URL: 'http://127.0.0.1:3000',
      ELECTRON_DEV_USER_DATA: devUserData,
    },
  });
}
