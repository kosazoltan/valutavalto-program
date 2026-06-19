import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TranslationSettingsPage from './TranslationSettingsPage'

const mocks = vi.hoisted(() => ({
  getLanguage: vi.fn(),
  getModule: vi.fn(),
  save: vi.fn(),
  importMany: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('../../services/api/translations', () => ({
  translationApi: {
    getLanguage: mocks.getLanguage,
    getModule: mocks.getModule,
    save: mocks.save,
    importMany: mocks.importMany,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

describe('TranslationSettingsPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getLanguage.mockResolvedValue({
      'common.save': 'Mentés',
      'common.cancel': 'Mégse',
    })
    mocks.getModule.mockResolvedValue({
      'settings.title': 'Beállítások',
    })
    mocks.save.mockResolvedValue({
      id: 1,
      languageCode: 'hu',
      module: 'UI',
      messageKey: 'common.save',
      messageValue: 'Mentés most',
    })
    mocks.importMany.mockResolvedValue({ imported: 1, languageCode: 'hu' })
  })

  it('nyelvi és modul fordításokat a backend szerződésből kér le', async () => {
    const user = userEvent.setup()
    render(<TranslationSettingsPage />)

    await user.click(screen.getByRole('button', { name: 'Nyelv' }))
    await waitFor(() => {
      expect(mocks.getLanguage).toHaveBeenCalledWith('hu')
    })
    expect(screen.getAllByText('common.cancel').length).toBeGreaterThan(0)

    await user.click(screen.getByRole('button', { name: 'Modul' }))
    await waitFor(() => {
      expect(mocks.getModule).toHaveBeenCalledWith('hu', 'UI')
    })
    expect(screen.getAllByText('settings.title').length).toBeGreaterThan(0)
  })

  it('egyedi fordítás mentése POST /translations szerződésre megy', async () => {
    const user = userEvent.setup()
    render(<TranslationSettingsPage />)

    await user.clear(screen.getByLabelText('Fordítás'))
    await user.type(screen.getByLabelText('Fordítás'), 'Mentés most')
    await user.click(screen.getByRole('button', { name: 'Fordítás mentése' }))

    await waitFor(() => {
      expect(mocks.save).toHaveBeenCalledWith({
        languageCode: 'hu',
        module: 'UI',
        messageKey: 'common.save',
        messageValue: 'Mentés most',
      })
    })
    expect(screen.getAllByText('Mentés most').length).toBeGreaterThan(0)
  })

  it('JSON import POST /translations/import szerződést hív', async () => {
    const user = userEvent.setup()
    render(<TranslationSettingsPage />)

    fireEvent.change(screen.getByLabelText('Fordítás JSON import'), {
      target: { value: '{"settings.title":"Beállítások"}' },
    })
    await user.click(screen.getByRole('button', { name: 'Import' }))

    await waitFor(() => {
      expect(mocks.importMany).toHaveBeenCalledWith('hu', { 'settings.title': 'Beállítások' })
    })
  })
})
