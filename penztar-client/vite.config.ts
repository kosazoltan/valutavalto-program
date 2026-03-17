import { defineConfig } from 'vite';
import electron from 'vite-plugin-electron';

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
            rollupOptions: {
              external: ['better-sqlite3', 'sql.js'],
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
          },
        },
      },
    ]),
  ],
});
