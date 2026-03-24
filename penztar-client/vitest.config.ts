import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    globals: true,
    include: [
      'src/**/*.test.{ts,tsx}',
      'electron/__tests__/**/*.test.ts',
    ],
    environmentMatchGlobs: [
      ['electron/__tests__/**', 'node'],
      ['src/**', 'jsdom'],
    ],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
