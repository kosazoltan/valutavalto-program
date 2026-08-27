import { useEffect, useState } from 'react'
import type { CustomerDisplayPayload } from '../../types/electron'
import i18n from '../../i18n'

/**
 * VFD ügyfélkijelző oldal (P2-1).
 *
 * Ezt az oldalt EGY MÁSIK Electron BrowserWindow tölti be (nem a fő-renderer),
 * jellemzően a második monitoron full-screen módban. NINCS sidebar, NINCS header,
 * NINCS auth — egyszerű "kirakat" kijelző az ügyfél számára.
 *
 * Az oldal IPC eseményeken keresztül kapja a tranzakció részleteit a fő-renderer-től
 * (a pénztáros oldalakról: Buy/Sell/Conversion).
 *
 * Hivatkozás: D:\valutavalto-vault\references\p2-features-design-2026-05-06.md
 */

const TRANSACTION_TYPE_LABEL: Record<
  NonNullable<CustomerDisplayPayload['transactionType']>,
  string
> = {
  BUY: 'VÉTEL',
  SELL: 'ELADÁS',
  CONVERSION: 'KONVERZIÓ',
  STORNO: 'SZTORNÓ',
}

function formatNumber(value: number | undefined, fractionDigits = 0): string {
  if (value == null || Number.isNaN(value)) return '—'
  return new Intl.NumberFormat('hu-HU', {
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  }).format(value)
}

export default function CustomerDisplayPage() {
  const [payload, setPayload] = useState<CustomerDisplayPayload | null>(null)

  useEffect(() => {
    // IPC listener regisztrálása a customer-display:update eseményre.
    // A `onUpdate` egy unsubscribe függvénnyel tér vissza, amit cleanup-ban hívunk.
    const cd = window.electronAPI?.customerDisplay
    if (!cd?.onUpdate) {
      // Web módban (NEM Electron) nincs IPC — a komponens demo/idle nézetet mutat.
      return
    }
    const unsubscribe = cd.onUpdate((p: CustomerDisplayPayload) => {
      setPayload(p ?? null)
    })
    return () => {
      unsubscribe()
    }
  }, [])

  // Idle (üdvözlő) képernyő — ha nincs aktív tranzakció
  const isIdle = !payload || (!payload.transactionType && !payload.amount && !payload.totalHuf)

  if (isIdle) {
    return (
      <div className="flex h-screen w-screen flex-col items-center justify-center bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 text-white">
        <h1 className="mb-8 text-7xl font-bold tracking-tight">
          {payload?.message ?? 'Üdvözöljük az Exclusive Best Change-nél!'}
        </h1>
        <p className="text-3xl text-slate-300">{i18n.t('literals.kerjuk-lepjen-a-penztarhoz')}</p>
      </div>
    )
  }

  return (
    <div className="flex h-screen w-screen flex-col items-stretch justify-between bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 px-16 py-12 text-white">
      {/* Fejléc — tranzakció típusa */}
      <header className="text-center">
        <p className="text-2xl uppercase tracking-widest text-slate-400">
          {i18n.t('literals.tranzakcio')}
        </p>
        <h1 className="mt-2 text-7xl font-bold tracking-tight text-amber-300">
          {payload.transactionType ? TRANSACTION_TYPE_LABEL[payload.transactionType] : '—'}
        </h1>
      </header>

      {/* Fő részletek — összeg + valuta + árfolyam */}
      <main className="flex flex-col items-center gap-6">
        {payload.currencyCode && payload.amount != null && (
          <div className="text-center">
            <p className="text-2xl uppercase tracking-widest text-slate-400">
              {i18n.t('literals.osszeg')}
            </p>
            <p className="mt-2 text-8xl font-bold">
              {formatNumber(payload.amount, 2)}{' '}
              <span className="text-amber-300">{payload.currencyCode}</span>
            </p>
          </div>
        )}

        {payload.rate != null && (
          <div className="text-center">
            <p className="text-xl uppercase tracking-widest text-slate-400">
              {i18n.t('literals.arfolyam')}
            </p>
            <p className="mt-1 text-5xl font-semibold text-slate-200">
              {formatNumber(payload.rate, 4)}
              {i18n.t('literals.huf-2')}
            </p>
          </div>
        )}

        {payload.handlingFee != null && payload.handlingFee > 0 && (
          <div className="text-center">
            <p className="text-xl uppercase tracking-widest text-slate-400">
              {i18n.t('literals.kezelesi-koltseg')}
            </p>
            <p className="mt-1 text-4xl font-semibold text-slate-200">
              {formatNumber(payload.handlingFee, 0)}
              {i18n.t('literals.huf-2')}
            </p>
          </div>
        )}
      </main>

      {/* Lábléc — végösszeg HUF-ban */}
      <footer className="text-center">
        {payload.totalHuf != null ? (
          <>
            <p className="text-2xl uppercase tracking-widest text-slate-400">
              {i18n.t('literals.fizetendo')}
            </p>
            <p className="mt-2 text-8xl font-bold text-emerald-300">
              {formatNumber(payload.totalHuf, 0)}{' '}
              <span className="text-emerald-200">{i18n.t('literals.huf')}</span>
            </p>
          </>
        ) : payload.hufAmount != null ? (
          <>
            <p className="text-2xl uppercase tracking-widest text-slate-400">
              {i18n.t('literals.huf-ertek')}
            </p>
            <p className="mt-2 text-7xl font-bold text-emerald-300">
              {formatNumber(payload.hufAmount, 0)}
              {i18n.t('literals.huf-2')}
            </p>
          </>
        ) : null}
        {payload.message && <p className="mt-6 text-3xl text-slate-300">{payload.message}</p>}
      </footer>
    </div>
  )
}
