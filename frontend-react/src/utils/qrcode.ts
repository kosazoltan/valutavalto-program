/**
 * QR kód generátor — NAV kompatibilis bizonylat QR kód.
 *
 * KÖTELEZŐ: minden bizonylaton szerepelnie kell a QR kódnak.
 * A QR tartalom pipe-szeparált: bizonylatszám|dátum|összeg|valuta|adószám|pénztárkód
 *
 * Portolva: penztar-client/src/utils/qrcode.ts
 *
 * FIGYELEM: Szükséges npm csomag: qrcode  (@types/qrcode)
 *   npm install qrcode @types/qrcode  (penztar-client-ben már telepítve)
 */

import type { QRData } from '@/types/receipt';

// Dynamic import to avoid breaking the build if qrcode is not installed yet.
// Once `npm install qrcode @types/qrcode` is run in frontend-react, replace with:
//   import QRCode from 'qrcode';
let QRCode: typeof import('qrcode') | null = null;
(async () => {
  try {
    QRCode = await import('qrcode');
  } catch {
    // qrcode not installed — generateQRCode will return a placeholder
    console.warn('[qrcode] npm package "qrcode" not installed. Run: npm install qrcode @types/qrcode');
  }
})();

/**
 * QR kód generálás — base64 data URL-t ad vissza (PNG).
 *
 * @param data QR tartalom adatok
 * @returns base64 data URL (pl. "data:image/png;base64,...")
 */
export async function generateQRCode(data: QRData): Promise<string> {
  const content = buildQRContent(data);

  if (!QRCode) {
    // Fallback: return empty transparent PNG placeholder
    console.warn('[qrcode] QR kód generálás nem elérhető — telepítsd: npm install qrcode @types/qrcode');
    return '';
  }

  return QRCode.toDataURL(content, {
    width: 200,
    margin: 1,
    errorCorrectionLevel: 'M',
  });
}

/**
 * QR kód tartalom string generálás (nyomtatónak / audithoz).
 */
export function generateQRContent(data: QRData): string {
  return buildQRContent(data);
}

function buildQRContent(data: QRData): string {
  return [
    data.bizonylatSzam,
    data.datum,
    data.osszeg.toString(),
    data.valuta,
    data.adoszam,
    data.penztarKod.toString(),
  ].join('|');
}
