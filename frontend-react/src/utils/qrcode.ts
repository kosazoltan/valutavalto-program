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

import type { QRData } from '@/types/receipt'
import { logger } from './logger'

// Lazy-loaded QR code module — import happens on first use, not at module load time.
// This avoids a race condition where a top-level IIFE could still be pending
// when generateQRCode is called right after page load.
let QRCodeModule: typeof import('qrcode') | null = null
let loadPromise: Promise<typeof import('qrcode') | null> | null = null

async function getQRCodeModule(): Promise<typeof import('qrcode') | null> {
  if (QRCodeModule) return QRCodeModule
  if (!loadPromise) {
    loadPromise = import('qrcode')
      .then((mod) => {
        QRCodeModule = mod
        return mod
      })
      .catch(() => {
        logger.warn(
          'qrcode',
          'npm package "qrcode" not installed. Run: npm install qrcode @types/qrcode',
        )
        return null
      })
  }
  return loadPromise
}

/**
 * QR kód generálás — base64 data URL-t ad vissza (PNG).
 *
 * @param data QR tartalom adatok
 * @returns base64 data URL (pl. "data:image/png;base64,...")
 */
export async function generateQRCode(data: QRData): Promise<string> {
  try {
    const content = buildQRContent(data)

    const mod = await getQRCodeModule()
    if (!mod) {
      return ''
    }

    return mod.toDataURL(content, {
      width: 200,
      margin: 1,
      errorCorrectionLevel: 'M',
    })
  } catch (err) {
    logger.error('qrcode', 'generateQRCode failed', err)
    throw err
  }
}

/**
 * QR kód tartalom string generálás (nyomtatónak / audithoz).
 */
export function generateQRContent(data: QRData): string {
  return buildQRContent(data)
}

function buildQRContent(data: QRData): string {
  return [
    data.bizonylatSzam,
    data.datum,
    data.osszeg.toString(),
    data.valuta,
    data.adoszam,
    data.penztarKod.toString(),
  ].join('|')
}
