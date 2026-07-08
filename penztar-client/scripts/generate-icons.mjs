import sharp from 'sharp';
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const iconsDir = join(__dirname, '..', 'build', 'icons');

// Best Change ikonok
const bestChangeSvg = readFileSync(join(iconsDir, 'app-icon-bestchange.svg'));

await sharp(bestChangeSvg)
  .resize(256, 256)
  .png()
  .toFile(join(iconsDir, 'app-icon-bestchange-256.png'));

await sharp(bestChangeSvg)
  .resize(512, 512)
  .png()
  .toFile(join(iconsDir, 'app-icon-bestchange-512.png'));

await sharp(bestChangeSvg)
  .resize(256, 256)
  .toFormat('png')
  .toFile(join(iconsDir, 'app-icon-bestchange.png')); // electron-builder default

// Expressz ikonok
const expresszSvg = readFileSync(join(iconsDir, 'app-icon-expressz.svg'));

await sharp(expresszSvg).resize(256, 256).png().toFile(join(iconsDir, 'app-icon-expressz-256.png'));

await sharp(expresszSvg).resize(512, 512).png().toFile(join(iconsDir, 'app-icon-expressz-512.png'));

await sharp(expresszSvg)
  .resize(256, 256)
  .toFormat('png')
  .toFile(join(iconsDir, 'app-icon-expressz.png')); // electron-builder default

console.log('✅ Ikonok generálva:');
console.log('  - Best Change: 256px, 512px PNG');
console.log('  - Expressz: 256px, 512px PNG');
console.log(
  '\n📝 ICO fájlok generálásához használd: electron-builder (automatikus Windows build-nél)',
);
