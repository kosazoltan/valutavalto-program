// FK-014 (2026-06-01) – Banki/speciális partnerek azonosítása és kiszűrése.
//
// A 10 fix "banki és speciális partner" a backendben BRANCH_TYPE = 'VAULT_COUNTERPARTY'
// (V277 seed; BranchService.findByCompanyIdAndBranchTypeCode(companyId, "VAULT_COUNTERPARTY")).
// Ezek NEM a cég valódi irodái (65 pénztár + 8 értéktár), NEM végeznek napi zárást —
// kizárólag átadás-átvételi kapcsolati pontok. Ezért a felügyeleti modulokból
// (Zárás beérkezés, Napi ellenőrzési lista) ki kell szűrni őket; az értéktári
// Átadás-átvétel menüben viszont MARADNAK (ott a /branches/vault-counterparties adja őket).
//
// Két szűrő-mechanizmus, hogy minden adatforrásra működjön:
//   1. strukturális: branchTypeCode === 'VAULT_COUNTERPARTY' (ahol elérhető, pl. /branches);
//   2. kód-alapú fallback: a 10 kanonikus kód (pl. a ClosingControlStatus NEM hordoz
//      branchTypeCode-ot, csak branchCode-ot).

/** A 10 fix banki/speciális partner kódja (VAULT_COUNTERPARTY). FK-014 acceptance forrása. */
export const VAULT_COUNTERPARTY_CODES = [
  'PRB',
  'UPT',
  'TRB',
  'ERB',
  'FRB',
  'RB',
  'JRB',
  'MNB',
  'TH',
  'FOP1',
] as const

const COUNTERPARTY_CODE_SET = new Set<string>(VAULT_COUNTERPARTY_CODES)

const VAULT_COUNTERPARTY_TYPE = 'VAULT_COUNTERPARTY'

/** Bármilyen branch-szerű objektum, amiből kiolvasható a kód és/vagy a típus. */
export interface BranchLike {
  branchCode?: string | null
  code?: string | null
  branchTypeCode?: string | null
}

/**
 * Igaz, ha az adott egység banki/speciális partner (NEM valódi iroda).
 * Strukturális (branchTypeCode) VAGY kód-alapú egyezés.
 */
export function isBankPartner(branch: BranchLike): boolean {
  if ((branch.branchTypeCode ?? '').trim().toUpperCase() === VAULT_COUNTERPARTY_TYPE) {
    return true
  }
  const code = (branch.branchCode ?? branch.code ?? '').trim().toUpperCase()
  return code.length > 0 && COUNTERPARTY_CODE_SET.has(code)
}

/**
 * Banki/speciális partnerek kiszűrése egy listából — csak a valódi irodák
 * (pénztár + értéktár) maradnak. FK-014.
 */
export function excludeBankPartners<T extends BranchLike>(rows: T[]): T[] {
  return rows.filter((row) => !isBankPartner(row))
}
