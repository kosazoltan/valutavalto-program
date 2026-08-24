import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

export const LOCAL_BACKEND_CONFIG_RELATIVE =
  'BestChange/config/application-local.properties' as const;

export const FK091_PROPERTY_LINE = 'evening.closing.artifact-success-enabled=true' as const;

const PROPERTY_KEY_PATTERN = /^evening\.closing\.artifact-success-enabled=/m;
const PROPERTY_FALSE_PATTERN = /^evening\.closing\.artifact-success-enabled=false\s*$/m;
const PROPERTY_TRUE_PATTERN = /^evening\.closing\.artifact-success-enabled=true\s*$/m;

export function resolveLocalBackendConfigPath(programData: string): string {
  return path.join(programData, 'config', 'application-local.properties');
}

/**
 * FK-091: meglévő pénztár gépek — idempotens property patch a külső config fájlban.
 * Pure függvény: könnyen tesztelhető.
 */
export function ensureFk091ArtifactSuccessEnabled(configText: string): {
  updated: boolean;
  config: string;
} {
  if (PROPERTY_TRUE_PATTERN.test(configText)) {
    return { updated: false, config: configText };
  }
  if (PROPERTY_FALSE_PATTERN.test(configText)) {
    return {
      updated: true,
      config: configText.replace(
        PROPERTY_FALSE_PATTERN,
        'evening.closing.artifact-success-enabled=true',
      ),
    };
  }
  if (!PROPERTY_KEY_PATTERN.test(configText)) {
    const trimmed = configText.replace(/\s+$/, '');
    const separator = trimmed.length === 0 ? '' : '\n';
    return {
      updated: true,
      config: `${trimmed}${separator}${FK091_PROPERTY_LINE}\n`,
    };
  }
  return { updated: false, config: configText };
}

export interface LocalBackendConfigMigrationDeps {
  platform: NodeJS.Platform;
  programData: string;
  readFile: (filePath: string) => string;
  writeFile: (filePath: string, content: string) => void;
  fileExists: (filePath: string) => boolean;
  restartBackendService: () => Promise<void>;
  log: {
    info: (message: string, ...args: unknown[]) => void;
    warn: (message: string, ...args: unknown[]) => void;
  };
}

export async function applyLocalBackendConfigMigration(
  deps: LocalBackendConfigMigrationDeps,
): Promise<void> {
  if (deps.platform !== 'win32') {
    return;
  }

  const configPath = resolveLocalBackendConfigPath(deps.programData);
  if (!deps.fileExists(configPath)) {
    return;
  }

  const current = deps.readFile(configPath);
  const { updated, config } = ensureFk091ArtifactSuccessEnabled(current);
  if (!updated) {
    deps.log.info('[FK-091] Lokális backend config: artifact-success már engedélyezve');
    return;
  }

  deps.writeFile(configPath, config);
  deps.log.info('[FK-091] Lokális backend config frissítve, BestChange-Backend újraindítás...');
  try {
    await deps.restartBackendService();
    deps.log.info('[FK-091] BestChange-Backend újraindítva (artifact-success-enabled=true)');
  } catch (error) {
    deps.log.warn('[FK-091] Backend újraindítás sikertelen (nem kritikus):', error);
  }
}

function runNetCommand(action: 'stop' | 'start', serviceName: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn('net', [action, serviceName], {
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let stderr = '';
    child.stderr?.on('data', (chunk: Buffer) => {
      stderr += chunk.toString('utf8');
    });
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new Error(`net ${action} ${serviceName} failed (${code}): ${stderr.trim()}`));
    });
  });
}

export async function restartBestChangeBackendService(): Promise<void> {
  await runNetCommand('stop', 'BestChange-Backend');
  await runNetCommand('start', 'BestChange-Backend');
}

export async function migrateLocalBackendConfigOnStartup(log: {
  info: (message: string, ...args: unknown[]) => void;
  warn: (message: string, ...args: unknown[]) => void;
}): Promise<void> {
  const programData = process.env.ProgramData;
  if (!programData) {
    return;
  }

  await applyLocalBackendConfigMigration({
    platform: process.platform,
    programData,
    readFile: (filePath) => fs.readFileSync(filePath, 'utf8'),
    writeFile: (filePath, content) => fs.writeFileSync(filePath, content, 'utf8'),
    fileExists: (filePath) => fs.existsSync(filePath),
    restartBackendService: restartBestChangeBackendService,
    log,
  });
}
