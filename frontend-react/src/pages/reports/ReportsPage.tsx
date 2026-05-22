import { useNavigate } from 'react-router-dom'
import {
  FileText, Calendar, BarChart3, PieChart, TrendingUp,
  FileSpreadsheet, BookOpen, Sun, Moon, Clock,
} from 'lucide-react'
import { useTranslation } from 'react-i18next'

interface ReportLink {
  id: string
  name: string
  icon: React.ElementType
  description: string
  path: string
}

const reportLinks: ReportLink[] = [
  { id: 'live-cash', name: 'Pillanatnyi pénztárállás', icon: BarChart3, description: 'Valutánkénti nyitó/bevétel/kiadás/záró + kezelési díj', path: '/reports/live-cash-position' },
  { id: 'daily-turnover', name: 'Napi forgalom', icon: Calendar, description: 'Napi tranzakciók és forgalom összesítése', path: '/daily-turnover' },
  { id: 'daybook', name: 'Napló (DayBook)', icon: BookOpen, description: 'Napi bizonylatok kronológikus listája', path: '/daybook' },
  { id: 'decade', name: 'Dekádzárás', icon: Clock, description: 'Dekádos forgalmi összesítő', path: '/decade' },
  { id: 'profit', name: 'Eredmény kimutatás', icon: TrendingUp, description: 'Profit és veszteség számítás', path: '/profit' },
  { id: 'mnb', name: 'MNB jelentés', icon: FileSpreadsheet, description: 'Hatósági (MNB) jelentés generálás', path: '/reports/mnb' },
  { id: 'darius', name: 'Darius riport', icon: BarChart3, description: 'Darius rendszer riportok', path: '/darius' },
  { id: 'evening', name: 'Esti zárás', icon: Moon, description: 'Napi lezárás és zárási bizonylat', path: '/evening-closing' },
  { id: 'monthly', name: 'Havi zárás', icon: PieChart, description: 'Havi forgalmi zárás és összesítés', path: '/closing/monthly' },
  { id: 'extended', name: 'Kibővített riportok', icon: FileText, description: 'Speciális kimutatások és exportok', path: '/reports/extended' },
  { id: 'anonymous', name: 'Névtelen bejelentés', icon: Sun, description: 'AML névtelen bejelentések kezelése', path: '/anonymous-reports' },
  { id: 'suspicious', name: 'Gyanús tranzakciók', icon: FileText, description: 'Gyanús tranzakció jelentések', path: '/suspicious-reports' },
]

export default function ReportsPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          {t('reports.riportok')}
        </h1>
      </div>

      {/* Report cards grid */}
      <div className="grid grid-cols-3 gap-3">
        {reportLinks.map((report) => {
          const Icon = report.icon
          return (
            <button
              key={report.id}
              onClick={() => navigate(report.path)}
              className="form-panel text-left hover:shadow-md transition-shadow cursor-pointer group"
              data-testid={`report-link-${report.id}`}
            >
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-lg bg-blue-50 group-hover:bg-blue-100 transition-colors">
                  <Icon size={20} className="text-blue-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-800 group-hover:text-blue-700 transition-colors">
                    {report.name}
                  </h3>
                  <p className="text-sm text-gray-500 mt-0.5">{report.description}</p>
                </div>
              </div>
            </button>
          )
        })}
      </div>
    </div>
  )
}
