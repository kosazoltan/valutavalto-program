import { ReceiptPreviewModal } from '../../components/electron'
import { isElectron } from '../../utils/electron'
import { toast } from '../../components/ui/toaster'
import type { PrintReceiptData } from '../../types/receipt'

export default function TransferReceiptModal({
  isOpen,
  onClose,
  receiptData,
}: {
  isOpen: boolean
  onClose: () => void
  receiptData: PrintReceiptData | null
}) {
  return (
    <ReceiptPreviewModal
      isOpen={isOpen}
      onClose={onClose}
      receiptData={receiptData}
      qrCodeDataUrl={null}
      allowPrint={isElectron()}
      onPrint={async () => {
        // Copilot PR #1100 (storno-minta): a hibás ágak THROW-val zárulnak — a
        // ReceiptPreviewModal csak SIKERES onPrint után zár be (2s auto-close),
        // hiba esetén nyitva marad és újrapróbálható.
        if (!receiptData) throw new Error('Nincs aktív bizonylat-adat')
        if (!window.electronAPI?.printReceipt) {
          toast.warning(
            'Nyomtatás nem elérhető',
            isElectron()
              ? 'Electron preload/electronAPI hiba — indítsa újra a klienst.'
              : 'Webes módban nincs nyomtatás. Telepítse az Electron klienst.',
          )
          throw new Error('printReceipt nem elérhető')
        }
        try {
          const ok = await window.electronAPI.printReceipt(JSON.stringify(receiptData))
          if (!ok) {
            toast.error(
              'Nyomtatás sikertelen',
              'Ellenőrizze a nyomtatót (Beállítások > Nyomtatás).',
            )
            throw new Error('Nyomtatás sikertelen')
          }
          toast.success('Nyomtatás elindítva', `Bizonylat: ${receiptData.receiptNumber ?? '—'}`)
        } catch (err) {
          if (!(err instanceof Error && err.message === 'Nyomtatás sikertelen')) {
            toast.error('Nyomtatás sikertelen', 'A nyomtatási parancs nem futott le.')
          }
          throw err
        }
      }}
    />
  )
}
