import { Home, ArrowLeftRight, Users, TrendingUp, Wallet, FileText, Settings, Sun, Shield, ShieldAlert, LayoutDashboard, Download, Camera, Package, ClipboardCheck, Building2, MonitorCheck } from "lucide-react"
import type { LucideIcon } from "lucide-react"
import { canonicalizeRoleForAppMode } from "../utils/appModeRoles"
import type { AppMode } from "../types/appMode"

export const PENZTAR_ROLES = ["penztar"] as const
export const ERTEKTAR_ROLES = ["ertektar"] as const
export const ERTEKSZALLITO_ROLES = ["ertekszallito"] as const
export const SZERVER_ROLES = ["ugyvezeto", "foertektar", "irodavezeto", "belso_ellenor", "teruleti_vezeto", "biztonsagi_vezeto", "berszamfejto", "penzugyi_vezeto", "irodai_dolgozo", "csoportvezeto", "arfolyam_nezo"] as const

export interface MenuItem {
  path: string
  label: string
  icon: LucideIcon
  modes?: readonly AppMode[]
  canonicalRoles?: readonly string[]
  minRole?: string
}

export type FeatureFlagKey = "camera" | "yearOpeningScheduler" | "navIntegration"

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
    label: "Központ",
    canonicalRoles: SZERVER_ROLES,
    modes: ["full"],
    items: [
      { path: "/central-workstation", label: "Irányítóközpont", icon: MonitorCheck },
      { path: "/central/closing-control", label: "Zárás beérkezés", icon: ClipboardCheck },
      { path: "/central/received-data", label: "Beérkezett adatok", icon: FileText },
    ],
  },
  {
    label: "Főértéktár",
    canonicalRoles: ["foertektar", "ugyvezeto"],
    modes: ["full"],
    items: [
      { path: "/foertektar", label: "Országos dashboard", icon: LayoutDashboard },
      { path: "/mnb/reports", label: "MNB jelentések", icon: FileText },
      { path: "/statistics/cashier-kpi", label: "Pénztáros KPI", icon: Users },
      { path: "/cashier-stocks", label: "Országos készlet", icon: Wallet },
      { path: "/stock-snapshot", label: "Készlet-snapshot", icon: FileText },
      { path: "/vault-stocktake", label: "Értéktár leltár", icon: Package },
      { path: "/bank-orders", label: "Banki rendelések", icon: Building2 },
    ],
  },
  {
    label: "Pénztár (Valutaváltó)",
    canonicalRoles: PENZTAR_ROLES,
    modes: ["penztar"],
    items: [
      { path: "/cashier", label: "Pénztáros főmenü", icon: LayoutDashboard },
      { path: "/cashdesk/day-open", label: "Napnyitás", icon: Sun },
      { path: "/transactions/cashier", label: "Valuta vétel / eladás", icon: ArrowLeftRight },
      { path: "/transactions/conversion", label: "Konverzió", icon: ArrowLeftRight },
      { path: "/cashdesk", label: "Kassza / készlet", icon: Wallet },
      { path: "/cashdesk/denominations", label: "Címletezés", icon: FileText },
      { path: "/customers", label: "Ügyfelek", icon: Users },
      { path: "/transit", label: "Úton lévő csomagok", icon: ArrowLeftRight },
      { path: "/closing/wizard", label: "Napzárás", icon: FileText },
      { path: "/rates", label: "Árfolyamok (nézet)", icon: TrendingUp },
      { path: "/transactions", label: "Tranzakciólista", icon: FileText },
    ],
  },
  {
    label: "Értéktár (lokál)",
    canonicalRoles: ERTEKTAR_ROLES,
    modes: ["ertektar"],
    items: [
      { path: "/treasury", label: "Értéktári dashboard", icon: LayoutDashboard },
      { path: "/shipments", label: "Átadás-átvétel (pénztáraknak)", icon: ArrowLeftRight },
      { path: "/transfers", label: "Átadás bank / másik értéktár", icon: ArrowLeftRight },
      { path: "/transfer-documents", label: "Szállítólevelek", icon: FileText },
      { path: "/transit", label: "Úton lévő csomagok", icon: ArrowLeftRight },
      { path: "/inventory", label: "Értéktári készlet", icon: Wallet },
      { path: "/cashier-stocks", label: "Pénztári készletek", icon: Wallet },
      { path: "/daybook", label: "Naplókönyv", icon: FileText },
      { path: "/evening-closing", label: "Napi zárás", icon: FileText },
      { path: "/closing/monthly", label: "Havi zárás", icon: FileText },
      { path: "/customers", label: "Ügyfelek", icon: Users },
      { path: "/rates", label: "Árfolyamok (nézet)", icon: TrendingUp },
    ],
  },
  {
    label: "Értékszállító",
    canonicalRoles: ERTEKSZALLITO_ROLES,
    modes: ["ertekszallito"],
    items: [
      { path: "/transfers", label: "Átadás-átvétel aláírás", icon: ArrowLeftRight },
      { path: "/transfer-documents", label: "Szállítólevelek", icon: FileText },
      { path: "/transit", label: "Úton lévő csomagok", icon: ArrowLeftRight },
    ],
  },
  {
    label: "Árfolyamok (nézet)",
    canonicalRoles: ["foertektar", "arfolyam_nezo", "ugyvezeto"],
    modes: ["full"],
    items: [
      { path: "/rates", label: "Aktuális árfolyamok", icon: TrendingUp },
      { path: "/rates/history", label: "Árfolyam történet", icon: FileText },
      { path: "/rates/categories", label: "Árfolyam kategóriák", icon: FileText, canonicalRoles: ["foertektar", "ugyvezeto"] },
    ],
  },
  {
    label: "Riportok",
    canonicalRoles: ["foertektar", "ugyvezeto", "irodavezeto", "belso_ellenor", "teruleti_vezeto", "penzugyi_vezeto"],
    modes: ["full"],
    items: [
      { path: "/reports", label: "Riportok", icon: FileText },
      { path: "/reports/extended", label: "Kiterjesztett riportok", icon: FileText },
      { path: "/reports/mnb", label: "MNB riportok", icon: FileText },
      { path: "/reports/handling-fee-decade", label: "Kezelési díj — dekád", icon: FileText },
      { path: "/reports/bank-transactions", label: "Banki tranzakciók", icon: FileText },
      { path: "/reports/cashier-turnover", label: "Pénztáros forgalom", icon: FileText },
      { path: "/reports/recurring-customers", label: "Visszatérő ügyfél (AML)", icon: FileText },
      { path: "/reports/average-rate", label: "Átlag árfolyam", icon: TrendingUp },
      { path: "/reports/daily-journal", label: "Napkönyv (PDF)", icon: FileText },
      { path: "/daily-turnover", label: "Napi forgalom", icon: TrendingUp },
      { path: "/profit", label: "Nyereség (haszon)", icon: TrendingUp },
      { path: "/stock-snapshot", label: "Készlet pillanatképek", icon: FileText },
      { path: "/booking-export", label: "Könyvelés export", icon: Download },
    ],
  },
  {
    label: "AML / Compliance",
    canonicalRoles: ["belso_ellenor", "biztonsagi_vezeto", "ugyvezeto"],
    modes: ["full"],
    items: [
      { path: "/police-requests", label: "Rendőrségi megkeresések", icon: Shield },
      { path: "/audit-log", label: "Audit napló", icon: Shield },
      { path: "/admin/error-monitor", label: "Hiba-monitor", icon: ShieldAlert, canonicalRoles: ["ugyvezeto", "belso_ellenor", "biztonsagi_vezeto"] },
      { path: "/admin/audit-diagnostics", label: "Audit-diagnosztika (V234)", icon: ShieldAlert, canonicalRoles: ["ugyvezeto", "belso_ellenor", "biztonsagi_vezeto"] },
      { path: "/sanction", label: "Szankciós lista (AML)", icon: ShieldAlert },
      { path: "/seal-tracking", label: "Plomba nyilvántartás", icon: Shield },
      { path: "/compliance", label: "Compliance Dashboard", icon: ClipboardCheck },
    ],
  },
  {
    label: "Ügyfelek",
    canonicalRoles: ["ugyvezeto", "foertektar", "irodavezeto", "belso_ellenor", "teruleti_vezeto", "biztonsagi_vezeto", "berszamfejto", "penzugyi_vezeto", "irodai_dolgozo"],
    modes: ["full"],
    items: [
      { path: "/customers", label: "Ügyfélkezelés", icon: Users },
    ],
  },
  {
    label: "Adminisztráció",
    canonicalRoles: ["ugyvezeto", "irodavezeto", "irodai_dolgozo"],
    modes: ["full"],
    items: [
      { path: "/workers", label: "Dolgozók", icon: Users },
      { path: "/employees", label: "HR (munkavállalók)", icon: Users },
      { path: "/attendance", label: "Munkaidő nyilvántartás", icon: Users },
      { path: "/licenses", label: "Engedélyek", icon: Shield },
      { path: "/settings", label: "Rendszerbeállítások", icon: Settings, canonicalRoles: ["ugyvezeto"] },
      { path: "/settings/permission-matrix", label: "Jogosultság mátrix", icon: Shield, canonicalRoles: ["ugyvezeto"] },
      { path: "/scheduler", label: "Ütemező", icon: FileText, canonicalRoles: ["ugyvezeto", "irodavezeto"] },
      { path: "/email-settings", label: "E-mail beállítások", icon: Settings, canonicalRoles: ["ugyvezeto", "irodavezeto"] },
      { path: "/handling-fee-config", label: "Kezelési költség beállítás", icon: Wallet, canonicalRoles: ["ugyvezeto", "irodavezeto", "belso_ellenor"] },
    ],
  },
  {
    label: "HR / Bérszámfejtés",
    canonicalRoles: ["berszamfejto", "ugyvezeto"],
    modes: ["full"],
    items: [
      { path: "/employees", label: "Munkavállalók", icon: Users },
    ],
  },
  {
    label: "Kamera",
    canonicalRoles: ["biztonsagi_vezeto", "ugyvezeto", "foertektar"],
    modes: ["full"],
    featureFlagKey: "camera",
    items: [
      { path: "/camera/live", label: "Élő kép", icon: Camera },
      { path: "/camera/playback", label: "Visszajátszás", icon: Camera },
      { path: "/camera/export", label: "Export & Custody", icon: Download },
      { path: "/camera/status", label: "Állapot", icon: Camera },
    ],
  },
  {
    label: "Főoldal",
    modes: ["full"],
    items: [
      { path: "/dashboard", label: "Irányítópult", icon: Home },
    ],
  },
]

export function getDefaultRouteForRoles(roles: readonly string[] | undefined, activeRole: string | null | undefined): string {
  const all = new Set(
    [activeRole, ...(roles ?? [])]
      .map((role) => canonicalizeRoleForAppMode(role))
      .filter(Boolean),
  )
  if (all.has("penztar")) return "/cashier"
  // ertekszallito role: az atadas-atveteli bizonylat alairasanak UI-ja
  if (all.has("ertekszallito")) return "/transfers"
  if (all.has("ertektar")) return "/treasury"
  return "/dashboard"
}
