export interface VaultLabelBranch {
  code: string
  name: string
  isVault?: boolean
  regionCode?: string | null
}

export function buildVaultLabel(
  ownBranch: VaultLabelBranch | undefined,
  worker: { branchName?: string | null; branchCode?: string | null } | null | undefined,
): string {
  if (ownBranch) {
    return ownBranch.isVault && ownBranch.regionCode?.trim()
      ? `${ownBranch.regionCode.trim()}. ${ownBranch.name}`
      : `${ownBranch.code} - ${ownBranch.name}`
  }
  return worker?.branchName ?? worker?.branchCode ?? '—'
}

// Batch2-E: az értéktár cím/telefon fallback a lokális cached_cash_desks mirrorból
// (offline rögzített sorok előnézetéhez — azok strukturálisan nem hordoznak fejléc-adatot).
export async function loadOwnVaultContact(
  branchId: string | undefined,
): Promise<{ address?: string; phone?: string }> {
  try {
    const cachedDesks = await window.electronAPI?.getCachedCashDesks?.()
    const ownDesk = cachedDesks?.find((d) => d.id === branchId)
    if (ownDesk) {
      // A backend formatBranchAddress() formátumával egyezően: "Város, Cím, IRSZ".
      const parts = [ownDesk.city, ownDesk.address, ownDesk.zip_code]
        .map((p) => (p ?? '').trim())
        .filter((p) => p !== '')
      return {
        address: parts.length > 0 ? parts.join(', ') : undefined,
        phone: ownDesk.phone?.trim() || undefined,
      }
    }
  } catch {
    /* cache-hiány nem blokkolja a bizonylatot */
  }
  return {}
}
