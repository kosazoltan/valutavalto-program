import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import NotificationPage from './NotificationPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  unreadCount: vi.fn(),
  markAsRead: vi.fn(),
  markAllAsRead: vi.fn(),
  send: vi.fn(),
  sendInApp: vi.fn(),
  broadcast: vi.fn(),
  toast: {
    success: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  notificationApi: {
    list: mocks.list,
    unreadCount: mocks.unreadCount,
    markAsRead: mocks.markAsRead,
    markAllAsRead: mocks.markAllAsRead,
    send: mocks.send,
    sendInApp: mocks.sendInApp,
    broadcast: mocks.broadcast,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('NotificationPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([])
    mocks.unreadCount.mockResolvedValue(0)
    mocks.markAsRead.mockResolvedValue(undefined)
    mocks.markAllAsRead.mockResolvedValue(undefined)
    mocks.send.mockResolvedValue({ id: 'notification-1' })
    mocks.sendInApp.mockResolvedValue({ id: 'notification-2' })
    mocks.broadcast.mockResolvedValue(undefined)
  })

  it('célzott értesítés küldésekor workerId payloadot küld a backendnek', async () => {
    const user = userEvent.setup()
    render(<NotificationPage />)

    await waitFor(() => expect(mocks.list).toHaveBeenCalled())
    await user.click(screen.getByRole('button', { name: /notifications.ujErtesites/i }))

    const textboxes = screen.getAllByRole('textbox')
    await user.type(textboxes[0]!, 'Teszt cím')
    await user.type(textboxes[1]!, 'Teszt üzenet')
    await user.type(textboxes[2]!, '12')
    await user.click(screen.getByRole('button', { name: /common.send/i }))

    await waitFor(() => {
      expect(mocks.send).toHaveBeenCalledWith({
        workerId: 12,
        title: 'Teszt cím',
        message: 'Teszt üzenet',
        type: 'INFO',
      })
    })
  })

  it('csak in-app küldési módban a canonical POST /notifications szerződést használja', async () => {
    const user = userEvent.setup()
    render(<NotificationPage />)

    await waitFor(() => expect(mocks.list).toHaveBeenCalled())
    await user.click(screen.getByRole('button', { name: /notifications.ujErtesites/i }))

    const textboxes = screen.getAllByRole('textbox')
    await user.type(textboxes[0]!, 'In-app cím')
    await user.type(textboxes[1]!, 'In-app üzenet')
    await user.type(textboxes[2]!, '12')
    await user.selectOptions(screen.getByTestId('notification-channel'), 'in-app')
    await user.click(screen.getByRole('button', { name: /common.send/i }))

    await waitFor(() => {
      expect(mocks.sendInApp).toHaveBeenCalledWith({
        userId: '12',
        title: 'In-app cím',
        message: 'In-app üzenet',
        type: 'INFO',
      })
      expect(mocks.send).not.toHaveBeenCalled()
    })
  })
})
