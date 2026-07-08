import { describe, it, expect, vi } from 'vitest'
import { createInstallStateMachine } from './installStateMachine'
import { TOTAL_INSTALL_STEPS } from './installSteps'

/**
 * EBC Hangsegéd telepítő-állapot-gép egységtesztek.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md Fázis 9 acceptance.
 */
describe('InstallStateMachine', () => {
  it('alaphelyzetben az 1. lepesen all', () => {
    const sm = createInstallStateMachine()
    expect(sm.current()).toBe(1)
  })

  it('success=true eseten 1->2->3 lepest ad', () => {
    const sm = createInstallStateMachine()
    const s2 = sm.next(1, true)
    expect(s2.step_number).toBe(2)
    const s3 = sm.next(2, true)
    expect(s3.step_number).toBe(3)
  })

  it('success=false eseten ugyanazon a (belso) lepesen marad', () => {
    const sm = createInstallStateMachine()
    // belso allapot: 1. lepesen — a sikertelen jelzes is ott tart
    const s = sm.next(1, false)
    expect(s.step_number).toBe(1)
    expect(sm.current()).toBe(1)
  })

  it('Codex PR #666 P1: az LLM nem ugorhat at lepest (security)', () => {
    const sm = createInstallStateMachine()
    // belso allapot = 1, de az LLM hibasan 6-ot kuld
    const s = sm.next(6, true)
    // A leptetes a BELSO idx-en 1 lepes elore: 1 -> 2 (NEM 6 -> 7!)
    // Az LLM nem skip-elhet at lepeseket.
    expect(s.step_number).toBe(2)
    expect(sm.current()).toBe(2)
    expect(sm.isCompleted()).toBe(false)
  })

  it('Copilot PR #680 followup: NaN/Infinity currentStep sanitizalva (-1-re mappel)', () => {
    const sm = createInstallStateMachine()
    // dispatchToolCall a `Number("abc")`-bol NaN-t kaphat
    const s1 = sm.next(Number.NaN, true)
    expect(s1.step_number).toBe(2)
    expect(sm.current()).toBe(2)

    // Replay (megint NaN) - mindketto -1-re mappel a sanitization utan, igy idempotens
    const s2 = sm.next(Number.NaN, true)
    expect(s2.step_number).toBe(2)
    expect(sm.current()).toBe(2)

    // Infinity is sanitizalva
    const s3 = sm.next(Number.POSITIVE_INFINITY, true)
    expect(s3.step_number).toBe(2)
    expect(sm.current()).toBe(2)
  })

  it('Codex PR #680 P1: out-of-order delayed replay NEM ugorja at a lepest (Set-based gate)', () => {
    const sm = createInstallStateMachine()
    // Normalis flow: 1->2->3
    const s1 = sm.next(1, true)
    expect(s1.step_number).toBe(2)
    const s2 = sm.next(2, true)
    expect(s2.step_number).toBe(3)

    // DELAYED OUT-OF-ORDER replay (network glitch elobb erkezo elozo csomag):
    // next(1, true) erkezik a 2. lepes utan. Egy single-scalar tracker (lastApplied=2)
    // azt latna hogy 1!==2 es teves modon elorelepne 4-re. A Set-based gate elkapja.
    const s3 = sm.next(1, true)
    expect(s3.step_number).toBe(3)
    expect(sm.current()).toBe(3)
  })

  it('Copilot PR #680: success=false utani success=true legitim retry (NEM minosul replay-nek)', () => {
    const sm = createInstallStateMachine()
    // success=false eseten NEM kerul a Set-be (early return success-guard elott)
    const s1 = sm.next(1, false)
    expect(s1.step_number).toBe(1)
    expect(sm.current()).toBe(1)

    // Most a legitim retry success=true-val MEG halad
    const s2 = sm.next(1, true)
    expect(s2.step_number).toBe(2)
    expect(sm.current()).toBe(2)
  })

  it('Codex+Copilot PR #679 P1: stale current_step:0 (LLM coerced ?? 0) NEM trap-eli a folyamatot', () => {
    const sm = createInstallStateMachine()
    // dispatchToolCall a missing args.current_step-et Number(args.current_step ?? 0)-ra
    // coercolja. Ha az LLM kihagyja a current_step parametert, 0 erkezik.
    // FONTOS: NEM szabad bevarazsolni a folyamatot.
    const s1 = sm.next(0, true)
    expect(s1.step_number).toBe(2)
    expect(sm.current()).toBe(2)

    // A kovetkezo (normalis) hivas eloreviszi
    const s2 = sm.next(2, true)
    expect(s2.step_number).toBe(3)
    expect(sm.current()).toBe(3)
  })

  it('Codex+Copilot PR #679 P1 replay-idempotency: ismetelt next(SAME, true) NEM lep tobb mint egyet', () => {
    const sm = createInstallStateMachine()
    // 1. hivas (step 1, success=true): 1 -> 2
    const s1 = sm.next(1, true)
    expect(s1.step_number).toBe(2)
    expect(sm.current()).toBe(2)

    // 2. hivas (REPLAY ugyanazon currentStep ertekkel): NEM lephet 3-ra
    const s2 = sm.next(1, true)
    expect(s2.step_number).toBe(2)
    expect(sm.current()).toBe(2)

    // 3. hivas (replay megegyszer): NEM lephet 3-ra
    const s3 = sm.next(1, true)
    expect(s3.step_number).toBe(2)
    expect(sm.current()).toBe(2)

    // a kovetkezo helyes hivas (currentStep=2): 2 -> 3
    const s4 = sm.next(2, true)
    expect(s4.step_number).toBe(3)
    expect(sm.current()).toBe(3)
  })

  it('az utolso lepes utan completed', () => {
    const onCompleted = vi.fn()
    const sm = createInstallStateMachine(onCompleted)
    for (let i = 1; i <= TOTAL_INSTALL_STEPS; i++) {
      sm.next(i, true)
    }
    expect(sm.isCompleted()).toBe(true)
    expect(onCompleted).toHaveBeenCalledTimes(1)
  })

  it('Codex PR #666 P2: onCompleted CSAK EGYSZER fut le, replay nem duplazza', () => {
    const onCompleted = vi.fn()
    const sm = createInstallStateMachine(onCompleted)
    for (let i = 1; i <= TOTAL_INSTALL_STEPS; i++) {
      sm.next(i, true)
    }
    expect(onCompleted).toHaveBeenCalledTimes(1)
    // tovabbi replay-hivasok NEM tuzelnek
    sm.next(TOTAL_INSTALL_STEPS, true)
    sm.next(TOTAL_INSTALL_STEPS, true)
    expect(onCompleted).toHaveBeenCalledTimes(1)
  })

  it('reset visszaviszi az 1. lepesre', () => {
    const sm = createInstallStateMachine()
    sm.next(1, true)
    sm.next(2, true)
    sm.reset()
    expect(sm.current()).toBe(1)
    expect(sm.isCompleted()).toBe(false)
  })

  it('note-okat osszegyujt es a callback-nek atadja', () => {
    const onCompleted = vi.fn()
    const sm = createInstallStateMachine(onCompleted)
    sm.next(1, true, 'mikrofon engedelyezve')
    sm.next(2, true, 'nev: Heni')
    for (let i = 3; i <= TOTAL_INSTALL_STEPS; i++) {
      sm.next(i, true)
    }
    expect(onCompleted).toHaveBeenCalledWith(
      expect.arrayContaining(['mikrofon engedelyezve', 'nev: Heni']),
    )
  })
})
