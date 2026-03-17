/**
 * Bizonylat szám generálás — backend ReceiptSequenceService kompatibilis.
 *
 * Formátum: PREFIX + branchCode(3 számjegy, 0-paddelt) + sorszám(6 számjegy, 0-paddelt)
 * Példa: E001100001 (eladás, 001-es pénztár, 100001-es sorszám)
 *
 * Prefix-ek (backend getPrefix() alapján):
 *   E  = Eladás (SELL)
 *   V  = Vétel (BUY)
 *   F  = Átadás ki (TRANSFER_OUT)
 *   U  = Átvétel be (TRANSFER_IN)
 *   K  = Konverzió (CONVERSION)
 *   W  = Western Union
 *   M  = MoneyGram
 *   X  = Egyéb szolgáltatás (VIGNETTE, PHONE_TOPUP, OTHER)
 *   PR = Részleges visszatérítés (PARTIAL_REFUND)
 *
 * Stornó: az EREDETI típus prefixét kapja — NINCS külön S prefix!
 *
 * Portolva: penztar-client/src/utils/receipt.ts
 */

export type TransactionType =
  | 'SELL'
  | 'BUY'
  | 'TRANSFER_OUT'
  | 'TRANSFER_IN'
  | 'CONVERSION'
  | 'WESTERN_UNION_SEND'
  | 'WESTERN_UNION_RECEIVE'
  | 'MONEYGRAM_SEND'
  | 'MONEYGRAM_RECEIVE'
  | 'VIGNETTE'
  | 'PHONE_TOPUP'
  | 'OTHER'
  | 'PARTIAL_REFUND'
  | 'REVERSAL';

const PREFIX_MAP: Record<string, string> = {
  SELL: 'E',
  BUY: 'V',
  TRANSFER_OUT: 'F',
  TRANSFER_IN: 'U',
  CONVERSION: 'K',
  WESTERN_UNION_SEND: 'W',
  WESTERN_UNION_RECEIVE: 'W',
  MONEYGRAM_SEND: 'M',
  MONEYGRAM_RECEIVE: 'M',
  VIGNETTE: 'X',
  PHONE_TOPUP: 'X',
  OTHER: 'X',
  PARTIAL_REFUND: 'PR',
};

/**
 * Bizonylat szám generálás — backend-kompatibilis formátum.
 *
 * FONTOS: Éles környezetben a backend generálja a bizonylat számot (pessimistic lock).
 * Ez a függvény offline / preview célra használható.
 *
 * @param type tranzakció típusa
 * @param branchCode pénztár kód (3 jegyűre paddeli)
 * @param sequenceNumber sorszám (6 jegyűre paddeli)
 * @returns bizonylat szám (pl. "E001100001")
 */
export function generateReceiptNumber(
  type: TransactionType,
  branchCode: string,
  sequenceNumber: number,
): string {
  if (type === 'REVERSAL') {
    throw new Error('REVERSAL típushoz az eredeti tranzakció típusát kell használni!');
  }

  const prefix = PREFIX_MAP[type];
  if (!prefix) {
    throw new Error(`Ismeretlen tranzakció típus: ${type}`);
  }

  const code = padBranchCode(branchCode);
  const seq = String(sequenceNumber).padStart(6, '0');
  return `${prefix}${code}${seq}`;
}

/**
 * Branch kódból 3 jegyű szám (backend extractBranchCode() logika).
 */
function padBranchCode(code: string): string {
  if (!code || code.trim() === '') return '000';

  const numericOnly = code.replace(/[^0-9]/g, '');
  if (numericOnly.length > 0) {
    const num = parseInt(numericOnly, 10) % 1000;
    return String(num).padStart(3, '0');
  }

  // Hash-alapú fallback (egyszerűsített, determinisztikus)
  let hash = 0;
  for (let i = 0; i < code.length; i++) {
    hash = ((hash << 5) - hash + code.charCodeAt(i)) | 0;
  }
  return String(Math.abs(hash) % 1000).padStart(3, '0');
}

/**
 * Bizonylat szám parse-olás — backend formátum.
 *
 * Formátum: PREFIX(1-2 karakter) + branchCode(3 számjegy) + sorszám(6 számjegy)
 */
export function parseReceiptNumber(receiptNumber: string): {
  prefix: string;
  branchCode: string;
  sequence: number;
} | null {
  if (!receiptNumber || receiptNumber.length < 10) return null;

  // Kétjegyű prefix check (PR, FF, UF)
  let prefix: string;
  let numericPart: string;

  if (
    receiptNumber.length >= 2 &&
    !isDigit(receiptNumber[1]!) &&
    receiptNumber[0] !== receiptNumber[1]
  ) {
    prefix = receiptNumber.substring(0, 2);
    numericPart = receiptNumber.substring(2);
  } else {
    prefix = receiptNumber.substring(0, 1);
    numericPart = receiptNumber.substring(1);
  }

  if (numericPart.length < 9) return null;

  const branchCode = numericPart.substring(0, 3);
  const seqStr = numericPart.substring(3);

  const sequence = parseInt(seqStr, 10);
  if (isNaN(sequence)) return null;

  return { prefix, branchCode, sequence };
}

function isDigit(ch: string): boolean {
  return ch >= '0' && ch <= '9';
}
