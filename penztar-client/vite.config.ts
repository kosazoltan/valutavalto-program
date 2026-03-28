import { defineConfig } from 'vite';
import electron from 'vite-plugin-electron';
import { builtinModules } from 'node:module';

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
  ...builtinModules,
  ...builtinModules.map((m) => `node:${m}`),
];

// A penztar-client-nek nincs saját renderer-je — a frontend-react build outputját tölti be.
// Ez a Vite config CSAK az electron main + preload buildelését végzi.
export default defineConfig({
  plugins: [
    electron([
      {
        entry: 'electron/main.ts',
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
