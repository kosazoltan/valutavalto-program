import { useRef } from 'react'
import { Printer, X, QrCode as QrCodeIcon } from 'lucide-react'
import { Transaction } from '../services/api'
import { formatDecimal, formatInteger } from '../utils/numberFormat'

interface ReceiptPrintProps {
  transaction: Transaction
  companyName: string
  companyAddress: string
  companyTaxNumber: string
  branchName: string
  workerName: string
  onClose: () => void
}

/**
 * Bizonylat nyomtatási komponens
 *
 * Legacy: BIZONYLAT.DLL
 * - A4 vagy blokk nyomtatási formátum
 * - QR kód NAV ellenőrzéshez
 * - Törvényi kötelező adatok
 */
export default function ReceiptPrint({
  transaction,
  companyName,
  companyAddress,
  companyTaxNumber,
  branchName,
  workerName,
  onClose
}: ReceiptPrintProps) {
  const printRef = useRef<HTMLDivElement>(null)

  // Generate QR code data (NAV format)
  const generateQrData = () => {
    return JSON.stringify({
      receiptNumber: transaction.receiptNumber,
      date: transaction.createdAt,
      type: transaction.transactionType,
      currencyCode: transaction.currencyCode,
      amount: transaction.currencyAmount,
      hufAmount: transaction.hufAmount,
      taxNumber: companyTaxNumber
    })
  }

  // Simple QR code placeholder (in production, use a QR library like qrcode.react)
  const QRCodePlaceholder = ({ data: _data }: { data: string }) => (
    <div className="w-24 h-24 border-2 border-gray-300 flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <QrCodeIcon size={32} className="mx-auto text-gray-400" />
        <div className="text-xs text-gray-400 mt-1">QR</div>
      </div>
    </div>
  )

  const handlePrint = () => {
    const printContent = printRef.current
    if (!printContent) return

    const printWindow = window.open('', '_blank')
    if (!printWindow) {
      alert('Engedélyezze a felugró ablakokat a nyomtatáshoz!')
      return
    }

    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Bizonylat - ${transaction.receiptNumber}</title>
        <style>
          @page { size: 80mm auto; margin: 5mm; }
          body { font-family: 'Courier New', monospace; font-size: 12px; }
          .receipt { width: 70mm; margin: 0 auto; }
          .header { text-align: center; border-bottom: 1px dashed #000; padding-bottom: 8px; margin-bottom: 8px; }
          .company-name { font-size: 14px; font-weight: bold; }
          .row { display: flex; justify-content: space-between; margin: 4px 0; }
          .label { color: #666; }
          .value { font-weight: bold; text-align: right; }
          .total { font-size: 16px; border-top: 1px solid #000; border-bottom: 1px solid #000; padding: 8px 0; margin: 8px 0; }
          .footer { text-align: center; font-size: 10px; color: #666; margin-top: 12px; border-top: 1px dashed #000; padding-top: 8px; }
          .qr { text-align: center; margin: 12px 0; }
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
      case 'BUY': return 'VÉTEL'
      case 'SELL': return 'ELADÁS'
      case 'REVERSAL': return 'SZTORNÓ'
      case 'CONVERSION': return 'KONVERZIÓ'
      default: return transaction.transactionType
    }
  }

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
            className="receipt bg-white p-4 border rounded font-mono text-sm mx-auto"
            style={{ maxWidth: '300px' }}
          >
            {/* Header */}
            <div className="header text-center border-b border-dashed pb-3 mb-3">
              <div className="company-name text-base font-bold">{companyName}</div>
              <div className="text-xs text-gray-600">{companyAddress}</div>
              <div className="text-xs text-gray-600">Adószám: {companyTaxNumber}</div>
              <div className="text-xs mt-1">{branchName}</div>
            </div>

            {/* Transaction type */}
            <div className="text-center mb-3">
              <span className={`px-3 py-1 text-sm font-bold rounded ${
                transaction.transactionType === 'BUY' ? 'bg-green-100 text-green-700' :
                transaction.transactionType === 'SELL' ? 'bg-blue-100 text-blue-700' :
                transaction.transactionType === 'REVERSAL' ? 'bg-red-100 text-red-700' :
                'bg-gray-100 text-gray-700'
              }`}>
                {transactionTypeDisplay()}
              </span>
            </div>

            {/* Receipt number */}
            <div className="text-center mb-3">
              <div className="text-xs text-gray-500">Bizonylatszám</div>
              <div className="text-lg font-bold">{transaction.receiptNumber}</div>
            </div>

            {/* Date/Time */}
            <div className="row flex justify-between text-xs mb-3">
              <span>Dátum:</span>
              <span>{new Date(transaction.createdAt).toLocaleDateString('hu-HU')}</span>
            </div>
            <div className="row flex justify-between text-xs mb-3">
              <span>Idő:</span>
              <span>{new Date(transaction.createdAt).toLocaleTimeString('hu-HU')}</span>
            </div>

            {/* Currency details */}
            <div className="border-t border-b py-2 my-2">
              <div className="row flex justify-between">
                <span>Valuta:</span>
                <span className="font-bold">{transaction.currencyCode}</span>
              </div>
              <div className="row flex justify-between">
                <span>Összeg:</span>
                <span className="font-bold">
                  {formatDecimal(transaction.currencyAmount, 2, 2)} {transaction.currencyCode}
                </span>
              </div>
              <div className="row flex justify-between">
                <span>Árfolyam:</span>
                <span>{formatDecimal(transaction.exchangeRate, 2, 4)}</span>
              </div>
            </div>

            {/* HUF amount (highlighted) */}
            <div className="total bg-gray-100 p-2 rounded text-center my-3">
              <div className="text-xs text-gray-500">
                {transaction.transactionType === 'BUY' ? 'Fizetendő:' : 'Kapott összeg:'}
              </div>
              <div className="text-xl font-bold">
                {formatInteger(transaction.hufAmount)} Ft
              </div>
            </div>

            {/* Fees */}
            {transaction.handlingFee && transaction.handlingFee > 0 && (
              <div className="row flex justify-between text-xs">
                <span>Kezelési díj:</span>
                <span>{formatInteger(transaction.handlingFee)} Ft</span>
              </div>
            )}

            {/* Customer info (if available) */}
            {transaction.customerName && (
              <div className="border-t pt-2 mt-2 text-xs">
                <div className="row flex justify-between">
                  <span>Ügyfél:</span>
                  <span>{transaction.customerName}</span>
                </div>
              </div>
            )}

            {/* QR Code */}
            <div className="qr flex justify-center my-4">
              <QRCodePlaceholder data={generateQrData()} />
            </div>

            {/* Footer */}
            <div className="footer text-center text-xs text-gray-500 border-t border-dashed pt-3 mt-3">
              <div>Pénztáros: {workerName}</div>
              <div className="mt-2">
                Köszönjük, hogy minket választott!
              </div>
              <div className="mt-2 text-[10px]">
                A bizonylat a pénzmosás elleni törvény
                <br />
                alapján nem helyettesíti a számlát.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
