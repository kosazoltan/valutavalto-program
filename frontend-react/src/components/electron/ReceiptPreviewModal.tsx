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
import { useTranslation } from 'react-i18next'

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
  const { t } = useTranslation()
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
          regNumber: '02 10 060505',
          address: '7621 Pécs, Citrom utca 2-6. földszint 26. ajtó',
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
      <div className="relative w-full max-w-sm max-h-[90vh] rounded-2xl bg-white shadow-2xl flex flex-col overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between border-b px-6 py-4">
          <h2 className="text-xl font-bold text-gray-800">{t('components.bizonylatElonezet2')}</h2>
          {/* eslint-disable i18next/no-literal-string */}
          <button
            onClick={onClose}
            className="rounded-lg px-3 py-2 text-gray-500 hover:bg-gray-100 hover:text-gray-800"
            aria-label="Bezárás"
          >
            ✕
          </button>
          {/* eslint-enable i18next/no-literal-string */}
        </div>

        {/* Receipt content — 80mm thermal printer format */}
        <div className="flex-1 overflow-y-auto p-4">
          {(variant === 'draft' || statusMessage) && (
            <div className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
              {statusMessage ?? 'Szigorú számadású bizonylat — helyileg már véglegesítve (NGM 23/2014). Szerver-szinkron folyamatban, a sorszám nem változik.'}
            </div>
          )}
          <div
            className="mx-auto w-[180px] rounded-lg border border-dashed border-gray-300 bg-gray-50 p-2 font-mono text-[10px] leading-snug text-gray-800"
            style={{ fontFamily: 'Courier New, monospace' }}
          >
            {/* Fejléc */}
            <div className="text-center">
              <p className="text-lg font-bold">{company.name}</p>
              <p className="text-xs">{company.fullName}</p>
              <p className="text-xs">{company.address}</p>
              <p className="text-xs">{t('components.adoszam')}{company.taxNumber}</p>
              {company.regNumber && <p className="text-xs">{t('common.companyRegNumber')} {company.regNumber}</p>}
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
                <span className="font-semibold">{t('components.bizonylat')}</span> {receiptData.receiptNumber}
              </p>
              <p>
                <span className="font-semibold">{t('components.datum')}</span> {receiptData.date} {receiptData.time}
              </p>
              <p>
                <span className="font-semibold">{t('components.penztar')}</span> {receiptData.branchCode}
              </p>
              <p>
                <span className="font-semibold">{t('components.penztaros')}</span> {receiptData.cashierName}
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
                  <span>{t('components.valutanem')}</span> {receiptData.currencyCode ?? '—'}
                </p>
                <p>
                  <span>{t('components.osszeg')}</span> {formatAmount(receiptData.foreignAmount)}{' '}
                  {receiptData.currencyCode ?? ''}
                </p>
                <p>
                  <span>{t('components.arfolyam')}</span> {formatRate(receiptData.rate)}
                </p>

                <div className="my-2 border-t border-gray-400" />

                <p className="text-sm font-bold">
                  {t('components.hufOsszeg')}{formatAmount(receiptData.hufAmount)} {t('common.ft')}
                </p>

                {receiptData.roundingDiff !== undefined && receiptData.roundingDiff !== 0 && (
                  <p className="text-sm">
                    {t('components.kerekites')}{formatAmount(receiptData.roundingDiff)} {t('common.ft')}
                  </p>
                )}

                <p className="text-lg font-bold">
                  {t('components.fizetendo')}{formatAmount(receiptData.roundedHufAmount ?? receiptData.hufAmount)}{' '}
                  {t('components.ft')}
                </p>
              </div>
            )}

            {receiptData.type === 'conversion' && (
              <div className="space-y-2">
                <p className="font-semibold">{t('components.konverzio')}</p>
                <p>
                  <span>{t('components.forras')}</span> {formatAmount(receiptData.sourceAmount)} {receiptData.sourceCurrencyCode ?? ''}
                </p>
                <p>
                  <span>{t('components.cel')}</span> {formatAmount(receiptData.targetAmount)} {receiptData.targetCurrencyCode ?? ''}
                </p>
                <p>
                  <span>{t('components.koztesHuf')}</span> {formatAmount(receiptData.hufAmount)} {t('common.ft')}
                </p>
                <p>
                  <span>{t('components.arfolyam')}</span> {formatRate(receiptData.rate)}
                </p>
                {receiptData.note && (
                  <p>
                    <span className="font-semibold">{t('components.megjegyzes')}</span> {receiptData.note}
                  </p>
                )}
              </div>
            )}

            {/* Stornó specifikus adatok */}
            {receiptData.type === 'storno' && (
              <div className="space-y-2">
                <p className="font-semibold text-red-700">{t('components.stornozottTranzakcio')}</p>

                {receiptData.originalReceiptNumber && (
                  <p>
                    <span className="font-semibold">{t('components.eredetiBizonylat')}</span>{' '}
                    {receiptData.originalReceiptNumber}
                  </p>
                )}

                <p>
                  <span>{t('components.valutanem')}</span> {receiptData.currencyCode ?? '—'}
                </p>
                <p>
                  <span>{t('components.osszeg')}</span> {formatAmount(receiptData.foreignAmount)}{' '}
                  {receiptData.currencyCode ?? ''}
                </p>
                <p>
                  <span>{t('components.arfolyam')}</span> {formatRate(receiptData.rate)}
                </p>
                <p>
                  <span className="font-semibold">{t('components.hufOsszeg')}</span>{' '}
                  {formatAmount(receiptData.roundedHufAmount ?? receiptData.hufAmount)} {t('common.ft')}
                </p>

                {receiptData.stornoReason && (
                  <>
                    <div className="my-2 border-t border-gray-400" />
                    <p className="font-semibold">{t('components.stornoOka')}</p>
                    <p className="text-[10px] italic">{receiptData.stornoReason}</p>
                  </>
                )}
              </div>
            )}

            {/* Átadás-átvétel */}
            {receiptData.type === 'transfer' && (
              <div className="space-y-2">
                <p className="font-semibold">{t('components.atadasAtvetel')}</p>
                {receiptData.transferTarget && (
                  <p>
                    <span className="font-semibold">{t('components.cel')}</span> {receiptData.transferTarget}
                  </p>
                )}
                {receiptData.transferNote && (
                  <p>
                    <span className="font-semibold">{t('components.megjegyzes')}</span> {receiptData.transferNote}
                  </p>
                )}
              </div>
            )}

            {/* Ügyfél adatok */}
            {receiptData.customerName && (
              <>
                <div className="my-3 border-t border-gray-300" />
                <div className="space-y-1">
                  <p className="font-semibold">{t('components.ugyfelAdatok')}</p>
                  <p>{t('components.nev')}{receiptData.customerName}</p>
                  {receiptData.customerDocType && (
                    <p>Igazolv.: {receiptData.customerDocType}</p>
                  )}
                  {receiptData.customerDocNumber && (
                    <p>{t('components.szam')}{receiptData.customerDocNumber}</p>
                  )}
                  {receiptData.customerAddress && (
                    <p>{t('components.cim')}{receiptData.customerAddress}</p>
                  )}
                </div>
              </>
            )}

            {/* ÁFA-mentesség */}
            {receiptData.vatExemptionText && (
              <>
                <div className="my-3 border-t border-gray-300" />
                <p className="text-[10px] italic text-gray-600">
                  {receiptData.vatExemptionText}
                </p>
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
                    <p className="mb-2 font-semibold">{t('components.qrKod')}</p>
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
              <p>{t('components.koszonjukHogyMinketValasztott')}</p>
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
            {t('components.megseEsc')}
          </button>
        </div>
      </div>
    </div>
  );
}
