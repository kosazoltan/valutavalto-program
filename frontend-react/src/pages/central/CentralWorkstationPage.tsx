import { useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  AlertTriangle,
  BadgeCheck,
  Banknote,
  BookOpenCheck,
  Building2,
  ClipboardCheck,
  FileArchive,
  FileSpreadsheet,
  FileText,
  Landmark,
  LayoutDashboard,
  Megaphone,
  MonitorCheck,
  PackageCheck,
  Scale,
  Search,
  Shield,
  Users,
  Wallet,
} from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import i18n from '../../i18n'

type ModuleStatus = 'ready' | 'partial' | 'server'

interface CentralModule {
  id: string
  title: string
  description: string
  route: string
  status: ModuleStatus
  icon: LucideIcon
  roles: string[]
}

interface CentralModuleGroup {
  title: string
  modules: CentralModule[]
}

const CENTRAL_MODULE_GROUPS: CentralModuleGroup[] = [
  {
    title: 'Főértéktári felügyelet',
    modules: [
      {
        id: 'national-stock',
        title: 'Országos készlet',
        description: 'Pénztári készletek áttekintése irodánként',
        route: '/cashier-stocks',
        status: 'ready',
        icon: Wallet,
        roles: ['foertektar', 'ugyvezeto'],
      },
      {
        id: 'vault-stocktake',
        title: 'Értéktári leltár',
        description: 'Címletenkénti országos értéktár ellenőrzés',
        route: '/vault-stocktake',
        status: 'ready',
        icon: PackageCheck,
        roles: ['foertektar', 'ugyvezeto'],
      },
    ],
  },
  {
    title: 'Zárás és beérkezés felügyelet',
    modules: [
      {
        id: 'closing-control',
        title: 'Zárás beérkezés',
        description: 'Napi zárások beérkezésének valós idejű állapota',
        route: '/central/closing-control',
        status: 'ready',
        icon: MonitorCheck,
        roles: ['foertektar', 'ugyvezeto', 'belso_ellenor', 'teruleti_vezeto'],
      },
      {
        id: 'daily-checklist',
        title: 'Napi ellenőrző lista',
        // FK-086 FR-2: jóváhagyott leírás (szándékosan literál, nem i18n kulcs — NFR-2).
        description:
          'Valutánkénti napi mérleg — nyitó- és zárókészlet, forgalom, bank- és pénztármozgások',
        // FK-086 FR-1: a valódi riport útvonala a /daily-check (DailyCheckPage).
        route: '/daily-check',
        status: 'ready',
        icon: ClipboardCheck,
        // FK-086 FR-3: a fallback roles-ból kiesik a teruleti_vezeto (a szerver-oldali
        // manifest az elsődleges kapu — ld. CentralModuleManifest, FK-086 FR-4).
        roles: ['foertektar', 'ugyvezeto', 'belso_ellenor'],
      },
      {
        id: 'received-data',
        title: 'Beérkezett adatok',
        description: 'Pénztárak közötti pénzmozgások egyeztetése',
        route: '/central/received-data',
        status: 'ready',
        icon: FileText,
        // FK-003 §6: az egyeztetési modul KIZÁRÓLAG a főértéktári szerepkörnek érhető el.
        roles: ['foertektar'],
      },
      {
        id: 'daily-turnover',
        title: 'Napi forgalom',
        description: 'Összesítő napi forgalmi riport',
        route: '/daily-turnover',
        status: 'ready',
        icon: FileSpreadsheet,
        roles: ['foertektar', 'ugyvezeto', 'belso_ellenor', 'penzugyi_vezeto'],
      },
    ],
  },
  {
    title: 'MNB, bank és export',
    modules: [
      {
        id: 'mnb-reports',
        title: 'MNB jelentések',
        description: 'Havi MNB jelentés generálása és beküldése',
        route: '/reports/mnb',
        status: 'ready',
        icon: Landmark,
        roles: ['foertektar', 'ugyvezeto', 'belso_ellenor', 'penzugyi_vezeto'],
      },
      {
        id: 'bank-orders',
        title: 'Banki rendelések',
        description: 'Banki utánrendelés-kezelés',
        route: '/bank-orders',
        status: 'ready',
        icon: Banknote,
        roles: ['foertektar', 'ugyvezeto', 'penzugyi_vezeto'],
      },
      {
        id: 'bank-transactions',
        title: 'Banki tranzakció riport',
        description: 'Banki tranzakciók összesítője',
        route: '/reports/bank-transactions',
        status: 'ready',
        icon: FileSpreadsheet,
        roles: ['foertektar', 'ugyvezeto', 'penzugyi_vezeto'],
      },
      {
        id: 'booking-export',
        title: 'Könyvelés export',
        description: 'Raiffeisen, Darius, NAV export',
        route: '/booking-export',
        status: 'ready',
        icon: FileArchive,
        roles: ['ugyvezeto', 'penzugyi_vezeto', 'foertektar'],
      },
    ],
  },
  {
    title: 'Audit, AML és compliance',
    modules: [
      {
        id: 'compliance-dashboard',
        title: 'Compliance dashboard',
        description: 'Belső ellenőri összesítő',
        route: '/compliance',
        status: 'ready',
        icon: BadgeCheck,
        roles: ['belso_ellenor', 'biztonsagi_vezeto', 'ugyvezeto'],
      },
      {
        id: 'sanction-list',
        title: 'Szankciós lista',
        description: 'AML kontroll, szankciós lista karbantartása',
        route: '/sanction',
        status: 'ready',
        icon: Shield,
        roles: ['belso_ellenor', 'biztonsagi_vezeto', 'ugyvezeto'],
      },
      {
        id: 'transaction-audit',
        title: 'Tranzakció és sztornó audit',
        description: 'Tranzakciók és sztornók ellenőrzése',
        route: '/transactions',
        status: 'ready',
        icon: AlertTriangle,
        roles: ['belso_ellenor', 'biztonsagi_vezeto', 'ugyvezeto', 'foertektar'],
      },
      {
        id: 'wu-vat-control',
        title: 'WU és ÁFA ellenőrzés',
        description: 'Western Union és ÁFA elszámolás',
        route: '/western-union',
        status: 'ready',
        icon: BookOpenCheck,
        roles: ['belso_ellenor', 'biztonsagi_vezeto', 'ugyvezeto', 'foertektar'],
      },
    ],
  },
  {
    title: 'Törzsadat és dolgozói admin',
    modules: [
      {
        id: 'worker-registry',
        title: 'Dolgozói nyilvántartás',
        description: 'Munkavállalók adatainak kezelése',
        route: '/workers',
        status: 'ready',
        icon: Users,
        roles: ['ugyvezeto', 'irodavezeto', 'irodai_dolgozo'],
      },
      {
        id: 'commission-rates',
        title: 'Jutalék beállítás',
        description: 'Dolgozói jutalékok és százalékok',
        route: '/commission-rates',
        status: 'ready',
        icon: FileSpreadsheet,
        roles: ['ugyvezeto', 'berszamfejto', 'foertektar'],
      },
      {
        id: 'branch-groups',
        title: 'Irodák és körzetek',
        description: 'Irodák és területi körzetek karbantartása',
        route: '/branch-groups',
        status: 'ready',
        icon: Building2,
        roles: ['ugyvezeto', 'irodavezeto', 'foertektar'],
      },
      {
        id: 'permission-matrix',
        title: 'Jogosultság mátrix',
        description: 'Szerepkörök és jogosultságok beállítása',
        route: '/settings/permission-matrix',
        status: 'ready',
        icon: Shield,
        roles: ['ugyvezeto'],
      },
    ],
  },
  {
    title: 'Ügyfél, okmány és központi kommunikáció',
    modules: [
      {
        id: 'customer-control',
        title: 'Ügyfél-ellenőrzés',
        description: 'Ügyfelek és jogi szervezetek nyilvántartása',
        route: '/customers',
        status: 'ready',
        icon: Search,
        roles: ['belso_ellenor', 'ugyvezeto', 'irodavezeto', 'foertektar'],
      },
      {
        id: 'document-vault',
        title: 'Dokumentumtár',
        description: 'Okmányok és hiányzó dokumentumok',
        route: '/documents',
        status: 'ready',
        icon: FileText,
        roles: ['belso_ellenor', 'biztonsagi_vezeto', 'ugyvezeto', 'foertektar'],
      },
      {
        id: 'police-requests',
        title: 'Rendőrségi megkeresések',
        description: 'Hatósági megkeresések kezelése',
        route: '/police-requests',
        status: 'ready',
        icon: Shield,
        roles: ['belso_ellenor', 'biztonsagi_vezeto', 'ugyvezeto'],
      },
      {
        id: 'circulars',
        title: 'Körlevél',
        description: 'Belső körlevelek és értesítések',
        route: '/circulars',
        status: 'ready',
        icon: Megaphone,
        roles: ['ugyvezeto', 'irodavezeto', 'irodai_dolgozo'],
      },
    ],
  },
  {
    title: 'Eredmény és területi haszon',
    modules: [
      {
        id: 'territory-reconciliation',
        title: 'Területi reconciliation',
        description:
          'Értéktári átértékelés lecsorgatása a pénztárakra; terület = Σ pénztári haszon',
        route: '/reports/territory-reconciliation',
        status: 'ready',
        icon: Scale,
        roles: ['foertektar', 'ugyvezeto', 'belso_ellenor', 'teruleti_vezeto'],
      },
    ],
  },
]

