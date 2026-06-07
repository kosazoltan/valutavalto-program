import { render, screen, waitFor, fireEvent, within } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import { WorkgroupTileListView } from './RateCreationPage'

// FK-02 §3: az árfolyamkészítő csempés kezelő felület karbantartó funkciói.
// A rateWorkgroupApi write-végpontjait mockoljuk; a tile-view ezeken keresztül ír.
const mocks = vi.hoisted(() => ({
  create: vi.fn(),
  update: vi.fn(),
  remove: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('../../services/api/index', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../../services/api/index')>()
  return {
    ...actual,
    rateWorkgroupApi: { ...actual.rateWorkgroupApi, create: mocks.create, update: mocks.update, remove: mocks.remove },
  }
})
vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))

const WG = (over: Record<string, unknown> = {}) => ({
  id: 'wg1', code: 'WG01', name: 'Budapest központ', legacyGroupNumber: 1, active: true,
  branches: [{ id: 'b1', code: 'BP1', name: 'Deák' }],
  limit1Boundary: 50000, limit2Boundary: 300000, limit3Boundary: 1000000,
  tileColor: 'sky', protectionEnabled: true, ...over,
})

function renderView(props: Record<string, unknown> = {}) {
  const onReload = vi.fn()
  const onSelect = vi.fn()
  render(
    <WorkgroupTileListView
      workgroups={[WG()] as never}
      canWrite={true}
      onSelect={onSelect}
      onBackToMain={() => {}}
      onReload={onReload}
      loading={false}
      error={null}
      {...props}
    />,
  )
  return { onReload, onSelect }
}

describe('WorkgroupTileListView (FK-02 karbantartás)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.create.mockResolvedValue(WG())
    mocks.update.mockResolvedValue(WG())
    mocks.remove.mockResolvedValue(undefined)
  })

  it('írásjoggal megjeleníti az „Új munkacsoport”, Szerk. és Törlés akciókat', () => {
    renderView()
    expect(screen.getByText('Új munkacsoport')).toBeInTheDocument()
    expect(screen.getByText('Szerk.')).toBeInTheDocument()
    expect(screen.getByText('Törlés')).toBeInTheDocument()
    // Interaktív védelem-checkbox (nem csak jelző).
    expect(screen.getByRole('checkbox', { name: /Árfolyamvédelem a\(z\) Budapest központ/ })).toBeChecked()
  })

  it('olvasójoggal NINCS karbantartó akció, csak read-only védelem-jelző', () => {
    renderView({ canWrite: false })
    expect(screen.queryByText('Új munkacsoport')).not.toBeInTheDocument()
    expect(screen.queryByText('Szerk.')).not.toBeInTheDocument()
    expect(screen.queryByRole('checkbox')).not.toBeInTheDocument()
  })

  it('„Új munkacsoport” → szerkesztő → Mentés a create API-t hívja, majd reload', async () => {
    const { onReload } = renderView()
    fireEvent.click(screen.getByText('Új munkacsoport'))
    const dialog = screen.getByText('Új munkacsoport', { selector: 'h3' }).closest('div') as HTMLElement
    const scope = within(dialog)
    fireEvent.change(scope.getByPlaceholderText('pl. Budapest központ'), { target: { value: 'Szeged' } })
    // FK02-E (FR-1, FR-2): nincs Kód mező; a sorszám üresen marad → a szerver osztja ki (a teljes
    // cég-scope alapján), így a payload legacyGroupNumber-e undefined.
    fireEvent.click(scope.getByText('Mentés'))
    await waitFor(() => expect(mocks.create).toHaveBeenCalledTimes(1))
    expect(mocks.create).toHaveBeenCalledWith(expect.objectContaining({ name: 'Szeged', legacyGroupNumber: undefined }))
    await waitFor(() => expect(onReload).toHaveBeenCalled())
  })

  it('Szerk. → átnevezés a meglévő kóddal/limitekkel hívja az update API-t', async () => {
    renderView()
    fireEvent.click(screen.getByText('Szerk.'))
    const dialog = screen.getByText('Munkacsoport átnevezése', { selector: 'h3' }).closest('div') as HTMLElement
    const scope = within(dialog)
    fireEvent.change(scope.getByPlaceholderText('pl. Budapest központ'), { target: { value: 'BP-átnevezve' } })
    fireEvent.click(scope.getByText('Mentés'))
    await waitFor(() => expect(mocks.update).toHaveBeenCalledWith('wg1', expect.objectContaining({
      name: 'BP-átnevezve', code: 'WG01', limit1Boundary: 50000,
    })))
  })

  it('Törlés → megerősítő dialógus után remove(id)', async () => {
    const { onReload } = renderView()
    fireEvent.click(screen.getByText('Törlés'))
    const dialog = screen.getByText('Munkacsoport törlése').closest('div') as HTMLElement
    fireEvent.click(within(dialog).getByText('Törlés'))
    await waitFor(() => expect(mocks.remove).toHaveBeenCalledWith('wg1'))
    await waitFor(() => expect(onReload).toHaveBeenCalled())
  })

  it('védelem-checkbox kikapcsolása update-et hív protectionEnabled:false-szal', async () => {
    renderView()
    fireEvent.click(screen.getByRole('checkbox', { name: /Árfolyamvédelem/ }))
    await waitFor(() => expect(mocks.update).toHaveBeenCalledWith('wg1', expect.objectContaining({ protectionEnabled: false })))
  })
})
