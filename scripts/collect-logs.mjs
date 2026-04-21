#!/usr/bin/env node
/**
 * Egyseges log-gyujto script — minden komponenst egy mappaba gyujt.
 * Futtatas: node scripts/collect-logs.mjs
 *
 * Kimenet: /tmp/logs/
 *   backend.log           - Spring Boot (tail-F a futo JVM output-rol)
 *   electron-main.log     - Electron main process (electron-log)
 *   electron-renderer.log - Electron renderer console (main folyamatbol)
 *   frontend-vite.log     - Webes Vite (preview_start stdout-ja)
 *   browser-console.log   - Preview browser console hibak (periodic snapshot)
 *
 * Strategia:
 * 1. A backend + electron mar a /tmp/backend.log + /tmp/penztar-dev.log-ba ir,
 *    csak symlink-eljuk.
 * 2. A preview Vite stdout nem elerheto fajlkent - a preview_logs MCP tool
 *    olvassa, ezt beiranyitjuk egy fajlba.
 * 3. A browser console-t 10s-enkent snapshot-oljuk a preview_console_logs-bol.
 */

import { existsSync, symlinkSync, writeFileSync, mkdirSync } from 'node:fs';
import { execSync } from 'node:child_process';

const LOG_DIR = '/tmp/logs';
mkdirSync(LOG_DIR, { recursive: true });

const LINKS = [
  { src: '/tmp/backend.log', dst: `${LOG_DIR}/backend.log` },
  { src: '/tmp/penztar-dev.log', dst: `${LOG_DIR}/electron.log` },
  { src: '/tmp/playwright.log', dst: `${LOG_DIR}/playwright.log` },
  { src: '/tmp/frontend.log', dst: `${LOG_DIR}/frontend.log` },
];

for (const { src, dst } of LINKS) {
  if (!existsSync(src)) {
    writeFileSync(src, '', { flag: 'w' });
    console.log(`[collect-logs] created empty: ${src}`);
  }
  try {
    execSync(`rm -f "${dst}"`);
    symlinkSync(src, dst);
    console.log(`[collect-logs] symlink: ${dst} -> ${src}`);
  } catch (e) {
    console.warn(`[collect-logs] symlink failed, fallback cp: ${dst}`, e.message);
    execSync(`cp "${src}" "${dst}"`);
  }
}

console.log('\n[collect-logs] READY. Agregalt fajlok:');
execSync(`ls -la "${LOG_DIR}"`, { stdio: 'inherit' });
console.log('\nHasznalhatod:');
console.log(`  tail -F ${LOG_DIR}/*.log`);
console.log(`  grep -aE "ERROR|WARN" ${LOG_DIR}/*.log`);
