import type { LucideIcon } from 'lucide-react'
import {
  Settings, Trash2, Upload, Sun, Lock, Cable, LogOut,
  Terminal, CreditCard, FileText, Users,
} from 'lucide-react'

/**
 * EXCMD b6b FR-EFM-01: az „Egyéb feladatok" menü két variánsa, amelyet a pénztár
 * konfigurációja választ ki (NAV pénztárgép integráció aktív vs. OTP POS / adatlapos mód).
 * A konfigurációs flag a szerver-vezérelt `navIntegration` feature-flag (useFeatureFlags).
 * A menüpontok MEGLÉVŐ oldalakra navigálnak (a NAV-parancsok maguk a /nav-integration
 * oldalon élnek) — ez a modul csak a konszolidált választó-menüt adja (EXCMD audit 2026-06-04:
 * „Funkciók szétszórtan; választó-menü hiányzik").
 */

export interface OtherTaskMenuItem {
  id: string
  label: string
  description: string
  icon: LucideIcon
  route: string
}

/** FR-EFM-04: a KILÉPÉS mindkét variánsban a pénztáros főmenübe visz, megerősítés nélkül. */
export const OTHER_TASKS_EXIT_ROUTE = '/cashier'

const EXIT_ITEM: OtherTaskMenuItem = {
  id: 'exit',
  label: 'KILÉPÉS AZ EGYÉB FELADATOKBÓL',
  description: 'Visszatérés a pénztáros főmenübe',
  icon: LogOut,
  route: OTHER_TASKS_EXIT_ROUTE,
}

const SETTINGS_ITEM: OtherTaskMenuItem = {
  id: 'settings',
  label: 'KÜLÖNFÉLE BEÁLLÍTÁSOK',
  description: 'Pénztári beállítások képernyő',
  icon: Settings,
  route: '/settings/penztar',
}

// FR-EFM-02 — Variáns 1 (NAV pénztárgépes konfiguráció). A 2–6. pontok a NAV-integrációs
// oldalra visznek, ahol a COM-port beállítás és a pénztárgép-parancsok élnek.
const NAV_VARIANT_ITEMS: OtherTaskMenuItem[] = [
  SETTINGS_ITEM,
  {
    id: 'nav-clear-currencies',
    label: 'PÉNZTÁRGÉP VALUTÁINAK TÖRLÉSE',
    description: 'A pénztárgép memóriájában tárolt valuták törlése (NAV-integráció)',
    icon: Trash2,
    route: '/nav-integration',
  },
  {
    id: 'nav-load-currencies',
    label: 'VALUTÁK BETÖLTÉSE A PÉNZTÁRGÉPBE',
    description: 'Az aktuális valutalista betöltése a pénztárgépbe (NAV-integráció)',
    icon: Upload,
    route: '/nav-integration',
  },
  {
    id: 'nav-day-open',
    label: 'NAPNYITÁS A PÉNZTÁRGÉPEN',
    description: 'Napi nyitási parancs a NAV pénztárgépnek (NAV-integráció)',
    icon: Sun,
    route: '/nav-integration',
  },
  {
    id: 'nav-day-close',
    label: 'NAPZÁRÁS A PÉNZTÁRGÉPEN',
    description: 'Napi zárási parancs a NAV pénztárgépnek (NAV-integráció)',
    icon: Lock,
    route: '/nav-integration',
  },
  {
    id: 'nav-com-port',
    label: 'A PÉNZTÁRGÉP COM-PORTJÁNAK ÁLLÍTÁSA',
    description: 'Soros port kiválasztása és tesztelése (NAV-integráció)',
    icon: Cable,
    route: '/nav-integration',
  },
  EXIT_ITEM,
]

// FR-EFM-03 — Variáns 2 (OTP POS / adatlapos konfiguráció).
const POS_VARIANT_ITEMS: OtherTaskMenuItem[] = [
  SETTINGS_ITEM,
  {
    id: 'cash-register-commands',
    label: 'PÉNZTÁRGÉP UTASÍTÁSAI',
    description: 'Pénztárgép-specifikus parancsok',
    icon: Terminal,
    route: '/nav-integration',
  },
  {
    id: 'otp-pos',
    label: 'OTP POS TERMINÁL PARANCSOK',
    description: 'Bankkártyás terminál-vezérlő',
    icon: CreditCard,
    route: '/pos-terminal',
  },
  {
    id: 'datasheets',
    label: 'ADATLAPOK KEZELÉSE',
    description: 'Ügyfél-adatlapok és dokumentumok kezelése',
    icon: FileText,
    route: '/documents',
  },
  {
    id: 'customer-maintenance',
    label: 'ÜGYFÉL KARBANTARTÁS',
    description: 'Ügyfél-törzsadatok keresése és szerkesztése',
    icon: Users,
    route: '/customers',
  },
  EXIT_ITEM,
]

/**
 * FR-EFM-01: a pénztár-konfiguráció szerinti menü-variáns. A két variáns soha nem
 * látszik egyszerre.
 */
export function buildOtherTasksMenu(navIntegrationActive: boolean): OtherTaskMenuItem[] {
  return navIntegrationActive ? NAV_VARIANT_ITEMS : POS_VARIANT_ITEMS
}
