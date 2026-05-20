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

/** FT és kezelési költség típus → kizárólag HUF (forint) érintett. */
export function isHufOnlyTransferType(type: TransferType): boolean {
  return type === 'CASH' || type === 'HANDLING_FEE'
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
