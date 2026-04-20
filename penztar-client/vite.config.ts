import { defineConfig } from 'vite';
import electron from 'vite-plugin-electron';
import { builtinModules } from 'node:module';
import path from 'node:path';
import fs from 'node:fs';
import { spawn, execSync, type ChildProcess } from 'node:child_process';

// All Node.js builtins + Electron must be external for the main process.
const nodeExternals = [
  'electron',
  'electron-log',
  'electron-log/main',
  'electron-updater',
  'sql.js',
  'better-sqlite3',
  'dotenv',
  'dotenv/config',
  // graceful-fs + serialport + nan - nativ dep-ek, nem bundle-olhatok
  'graceful-fs',
  'serialport', '@serialport/bindings-cpp',
  'nan', 'node-gyp-build',
  ...builtinModules,
  ...builtinModules.map((m) => `node:${m}`),
];

// A penztar-client-nek nincs saját renderer-je — a frontend-react build outputját tölti be.
// Ez a Vite config CSAK az electron main + preload buildelését végzi.
let electronDevProcess: ChildProcess | null = null;

export default defineConfig({
  plugins: [
    electron([
      {
        entry: 'electron/main.ts',
        onstart(_args) {
          // Electron bug #49034: require('electron') resolves to
          // node_modules/electron/index.js (string path) instead of the built-in
          // Electron API. Affects Electron 31+ on Windows.
          //
          // The built-in module ONLY works when loaded from inside an ASAR archive
          // (where node_modules/electron doesn't exist). So we create a minimal
          // ASAR from the build output, then launch electron pointing at it.
          const electronExe = path.resolve('node_modules/electron/dist/electron.exe');

          // Create a temporary app directory with just the essentials
          const tmpAppDir = path.resolve('.dev-app');
          const asarPath = path.resolve('node_modules/electron/dist/resources/app.asar');

          // Copy dist-electron + package.json into tmpAppDir
          if (fs.existsSync(tmpAppDir)) {
            fs.rmSync(tmpAppDir, { recursive: true, force: true });
          }
          fs.mkdirSync(tmpAppDir, { recursive: true });
          fs.mkdirSync(path.join(tmpAppDir, 'dist-electron'), { recursive: true });

          // Copy package.json
          fs.copyFileSync(
            path.resolve('package.json'),
            path.join(tmpAppDir, 'package.json')
          );

          // Copy all dist-electron files
          for (const file of fs.readdirSync(path.resolve('dist-electron'))) {
            fs.copyFileSync(
              path.join(path.resolve('dist-electron'), file),
              path.join(tmpAppDir, 'dist-electron', file)
            );
          }

          // Copy dist (frontend) if exists
          if (fs.existsSync(path.resolve('dist'))) {
            fs.cpSync(path.resolve('dist'), path.join(tmpAppDir, 'dist'), { recursive: true });
          }

          // Copy node_modules (except electron) for runtime deps
          const prodDeps = ['electron-log', 'electron-updater', 'qrcode', 'sql.js'];
          fs.mkdirSync(path.join(tmpAppDir, 'node_modules'), { recursive: true });
          for (const dep of prodDeps) {
            const src = path.resolve('node_modules', dep);
            const dest = path.join(tmpAppDir, 'node_modules', dep);
            if (fs.existsSync(src)) {
              fs.cpSync(src, dest, { recursive: true });
            }
          }
          // Copy transitive deps (flatten)
          const transitiveDeps = ['lazy-val', 'semver', 'lodash.isequal', 'js-yaml',
            'builder-util-runtime', 'sax', 'global-agent', 'roarr', 'serialize-error',
            'matcher', 'boolean', 'detect-node', 'es6-error',
            'globalthis', 'pngjs', 'dijkstrajs', 'encode-utf8'];
          for (const dep of transitiveDeps) {
            const src = path.resolve('node_modules', dep);
            const dest = path.join(tmpAppDir, 'node_modules', dep);
            if (fs.existsSync(src) && !fs.existsSync(dest)) {
              fs.cpSync(src, dest, { recursive: true });
            }
          }

          // Create ASAR
          try {
            execSync(`npx asar pack "${tmpAppDir}" "${asarPath}"`, { stdio: 'pipe' });
          } catch (e: unknown) {
            const message = e instanceof Error ? e.message : String(e);
            console.error('Failed to create ASAR:', message);
            // Fallback: use tmpAppDir directly
          }

          // Always stop previous Electron dev process to avoid profile/cache locks on Windows.
          if (electronDevProcess && !electronDevProcess.killed) {
            electronDevProcess.kill();
          }

          const devUserData = path.join(tmpAppDir, 'user-data');
          fs.mkdirSync(devUserData, { recursive: true });

          // Launch electron — it will find resources/app.asar automatically
          electronDevProcess = spawn(electronExe, [], {
            stdio: 'inherit',
            cwd: process.cwd(),
            env: {
              ...process.env,
              ELECTRON_RENDERER_URL: 'http://127.0.0.1:3000',
              ELECTRON_DEV_USER_DATA: devUserData,
            },
          });
          electronDevProcess.once('exit', () => {
            // Clean up
            try {
              fs.rmSync(tmpAppDir, { recursive: true, force: true });
            } catch {
              // Ignore temp cleanup failures on Windows dev cache locks.
            }
            electronDevProcess = null;
          });
        },
        vite: {
          build: {
            outDir: 'dist-electron',
            minify: false,
            rollupOptions: {
              external: nodeExternals,
            },
          },
        },
      },
      {
        entry: 'electron/preload.ts',
        onstart(args) {
          args.reload();
        },
        vite: {
          build: {
            outDir: 'dist-electron',
            minify: false,
            rollupOptions: {
              external: nodeExternals,
            },
          },
        },
      },
    ]),
  ],
});
