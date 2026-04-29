import { useState, useEffect, useCallback } from 'react'
import { Settings, Building, Users, Printer, Database, Bell, Shield, Palette, Sliders, Loader2 } from 'lucide-react'
import SystemParameterPage from './SystemParameterPage'
import PermissionPage from './PermissionPage'
import RolePage from './RolePage'
import UserPage from './UserPage'
import { ownCompanyApi, type OwnCompany } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'

/**
 * v2.3.36 (Sourcery #299 P3): Type-safe field whitelist a SettingsPage company
 * tab szerkesztheto mezoinek. A `keyof OwnCompany` magaba foglalna az `id`,
 * `isActive`, `companyId` mezoket is, amelyek NEM szerkeszthetoek a UI-bol.
 * Ez a union biztositja, hogy a compiler csak az engedelyezett string-mezokre
 * engedjen `handleCompanyChange` hivasokat.
 */
type EditableOwnCompanyKeys =
  | 'name'
  | 'taxNumber'
  | 'registrationNumber'
  | 'licenseNumber'
  | 'address'
  | 'phone'
  | 'email'
  | 'bankAccountNumber'
  | 'iban'
  | 'swift'

/**
 * v2.3.34 (B11): Cégadatok tab most az aktív OwnCompany rekordbol toltodik
 * (NEM hardkodolt "Pénzváltó Kft." placeholder-ek). Ha az own_company tabla
 * ures, akkor a v2.3.34 V172 Flyway migration az EBC Zrt. seed-et szurja be
 * (Exclusive Best Change Zrt. — kosa.zoltan.ebc@gmail.com beruhazo cege).
 */
