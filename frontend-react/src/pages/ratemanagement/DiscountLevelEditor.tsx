import { useState, useEffect } from 'react'
import { Percent, Plus, Save } from 'lucide-react'

interface Workgroup {
  id: string
  name: string
  code: string
}

interface Discount {
  id?: string
  workgroupId: string
  level: number
  name: string
  buyDiscountPercent: string
  sellDiscountPercent: string
  active: boolean
}

export default function DiscountLevelEditor() {
  const [workgroups, setWorkgroups] = useState<Workgroup[]>([])
  const [selectedWorkgroup, setSelectedWorkgroup] = useState('')
  const [discounts, setDiscounts] = useState<Discount[]>([])
  const [editing, setEditing] = useState<Discount | null>(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    fetchWorkgroups()
  }, [])

  useEffect(() => {
    if (selectedWorkgroup) fetchDiscounts()
  }, [selectedWorkgroup])

  const fetchWorkgroups = async () => {
    try {
      const res = await fetch('/api/v1/rate-management/workgroups')
      if (res.ok) {
        const data = await res.json()
        setWorkgroups(data)
        if (data.length > 0) setSelectedWorkgroup(data[0].id)
      }
    } catch (err) {
      console.error('Lekeres sikertelen:', err)
    }
  }

  const fetchDiscounts = async () => {
    setLoading(true)
    try {
      const res = await fetch(`/api/v1/rate-management/discounts/${selectedWorkgroup}`)
      if (res.ok) setDiscounts(await res.json())
    } catch (err) {
      console.error('Kedvezmeny lekeres sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const saveDiscount = async () => {
    if (!editing) return
    try {
      const method = editing.id ? 'PUT' : 'POST'
      const url = editing.id
        ? `/api/v1/rate-management/discounts/${editing.id}`
        : '/api/v1/rate-management/discounts'
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(editing),
      })
      if (res.ok) {
        setEditing(null)
        fetchDiscounts()
      }
    } catch (err) {
      console.error('Mentes sikertelen:', err)
    }
  }

  const newDiscount = (): Discount => ({
    workgroupId: selectedWorkgroup,
    level: discounts.length + 1,
    name: '',
    buyDiscountPercent: '0',
    sellDiscountPercent: '0',
    active: true,
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Percent className="h-5 w-5" />
        <label className="font-medium text-sm">Munkacsoport:</label>
        <select
          className="border rounded px-3 py-2 text-sm"
          value={selectedWorkgroup}
          onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setSelectedWorkgroup(e.target.value)}
        >
          {workgroups.map((wg) => (
            <option key={wg.id} value={wg.id}>{wg.name} ({wg.code})</option>
          ))}
        </select>
        <button
          className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          onClick={() => setEditing(newDiscount())}
          disabled={discounts.length >= 3}
        >
          <Plus className="h-4 w-4 mr-1" />
          Uj szint
        </button>
      </div>

      {editing && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4">
            <div className="grid grid-cols-4 gap-4">
              <div>
                <label className="text-sm font-medium">Szint</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.level}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, level: parseInt(e.target.value, 10) || 1 })}
                  min={1}
                  max={3}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Nev</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.name}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, name: e.target.value })}
                  placeholder="pl. VIP"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Veteli kedvezmeny (%)</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.buyDiscountPercent}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, buyDiscountPercent: e.target.value })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Eladasi kedvezmeny (%)</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.sellDiscountPercent}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, sellDiscountPercent: e.target.value })}
                />
              </div>
            </div>
            <div className="flex gap-2 mt-4">
              <button
                className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                onClick={saveDiscount}
              >
                <Save className="h-4 w-4 mr-2" />
                Mentes
              </button>
              <button
                className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
                onClick={() => setEditing(null)}
              >
                Megse
              </button>
            </div>
          </div>
        </div>
      )}

      {loading ? (
        <p>Betoltes...</p>
      ) : discounts.length === 0 ? (
        <div className="text-center py-8 text-muted-foreground">Nincs kedvezmeny szint (max 3 szint adhato hozza)</div>
      ) : (
        <div className="space-y-2">
          {discounts.map((d) => (
            <div key={d.id} className="rounded-lg border bg-card shadow-sm">
              <div className="p-3 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium border bg-transparent">Szint {d.level}</span>
                  <span className="font-medium">{d.name}</span>
                  <span className="text-sm text-muted-foreground">
                    Vetel: -{d.buyDiscountPercent}% | Eladas: -{d.sellDiscountPercent}%
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    d.active ? 'bg-primary text-primary-foreground' : 'bg-secondary text-secondary-foreground'
                  }`}>
                    {d.active ? 'Aktiv' : 'Inaktiv'}
                  </span>
                  <button
                    className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                    onClick={() => setEditing(d)}
                  >
                    Szerkesztes
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
