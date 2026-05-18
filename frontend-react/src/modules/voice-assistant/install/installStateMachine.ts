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
 * Az LLM által megadott `currentStep` SEM nem hitelesíti a leptetést,
 * SEM nem blokkolja: figyelmeztető log csak (Codex PR #666 P1 security —
 * az LLM nem küldhet `current_step: 6` értéket, hogy átugorjon lépéseket).
 *
 * Replay-idempotency (Codex+Copilot PR #679 P1 — corrected from #676):
 * - True replay (ugyanaz a tool-call ujra a SAME currentStep ertekkel
 *   success=true-val) → no-op, mert `lastAppliedCurrentStep` egyezik.
 * - LLM out-of-sync (pl. dispatchToolCall a missing `current_step`-et
 *   `?? 0`-ra coercolja) → tovabbra is leptetunk a BELSO idx-en,
 *   nem trap-elunk.
 * - Tradeoff: ha az LLM ugyanazt a hibás `currentStep` erteket sokszor
 *   kuldi sorban (pl. mindig 0), akkor a 2. hivastol no-op lesz → a
 *   user beragadhat. Ezert a tool-schema description-jenek kotelezo
 *   a current_step-et 1..7 koze megkotni (Realtime API parameter spec).
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
  // Codex+Copilot PR #679 P1 (corrected from #676): a true-replay marker
  // az LLM altal kuldott currentStep ertekkel asszocialodik, NEM a belso
  // idx-szel — igy az LLM `current_step ?? 0` coercolt 0-jat NEM trap-eljuk
  // be (csak igaz duplikatumokat).
  let lastAppliedCurrentStep: number | null = null
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
      // de NEM ugor at lepest, NEM trap-el be (Codex PR #679 P1).
      if (currentStep !== currentIdx) {
        logger.warn(
          'VoiceAssistant',
          `installStateMachine: LLM currentStep=${currentStep} !== internal=${currentIdx}, internal a kanonikus`
        )
      }

      if (!success) {
        return stepAt(currentIdx)
      }

      // Codex+Copilot PR #679 P1 replay-idempotency (corrected from #676):
      // Ha ugyanazzal a currentStep ertekkel masodszor jon success=true (network
      // glitch / LLM retry / partial response replay), NEM leptetunk megegyszer.
      // A gate az LLM altal kuldott `currentStep`-en alapul (NEM a belso idx-en),
      // hogy az out-of-sync stale `current_step: 0` ne trap-elje be a folyamatot.
      if (lastAppliedCurrentStep !== null && currentStep === lastAppliedCurrentStep) {
        return stepAt(currentIdx)
      }
      lastAppliedCurrentStep = currentStep

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
      lastAppliedCurrentStep = null
      collectedNotes.length = 0
    },
    isCompleted() {
      return currentIdx > TOTAL_INSTALL_STEPS
    },
  }
}