const statusLabel: Record<ModuleStatus, string> = {
  ready: 'üzemkész',
  partial: 'bekötött',
  server: 'szerverfeladat',
}

const statusClass: Record<ModuleStatus, string> = {
  ready: 'border-emerald-200 bg-emerald-50 text-emerald-700',
  partial: 'border-amber-200 bg-amber-50 text-amber-700',
  server: 'border-slate-200 bg-slate-50 text-slate-600',
}

function canSeeModule(
  module: CentralModule,
  centralModules: string[] | null,
  hasCanonicalRole: (role: string | string[]) => boolean,
  hasRole: (role: string) => boolean,
): boolean {
  if (centralModules) {
    return centralModules.includes(module.id)
  }
  return hasRole('ADMIN') || module.roles.some((role) => hasCanonicalRole(role))
}

export default function CentralWorkstationPage() {
  const navigate = useNavigate()
  const centralModules = useAuthStore((state) => state.centralModules)
  const hasCanonicalRole = useAuthStore((state) => state.hasCanonicalRole)
  const hasRole = useAuthStore((state) => state.hasRole)

  const visibleGroups = useMemo(
    () =>
      CENTRAL_MODULE_GROUPS.map((group) => ({
        ...group,
        modules: group.modules.filter((module) =>
          canSeeModule(module, centralModules, hasCanonicalRole, hasRole),
        ),
      })).filter((group) => group.modules.length > 0),
    [centralModules, hasCanonicalRole, hasRole],
  )

  const moduleCount = visibleGroups.reduce((sum, group) => sum + group.modules.length, 0)
  const readyCount = visibleGroups.reduce(
    (sum, group) => sum + group.modules.filter((module) => module.status === 'ready').length,
    0,
  )

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <LayoutDashboard className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">
                {i18n.t('literals.kozponti-iranyitokozpont')}
              </h1>
              <div className="text-xs text-slate-500">
                {i18n.t('literals.felugyelet-riportok-es-torzsadat-kezeles')}
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2 text-xs">
            <span className="rounded border border-slate-200 bg-slate-50 px-2 py-1 text-slate-700">
              {moduleCount}
              {i18n.t('literals.modul')}
            </span>
            <span className="rounded border border-emerald-200 bg-emerald-50 px-2 py-1 text-emerald-700">
              {readyCount}
              {i18n.t('literals.uzemkesz')}
            </span>
          </div>
        </div>
      </div>

      <div className="space-y-4 p-4">
        {visibleGroups.map((group) => (
          <section key={group.title} className="space-y-2">
            <h2 className="text-xs font-semibold uppercase text-slate-500">{group.title}</h2>
            <div className="grid grid-cols-1 gap-2 md:grid-cols-2 xl:grid-cols-4">
              {group.modules.map((module) => (
                <button
                  key={module.id}
                  type="button"
                  onClick={() => navigate(module.route)}
                  className="min-h-[100px] rounded-md border border-slate-200 bg-white p-3 text-left shadow-sm transition hover:border-slate-300 hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <span className="flex h-8 w-8 items-center justify-center rounded border border-slate-200 bg-slate-50 text-slate-700">
                        <module.icon size={17} />
                      </span>
                      <span className="text-sm font-semibold text-slate-900">{module.title}</span>
                    </div>
                    <span
                      className={`rounded border px-1.5 py-0.5 text-[10px] font-semibold ${statusClass[module.status]}`}
                    >
                      {statusLabel[module.status]}
                    </span>
                  </div>
                  <div className="mt-2 text-[11px] leading-4 text-slate-500">
                    {module.description}
                  </div>
                </button>
              ))}
            </div>
          </section>
        ))}
      </div>
    </div>
  )
}
