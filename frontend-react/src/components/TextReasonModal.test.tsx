import { useState } from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
// FKH-027 PR A (RED): a modul még nem létezik — ez a teszt rögzíti a szerződést.
//  - default export TextReasonModal: kontrollált komponens,
//    props: { open: boolean; title: string; placeholder?: string;
//             onClose: (result: string | null) => void }
//  - named export useTextReasonModal(): { modal: ReactNode;
//    requestReason(opts: { title: string; placeholder?: string }): Promise<string | null> }
//  - az overlay elem kötelezően data-testid="text-reason-modal-overlay" azonosítót visel,
//    hogy a teszt ne kösse meg a belső DOM-szerkezetet
import TextReasonModal, { useTextReasonModal } from './TextReasonModal'

const TITLE = 'Elutasítás indoka'
const PLACEHOLDER = 'pl. hiányos kérelem'

async function renderOpen(onClose = vi.fn()) {
  render(<TextReasonModal open title={TITLE} placeholder={PLACEHOLDER} onClose={onClose} />)
  const input = screen.getByPlaceholderText(PLACEHOLDER)
  // Az autofókusz lehet aszinkron (vö. SupervisorPinModal setTimeout-os mintája)
  await waitFor(() => expect(input).toHaveFocus())
  return { onClose, input }
}

describe('TextReasonModal — közös szöveges-ok bekérő modal (FR-1–FR-6)', () => {
  it('FR-1: title és placeholder paraméterrel nyílik, a szövegmező autofókuszt kap', async () => {
    const { input } = await renderOpen()
    expect(screen.getByRole('alertdialog')).toHaveAccessibleName(TITLE)
    // Egysoros input a window.prompt-paritás miatt (nem textarea)
    expect((input as HTMLInputElement).type).toBe('text')
  })

  it('FR-1: open=false esetén semmit nem renderel', () => {
    render(<TextReasonModal open={false} title={TITLE} onClose={vi.fn()} />)
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
  })

  it('FR-2: Escape lenyomására onClose(null) hívódik, pontosan egyszer', async () => {
    const user = userEvent.setup()
    const { onClose } = await renderOpen()
    await user.keyboard('{Escape}')
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(onClose).toHaveBeenCalledWith(null)
  })

  it('FR-2: overlay-kattintásra onClose(null) hívódik', async () => {
    const user = userEvent.setup()
    const { onClose } = await renderOpen()
    await user.click(screen.getByTestId('text-reason-modal-overlay'))
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(onClose).toHaveBeenCalledWith(null)
  })

  it('FR-3: Mégse gombra onClose(null) hívódik', async () => {
    const user = userEvent.setup()
    const { onClose } = await renderOpen()
    await user.click(screen.getByRole('button', { name: 'Mégse' }))
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(onClose).toHaveBeenCalledWith(null)
  })

  it('FR-4: OK gombra a beírt értékkel hívódik az onClose', async () => {
    const user = userEvent.setup()
    const { onClose, input } = await renderOpen()
    await user.type(input, 'Hiányzó plomba a kazettán')
    await user.click(screen.getByRole('button', { name: 'OK' }))
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(onClose).toHaveBeenCalledWith('Hiányzó plomba a kazettán')
  })

  it('FR-4: Enter a mezőben ugyanúgy a beírt értékkel zár, pontosan egyszer', async () => {
    const user = userEvent.setup()
    const { onClose, input } = await renderOpen()
    await user.type(input, 'Hiányzó plomba a kazettán')
    await user.keyboard('{Enter}')
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(onClose).toHaveBeenCalledWith('Hiányzó plomba a kazettán')
  })

  it('FR-4: üres mezőnél az OK üres stringgel zár — az üres string érvényes érték', async () => {
    const user = userEvent.setup()
    const { onClose } = await renderOpen()
    await user.click(screen.getByRole('button', { name: 'OK' }))
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(onClose).toHaveBeenCalledWith('')
  })

  it('FR-5: Tab/Shift+Tab fókusz-csapda — a fókusz nem hagyja el a modált', async () => {
    const user = userEvent.setup()
    render(
      <div>
        <button>kívül eső gomb</button>
        <TextReasonModal open title={TITLE} placeholder={PLACEHOLDER} onClose={vi.fn()} />
      </div>,
    )
    const dialog = screen.getByRole('alertdialog')
    const input = screen.getByPlaceholderText(PLACEHOLDER)
    await waitFor(() => expect(input).toHaveFocus())
    const outside = screen.getByRole('button', { name: 'kívül eső gomb' })
    for (let i = 0; i < 6; i++) {
      await user.tab()
      expect(outside).not.toHaveFocus()
      expect(dialog.contains(document.activeElement)).toBe(true)
    }
    for (let i = 0; i < 6; i++) {
      await user.tab({ shift: true })
      expect(outside).not.toHaveFocus()
      expect(dialog.contains(document.activeElement)).toBe(true)
    }
  })

  it('FR-6: role="alertdialog", aria-modal="true", a title az akadálymentes név', async () => {
    await renderOpen()
    const dialog = screen.getByRole('alertdialog')
    expect(dialog).toHaveAttribute('aria-modal', 'true')
    expect(dialog).toHaveAccessibleName(TITLE)
  })
})

function PromiseHarness() {
  const { modal, requestReason } = useTextReasonModal()
  const [result, setResult] = useState('(nincs válasz)')
  return (
    <div>
      <button
        onClick={() => {
          void requestReason({ title: TITLE, placeholder: PLACEHOLDER }).then((r) =>
            setResult(JSON.stringify(r)),
          )
        }}
      >
        Bekérés
      </button>
      <div data-testid="promise-result">{result}</div>
      {modal}
    </div>
  )
}

describe('useTextReasonModal — Promise-szerződés (FR-2/FR-4)', () => {
  it('FR-2: megszakításkor (Escape) a Promise null-lal teljesül és a modal bezárul', async () => {
    const user = userEvent.setup()
    render(<PromiseHarness />)
    await user.click(screen.getByRole('button', { name: 'Bekérés' }))
    const input = await screen.findByPlaceholderText(PLACEHOLDER)
    await waitFor(() => expect(input).toHaveFocus())
    await user.keyboard('{Escape}')
    await waitFor(() => expect(screen.getByTestId('promise-result')).toHaveTextContent(/^null$/))
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
  })

  it('FR-4: OK-ra a Promise a beírt stringgel teljesül és a modal bezárul', async () => {
    const user = userEvent.setup()
    render(<PromiseHarness />)
    await user.click(screen.getByRole('button', { name: 'Bekérés' }))
    const input = await screen.findByPlaceholderText(PLACEHOLDER)
    await waitFor(() => expect(input).toHaveFocus())
    await user.type(input, 'kamera merevlemez hibás')
    await user.click(screen.getByRole('button', { name: 'OK' }))
    await waitFor(() =>
      expect(screen.getByTestId('promise-result')).toHaveTextContent('"kamera merevlemez hibás"'),
    )
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
  })
})
