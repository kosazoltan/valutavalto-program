import png2icons from 'png2icons';
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const iconsDir = join(__dirname, '..', 'build', 'icons');

// Best Change ICO
const bestChangePng256 = readFileSync(join(iconsDir, 'app-icon-bestchange-256.png'));
const bestChangeIco = png2icons.createICO(bestChangePng256, png2icons.BICUBIC, 0, false);
writeFileSync(join(iconsDir, 'app-icon-bestchange.ico'), bestChangeIco);

// Expressz ICO
const expresszPng256 = readFileSync(join(iconsDir, 'app-icon-expressz-256.png'));
const expresszIco = png2icons.createICO(expresszPng256, png2icons.BICUBIC, 0, false);
writeFileSync(join(iconsDir, 'app-icon-expressz.ico'), expresszIco);

console.log('✅ ICO fájlok generálva:');
console.log('  - app-icon-bestchange.ico');
console.log('  - app-icon-expressz.ico');
