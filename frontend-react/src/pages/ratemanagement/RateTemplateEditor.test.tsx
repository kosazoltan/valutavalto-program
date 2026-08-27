import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RateTemplateEditor from './RateTemplateEditor'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
  apiDelete: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
    put: mocks.apiPut,
    delete: mocks.apiDelete,
  },
}))

describe('RateTemplateEditor backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/rate-management/workgroups') {
        return Promise.resolve({
          data: [
            {
              id: 'workgroup-1',
              name: 'Belvárosi csoport',
              code: 'BEL',
            },
          ],
        })
      }

      if (path === '/currencies') {
        return Promise.resolve({
          data: [
            {
              id: 1,
              code: 'EUR',
              name: 'Euró',
            },
          ],
        })
      }

      if (path === '/rate-management/templates') {
        return Promise.resolve({
          data: [
            {
              id: 'template-1',
              currencyId: 1,
              workgroupId: 'workgroup-1',
              baseBuyRate: '390.00',
              baseSellRate: '399.00',
              buySpread: '1.00',
              sellSpread: '1.00',
              officialRate: '394.00',
              limit1Amount: '100000',
              limit1BuyRate: '391.00',
              limit1SellRate: '400.00',
              limit2Amount: '500000',
              limit2BuyRate: '392.00',
              limit2SellRate: '401.00',
              limit3Amount: '1000000',
              limit3BuyRate: '393.00',
              limit3SellRate: '402.00',
              roundingRule: 5,
              status: 'DRAFT',
            },
          ],
        })
      }

      if (path === '/rate-management/templates/template-1') {
        return Promise.resolve({
          data: {
            id: 'template-1',
            currencyId: 1,
            workgroupId: 'workgroup-1',
            baseBuyRate: '391.50',
            baseSellRate: '401.50',
            buySpread: '1.50',
            sellSpread: '2.50',
            officialRate: '396.00',
            limit1Amount: '120000',
            limit1BuyRate: '392.00',
            limit1SellRate: '402.00',
            limit2Amount: '520000',
            limit2BuyRate: '393.00',
            limit2SellRate: '403.00',
            limit3Amount: '1020000',
            limit3BuyRate: '394.00',
            limit3SellRate: '404.00',
            roundingRule: 10,
            status: 'DRAFT',
          },
        })
      }

      return Promise.resolve({ data: [] })
    })
  })

  it('szerkesztéskor a /rate-management/templates/{id} részlet endpointból tölti az űrlapot', async () => {
    const user = userEvent.setup()
    render(<RateTemplateEditor />)

    await screen.findByText(/Vétel: 390\.00/)
    await user.click(screen.getByRole('button', { name: 'ratemanagement.szerkesztes' }))

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/rate-management/templates/template-1')
    })
    expect(await screen.findByDisplayValue('391.50')).toBeInTheDocument()
    expect(screen.getByDisplayValue('401.50')).toBeInTheDocument()
    expect(screen.getByDisplayValue('396.00')).toBeInTheDocument()
  })

  it('munkacsoport publikáláskor a batch /rate-management/publish szerződést hívja', async () => {
    const user = userEvent.setup()
    render(<RateTemplateEditor />)

    await screen.findByText(/Vétel: 390\.00/)
    await user.type(screen.getByLabelText('Publikálási megjegyzés'), 'Napi batch publikálás')
    await user.click(screen.getByTestId('rate-management-publish-batch'))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/rate-management/publish', {
        workgroupId: 'workgroup-1',
        templateIds: ['template-1'],
        notes: 'Napi batch publikálás',
      })
    })
  })
})
