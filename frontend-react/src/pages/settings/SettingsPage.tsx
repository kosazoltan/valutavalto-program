import { useState, useEffect, useCallback } from 'react'
import {
  Settings,
  Building,
  Users,
  Printer,
  Database,
  Bell,
  Shield,
  Palette,
  Sliders,
  Loader2,
  FileText,
  AlertTriangle,
  Landmark,
  KeyRound,
  Languages,
  Mail,
} from 'lucide-react'
import SystemParameterPage from './SystemParameterPage'
import PermissionPage from './PermissionPage'
import RolePage from './RolePage'
import UserPage from './UserPage'
import ReceiptTextSettingsPage from './ReceiptTextSettingsPage'
import CashierBandSettingsPage from './CashierBandSettingsPage'
import ValueBandSettingsPage from './ValueBandSettingsPage'
import IncomeProofRecipientsPanel from './IncomeProofRecipientsPanel'
import BankIntegrationStatusPage from './BankIntegrationStatusPage'
import MfaEnrollmentPage from './MfaEnrollmentPage'
import SupervisorPinSettingsPanel from './SupervisorPinSettingsPanel'
import TranslationSettingsPage from './TranslationSettingsPage'
import WorkerPasswordSettingsPanel from './WorkerPasswordSettingsPanel'
import { ownCompanyApi, type OwnCompany } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

/**
 * v2.3.36 (Sourcery #299 P3): Type-safe field whitelist a SettingsPage company
 * tab szerkesztheto mezoinek.
 * v2.3.37 (Sourcery #301 P3): Pick<OwnCompany, ...> derivacio a hardcoded union
 * helyett — igy ha az `OwnCompany` interface-be uj editable mezo kerul, a
 * compiler hibat dob, ha NEM frissitjuk a whitelist-et (drift-prevention).
 */
type EditableOwnCompanyKeys = keyof Pick<
  OwnCompany,
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
>

/**
 * v2.3.34 (B11): Cégadatok tab most az aktív OwnCompany rekordbol toltodik
 * (NEM hardkodolt "Pénzváltó Kft." placeholder-ek). Ha az own_company tabla
 * ures, akkor a v2.3.34 V172 Flyway migration az EBC Zrt. seed-et szurja be
 * (Exclusive Best Change Zrt. — kosa.zoltan.ebc@gmail.com beruhazo cege).
 */
