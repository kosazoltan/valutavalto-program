import sharp from 'sharp';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const buildDir = join(__dirname, '..', 'build');

// NSIS installer header: 500x150px BMP
// Best Change brand szín (#DC2626) gradient
const width = 500;
const height = 150;

// SVG gradient háttér + "Valutaváltó Pénztár" szöveg
const svgHeader = `
<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#DC2626;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#B91C1C;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="${width}" height="${height}" fill="url(#grad)"/>
  <text x="${width / 2}" y="70" font-family="Segoe UI, Arial, sans-serif" font-size="32" font-weight="700" fill="white" text-anchor="middle">Valutaváltó Pénztár</text>
  <text x="${width / 2}" y="105" font-family="Segoe UI, Arial, sans-serif" font-size="16" font-weight="400" fill="white" text-anchor="middle" opacity="0.9">Telepítő varázsló</text>
</svg>
`;

// PNG generálás (NSIS is elfogadja)
await sharp(Buffer.from(svgHeader))
  .resize(width, height)
  .png()
  .toFile(join(buildDir, 'installer-header.png'));

console.log('✅ Installer header generálva: build/installer-header.png');
console.log('📝 Megjegyzés: NSIS PNG-t is elfogad, BMP konverzió opcionális');
