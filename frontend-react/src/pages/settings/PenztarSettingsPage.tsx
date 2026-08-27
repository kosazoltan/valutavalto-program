import { useState, useCallback, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { Settings as SettingsIcon, Save, X, Lock } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import {
  loadPenztarSettings,
  savePenztarSettings,
  isValidServerIp,
  clampFrequency,
  clampFutofenyDarab,
  clampFutofenySebesseg,
  clampComPort,
  FREQUENCY_MIN,
  FREQUENCY_MAX,
  type PenztarSettings,
  type MachineRole,
  type DisplayColor,
  type PrinterPort,
  type HandlingFeeMode,
  type FutofenyMode,
} from './penztarSettings'
import { machineConfigApi, resolveWorkstationCode } from '../../services/api/machineConfig'
import i18n from '../../i18n'

const APP_OPTIONS = ['VALUTAVALTAS', 'WESTERN_UNION', 'TESCO_AFA', 'METRO_AFA', 'E_KERESKEDELEM']

/**
 * G20 (EXCMD b6-beallitasok): pénztárgép lokális beállítások képernyő.
 *
 * FR-14 Perzisztencia (háromrétegű):
 *   1. localStorage (gyors lokális cache, offline-safe)
 *   2. Backend PUT /api/v1/machine-config/{workstationCode} (Postgres, company-izolált)
 *   Betöltéskor: backend érték nyeri, localStorage a fallback (offline).
 *   Electron SQLite: az általános getConfig/setConfig IPC nincs kibővítve (az Electron
 *   main módosítása kockázatos ebben a körben) — a backend+localStorage elegendő.
 *
 * FR-06 Jelszó biztonsági eltérés:
 *   A spec plain-text jelszót mutat ("<JELSZO>"), de b9 NFR-02 + security-standards
 *   alapján maszkoltan jelenítjük meg (••••). A jelszó-módosítás inline modal-ban
 *   (window.prompt TILOS Electron-ban); a plain-text a backendnek megy, ahol BCrypt-tel
 *   hash-elődik; a hash soha nem jön vissza (csak dailyReportPasswordSet: boolean).
 *
 * FR-06 Branch mezők:
 *   Az értéktár e-mail és szombati nyitvatartás a Branch entitáson él (V293).
 *   Döntés: a settings oldalon read-only hivatkozással jelennek meg, szerkesztés a
 *   Pénztár Törzsben (BranchEditPage). NEM duplikáljuk a branch-adatot a machine_config
 *   JSON-ban — elkerüljük az inkonzisztenciát.
 *
 * FR-11 Futófény:
 *   A soros-port vezérlés (COM-port tényleges nyitása) runtime-feladat (spec
 *   integration_points szerint külön réteg). A panel a KONFIGURÁCIÓT rögzíti.
 */
export default function PenztarSettingsPage() {
  const navigate = useNavigate()
  const [s, setS] = useState<PenztarSettings>(() => loadPenztarSettings())
  const [loading, setLoading] = useState(true)
  const workstationCodeRef = useRef<string>('UNKNOWN')

  // SP500 nyomtató-konfiguráció: elérhető Windows-nyomtatók és soros portok (Electron)
  const [printers, setPrinters] = useState<Array<{ name: string; displayName: string }>>([])
  const [serialPorts, setSerialPorts] = useState<
    Array<{ path: string; manufacturer?: string; friendlyName?: string }>
  >([])
  // Kompenzáló rollbackhez: a betöltéskor (ill. utolsó sikeres mentéskor)
  // érvényes operatív SQLite-értékek ('' = nincs beállítva)
  const sqlitePrinterRef = useRef({ device: '', serial: '' })

  // FR-14: Betöltéskor backend érték nyeri, localStorage fallback (offline)
  useEffect(() => {
    let cancelled = false
    async function loadFromBackend() {
      try {
        const code = await resolveWorkstationCode()
        if (!cancelled) workstationCodeRef.current = code
        const remote = await machineConfigApi.get(code)
        if (remote && remote.config && !cancelled) {
          try {
            const parsed = JSON.parse(remote.config) as Partial<PenztarSettings>
            // Backend-érték nyeri: felülírja a localStorage cache-t
            setS((prev) => ({ ...prev, ...parsed }))
          } catch {
            // Sérült backend JSON → localStorage-érték marad
          }
        }
        // dailyReportPasswordSet jelzőt a UI-ban felhasználhatjuk (jelenleg megjelenítjük)
      } catch {
        // Offline → localStorage fallback
      }

      // SP500: nyomtató-/portlista + az Electron SQLite operatív értékei
      // (printer.deviceName / printer.serialPort). A backend-merge UTÁN fut,
      // mert nyomtatáskor a main process a SQLite-ból olvas — az nyer a kijelzésben.
      const api = window.electronAPI
      if (api?.getPrinters) {
        try {
          const [printerList, portList, storedDevice, storedPort] = await Promise.all([
            api.getPrinters().catch(() => []),
            api.listSerialPorts().catch(() => []),
            api.getConfig('printer.deviceName').catch(() => null),
            api.getConfig('printer.serialPort').catch(() => null),
          ])
          if (!cancelled) {
            setPrinters(printerList)
            setSerialPorts(portList)
            // Az SQLite az operatív igazságforrás: a tárolt érték (az explicit
            // üres string is!) felülírja a backend/localStorage állapotot;
            // csak hiányzó kulcs (null) esetén marad az örökölt érték.
            sqlitePrinterRef.current = {
              device: typeof storedDevice === 'string' ? storedDevice.trim() : '',
              serial: typeof storedPort === 'string' ? storedPort.trim() : '',
            }
            setS((prev) => ({
              ...prev,
              printerDeviceName:
                typeof storedDevice === 'string' ? storedDevice.trim() : prev.printerDeviceName,
              printerSerialPort:
                typeof storedPort === 'string' ? storedPort.trim() : prev.printerSerialPort,
            }))
          }
        } catch {
          // Electron IPC hiba → a mezők a localStorage/backend értéken maradnak
        }
      }

      if (!cancelled) setLoading(false)
    }
    void loadFromBackend()
    return () => {
      cancelled = true
    }
  }, [])

  // FR-06: Jelszó-módosítás inline modal state
  const [showPasswordModal, setShowPasswordModal] = useState(false)
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [pendingPassword, setPendingPassword] = useState<string | undefined>(undefined)

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

  const handleSave = async () => {
    if (!isValidServerIp(s.serverIp)) {
      toast.error('Érvénytelen IP', 'Mind a 4 oktett 0–255 közötti egész legyen.')
      return
    }
    // FR-11: COM-portok egyediség-ellenőrzése (spec FR-11 validáció)
    if (s.futofenyDarab >= 2 && s.futofenyCom1 === s.futofenyCom2) {
      toast.error(
        'COM-port ütközés',
        'Az első és második futófénytábla COM-portja nem lehet azonos.',
      )
      return
    }

    // Operatív réteg (SP500) ELŐSZÖR: Electron SQLite config — nyomtatáskor a main
    // process print-receipt handlere EBBŐL olvas (fail-closed); üres string = nincs
    // beállítva. A localStorage/backend csak sikeres SQLite-írás után frissül, így a
    // rétegek nem csúszhatnak szét. Két kulcs, nincs batch-IPC: hiba esetén az első
    // kulcs kompenzáló rollbackkel áll vissza (végállapot: mindkét kulcs régi VAGY új).
    const api = window.electronAPI
    if (api?.setConfig) {
      const nextDevice = s.printerDeviceName.trim()
      const nextSerial = s.printerSerialPort.trim()
      let deviceWritten = false
      try {
        await api.setConfig('printer.deviceName', nextDevice)
        deviceWritten = true
        await api.setConfig('printer.serialPort', nextSerial)
      } catch {
        if (deviceWritten) {
          try {
            await api.setConfig('printer.deviceName', sqlitePrinterRef.current.device)
          } catch {
            // best-effort rollback — a hibajelzés alább így is megtörténik
          }
        }
        toast.error(
          'Nyomtató-beállítás mentési hiba',
          'A nyomtató-beállítás lokális (Electron) mentése nem sikerült — a beállítások NEM kerültek mentésre, kérjük, próbálja újra.',
        )
        return
      }
      sqlitePrinterRef.current = { device: nextDevice, serial: nextSerial }
    }

    // localStorage réteg (csak a sikeres operatív írás után)
    const ok = savePenztarSettings(s)
    if (!ok) {
      toast.error(
        'Mentési hiba',
        'A beállítások mentése nem sikerült (böngésző tárhely / privát mód).',
      )
      return
    }

    // 2. réteg: Backend (async, nem blokkoló — offline esetén silent fail)
    try {
      await machineConfigApi.put(workstationCodeRef.current, {
        configJson: JSON.stringify(s),
        // Jelszó csak ha a user új jelszót adott meg a modalban
        dailyReportPassword: pendingPassword,
      })
      // Jelszót csak sikeres backend-mentés után töröljük (Codex P2: hiba esetén megmarad)
      setPendingPassword(undefined)
    } catch {
      // Backend-hiba nem blokkolja a mentést — localStorage-ban megvan.
      // Jelszó-state szándékosan megmarad, hogy újrapróbáláskor ne kelljen újra beírni.
      toast.error(
        'Backend szinkron hiba',
        'A beállítások lokálisan mentve, de a szerver-szinkronizáció sikertelen. Kérjük, próbáljon meg újra menteni.',
      )
      return
    }

    toast.success('Mentve', 'A beállítások rögzítve.')
    navigate(-1)
  }

  const handlePasswordSave = () => {
    if (!newPassword || newPassword.length < 4) {
      toast.error('Rövid jelszó', 'A jelszónak legalább 4 karakter hosszúnak kell lennie.')
      return
    }
    if (newPassword !== confirmPassword) {
      toast.error('Jelszó-eltérés', 'A két jelszó nem egyezik.')
      return
    }
    setPendingPassword(newPassword)
    setNewPassword('')
    setConfirmPassword('')
    setShowPasswordModal(false)
    toast.success(
      'Jelszó beállítva',
      'Az új jelszó a "Rögzítés és kilépés" gombra mentődik el a szerverre.',
    )
  }

  const radioGroup = <T extends string>(
    name: string,
    label: string,
    value: T,
    options: Array<{ v: T; label: string }>,
    onChange: (v: T) => void,
  ) => (
    <div>
      <div className="form-label">{label}</div>
      <div className="flex flex-wrap gap-3">
        {options.map((o) => (
          <label key={o.v} className="flex items-center gap-1 text-sm">
            <input
              type="radio"
              name={name}
              checked={value === o.v}
              onChange={() => onChange(o.v)}
            />
            {o.label}
          </label>
        ))}
      </div>
    </div>
  )

  if (loading) {
    return (
      <div className="space-y-4">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <SettingsIcon />
          {i18n.t('literals.penztargep-beallitasok')}
        </h1>
        <div className="form-panel text-sm text-muted-foreground">
          {i18n.t('literals.beallitasok-betoltese')}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2">
        <SettingsIcon />
        {i18n.t('literals.penztargep-beallitasok')}
      </h1>

      {/* FR-02 + FR-03: Alapfunkció és Alkalmazások */}
      <div className="form-panel space-y-3">
        <h2 className="section-title">{i18n.t('literals.alapfunkcio')}</h2>
        {radioGroup<MachineRole>(
          'machineRole',
          'A gép szerepe',
          s.machineRole,
          [
            { v: 'PENZTARI', label: 'Pénztári gép' },
            { v: 'ERTEKTARI', label: 'Értéktári gép' },
            { v: 'AFAS', label: 'ÁFÁS gép' },
          ],
          (v) => set('machineRole', v),
        )}

        <div>
          <div className="form-label">{i18n.t('literals.engedelyezett-alkalmazasok')}</div>
          <div className="flex flex-wrap gap-3">
            {APP_OPTIONS.map((app) => (
              <label key={app} className="flex items-center gap-1 text-sm">
                <input
                  type="checkbox"
                  checked={s.applications.includes(app)}
                  onChange={() => toggleApp(app)}
                />
                {app.replace(/_/g, ' ')}
              </label>
            ))}
          </div>
        </div>
      </div>

      {/* FR-04 + FR-13: Kijelző és reklám */}
      <div className="form-panel space-y-3">
        <h2 className="section-title">{i18n.t('literals.kijelzo-es-reklam')}</h2>
        {radioGroup<DisplayColor>(
          'displayColor',
          'Árfolyam-kijelző színe',
          s.displayColor,
          [
            { v: 'ZOLD', label: 'Zöld' },
            { v: 'SARGA', label: 'Sárga' },
            { v: 'PIROS', label: 'Piros' },
          ],
          (v) => set('displayColor', v),
        )}
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={s.adOnDisplay}
            onChange={(e) => set('adOnDisplay', e.target.checked)}
          />
          {i18n.t('literals.reklam-a-kijelzon')}
        </label>
      </div>

      {/* FR-05 + FR-07: Szerver kapcsolat */}
      <div className="form-panel space-y-3">
        <h2 className="section-title">{i18n.t('literals.szerver-kapcsolat')}</h2>
        <div>
          <div className="form-label">{i18n.t('literals.szerver-eleres-ip-cime')}</div>
          <div className="flex items-center gap-1">
            {[0, 1, 2, 3].map((i) => (
              <span key={i} className="flex items-center gap-1">
                <input
                  className="form-input w-16 text-center"
                  type="number"
                  min={0}
                  max={255}
                  value={s.serverIp[i]}
                  onChange={(e) => setOctet(i, e.target.value)}
                />
                {i < 3 && <span>{i18n.t('literals.lit-5')}</span>}
              </span>
            ))}
          </div>
        </div>
        <div>
          <label className="form-label" htmlFor="freq">
            {i18n.t('literals.adatkuldes-gyakorisaga')}
            {s.dataSendFrequencyMin}
            {i18n.t('literals.perc')}
          </label>
          <input
            id="freq"
            type="range"
            min={FREQUENCY_MIN}
            max={FREQUENCY_MAX}
            value={s.dataSendFrequencyMin}
            onChange={(e) => set('dataSendFrequencyMin', clampFrequency(Number(e.target.value)))}
            className="w-full"
          />
        </div>
      </div>

      {/* FR-06: Napi jelentés jelszó + értéktár e-mail + szombati nyitvatartás */}
      <div className="form-panel space-y-3">
        <h2 className="section-title">{i18n.t('literals.napi-jelentes')}</h2>

        {/* Jelszó maszkolva + módosítás gomb */}
        {/*
          BIZTONSÁGI ELTÉRÉS A SPECTŐL (b6 FR-06 + b9 NFR-02):
          A spec plain-text jelszót jelenítene meg ("<JELSZO>"), de a security-standards
          alapján a jelszót maszkolt formában (••••) mutatjuk. A módosítás inline modálban
          történik (window.prompt TILOS Electron-ban).
        */}
        <div>
          <div className="form-label">{i18n.t('literals.napi-jelentes-jelszo')}</div>
          <div className="flex items-center gap-2">
            <span className="form-input w-32 inline-block text-center tracking-widest select-none text-muted-foreground">
              {pendingPassword ? '••••••••' : '••••'}
            </span>
            <button
              type="button"
              className="form-button flex items-center gap-1 text-sm"
              onClick={() => setShowPasswordModal(true)}
            >
              <Lock size={14} />
              {i18n.t('literals.jelszo-modositas')}
            </button>
            {pendingPassword && (
              <span className="text-xs text-green-600">
                {i18n.t('literals.uj-jelszo-beallitva-menteskor-ervenyesul')}
              </span>
            )}
          </div>
        </div>

        {/*
          FR-06 BRANCH MEZŐK KEZELÉSE:
          Az értéktár e-mail (Branch.email) és szombati nyitvatartás (Branch.closed_saturday)
          a Branch entitáson tárolódnak (V293). Döntés: read-only megjelenítés + link a
          Pénztár Törzsbe. NEM duplikáljuk machine_config JSON-ban az inkonzisztencia elkerülésére.
          A meglévő localStorage-értékeket (dailyReportEmail, saturdayOpen) egyelőre megtartjuk
          backward-kompatibilitásból, de a szerkesztés a BranchEditPage-en történik.
        */}
        <div className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800 space-y-1">
          <div className="font-medium">
            {i18n.t('literals.ertektar-e-mail-es-szombati-nyitvatartas')}
          </div>
          <div>
            {i18n.t('literals.ezek-a-beallitasok-a')}
            <strong>{i18n.t('literals.penztar-torzs')}</strong>
            {i18n.t('literals.iroda-adataiban-szerkeszthetok-branch-en')}{' '}
            <em>{s.dailyReportEmail || '(nem megadott)'}</em>
            {i18n.t('literals.szombat')} <em>{s.saturdayOpen ? 'nyitva' : 'zárva'}</em>
            {i18n.t('literals.lit-5')}
          </div>
        </div>
      </div>

      {/* FR-11: Futófény beállítások */}
      {/*
        Soros-port vezérlés (COM-port tényleges nyitása, adatküldés) runtime/hardver-feladat
        (spec integration_points: "COM-vezérlés külön réteg"). Ez a panel a KONFIGURÁCIÓT
        rögzíti — az Electron main folyamatban lesz a tényleges COM-kommunikáció.
      */}
      <div className="form-panel space-y-3">
        <h2 className="section-title">{i18n.t('literals.futofeny-beallitasok')}</h2>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
          <div>
            <label className="form-label" htmlFor="futofenyDarab">
              {i18n.t('literals.futofenytablak-szama')}
              {s.futofenyDarab}
            </label>
            <input
              id="futofenyDarab"
              type="number"
              min={0}
              max={10}
              className="form-input w-20"
              value={s.futofenyDarab}
              onChange={(e) => set('futofenyDarab', clampFutofenyDarab(e.target.value))}
            />
          </div>
          <div>
            <label className="form-label" htmlFor="com1">
              {i18n.t('literals.1-tabla-com-portja')}
            </label>
            <input
              id="com1"
              type="number"
              min={1}
              max={255}
              className="form-input w-20"
              value={s.futofenyCom1}
              disabled={s.futofenyDarab === 0}
              onChange={(e) => set('futofenyCom1', clampComPort(e.target.value, 1))}
            />
          </div>
          <div>
            <label className="form-label" htmlFor="com2">
              {i18n.t('literals.2-tabla-com-portja')}
            </label>
            <input
              id="com2"
              type="number"
              min={1}
              max={255}
              className="form-input w-20"
              value={s.futofenyCom2}
              disabled={s.futofenyDarab < 2}
              onChange={(e) => set('futofenyCom2', clampComPort(e.target.value, 2))}
            />
          </div>
        </div>

        {radioGroup<FutofenyMode>(
          'futofenyMod',
          'Megjelenítési mód',
          s.futofenyMod,
          [
            { v: 'ARFOLYAM', label: 'Csak árfolyam-kijelzés' },
            { v: 'SZOVEG', label: 'Csak szöveg kijelzése' },
            { v: 'VALTAKOZO', label: 'Váltakozó (nappal szöveg / éjjel árfolyam)' },
          ],
          (v) => set('futofenyMod', v),
        )}

        <div>
          <label className="form-label" htmlFor="futofenySebesseg">
            {i18n.t('literals.futofeny-sebessege')}{' '}
            <span className="font-medium">
              {s.futofenySebesseg <= 3 ? 'Lassú' : s.futofenySebesseg >= 8 ? 'Gyors' : 'Közepes'}
            </span>{' '}
            {i18n.t('literals.lit-19')}
            {s.futofenySebesseg}
            {i18n.t('literals.lit-2')}
          </label>
          <div className="flex items-center gap-2">
            <span className="text-xs">{i18n.t('literals.lassu')}</span>
            <input
              id="futofenySebesseg"
              type="range"
              min={1}
              max={10}
              value={s.futofenySebesseg}
              onChange={(e) => set('futofenySebesseg', clampFutofenySebesseg(e.target.value))}
              className="flex-1"
            />
            <span className="text-xs">{i18n.t('literals.gyors')}</span>
          </div>
        </div>

        <div>
          <button
            type="button"
            className={`form-button text-sm ${s.futofenyKikapcsolva ? 'border-red-400 text-red-700' : 'border-gray-300'}`}
            onClick={() => set('futofenyKikapcsolva', !s.futofenyKikapcsolva)}
          >
            {s.futofenyKikapcsolva ? '▶ Futófény bekapcsolása' : '⏹ Futófény kikapcsolása'}
          </button>
          {s.futofenyKikapcsolva && (
            <span className="ml-2 text-xs text-red-600">
              {i18n.t('literals.futofeny-kikapcsolva')}
            </span>
          )}
        </div>
      </div>

      {/* FR-08, FR-09, FR-10, FR-12: Eszközök és fizetés */}
      <div className="form-panel space-y-3">
        <h2 className="section-title">{i18n.t('literals.eszkozok-es-fizetes')}</h2>
        {radioGroup<PrinterPort>(
          'printerPort',
          'Nyomtató típusa',
          s.printerPort,
          [
            { v: 'LPT1', label: 'LPT1 portra csatlakoztatva' },
            { v: 'USB', label: 'USB portra csatlakoztatva' },
          ],
          (v) => set('printerPort', v),
        )}
        {/* SP500 blokknyomtató: Windows-nyomtató és/vagy soros COM-port kiválasztása.
            Elég az egyik; nyomtatáskor a soros út fut először, utána a Windows-driveres. */}
        <div>
          <label className="form-label" htmlFor="printerDeviceName">
            {i18n.t('literals.windows-nyomtato-blokknyomtato')}
          </label>
          {window.electronAPI ? (
            <select
              id="printerDeviceName"
              className="form-input w-full"
              value={s.printerDeviceName}
              onChange={(e) => set('printerDeviceName', e.target.value)}
            >
              <option value="">{i18n.t('literals.nincs-kivalasztva')}</option>
              {[
                ...new Set([
                  ...printers.map((p) => p.name),
                  ...(s.printerDeviceName ? [s.printerDeviceName] : []),
                ]),
              ].map((name) => (
                <option key={name} value={name}>
                  {name}
                </option>
              ))}
            </select>
          ) : (
            <div className="text-xs text-muted-foreground">
              {i18n.t('literals.a-nyomtatovalasztas-csak-a-telepitett-el')}
            </div>
          )}
        </div>
        <div>
          <label className="form-label" htmlFor="printerSerialPort">
            {i18n.t('literals.soros-port-com-star-sp500-blokknyomtato')}
          </label>
          {window.electronAPI ? (
            <select
              id="printerSerialPort"
              className="form-input w-full"
              value={s.printerSerialPort}
              onChange={(e) => set('printerSerialPort', e.target.value)}
            >
              <option value="">{i18n.t('literals.nincs-kivalasztva')}</option>
              {[
                ...new Set([
                  ...serialPorts.map((p) => p.path),
                  ...(s.printerSerialPort ? [s.printerSerialPort] : []),
                ]),
              ].map((path) => {
                const port = serialPorts.find((p) => p.path === path)
                return (
                  <option key={path} value={path}>
                    {port?.friendlyName ? `${path} — ${port.friendlyName}` : path}
                  </option>
                )
              })}
            </select>
          ) : (
            <div className="text-xs text-muted-foreground">
              {i18n.t('literals.a-soros-port-valasztas-csak-a-telepitett')}
            </div>
          )}
        </div>
        <div>
          <label className="form-label" htmlFor="scanner">
            {i18n.t('literals.szkenner-driver')}
          </label>
          <input
            id="scanner"
            className="form-input w-full"
            placeholder="pl. WIA-CanoScan Lide 120"
            value={s.scannerDriver}
            onChange={(e) => set('scannerDriver', e.target.value)}
          />
        </div>
        {radioGroup<HandlingFeeMode>(
          'handlingFee',
          'Kezelési költség',
          s.handlingFeeMode,
          [
            { v: 'NINCS', label: 'Nincs' },
            { v: 'EZRELEKES', label: 'Ezrelékes' },
            { v: 'SAVOS', label: 'Sávos' },
          ],
          (v) => set('handlingFeeMode', v),
        )}
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={s.cardPaymentEnabled}
            onChange={(e) => set('cardPaymentEnabled', e.target.checked)}
          />
          {i18n.t('literals.bankkartyas-fizetes-engedelyezve')}
        </label>
      </div>

      {/* Akciógombok */}
      <div className="flex gap-2">
        <button
          onClick={() => void handleSave()}
          className="form-button-primary flex items-center gap-1"
        >
          <Save size={16} />
          {i18n.t('literals.rogzites-es-kilepes')}
        </button>
        <button onClick={() => navigate(-1)} className="form-button flex items-center gap-1">
          <X size={16} />
          {i18n.t('literals.kilepes-modositas-nelkul')}
        </button>
      </div>

      {/* FR-06: Jelszó-módosítás inline modal */}
      {showPasswordModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-background rounded-lg shadow-lg p-6 space-y-4 w-full max-w-sm">
            <h3 className="font-semibold flex items-center gap-2">
              <Lock size={16} />
              {i18n.t('literals.napi-jelentes-jelszo-modositasa')}
            </h3>
            <div className="space-y-2">
              <label className="form-label" htmlFor="newPwd">
                {i18n.t('literals.uj-jelszo')}
              </label>
              <input
                id="newPwd"
                type="password"
                className="form-input w-full"
                value={newPassword}
                autoComplete="new-password"
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="Legalább 4 karakter"
              />
            </div>
            <div className="space-y-2">
              <label className="form-label" htmlFor="confirmPwd">
                {i18n.t('literals.jelszo-megerositese')}
              </label>
              <input
                id="confirmPwd"
                type="password"
                className="form-input w-full"
                value={confirmPassword}
                autoComplete="new-password"
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Ismételd meg az új jelszót"
              />
            </div>
            <div className="flex gap-2 justify-end">
              <button
                type="button"
                className="form-button text-sm"
                onClick={() => {
                  setShowPasswordModal(false)
                  setNewPassword('')
                  setConfirmPassword('')
                }}
              >
                {i18n.t('literals.megse')}
              </button>
              <button
                type="button"
                className="form-button-primary text-sm"
                onClick={handlePasswordSave}
              >
                {i18n.t('literals.beallitas')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
