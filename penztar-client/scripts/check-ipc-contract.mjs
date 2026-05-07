import fs from 'node:fs';
import path from 'node:path';

const proc = globalThis.process;
const logger = globalThis.console;

if (!proc || !logger) {
  throw new Error('Node globals are not available in this runtime.');
}

const rootDir = proc.cwd();
const preloadFile = path.join(rootDir, 'electron', 'preload.ts');
const electronDir = path.join(rootDir, 'electron');
const sharedIpcFile = path.join(rootDir, '..', 'packages', 'shared-ipc', 'src', 'index.ts');
// Belső sync handler whitelist — ezek nem a preload-on keresztül futnak,
// hanem a sync-engine / sync-queue IPC dispatcher közvetlenül hívja meg őket
// a főfolyamaton belül. A check:ipc ezért nem warn-olja őket hiányzó preload
// invoke miatt.
const internalOnlyHandlers = new Set([
  'mark-transaction-synced',
  'mark-conversion-synced',
  'mark-bank-transaction-synced',
  'mark-storno-synced',
]);

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function collectTsFiles(dir) {
  const out = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...collectTsFiles(fullPath));
      continue;
    }

    if (entry.isFile() && fullPath.endsWith('.ts')) {
      out.push(fullPath);
    }
  }

  return out;
}

function extractMatches(text, regex) {
  const set = new Set();
  for (const match of text.matchAll(regex)) {
    set.add(match[1]);
  }
  return set;
}

function collectIpcChannelConstants(filePath) {
  if (!fs.existsSync(filePath)) {
    return new Map();
  }

  const constants = new Map();
  const content = readText(filePath);
  const objectMatch = content.match(/export\s+const\s+IPC_CHANNELS\s*=\s*\{([\s\S]*?)\}\s*satisfies/);

  if (!objectMatch) {
    return constants;
  }

  for (const match of objectMatch[1].matchAll(/([A-Z0-9_]+)\s*:\s*['"`]([^'"`]+)['"`]/g)) {
    constants.set(match[1], match[2]);
  }

  return constants;
}

if (!fs.existsSync(preloadFile)) {
  logger.error('ERROR: electron/preload.ts not found.');
  proc.exit(1);
}

if (!fs.existsSync(electronDir)) {
  logger.error('ERROR: electron directory not found.');
  proc.exit(1);
}

const preloadContent = readText(preloadFile);
const invokedChannels = extractMatches(
  preloadContent,
  /ipcRenderer\.invoke\(\s*['"`]([^'"`]+)['"`]/g,
);
const ipcChannelConstants = collectIpcChannelConstants(sharedIpcFile);

for (const match of preloadContent.matchAll(/ipcRenderer\.invoke\(\s*IPC_CHANNELS\.([A-Z0-9_]+)/g)) {
  const channel = ipcChannelConstants.get(match[1]);
  if (channel) {
    invokedChannels.add(channel);
  }
}

const electronFiles = collectTsFiles(electronDir);
const handledChannels = new Set();

for (const filePath of electronFiles) {
  const content = readText(filePath);
  const matches = extractMatches(content, /ipcMain\.handle\(\s*['"`]([^'"`]+)['"`]/g);
  for (const channel of matches) {
    handledChannels.add(channel);
  }
}

const missingHandlers = [...invokedChannels].filter((channel) => !handledChannels.has(channel));
const unusedHandlers = [...handledChannels].filter((channel) => !invokedChannels.has(channel));
const ignoredUnusedHandlers = unusedHandlers.filter((channel) => internalOnlyHandlers.has(channel));
const actionableUnusedHandlers = unusedHandlers.filter((channel) => !internalOnlyHandlers.has(channel));

logger.log('IPC contract check');
logger.log(`- Invoked channels (preload): ${invokedChannels.size}`);
logger.log(`- Handled channels (main/electron): ${handledChannels.size}`);

if (missingHandlers.length > 0) {
  logger.error('\nERROR: Missing ipcMain.handle for these channels:');
  for (const channel of missingHandlers) {
    logger.error(`  - ${channel}`);
  }
  proc.exit(1);
}

if (ignoredUnusedHandlers.length > 0) {
  logger.log(`\nInfo: belső használatú handler(ek) kihagyva a warningból: ${ignoredUnusedHandlers.join(', ')}`);
}

if (actionableUnusedHandlers.length > 0) {
  logger.warn('\nWARN: Handlers without preload invoke (review if intentional):');
  for (const channel of actionableUnusedHandlers) {
    logger.warn(`  - ${channel}`);
  }
}

logger.log('\nOK: Every preload invoke channel has a registered ipcMain.handle.');
