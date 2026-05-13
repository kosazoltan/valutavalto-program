import { defineConfig, loadEnv } from 'vite'
import electron from 'vite-plugin-electron'
import { builtinModules } from 'node:module'
import path from 'node:path'

const nodeExternals = [
  'electron',
  'electron-log',
  'electron-log/main',
  ...builtinModules,
  ...builtinModules.map((moduleName) => `node:${moduleName}`),
]

export default defineConfig(({ mode }) => {
  const repoEnv = loadEnv(mode, path.resolve(process.cwd(), '..'), '')
  const localEnv = loadEnv(mode, process.cwd(), '')
  const env = { ...repoEnv, ...localEnv }
  const electronDefine: Record<string, string> = {}

  for (const key of [
    'NODE_ENV',
    'VITE_GOOGLE_DESKTOP_CLIENT_ID',
    'VITE_GOOGLE_DESKTOP_CLIENT_SECRET',
    'GOOGLE_DESKTOP_CLIENT_ID',
    'GOOGLE_DESKTOP_CLIENT_SECRET',
  ]) {
    const value = env[key]
    if (value !== undefined) {
      electronDefine[`process.env.${key}`] = JSON.stringify(value)
    }
  }

  return {
    plugins: [
      electron([
        {
          entry: 'electron/main.ts',
          onstart(args) {
            args.startup()
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
            args.reload()
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
  }
})
