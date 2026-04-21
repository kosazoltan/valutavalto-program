#!/usr/bin/env node
/**
 * Egyseges log-gyujto script — minden komponenst egy mappaba gyujt.
 * Futtatas: node scripts/collect-logs.mjs
 *
 * Kimenet: /tmp/logs/
 *   backend.log           - Spring Boot
 *   electron-main.log     - Electron main process (electron-log)
 *   electron-renderer.log - Electron renderer console (main folyamatbol)
 *   frontend-vite.log     - Webes Vite (preview_start stdout-ja)
 *   browser-console.log   - Preview browser console hibak (periodic snapshot)
 *
 * Strategia:
 * 1. A backend + electron mar a /tmp/backend.log + /tmp/penztar-dev.log-ba ir,
 *    csak symlink-eljuk (fallback: copy).
 * 2. A preview Vite stdout nem elerheto fajlkent - a preview_logs MCP tool
 *    olvassa, ezt beiranyitjuk egy fajlba.
 * 3. A browser console-t 10s-enkent snapshot-oljuk a preview_console_logs-bol.
 *
 * Codex AI P2 fix: Unix-only shell calls -> Node fs API cross-platform.
 */

import { existsSync, symlinkSync, writeFileSync, mkdirSync, rmSync, copyFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

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
    // Codex P2 + Sourcery: existsSync(dangling_symlink) = false -> rm skipped ->
    // symlinkSync EEXIST fail. Unconditional rmSync (force:true) handles both
    // missing and dangling symlink cases.
    rmSync(dst, { force: true });
    symlinkSync(src, dst);
    console.log(`[collect-logs] symlink: ${dst} -> ${src}`);
  } catch (e) {
    console.warn(`[collect-logs] symlink failed, fallback copy: ${dst}`, e.message);
    try {
      copyFileSync(src, dst);
    } catch (copyErr) {
      console.error(`[collect-logs] copy fallback also failed: ${dst}`, copyErr.message);
    }
  }
}

console.log('\n[collect-logs] READY. Agregalt fajlok:');
try {
  const files = readdirSync(LOG_DIR);
  for (const f of files) {
    const full = join(LOG_DIR, f);
    try {
      const st = statSync(full);
      console.log(`  ${f}\t${st.size} bytes\t${st.mtime.toISOString()}`);
    } catch {
      console.log(`  ${f}\t(stat failed)`);
    }
  }
} catch (e) {
  console.warn('[collect-logs] listing failed:', e.message);
}

console.log('\nHasznalhatod:');
console.log(`  tail -F ${LOG_DIR}/*.log`);
console.log(`  grep -aE "ERROR|WARN" ${LOG_DIR}/*.log`);