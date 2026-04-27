/**
 * Post-build fix: patch the bundled main.js to destructure require("electron").
 * 
 * In Electron 41 (Node.js 24), the internal `require('electron')` module
 * returns an object that works with destructuring but NOT as a plain
 * namespace assignment. The Rolldown bundler generates:
 *   let electron = require("electron");
 * which should be:
 *   let electron = require("electron"); // namespace
 * then destructure app, BrowserWindow etc. from it.
 * 
 * But the Electron internal module uses getters/proxies that only work
 * with property access from the original object. The Rolldown `let electron`
 * doesn't preserve this properly.
 * 
 * Fix: Replace the namespace require with explicit destructuring that
 * creates a proper namespace object.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const mainJs = join(__dirname, '..', 'dist-electron', 'main.js');

// Audit-iter3 P0 (CodeQL js/file-system-race fix, 2026-04-27):
// `existsSync` + `readFileSync` TOCTOU race volt - a check es use kozt a fajl
// torolheto vagy modosithato. Egyenes try-readFileSync race-mentes: ha hianyzik,
// ENOENT-tel megall, NEM "exists check + read" ket lepesben.
let content;
try {
  content = readFileSync(mainJs, 'utf8');
} catch (e) {
  if (e.code === 'ENOENT') {
    console.error('❌ dist-electron/main.js not found');
    process.exit(1);
  }
  throw e;
}

const needle = 'let electron = require("electron");';
const replacement = `let electron = (() => {
  const _e = require("electron");
  // Electron 41 internal module fix: create a proper namespace object
  // by eagerly reading all properties from the module's getter-based exports.
  if (typeof _e === "object" && _e !== null) {
    const ns = {};
    for (const key of Object.getOwnPropertyNames(_e)) {
      try { ns[key] = _e[key]; } catch {}
    }
    // Also copy Symbol.toStringTag if present
    const desc = Object.getOwnPropertyDescriptor(_e, Symbol.toStringTag);
    if (desc) Object.defineProperty(ns, Symbol.toStringTag, desc);
    return ns;
  }
  return _e;
})();`;

if (content.includes(needle)) {
  content = content.replace(needle, replacement);
  writeFileSync(mainJs, content, 'utf8');
  console.log('✅ Electron require patched in dist-electron/main.js');
} else {
  console.log('⚠️ Pattern not found — main.js may already be patched');
}
