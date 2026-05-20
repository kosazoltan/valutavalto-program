import type { CreateTransferRequest } from '../../services/api/index'

/**
 * Átadás-átvétel üzleti szabályok (Kósa Zoltán tesztelői kérés, pénztár+értéktár modul).
 *
 * Pure, izoláltan tesztelhető (transferRules.test.ts) — a TransferPage komponens ezeket
 * használja a típus- és valuta-választás szűréséhez.
 */
export type TransferType = CreateTransferRequest['transferType']

export interface TransferTypeOption {
  value: TransferType
  label: string
}

/**
 * (Req #2 + #3) A választható átadás-típusok az irány (átadás/átvétel) és a felhasználó
 * típusa (pénztár vs. értéktár) szerint. Pénztárnál CSAK forint / valuta / kezelési költség —
 * értéktári feltöltés/leszedés NEM. A címke az iránynak megfelelő szót használja.
 */
export function getAvailableTransferTypes(isVaultUser: boolean, direction: 'out' | 'in'): TransferTypeOption[] {
  const word = direction === 'out' ? 'átadás' : 'átvétel'
  const base: TransferTypeOption[] = [
    { value: 'CASH', label: `Forint (HUF) ${word}` },
    { value: 'CURRENCY', label: `Valuta ${word}` },
    { value: 'HANDLING_FEE', label: `Kezelési költség ${word}` },
  ]
  if (isVaultUser) {
    base.push(
      { value: 'VAULT_DEPOSIT', label: 'Értéktár feltöltés' },
      { value: 'VAULT_WITHDRAW', label: 'Értéktár leszedés' },
    )
  }
  return base
}

/**
 * A felhasználó számára engedélyezett típus-értékek (irány-független halmaz) — a
 * `getAvailableTransferTypes` single source of truth-ból származtatva (DRY, nincs drift).
 */
export function getAllowedTransferTypeValues(isVaultUser: boolean): TransferType[] {
  return getAvailableTransferTypes(isVaultUser, 'out').map(o => o.value)
}

/** FT és kezelési költség típus → kizárólag HUF (forint) érintett. */
export function isHufOnlyTransferType(type: TransferType): boolean {
  return type === 'CASH' || type === 'HANDLING_FEE'
}

/** (#6) Egy szerkesztő-sor a több-valutás átadólapon. */
export interface CurrencyLineInput {
  /** Stabil React-kulcs a sorhoz (a buildTransferLines figyelmen kívül hagyja). */
  id?: number
  currencyId: number | null
  amount: string
}

export interface BuiltTransferLines {
  lines: Array<{ currencyId: number; amount: number }>
  error: string | null
}

/**
 * (#6) A több-valutás szerkesztő-sorokból validált `lines` tömb építése:
 *  - üres (currencyId=null) sor kihagyva,
 *  - minden megadott sorhoz pozitív összeg kell,
 *  - egy valuta csak egyszer szerepelhet,
 *  - legalább egy érvényes sor kell.
 */
export function buildTransferLines(rows: CurrencyLineInput[]): BuiltTransferLines {
  const lines: Array<{ currencyId: number; amount: number }> = []
  const seen = new Set<number>()
  for (const r of rows) {
    const amountFilled = String(r.amount).trim() !== ''
    if (r.currencyId == null) {
      // Teljesen üres sor → kihagyjuk; de ha összeg van valuta nélkül → hiba (részben kitöltött, Codex #726).
      if (amountFilled) {
        return { lines: [], error: 'Válasszon valutát minden kitöltött sorhoz (vagy törölje az üres sort)!' }
      }
      continue
    }
    const amt = Number.parseFloat(String(r.amount).replace(/\s/g, '').replace(',', '.'))
    if (!Number.isFinite(amt) || amt <= 0) {
      return { lines: [], error: 'Minden megadott valuta-sorhoz pozitív összeg szükséges!' }
    }
    if (seen.has(r.currencyId)) {
      return { lines: [], error: 'Egy átadólapon egy valuta csak egyszer szerepelhet!' }
    }
    seen.add(r.currencyId)
    lines.push({ currencyId: r.currencyId, amount: amt })
  }
  if (lines.length === 0) {
    return { lines: [], error: 'Legalább egy valuta-sort meg kell adni!' }
  }
  return { lines, error: null }
}

/**
 * (Req #4 + #5) Valuta-szűrés a típus szerint:
 *  - FT / kezelési költség → CSAK HUF,
 *  - valuta → HUF NÉLKÜL (csak deviza),
 *  - egyéb (értéktár) → minden valuta.
 */
export function filterCurrenciesForType<T extends { code: string }>(currencies: T[], type: TransferType): T[] {
  if (type === 'CURRENCY') return currencies.filter(c => c.code !== 'HUF')
  if (isHufOnlyTransferType(type)) return currencies.filter(c => c.code === 'HUF')
  return currencies
}
