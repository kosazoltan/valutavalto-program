/**
 * ReceiptPreviewModal — Bizonylat előnézet és nyomtatás modal.
 *
 * Böngészőben is megjelenítható (előnézet), de a tényleges nyomtatás
 * (window.electronAPI.printReceipt) csak Electron-ban működik.
 *
 * FUNKCIÓK:
 * - Bizonylat előnézet (80mm hőnyomtató formátum)
 * - QR kód megjelenítés
 * - Nyomtatás megerősítés
 * - Újranyomtatás lehetőség
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import type { PrintReceiptData } from '@/types/receipt';
import { logger } from '../../utils/logger';

interface ReceiptPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  receiptData: PrintReceiptData | null;
  qrCodeDataUrl: string | null;
  onPrint: () => Promise<void>;
  variant?: 'official' | 'draft';
  statusMessage?: string | null;
  printLabel?: string;
  allowPrint?: boolean;
}

export default function ReceiptPreviewModal({
  isOpen,
  onClose,
  receiptData,
  qrCodeDataUrl,
  onPrint,
  variant = 'official',
  statusMessage = null,
  printLabel,
  allowPrint = true,
}: ReceiptPreviewModalProps) {
  const [isPrinting, setIsPrinting] = useState(false);
  const closeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Cleanup timer on unmount to prevent setState on unmounted component
  useEffect(() => {
    return () => {
      if (closeTimerRef.current) {
        clearTimeout(closeTimerRef.current);
      }
    };
  }, []);

  // ESC to close
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  const handlePrint = useCallback(async () => {
    setIsPrinting(true);
    try {
      await onPrint();
      // Wait 2s after print, then close
      closeTimerRef.current = setTimeout(() => {
        setIsPrinting(false);
        onClose();
      }, 2000);
    } catch (err) {
      logger.error('ReceiptPreviewModal', 'Nyomtatás hiba:', err);
      setIsPrinting(false);
    }
  }, [onPrint, onClose]);

  if (!isOpen || !receiptData) return null;

  const company =
    receiptData.companyType === 'BEST_CHANGE'
      ? {
          name: 'BEST CHANGE',
          fullName: 'EXCLUSIVE BEST CHANGE ZRT.',
          taxNumber: '32313332-2-02',
          address: 'Szeged, Kárász u. 5.',
        }
      : {
          name: 'EXPRESSZ',
          fullName: 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.',
          taxNumber: '14040535-2-02',
          address: 'Szeged, Klauzál tér 3.',
        };

  const jobTypeLabels: Record<string, string> = {
    sell: 'ELADÁSI BIZONYLAT',
    buy: 'VÁSÁRLÁSI BIZONYLAT',
    transfer: 'ÁTADÁS-ÁTVÉTELI BIZONYLAT',
    storno: 'STORNÓ BIZONYLAT',
    conversion: 'KONVERZIÓS BIZONYLAT',
    closing: 'NAPI ZÁRÁS',
  };

  const formatAmount = (value: number | undefined) =>
    value !== undefined ? value.toLocaleString('hu-HU', { maximumFractionDigits: 2 }) : '—';

  const formatRate = (value: number | undefined) =>
    value !== undefined
      ? value.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 4 })
      : '—';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="relative w-full max-w-md rounded-2xl bg-white shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between border-b px-6 py-4">
          <h2 className="text-xl font-bold text-gray-800">Bizonylat Előnézet</h2>
          <button
            onClick={onClose}
            className="rounded-lg px-3 py-2 text-gray-500 hover:bg-gray-100 hover:text-gray-800"
            aria-label="Bezárás"
          >
            ✕
          </button>
        </div>

        {/* Receipt content — 80mm thermal printer format */}
        <div className="max-h-[600px] overflow-y-auto p-6">
          {(variant === 'draft' || statusMessage) && (
            <div className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
              {statusMessage ?? 'Ez helyi, függő bizonylatvázlat. A hivatalos bizonylatszám és végleges nyomtatási életciklus csak szerveres szinkron után érvényes.'}
            </div>
          )}
          <div
            className="mx-auto w-[300px] rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 p-4 font-mono text-xs leading-relaxed text-gray-800"
            style={{ fontFamily: 'Courier New, monospace' }}
          >
            {/* Fejléc */}
            <div className="text-center">
              <p className="text-lg font-bold">{company.name}</p>
              <p className="text-xs">{company.fullName}</p>
              <p className="text-xs">{company.address}</p>
              <p className="text-xs">Adószám: {company.taxNumber}</p>
            </div>

            <div className="my-3 border-t-2 border-gray-400" />

            {/* Bizonylat típus */}
            <div className="text-center">
              <p className="text-base font-bold">{jobTypeLabels[receiptData.type]}</p>
            </div>

            <div className="my-3 border-t border-gray-300" />

            {/* Bizonylat adatok */}
            <div className="space-y-1">
              <p>
                <span className="font-semibold">Bizonylat:</span> {receiptData.receiptNumber}
              </p>
              <p>
                <span className="font-semibold">Dátum:</span> {receiptData.date} {receiptData.time}
              </p>
              <p>
                <span className="font-semibold">Pénztár:</span> {receiptData.branchCode}
              </p>
              <p>
                <span className="font-semibold">Pénztáros:</span> {receiptData.cashierName}
              </p>
            </div>

            <div className="my-3 border-t border-gray-300" />

            {/* Tranzakció tételek — Sell/Buy */}
            {(receiptData.type === 'sell' || receiptData.type === 'buy') && (
              <div className="space-y-2">
                <p className="font-semibold">
                  {receiptData.type === 'sell' ? 'Deviza eladás:' : 'Deviza vásárlás:'}
                </p>
                <p>
                  <span>Valutanem:</span> {receiptData.currencyCode ?? '—'}
                </p>
                <p>
                  <span>Összeg:</span> {formatAmount(receiptData.foreignAmount)}{' '}
                  {receiptData.currencyCode ?? ''}
                </p>
                <p>
                  <span>Árfolyam:</span> {formatRate(receiptData.rate)}
                </p>

                <div className="my-2 border-t border-gray-400" />

                <p className="text-sm font-bold">
                  HUF összeg: {formatAmount(receiptData.hufAmount)} Ft
                </p>

                {receiptData.roundingDiff !== undefined && receiptData.roundingDiff !== 0 && (
                  <p className="text-sm">
                    Kerekítés: {formatAmount(receiptData.roundingDiff)} Ft
                  </p>
                )}

                <p className="text-lg font-bold">
                  FIZETENDŐ: {formatAmount(receiptData.roundedHufAmount ?? receiptData.hufAmount)}{' '}
                  Ft
                </p>
              </div>
            )}

            {receiptData.type === 'conversion' && (
              <div className="space-y-2">
                <p className="font-semibold">KONVERZIÓ</p>
                <p>
                  <span>Forrás:</span> {formatAmount(receiptData.sourceAmount)} {receiptData.sourceCurrencyCode ?? ''}
                </p>
                <p>
                  <span>Cél:</span> {formatAmount(receiptData.targetAmount)} {receiptData.targetCurrencyCode ?? ''}
                </p>
                <p>
                  <span>Köztes HUF:</span> {formatAmount(receiptData.hufAmount)} Ft
                </p>
                <p>
                  <span>Árfolyam:</span> {formatRate(receiptData.rate)}
                </p>
                {receiptData.note && (
                  <p>
                    <span className="font-semibold">Megjegyzés:</span> {receiptData.note}
                  </p>
                )}
              </div>
            )}

            {/* Stornó specifikus adatok */}
            {receiptData.type === 'storno' && (
              <div className="space-y-2">
                <p className="font-semibold text-red-700">STORNÓZOTT TRANZAKCIÓ</p>

                {receiptData.originalReceiptNumber && (
                  <p>
                    <span className="font-semibold">Eredeti bizonylat:</span>{' '}
                    {receiptData.originalReceiptNumber}
                  </p>
                )}

                <p>
                  <span>Valutanem:</span> {receiptData.currencyCode ?? '—'}
                </p>
                <p>
                  <span>Összeg:</span> {formatAmount(receiptData.foreignAmount)}{' '}
                  {receiptData.currencyCode ?? ''}
                </p>
                <p>
                  <span>Árfolyam:</span> {formatRate(receiptData.rate)}
                </p>
                <p>
                  <span className="font-semibold">HUF összeg:</span>{' '}
                  {formatAmount(receiptData.roundedHufAmount ?? receiptData.hufAmount)} Ft
                </p>

                {receiptData.stornoReason && (
                  <>
                    <div className="my-2 border-t border-gray-400" />
                    <p className="font-semibold">Stornó oka:</p>
                    <p className="text-[10px] italic">{receiptData.stornoReason}</p>
                  </>
                )}
              </div>
            )}

            {/* Átadás-átvétel */}
            {receiptData.type === 'transfer' && (
              <div className="space-y-2">
                <p className="font-semibold">ÁTADÁS-ÁTVÉTEL</p>
                {receiptData.transferTarget && (
                  <p>
                    <span className="font-semibold">Cél:</span> {receiptData.transferTarget}
                  </p>
                )}
                {receiptData.transferNote && (
                  <p>
                    <span className="font-semibold">Megjegyzés:</span> {receiptData.transferNote}
                  </p>
                )}
              </div>
            )}

            {/* Ügyfél adatok */}
            {receiptData.customerName && (
              <>
                <div className="my-3 border-t border-gray-300" />
                <div className="space-y-1">
                  <p className="font-semibold">ÜGYFÉL ADATOK:</p>
                  <p>Név: {receiptData.customerName}</p>
                  {receiptData.customerDocType && (
                    <p>Igazolv.: {receiptData.customerDocType}</p>
                  )}
                  {receiptData.customerDocNumber && (
                    <p>Szám: {receiptData.customerDocNumber}</p>
                  )}
                </div>
              </>
            )}

            {/* QR kód */}
            {qrCodeDataUrl &&
              (receiptData.type === 'sell' ||
                receiptData.type === 'buy' ||
                receiptData.type === 'conversion' ||
                receiptData.type === 'storno') && (
                <>
                  <div className="my-3 border-t border-gray-300" />
                  <div className="text-center">
                    <p className="mb-2 font-semibold">QR KÓD:</p>
                    <img
                      src={qrCodeDataUrl}
                      alt="Bizonylat QR kód"
                      className="mx-auto h-32 w-32 rounded-md border-2 border-gray-300"
                    />
                    <p className="mt-2 text-[10px] text-gray-500">
                      {receiptData.receiptNumber} | {receiptData.date}
                    </p>
                  </div>
                </>
              )}

            {/* Lábléc */}
            <div className="my-3 border-t-2 border-gray-400" />
            <div className="text-center text-xs text-gray-600">
              <p>Köszönjük, hogy minket választott!</p>
            </div>
          </div>
        </div>

        {/* Gombok */}
        <div className="flex gap-3 border-t px-6 py-4">
          <button
            onClick={handlePrint}
            disabled={isPrinting || !allowPrint}
            className="flex-1 rounded-lg bg-blue-600 px-4 py-3 font-semibold text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-gray-400"
          >
            {isPrinting ? 'Nyomtatás...' : (printLabel ?? (variant === 'draft' ? 'Vázlat nyomtatása' : 'Nyomtatás'))}
          </button>

          <button
            onClick={onClose}
            disabled={isPrinting}
            className="rounded-lg bg-gray-200 px-4 py-3 font-semibold text-gray-700 hover:bg-gray-300 disabled:cursor-not-allowed disabled:bg-gray-100"
          >
            Mégse (ESC)
          </button>
        </div>
      </div>
    </div>
  );
}
