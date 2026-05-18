/**
 * NAV-szabvanyu adomentes valutavalto bizonylat sablon.
 *
 * I18N EXEMPTION: a `eslint.config.js`-ben kifejezetten ki van veve a
 * `i18next/no-literal-string` rule alol (lasd ott a "NAV bizonylat" override
 * blokkot). Az alabbi JSDoc dokumentalja MIERT:
 *
 * Minden JSX literal a fajlban jogszabalyi vagy NAV mintaszerusegbol KOTELEZO:
 *   - "Adomentes a szolgaltatas nyujtasa a 2007. evi CXVII. tv. 86 § e) alapjan"
 *     -> pontos jogszabaly-idezet, NEM forditano, NEM modosithato
 *   - "Sorszam (INVOICE NR)", "Datum (DATE)", "Ido (TIME)", "Arfolyam", "Forint"
 *     -> bilingual (HU/EN) cimke-mintaszeruseg az MNB Pmt. eloiraval egyezo
 *   - "V.nem", "B.jegy", "CURR.", "Kerekites (ROUNDING)", "Netto Ft (SUM TOTAL)"
 *     -> rovidites + bilingual, NAV bizonylat-sablon
 *
 * Sourcery PR #669 javaslat: inline disable per literal. Lokalisan ez ~50+ inline
 * komment lenne, plus a in-file `/* eslint-disable * /` directive a jelenlegi
 * ESLint flat-config + i18next plugin verzioval NEM aktivalodik (a directive
 * "Unused"-kent flag-elodik, de a warning-ok megis kiirodnak). Ezert config-szintu
 * override-ot hasznalunk, plus EZ a JSDoc a fajlban tartja a dokumentaciot.
 *
 * Ha barki ide nem-jogszabalyi literal-t adna (pl. debug-szoveg, dev-only komment
 * a renderelt outputban), az inkabb a fajl scope-jat serti, NEM csak i18n-igent.
 * Code-review-n kell elkapni, NEM csak ESLint-tel.
 */

import { useRef, useEffect, useState } from 'react'
import QRCode from 'qrcode'
import { Printer, X } from 'lucide-react'
import { Transaction } from '../services/api/index'
import { formatDecimal, formatInteger } from '../utils/numberFormat'
import { toast } from './ui/toaster'
import { useTranslation } from 'react-i18next'

interface ReceiptPrintProps {
  transaction: Transaction
  companyName: string
  companyFullName?: string
  companyAddress: string
  companyTaxNumber: string
  companyPhone?: string
  branchName: string
  branchCode?: string
  branchAddress?: string
  branchPhone?: string
  workerName: string
  onClose: () => void
}

const MEDIUM_THRESHOLD = 100_000
const HIGH_THRESHOLD = 300_000