export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState('company')
  const [companyData, setCompanyData] = useState<OwnCompany | null>(null)
  const [companyLoading, setCompanyLoading] = useState(false)
  const [companySaving, setCompanySaving] = useState(false)

  const loadCompany = useCallback(async () => {
    setCompanyLoading(true)
    try {
      const list = await ownCompanyApi.getActive()
      setCompanyData(list[0] ?? null)
    } catch (err) {
      logger.warn('SettingsPage', 'OwnCompany lekérdezés sikertelen:', err)
      setCompanyData(null)
    } finally {
      setCompanyLoading(false)
    }
  }, [])

  useEffect(() => {
    if (activeTab === 'company') {
      void loadCompany()
    }
  }, [activeTab, loadCompany])

  const handleCompanyChange = (field: EditableOwnCompanyKeys, value: string) => {
    setCompanyData((prev) => prev ? { ...prev, [field]: value } : prev)
  }

  const handleCompanySave = async () => {
    if (!companyData) return
    setCompanySaving(true)
    try {
      const updated = await ownCompanyApi.update(companyData.id, companyData)
      setCompanyData(updated)
      toast.success('Cégadatok mentve', updated.name ?? '')
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Ismeretlen hiba'
      toast.error('Mentés sikertelen', msg)
      logger.error('SettingsPage', 'OwnCompany mentés sikertelen:', err)
    } finally {
      setCompanySaving(false)
    }
  }

  const tabs = [
    { id: 'company', name: 'Cégadatok', icon: Building },
    { id: 'users', name: 'Felhasználók', icon: Users },
    { id: 'system-parameters', name: 'Rendszerparaméterek', icon: Sliders },
    { id: 'permissions', name: 'Jogosultságok', icon: Shield },
    { id: 'roles', name: 'Szerepkörök', icon: Users },
    { id: 'printing', name: 'Nyomtatás', icon: Printer },
    { id: 'database', name: 'Adatbázis', icon: Database },
    { id: 'notifications', name: 'Értesítések', icon: Bell },
    { id: 'security', name: 'Biztonság', icon: Shield },
    { id: 'appearance', name: 'Megjelenés', icon: Palette },
  ]

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Settings />
          Beállítások
        </h1>
      </div>

      <div className="grid grid-cols-5 gap-3">
        {/* Sidebar */}
        <div className="form-panel">
          <div className="space-y-1">
            {tabs.map((tab) => {
              const Icon = tab.icon
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full text-left p-2 rounded flex items-center gap-2 transition-colors ${
                    activeTab === tab.id
                      ? 'bg-blue-100 text-blue-800 border border-blue-300'
                      : 'hover:bg-gray-100'
                  }`}
                >
                  <Icon size={16} />
                  <span className="text-sm font-medium">{tab.name}</span>
                </button>
              )
            })}
          </div>
        </div>

        {/* Content */}
        <div className="col-span-4 form-panel">
          {activeTab === 'company' && (
            <div className="space-y-4">
              <h2 className="section-title">Cégadatok</h2>
              {companyLoading && (
                <div className="flex items-center gap-2 text-gray-500">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span>Betöltés...</span>
                </div>
              )}
              {!companyLoading && !companyData && (
                <div className="rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
                  Nincs aktív cégadat-rekord — a Flyway V172 migráció EBC Zrt. seed után automatikusan betöltődik.
                </div>
              )}
              {!companyLoading && companyData && (
                <>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="form-label">Cégnév</label>
                      <input
                        type="text"
                        className="form-input"
                        value={companyData.name ?? ''}
                        onChange={(e) => handleCompanyChange('name', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">Adószám</label>
                      <input
                        type="text"
                        className="form-input font-mono"
                        value={companyData.taxNumber ?? ''}
                        onChange={(e) => handleCompanyChange('taxNumber', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">Cégjegyzékszám</label>
                      <input
                        type="text"
                        className="form-input font-mono"
                        value={companyData.registrationNumber ?? ''}
                        onChange={(e) => handleCompanyChange('registrationNumber', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">MNB engedély száma</label>
                      <input
                        type="text"
                        className="form-input font-mono"
                        value={companyData.licenseNumber ?? ''}
                        onChange={(e) => handleCompanyChange('licenseNumber', e.target.value)}
                      />
                    </div>
                    <div className="col-span-2">
                      <label className="form-label">Székhely</label>
                      <input
                        type="text"
                        className="form-input"
                        value={companyData.address ?? ''}
                        onChange={(e) => handleCompanyChange('address', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">Telefon</label>
                      <input
                        type="text"
                        className="form-input"
                        value={companyData.phone ?? ''}
                        onChange={(e) => handleCompanyChange('phone', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">E-mail</label>
                      <input
                        type="email"
                        className="form-input"
                        value={companyData.email ?? ''}
                        onChange={(e) => handleCompanyChange('email', e.target.value)}
                      />
                    </div>
                  </div>
                  <div className="flex justify-end">
                    <button
                      className="form-button-primary"
                      onClick={handleCompanySave}
                      disabled={companySaving}
                    >
                      {companySaving ? 'Mentés folyamatban...' : 'Mentés'}
                    </button>
                  </div>
                </>
              )}
            </div>
          )}

          {activeTab === 'system-parameters' && (
            <SystemParameterPage />
          )}

          {activeTab === 'permissions' && (
            <PermissionPage />
          )}

          {activeTab === 'roles' && (
            <RolePage />
          )}

          {activeTab === 'users' && (
            <UserPage />
          )}

          {activeTab === 'printing' && (
            <div className="space-y-4">
              <h2 className="section-title">Nyomtatási beállítások</h2>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Bizonylat nyomtató</label>
                  <select className="form-input">
                    <option>EPSON TM-T88V</option>
                    <option>Star TSP100</option>
                    <option>PDF (fájlba)</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">Riport nyomtató</label>
                  <select className="form-input">
                    <option>HP LaserJet Pro</option>
                    <option>PDF (fájlba)</option>
                  </select>
                </div>
              </div>
              <div className="space-y-2">
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span>Automatikus bizonylat nyomtatás</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span>Nyomtatás előnézet megjelenítése</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" />
                  <span>Duplikált bizonylat nyomtatása</span>
                </label>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">Mentés</button>
              </div>
            </div>
          )}

          {activeTab === 'database' && (
            <div className="space-y-4">
              <h2 className="section-title">Adatbázis</h2>
              <div className="bg-green-50 p-3 rounded border border-green-200">
                <span className="text-green-800">Kapcsolat: OK | PostgreSQL 15.2</span>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Szerver</label>
                  <input type="text" className="form-input" defaultValue="localhost" disabled />
                </div>
                <div>
                  <label className="form-label">Adatbázis</label>
                  <input type="text" className="form-input" defaultValue="valutavalto" disabled />
                </div>
              </div>
              <div className="flex gap-2">
                <button className="form-button">Biztonsági mentés</button>
                <button className="form-button">Visszaállítás</button>
                <button className="form-button text-red-600">Adatok törlése</button>
              </div>
            </div>
          )}

          {activeTab === 'notifications' && (
            <div className="space-y-4">
              <h2 className="section-title">Értesítések</h2>
              <div className="space-y-3">
                <label className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span>Alacsony készlet figyelmeztetés</span>
                  <input type="checkbox" className="rounded" defaultChecked />
                </label>
                <label className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span>Napi zárás emlékeztető</span>
                  <input type="checkbox" className="rounded" defaultChecked />
                </label>
                <label className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span>MNB árfolyam frissítés</span>
                  <input type="checkbox" className="rounded" defaultChecked />
                </label>
                <label className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span>Nagy összegű tranzakció</span>
                  <input type="checkbox" className="rounded" />
                </label>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">Mentés</button>
              </div>
            </div>
          )}

          {activeTab === 'security' && (
            <div className="space-y-4">
              <h2 className="section-title">Biztonsági beállítások</h2>
              <div className="space-y-3">
                <div>
                  <label className="form-label">Jelszó minimális hossza</label>
                  <input type="number" className="form-input w-24" defaultValue={8} />
                </div>
                <div>
                  <label className="form-label">Munkamenet időkorlát (perc)</label>
                  <input type="number" className="form-input w-24" defaultValue={30} />
                </div>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span>Kétfaktoros hitelesítés kötelező</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span>Sikertelen bejelentkezések naplózása</span>
                </label>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">Mentés</button>
              </div>
            </div>
          )}

          {activeTab === 'appearance' && (
            <div className="space-y-4">
              <h2 className="section-title">Megjelenés</h2>
              <div className="space-y-3">
                <div>
                  <label className="form-label">Téma</label>
                  <select className="form-input w-48">
                    <option>Világos</option>
                    <option>Sötét</option>
                    <option>Rendszer beállítás</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">Nyelv</label>
                  <select className="form-input w-48">
                    <option>Magyar</option>
                    <option>English</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">Dátum formátum</label>
                  <select className="form-input w-48">
                    <option>ÉÉÉÉ-HH-NN</option>
                    <option>ÉÉÉÉ.HH.NN</option>
                    <option>NN/HH/ÉÉÉÉ</option>
                  </select>
                </div>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">Mentés</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
