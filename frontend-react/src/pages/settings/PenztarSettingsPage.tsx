import { useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Settings as SettingsIcon, Save, X } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import {
  loadPenztarSettings, savePenztarSettings, isValidServerIp, clampFrequency,
  FREQUENCY_MIN, FREQUENCY_MAX,
  type PenztarSettings, type MachineRole, type DisplayColor, type PrinterPort,
  type HandlingFeeMode,
} from './penztarSettings'

const APP_OPTIONS = ['VALUTAVALTAS', 'WESTERN_UNION', 'TESCO_AFA', 'METRO_AFA', 'E_KERESKEDELEM']

/**
 * G20 (EXCMD b6-beallitasok): pénztárgép lokális beállítások képernyő.
 * Az értékek "Rögzítés és kilépés" után perzisztensek (localStorage). A tényleges
 * hardver-kötés (szkenner/nyomtató/futófény/IP) runtime-feladat az Electron mainben.
 */
export default function PenztarSettingsPage() {
  const navigate = useNavigate()
  const [s, setS] = useState<PenztarSettings>(() => loadPenztarSettings())

  const set = useCallback(<K extends keyof PenztarSettings>(key: K, value: PenztarSettings[K]) => {
    setS((prev) => ({ ...prev, [key]: value }))
  }, [])

  const setOctet = (i: number, raw: string) => {
    const v = Math.max(0, Math.min(255, Math.floor(Number(raw) || 0)))
    setS((prev) => {
      const ip = [...prev.serverIp] as [number, number, number, number]
      ip[i] = v
      return { ...prev, serverIp: ip }
    })
  }

  const toggleApp = (app: string) => {
    setS((prev) => ({
      ...prev,
      applications: prev.applications.includes(app)
        ? prev.applications.filter((a) => a !== app)
        : [...prev.applications, app],
    }))
  }

  const handleSave = () => {
    if (!isValidServerIp(s.serverIp)) {
      toast.error('Érvénytelen IP', 'Mind a 4 oktett 0–255 közötti egész legyen.')
      return
    }
    savePenztarSettings(s)
    toast.success('Mentve', 'A beállítások rögzítve.')
    navigate(-1)
  }

  const radioGroup = <T extends string>(
    label: string, value: T, options: Array<{ v: T; label: string }>, onChange: (v: T) => void,
  ) => (
    <div>
      <div className="form-label">{label}</div>
      <div className="flex flex-wrap gap-3">
        {options.map((o) => (
          <label key={o.v} className="flex items-center gap-1 text-sm">
            <input type="radio" checked={value === o.v} onChange={() => onChange(o.v)} />
            {o.label}
          </label>
        ))}
      </div>
    </div>
  )

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><SettingsIcon />Pénztárgép beállítások</h1>

      <div className="form-panel space-y-3">
        <h2 className="section-title">Alapfunkció</h2>
        {radioGroup<MachineRole>('A gép szerepe', s.machineRole, [
          { v: 'PENZTARI', label: 'Pénztári gép' },
          { v: 'ERTEKTARI', label: 'Értéktári gép' },
          { v: 'AFAS', label: 'ÁFÁS gép' },
        ], (v) => set('machineRole', v))}

        <div>
          <div className="form-label">Engedélyezett alkalmazások</div>
          <div className="flex flex-wrap gap-3">
            {APP_OPTIONS.map((app) => (
              <label key={app} className="flex items-center gap-1 text-sm">
                <input type="checkbox" checked={s.applications.includes(app)} onChange={() => toggleApp(app)} />
                {app.replace(/_/g, ' ')}
              </label>
            ))}
          </div>
        </div>
      </div>

      <div className="form-panel space-y-3">
        <h2 className="section-title">Kijelző és reklám</h2>
        {radioGroup<DisplayColor>('Árfolyam-kijelző színe', s.displayColor, [
          { v: 'ZOLD', label: 'Zöld' }, { v: 'SARGA', label: 'Sárga' }, { v: 'PIROS', label: 'Piros' },
        ], (v) => set('displayColor', v))}
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={s.adOnDisplay} onChange={(e) => set('adOnDisplay', e.target.checked)} />
          Reklám a kijelzőn
        </label>
      </div>

      <div className="form-panel space-y-3">
        <h2 className="section-title">Szerver kapcsolat</h2>
        <div>
          <div className="form-label">Szerver elérés IP-címe</div>
          <div className="flex items-center gap-1">
            {[0, 1, 2, 3].map((i) => (
              <span key={i} className="flex items-center gap-1">
                <input
                  className="form-input w-16 text-center" type="number" min={0} max={255}
                  value={s.serverIp[i]} onChange={(e) => setOctet(i, e.target.value)}
                />
                {i < 3 && <span>.</span>}
              </span>
            ))}
          </div>
        </div>
        <div>
          <label className="form-label" htmlFor="freq">Adatküldés gyakorisága: {s.dataSendFrequencyMin} perc</label>
          <input
            id="freq" type="range" min={FREQUENCY_MIN} max={FREQUENCY_MAX} value={s.dataSendFrequencyMin}
            onChange={(e) => set('dataSendFrequencyMin', clampFrequency(Number(e.target.value)))}
            className="w-full"
          />
        </div>
      </div>

      <div className="form-panel space-y-3">
        <h2 className="section-title">Napi jelentés</h2>
        <div>
          <label className="form-label" htmlFor="email">Értéktár e-mail címe</label>
          <input id="email" type="email" className="form-input w-full"
            value={s.dailyReportEmail} onChange={(e) => set('dailyReportEmail', e.target.value)} />
        </div>
        {radioGroup<string>('Szombati nyitvatartás', s.saturdayOpen ? 'OPEN' : 'CLOSED', [
          { v: 'OPEN', label: 'Szombaton nyitva' }, { v: 'CLOSED', label: 'Szombaton zárva' },
        ], (v) => set('saturdayOpen', v === 'OPEN'))}
      </div>

      <div className="form-panel space-y-3">
        <h2 className="section-title">Eszközök és fizetés</h2>
        {radioGroup<PrinterPort>('Nyomtató típusa', s.printerPort, [
          { v: 'LPT1', label: 'LPT1 portra csatlakoztatva' }, { v: 'USB', label: 'USB portra csatlakoztatva' },
        ], (v) => set('printerPort', v))}
        <div>
          <label className="form-label" htmlFor="scanner">Szkenner driver</label>
          <input id="scanner" className="form-input w-full" placeholder="pl. WIA-CanoScan Lide 120"
            value={s.scannerDriver} onChange={(e) => set('scannerDriver', e.target.value)} />
        </div>
        {radioGroup<HandlingFeeMode>('Kezelési költség', s.handlingFeeMode, [
          { v: 'NINCS', label: 'Nincs' }, { v: 'EZRELEKES', label: 'Ezrelékes' }, { v: 'SAVOS', label: 'Sávos' },
        ], (v) => set('handlingFeeMode', v))}
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={s.cardPaymentEnabled} onChange={(e) => set('cardPaymentEnabled', e.target.checked)} />
          Bankkártyás fizetés engedélyezve
        </label>
      </div>

      <div className="flex gap-2">
        <button onClick={handleSave} className="form-button-primary flex items-center gap-1">
          <Save size={16} />Rögzítés és kilépés
        </button>
        <button onClick={() => navigate(-1)} className="form-button flex items-center gap-1">
          <X size={16} />Kilépés módosítás nélkül
        </button>
      </div>
    </div>
  )
}
