// Provides the Electron executable path for vite-plugin-electron startup().
// This file exists because node_modules/electron/index.js is temporarily
// renamed during dev mode to prevent it from shadowing the built-in
// 'electron' module in the Electron main process (Electron 41 + Node 24 bug).
const path = require('path');
const fs = require('fs');

const distDir = path.join(__dirname, 'node_modules', 'electron', 'dist');
const pathFile = path.join(__dirname, 'node_modules', 'electron', 'path.txt');
let exeName = 'electron.exe';
if (fs.existsSync(pathFile)) {
  exeName = fs.readFileSync(pathFile, 'utf-8').trim();
}
module.exports = path.join(distDir, exeName);
