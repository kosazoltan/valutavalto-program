/**
 * QR kód generátor — NAV kompatibilis bizonylat QR kód.
 *
 * KÖTELEZŐ: minden bizonylaton szerepelnie kell a QR kódnak.
 * A QR tartalom pipe-szeparált: bizonylatszám|dátum|összeg|valuta|adószám|pénztárkód
 */

import QRCode from 'qrcode';
import type { QRData } from '@/types';

/**
 * QR kód generálás — base64 data URL-t ad vissza (PNG).
 *
 * @param data QR tartalom adatok
 * @returns base64 data URL (pl. "data:image/png;base64,...")
 */
export async function generateQRCode(data: QRData): Promise<string> {
  const content = [
    data.bizonylatSzam,
    data.datum,
    data.osszeg.toString(),
    data.valuta,
    data.adoszam,
    data.penztarKod.toString(),
  ].join('|');

  return QRCode.toDataURL(content, {
    width: 200,
    margin: 1,
    errorCorrectionLevel: 'M',
  });
}

/**
 * QR kód tartalom string generálás (nyomtatónak).
 */
export function generateQRContent(data: QRData): string {
  return [
    data.bizonylatSzam,
    data.datum,
    data.osszeg.toString(),
    data.valuta,
    data.adoszam,
    data.penztarKod.toString(),
  ].join('|');
}
