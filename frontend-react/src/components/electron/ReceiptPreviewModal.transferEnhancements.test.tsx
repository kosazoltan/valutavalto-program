import { render } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import ReceiptPreviewModal from './ReceiptPreviewModal'
import type { PrintReceiptData } from '../../types/receipt'

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (k: string) => k }),
}))

const base: PrintReceiptData = {
  type: 'transfer',
  companyType: 'BEST_CHANGE',
  receiptNumber: 'AT-000042',
  branchCode: 'Szeged Értéktár',
  cashierName: 'Bali Henriett',
  date: '2026. 06. 07.',
  time: '10:00:00',
  currencyCode: 'EUR',
  foreignAmount: 1000,
  roundedHufAmount: 405000,
  transferTarget: 'BR060 - Szeged Tesco',
  carrierName: 'Gyors Futár Kft.',
  sealNumber: 'PL-12345',
}

function renderModal(data: PrintReceiptData) {
  return render(
    <ReceiptPreviewModal
      isOpen
      onClose={() => {}}
      receiptData={data}
      qrCodeDataUrl={null}
      onPrint={async () => {}}
    />,
  )
}

describe('ReceiptPreviewModal — átadás-átvétel bővítések (FK02-E transfer)', () => {
  it('FR-1: a fejlécben a cégnév marad, de az értéktár SAJÁT címe jelenik meg (nem a székhely)', () => {
    const { container } = renderModal({ ...base, vaultAddress: 'Szeged, Hajnóczy u. 57., 6722' })
    const txt = container.textContent ?? ''
    expect(txt).toContain('EXCLUSIVE BEST CHANGE ZRT.')
    expect(txt).toContain('Szeged, Hajnóczy u. 57., 6722')
    // NEM a BEST_CHANGE hardcode székhelycím (Pécs)
    expect(txt).not.toContain('Citrom utca')
  })

  it('FR-2: transferDocType=receipt → „Átvételi bizonylat" cím', () => {
    const { container } = renderModal({ ...base, transferDocType: 'receipt' })
    expect(container.textContent ?? '').toContain('Átvételi bizonylat')
  })

  it('Fejléc-javítás FR-1/FR-3: hiányzó vaultAddress esetén transfer bizonylaton NEM jelenik meg hardcode-olt székhelycím', () => {
    const { container } = renderModal({ ...base, vaultAddress: undefined })
    const txt = container.textContent ?? ''
    expect(txt).not.toContain('Citrom utca')
    expect(txt).not.toContain('Pécs')
  })

  it('Fejléc-javítás FR-2: a vaultPhone „Tel:" sorként jelenik meg a fejlécben', () => {
    const { container } = renderModal({ ...base, vaultPhone: '06703800161' })
    expect(container.textContent ?? '').toContain('Tel: 06703800161')
  })

  it('Fejléc-javítás TBD-3: hiányzó vaultPhone esetén nincs „Tel:" sor (nem üres sor, nem „null")', () => {
    const { container } = renderModal({ ...base, vaultPhone: undefined })
    const txt = container.textContent ?? ''
    expect(txt).not.toContain('Tel:')
    expect(txt).not.toContain('null')
  })

  it('Fejléc-javítás FR-5: átvételi bizonylaton megjelenik a kötelező jogi nyilatkozat', () => {
    const { container } = renderModal({ ...base, transferDocType: 'receipt' })
    const txt = container.textContent ?? ''
    expect(txt).toContain('Büntetőjogi felelősségem tudatában')
    expect(txt).toContain('pénzkészletet a szállítóktól átvettem, azt tételesen átszámoltam')
  })

  it('Fejléc-javítás FR-5: átadási bizonylaton a jogi nyilatkozat NEM jelenik meg', () => {
    const { container } = renderModal({ ...base, transferDocType: 'handover' })
    expect(container.textContent ?? '').not.toContain('Büntetőjogi felelősségem tudatában')
  })

  it('Fejléc-javítás FR-5: sztornó bizonylaton a jogi nyilatkozat NEM jelenik meg (átvételi irány esetén sem)', () => {
    const { container } = renderModal({
      ...base,
      transferDocType: 'receipt',
      isStorno: true,
      stornoReason: 'Téves',
    })
    expect(container.textContent ?? '').not.toContain('Büntetőjogi felelősségem tudatában')
  })

  it('Fejléc-javítás FR-6: átvételi bizonylaton a nyilatkozat alatt Átadó és Átvevő aláírás vonalak vannak', () => {
    const { container } = renderModal({ ...base, transferDocType: 'receipt' })
    const txt = container.textContent ?? ''
    expect(txt).toContain('Átadó')
    expect(txt).toContain('Átvevő')
  })

  it('FR-2: transferDocType=handover (alapért.) → „Átadási bizonylat" cím', () => {
    const { container } = renderModal({ ...base, transferDocType: 'handover' })
    expect(container.textContent ?? '').toContain('Átadási bizonylat')
  })

  it('FR-13/FR-15: sztornó bizonylat fejléce „SZTORNÓ BIZONYLAT" + tartalmazza az indoklást', () => {
    const { container } = renderModal({
      ...base,
      receiptNumber: 'AT-000042-SZ',
      isStorno: true,
      stornoReason: 'Téves rögzítés',
    })
    const txt = container.textContent ?? ''
    expect(txt).toContain('SZTORNÓ BIZONYLAT')
    expect(txt).toContain('Sztornó indoklása:')
    expect(txt).toContain('Téves rögzítés')
    expect(txt).toContain('AT-000042-SZ')
  })

  it('FR-17/FR-18: ha van címletezés, a táblázat minden sora megjelenik', () => {
    const { container } = renderModal({
      ...base,
      denominations: [
        { quantity: 5, faceValue: 100, currencyCode: 'EUR', lineTotal: 500 },
        { quantity: 10, faceValue: 50, currencyCode: 'EUR', lineTotal: 500 },
      ],
    })
    const txt = container.textContent ?? ''
    expect(txt).toContain('Címletezés')
    expect(txt).toContain('5')
    expect(txt).toContain('10')
  })

  it('FR-19: ha nincs címletezés, a „Címletezés" szekció NEM jelenik meg', () => {
    const { container } = renderModal({ ...base, denominations: [] })
    expect(container.textContent ?? '').not.toContain('Címletezés')
  })

  it('regresszió: nem-HUF átadásnál hiányzó forint-érték esetén NEM jelenik meg „0 HUF"', () => {
    // online nem-HUF eset: a backend hufValue=null → roundedHufAmount=null kerül a receiptData-ba
    const { container } = renderModal({
      ...base,
      roundedHufAmount: undefined,
      hufAmount: undefined,
    })
    expect(container.textContent ?? '').not.toContain('Forint érték:')
  })
})
