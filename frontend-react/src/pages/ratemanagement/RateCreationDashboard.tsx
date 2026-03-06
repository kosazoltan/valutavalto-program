import { useState } from 'react'
import { BarChart3 } from 'lucide-react'
import RateTemplateEditor from './RateTemplateEditor'
import WorkgroupManager from './WorkgroupManager'
import DiscountLevelEditor from './DiscountLevelEditor'
import RatePublishHistory from './RatePublishHistory'

const tabs = [
  { key: 'templates', label: 'Arfolyam sablonok' },
  { key: 'workgroups', label: 'Munkacsoportok' },
  { key: 'discounts', label: 'Kedvezmenyek' },
  { key: 'history', label: 'Publikalasi naplo' },
] as const

type TabKey = (typeof tabs)[number]['key']

export default function RateCreationDashboard() {
  const [activeTab, setActiveTab] = useState<TabKey>('templates')

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <BarChart3 className="h-6 w-6" />
          Arfolyam kezeles
        </h1>
      </div>

      {/* Tab navigation */}
      <div className="inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            className={`inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 ${
              activeTab === tab.key
                ? 'bg-background text-foreground shadow-sm'
                : 'hover:bg-background/50 hover:text-foreground'
            }`}
            onClick={() => setActiveTab(tab.key)}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab content */}
      <div className="mt-4">
        {activeTab === 'templates' && <RateTemplateEditor />}
        {activeTab === 'workgroups' && <WorkgroupManager />}
        {activeTab === 'discounts' && <DiscountLevelEditor />}
        {activeTab === 'history' && <RatePublishHistory />}
      </div>
    </div>
  )
}
