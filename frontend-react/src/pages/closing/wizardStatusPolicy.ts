/**
 * FK-065 FR-3: a zárási wizard státusz-alapú elágazásának EGYETLEN közös helye.
 * A ClosingWizardPage ebből dönt a beragadt munkamenet kezeléséről.
 *
 * Exhaustiveness-garancia két rétegben:
 *  - fordításidő: a switch default ága `never`-re szűkít — új backend státusz
 *    típushibát okoz, amíg ide explicit ág nem kerül;
 *  - futásidő: ismeretlen érték (pl. verzió-eltérés régi kliens / új backend közt)
 *    NEM esik át néma default ágon, hanem hibát dob — a hívó oldalon (page)
 *    try/catch + semleges üzenet kötelező.
 */

export const WIZARD_STATUS_VALUES = [
  'IN_PROGRESS',
  'COMPLETED',
  'FAILED',
  'CANCELLED',
  'EXPIRED',
] as const

export type WizardStatusValue = (typeof WIZARD_STATUS_VALUES)[number]

export type WizardResumeAction = 'resume' | 'restart-only' | 'none'

export function resolveWizardResumeAction(status: WizardStatusValue): WizardResumeAction {
  switch (status) {
    case 'IN_PROGRESS':
      return 'resume'
    case 'EXPIRED':
      // Lejárt munkamenet nem folytatható — csak új zárás indítható
      return 'restart-only'
    case 'COMPLETED':
    case 'CANCELLED':
    case 'FAILED':
      return 'none'
    default: {
      const unknownStatus: never = status
      throw new Error(`Ismeretlen zárási wizard státusz: ${String(unknownStatus)}`)
    }
  }
}
