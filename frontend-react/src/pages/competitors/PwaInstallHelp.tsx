import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Smartphone, ChevronDown, ChevronUp } from 'lucide-react'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

/**
 * FK-041/II — „Telepítés a telefonra" segéd. A local-first NEM telepíthető telefonra, ezért az árfolyam
 * néző a web-appot telepíti PWA-ként (Android Chrome / iOS Safari): megnyitja a címet (vagy beolvassa a
 * QR-kódot), bejelentkezik, és kiteszi a kezdőképernyőre — onnantól egy gombbal indítható alkalmazásként.
 *
 * A QR-kód egy MÁSIK eszközről (pl. a főértéktáros desktop-képernyőjéről) beolvasva köti össze a néző
 * telefonját; a telepítési lépések a néző telefonján is olvashatók.
 */
export default function PwaInstallHelp({ url, title }: { url?: string; title?: string }) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [qr, setQr] = useState<string>('')
  const target = url ?? (typeof window !== 'undefined' ? window.location.origin : '')

  useEffect(() => {
    if (!open || qr || !target) return
    let cancelled = false
    void (async () => {
      try {
        const mod = await import('qrcode')
        const dataUrl = await mod.toDataURL(target, {
          width: 180,
          margin: 1,
          errorCorrectionLevel: 'M',
        })
        if (!cancelled) setQr(dataUrl)
      } catch (err) {
        logger.warn('PwaInstallHelp', 'QR generálás sikertelen:', err)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [open, qr, target])

  return (
    <div className="form-panel mt-4" data-testid="pwa-install-help">
      <button
        type="button"
        className="flex w-full items-center justify-between text-left"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        data-testid="pwa-install-toggle"
      >
        <span className="flex items-center gap-2 text-sm font-semibold text-gray-700">
          <Smartphone size={18} className="text-blue-700" />
          {title ?? t('pwaInstall.cim')}
        </span>
        {open ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
      </button>

      {open && (
        <div className="mt-3 space-y-3 text-sm text-gray-600">
          <p>{t('pwaInstall.leiras')}</p>
          <div className="flex flex-col items-start gap-3 sm:flex-row sm:items-center">
            {qr && (
              <img
                src={qr}
                alt={t('pwaInstall.qrAlt')}
                width={180}
                height={180}
                className="rounded border border-gray-200"
                data-testid="pwa-install-qr"
              />
            )}
            <div className="break-all font-mono text-xs text-blue-800">{target}</div>
          </div>
          <ol className="list-decimal space-y-1 pl-5">
            <li>{t('pwaInstall.lepes1')}</li>
            <li>{t('pwaInstall.lepes2')}</li>
            <li>
              <strong>{i18n.t('literals.android-chrome')}</strong> {t('pwaInstall.android')}
            </li>
            <li>
              <strong>{i18n.t('literals.iphone-safari')}</strong> {t('pwaInstall.ios')}
            </li>
          </ol>
        </div>
      )}
    </div>
  )
}
