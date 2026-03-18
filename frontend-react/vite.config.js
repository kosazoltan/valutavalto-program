import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
// https://vitejs.dev/config/
export default defineConfig({
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
                target: 'https://valuta-backend-spbx.onrender.com',
                changeOrigin: true,
            },
        },
    },
    build: {
        outDir: 'dist',
        sourcemap: false,
    },
    // API URL beállítása build időben
    envPrefix: 'VITE_',
    // Disable Vite error overlay (hide vite-error-overlay element)
    clearScreen: false,
});
