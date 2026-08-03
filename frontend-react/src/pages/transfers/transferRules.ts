import type { CreateTransferRequest } from '../../services/api/index'
import { FRACTIONAL_FACE_VALUE_ERROR, isAllowedFaceValue } from '../../utils/denominationRules'

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
export function getAvailableTransferTypes(
  isVaultUser: boolean,
  direction: 'out' | 'in',
): TransferTypeOption[] {
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
      // Technikai gyűjtő kötés-kódok (legacy RB-gyűjtők, b5-penztar-mozgasok.md:51-72,
      // c4 P3#5 — üzleti döntés 2026-06-11). A valuta+irány+vault-only invariánsokat a
      // backend is kikényszeríti (TransferService.create guard: Branch.isVault ellenőrzés,
      // Codex/Copilot P2 #1092) — ez a lista csak a UI-választékot szűri.
      { value: 'ERB', label: 'ERB — Fixing valuta mozgás RB' },
      { value: 'FRB', label: 'FRB — Forint mozgás RB' },
      { value: 'TRB', label: 'TRB — Egyedi kötés RB' },
    )
    if (direction === 'in') {
      // PRB = POS ÁTVÉTEL BANKTÓL → a legacy név szerint kizárólag átvétel irányban.
      base.push({ value: 'PRB', label: 'PRB — POS átvétel banktól' })
    }
  }
  return base
}

/**
 * A felhasználó számára engedélyezett típus-értékek (irány-független halmaz) — a
 * `getAvailableTransferTypes` single source of truth-ból származtatva (DRY, nincs drift).
 * Mindkét irány unióját adja, mert a PRB csak 'in' irányban választható.
 */
export function getAllowedTransferTypeValues(isVaultUser: boolean): TransferType[] {
  const union = [
    ...getAvailableTransferTypes(isVaultUser, 'out').map((o) => o.value),
    ...getAvailableTransferTypes(isVaultUser, 'in').map((o) => o.value),
  ]
  return [...new Set(union)]
}

/** FT / kezelési költség / FRB (forint mozgás RB) / PRB (POS átvétel banktól) → kizárólag HUF. */
export function isHufOnlyTransferType(type: TransferType): boolean {
  return type === 'CASH' || type === 'HANDLING_FEE' || type === 'FRB' || type === 'PRB'
}

/** Kizárólag devizás (HUF nélküli) kötés-típusok: valuta + ERB/TRB technikai RB-kötések. */
export function isCurrencyOnlyTransferType(type: TransferType): boolean {
  return type === 'CURRENCY' || type === 'ERB' || type === 'TRB'
}

/**
 * (#1) Átadás-átvétel cél-fiók szűrés (Kósa Zoltán 2026-05-20): csak
 *  - az adott pénztár TERÜLETÉHEZ tartozó értéktár (isVault + azonos vaultTerritoryId/region),
 *  - TH (Többlet-hiány) pénztár,
 *  - az "1.sz Főpénztár" = a Pécsi Iroda "Egyes számú pénztár" központi készpénzpénztára
 *    (ide mennek a készpénz-átadások/átvételek és a hiány/többlet könyvelés).
 *
 * ÜRES-FALLBACK: ha a szűrő 0 fiókot adna (hibás/hiányos törzsadat), MINDET visszaadjuk —
 * nehogy megismétlődjön a 2026-05-15-i üres-dropdown production hiba.
 */
export interface TransferTargetBranch {
  id: string
  code: string
  name: string
  isVault?: boolean
  branchTypeCode?: string
  region?: string
  vaultTerritoryId?: number | null
}

export function isTHBranch(b: TransferTargetBranch): boolean {
  const code = (b.code ?? '').toUpperCase()
  return (
    b.branchTypeCode === 'TH' ||
    code === 'TH' ||
    /^TH[\d\-_ ]/.test(code) || // kód-prefix: "TH01", "TH-1", "TH_3" ... (Codex P1 #727)
    /\bTH\b/i.test(b.code) ||
    /\bTH\b/i.test(b.name)
  )
}

/**
 * Az "1.sz Főpénztár" = a Pécsi Iroda "Egyes számú pénztár" központi készpénzpénztára.
 * SZŰK minta (Codex P2 #727): a névnek az 1.sz / egyes számú megjelöléssel KELL kezdődnie,
 * hogy ne match-eljen véletlen "főpénztár" előfordulást más fióknévben.
 */
export function isMainCashierBranch(b: TransferTargetBranch): boolean {
  const n = (b.name ?? '').trim().toLowerCase()
  return (
    /^egyes\s+sz[aá]m[uú]\s+(f[őo])?p[eé]nzt[aá]r/.test(n) || // "Egyes számú (fő)pénztár"
    /^1\.?\s*sz[aá]m[uú]\s+(f[őo])?p[eé]nzt[aá]r/.test(n) || // "1. számú (fő)pénztár"
    /^1\.?\s*sz\.?\s*(f[őo])?p[eé]nzt[aá]r/.test(n)
  ) // "1.sz Főpénztár" / "1. sz. pénztár"
}

