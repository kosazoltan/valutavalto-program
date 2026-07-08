// Shim that ensures require('electron') returns the built-in Electron module
// rather than the npm package's path-exporting index.js.
//
// In Electron's main process, the built-in 'electron' module is available
// via process.electronBinding, but CJS require() finds node_modules first.
// This shim is used as a Vite resolve alias so the bundled output imports
// this file (which is then kept external), and at runtime we patch require
// to skip node_modules for the 'electron' specifier.

const Module = require('module');

// Save the real electron npm package path so we can skip it
const npmElectronPath = require.resolve('electron');

// Temporarily override resolution for 'electron' to skip the npm package
const origResolve = Module._resolveFilename;
Module._resolveFilename = function (request, parent, isMain, options) {
  if (request === 'electron' || request === 'electron/main') {
    // Force Electron's built-in module by returning just 'electron'
    // which the Electron binary intercepts at the c._load level
    return 'electron';
  }
  return origResolve.call(this, request, parent, isMain, options);
};

// Clear any cached resolution of the npm electron package
delete require.cache[npmElectronPath];

// Now require('electron') should hit the built-in
const electron = require('electron');

// Restore original resolution
Module._resolveFilename = origResolve;

module.exports = electron;
