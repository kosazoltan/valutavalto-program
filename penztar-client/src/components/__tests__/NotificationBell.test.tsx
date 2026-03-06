import { describe, it, expect, vi } from 'vitest';

// Mock notifications API
vi.mock('@/api/notifications', () => ({
  getUnreadCount: vi.fn().mockResolvedValue(0),
  getUnreadNotifications: vi.fn().mockResolvedValue([]),
  markAsRead: vi.fn().mockResolvedValue(undefined),
  markAllAsRead: vi.fn().mockResolvedValue(undefined),
}));

describe('NotificationBell', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../NotificationBell');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../NotificationBell');
    expect(typeof mod.default).toBe('function');
  });
});
