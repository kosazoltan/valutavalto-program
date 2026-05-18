import { INSTALL_STEPS, TOTAL_INSTALL_STEPS, type InstallStep } from './installSteps'

/**
 * EBC Hangsegéd telepítő-állapot-gép — Phase 7 ToolContext.nextInstallStep
 * default helyettesítése.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §6.3
 *
 * <p>Az `next(currentStep, success)` a Realtime API `next_install_step` tool
 * hívásakor lép előre / marad. Az `onCompleted` callback a 7. lépés után
 * fut le (Phase 9.5 Electron integráció esetén bezárja a Setup Wizard panelt).
 */

export interface InstallStateMachine {
  current(): number
  next(currentStep: number, success: boolean, note?: string): InstallStep
  reset(): void
  isCompleted(): boolean
}

export function createInstallStateMachine(
  onCompleted?: (notes: string[]) => void
): InstallStateMachine {
  let currentIdx = 1
  const collectedNotes: string[] = []

  function stepAt(idx: number): InstallStep {
    const clamped = Math.max(1, Math.min(idx, TOTAL_INSTALL_STEPS))
    return INSTALL_STEPS[clamped - 1] as InstallStep
  }

  return {
    current() {
      return currentIdx
    },
    next(currentStep, success, note) {
      if (note && note.trim()) collectedNotes.push(note.trim())
      if (!success) {
        return stepAt(currentStep)
      }
      const nextIdx = Math.min(currentStep + 1, TOTAL_INSTALL_STEPS + 1)
      currentIdx = nextIdx
      if (currentIdx > TOTAL_INSTALL_STEPS) {
        if (onCompleted) onCompleted([...collectedNotes])
        return stepAt(TOTAL_INSTALL_STEPS)
      }
      return stepAt(currentIdx)
    },
    reset() {
      currentIdx = 1
      collectedNotes.length = 0
    },
    isCompleted() {
      return currentIdx > TOTAL_INSTALL_STEPS
    },
  }
}
