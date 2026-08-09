import {
  Home,
  ArrowLeftRight,
  Users,
  TrendingUp,
  Wallet,
  FileText,
  Settings,
  Sun,
  Shield,
  ShieldAlert,
  LayoutDashboard,
  Download,
  Camera,
  Package,
  ClipboardCheck,
  Building2,
  Banknote,
  MonitorCheck,
  Smartphone,
} from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import { canonicalizeRoleForAppMode } from '../utils/appModeRoles'
import type { AppMode } from '../types/appMode'

export const PENZTAR_ROLES = ['penztar'] as const
export const ERTEKTAR_ROLES = ['ertektar'] as const
// SZERVER_ROLES = a központi (full) felület ÁLTALÁNOS irodai/felügyeleti szerepkörei. Ez vezérli a
// „Központ"/„Főoldal" menücsoportok láthatóságát ÉS a lokál-módú oversight bypass-t (hasSupervisoryAccess).
// FK-041/II: az `arfolyam_nezo` (Árfolyam néző) SZÁNDÉKOSAN NINCS itt — ő NEM általános irodai/felügyeleti
// user, csak a saját szűk „Versenytárs-árfolyam" beíró szkópját látja (lentebb, explicit canonicalRoles).
// A full-módú belépési érvényesség külön listából jön (appModeRoles.ts SERVER_ALLOWED_CANONICAL_ROLES),
// így a néző belépése full módban érintetlen. Ha ide visszakerülne, a néző menüjébe beszivárogna a Központ
// (Irányítóközpont/Mobil felügyelet/Zárás beérkezés/Beérkezett adatok) és tévesen felügyeletinek minősülne.
export const SZERVER_ROLES = [
  'ugyvezeto',
  'foertektar',
  'irodavezeto',
  'belso_ellenor',
  'teruleti_vezeto',
  'biztonsagi_vezeto',
  'berszamfejto',
  'penzugyi_vezeto',
  'irodai_dolgozo',
  'csoportvezeto',
] as const

export interface MenuItem {
  path: string
  label: string
  icon: LucideIcon
  modes?: readonly AppMode[]
  canonicalRoles?: readonly string[]
  minRole?: string
  /**
   * FKH-026 v3: a bejegyzés a standard (szerepkör-alapú) menüből rejtett; a
   * felügyeleti (SZERVER_ROLES) lokál-módú oversight-bypass szándékosan
   * TOVÁBBRA IS látja (isMenuItemVisible, a bypass utáni ág). A bejegyzés
   * megtartása (törlés helyett) őrzi a MenuRoleGate szerepkör-unióját
   * (effectiveCanonicalRolesForPath) — a route-hozzáférés nem változik.
   */
  hidden?: boolean
}

export type FeatureFlagKey = 'camera' | 'yearOpeningScheduler' | 'navIntegration'

export interface MenuGroup {
  label: string
  items: MenuItem[]
  modes?: readonly AppMode[]
  canonicalRoles?: readonly string[]
  /**
   * Sourcery PR #146 P2 fix: feature flag key (stabil id) cimke helyett.
   * Lokalizacio es rename biztonsagos.
   */
  featureFlagKey?: FeatureFlagKey
}

