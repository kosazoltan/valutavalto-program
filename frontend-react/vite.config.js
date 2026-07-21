/// <reference types="vitest/config" />
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import fs from 'fs';
// 2.1.1: A package.json-ból olvasott verzió, hogy a LoginPage, App-cím
// és egyéb helyek SOHA ne térjenek el a tényleges build verziótól.
// Korábban "v2.0" hardcode volt a LoginPage-en, miközben a build 2.1.0 volt.
const pkg = JSON.parse(fs.readFileSync(path.resolve(__dirname, 'package.json'), 'utf-8'));
const APP_VERSION = pkg.version ?? '0.0.0';
// https://vitejs.dev/config/
const config = {
    plugins: [react()],
    define: {
        __APP_VERSION__: JSON.stringify(APP_VERSION),
    },
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
        },
    },
    server: {
        port: 3000,
        proxy: {
            '/api': {
                target: process.env.VITE_PROXY_TARGET ?? 'http://localhost:8080',
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
        testTimeout: 10_000,
    },
    // API URL beállítása build időben
    envPrefix: 'VITE_',
    // Disable Vite error overlay (hide vite-error-overlay element)
    clearScreen: false,
};
export default defineConfig(config);
