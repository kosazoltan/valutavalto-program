import { Home, ArrowLeftRight, Users, TrendingUp, Wallet, FileText, Settings, Sun, Shield, LayoutDashboard, PlusCircle, Download, Camera } from "lucide-react"
import type { LucideIcon } from "lucide-react"

export const PENZTAR_ROLES = ["penztar"] as const
export const ERTEKTAR_ROLES = ["ertektar"] as const
export const SZERVER_ROLES = ["ugyvezeto", "foertektar", "irodavezeto", "belso_ellenor", "teruleti_vezeto", "biztonsagi_vezeto", "berszamfejto", "penzugyi_vezeto", "irodai_dolgozo", "csoportvezeto", "arfolyam_nezo"] as const

export type AppMode = "full" | "penztar" | "ertektar"

export interface MenuItem {
  path: string
  label: string
  icon: LucideIcon
  modes?: readonly AppMode[]
  canonicalRoles?: readonly string[]
  minRole?: string
}

export interface MenuGroup {
  label: string
  items: MenuItem[]
  modes?: readonly AppMode[]
  canonicalRoles?: readonly string[]
}

export const menuGroups: MenuGroup[] = [
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
      { path: "/daybook", label: "Naplókönyv", icon: FileText },
      { path: "/evening-closing", label: "Napi zárás", icon: FileText },
      { path: "/closing/monthly", label: "Havi zárás", icon: FileText },
      { path: "/customers", label: "Ügyfelek", icon: Users },
      { path: "/rates", label: "Árfolyamok (nézet)", icon: TrendingUp },
    ],
  },
  {
    label: "Árfolyamok",
    canonicalRoles: ["foertektar", "arfolyam_nezo", "ugyvezeto"],
    modes: ["full"],
    items: [
      { path: "/rate-management", label: "Árfolyam dashboard", icon: LayoutDashboard },
      { path: "/rates/creation", label: "Árfolyam készítés", icon: PlusCircle, canonicalRoles: ["foertektar", "ugyvezeto"] },
      { path: "/rates", label: "Árfolyamok", icon: TrendingUp },
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
      { path: "/daily-turnover", label: "Napi forgalom", icon: TrendingUp },
      { path: "/profit", label: "Nyereség (haszon)", icon: TrendingUp },
      { path: "/stock-snapshots", label: "Készlet pillanatképek", icon: FileText },
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
      { path: "/seal-tracking", label: "Plomba nyilvántartás", icon: Shield },
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
      { path: "/licenses", label: "Engedélyek", icon: Shield },
      { path: "/settings", label: "Rendszerbeállítások", icon: Settings, canonicalRoles: ["ugyvezeto"] },
      { path: "/scheduler", label: "Ütemező", icon: FileText, canonicalRoles: ["ugyvezeto", "irodavezeto"] },
      { path: "/email-settings", label: "E-mail beállítások", icon: Settings, canonicalRoles: ["ugyvezeto", "irodavezeto"] },
    ],
  },
  {
    label: "HR / Bérszámfejtés",
    canonicalRoles: ["berszamfejto", "ugyvezeto"],
    modes: ["full"],
    items: [
      { path: "/hrk", label: "HRK", icon: Users },
      { path: "/employees", label: "Munkavállalók", icon: Users },
    ],
  },
  {
    label: "Kamera",
    canonicalRoles: ["biztonsagi_vezeto", "ugyvezeto", "foertektar"],
    modes: ["full"],
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
  const active = activeRole ?? ""
  const all = new Set([active, ...(roles ?? [])].filter(Boolean))
  if (all.has("penztar")) return "/cashier"
  // ertekszallito role: az atadas-atveteli bizonylat alairasanak UI-ja
  if (all.has("ertekszallito")) return "/transfers"
  if (all.has("ertektar")) return "/treasury"
  return "/dashboard"
}
