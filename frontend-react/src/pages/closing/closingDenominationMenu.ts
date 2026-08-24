/**
 * EXCMD b5 FR-KC-05: „Címletezés – zárások" választó-menü adatai. Az aktív pontok a
 * zárás-varázslóra visznek (az esti zárás ÉS a kezelési díj címletezése a ClosingWizardPage
 * lépései); a forrás-képernyőn szürkített pontok inaktívak — kattintásra NEM indulhatnak el
 * (FR-KC-05 kényszer), ezért route-juk sincs.
 *
 * FR-KC-06 (Prio C, háttér-menü) SZÁNDÉKOSAN nincs implementálva. A forrás-kép
 * (Cimletezés menü.jpeg, újraolvasva 2026-06-10) tisztázta: a csonkítás NEM OCR-hiba —
 * a Címletezés-dialógus FIZIKAILAG takarja a háttér-menüt a képen, így a „KÜLÖNFÉLE CÍ…"
 * és „CÍMLETEK KIN…" teljes szövege a forrásból megismerhetetlen. A kivehető pontok:
 * „A MAI NAPI ZÁRÁS […]", „A HAVI ZÁRÁS VÉ[GRE]HAJTÁSA", „MÉGSEM" — mind meglévő
 * funkcióra mutat (/closing/wizard, /closing/monthly, vissza). Kitalált felirat nem
 * kerülhet a UI-ba; a funkciók ezen a választó-menün + a főmenün elérhetők. Ugyanez a
 * kép vizuálisan megerősítette az FR-KC-05 implementációt (VISSZA/KILÉPÉS,
 * „CIMLETEZÉS – ZÁRÁSOK" cím).
 *
 * FK-078 FR-1: az „Esti zárás" és a „Kezelési díj" pont már NEM a zárás-varázslóra visz,
 * hanem a közös, kategória-tudatos becímletező oldalra (/closing/denomination-entry/:category).
 * A tényleges zárást onnan kizárólag a „Napi zárás végrehajtása" gomb indítja (FR-5).
 * FK-078 FR-6: az „Elektromos kereskedés" csempe eltávolítva (5 pont a korábbi 6 helyett) —
 * a mögötte lévő e-kereskedelem backend-vertikum (DenominationCategory.ECOMMERCE, a varázsló
 * saját lépése, a riportok) SZÁNDÉKOSAN érintetlen (Scope OUT).
 * FK-078 FR-8: a WU / ÁFA / Foglaló pontok változatlanul, inaktívan maradnak.
 */

export interface ClosingDenominationMenuItem {
  id: string
  label: string
  /** Csak aktív pontnak van route-ja; inaktívnak nincs (nem indítható). */
  route?: string
  disabled: boolean
  description: string
}

/** Pénztári alapértelmezett kilépés (változatlan). */
export const CLOSING_DENOMINATION_EXIT_ROUTE = '/cashier'

/** Értéktári fallback, ha nincs érvényes returnTo (FKH-039 FR-4). */
export const CLOSING_DENOMINATION_VAULT_EXIT_ROUTE = '/evening-closing'

/**
 * FKH-039 FR-4: kontextusfüggő exit-fallback — vault → Napi zárás, pénztár → /cashier.
 * Explicit named feltétel, közös fájlban (nem külön komponens).
 */
export function resolveClosingDenominationExitRoute(isVaultContext: boolean): string {
  return isVaultContext
    ? CLOSING_DENOMINATION_VAULT_EXIT_ROUTE
    : CLOSING_DENOMINATION_EXIT_ROUTE
}

export const CLOSING_DENOMINATION_MENU: ClosingDenominationMenuItem[] = [
  {
    id: 'evening-closing',
    label: 'ESTI ZÁRÁS CÍMLETEZÉSE',
    route: '/closing/denomination-entry/EVENING',
    disabled: false,
    description: 'Napközbeni becímletezés önellenőrzéssel (EVENING kategória)',
  },
  {
    id: 'handling-fee',
    label: 'KEZELÉSI DÍJ CÍMLETEZÉSE',
    route: '/closing/denomination-entry/HANDLING_FEE',
    disabled: false,
    description: 'A kezelési díj becímletezése (HANDLING_FEE kategória)',
  },
  {
    id: 'western-union',
    label: 'WESTERN UNION CÍMLETEZÉSE',
    disabled: true,
    description: 'A forrás-képernyőn inaktív (szürkített) menüpont',
  },
  {
    id: 'afa-penztar',
    label: 'ÁFA ÁTADÁS-ÁTVÉTEL CÍMLETEZÉSE',
    route: '/closing/denomination-entry/VAT',
    disabled: false,
    description: 'ÁFA-célú HUF-ellátmány címletezése (VAT kategória)',
  },
  {
    id: 'foglalo-keszlet',
    label: 'FOGLALÓ KÉSZLET CÍMLETEZÉSE',
    disabled: true,
    description: 'A forrás-képernyőn inaktív (szürkített) menüpont',
  },
]
