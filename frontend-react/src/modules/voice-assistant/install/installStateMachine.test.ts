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

  it('success=false eseten ugyanazon a lepesen marad', () => {
    const sm = createInstallStateMachine()
    const s = sm.next(3, false)
    expect(s.step_number).toBe(3)
  })

  it('az utolso lepes utan completed', () => {
    const onCompleted = vi.fn()
    const sm = createInstallStateMachine(onCompleted)
    for (let i = 1; i <= TOTAL_INSTALL_STEPS; i++) {
      sm.next(i, true)
    }
    expect(sm.isCompleted()).toBe(true)
    expect(onCompleted).toHaveBeenCalled()
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
