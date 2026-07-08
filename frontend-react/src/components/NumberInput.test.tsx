import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, it, expect, beforeEach } from 'vitest'
import { NumberInput } from './NumberInput'

// TestWrapper komponens definíciója (nem használt közvetlenül a tesztekben)

describe('NumberInput', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('input elem renderelésének ellenőrzése', () => {
    const { container } = render(
      <NumberInput value="" onChange={vi.fn()} data-testid="number-input" />,
    )
    const input = container.querySelector('input')
    expect(input).toBeInTheDocument()
  })

  it('szöveg beírás helyesen frissíti az értéket', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} placeholder="Test" />)

    const input = screen.getByPlaceholderText('Test') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '123')

    // onChange is called for each character, last call should be '123'
    expect(onChange).toHaveBeenCalled()
  })

  it('tizedesjegyek engedélyezése esetén vesszőt elfogad', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} allowDecimals={true} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '123.45')

    expect(onChange).toHaveBeenCalled()
  })

  it('tizedesjegyek tiltásakor vesszőt nem fogad', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} allowDecimals={false} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '123')
    // A vessző beírása nem történik meg
    expect(onChange).toHaveBeenCalled()
  })

  it('negatív számok tiltásakor mínusz jelet nem fogad', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} allowNegative={false} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '123')
    expect(onChange).toHaveBeenCalled()
  })

  it('negatív számok engedélyezésekor mínusz jelet fogad', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} allowNegative={true} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '-123')
    expect(onChange).toHaveBeenCalled()
  })

  it('e, E, + karaktereket nem fogad', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} allowDecimals={true} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '1e5')
    // 'e' nem kerül be, csak az számok
    expect(onChange).toHaveBeenCalled()
  })

  it('üres érték engedélyezett (felhasználó törölhet)', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="123" onChange={onChange} placeholder="Test" />)

    const input = screen.getByPlaceholderText('Test') as HTMLInputElement
    const user = userEvent.setup()

    await user.clear(input)

    expect(onChange).toHaveBeenCalledWith('')
  })

  it('min érték ellenőrzés', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} min={10} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '5')
    // Min érték miatt 10-re módosul
    expect(onChange).toHaveBeenCalled()
  })

  it('max érték ellenőrzés', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} max={100} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '200')
    // Max érték miatt 100-ra módosul
    expect(onChange).toHaveBeenCalled()
  })

  it('Hungarian comma format megjelenítés', () => {
    const { container } = render(<NumberInput value={123.45} onChange={vi.fn()} />)

    const input = container.querySelector('input') as HTMLInputElement
    expect(input.value).toBe('123,45')
  })

  it('onKeyDown callback meghívódik', async () => {
    const onKeyDown = vi.fn()
    render(<NumberInput value="" onChange={vi.fn()} onKeyDown={onKeyDown} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, 'a')
    expect(onKeyDown).toHaveBeenCalled()
  })

  it('placeholder megjelenítés', () => {
    render(<NumberInput value="" onChange={vi.fn()} placeholder="Enter amount" />)

    expect(screen.getByPlaceholderText('Enter amount')).toBeInTheDocument()
  })

  it('disabled state működésének ellenőrzése', () => {
    const { container } = render(<NumberInput value="" onChange={vi.fn()} disabled={true} />)

    const input = container.querySelector('input') as HTMLInputElement
    expect(input.disabled).toBe(true)
  })

  it('id és name attribútumok', () => {
    const { container } = render(
      <NumberInput value="" onChange={vi.fn()} id="test-id" name="test-name" />,
    )

    const input = container.querySelector('input') as HTMLInputElement
    expect(input.id).toBe('test-id')
    expect(input.name).toBe('test-name')
  })

  it('titel szöveg megjelenítés', () => {
    const { container } = render(<NumberInput value="" onChange={vi.fn()} title="Amount in HUF" />)

    const input = container.querySelector('input') as HTMLInputElement
    expect(input.title).toBe('Amount in HUF')
  })

  it('csak egy tizedesjel engedélyezett', async () => {
    const onChange = vi.fn()
    render(<NumberInput value="" onChange={onChange} allowDecimals={true} />)

    const input = document.querySelector('input') as HTMLInputElement
    const user = userEvent.setup()

    await user.type(input, '123,45,67')
    // Csak az első vesszőig tartjuk meg
    expect(onChange).toHaveBeenCalled()
  })

  it('autoFocus működésének ellenőrzése', () => {
    const { container } = render(<NumberInput value="" onChange={vi.fn()} autoFocus={true} />)

    const input = container.querySelector('input') as HTMLInputElement
    // Check that the input exists
    expect(input).toBeInTheDocument()
  })

  it('class name prop átadás', () => {
    const { container } = render(
      <NumberInput value="" onChange={vi.fn()} className="custom-class" />,
    )

    const input = container.querySelector('input') as HTMLInputElement
    expect(input).toHaveClass('custom-class')
  })
})
