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
 * Replay-idempotency (Codex+Copilot PR #680 P1 — corrected from #676 + #679):
 * - A {@code appliedCurrentSteps} **Set** tarolja az osszes `currentStep`
 *   erteket, amire mar applied success=true-t. Igy:
 *   - Consecutive replay (`next(1,true)` -> `next(1,true)`) → no-op.
 *   - Out-of-order delayed replay (`next(1,true), next(2,true), next(1,true)`)
 *     → 3. hivas `currentStep=1` MAR a Set-ben → no-op (NEM ugrik 3->4).
 *   - `success=false` ag NEM iratkozik fel a Set-be (`if (!success) return`
 *     elotte fut), igy retry pattern (`next(1,false)` aztan `next(1,true)`)
 *     legitim modon halad tovabb.
 *   - Stale `current_step: 0` (LLM coerce) → elso hivas 0 a Set-be,
 *     belso idx 1->2. Replay (0 ujra) → no-op. NEM trap.
 * - Tool-schema constraint (PR #680 Copilot finding): a Realtime API
 *   `next_install_step` tool sema-ja `current_step: integer, minimum 1,
 *   maximum {TOTAL_INSTALL_STEPS}` — lasd tools/toolDefinitions.ts.
 */

export interface InstallStateMachine {
  current(): number
  next(currentStep: number, success: boolean, note?: string): InstallStep
  reset(): void
  isCompleted(): boolean
}

export function createInstallStateMachine(
  onCompleted?: (notes: string[]) => void,
): InstallStateMachine {
  let currentIdx = 1
  let completedFired = false
  // Codex+Copilot PR #680 P1 (corrected from #676 + #679):
  // A Set tarolja az osszes mar successfully applied `currentStep` erteket,
  // hogy az out-of-order delayed replay-eket is elkapjuk (NEM csak a
  // consecutive duplikatumokat). Pelda:
  //   next(1,true) → applied={1}, idx 1->2
  //   next(2,true) → applied={1,2}, idx 2->3
  //   delayed next(1,true) → 1 IN applied → no-op (NEM ugrik 3->4)
  const appliedCurrentSteps = new Set<number>()
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

      // Copilot PR #680 followup: NaN/Infinity guard. A dispatchToolCall a
      // `Number(args.current_step ?? 0)`-bol NaN-t kaphat (pl. ha az LLM
      // string-et kuld `current_step: "abc"`), vagy Infinity-t. Mindketto
      // szennyezne a Set-et. Sanitizaljuk: a `current_step` invalid esetben
      // -1-re mappel (NEM 0 - hogy ne utkozzon az LLM-szerinti valid 0-val
      // a stale-coerce miatt).
      const sanitizedStep = Number.isFinite(currentStep) ? Math.trunc(currentStep) : -1

      // Codex PR #666 P1: a leptetes a BELSO currentIdx-en, NEM az LLM altal
      // kuldott currentStep-en. Ha az LLM out-of-sync (pl. current_step: 6,
      // miközben a user meg az 1. lepesnel van), figyelmezteto log-ot ir,
      // de NEM ugor at lepest, NEM trap-el be (Codex PR #679 P1).
      if (sanitizedStep !== currentIdx) {
        logger.warn(
          'VoiceAssistant',
          `installStateMachine: LLM currentStep=${currentStep} (sanitized=${sanitizedStep}) !== internal=${currentIdx}, internal a kanonikus`,
        )
      }

      if (!success) {
        return stepAt(currentIdx)
      }

      // Codex+Copilot PR #680 P1 replay-idempotency (Set-based, corrected
      // from #676 single-scalar + #679 consecutive-only):
      // Ha ezt a `sanitizedStep` erteket mar success=true-val applied
      // (akar koretkezo hivas, akar delayed out-of-order replay), no-op.
      // Megj: Set.has(NaN) === true a SameValueZero algoritmus miatt, de
      // a fenti `Number.isFinite` guard utan NaN -> -1, igy ez nem rontja a logikat.
      if (appliedCurrentSteps.has(sanitizedStep)) {
        return stepAt(currentIdx)
      }
      appliedCurrentSteps.add(sanitizedStep)

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
      appliedCurrentSteps.clear()
      collectedNotes.length = 0
    },
    isCompleted() {
      return currentIdx > TOTAL_INSTALL_STEPS
    },
  }
}