export const menuGroups: MenuGroup[] = [
  {
    label: 'Központ',
    canonicalRoles: SZERVER_ROLES,
    modes: ['full'],
    items: [
      { path: '/central-workstation', label: 'Irányítóközpont', icon: MonitorCheck },
      { path: '/mobile', label: 'Mobil felügyelet', icon: Smartphone },
      { path: '/central/closing-control', label: 'Zárás beérkezés', icon: ClipboardCheck },
      { path: '/central/received-data', label: 'Beérkezett adatok', icon: FileText },
    ],
  },
  {
    label: 'Főértéktár',
    canonicalRoles: ['foertektar', 'ugyvezeto'],
    modes: ['full'],
    items: [
      { path: '/foertektar', label: 'Országos dashboard', icon: LayoutDashboard },
      { path: '/mnb/reports', label: 'MNB jelentések', icon: FileText },
      { path: '/statistics/cashier-kpi', label: 'Pénztáros KPI', icon: Users },
      { path: '/cashier-stocks', label: 'Országos készlet', icon: Wallet },
      { path: '/stock-snapshot', label: 'Készlet-snapshot', icon: FileText },
      { path: '/vault-stocktake', label: 'Értéktár leltár', icon: Package },
      {
        path: '/mnb-settlement-rates',
        label: 'MNB árfolyamok rögzítése',
        icon: TrendingUp,
        canonicalRoles: ['foertektar', 'belso_ellenor', 'ugyvezeto'],
      },
      { path: '/bank-orders', label: 'Banki rendelések', icon: Building2 },
      // Bali Henriett 2. pont (2026-05-27, Copilot #891): a főértéktárosnak is
      // elérhetőnek kell lennie (endpoint engedi FOERTEKTAR + UGYVEZETO + ADMIN-t).
      { path: '/branches/new-cashier', label: 'Új pénztár felrögzítése', icon: Building2 },
    ],
  },
  {
    label: 'Pénztár (Valutaváltó)',
    canonicalRoles: PENZTAR_ROLES,
    modes: ['penztar'],
    items: [
      { path: '/cashier', label: 'Pénztáros főmenü', icon: LayoutDashboard },
      { path: '/cashdesk/day-open', label: 'Napnyitás', icon: Sun },
      { path: '/transactions/cashier', label: 'Valuta vétel / eladás', icon: ArrowLeftRight },
      { path: '/transactions/conversion', label: 'Konverzió', icon: ArrowLeftRight },
      { path: '/trades', label: 'Irodaközi trade', icon: ArrowLeftRight },
      { path: '/cashdesk', label: 'Kassza / készlet', icon: Wallet },
      // FK-078 FR-7: a régi, önálló „Címletezés" oldal megszűnt — a becímletezés a
      // „Címletezés – zárások" menüponton át, kategóriánként érhető el.
      // EXCMD b5 FR-KC-05: zárási címletezések választó-menüje.
      { path: '/closing/denominations-menu', label: 'Címletezés – zárások', icon: FileText },
      // FS-9 S3: aktív címletképek read-only nézegetője (hamis bankjegy ellenőrzés).
      { path: '/denomination-images', label: 'Címletképek (valuta)', icon: Banknote },
      { path: '/customers', label: 'Ügyfelek', icon: Users },
      // FKH-026 v3 FR-3: a pénztáros elől rejtve; a felügyeleti bypass (foertektar/
      // helyettes) továbbra is látja — a badge-láthatóság is ehhez kötött (MainLayout).
      {
        path: '/transit',
        label: 'Úton lévő csomagok',
        icon: ArrowLeftRight,
        canonicalRoles: ['penztar'],
        hidden: true,
      },
      // 2026-07-14 (transfers-relabel-split): a régi egybemosott "Átadás-átvétel aláírás"
      // bejegyzés kettébontva — a címke pontosan azt ígéri, amit a felület csinál.
      // 2026-07-14 user-döntés: az ertekszallito (futár) tiszta dokumentáció — kikerült a menü-RBAC-ból.
      {
        path: '/transfers',
        label: 'Átadás-átvétel visszaigazolás (aláírás)',
        icon: ClipboardCheck,
        canonicalRoles: ['penztar'],
      },
      // FKH-026 v3 FR-6: önálló menüpont helyett a /transfers fejléc-gombja
      // ("+ Új átadás") a belépési pont; a felügyeleti bypass továbbra is látja.
      {
        path: '/transfers/new',
        label: 'Új átadás-átvétel rögzítése',
        icon: ArrowLeftRight,
        canonicalRoles: ['penztar'],
        hidden: true,
      },
      { path: '/closing/wizard', label: 'Napzárás', icon: FileText },
      { path: '/rates', label: 'Árfolyamok (nézet)', icon: TrendingUp },
      { path: '/transactions', label: 'Tranzakciólista', icon: FileText },
      // EXCMD b6b FR-EFM-01: konszolidált „Egyéb feladatok" menü (NAV/POS variáns a konfiguráció szerint).
      { path: '/other-tasks', label: 'Egyéb feladatok', icon: Settings },
      // Batch2-B (Fabulya-teszt 2026-06-12): a kezelési díj konfiguráció a pénztár-kliensben
      // is elérhető legyen. Pénztárosnak READ-ONLY nézet (a PUT szerver-oldalon továbbra is
      // vezetői jog — a HandlingFeeConfigPage a szerepkör szerint tiltja a szerkesztést).
      // Explicit canonicalRoles: a route-gate (effectiveCanonicalRolesForPath UNIÓ) így a
      // pénztárost ÉS az oversight-bypass-szal belépő vezetőket is átengedi.
      {
        path: '/handling-fee-config',
        label: 'Kezelési költség beállítások',
        icon: Wallet,
        canonicalRoles: ['penztar', 'foertektar', 'ugyvezeto', 'irodavezeto', 'belso_ellenor'],
      },
    ],
  },
  {
    label: 'Értéktár (lokál)',
    canonicalRoles: ERTEKTAR_ROLES,
    modes: ['ertektar'],
    items: [
      { path: '/treasury', label: 'Értéktári dashboard', icon: LayoutDashboard },
      // FK-013 (Bali Henriett / Kasza Helga 2026-05-28): a két régi menüpont
      // (`Átadás-átvétel (pénztáraknak)` + `Átadás bank / másik értéktár`) egybevonva
      // EGY egységes menüpontba. A "Cél iroda" dropdown 3 csoportos (saját terület
      // pénztárai + társ értéktárak + 10 fix banki/speciális partner).
      { path: '/shipments', label: 'Átadás-átvétel', icon: ArrowLeftRight },
      // FKH-026 v3 FR-1: az értéktáros elől rejtve — a Pénztár-módú bejegyzés (fent)
      // VÁLTOZATLAN; a felügyeleti bypass (foertektar/helyettes) itt is látja.
      { path: '/trades', label: 'Irodaközi trade', icon: ArrowLeftRight, hidden: true },
      {
        path: '/transfers',
        label: 'Átadás-átvétel visszaigazolás (aláírás)',
        icon: ClipboardCheck,
        canonicalRoles: ['ertektar'],
      },
      // FKH-026 v3 FR-6: önálló menüpont helyett a /transfers fejléc-gombja
      // ("+ Új átadás") a belépési pont; a felügyeleti bypass továbbra is látja.
      {
        path: '/transfers/new',
        label: 'Új átadás-átvétel rögzítése',
        icon: ArrowLeftRight,
        canonicalRoles: ['ertektar'],
        hidden: true,
      },
      // FKH-026 v3 FR-5: az értéktáros elől rejtve (felügyeleti bypass látja).
      {
        path: '/transfer-documents',
        label: 'Szállítólevelek',
        icon: FileText,
        canonicalRoles: ['ertektar'],
        hidden: true,
      },
      // FKH-026 v3 FR-3: az értéktáros elől rejtve; a badge-láthatóság is ehhez kötött.
      {
        path: '/transit',
        label: 'Úton lévő csomagok',
        icon: ArrowLeftRight,
        canonicalRoles: ['ertektar'],
        hidden: true,
      },
      { path: '/inventory', label: 'Értéktári készlet', icon: Wallet },
      { path: '/cashier-stocks', label: 'Pénztári készletek', icon: Wallet },
      // Bali Henriett 2. pont (2026-05-27): manuális pénztár-felrögzítés értéktáros által.
      { path: '/branches/new-cashier', label: 'Új pénztár felrögzítése', icon: Building2 },
      // FK-ÉRTÉKTÁR (V285): új személyes értéktári munkatárs felvétele (név + jelszó).
      { path: '/vault-workers/new', label: 'Új munkatárs felvétele', icon: Users },
      { path: '/daybook', label: 'Naplókönyv', icon: FileText },
      // FKH-030 FR-1: Pénzforgalom riport — Bank/Terület/Pénztár mozgások tetszőleges
      // dátumtartományra. A Naplókönyv mellé kerül: ugyanaz az adatkör (Transfer+Shipment),
      // de tartományra és a teljes körzetre, nem egy napra és egy fiókra.
      { path: '/reports/cash-flow', label: 'Pénzforgalom riport', icon: FileText },
      { path: '/evening-closing', label: 'Napi zárás', icon: FileText },
      // FK-061 FR-1: a zárási varázsló ("Napzárás") értéktári módban is elérhető a menüből.
      // A /closing/wizard route gate nélkül, mindkét módban kiszolgál (App.tsx változatlan).
      { path: '/closing/wizard', label: 'Napzárás', icon: FileText },
      { path: '/closing/monthly', label: 'Havi zárás', icon: FileText },
      { path: '/customers', label: 'Ügyfelek', icon: Users },
      { path: '/rates', label: 'Árfolyamok (nézet)', icon: TrendingUp },
    ],
  },
  {
    // FK-041/II: az `arfolyam_nezo` (Árfolyam néző) NEM látja a belső területi árfolyamokat — neki
    // dedikált, szűk szkópja van (lentebb: „Versenytárs-árfolyam"). A nézetet a főértéktár/ügyvezető látja.
    label: 'Árfolyamok (nézet)',
    canonicalRoles: ['foertektar', 'ugyvezeto'],
    modes: ['full'],
    items: [
      { path: '/rates', label: 'Aktuális árfolyamok', icon: TrendingUp },
      { path: '/rates/history', label: 'Árfolyam történet', icon: FileText },
      {
        path: '/rates/categories',
        label: 'Árfolyam kategóriák',
        icon: FileText,
        canonicalRoles: ['foertektar', 'ugyvezeto'],
      },
    ],
  },
  {
    // FK-041/II: az árfolyam néző dedikált (mobil/PWA-barát) versenytárs-árfolyam beíró szkópja — csak a
    // saját területe (régió) versenyhelyeihez. A bevitt adat a főértéktár konkurencia-adatlapján jelenik meg.
    label: 'Versenytárs-árfolyam',
    canonicalRoles: ['arfolyam_nezo', 'foertektar', 'ugyvezeto'],
    modes: ['full'],
    items: [{ path: '/competitor-rates', label: 'Versenytárs-árfolyam bevitel', icon: Building2 }],
  },
  {
    // #ERR-RATE-INTEG-01: a rate-maker (Árfolyamkészítő) módnak eddig NEM volt menücsoportja,
    // ezért a sidebar üresen jelent meg. A főlap (/rates/main) saját navigációval működik, de
    // az üres sidebar UX-hiba volt — ez a csoport adja a dedikált sidebar-navigációt rate-maker módban.
    label: 'Árfolyamkészítés',
    canonicalRoles: ['foertektar', 'ugyvezeto'],
    modes: ['rate-maker'],
    items: [
      { path: '/rates/main', label: 'Főlap (0-s elszámoló)', icon: TrendingUp },
      { path: '/rates/creation', label: 'Csoport árfolyamlapok', icon: FileText },
      { path: '/rates/history', label: 'Árfolyam történet', icon: FileText },
    ],
  },
  {
    label: 'Riportok',
    canonicalRoles: [
      'foertektar',
      'ugyvezeto',
      'irodavezeto',
      'belso_ellenor',
      'teruleti_vezeto',
      'penzugyi_vezeto',
    ],
    modes: ['full'],
    items: [
      { path: '/reports', label: 'Riportok', icon: FileText },
      { path: '/reports/extended', label: 'Kiterjesztett riportok', icon: FileText },
      { path: '/reports/mnb', label: 'MNB riportok', icon: FileText },
      { path: '/reports/handling-fee-decade', label: 'Kezelési díj — készpénz', icon: FileText },
      { path: '/reports/pos-handling-fee', label: 'Kezelési díj — POS', icon: FileText },
      { path: '/reports/bank-transactions', label: 'Banki tranzakciók', icon: FileText },
      { path: '/reports/cashier-turnover', label: 'Pénztáros forgalom', icon: FileText },
      { path: '/reports/recurring-customers', label: 'Visszatérő ügyfél (AML)', icon: FileText },
      {
        path: '/reports/average-rate',
        label: 'Átlag árfolyam',
        icon: TrendingUp,
        canonicalRoles: ['foertektar', 'ugyvezeto', 'belso_ellenor'],
      },
      { path: '/reports/daily-journal', label: 'Napkönyv (PDF)', icon: FileText },
      { path: '/reports/central', label: 'Központi riportok (CSV)', icon: Building2 },
      { path: '/reports/nav', label: 'NAV adatszolgáltatás', icon: ShieldAlert },
      { path: '/daily-turnover', label: 'Napi forgalom', icon: TrendingUp },
      {
        path: '/daily-check',
        label: 'Napi ellenőrző lista',
        icon: ClipboardCheck,
        canonicalRoles: ['foertektar', 'ugyvezeto', 'belso_ellenor'],
      },
      { path: '/profit', label: 'Nyereség (haszon)', icon: TrendingUp },
      { path: '/stock-snapshot', label: 'Készlet pillanatképek', icon: FileText },
      { path: '/booking-export', label: 'Könyvelés export', icon: Download },
    ],
  },
  {
    label: 'AML / Compliance',
    // FS11-MENU-ROLE: szinkronban a backend compliance hasAnyRole-halmazával (ld. menuVisibility.test.ts pin)
    canonicalRoles: ['belso_ellenor', 'biztonsagi_vezeto', 'ugyvezeto'],
    modes: ['full'],
    items: [
      { path: '/police-requests', label: 'Rendőrségi megkeresések', icon: Shield },
      { path: '/audit-log', label: 'Audit napló', icon: Shield },
      {
        path: '/admin/error-monitor',
        label: 'Hiba-monitor',
        icon: ShieldAlert,
        canonicalRoles: ['ugyvezeto', 'belso_ellenor', 'biztonsagi_vezeto'],
      },
      {
        path: '/admin/audit-diagnostics',
        label: 'Audit-diagnosztika (V234)',
        icon: ShieldAlert,
        canonicalRoles: ['ugyvezeto', 'belso_ellenor', 'biztonsagi_vezeto'],
      },
      { path: '/sanction', label: 'Szankciós lista (AML)', icon: ShieldAlert },
      { path: '/seal-tracking', label: 'Plomba nyilvántartás', icon: Shield },
      { path: '/compliance', label: 'Compliance Dashboard', icon: ClipboardCheck },
      { path: '/compliance/questions', label: 'Compliance kérdések', icon: ClipboardCheck },
      { path: '/compliance/transactions', label: 'Compliance tranzakciók', icon: ArrowLeftRight },
    ],
  },
  {
    label: 'Ügyfelek',
    canonicalRoles: [
      'ugyvezeto',
      'foertektar',
      'irodavezeto',
      'belso_ellenor',
      'teruleti_vezeto',
      'biztonsagi_vezeto',
      'berszamfejto',
      'penzugyi_vezeto',
      'irodai_dolgozo',
    ],
    modes: ['full'],
    items: [
      { path: '/customers', label: 'Ügyfélkezelés', icon: Users },
      { path: '/representatives', label: 'Meghatalmazottak', icon: Users },
    ],
  },
  {
    label: 'Adminisztráció',
    canonicalRoles: ['ugyvezeto', 'irodavezeto', 'irodai_dolgozo'],
    modes: ['full'],
    items: [
      // FK-020: Pénztár Törzs Adatbázis lista (olvasás: foertektar/helyettes, belso_ellenor, ugyvezeto).
      {
        path: '/admin/branches',
        label: 'Pénztár Törzs Adatbázis',
        icon: Building2,
        canonicalRoles: ['foertektar', 'belso_ellenor', 'ugyvezeto'],
      },
      // FK-026: Dolgozói Törzs Adatbázis read-only lista (ugyanazon olvasó szerepkörök).
      {
        path: '/admin/workers-database',
        label: 'Dolgozói Törzs Adatbázis',
        icon: Users,
        canonicalRoles: ['foertektar', 'belso_ellenor', 'ugyvezeto'],
      },
      { path: '/workers', label: 'Dolgozók', icon: Users },
      // #954 four-eyes előfeltétel: supervisor sztornó-jóváhagyó lista (backend
      // @PreAuthorize SUPERVISOR/MANAGER/ADMIN a hiteles enforcement).
      {
        path: '/stornos/approvals',
        label: 'Sztornó jóváhagyások',
        icon: ClipboardCheck,
        canonicalRoles: ['ugyvezeto', 'irodavezeto'],
      },
      { path: '/employees', label: 'HR (munkavállalók)', icon: Users },
      { path: '/attendance', label: 'Munkaidő nyilvántartás', icon: Users },
      { path: '/licenses', label: 'Engedélyek', icon: Shield },
      {
        path: '/settings',
        label: 'Rendszerbeállítások',
        icon: Settings,
        canonicalRoles: ['ugyvezeto'],
      },
      {
        path: '/settings/permission-matrix',
        label: 'Jogosultság mátrix',
        icon: Shield,
        canonicalRoles: ['ugyvezeto'],
      },
      {
        path: '/scheduler',
        label: 'Ütemező',
        icon: FileText,
        canonicalRoles: ['ugyvezeto', 'irodavezeto'],
      },
      {
        path: '/email-settings',
        label: 'E-mail beállítások',
        icon: Settings,
        canonicalRoles: ['ugyvezeto', 'irodavezeto'],
      },
      {
        path: '/handling-fee-config',
        label: 'Kezelési költség beállítások',
        icon: Wallet,
        canonicalRoles: ['ugyvezeto', 'irodavezeto', 'belso_ellenor'],
      },
      {
        path: '/packaging',
        label: 'Göngyöleg nyilvántartás',
        icon: Package,
        canonicalRoles: ['ugyvezeto', 'irodavezeto'],
      },
    ],
  },
  {
    label: 'HR / Bérszámfejtés',
    canonicalRoles: ['berszamfejto', 'ugyvezeto'],
    modes: ['full'],
    items: [{ path: '/employees', label: 'Munkavállalók', icon: Users }],
  },
  {
    label: 'Kamera',
    canonicalRoles: ['biztonsagi_vezeto', 'ugyvezeto', 'foertektar'],
    modes: ['full'],
    featureFlagKey: 'camera',
    items: [
      { path: '/camera/live', label: 'Élő kép', icon: Camera },
      { path: '/camera/playback', label: 'Visszajátszás', icon: Camera },
      { path: '/camera/export', label: 'Export & Custody', icon: Download },
      { path: '/camera/status', label: 'Állapot', icon: Camera },
    ],
  },
  {
    label: 'Főoldal',
    // FK-041/II: a Főoldal (Irányítópult /dashboard) az általános központi felület — a szűk szkópú
    // árfolyam néző NEM látja (eddig korlátlan volt → minden full-user, így a néző is látta). A többi
    // (felügyeleti) szerver-user változatlanul látja (mind benne van a SZERVER_ROLES-ban).
    canonicalRoles: SZERVER_ROLES,
    modes: ['full'],
    items: [{ path: '/dashboard', label: 'Irányítópult', icon: Home }],
  },
]

export function getDefaultRouteForRoles(
  roles: readonly string[] | undefined,
  activeRole: string | null | undefined,
): string {
  const all = new Set(
    [activeRole, ...(roles ?? [])].map((role) => canonicalizeRoleForAppMode(role)).filter(Boolean),
  )
  if (all.has('penztar')) return '/cashier'
  // ertekszallito role: az atadas-atveteli bizonylat alairasanak UI-ja
  if (all.has('ertekszallito')) return '/transfers'
  if (all.has('ertektar')) return '/treasury'
  // FK-041/II: az árfolyam néző egyetlen feladata a versenytárs-árfolyam bevitel (mobil/PWA) —
  // belépés után közvetlenül oda landol. (Csak akkor, ha nincs magasabb jogú szerepköre.)
  if (all.has('arfolyam_nezo') && !all.has('foertektar') && !all.has('ugyvezeto')) {
    return '/competitor-rates'
  }
  return '/dashboard'
}
