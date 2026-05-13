import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowRight,
  CheckCircle2,
  ClipboardList,
  Clock3,
  CircleDot,
  Search,
  Server,
  ShieldCheck,
} from 'lucide-react'

type SprintState = 'done' | 'active' | 'queued' | 'server'

interface SprintItem {
  area: string
  module: string
  legacy: string
  route: string
  state: SprintState
  priority: 'P0' | 'P1' | 'P2'
  outcome: string
}

const SPRINT_ITEMS: SprintItem[] = [
  {
    area: 'Központi munkaállomás',
    module: 'Központi irányítóközpont',
    legacy: 'szerver.exe menülogika, szétszedett DLL/EXE modulok',
    route: '/central-workstation',
    state: 'done',
    priority: 'P0',
    outcome: 'Electron központi program külön belépési ponttal, központi szerepkörökre szűrt menüvel.',
  },
  {
    area: 'Központi munkaállomás',
    module: 'Központi sprint',
    legacy: 'server legacy module inventory, repo memória',
    route: '/central/sprint',
    state: 'done',
    priority: 'P0',
    outcome: 'A feltárt központi funkciók egy sprintnézetben, fejlesztési sorrenddel és célképpel.',
  },
  {
    area: 'Belépés és jogosultság',
    module: 'Google OAuth auto-detection',
    legacy: 'userin.dll jelszavas vezetői belépés kiváltása',
    route: '/login',
    state: 'done',
    priority: 'P0',
    outcome: 'Vezetők email alapján azonosítva, pénztárosoknál marad a felhasználónév-jelszó modell.',
  },
  {
    area: 'Belépés és jogosultság',
    module: 'Jogosultság mátrix',
    legacy: 'userin.dll, szerepkör alapú lokális funkcióválasztás',
    route: '/settings/permission-matrix',
    state: 'done',
    priority: 'P1',
    outcome: 'A központi Electronban szerepkör szerint látszanak a főértéktári, belső ellenőri és ügyvezetői funkciók.',
  },
  {
    area: 'Árfolyam és főértéktár',
    module: 'Árfolyamkészítő',
    legacy: 'ARFOLYAM.exe, arfdata.dat, old_arfdata.dat',
    route: '/rates/creation',
    state: 'done',
    priority: 'P0',
    outcome: 'A főértéktáros helyi alkalmazásból készít árfolyamot, nem nyitva tartott szerveren.',
  },
  {
    area: 'Árfolyam és főértéktár',
    module: 'Árfolyam publikálás',
    legacy: 'arftmk.dll, RM*.ARF kiküldési minta',
    route: '/rate-management/workflow',
    state: 'done',
    priority: 'P0',
    outcome: 'Szerveren át terített, auditált árfolyamcsomag a pénztárak automatikus beolvasásához.',
  },
  {
    area: 'Árfolyam és főértéktár',
    module: 'Országos készlet',
    legacy: 'keszdisp.dll, makeszlt',
    route: '/cashier-stocks',
    state: 'done',
    priority: 'P1',
    outcome: 'Központi készletnézet pénztáranként, értéktáranként és valutánként.',
  },
  {
    area: 'Árfolyam és főértéktár',
    module: 'Értéktári leltár',
    legacy: 'értéktár, készlet ellenőrzés',
    route: '/vault-stocktake',
    state: 'done',
    priority: 'P1',
    outcome: 'Főértéktári leltárfolyamat külön ellenőrzési pontokkal.',
  },
  {
    area: 'Zárás és beérkezés',
    module: 'Zárás beérkezés',
    legacy: 'zarasctrl.dll, beerk.dll, missctrl.dll, daybook.fdb',
    route: '/central/closing-control',
    state: 'done',
    priority: 'P0',
    outcome: 'Minden aktív iroda látszik, a hiányzó zárás szintetikus sorral és riasztással jelenik meg.',
  },
  {
    area: 'Zárás és beérkezés',
    module: 'Beérkezett adatok',
    legacy: 'beerk.dll, datadisp.dll, getdisp.dll',
    route: '/central/received-data',
    state: 'done',
    priority: 'P0',
    outcome: 'Napi adatcsomag és daybook állapot országos áttekintése központi dátumszűrővel.',
  },
  {
    area: 'Zárás és beérkezés',
    module: 'Napi ellenőrző lista',
    legacy: 'missctrl.dll, daybook.fdb kontrollpontok',
    route: '/daily-checklist',
    state: 'done',
    priority: 'P1',
    outcome: 'A pénztári napi ellenőrzési pontok központi, hiánylistás felügyelete.',
  },
  {
    area: 'Zárás és beérkezés',
    module: 'Napi forgalom',
    legacy: 'forgdisp.dll, datadisp.dll',
    route: '/daily-turnover',
    state: 'done',
    priority: 'P1',
    outcome: 'Napi forgalmi riport központi és pénzügyi vezetői nézethez.',
  },
  {
    area: 'MNB, bank és export',
    module: 'MNB jelentések',
    legacy: 'gyujto.dll, mnbhibak.dll',
    route: '/reports/mnb',
    state: 'done',
    priority: 'P1',
    outcome: 'MNB riport útvonal központi programból, hibalisták ellenőrzési céljával.',
  },
  {
    area: 'MNB, bank és export',
    module: 'Banki rendelések',
    legacy: 'import.dll, banki import file',
    route: '/bank-orders',
    state: 'done',
    priority: 'P1',
    outcome: 'Banki rendelés/import folyamat a főértéktári napi munkába illesztve.',
  },
  {
    area: 'MNB, bank és export',
    module: 'Banki tranzakció riport',
    legacy: 'bankdisp.dll, westforg.dll',
    route: '/reports/bank-transactions',
    state: 'done',
    priority: 'P1',
    outcome: 'Banki tranzakciók központi riportja pénzügyi és főértéktári szerepköröknek.',
  },
  {
    area: 'MNB, bank és export',
    module: 'Könyvelés export',
    legacy: 'Raiffeisen, Darius, NAV export toolok',
    route: '/booking-export',
    state: 'done',
    priority: 'P2',
    outcome: 'Könyvelési exportok egységesítése ellenőrizhető, verziózott kimenetekkel.',
  },
  {
    area: 'Audit, AML és compliance',
    module: 'Compliance dashboard',
    legacy: 'belső ellenőri összesítő',
    route: '/compliance',
    state: 'done',
    priority: 'P1',
    outcome: 'Belső ellenőri központi dashboard a kockázati és működési állapotokhoz.',
  },
  {
    area: 'Audit, AML és compliance',
    module: 'Szankciós lista',
    legacy: 'terrlist.dll, AML kontroll',
    route: '/sanction',
    state: 'done',
    priority: 'P1',
    outcome: 'AML/szankciós ellenőrzési útvonal központi munkaállomásból.',
  },
  {
    area: 'Audit, AML és compliance',
    module: 'TRB és stornó audit',
    legacy: 'trbdisp.dll, stornodisp.dll',
    route: '/transactions',
    state: 'done',
    priority: 'P1',
    outcome: 'Belső ellenőri tranzakció- és stornóvizsgálat központi kereséssel.',
  },
  {
    area: 'Audit, AML és compliance',
    module: 'WU és ÁFA ellenőrzés',
    legacy: 'wudisp.dll, sumwuafa.dll, wuwadvet.dll',
    route: '/western-union',
    state: 'done',
    priority: 'P2',
    outcome: 'Western Union és ÁFA jellegű ellenőrzések elkülönített központi munkafolyamatba rendezve.',
  },
  {
    area: 'Törzsadat és dolgozói admin',
    module: 'Dolgozói nyilvántartás',
    legacy: 'dolgozok.dll',
    route: '/workers',
    state: 'done',
    priority: 'P1',
    outcome: 'Dolgozói törzsadat, email-alapú azonosítás és aktív szerepkörök központi karbantartása.',
  },
  {
    area: 'Törzsadat és dolgozói admin',
    module: 'Jutalék beállítás',
    legacy: 'dolgjutalek.dll, jutszaz.dll',
    route: '/commission-rates',
    state: 'done',
    priority: 'P2',
    outcome: 'Dolgozói és fiókszintű jutalékszabályok központi adminisztrációja.',
  },
  {
    area: 'Törzsadat és dolgozói admin',
    module: 'Irodák és körzetek',
    legacy: 'irtmk.dll, getegyseg.dll',
    route: '/branch-groups',
    state: 'done',
    priority: 'P2',
    outcome: 'Fiók, körzet és területi vezetői kapcsolatok egységes szerkesztése.',
  },
  {
    area: 'Ügyfél, okmány és kommunikáció',
    module: 'Ügyfél-ellenőrzés',
    legacy: 'ugyfctrl.exe, jogiszem.exe',
    route: '/customers',
    state: 'done',
    priority: 'P1',
    outcome: 'Ügyfél és jogi személy ellenőrzési felület központi szerepköröknek.',
  },
  {
    area: 'Ügyfél, okmány és kommunikáció',
    module: 'Dokumentumtár',
    legacy: 'okmctrl.exe, hiányzó okmányok',
    route: '/documents',
    state: 'done',
    priority: 'P2',
    outcome: 'Hiányzó okmányok és ügyféldokumentumok központi nyomon követése.',
  },
  {
    area: 'Ügyfél, okmány és kommunikáció',
    module: 'Rendőrségi megkeresések',
    legacy: 'police tool család',
    route: '/police-requests',
    state: 'done',
    priority: 'P1',
    outcome: 'Rendőrségi megkeresések kezelése auditálható központi felületen.',
  },
  {
    area: 'Ügyfél, okmány és kommunikáció',
    module: 'Körlevél',
    legacy: 'korlevel.exe',
    route: '/circulars',
    state: 'done',
    priority: 'P2',
    outcome: 'Központi körlevelek és irodai kommunikáció jogosultságkezelt kezelése.',
  },
  {
    area: 'Szerver-szinkron és release',
    module: 'Telepítő és verziófegyelem',
    legacy: 'külön EXE-k helyett verziózott Electron telepítő',
    route: '/central-workstation',
    state: 'server',
    priority: 'P0',
    outcome: 'Minden új telepítő magasabb verzióval készül és a Letöltések mappába kerül.',
  },
]

