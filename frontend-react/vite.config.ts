/// <reference types="vitest/config" />
import { defineConfig, type UserConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import type { InlineConfig } from 'vitest/node'

// https://vitejs.dev/config/
const config: UserConfig & { test: InlineConfig } = {
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
    css: true,
    exclude: ['e2e/**', 'node_modules/**', 'dist/**'],
  },
  // API URL beállítása build időben
  envPrefix: 'VITE_',
  // Disable Vite error overlay (hide vite-error-overlay element)
  clearScreen: false,
}

export default defineConfig(config)