export function filterTransferTargetBranches<T extends TransferTargetBranch>(
  branches: T[],
  ownBranch?: T | null,
): T[] {
  const filtered = branches.filter((b) => {
    if (isTHBranch(b)) return true
    if (isMainCashierBranch(b)) return true
    if (b.isVault === true && ownBranch) {
      const sameTerritory =
        (ownBranch.vaultTerritoryId != null && b.vaultTerritoryId === ownBranch.vaultTerritoryId) ||
        (!!ownBranch.region && b.region === ownBranch.region)
      if (sameTerritory) return true
    }
    return false
  })
  return filtered.length > 0 ? filtered : branches
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
        return {
          lines: [],
          error: 'Válasszon valutát minden kitöltött sorhoz (vagy törölje az üres sort)!',
        }
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
 *  - FT / kezelési költség / FRB / PRB → CSAK HUF,
 *  - valuta / ERB / TRB → HUF NÉLKÜL (csak deviza),
 *  - egyéb (értéktár) → minden valuta.
 */
export function filterCurrenciesForType<T extends { code: string }>(
  currencies: T[],
  type: TransferType,
): T[] {
  if (isCurrencyOnlyTransferType(type)) return currencies.filter((c) => c.code !== 'HUF')
  if (isHufOnlyTransferType(type)) return currencies.filter((c) => c.code === 'HUF')
  return currencies
}

/**
 * FR-1..3 / NFR-1,2 (átadás-átvétel): szállító + plombaszám kliens-oldali validációja, a backend
 * Bean Validationnel (CreateTransferDto) EGYEZŐEN — egyetlen forrás, hogy a TransferPage és a
 * MovementManager ne csússzon el egymástól (Sourcery). Hibaszöveget ad vissza, vagy null, ha érvényes.
 */
export function validateCarrierSeal(carrierName: string, sealNumber: string): string | null {
  const carrier = carrierName.trim()
  const seal = sealNumber.trim()
  if (!carrier) return 'A szállító nevének megadása kötelező!'
  if (carrier.length > 128) return 'A szállító neve legfeljebb 128 karakter lehet!'
  if (!seal) return 'A plombaszám megadása kötelező!'
  if (seal.length > 64) return 'A plombaszám legfeljebb 64 karakter lehet!'
  if (!/^[A-Za-z0-9\-/]+$/.test(seal))
    return 'A plombaszám csak betűt, számot, kötőjelet és perjelet tartalmazhat!'
  return null
}

/** FR-17/18: egy címletezés-sor nyers (string) bemenete a formból. */
export interface DenominationLineInput {
  quantity: string
  faceValue: string
}

export interface DenominationBuildResult {
  /** A beküldhető címletezés-sorok (üres/kikapcsolt esetben undefined → nem küldjük). */
  denominations?: Array<{ quantity: number; faceValue: number }>
  /** Hibaszöveg, ha a megadott sorok összege nem egyezik az átadás összegével (FR-20b). */
  error?: string
}

/**
 * FR-17..20b (átadás-átvétel): az opcionális címletezés-sorok feldolgozása + összeg-egyezés
 * ellenőrzése. Pure, izoláltan tesztelhető (a TransferPage ezt használja).
 *
 * - Kikapcsolt címletezés (`enabled=false`) VAGY nincs érvényes sor → `{}` (nincs címletezés, FR-19).
 * - Az érvénytelen sorokat (≤0 darab / névleges, NaN) kihagyjuk.
 * - Ha van legalább egy érvényes sor, az összegüknek egyeznie kell az átadás összegével — különben
 *   `error` (a backend is validál: VV-VALID-002). A magyar tizedesvessző és szóköz elfogadott.
 */
export function buildDenominationPayload(
  enabled: boolean,
  lines: ReadonlyArray<DenominationLineInput>,
  totalAmount: number,
): DenominationBuildResult {
  if (!enabled) return {}
  const allParsed = lines.map((l) => ({
    quantity: parseInt(l.quantity, 10),
    faceValue: parseFloat(String(l.faceValue).replace(',', '.').replace(/\s/g, '')),
  }))
  // FK-072 (FR-4): kitöltött sorban az 1 alatti (tört) névleges érték egyértelmű hibát
  // ad — NEM néma kihagyást, mert az érthetetlen összeg-eltérési hibát okozna. Az üres
  // / nem-pozitív sorok kihagyása változatlan (lásd lentebb).
  const hasFractional = allParsed.some(
    (l) =>
      Number.isFinite(l.quantity) &&
      l.quantity > 0 &&
      Number.isFinite(l.faceValue) &&
      l.faceValue > 0 &&
      !isAllowedFaceValue(l.faceValue),
  )
  if (hasFractional) {
    return {
      error: FRACTIONAL_FACE_VALUE_ERROR,
    }
  }
  const parsed = allParsed.filter(
    (l) =>
      Number.isFinite(l.quantity) &&
      l.quantity > 0 &&
      Number.isFinite(l.faceValue) &&
      l.faceValue > 0,
  )
  if (parsed.length === 0) return {}
  const sum = parsed.reduce((s, l) => s + l.quantity * l.faceValue, 0)
  if (Math.abs(sum - totalAmount) > 0.0001) {
    return {
      error: `A címletezés összege (${sum.toLocaleString('hu-HU')}) nem egyezik az átadás összegével (${totalAmount.toLocaleString('hu-HU')})!`,
    }
  }
  return { denominations: parsed }
}