const stateLabel: Record<SprintState, string> = {
  done: 'kész',
  active: 'sprintben',
  queued: 'következő',
  server: 'release',
}

const stateIcon = {
  done: CheckCircle2,
  active: CircleDot,
  queued: Clock3,
  server: Server,
} satisfies Record<SprintState, typeof CheckCircle2>

const stateClass: Record<SprintState, string> = {
  done: 'border-emerald-200 bg-emerald-50 text-emerald-700',
  active: 'border-blue-200 bg-blue-50 text-blue-700',
  queued: 'border-amber-200 bg-amber-50 text-amber-700',
  server: 'border-slate-200 bg-slate-50 text-slate-700',
}

const filterOptions: Array<{ state: SprintState | 'all'; label: string }> = [
  { state: 'all', label: 'mind' },
  { state: 'done', label: 'kész' },
  { state: 'active', label: 'sprintben' },
  { state: 'queued', label: 'következő' },
  { state: 'server', label: 'release' },
]

export default function CentralSprintPage() {
  const navigate = useNavigate()
  const [activeState, setActiveState] = useState<SprintState | 'all'>('all')
  const [query, setQuery] = useState('')

  const filteredItems = useMemo(() => {
    const normalizedQuery = query.trim().toLocaleLowerCase('hu-HU')
    return SPRINT_ITEMS.filter((item) => {
      const matchesState = activeState === 'all' || item.state === activeState
      const searchText = `${item.area} ${item.module} ${item.legacy} ${item.outcome} ${item.route}`.toLocaleLowerCase('hu-HU')
      return matchesState && (!normalizedQuery || searchText.includes(normalizedQuery))
    })
  }, [activeState, query])

  const counts = useMemo(() => {
    return SPRINT_ITEMS.reduce<Record<SprintState, number>>(
      (acc, item) => {
        acc[item.state] += 1
        return acc
      },
      { done: 0, active: 0, queued: 0, server: 0 },
    )
  }, [])

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <ClipboardList className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">Központi sprint</h1>
              <div className="text-xs text-slate-500">Legacy szerverfunkciók beépítése a helyi irányítóközpontba</div>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2 text-xs">
            <span className="rounded border border-slate-200 bg-slate-50 px-2 py-1 text-slate-700">{SPRINT_ITEMS.length} tétel</span>
            <span className="rounded border border-emerald-200 bg-emerald-50 px-2 py-1 text-emerald-700">{counts.done} kész</span>
            <span className="rounded border border-blue-200 bg-blue-50 px-2 py-1 text-blue-700">{counts.active} sprintben</span>
            <span className="rounded border border-amber-200 bg-amber-50 px-2 py-1 text-amber-700">{counts.queued} következő</span>
          </div>
        </div>
      </div>

      <div className="space-y-4 p-4">
        <section className="grid grid-cols-1 gap-3 lg:grid-cols-[minmax(0,1fr)_340px]">
          <div className="rounded-md border border-slate-200 bg-white p-3 shadow-sm">
            <div className="flex flex-wrap items-center gap-2">
              {filterOptions.map((option) => (
                <button
                  key={option.state}
                  type="button"
                  onClick={() => setActiveState(option.state)}
                  className={`rounded border px-3 py-1.5 text-xs font-semibold transition ${
                    activeState === option.state
                      ? 'border-slate-900 bg-slate-900 text-white'
                      : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>
            <label className="mt-3 flex items-center gap-2 rounded border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600">
              <Search size={16} />
              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                className="min-w-0 flex-1 bg-transparent text-sm text-slate-900 outline-none placeholder:text-slate-400"
                placeholder="Modul, legacy fájl vagy útvonal keresése"
              />
            </label>
          </div>

          <div className="grid grid-cols-2 gap-2">
            {(['done', 'active', 'queued', 'server'] as SprintState[]).map((state) => {
              const Icon = stateIcon[state]
              return (
                <div key={state} className={`rounded-md border p-3 ${stateClass[state]}`}>
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-xs font-semibold">{stateLabel[state]}</span>
                    <Icon size={16} />
                  </div>
                  <div className="mt-2 text-2xl font-semibold">{counts[state]}</div>
                </div>
              )
            })}
          </div>
        </section>

        <section className="overflow-x-auto rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="min-w-[1120px]">
            <div className="grid grid-cols-[72px_minmax(180px,1.2fr)_minmax(180px,1fr)_110px_minmax(260px,1.5fr)_116px] border-b border-slate-200 bg-slate-50 px-3 py-2 text-[11px] font-semibold uppercase text-slate-500">
              <div>Prior</div>
              <div>Modul</div>
              <div>Legacy alap</div>
              <div>Státusz</div>
              <div>Kimenet</div>
              <div>Megnyitás</div>
            </div>
            <div className="divide-y divide-slate-100">
              {filteredItems.map((item) => {
                const Icon = stateIcon[item.state]
                return (
                  <div
                    key={`${item.area}-${item.module}`}
                    className="grid grid-cols-[72px_minmax(180px,1.2fr)_minmax(180px,1fr)_110px_minmax(260px,1.5fr)_116px] items-center gap-3 px-3 py-3 text-sm"
                  >
                    <div>
                      <span className="rounded border border-slate-200 bg-slate-50 px-2 py-1 text-xs font-semibold text-slate-700">{item.priority}</span>
                    </div>
                    <div>
                      <div className="font-semibold text-slate-900">{item.module}</div>
                      <div className="mt-0.5 text-xs text-slate-500">{item.area}</div>
                    </div>
                    <div className="text-xs leading-5 text-slate-600">{item.legacy}</div>
                    <div>
                      <span className={`inline-flex items-center gap-1 rounded border px-2 py-1 text-xs font-semibold ${stateClass[item.state]}`}>
                        <Icon size={13} />
                        {stateLabel[item.state]}
                      </span>
                    </div>
                    <div className="text-xs leading-5 text-slate-600">{item.outcome}</div>
                    <div>
                      <button
                        type="button"
                        onClick={() => navigate(item.route)}
                        className="inline-flex w-full items-center justify-center gap-1 rounded border border-slate-200 bg-white px-2 py-1.5 text-xs font-semibold text-slate-700 transition hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        <ArrowRight size={14} />
                        Nyitás
                      </button>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        </section>

        <section className="rounded-md border border-slate-200 bg-white p-3 shadow-sm">
          <div className="flex items-start gap-2">
            <ShieldCheck className="mt-0.5 h-4 w-4 text-slate-600" />
            <div>
              <h2 className="text-sm font-semibold text-slate-900">Sprint definíció</h2>
              <div className="mt-1 text-xs leading-5 text-slate-600">
                Helyi Electron futtatás, Google OAuth vezetői belépés, szerveren át történő szinkronizáció, pénztári automatikus beolvasás és minden release-nél növekvő telepítőverzió.
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  )
}
