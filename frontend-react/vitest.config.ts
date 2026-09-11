/// <reference types="vitest/config" />
import { defineConfig, type UserConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import type { InlineConfig } from 'vitest/node'

const config: UserConfig & { test: InlineConfig } = {
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3003,
    proxy: {
      '/api': {
        target: 'https://excvaluta.com',
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
    exclude: ['e2e/**', 'playwright/**', 'node_modules/**', 'dist/**'],
    // FK: diff-coverage gate — a CI a MEGVÁLTOZOTT sorokra méri a lefedettséget (diff-cover),
    // nem a teljes repóra (a legacy adósság nem blokkolhat). lcov+cobertura a diff-cover-hez.
    coverage: {
      provider: 'v8',
      reporter: ['text-summary', 'lcov', 'cobertura'],
      reportsDirectory: './coverage',
      // #1748: `all` + `include` is REQUIRED for the blocking diff-coverage gate. Without
      // it v8 only reports files some test imported, so a brand-new module that NO test
      // touches is absent from the cobertura report entirely - diff-cover then treats it
      // as "no lines with coverage information" and PASSES, letting the completely
      // untested case slip through the very threshold meant to catch it (verified: a
      // never-imported probe file did not appear in the report).
      all: true,
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'e2e/**',
        'playwright/**',
        'node_modules/**',
        'dist/**',
        '**/*.test.{ts,tsx}',
        '**/*.config.{ts,js}',
        'src/test/**',
        // Type-only declarations carry no executable lines; keeping them in would add
        // noise without adding signal.
        'src/**/*.d.ts',
        'src/types/**',
      ],
    },
  },
  envPrefix: 'VITE_',
  clearScreen: false,
}

export default defineConfig(config)
