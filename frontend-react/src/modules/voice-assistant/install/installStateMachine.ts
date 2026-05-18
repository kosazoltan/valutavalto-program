import { INSTALL_STEPS, TOTAL_INSTALL_STEPS, type InstallStep } from './installSteps'
import { logger } from '../../../utils/logger'

/**
 * EBC Hangsegéd telepítő-állapot-gép — Phase 7 ToolContext.nextInstallStep
 * default helyettesítése.
 *
 * Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §6.3
 *
 * Az `next(currentStep, success)` a Realtime API `next_install_step` tool
 * hívásakor lép előre / marad.
 *
 * Az `onCompleted` callback a 7. lépés után FUT LE EGYSZER
 * (Copilot+Codex PR #666: one-shot completion — retry/replay esetén NEM
 * tüzel újra a callback, hogy ne duplázzunk finalize-műveletet).
 *
 * A `next()` az LLM által megadott `currentStep`-et FIGYELMEZTETŐ csak —
 * a tényleges leptetés a BELSŐ `currentIdx`-en történik (Codex PR #666 P1
 * security: az LLM nem küldhet `current_step: 6` értéket, hogy átugorjon
 * a telepítés lépésein).
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
  let completedFired = false
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

      // Codex PR #666 P1: a leptetes a BELSO currentIdx-en, NEM az LLM altal
      // kuldott currentStep-en. Ha az LLM out-of-sync (pl. current_step: 6,
      // miközben a user meg az 1. lepesnel van), figyelmezteto log-ot ir,
      // de NEM ugor at lepest. A teljes lepessor mindenkeppen vegigfut.
      if (currentStep !== currentIdx) {
        logger.warn(
          'VoiceAssistant',
          `installStateMachine: LLM currentStep=${currentStep} !== internal=${currentIdx}, internal a kanonikus`
        )
      }

      if (!success) {
        return stepAt(currentIdx)
      }

      // Codex PR #676 P1 replay-idempotency fix:
      // Az LLM/tool-call retry-elhet (network glitch, partial response, stb.) es
      // ujra elkuldheti a SAME success=true hivast ugyanarra a step-re. Korabban
      // ez `currentIdx`-et ELOREVITTE minden hivasnal, amiKovetkezmenye:
      // 1. hivas (step 1, success=true) -> currentIdx=2; 2. hivas (step 1, success=true,
      // replay) -> currentIdx=3 — kihagytuk a 2. lepest. Most az `currentStep !==
      // currentIdx` esetet rejectaljuk: NEM lepunk, csak warn-olunk, igy a replay
      // nem mozdit allapotot.
      if (currentStep !== currentIdx) {
        // out-of-sync / replay — NE lepunk
        return stepAt(currentIdx)
      }

      if (currentIdx <= TOTAL_INSTALL_STEPS) {
        currentIdx = currentIdx + 1
      }

      if (currentIdx > TOTAL_INSTALL_STEPS) {
        // Copilot+Codex PR #666 P2: one-shot completion — retry-/replay-szafe
        if (onCompleted && !completedFired) {
          completedFired = true
          onCompleted([...collectedNotes])
        }
        return stepAt(TOTAL_INSTALL_STEPS)
      }
      return stepAt(currentIdx)
    },
    reset() {
      currentIdx = 1
      completedFired = false
      collectedNotes.length = 0
    },
    isCompleted() {
      return currentIdx > TOTAL_INSTALL_STEPS
    },
  }
}