export default function SettingsPage() {
  const { t } = useTranslation()
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
    setCompanyData((prev) => (prev ? { ...prev, [field]: value } : prev))
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
    { id: 'receipt-texts', name: 'Bizonylat szövegek', icon: FileText },
    { id: 'translations', name: 'Fordítások', icon: Languages },
    { id: 'cashier-band', name: 'Pénztárosi sáv', icon: AlertTriangle },
    { id: 'value-bands', name: 'AML értéksávok', icon: Sliders },
    { id: 'income-proof-recipients', name: 'Jövedelemig. címzettek', icon: Mail },
    { id: 'bank-integration', name: 'Bank integráció', icon: Landmark },
    { id: 'mfa', name: 'Kétfaktoros (MFA)', icon: KeyRound },
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
          {t('settings.settings')}
        </h1>
      </div>

      <div className="grid grid-cols-1 gap-3 lg:grid-cols-5">
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
        <div className="form-panel lg:col-span-4">
          {activeTab === 'company' && (
            <div className="space-y-4">
              <h2 className="section-title">{t('settings.company')}</h2>
              {companyLoading && (
                <div className="flex items-center gap-2 text-gray-500">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span>{i18n.t('literals.betoltes')}</span>
                </div>
              )}
              {!companyLoading && !companyData && (
                <div className="rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
                  {t(
                    'settings.nincsAktivCegadatRekordAFlywayV172MigracioEbcZrtSeedUtanAutomatikusanBetoltodik',
                  )}
                </div>
              )}
              {!companyLoading && companyData && (
                <>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="form-label">{t('blacklist.cegnev2')}</label>
                      <input
                        type="text"
                        className="form-input"
                        value={companyData.name ?? ''}
                        onChange={(e) => handleCompanyChange('name', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">{t('common.taxNumber')}</label>
                      <input
                        type="text"
                        className="form-input font-mono"
                        value={companyData.taxNumber ?? ''}
                        onChange={(e) => handleCompanyChange('taxNumber', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">{t('common.companyRegNumber')}</label>
                      <input
                        type="text"
                        className="form-input font-mono"
                        value={companyData.registrationNumber ?? ''}
                        onChange={(e) => handleCompanyChange('registrationNumber', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">{t('settings.mnbEngedelySzama')}</label>
                      <input
                        type="text"
                        className="form-input font-mono"
                        value={companyData.licenseNumber ?? ''}
                        onChange={(e) => handleCompanyChange('licenseNumber', e.target.value)}
                      />
                    </div>
                    <div className="col-span-2">
                      <label className="form-label">{t('settings.szekhely')}</label>
                      <input
                        type="text"
                        className="form-input"
                        value={companyData.address ?? ''}
                        onChange={(e) => handleCompanyChange('address', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">{t('common.phone')}</label>
                      <input
                        type="text"
                        className="form-input"
                        value={companyData.phone ?? ''}
                        onChange={(e) => handleCompanyChange('phone', e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="form-label">{t('customers.eMail')}</label>
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

          {activeTab === 'system-parameters' && <SystemParameterPage />}

          {activeTab === 'permissions' && <PermissionPage />}

          {activeTab === 'roles' && <RolePage />}

          {activeTab === 'users' && <UserPage />}

          {activeTab === 'printing' && (
            <div className="space-y-4">
              <h2 className="section-title">{t('settings.nyomtatasiBeallitasok')}</h2>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('settings.bizonylatNyomtato')}</label>
                  <select className="form-input">
                    <option>{t('settings.epsonTmT88v')}</option>
                    <option>{t('settings.starTsp100')}</option>
                    <option>{t('settings.pdfFajlba')}</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">{t('settings.riportNyomtato')}</label>
                  <select className="form-input">
                    <option>{t('settings.hpLaserjetPro')}</option>
                    <option>{t('settings.pdfFajlba')}</option>
                  </select>
                </div>
              </div>
              <div className="space-y-2">
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span>{t('settings.automatikusBizonylatNyomtatas')}</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span>{t('settings.nyomtatasElonezetMegjelenitese')}</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" />
                  <span>{t('settings.duplikaltBizonylatNyomtatasa')}</span>
                </label>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">{t('common.save')}</button>
              </div>
            </div>
          )}

          {activeTab === 'receipt-texts' && <ReceiptTextSettingsPage />}

          {activeTab === 'translations' && <TranslationSettingsPage />}

          {activeTab === 'cashier-band' && <CashierBandSettingsPage />}

          {activeTab === 'value-bands' && <ValueBandSettingsPage />}

          {activeTab === 'income-proof-recipients' && <IncomeProofRecipientsPanel />}

          {activeTab === 'bank-integration' && <BankIntegrationStatusPage />}

          {activeTab === 'mfa' && (
            <div className="space-y-4">
              <SupervisorPinSettingsPanel />
              <MfaEnrollmentPage />
            </div>
          )}

          {activeTab === 'database' && (
            <div className="space-y-4">
              <h2 className="section-title">{t('settings.adatbazis')}</h2>
              <div className="bg-green-50 p-3 rounded border border-green-200">
                <span className="text-green-800">
                  {i18n.t('literals.kapcsolat-ok-postgresql-15-2')}
                </span>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('settings.szerver')}</label>
                  <input type="text" className="form-input" defaultValue="localhost" disabled />
                </div>
                <div>
                  <label className="form-label">{t('settings.adatbazis')}</label>
                  <input type="text" className="form-input" defaultValue="valutavalto" disabled />
                </div>
              </div>
              <div className="flex gap-2">
                <button className="form-button">{t('settings.biztonsagiMentes')}</button>
                <button className="form-button">{t('settings.visszaallitas')}</button>
                <button className="form-button text-red-600">{t('settings.adatokTorlese')}</button>
              </div>
            </div>
          )}

          {activeTab === 'notifications' && (
            <div className="space-y-4">
              <h2 className="section-title">{t('notifications.ertesitesek')}</h2>
              <div className="space-y-3">
                <label className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span>{t('settings.alacsonyKeszletFigyelmeztetes')}</span>
                  <input type="checkbox" className="rounded" defaultChecked />
                </label>
                <label className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span>{t('settings.napiZarasEmlekezteto')}</span>
                  <input type="checkbox" className="rounded" defaultChecked />
                </label>
                <label className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span>{t('settings.mnbArfolyamFrissites')}</span>
                  <input type="checkbox" className="rounded" defaultChecked />
                </label>
                <label className="flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span>{t('settings.nagyOsszeguTranzakcio')}</span>
                  <input type="checkbox" className="rounded" />
                </label>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">{t('common.save')}</button>
              </div>
            </div>
          )}

          {activeTab === 'security' && (
            <div className="space-y-4">
              <WorkerPasswordSettingsPanel />
              <h2 className="section-title">{t('settings.biztonsagiBeallitasok')}</h2>
              <div className="space-y-3">
                <div>
                  <label className="form-label">{t('settings.jelszoMinimalisHossza')}</label>
                  <input type="number" className="form-input w-24" defaultValue={8} />
                </div>
                <div>
                  <label className="form-label">{t('settings.munkamenetIdokorlatPerc')}</label>
                  <input type="number" className="form-input w-24" defaultValue={30} />
                </div>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span>{t('settings.ketfaktorosHitelesitesKotelezo')}</span>
                </label>
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" defaultChecked />
                  <span>{t('settings.sikertelenBejelentkezesekNaplozasa')}</span>
                </label>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">{t('common.save')}</button>
              </div>
            </div>
          )}

          {activeTab === 'appearance' && (
            <div className="space-y-4">
              <h2 className="section-title">{t('settings.megjelenes')}</h2>
              <div className="space-y-3">
                <div>
                  <label className="form-label">{t('settings.tema')}</label>
                  <select className="form-input w-48">
                    <option>{t('settings.vilagos')}</option>
                    <option>{t('settings.sotet')}</option>
                    <option>{t('settings.rendszerBeallitas')}</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">{t('settings.nyelv')}</label>
                  <select className="form-input w-48">
                    <option>{t('settings.magyar')}</option>
                    <option>{t('settings.english')}</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">{t('settings.datumFormatum')}</label>
                  <select className="form-input w-48">
                    <option>{t('settings.eeeeHhNn')}</option>
                    <option>{i18n.t('literals.eeee-hh-nn')}</option>
                    <option>{t('settings.nnHhEeee')}</option>
                  </select>
                </div>
              </div>
              <div className="flex justify-end">
                <button className="form-button-primary">{t('common.save')}</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
