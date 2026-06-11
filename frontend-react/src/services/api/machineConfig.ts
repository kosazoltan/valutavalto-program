import { api } from './client'

/**
 * EXCMD b6-beallitasok FR-14 — gépenként izolált konfigurációs backend API.
 *
 * A workstationCode forrása: Electron-kliens esetén `electronAPI.getConfig("branch_code")`
 * (Setup Wizard által az SQLite config-ba írt branch kód, pl. BR039).
 * Web/dev módban fallback: localStorage["penztar-branch-code"] vagy "UNKNOWN".
 *
 * Fontos biztonsági elvek:
 * - A GET válasz NEM tartalmazza a jelszó hash-t — csak `dailyReportPasswordSet: boolean`.
 * - A PUT-ban küldött `dailyReportPassword` plain-text a server oldalon BCrypt-tel hash-elődik.
 * - A companyId mindig a szerver SecurityContext-ből jön, soha nem a kliens küldi.
 */

export interface MachineConfigGetResponse {
  /** A settings JSON string (PenztarSettings serialized). */
  config: string
  /** Van-e beállítva napi-jelentés jelszó (hash SOHA nem jön vissza). */
  dailyReportPasswordSet: boolean
  updatedAt: string | null
  updatedBy: string | null
}

export interface MachineConfigPutRequest {
  /** A teljes settings JSON string. */
  config: string
  /**
   * Ha megadva és nem üres: a szerver BCrypt-tel hash-eli és menti.
   * Ha nincs megadva vagy üres: a meglévő jelszó változatlan.
   */
  dailyReportPassword?: string
}

export interface MachineConfigPutResponse {
  workstationCode: string
  dailyReportPasswordSet: boolean
  updatedAt: string | null
}

export const machineConfigApi = {
  /**
   * Konfigurációs rekord lekérése a backendről.
   * Offline/hiba esetén null-t ad vissza (a hívó localStorage fallbackkel dolgozik).
   */
  get: async (workstationCode: string): Promise<MachineConfigGetResponse | null> => {
    try {
      const resp = await api.get<MachineConfigGetResponse>(`/machine-config/${workstationCode}`)
      return resp.data
    } catch {
      return null
    }
  },

  /**
   * Konfigurációs rekord mentése a backendbe (upsert).
   * Offline/hiba esetén silently fails (localStorage-ban megmarad az érték).
   */
  put: async (workstationCode: string, req: MachineConfigPutRequest): Promise<MachineConfigPutResponse | null> => {
    try {
      const resp = await api.put<MachineConfigPutResponse>(`/machine-config/${workstationCode}`, req)
      return resp.data
    } catch {
      return null
    }
  },
}

/**
 * A workstation kód meghatározása a klienskörnyezetből.
 *
 * Döntés indoklás (EXCMD b6 FR-14):
 * - Electron: `electronAPI.getConfig("branch_code")` — a Setup Wizard által
 *   az SQLite config-ba írt branch kód (pl. BR039). Ez az egyetlen hiteles forrás,
 *   mert a gép-specifikus azonosítása erre az értékre épül (sync, készlet, stb.).
 * - Web/dev mód: `localStorage["penztar-branch-code"]` fallback, végső fallback "UNKNOWN".
 *
 * Az IPC hívás async, de a preload.ts-ben a `getConfig` szinkron is elérhető
 * visszafelé kompatibilitásból — ipcRenderer.invoke-ra épülő promis-t használunk.
 */
export async function resolveWorkstationCode(): Promise<string> {
  if (typeof window !== 'undefined' && (window as unknown as { electronAPI?: { getConfig?: (k: string) => Promise<string | null> } }).electronAPI?.getConfig) {
    const electronAPI = (window as unknown as { electronAPI: { getConfig: (k: string) => Promise<string | null> } }).electronAPI
    try {
      const code = await electronAPI.getConfig('branch_code')
      if (code && code.trim()) return code.trim()
    } catch {
      // Electron IPC fallthrough
    }
  }
  // Web/dev fallback
  const stored = localStorage.getItem('penztar-branch-code')
  return (stored && stored.trim()) ? stored.trim() : 'UNKNOWN'
}