export default function ReceiptPrint({
  transaction,
  companyName,
  companyFullName,
  companyAddress,
  companyTaxNumber,
  companyPhone,
  branchName,
  branchCode,
  branchAddress,
  branchPhone,
  workerName,
  onClose
}: ReceiptPrintProps) {
  const { t } = useTranslation()
  const printRef = useRef<HTMLDivElement>(null)

  const generateQrData = () => {
    return [
      transaction.receiptNumber,
      new Date(transaction.createdAt).toLocaleDateString('hu-HU'),
      Math.round(transaction.roundedHufAmount ?? transaction.hufAmount ?? 0).toString(),
      transaction.currencyCode ?? 'HUF',
      companyTaxNumber,
      branchCode ?? ''
    ].join('|')
  }

  const [qrDataUrl, setQrDataUrl] = useState<string>('')
  useEffect(() => {
    const qrContent = generateQrData()
    if (qrContent) {
      QRCode.toDataURL(qrContent, {
        width: 120,
        margin: 1,
        errorCorrectionLevel: 'M',
      }).then(setQrDataUrl).catch(() => setQrDataUrl(''))
    }
  }, [transaction, companyTaxNumber, branchCode]) // eslint-disable-line react-hooks/exhaustive-deps

  const handlePrint = () => {
    const printContent = printRef.current
    if (!printContent) return

    const printWindow = window.open('', '_blank')
    if (!printWindow) {
      toast.warning('Nyomtatás sikertelen', 'Engedélyezze a felugró ablakokat a nyomtatáshoz!')
      return
    }

    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Bizonylat - ${transaction.receiptNumber}</title>
        <style>
          @page { size: 80mm auto; margin: 2mm; }
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: 'Courier New', monospace; font-size: 11px; line-height: 1.4; width: 76mm; color: #000; }
          .receipt { width: 76mm; margin: 0 auto; }
          .center { text-align: center; }
          .bold { font-weight: bold; }
          .company-name { font-size: 14px; font-weight: bold; }
          .receipt-title { font-size: 16px; font-weight: bold; margin: 4px 0; }
          .receipt-subtype { font-size: 13px; font-weight: bold; margin: 2px 0; }
          .receipt-subtype-en { font-size: 11px; margin: 1px 0; }
          .row { display: flex; justify-content: space-between; margin: 2px 0; }
          .separator { border-top: 1px dashed #000; margin: 4px 0; }
          .double-separator { border-top: 2px solid #000; margin: 4px 0; }
          .total { font-size: 14px; font-weight: bold; margin: 4px 0; }
          .signature-row { display: flex; justify-content: space-around; margin-top: 12px; }
          .signature-block { text-align: center; }
          .signature-line { border-top: 1px solid #000; width: 100px; display: inline-block; margin-bottom: 2px; }
          .footer { text-align: center; font-size: 9px; color: #666; margin-top: 8px; }
          .vat-exempt { font-size: 9px; margin: 6px 0; }
          .customer-section { margin: 6px 0; padding: 4px; }
          .currency-table { width: 100%; font-size: 10px; margin: 4px 0; }
          .currency-table td { padding: 1px 2px; }
        </style>
      </head>
      <body>
        ${printContent.innerHTML}
      </body>
      </html>
    `)

    printWindow.document.close()
    printWindow.focus()
    printWindow.print()
    printWindow.close()
  }

  const subtypeHu = transaction.transactionType === 'BUY' ? 'Valuta vétel'
    : transaction.transactionType === 'SELL' ? 'Valuta eladás'
    : transaction.transactionType === 'REVERSAL' ? '*** Sztornó ***'
    : transaction.transactionType === 'CONVERSION' ? 'Konverziós bizonylat'
    : transaction.transactionType

  const subtypeEn = transaction.transactionType === 'BUY' ? 'EXCHANGE (PURCHASE)'
    : transaction.transactionType === 'SELL' ? 'EXCHANGE (SELLING)'
    : transaction.transactionType === 'REVERSAL' ? '*** REVERSAL ***'
    : transaction.transactionType === 'CONVERSION' ? 'CONVERSION'
    : ''

  const displayCompanyName = companyFullName || companyName
  const absHuf = Math.abs(transaction.hufAmount ?? 0)
  const isHighValue = absHuf >= HIGH_THRESHOLD
  const isMediumValue = absHuf >= MEDIUM_THRESHOLD

  const roundingDiff = transaction.roundingDiff ?? 0
  const netTotal = transaction.roundedHufAmount ?? transaction.hufAmount ?? 0
  const fee = transaction.handlingFee ?? 0
  const paid = netTotal + fee

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b">
          <h2 className="text-lg font-semibold">{t('components.bizonylatElonezet')}</h2>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={handlePrint}
              className="form-button-primary flex items-center gap-1"
            >
              <Printer size={16} />
              {t('common.print')}
            </button>
            <button
              type="button"
              onClick={onClose}
              className="form-button"
            >
              <X size={16} />
            </button>
          </div>
        </div>

        {/* Receipt preview */}
        <div className="p-4">
          <div
            ref={printRef}
            className="receipt bg-white p-4 border rounded font-mono text-xs mx-auto"
            style={{ maxWidth: '300px' }}
          >
            {/* === FEJLÉC — NYUGTA + Cég + Tranzakció típus === */}
            <div className="center">
              <div className="receipt-title">NYUGTA</div>
              <div className="company-name">{displayCompanyName}</div>
              {branchName && <div className="text-xs">{branchName}</div>}
              {branchAddress && <div className="text-xs text-gray-600">{branchAddress}</div>}
              {companyAddress && !branchAddress && <div className="text-xs text-gray-600">{companyAddress}</div>}
              {(branchPhone || companyPhone) && (
                <div className="text-xs text-gray-600">Telefon: {branchPhone || companyPhone}</div>
              )}
              <div className="text-xs text-gray-600">Adószám: {companyTaxNumber}</div>
              <div className="receipt-subtype">{subtypeHu}</div>
              <div className="receipt-subtype-en">{subtypeEn}</div>
            </div>

            <div className="separator" />

            {/* === BIZONYLAT ADATOK (kétnyelvű) === */}
            <div className="row"><span>Sorszám (INVOICE NR)</span><span className="bold">{transaction.receiptNumber}</span></div>
            <div className="row">
              <span>Dátum (DATE)</span>
              <span>{new Date(transaction.createdAt).toLocaleDateString('hu-HU')}</span>
            </div>
            <div className="row">
              <span>Idő (TIME)</span>
              <span>{new Date(transaction.createdAt).toLocaleTimeString('hu-HU')}</span>
            </div>

            <div className="separator" />

            {/* === ÁFA-MENTESSÉGI SZÖVEG (a valutatáblázat ELŐTT) === */}
            <div className="vat-exempt">
              <div>Szj - 67.13.10.0</div>
              <div>Adómentes  a szolgáltatás nyújtása a 2007</div>
              <div>M.Á.A. evi CXVII tv. 86 § e) alapján</div>
              <div>mentes az adó alól</div>
            </div>

            <div className="separator" />

            {/* === VALUTA TÁBLÁZAT === */}
            <table className="currency-table">
              <thead>
                <tr>
                  <td className="bold">V.nem</td>
                  <td className="bold">Árfolyam</td>
                  <td className="bold">B.jegy</td>
                  <td className="bold" style={{ textAlign: 'right' }}>Forint</td>
                </tr>
                <tr style={{ fontSize: '9px' }}>
                  <td>CURR.</td>
                  <td>RATE</td>
                  <td>CASH</td>
                  <td style={{ textAlign: 'right' }}>VALUE</td>
                </tr>
              </thead>
            </table>
            <div className="separator" />
            <table className="currency-table">
              <tbody>
                <tr>
                  <td className="bold">{transaction.currencyCode}</td>
                  <td>{formatDecimal(transaction.exchangeRate, 2, 4)}</td>
                  <td>{formatDecimal(transaction.currencyAmount, 2, 2)}</td>
                  <td style={{ textAlign: 'right' }}>{formatInteger(transaction.hufAmount)}</td>
                </tr>
              </tbody>
            </table>
            <div className="separator" />

            {/* === ÖSSZESÍTÉS (kétnyelvű) === */}
            <div className="row"><span>Kerekítés (ROUNDING)</span><span>{formatInteger(roundingDiff)}</span></div>
            <div className="row"><span>Nettó Ft (SUM TOTAL)</span><span>{formatInteger(netTotal)}</span></div>
            <div className="row"><span>Kez. kltsg (HANDLING FEE)</span><span>{formatInteger(fee)}</span></div>
            <div className="row bold total"><span>Kifizetve:(PAID):</span><span>{formatInteger(paid)}</span></div>

            <div className="separator" />

            {/* === ÜGYFÉL ADATOK (3 szintű: <100k / 100k-300k / 300k+) === */}
            <div className="customer-section">
              <div className="center bold" style={{ marginBottom: '4px' }}>--- ügyfél adatai ---</div>

              {isMediumValue && (
                <div className="space-y-0.5">
                  {transaction.customerName && (
                    <div className="row"><span>Neve:</span><span>{transaction.customerName}</span></div>
                  )}
                  {transaction.customerMotherName && (
                    <div className="row"><span>Anyja neve:</span><span>{transaction.customerMotherName}</span></div>
                  )}
                  {transaction.customerBirthPlace && (
                    <div className="row"><span>Szül-i hely:</span><span>{transaction.customerBirthPlace}</span></div>
                  )}
                  {transaction.customerBirthDate && (
                    <div className="row"><span>Szül-i idő:</span><span>{transaction.customerBirthDate}</span></div>
                  )}

                  {isHighValue && (
                    <>
                      {transaction.customerAddress && (
                        <div className="row"><span>Lakcím(ADDRESS):</span><span>{transaction.customerAddress}</span></div>
                      )}
                      {transaction.customerDocType && (
                        <div className="row"><span>DOC TYPE:</span><span>{transaction.customerDocType}</span></div>
                      )}
                      {transaction.customerDocumentNumber && (
                        <div className="row"><span>NR.:</span><span>{transaction.customerDocumentNumber}</span></div>
                      )}
                      <div>{transaction.customerIsPep ? 'Az ügyfél kiemelt közszereplő' : 'Az ügyfél nem közszereplő'}</div>
                    </>
                  )}
                </div>
              )}

              <div style={{ marginTop: '4px' }}>Az ügyletet készpénzben teljesítjük</div>
              <div>Deviza-státusz: {transaction.foreignStatus == null ? '—' : (transaction.foreignStatus === 'FOREIGN' ? 'Külföldi' : 'Belföldi')}</div>
            </div>

            <div className="separator" />

            {/* === 300k+ FELETT: Bankpartner + marketing === */}
            {isHighValue && (
              <>
                <div className="center" style={{ margin: '4px 0' }}>
                  <div>Raiffeisen Bank Zrt.</div>
                  <div>KIEMELT KÖZVETÍTŐJE</div>
                </div>
                <div className="separator" />
                <div className="center bold" style={{ margin: '4px 0' }}>
                  <div>EXCLUSIVE CHANGE</div>
                  <div>KEDVEZŐBB,</div>
                  <div>GYORSABB,</div>
                  <div>BIZTONSÁGOSABB</div>
                </div>
                <div className="separator" />

                {/* JOGCÍM NYILATKOZAT */}
                <div style={{ margin: '4px 0' }}>
                  <div className="bold">JOGCÍM NYILATKOZAT</div>
                  <div style={{ fontSize: '10px', lineHeight: '1.3' }}>
                    Büntetőjogi felelősségem tudatában nyilatkozom, hogy a fenti tranzakciót saját nevemben bonyolítom,
                  </div>
                  {transaction.sourceOfFunds && (
                    <div style={{ marginTop: '2px' }}>
                      <span>Pénzeszközöm forrása: </span>
                      <span className="bold">{transaction.sourceOfFunds}</span>
                    </div>
                  )}
                </div>
                <div className="separator" />
              </>
            )}

            {/* === PÉNZTÁROS + ALÁÍRÁS SOROK === */}
            <div style={{ margin: '4px 0' }}>Pénztáros: {workerName}</div>
            <div className="signature-row">
              <div className="signature-block">
                <div className="signature-line" />
                <div>Pénztáros</div>
              </div>
              <div className="signature-block">
                <div className="signature-line" />
                <div>Ügyfél</div>
              </div>
            </div>

            {/* === QR KÓD === */}
            <div className="center" style={{ margin: '8px 0', textAlign: 'center' }}>
              {qrDataUrl ? (
                <img src={qrDataUrl} alt="QR" style={{ width: '100px', height: '100px' }} />
              ) : (
                <div style={{ fontSize: '8px', color: '#999' }}>QR: {generateQrData()}</div>
              )}
            </div>

            {/* === LÁBLÉC === */}
            <div className="footer">
              <div>Köszönjük, hogy minket választott!</div>
              <div style={{ marginTop: '4px' }}>
                A bizonylat a pénzmosás elleni törvény alapján nem helyettesíti a számlát.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
