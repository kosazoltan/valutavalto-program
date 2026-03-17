/**
 * Bizonylat szám generálás — a Delphi UTOLSOBLOKKOK logikája szerint.
 *
 * Formátum:
 *   Eladás:   E-YYMMDD-XXXX
 *   Vásárlás: V-YYMMDD-XXXX
 *   Átadás:   A-YYMMDD-XXXX
 *   Stornó:   S-YYMMDD-XXXX
 *
 * Portolva: penztar-client/src/utils/receipt.ts
 */

type ReceiptType = 'SELL' | 'BUY' | 'TRANSFER' | 'STORNO';

const PREFIX_MAP: Record<ReceiptType, string> = {
  SELL: 'E',
  BUY: 'V',
  TRANSFER: 'A',
  STORNO: 'S',
};

function formatDate(date: Date): string {
  const yy = String(date.getFullYear()).slice(2);
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  return `${yy}${mm}${dd}`;
}

export function generateReceiptNumber(
  type: ReceiptType,
  sequenceNumber: number,
  date?: Date,
): string {
  const prefix = PREFIX_MAP[type];
  const dateStr = formatDate(date ?? new Date());
  const seq = String(sequenceNumber).padStart(4, '0');
  return `${prefix}-${dateStr}-${seq}`;
}

export function parseReceiptNumber(receiptNumber: string): {
  type: ReceiptType;
  date: string;
  sequence: number;
} | null {
  const match = receiptNumber.match(/^([EVAS])-(\d{6})-(\d{4})$/);
  if (!match) return null;

  const prefixToType: Record<string, ReceiptType> = {
    E: 'SELL',
    V: 'BUY',
    A: 'TRANSFER',
    S: 'STORNO',
  };

  const typeStr = match[1];
  if (!typeStr || !prefixToType[typeStr]) return null;

  return {
    type: prefixToType[typeStr]!,
    date: match[2]!,
    sequence: parseInt(match[3]!, 10),
  };
}
