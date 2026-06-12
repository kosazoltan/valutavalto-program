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
    cancelled_transaction: 'Megszakított tranzakció',
  };

  const subtypeEn: Record<string, string> = {
    buy: 'EXCHANGE (PURCHASE)',
    sell: 'EXCHANGE (SELLING)',
    storno: '*** REVERSAL ***',
    conversion: 'CONVERSION',
    transfer: 'TRANSFER',
    closing: 'DAILY CLOSING',
    cancelled_transaction: 'CANCELLED TRANSACTION',
  };

  const formatAmount = (value: number | undefined) =>
    value !== undefined ? value.toLocaleString('hu-HU', { maximumFractionDigits: 2 }) : '—';

  const formatRate = (value: number | undefined) =>
    value !== undefined
      ? value.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 4 })
      : '—';

  const formatInt = (value: number | undefined) =>
    value !== undefined ? Math.round(value).toLocaleString('hu-HU') : '0';

  // Codex PR #1102 P1: a küszöbök az AML-lel azonos FIZETENDŐ összegre (díjjal) számolnak.
  // Copilot #1110: a dokumentált fallback-lánc a printer isHighValueReceipt-tel egyezően
  // payableHufAmount ?? roundedHufAmount ?? hufAmount — a csak roundedHufAmount-ot hordozó
  // (pl. többsoros) bizonylatokon e nélkül a 300k+ blokkok tévesen elmaradtak volna.
  const absHuf = Math.abs(receiptData.payableHufAmount ?? receiptData.roundedHufAmount ?? receiptData.hufAmount ?? 0);
  const isMediumValue = absHuf >= MEDIUM_THRESHOLD;
  const isHighValue = absHuf >= HIGH_THRESHOLD;
  // Codex P2 #1110: a PepKind nyers kódja (CSALADTAG/PARLAMENTI/...) emberi szövegre fordul
  // — a penztar-client printer.ts pepKindReceiptText tükre (külön package, ezért lokál másolat).
  const pepKindText = (() => {
    const k = receiptData.customerPepKind?.trim();
    if (!k) return undefined;
    switch (k) {
      case 'CSALADTAG': return 'kiemelt közszereplő családtagja';
      case 'KOZELI_MUNKATARS': return 'kiemelt közszereplő közeli munkatársa';
      case 'KORMANYFO': return 'kormányfő / miniszter / államtitkár';
      case 'PARLAMENTI': return 'országgyűlési / önkormányzati képviselő';
      case 'NAV_VEZETO': return 'NAV / állami vállalat felsővezetés';
      case 'EGYEB': return 'egyéb kiemelt közszereplő';
      default: return k;
    }
  })();
  // Batch2-D: orosz EUR-vásárlási nyilatkozat triggere (legacy EzoroszUgyfel tükre,
  // a printer.ts isRussianEurPurchase-zal egyezően): EUR eladás + orosz állampolgár + 300k+.
  const nationalityLower = (receiptData.customerNationality ?? '').trim().toLowerCase();
  const isRussianEurPurchase = receiptData.type === 'sell' && isHighValue
    && (nationalityLower === 'ru' || nationalityLower === 'rus'
      || nationalityLower.includes('orosz') || nationalityLower.includes('russia'))
    && (receiptData.currencyCode === 'EUR'
      || (receiptData.transactionLines ?? []).some(l => l.currencyCode === 'EUR'));
  // Átadási bizonylat (értéktári átadás-átvétel): nincs ügyfél / deviza-státusz / jogcím-nyilatkozat,
  // ezeket a tranzakció-specifikus szekciókat a transfer bizonylaton elrejtjük.
  const isTransfer = receiptData.type === 'transfer';
  // FR-2/FR-13: a transfer bizonylat címe — átadás/átvétel, sztornónál „SZTORNÓ BIZONYLAT".
  const transferTitle = receiptData.isStorno
    ? 'SZTORNÓ BIZONYLAT'
    : receiptData.transferDocType === 'receipt' ? 'Átvételi bizonylat' : 'Átadási bizonylat';

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
          { }
          <button
            onClick={onClose}
            className="rounded-lg px-3 py-2 text-gray-500 hover:bg-gray-100 hover:text-gray-800"
            aria-label="Bezárás"
          >
            ✕
          </button>
          { }
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
              {/* Batch2-E (Fabulya-teszt 2026-06-12): a kiállító értéktár azonosítója + neve a
                  fejlécben — eddig sosem volt a template része, az értéktár neve csak a
                  Kérő/Cél sorokban jelent meg. */}
              {isTransfer && receiptData.vaultBranchLabel && (
                <p className="text-xs font-bold">{receiptData.vaultBranchLabel}</p>
              )}
              {/* FR-1/FR-3: átadás-átvételnél a bejelentkezett értéktár SAJÁT címe a branch táblából
                  (a cégnév marad); hiány esetén nincs cím sor — hardcode-olt székhely transfer
                  bizonylatra nem kerülhet. */}
              {(isTransfer ? !!receiptData.vaultAddress : true) && (
                <p className="text-xs">{isTransfer ? receiptData.vaultAddress : company.address}</p>
              )}
              {/* FR-2 (fejléc-javítás): az értéktár telefonszáma a branch.phone-ból; hiány esetén nincs telefon sor (TBD-3). */}
              {isTransfer && receiptData.vaultPhone && (
                <p className="text-xs">Tel: {receiptData.vaultPhone}</p>
              )}
              <p className="text-xs">Adószám: {company.taxNumber}</p>
              <p className="text-sm font-bold mt-1">{isTransfer ? transferTitle : (subtypeHu[receiptData.type] ?? receiptData.type)}</p>
              <p className="text-xs">{isTransfer ? '' : (subtypeEn[receiptData.type] ?? '')}</p>
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
                {/* Multi-line aggregate (2026-06-04): minden valuta-sor egy sorban, EGY bizonylatszám alatt.
                    Egysoros bizonylatnál a fejléc currencyCode/rate/foreignAmount/hufAmount jelenik meg (változatlan). */}
                {(receiptData.transactionLines && receiptData.transactionLines.length > 0
                  ? receiptData.transactionLines
                  : [{
                      currencyCode: receiptData.currencyCode ?? '—',
                      rate: receiptData.rate ?? 0,
                      foreignAmount: receiptData.foreignAmount ?? 0,
                      hufAmount: receiptData.hufAmount ?? 0,
                    }]
                ).map((ln, i) => (
                  <div className="flex justify-between" key={`${ln.currencyCode}-${i}`}>
                    <span className="font-bold">{ln.currencyCode || '—'}</span>
                    <span>{formatRate(ln.rate)}</span>
                    <span>{formatAmount(ln.foreignAmount)}</span>
                    <span>{formatInt(ln.hufAmount)}</span>
                  </div>
                ))}
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

            {receiptData.type === 'cancelled_transaction' && (
              <div className="space-y-1">
                <p className="font-semibold">Megszakított tranzakció</p>
                <p className="font-bold">Pénzmozgás nem történt.</p>
                {receiptData.transactionLines && receiptData.transactionLines.length > 0 && (
                  <table className="w-full text-[9px]">
                    <thead>
                      <tr className="border-b border-gray-300">
                        <th className="text-left">Valuta</th>
                        <th className="text-right">Összeg</th>
                        <th className="text-right">Árf.</th>
                        <th className="text-right">Forint</th>
                      </tr>
                    </thead>
                    <tbody>
                      {receiptData.transactionLines.map((ln, i) => (
                        <tr key={`${ln.currencyCode}-${i}`}>
                          <td className="text-left">{ln.currencyCode || '—'}</td>
                          <td className="text-right">{formatAmount(ln.foreignAmount)}</td>
                          <td className="text-right">{formatRate(ln.rate)}</td>
                          <td className="text-right">{formatInt(ln.hufAmount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
                <p className="font-bold">HUF érték: {formatInt(receiptData.roundedHufAmount ?? receiptData.hufAmount)} Ft</p>
                {receiptData.stornoReason && (
                  <p><span className="font-semibold">Indok:</span> {receiptData.stornoReason}</p>
                )}
                {receiptData.note && (
                  <p className="text-[9px] italic">{receiptData.note}</p>
                )}
              </div>
            )}

            {receiptData.type === 'transfer' && (
              <div className="space-y-1">
                <p className="font-semibold">Átadás-átvétel</p>
                {/* FR-2: a Kérő iroda és Cél iroda kötelező mezők — mindig megjelennek (hiány esetén „—"). */}
                <p><span className="font-semibold">Kérő iroda:</span> {receiptData.branchCode || '—'}</p>
                <p><span className="font-semibold">Cél iroda:</span> {receiptData.transferTarget || '—'}</p>
                {receiptData.carrierName && (
                  <p><span className="font-semibold">Szállító:</span> {receiptData.carrierName}</p>
                )}
                {receiptData.sealNumber && (
                  <p><span className="font-semibold">Plombaszám:</span> {receiptData.sealNumber}</p>
                )}
                {/* Penztar-batch A.1 (2026-06-12): több-valutás átadólapon MINDEN sor
                    megjelenik — egysorosnál a korábbi fejléc-mezős megjelenítés marad. */}
                {receiptData.transferLines && receiptData.transferLines.length > 0 ? (
                  <div>
                    <p className="font-semibold">Valuták és összegek:</p>
                    {receiptData.transferLines.map((line, idx) => (
                      <p key={idx} className="pl-2 font-mono">
                        {line.currencyCode}: {formatAmount(line.amount)}
                      </p>
                    ))}
                  </div>
                ) : (
                  <>
                    {receiptData.currencyCode && (
                      <p><span className="font-semibold">Valuta:</span> {receiptData.currencyCode}</p>
                    )}
                    {receiptData.foreignAmount !== undefined && (
                      <p><span className="font-semibold">Összeg:</span> {formatAmount(receiptData.foreignAmount)} {receiptData.currencyCode ?? ''}</p>
                    )}
                  </>
                )}
                {/* Batch2-E: árfolyam a deviza-bizonylaton (HUF-átadásnál nincs árfolyam sor). */}
                {receiptData.rate != null && receiptData.currencyCode !== 'HUF' && (
                  <p><span className="font-semibold">Árfolyam:</span> {formatRate(receiptData.rate)}</p>
                )}
                {(receiptData.roundedHufAmount != null || receiptData.hufAmount != null) && (
                  <p><span className="font-semibold">Forint érték:</span> {formatInt(receiptData.roundedHufAmount ?? receiptData.hufAmount)} HUF</p>
                )}
                {receiptData.deliveryDate && (
                  <p><span className="font-semibold">Kézbesítési dátum:</span> {receiptData.deliveryDate}</p>
                )}
                {receiptData.transferNote && (
                  <p><span className="font-semibold">Megjegyzés:</span> {receiptData.transferNote}</p>
                )}
                {/* FR-15: sztornó indoklása a sztornó bizonylaton. */}
                {receiptData.isStorno && receiptData.stornoReason && (
                  <p><span className="font-semibold">Sztornó indoklása:</span> {receiptData.stornoReason}</p>
                )}
                {/* FR-17..19: opcionális címletezési táblázat — csak ha van megadott sor. */}
                {receiptData.denominations && receiptData.denominations.length > 0 && (
                  <div className="mt-2">
                    <p className="font-semibold">Címletezés</p>
                    <table className="w-full text-[9px]">
                      <thead>
                        <tr className="border-b border-gray-300">
                          <th className="text-left">Darab</th>
                          <th className="text-right">Névleges</th>
                          <th className="text-right">Összesen</th>
                        </tr>
                      </thead>
                      <tbody>
                        {receiptData.denominations.map((d, i) => (
                          <tr key={i}>
                            <td className="text-left">{d.quantity}</td>
                            <td className="text-right">{formatAmount(d.faceValue)}</td>
                            <td className="text-right">{formatAmount(d.lineTotal)} {d.currencyCode ?? receiptData.currencyCode ?? ''}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}

            {/* Tranzakció-specifikus szekciók (ügyfél / deviza-státusz / jogcím) — átadási bizonylaton elrejtve. */}
            {!isTransfer && (<>
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
                    {/* Penztar-batch C.1: PEP-minőség is megjelenik, ha ismert (emberi szöveg, nem kód). */}
                    <p>
                      {receiptData.customerIsPep
                        ? `Az ügyfél kiemelt közszereplő${pepKindText ? ` (${pepKindText})` : ''}`
                        : 'Az ügyfél nem közszereplő'}
                    </p>
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
                  {/* Penztar-batch C.1: a „saját nevemben / <képviselt> nevében" ág a TÉNYLEGES
                      onOwnBehalf flagből — a korábbi statikus „saját nevemben" szöveg helyett
                      (a kanonikus backend EscPosReceiptService logikájával egyezően). */}
                  {receiptData.customerOnOwnBehalf === false && receiptData.customerActorName ? (
                    <>
                      <p className="text-[9px] leading-tight">
                        Büntetőjogi felelősségem tudatában nyilatkozom, hogy a fenti tranzakciót{' '}
                        <span className="font-bold">{receiptData.customerActorName}</span> nevében bonyolítom,
                      </p>
                      <p className="text-[9px] leading-tight">Képviselt fél adatai:</p>
                      {receiptData.customerActorBirthPlace && <p className="text-[9px] pl-2">szül.hely: {receiptData.customerActorBirthPlace}</p>}
                      {receiptData.customerActorBirthDate && <p className="text-[9px] pl-2">szül.idő: {receiptData.customerActorBirthDate}</p>}
                      {receiptData.customerActorMotherName && <p className="text-[9px] pl-2">anyja: {receiptData.customerActorMotherName}</p>}
                      {receiptData.customerActorNationality && <p className="text-[9px] pl-2">állampolg.: {receiptData.customerActorNationality}</p>}
                      {receiptData.customerActorDocumentNumber && (
                        <p className="text-[9px] pl-2">{receiptData.customerActorDocumentType ?? 'okmány'}: {receiptData.customerActorDocumentNumber}</p>
                      )}
                      {receiptData.customerActorAddress && <p className="text-[9px] pl-2">lakcím: {receiptData.customerActorAddress}</p>}
                    </>
                  ) : (
                    <p className="text-[9px] leading-tight">
                      Büntetőjogi felelősségem tudatában nyilatkozom, hogy a fenti tranzakciót saját nevemben bonyolítom,
                    </p>
                  )}
                  {/* Batch2-D (Fabulya-teszt 2026-06-12): a legacy Jogcimnyilatkozat (BLOKNYOM)
                      további kötelező elemei — első személyű PEP-nyilatkozat, 5 munkanapos
                      adatváltozás-klauzula, dedikált ügyfél-aláírás — a nyomtatóval egyezően.
                      Codex/Copilot #1110: ismeretlen PEP-státusznál (null) NINCS PEP-mondat
                      (a printer/backend guardjával azonosan); a minőség emberi szövegként,
                      a nyomtatóval azonos sortöréssel. */}
                  {receiptData.customerIsPep != null && (
                    receiptData.customerIsPep ? (
                      <>
                        <p className="text-[9px] leading-tight mt-1">Kiemelt közszereplő (vagyok),</p>
                        {pepKindText && <p className="text-[9px] leading-tight">mint: {pepKindText}</p>}
                      </>
                    ) : (
                      <p className="text-[9px] leading-tight mt-1">Nem (vagyok) kiemelt közszereplő.</p>
                    )
                  )}
                  <p className="text-[9px] leading-tight mt-1">
                    Tudomásom van arról, hogy 5 (öt) munkanapon belül köteles vagyok bejelenteni
                    a szolgáltatónak a fenti adatokban, vagy a saját adataimban bekövetkező
                    esetleges változásokat, és e kötelezettség elmulasztásából eredő kár engem terhel.
                  </p>
                  {receiptData.sourceOfFunds && (
                    <p className="mt-1">Pénzeszközöm forrása: <span className="font-bold">{receiptData.sourceOfFunds}</span></p>
                  )}
                  <p className="mt-3 text-center">.....................................</p>
                  <p className="text-center">ügyfél aláírása</p>
                </div>
                <div className="my-2 border-t border-gray-300" />
              </>
            )}

            {/* Batch2-D: orosz állampolgár EUR-vásárlása 300k+ felett → kétnyelvű
                személyes-használat nyilatkozat (legacy OroszNyilatkozat tükre). */}
            {isRussianEurPurchase && (
              <div className="mb-2">
                <div className="my-2 border-t border-gray-300" />
                <p className="text-center font-bold">NYILATKOZAT/DECLARATION</p>
                <div className="my-2 border-t border-gray-300" />
                <p className="text-[9px] leading-tight">
                  Alulírott {(receiptData.customerName ?? '').trim().substring(0, 30)} kijelentem,
                  hogy az általam vásárolt EUR valutát személyes használatra váltottam.
                </p>
                <p className="text-[9px] leading-tight mt-1">
                  /I declare that the just purchased EUR currency is for my personal usage.
                </p>
                <p className="mt-3 text-center">.....................................</p>
                <p className="text-center">ügyfél aláírása/signature of buyer</p>
              </div>
            )}
            </>)}

            {/* FR-5: kötelező jogi nyilatkozat — KIZÁRÓLAG átvételi bizonylaton (átadásin és sztornón NEM). */}
            {isTransfer && receiptData.transferDocType === 'receipt' && !receiptData.isStorno && (
              <>
                <div className="my-3 border-t border-gray-300" />
                <p className="text-[9px] leading-tight">
                  {/* FR-7 (bizonylat-doc 2. kör, 2026-06-12): "tökéletesen" → "tételesen". */}
                  Büntetőjogi felelősségem tudatában, kijelentem, hogy a fentiekben felsorolt
                  pénzkészletet a szállítóktól átvettem, azt tételesen átszámoltam.
                </p>
              </>
            )}

            {/* === Pénztáros / Átadó + aláírás === */}
            <p className="mb-1">{isTransfer ? 'Ügyintéző' : 'Pénztáros'}: {receiptData.cashierName}</p>
            <div className="flex justify-around mt-3 mb-2">
              <div className="text-center">
                <div className="border-t border-black w-16 mx-auto mb-0.5" />
                <p>{isTransfer ? 'Átadó' : 'Pénztáros'}</p>
              </div>
              <div className="text-center">
                <div className="border-t border-black w-16 mx-auto mb-0.5" />
                <p>{isTransfer ? 'Átvevő' : 'Ügyfél'}</p>
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
