import { useState } from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import { useTextReasonModal } from './TextReasonModal'

// Kiegészítő teszt a PR #1524 Cursor Bugbot MEDIUM találatára (átfedő kérések):
// második requestReason-hívásnál az első Promise nem maradhat örökre függőben —
// null-lal kell lezáródnia, a második kérésnek pedig hiánytalanul működnie kell.
// A RED-körben fagyasztott TextReasonModal.test.tsx változatlan; ez új eset.

function OverlapHarness() {
  const { modal, requestReason } = useTextReasonModal()
  const [first, setFirst] = useState('(függőben)')
  const [second, setSecond] = useState('(függőben)')
  return (
    <div>
      <button
        onClick={() => {
          void requestReason({ title: 'Első kérés' }).then((r) => setFirst(JSON.stringify(r)))
        }}
      >
        Első
      </button>
      <button
        onClick={() => {
          void requestReason({ title: 'Második kérés' }).then((r) => setSecond(JSON.stringify(r)))
        }}
      >
        Második
      </button>
      <div data-testid="first-result">{first}</div>
      <div data-testid="second-result">{second}</div>
      {modal}
    </div>
  )
}

describe('useTextReasonModal — átfedő kérések (Bugbot-fix)', () => {
  it('második requestReason az első Promise-t null-lal zárja, a második kérés hibátlanul lefut', async () => {
    const user = userEvent.setup()
    render(<OverlapHarness />)

    await user.click(screen.getByRole('button', { name: 'Első' }))
    expect(screen.getByRole('alertdialog')).toHaveAccessibleName('Első kérés')
    expect(screen.getByTestId('first-result')).toHaveTextContent(/^\(függőben\)$/)

    await user.click(screen.getByRole('button', { name: 'Második' }))
    // Az első kérés Promise-a null-lal záródott, nem maradt függőben
    await waitFor(() => expect(screen.getByTestId('first-result')).toHaveTextContent(/^null$/))
    expect(screen.getByRole('alertdialog')).toHaveAccessibleName('Második kérés')

    await user.type(screen.getByRole('textbox'), 'második indok')
    await user.click(screen.getByRole('button', { name: 'OK' }))
    await waitFor(() =>
      expect(screen.getByTestId('second-result')).toHaveTextContent('"második indok"'),
    )
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    // Az első eredmény nem íródott felül a második zárásakor
    expect(screen.getByTestId('first-result')).toHaveTextContent(/^null$/)
  })
})
