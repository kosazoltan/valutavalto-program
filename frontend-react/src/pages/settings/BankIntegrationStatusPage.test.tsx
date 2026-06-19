import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import BankIntegrationStatusPage from './BankIntegrationStatusPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPut: vi.fn(),
  apiPost: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('../../services/api/client', () => ({
  api: {
    get: mocks.apiGet,
    put: mocks.apiPut,
    post: mocks.apiPost,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

const statusResponse = {
  mnb: {
    rateCount: 23,
    lastFetchSuccess: true,
    lastFetchDate: '2026-06-18',
    schedulerActive: true,
  },
  raiffeisen: {
    schedulerActive: true,
    scheduledTime: '08:00 CET (munkanapokon)',
    enabled: true,
    mode: 'HTML_SCRAPING_FALLBACK',
    endpointConfigured: true,
    lastRunStatus: 'SUCCESS',
    lastRunTimestamp: '2026-06-18T08:00:00',
    lastRunMessage: 'OK',
  },
  darius: {
    currentMonth: '2026-06',
    periodStart: '2026-06-01',
    periodEnd: '2026-06-30',
    pendingReportsCount: 1,
    failedReportsCount: 0,
    submittedReportsCount: 18,
    lastSubmittedAt: '2026-06-18T10:00:00',
    transportMode: 'MANAGED_OUTBOX',
  },
  checkedAt: '2026-06-18T10:30:00',
}

const raiffeisenConfig = {
  id: 'config-1',
  providerName: 'RAIFFEISEN',
  mode: 'HTML_SCRAPING_FALLBACK',
  endpointUrl: 'https://raiffeisen.example/rates',
  authType: 'NONE',
  clientId: 'client-1',
  clientSecretConfigured: true,
  mtlsCertificateAlias: 'cert-1',
  updateFrequency: '0 0 8 * * MON-FRI',
  enabled: true,
  lastRunTimestamp: '2026-06-18T08:00:00',
  lastRunStatus: 'SUCCESS',
  lastRunMessage: 'OK',
  updatedAt: '2026-06-18T08:05:00',
}

describe('BankIntegrationStatusPage bank-api-config backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/admin/bank-integration/status') {
        return Promise.resolve({ data: statusResponse })
      }
      if (path === '/bank-api-config') {
        return Promise.resolve({ data: [raiffeisenConfig] })
      }
      if (path === '/bank-api-config/RAIFFEISEN') {
        return Promise.resolve({ data: raiffeisenConfig })
      }
      return Promise.resolve({ data: null })
    })
    mocks.apiPut.mockResolvedValue({
      data: {
        ...raiffeisenConfig,
        mode: 'REST_PRIMARY_WITH_HTML_FALLBACK',
        authType: 'OAUTH2_CLIENT_CREDENTIALS',
        endpointUrl: 'https://raiffeisen.example/rest',
        clientSecretConfigured: true,
      },
    })
    mocks.apiPost.mockResolvedValue({
      data: {
        savedRates: 12,
        config: {
          ...raiffeisenConfig,
          lastRunStatus: 'SUCCESS',
          lastRunMessage: 'Raiffeisen árfolyamok cache-elve: 12/12',
        },
      },
    })
  })

  it('betölti a státuszt, a bank-api-config listát és a Raiffeisen részletet', async () => {
    render(<BankIntegrationStatusPage />)

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/admin/bank-integration/status')
      expect(mocks.apiGet).toHaveBeenCalledWith('/bank-api-config')
      expect(mocks.apiGet).toHaveBeenCalledWith('/bank-api-config/RAIFFEISEN')
    })

    expect(await screen.findByText('Bank API konfiguráció')).toBeInTheDocument()
    expect(screen.getByDisplayValue('https://raiffeisen.example/rates')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Már beállítva')).toHaveValue('')
    expect(screen.getByText('Listaelemek')).toBeInTheDocument()
  })

  it('mentéskor a PUT /bank-api-config/RAIFFEISEN szerződést hívja secret kiírás nélkül', async () => {
    const user = userEvent.setup()
    render(<BankIntegrationStatusPage />)

    await screen.findByText('Bank API konfiguráció')
    await user.selectOptions(screen.getByLabelText('Mód'), 'REST_PRIMARY_WITH_HTML_FALLBACK')
    await user.selectOptions(screen.getByLabelText('Auth típus'), 'OAUTH2_CLIENT_CREDENTIALS')
    await user.clear(screen.getByLabelText('Endpoint URL'))
    await user.type(screen.getByLabelText('Endpoint URL'), 'https://raiffeisen.example/rest')
    await user.type(screen.getByLabelText('Client secret'), 'new-secret-value')
    await user.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => {
      expect(mocks.apiPut).toHaveBeenCalledWith('/bank-api-config/RAIFFEISEN', {
        mode: 'REST_PRIMARY_WITH_HTML_FALLBACK',
        endpointUrl: 'https://raiffeisen.example/rest',
        authType: 'OAUTH2_CLIENT_CREDENTIALS',
        clientId: 'client-1',
        clientSecret: 'new-secret-value',
        mtlsCertificateAlias: 'cert-1',
        updateFrequency: '0 0 8 * * MON-FRI',
        enabled: true,
      })
    })
    expect(screen.getByPlaceholderText('Már beállítva')).toHaveValue('')
  })

  it('kézi Raiffeisen fetch a POST /bank-api-config/raiffeisen/fetch-now endpointot hívja', async () => {
    const user = userEvent.setup()
    render(<BankIntegrationStatusPage />)

    await screen.findByText('Bank API konfiguráció')
    await user.click(screen.getByRole('button', { name: 'Raiffeisen kézi fetch' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/bank-api-config/raiffeisen/fetch-now')
      expect(mocks.toastSuccess).toHaveBeenCalledWith('Raiffeisen frissítés', '12 árfolyam mentve')
    })
  })
})
