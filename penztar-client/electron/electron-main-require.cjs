// Electron main process require wrapper.
// When running inside the Electron binary, `require('electron')` may incorrectly
// resolve to node_modules/electron/index.js (which exports the exe path string)
// instead of the built-in Electron module. This wrapper detects that case and
// falls back to the internal binding.
let electron;
try {
  electron = require('electron');
  // If we got a string (the exe path) instead of the real module, it means
  // node_modules resolution won over the built-in module.
  if (typeof electron === 'string' || typeof electron.app === 'undefined') {
    // Use Electron's internal module directly via the module system hack:
    // Delete the node_modules cache entry so the built-in takes precedence.
    const resolvedPath = require.resolve('electron');
    delete require.cache[resolvedPath];
    // The built-in 'electron' module is registered by Electron itself and
    // should be found after removing the npm package from cache.
    // However, require.resolve will still find node_modules first.
    // Instead, use Module._resolveFilename override or process.electronBinding.

    // Direct approach: construct the electron module from bindings
    const binding = process._linkedBinding('electron_common_features');
    if (binding) {
      // Access the internal module loader
      const Module = require('module');
      const originalResolve = Module._resolveFilename;
      Module._resolveFilename = function (request, parent, isMain, options) {
        if (request === 'electron') {
          // Return the internal electron module path
          return 'electron';
        }
        return originalResolve.call(this, request, parent, isMain, options);
      };
      // Clear cache and re-require
      delete require.cache[resolvedPath];
      electron = require('electron');
      Module._resolveFilename = originalResolve;
    }
  }
} catch (e) {
  // Fallback
  electron = require('electron');
}

module.exports = electron;
