import { defineConfig, loadEnv } from 'vite';
import electron from 'vite-plugin-electron';
import { builtinModules } from 'node:module';
import path from 'node:path';
import fs from 'node:fs';
import { spawn, type ChildProcess } from 'node:child_process';
import { createElectronDevLaunchArgs, createElectronDevServerConfig } from './vite-watch-config';

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
  'serialport',
  '@serialport/bindings-cpp',
  'nan',
  'node-gyp-build',
  ...builtinModules,
  ...builtinModules.map((m) => `node:${m}`),
];

// A penztar-client-nek nincs saját renderer-je — a frontend-react build outputját tölti be.
// Ez a Vite config CSAK az electron main + preload buildelését végzi.
let electronDevProcess: ChildProcess | null = null;
// Race-condition guard: mindkét entry (main + preload) onstart-ja csak akkor indítja
// az Electron-t, amikor mindkét build-output fájl létezik a dist-electron-ban.
// Korábban bug: onstart lefutott amint az első chunk kiíródott → ASAR csak a sqlite
// chunkot tartalmazta, a main.js hiányzott → "Cannot find module main.js".
function launchElectronIfReady() {
  const distElectron = path.resolve('dist-electron');
  const mainJs = path.join(distElectron, 'main.js');
  const preloadJs = path.join(distElectron, 'preload.js');
  if (!fs.existsSync(mainJs) || !fs.existsSync(preloadJs)) {
    return; // Még nincs kész mindkét entry — a következő onstart majd elindítja
  }
  // Idempotency: ha mar fut egy electronDevProcess, NE indits ujat (hirtelen kill+spawn roncsol)
  // A kezdeti inditas kesziti elo a dev appot; HMR reload-ok a preload-on at futnak.
  if (electronDevProcess && !electronDevProcess.killed) {
    return;
  }

  const electronExe = path.resolve('node_modules/electron/dist/electron.exe');
  const tmpAppDir = path.resolve('.dev-app');

  if (fs.existsSync(tmpAppDir)) {
    fs.rmSync(tmpAppDir, { recursive: true, force: true });
  }
  fs.mkdirSync(tmpAppDir, { recursive: true });
  fs.mkdirSync(path.join(tmpAppDir, 'dist-electron'), { recursive: true });
  fs.copyFileSync(path.resolve('package.json'), path.join(tmpAppDir, 'package.json'));
  for (const file of fs.readdirSync(distElectron)) {
    fs.copyFileSync(path.join(distElectron, file), path.join(tmpAppDir, 'dist-electron', file));
  }
  if (fs.existsSync(path.resolve('dist'))) {
    fs.cpSync(path.resolve('dist'), path.join(tmpAppDir, 'dist'), { recursive: true });
  }
  const prodDeps = [
    'electron-log',
    'electron-updater',
    'qrcode',
    'sql.js',
    'serialport',
    '@serialport/bindings-cpp',
    'graceful-fs',
  ];
  fs.mkdirSync(path.join(tmpAppDir, 'node_modules'), { recursive: true });
  for (const dep of prodDeps) {
    const src = path.resolve('node_modules', dep);
    const dest = path.join(tmpAppDir, 'node_modules', dep);
    if (fs.existsSync(src)) fs.cpSync(src, dest, { recursive: true });
  }
  const walkedDeps = new Set<string>(prodDeps);
  const walkDep = (pkgName: string) => {
    const pkgJsonPath = path.resolve('node_modules', pkgName, 'package.json');
    if (!fs.existsSync(pkgJsonPath)) return;
    try {
      const pkg = JSON.parse(fs.readFileSync(pkgJsonPath, 'utf-8')) as {
        dependencies?: Record<string, string>;
      };
      for (const dep of Object.keys(pkg.dependencies ?? {})) {
        if (!walkedDeps.has(dep)) {
          walkedDeps.add(dep);
          walkDep(dep);
        }
      }
    } catch {
      /* pkg.json parse hiba - skip */
    }
  };
  prodDeps.forEach(walkDep);
  for (const dep of walkedDeps) {
    if (prodDeps.includes(dep)) continue;
    const src = path.resolve('node_modules', dep);
    const dest = path.join(tmpAppDir, 'node_modules', dep);
    if (fs.existsSync(src) && !fs.existsSync(dest)) {
      fs.cpSync(src, dest, { recursive: true });
    }
  }

  if (electronDevProcess && !electronDevProcess.killed) {
    electronDevProcess.kill();
  }

  const devUserData = path.resolve('.dev-user-data');
  fs.mkdirSync(devUserData, { recursive: true });

  electronDevProcess = spawn(electronExe, createElectronDevLaunchArgs(tmpAppDir), {
    stdio: 'inherit',
    cwd: process.cwd(),
    env: {
      ...process.env,
      ELECTRON_RENDERER_URL: 'http://127.0.0.1:3000',
      ELECTRON_DEV_USER_DATA: devUserData,
    },
  });
  electronDevProcess.once('exit', () => {
    try {
      fs.rmSync(tmpAppDir, { recursive: true, force: true });
    } catch {
      /* cleanup race on Windows - ignore */
    }
    electronDevProcess = null;
  });
}

export default defineConfig(({ mode }) => {
  // Load .env.<mode> -> Object<string,string> with all VITE_* keys (and others without prefix filter).
  // Build-time inline: a `define` opcion keresztul a `process.env.VITE_*` referenciakat a main + preload
  // bundle-jebe inline-oljuk (a vite-plugin-electron nem futtat dotenv-et a child config-ben automatikusan).
  // Ez kell pl. a Google Desktop OAuth client ID + secret build-time inlinejehez.
  const env = loadEnv(mode, process.cwd(), '');
  const electronDefine: Record<string, string> = {};
  // Csak a `VITE_*` prefix-szel rendelkezo env-eket terjesszuk a main process-re (kovetjuk a Vite konvenciot).
  for (const [key, value] of Object.entries(env)) {
    if (key.startsWith('VITE_') || key === 'NODE_ENV') {
      electronDefine[`process.env.${key}`] = JSON.stringify(value);
    }
  }

  return {
    server: createElectronDevServerConfig(),
    plugins: [
      electron([
        {
          entry: 'electron/main.ts',
          onstart(_args) {
            // main.ts valtozasnal full Electron-restart kell (a preloadJs maradhat).
            // Eloszor leallitjuk a regi process-t, hogy az idempotency-guard ne skip-eljen.
            if (electronDevProcess && !electronDevProcess.killed) {
              electronDevProcess.kill();
              electronDevProcess = null;
            }
            launchElectronIfReady();
          },
          vite: {
            define: electronDefine,
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
            // Elso inditasnal (main onstart elott futhat) elinditjuk az Electron-t, ha
            // mindket fajl mar letezik. Kesobbi HMR preload-valtozasoknal args.reload()
            // frissiti a renderer-t ujrainditas nelkul.
            if (!electronDevProcess || electronDevProcess.killed) {
              launchElectronIfReady();
            } else {
              args.reload();
            }
          },
          vite: {
            define: electronDefine,
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
  };
});
