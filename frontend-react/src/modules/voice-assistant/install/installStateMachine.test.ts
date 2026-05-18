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

  it('Codex PR #666 P1: az LLM out-of-sync currentStep NEM ugor at lepest', () => {
    const sm = createInstallStateMachine()
    // belso allapot = 1, de az LLM hibasan 6-ot kuld
    const s = sm.next(6, true)
    // Codex PR #676 P1 fix: az out-of-sync currentStep NEM lepteti az allapotot,
    // hogy a replay/retry ne ugorja at a kotelezo lepeseket.
    expect(s.step_number).toBe(1)
    expect(sm.current()).toBe(1)
    expect(sm.isCompleted()).toBe(false)
  })

  it('Codex PR #676 P1 replay-idempotency: ismetelt next(1,true) NEM lep tobb mint egyet', () => {
    const sm = createInstallStateMachine()
    // 1. hivas (step 1, success=true): 1 -> 2
    const s1 = sm.next(1, true)
    expect(s1.step_number).toBe(2)
    expect(sm.current()).toBe(2)

    // 2. hivas (REPLAY ugyanazokkal a parameterekkel): NEM lephet 3-ra
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
      expect.arrayContaining(['mikrofon engedelyezve', 'nev: Heni'])
    )
  })
})
