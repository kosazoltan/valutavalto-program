import { useState } from 'react'
import { Settings, Building, Users, Printer, Database, Bell, Shield, Palette, Sliders } from 'lucide-react'
import SystemParameterPage from './SystemParameterPage'
import PermissionPage from './PermissionPage'
import RolePage from './RolePage'
import UserPage from './UserPage'

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState('company')

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
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Cégnév</label>
                  <input type="text" className="form-input" defaultValue="Pénzváltó Kft." />
                </div>
                <div>
                  <label className="form-label">Adószám</label>
                  <input type="text" className="form-input font-mono" defaultValue="12345678-2-41" />
                </div>
                <div>
                  <label className="form-label">Cégjegyzékszám</label>
                  <input type="text" className="form-input font-mono" defaultValue="01-09-123456" />
                </div>
                <div>
                  <label className="form-label">MNB engedély száma</label>
                  <input type="text" className="form-input font-mono" defaultValue="MNB-123/2020" />
                </div>
                <div className="col-span-2">
                  <label className="form-label">Székhely</label>
                  <input type="text" className="form-input" defaultValue="1011 Budapest, Fő utca 1." />
                </div>
                <div>
                  <label className="form-label">Telefon</label>
                  <input type="text" className="form-input" defaultValue="+36 1 234 5678" />
                </div>
                <div>
                  <label className="form-label">E-mail</label>
                  <input type="email" className="form-input" defaultValue="info@penzvalto.hu" />
                </div>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">Mentés</button>
              </div>
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
