import { useRef, useEffect, useState } from 'react'
import QRCode from 'qrcode'
import { Printer, X } from 'lucide-react'
import { Transaction } from '../services/api/index'
import { formatDecimal, formatInteger } from '../utils/numberFormat'
import { toast } from './ui/toaster'

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

/**
 * Bizonylat nyomtatási komponens — 80mm termál nyomtatóra optimalizálva.
 *
 * Legacy: BIZONYLAT.DLL
 * Tartalmazza:
 * - Cég fejléc (teljes név, cím, telefon, adószám, pénztárszám)
 * - ÁFA-mentességi szöveg (törvényi kötelező: Szj 67.13.10.0, 2007. évi CXVII tv. 85. § e))
 * - Teljes ügyfél adatok 300.000 Ft felett
 * - Két aláírás sor (pénztáros + ügyfél)
 * - QR kód NAV-kompatibilis formátumban
 */
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
  const printRef = useRef<HTMLDivElement>(null)

  // QR kód tartalom (NAV-kompatibilis: pipe-separated)
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

  // QR kód SVG data URL generálás
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
          .receipt-type { font-size: 14px; font-weight: bold; margin: 4px 0; }
          .row { display: flex; justify-content: space-between; margin: 2px 0; }
          .separator { border-top: 1px dashed #000; margin: 4px 0; }
          .double-separator { border-top: 2px solid #000; margin: 4px 0; }
          .total { font-size: 14px; font-weight: bold; margin: 4px 0; }
          .signature-row { display: flex; justify-content: space-around; margin-top: 12px; }
          .signature-block { text-align: center; }
          .signature-line { border-top: 1px solid #000; width: 100px; display: inline-block; margin-bottom: 2px; }
          .footer { text-align: center; font-size: 9px; color: #666; margin-top: 8px; }
          .vat-exempt { font-size: 9px; margin: 6px 0; }
          .customer-section { margin: 6px 0; padding: 4px; border: 1px solid #ccc; }
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

  const transactionTypeDisplay = () => {
    switch (transaction.transactionType) {
      case 'BUY': return 'VÉTELI BIZONYLAT'
      case 'SELL': return 'ELADÁSI BIZONYLAT'
      case 'REVERSAL': return 'SZTORNÓ BIZONYLAT'
      case 'CONVERSION': return 'KONVERZIÓS BIZONYLAT'
      default: return transaction.transactionType
    }
  }

  const displayCompanyName = companyFullName || companyName

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b">
          <h2 className="text-lg font-semibold">Bizonylat előnézet</h2>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={handlePrint}
              className="form-button-primary flex items-center gap-1"
            >
              <Printer size={16} />
              Nyomtatás
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
            {/* === FEJLÉC === */}
            <div className="center">
              <div className="company-name">{displayCompanyName}</div>
              {branchName && <div className="text-xs">{branchName}</div>}
              {branchAddress && <div className="text-xs text-gray-600">{branchAddress}</div>}
              {companyAddress && !branchAddress && <div className="text-xs text-gray-600">{companyAddress}</div>}
              {(branchPhone || companyPhone) && (
                <div className="text-xs text-gray-600">Tel: {branchPhone || companyPhone}</div>
              )}
              <div className="text-xs text-gray-600">Adószám: {companyTaxNumber}</div>
              {branchCode && <div className="text-xs">Pénztár: {branchCode}</div>}
            </div>

            <div className="double-separator" />

            {/* === BIZONYLAT TÍPUS === */}
            <div className="center">
              <span className={`receipt-type ${
                transaction.transactionType === 'BUY' ? 'text-green-700' :
                transaction.transactionType === 'SELL' ? 'text-blue-700' :
                transaction.transactionType === 'REVERSAL' ? 'text-red-700' :
                transaction.transactionType === 'CONVERSION' ? 'text-purple-700' :
                'text-gray-700'
              }`}>
                {transactionTypeDisplay()}
              </span>
            </div>

            <div className="double-separator" />

            {/* === ALAP ADATOK === */}
            <div className="row"><span>Bizonylat:</span><span className="bold">{transaction.receiptNumber}</span></div>
            <div className="row">
              <span>Dátum:</span>
              <span>{new Date(transaction.createdAt).toLocaleDateString('hu-HU')} {new Date(transaction.createdAt).toLocaleTimeString('hu-HU')}</span>
            </div>
            <div className="row"><span>Pénztáros:</span><span>{workerName}</span></div>

            <div className="separator" />

            {/* === TRANZAKCIÓ RÉSZLETEK === */}
            <div className="row"><span>Valuta:</span><span className="bold">{transaction.currencyCode}</span></div>
            <div className="row">
              <span>Összeg:</span>
              <span className="bold">{formatDecimal(transaction.currencyAmount, 2, 2)} {transaction.currencyCode}</span>
            </div>
            <div className="row"><span>Árfolyam:</span><span>{formatDecimal(transaction.exchangeRate, 2, 4)}</span></div>

            <div className="separator" />

            {/* HUF összeg */}
            <div className="row bold">
              <span>HUF összeg:</span>
              <span>{formatInteger(transaction.hufAmount)} Ft</span>
            </div>

            {/* Kerekítés (ha van) */}
            {transaction.roundingDiff !== undefined && transaction.roundingDiff !== null && transaction.roundingDiff !== 0 && (
              <>
                <div className="row text-gray-600">
                  <span>Kerekítés:</span>
                  <span>{formatInteger(transaction.roundingDiff)} Ft</span>
                </div>
                <div className="total row">
                  <span>FIZETENDŐ:</span>
                  <span>{formatInteger(transaction.roundedHufAmount ?? transaction.hufAmount)} Ft</span>
                </div>
              </>
            )}

            {/* Kezelési díj */}
            {transaction.handlingFee != null && transaction.handlingFee > 0 && (
              <div className="row">
                <span>Kezelési díj:</span>
                <span>{formatInteger(transaction.handlingFee)} Ft</span>
              </div>
            )}

            {/* === ÜGYFÉL ADATOK (300K felett kötelező) === */}
            {transaction.customerName && (
              <div className="customer-section">
                <div className="bold" style={{ marginBottom: '2px' }}>ÜGYFÉL ADATOK:</div>
                <div className="row"><span>Név:</span><span>{transaction.customerName}</span></div>
                {transaction.customerBirthPlace && (
                  <div className="row"><span>Szül. hely:</span><span>{transaction.customerBirthPlace}</span></div>
                )}
                {transaction.customerBirthDate && (
                  <div className="row"><span>Szül. idő:</span><span>{transaction.customerBirthDate}</span></div>
                )}
                {transaction.customerMotherName && (
                  <div className="row"><span>Anyja neve:</span><span>{transaction.customerMotherName}</span></div>
                )}
                {transaction.customerAddress && (
                  <div className="row"><span>Lakcím:</span><span>{transaction.customerAddress}</span></div>
                )}
                {transaction.customerDocType && (
                  <div className="row"><span>Okmány:</span><span>{transaction.customerDocType}</span></div>
                )}
                {transaction.customerDocumentNumber && (
                  <div className="row"><span>Okmányszám:</span><span>{transaction.customerDocumentNumber}</span></div>
                )}
                {transaction.customerNationality && (
                  <div className="row"><span>Állampolgárság:</span><span>{transaction.customerNationality}</span></div>
                )}
              </div>
            )}

            {/* === PEP (KÖZSZEREPLŐ) NYILATKOZAT — 300k+ Ft, JOGSZABÁLYI KÖTELEZŐ === */}
            {transaction.hufAmount != null && Math.abs(transaction.hufAmount) >= 300000 && (
              <div style={{ margin: '6px 0', padding: '4px', border: '1px solid #999' }}>
                <div className="bold" style={{ marginBottom: '2px' }}>KÖZSZEREPLŐI NYILATKOZAT</div>
                <div>{transaction.customerIsPep ? 'Az ügyfél kiemelt közszereplő' : 'Nem közszereplő'}</div>
              </div>
            )}

            {/* === JOGCÍM NYILATKOZAT — 300k+ Ft, JOGSZABÁLYI KÖTELEZŐ === */}
            {transaction.hufAmount != null && Math.abs(transaction.hufAmount) >= 300000 && (
              <div style={{ margin: '6px 0', padding: '4px', border: '1px solid #999' }}>
                <div className="bold" style={{ marginBottom: '2px' }}>JOGCÍM NYILATKOZAT</div>
                <div style={{ fontSize: '10px', lineHeight: '1.3' }}>
                  Büntetőjogi felelősségem tudatában
                  nyilatkozom, hogy a fenti tranzakciót
                  saját nevemben bonyolítom,
                </div>
                {transaction.sourceOfFunds && (
                  <div style={{ marginTop: '2px' }}>
                    <span>Pénzeszközöm forrása: </span>
                    <span className="bold">{transaction.sourceOfFunds}</span>
                  </div>
                )}
              </div>
            )}

            <div className="separator" />

            {/* === ÁFA-MENTESSÉGI SZÖVEG (TÖRVÉNYI KÖTELEZŐ) === */}
            <div className="vat-exempt">
              <div>Szj 67.13.10.0</div>
              <div>Az ÁFA alól mentes: 2007. évi CXVII tv. 85. § e)</div>
            </div>

            <div className="separator" />

            {/* === ALÁÍRÁS SOROK === */}
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
                A bizonylat a pénzmosás elleni törvény
                alapján nem helyettesíti a számlát.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
