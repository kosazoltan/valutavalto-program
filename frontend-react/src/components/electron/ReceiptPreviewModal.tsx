/**
 * ReceiptPreviewModal — Bizonylat előnézet és nyomtatás modal.
 *
 * Böngészőben is megjelenítható (előnézet), de a tényleges nyomtatás
 * (window.electronAPI.printReceipt) csak Electron-ban működik.
 *
 * Formátum a production PDF mintákhoz igazítva:
 * - NYUGTA főcím + kétnyelvű altípus
 * - ÁFA-mentesség a valutatáblázat ELŐTT
 * - 3 szintű ügyfél adat (<100k / 100k-300k / 300k+)
 * - Bankpartner + marketing szöveg 300k+ felett
 * - JOGCÍM NYILATKOZAT 300k+ felett
 */

/**
 * NAV-szabvanyu adomentes valutavalto bizonylat preview modal.
 *
 * I18N EXEMPTION: a `eslint.config.js`-ben kifejezetten ki van veve a
 * `i18next/no-literal-string` rule alol (lasd ReceiptPrint.tsx JSDoc-jat
 * a teljes indoklasrol).
 *
 * Minden JSX literal jogszabalyi vagy NAV mintaszerusegbol KOTELEZO:
 *   - "ÁFA-mentesség a 2007. évi CXVII. tv. 86. § e) alapján"
 *     -> pontos jogszabaly-idezet, NEM forditano
 *   - "Sorszám (INVOICE NR)", "Dátum (DATE)" stb.
 *     -> bilingual (HU/EN) NAV mintaszeruseg
 *   - "Bankpartner", "JOGCÍM NYILATKOZAT", "Ügyfél adatok"
 *     -> Pmt. (2017. évi LIII. tv.) 100k/300k szintes ugyfelidentitas-blokk
 *       cimke (kotelezo szoveg az adott osszeg-savnal)
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import type { PrintReceiptData } from '@/types/receipt';
import { logger } from '../../utils/logger';
import { useTranslation } from 'react-i18next'

const MEDIUM_THRESHOLD = 100_000
const HIGH_THRESHOLD = 300_000

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

  useEffect(() => {
    return () => {
      if (closeTimerRef.current) {
        clearTimeout(closeTimerRef.current);
      }
    };
  }, []);

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
          address: '7621 Pécs, Citrom utca 2-6. földszint 26. ajtó',
        }
      : {
          name: 'EXPRESSZ',
          fullName: 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.',
          taxNumber: '14040535-2-02',
          address: 'Szeged, Klauzál tér 3.',
        };

  const subtypeHu: Record<string, string> = {
    buy: 'Valuta vétel',
    sell: 'Valuta eladás',
    storno: '*** Sztornó ***',
    conversion: 'Konverziós bizonylat',
    transfer: 'Átadási bizonylat',
    closing: 'Napi zárás',
  };

  const subtypeEn: Record<string, string> = {
    buy: 'EXCHANGE (PURCHASE)',
    sell: 'EXCHANGE (SELLING)',
    storno: '*** REVERSAL ***',
    conversion: 'CONVERSION',
    transfer: 'TRANSFER',
    closing: 'DAILY CLOSING',
  };

  const formatAmount = (value: number | undefined) =>
    value !== undefined ? value.toLocaleString('hu-HU', { maximumFractionDigits: 2 }) : '—';

  const formatRate = (value: number | undefined) =>
    value !== undefined
      ? value.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 4 })
      : '—';

  const formatInt = (value: number | undefined) =>
    value !== undefined ? Math.round(value).toLocaleString('hu-HU') : '0';

  const absHuf = Math.abs(receiptData.hufAmount ?? 0);
  const isMediumValue = absHuf >= MEDIUM_THRESHOLD;
  const isHighValue = absHuf >= HIGH_THRESHOLD;

  const roundingDiff = receiptData.roundingDiff ?? 0;
  const netTotal = receiptData.roundedHufAmount ?? receiptData.hufAmount ?? 0;
  const fee = receiptData.handlingFee ?? 0;
  const paid = netTotal + fee;

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
            {/* === FEJLÉC: NYUGTA + Cég + Típus === */}
            <div className="text-center">
              <p className="text-lg font-bold">NYUGTA</p>
              <p className="text-xs font-bold">{company.fullName}</p>
              <p className="text-xs">{company.address}</p>
              <p className="text-xs">Adószám: {company.taxNumber}</p>
              <p className="text-sm font-bold mt-1">{subtypeHu[receiptData.type] ?? receiptData.type}</p>
              <p className="text-xs">{subtypeEn[receiptData.type] ?? ''}</p>
            </div>

            <div className="my-3 border-t border-gray-300" />

            {/* === BIZONYLAT ADATOK (kétnyelvű) === */}
            <div className="space-y-0.5">
              <p><span className="font-semibold">Sorszám (INVOICE NR):</span> {receiptData.receiptNumber}</p>
              <p><span className="font-semibold">Dátum (DATE):</span> {receiptData.date}</p>
              <p><span className="font-semibold">Idő (TIME):</span> {receiptData.time}</p>
              {receiptData.navReceiptNumber && (
                <p>(Nyugtaszám: {receiptData.navReceiptNumber})</p>
              )}
            </div>

            <div className="my-3 border-t border-gray-300" />

            {/* === ÁFA-MENTESSÉG (a valutatáblázat ELŐTT) === */}
            <div className="text-[9px]">
              <p>Szj - 67.13.10.0</p>
              <p>Adómentes  a szolgáltatás nyújtása a 2007</p>
              <p>M.Á.A. evi CXVII tv. 86 § e) alapján</p>
              <p>mentes az adó alól</p>
            </div>

            <div className="my-3 border-t border-gray-300" />

            {/* === VALUTA TÁBLÁZAT === */}
            {(receiptData.type === 'sell' || receiptData.type === 'buy') && (
              <>
                <div className="flex justify-between text-[9px] font-bold">
                  <span>V.nem</span><span>Árf.</span><span>B.jegy</span><span>Forint</span>
                </div>
                <div className="flex justify-between text-[8px]">
                  <span>CURR.</span><span>RATE</span><span>CASH</span><span>VALUE</span>
                </div>
                <div className="my-1 border-t border-gray-400" />
                <div className="flex justify-between">
                  <span className="font-bold">{receiptData.currencyCode ?? '—'}</span>
                  <span>{formatRate(receiptData.rate)}</span>
                  <span>{formatAmount(receiptData.foreignAmount)}</span>
                  <span>{formatInt(receiptData.hufAmount)}</span>
                </div>
                <div className="my-2 border-t border-gray-400" />

                {/* Összesítés */}
                <div className="space-y-0.5">
                  <div className="flex justify-between"><span>Kerekítés (ROUNDING):</span><span>{formatInt(roundingDiff)}</span></div>
                  <div className="flex justify-between"><span>Nettó Ft (SUM TOTAL):</span><span>{formatInt(netTotal)}</span></div>
                  <div className="flex justify-between"><span>Kez.kltsg (HANDLING FEE):</span><span>{formatInt(fee)}</span></div>
                  <div className="flex justify-between font-bold text-sm"><span>Kifizetve:(PAID):</span><span>{formatInt(paid)}</span></div>
                </div>
              </>
            )}

            {receiptData.type === 'conversion' && (
              <div className="space-y-1">
                <p className="font-semibold">Konverzió</p>
                <p><span>Forrás:</span> {formatAmount(receiptData.sourceAmount)} {receiptData.sourceCurrencyCode ?? ''}</p>
                <p><span>Cél:</span> {formatAmount(receiptData.targetAmount)} {receiptData.targetCurrencyCode ?? ''}</p>
                <p><span>Köztes HUF:</span> {formatAmount(receiptData.hufAmount)} Ft</p>
                <p><span>Árfolyam:</span> {formatRate(receiptData.rate)}</p>
              </div>
            )}

            {receiptData.type === 'storno' && (
              <div className="space-y-1">
                <p className="font-semibold text-red-700">Sztornózott tranzakció</p>
                {receiptData.originalReceiptNumber && (
                  <p><span className="font-semibold">Eredeti bizonylat:</span> {receiptData.originalReceiptNumber}</p>
                )}
                <p><span>Valutanem:</span> {receiptData.currencyCode ?? '—'}</p>
                <p><span>Összeg:</span> {formatAmount(receiptData.foreignAmount)} {receiptData.currencyCode ?? ''}</p>
                <p><span>Árfolyam:</span> {formatRate(receiptData.rate)}</p>
                <p className="font-bold">HUF: {formatAmount(receiptData.roundedHufAmount ?? receiptData.hufAmount)} Ft</p>
                {receiptData.stornoReason && (
                  <>
                    <div className="my-1 border-t border-gray-400" />
                    <p className="font-semibold">Sztornó oka:</p>
                    <p className="text-[9px] italic">{receiptData.stornoReason}</p>
                  </>
                )}
              </div>
            )}

            {receiptData.type === 'transfer' && (
              <div className="space-y-1">
                <p className="font-semibold">Átadás-átvétel</p>
                {receiptData.transferTarget && (
                  <p><span className="font-semibold">Cél:</span> {receiptData.transferTarget}</p>
                )}
                {receiptData.carrierName && (
                  <p><span className="font-semibold">Szállító:</span> {receiptData.carrierName}</p>
                )}
                {receiptData.sealNumber && (
                  <p><span className="font-semibold">Plombaszám:</span> {receiptData.sealNumber}</p>
                )}
                {receiptData.transferNote && (
                  <p><span className="font-semibold">Megjegyzés:</span> {receiptData.transferNote}</p>
                )}
              </div>
            )}

            <div className="my-3 border-t border-gray-300" />

            {/* === ÜGYFÉL ADATOK (3 szintű) === */}
            <div className="text-center font-bold mb-1">--- ügyfél adatai ---</div>

            {isMediumValue && (
              <div className="space-y-0.5">
                {receiptData.customerName && <p>Neve: {receiptData.customerName}</p>}
                {receiptData.customerMotherName && <p>Anyja neve: {receiptData.customerMotherName}</p>}
                {receiptData.customerBirthPlace && <p>Szül-i hely: {receiptData.customerBirthPlace}</p>}
                {receiptData.customerBirthDate && <p>Szül-i idő: {receiptData.customerBirthDate}</p>}

                {isHighValue && (
                  <>
                    {receiptData.customerAddress && <p>Lakcím(ADDRESS): {receiptData.customerAddress}</p>}
                    {receiptData.customerDocType && <p>DOC TYPE: {receiptData.customerDocType}</p>}
                    {receiptData.customerDocNumber && <p>NR.: {receiptData.customerDocNumber}</p>}
                    <p>{receiptData.customerIsPep ? 'Az ügyfél kiemelt közszereplő' : 'Az ügyfél nem közszereplő'}</p>
                  </>
                )}
              </div>
            )}

            <p className="mt-1">Az ügyletet készpénzben teljesítjük</p>
            <p>Deviza-státusz: {receiptData.foreignStatus == null ? '—' : (receiptData.foreignStatus === 'FOREIGN' ? 'Külföldi' : 'Belföldi')}</p>

            <div className="my-3 border-t border-gray-300" />

            {/* === 300k+ FELETT: Bankpartner + marketing + jogcím === */}
            {isHighValue && (
              <>
                <div className="text-center space-y-0.5 mb-2">
                  <p>Raiffeisen Bank Zrt.</p>
                  <p>KIEMELT KÖZVETÍTŐJE</p>
                </div>
                <div className="my-2 border-t border-gray-300" />
                <div className="text-center font-bold space-y-0.5 mb-2">
                  <p>EXCLUSIVE CHANGE</p>
                  <p>KEDVEZŐBB,</p>
                  <p>GYORSABB,</p>
                  <p>BIZTONSÁGOSABB</p>
                </div>
                <div className="my-2 border-t border-gray-300" />

                <div className="mb-2">
                  <p className="font-bold">JOGCÍM NYILATKOZAT</p>
                  <p className="text-[9px] leading-tight">
                    Büntetőjogi felelősségem tudatában nyilatkozom, hogy a fenti tranzakciót saját nevemben bonyolítom,
                  </p>
                  {receiptData.sourceOfFunds && (
                    <p className="mt-1">Pénzeszközöm forrása: <span className="font-bold">{receiptData.sourceOfFunds}</span></p>
                  )}
                </div>
                <div className="my-2 border-t border-gray-300" />
              </>
            )}

            {/* === Pénztáros + aláírás === */}
            <p className="mb-1">Pénztáros: {receiptData.cashierName}</p>
            <div className="flex justify-around mt-3 mb-2">
              <div className="text-center">
                <div className="border-t border-black w-16 mx-auto mb-0.5" />
                <p>Pénztáros</p>
              </div>
              <div className="text-center">
                <div className="border-t border-black w-16 mx-auto mb-0.5" />
                <p>Ügyfél</p>
              </div>
            </div>

            {/* QR kód */}
            {qrCodeDataUrl &&
              (receiptData.type === 'sell' ||
                receiptData.type === 'buy' ||
                receiptData.type === 'conversion' ||
                receiptData.type === 'storno') && (
                <>
                  <div className="my-3 border-t border-gray-300" />
                  <div className="text-center">
                    <img
                      src={qrCodeDataUrl}
                      alt="Bizonylat QR kód"
                      className="mx-auto h-24 w-24 rounded-md border border-gray-300"
                    />
                    <p className="mt-1 text-[9px] text-gray-500">
                      {receiptData.receiptNumber} | {receiptData.date}
                    </p>
                  </div>
                </>
              )}

            {/* Lábléc */}
            <div className="my-3 border-t-2 border-gray-400" />
            <div className="text-center text-[9px] text-gray-600">
              <p>Köszönjük, hogy minket választott!</p>
              <p className="mt-1">A bizonylat a pénzmosás elleni törvény alapján nem helyettesíti a számlát.</p>
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
