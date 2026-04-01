/**
 * patch-electron-dev.mjs
 * 
 * Patches node_modules/electron so that require('electron') in the Electron
 * main process resolves to the built-in module instead of the npm package's
 * path-exporting index.js.
 *
 * The problem: Electron 41's c._load intercept loses to Node 24's CJS
 * Module._resolveFilename which finds node_modules/electron/index.js first.
 * That file exports the electron.exe path (a string), not the API.
 *
 * Fix: Replace index.js with a stub that returns the string path ONLY when
 * NOT running inside the Electron binary (for the vite-plugin-electron
 * startup() function that needs the path). When running inside Electron
 * (process.versions.electron exists AND process.type is defined OR we can
 * detect the main process), we delete ourselves from cache and let the
 * built-in module resolve.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const electronPkgDir = path.resolve(__dirname, '../node_modules/electron');
const indexPath = path.join(electronPkgDir, 'index.js');
const backupPath = path.join(electronPkgDir, 'index.js.original');

// Backup original if not already done
if (!fs.existsSync(backupPath)) {
  fs.copyFileSync(indexPath, backupPath);
  console.log('[patch-electron-dev] Backed up original index.js');
}

const patchedContent = `// PATCHED by patch-electron-dev.mjs for dev mode compatibility
const fs = require('fs');
const path = require('path');

// Check if we're running inside the Electron binary
if (process.versions && process.versions.electron) {
  // We ARE inside Electron — the built-in 'electron' module should be used.
  // Delete this module from cache so next require('electron') can find the built-in.
  // But first, we need to make the built-in discoverable by removing ourselves.
  const Module = require('module');
  const myPath = __filename;
  
  // Override _resolveFilename to intercept 'electron' and return a sentinel
  const origResolve = Module._resolveFilename;
  Module._resolveFilename = function(request, parent, isMain, options) {
    if (request === 'electron') {
      // Return our own path — but we'll handle it in _load
      return myPath;
    }
    return origResolve.call(this, request, parent, isMain, options);
  };
  
  // Override _load at this level to return electron internals
  // Electron registers its modules in the electron/js2c/* namespace
  // and the 'electron' main module is assembled from those.
  // We can access it via require('electron/js2c/browser_init') but that's internal.
  
  // Simplest: just re-export what Electron's internal init makes available
  // In Electron main process, process.electronBinding exists or we can get
  // the module from the Electron internals.
  
  // Actually the cleanest way: the Electron binary's c._load checks if the
  // filename matches certain patterns. Let's just make require('electron')
  // work by using the Module._cache trick:
  
  // Step 1: Remove our entry from Module._cache
  delete require.cache[myPath];
  
  // Step 2: The c._load in electron/js2c/node_init intercepts based on the
  // request string. If request === 'electron', it returns the built-in.
  // But Module._resolveFilename resolves it to THIS file first.
  // So we need to prevent resolution to this file.
  
  // Step 3: Rename/remove ourselves temporarily — not practical.
  // Instead: override _resolveFilename to throw for 'electron',
  // then the c._load fallback should catch it.
  
  // Actually, let's look at what Electron's c._load does:
  // It wraps Module._load and checks: if request starts with 'electron/' 
  // or request === 'electron', it returns the built-in module.
  // BUT this happens AFTER _resolveFilename — and if _resolveFilename
  // already resolved to a file, _load uses that file path, not the request.
  
  // The real fix: make _resolveFilename NOT find us for 'electron'.
  Module._resolveFilename = function(request, parent, isMain, options) {
    if (request === 'electron') {
      // Throw MODULE_NOT_FOUND so that c._load's fallback kicks in
      const err = new Error("Cannot find module 'electron'");
      err.code = 'MODULE_NOT_FOUND';
      throw err;
    }
    return origResolve.call(this, request, parent, isMain, options);
  };
  
  // Now try requiring electron — c._load should intercept the error
  // and return the built-in module
  try {
    const electronInternal = require('electron');
    // Restore original resolver
    Module._resolveFilename = origResolve;
    // Cache ourselves as the electron module for future requires
    if (require.cache[myPath]) {
      require.cache[myPath].exports = electronInternal;
    }
    module.exports = electronInternal;
  } catch(e) {
    // Restore and fall through to path export
    Module._resolveFilename = origResolve;
    module.exports = getElectronPath();
  }
} else {
  // NOT inside Electron — export the path (for vite-plugin-electron startup)
  module.exports = getElectronPath();
}

function getElectronPath() {
  const pathFile = path.join(__dirname, 'path.txt');
  let executablePath;
  if (fs.existsSync(pathFile)) {
    executablePath = fs.readFileSync(pathFile, 'utf-8');
  }
  if (process.env.ELECTRON_OVERRIDE_DIST_PATH) {
    return path.join(process.env.ELECTRON_OVERRIDE_DIST_PATH, executablePath || 'electron');
  }
  if (executablePath) {
    return path.join(__dirname, 'dist', executablePath);
  } else {
    throw new Error('Electron failed to install correctly');
  }
}
`;

fs.writeFileSync(indexPath, patchedContent, 'utf-8');
console.log('[patch-electron-dev] Patched node_modules/electron/index.js for dev mode');
