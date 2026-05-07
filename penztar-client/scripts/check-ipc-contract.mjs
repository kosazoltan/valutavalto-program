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

function extractObjectBodyAfterAssignment(content, exportName) {
  const assignment = new RegExp(`export\\s+const\\s+${exportName}\\s*(?::[^=]+)?=\\s*\\{`, 'm').exec(content);
  if (!assignment) {
    return null;
  }

  let depth = 1;
  const start = assignment.index + assignment[0].length;
  for (let index = start; index < content.length; index += 1) {
    const char = content[index];
    if (char === '{') {
      depth += 1;
    } else if (char === '}') {
      depth -= 1;
      if (depth === 0) {
        return content.slice(start, index);
      }
    }
  }

  return null;
}

function collectIpcChannelConstants(filePath) {
  if (!fs.existsSync(filePath)) {
    return new Map();
  }

  const constants = new Map();
  const content = readText(filePath);
  const objectBody = extractObjectBodyAfterAssignment(content, 'IPC_CHANNELS');

  if (!objectBody) {
    return constants;
  }

  for (const match of objectBody.matchAll(/([A-Z0-9_]+)\s*:\s*['"`]([^'"`]+)['"`](?:\s+as\s+const)?/g)) {
    constants.set(match[1], match[2]);
  }

  return constants;
}

function resolveIpcChannelArgument(argument, constants, missingConstantReferences) {
  const normalizedArgument = argument.trim();
  const literalMatch = /^['"`]([^'"`]+)['"`]/.exec(normalizedArgument);

  if (literalMatch) {
    return literalMatch[1];
  }

  const constantMatch = /^IPC_CHANNELS\.([A-Z0-9_]+)/.exec(normalizedArgument);
  if (!constantMatch) {
    return null;
  }

  const constantName = constantMatch[1];
  const channel = constants.get(constantName);
  if (!channel) {
    missingConstantReferences.add(`IPC_CHANNELS.${constantName}`);
    return null;
  }

  return channel;
}

function collectIpcChannelsFromCalls(text, callRegex, constants, missingConstantReferences) {
  const channels = new Set();

  for (const match of text.matchAll(callRegex)) {
    const channel = resolveIpcChannelArgument(match[1], constants, missingConstantReferences);
    if (channel) {
      channels.add(channel);
    }
  }

  return channels;
}

function addSetValues(targetSet, sourceSet) {
  for (const value of sourceSet) {
    targetSet.add(value);
  }
}

function hasIpcChannelConstantReference(content) {
  return /\bIPC_CHANNELS\.[A-Z0-9_]+\b/.test(content);
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
const electronFiles = collectTsFiles(electronDir);
const electronFileContents = electronFiles.map((filePath) => readText(filePath));
const ipcChannelConstants = collectIpcChannelConstants(sharedIpcFile);
const usesIpcChannelConstants =
  hasIpcChannelConstantReference(preloadContent) ||
  electronFileContents.some((content) => hasIpcChannelConstantReference(content));

if (usesIpcChannelConstants && ipcChannelConstants.size === 0) {
  logger.error('ERROR: IPC_CHANNELS is referenced, but no IPC_CHANNELS constants could be extracted.');
  proc.exit(1);
}

const missingConstantReferences = new Set();
const invokedChannels = collectIpcChannelsFromCalls(
  preloadContent,
  /\b(?:[A-Za-z_$][\w$]*\.)?ipcRenderer\.invoke\(\s*([^,\n\r)]+)/g,
  ipcChannelConstants,
  missingConstantReferences,
);

const handledChannels = new Set();

for (const content of electronFileContents) {
  addSetValues(
    handledChannels,
    collectIpcChannelsFromCalls(
      content,
      /\b(?:[A-Za-z_$][\w$]*\.)?ipcMain\.handle(?:Once)?\(\s*([^,\n\r)]+)/g,
      ipcChannelConstants,
      missingConstantReferences,
    ),
  );
}

if (missingConstantReferences.size > 0) {
  logger.error('\nERROR: IPC_CHANNELS references without extracted constants:');
  for (const reference of missingConstantReferences) {
    logger.error(`  - ${reference}`);
  }
  proc.exit(1);
}

const missingHandlers = [...invokedChannels].filter((channel) => !handledChannels.has(channel));
const unusedHandlers = [...handledChannels].filter((channel) => !invokedChannels.has(channel));
const ignoredUnusedHandlers = unusedHandlers.filter((channel) => internalOnlyHandlers.has(channel));
const actionableUnusedHandlers = unusedHandlers.filter((channel) => !internalOnlyHandlers.has(channel));

logger.log('IPC contract check');
if (usesIpcChannelConstants) {
  logger.log(`- IPC_CHANNELS constants extracted: ${ipcChannelConstants.size}`);
}
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
