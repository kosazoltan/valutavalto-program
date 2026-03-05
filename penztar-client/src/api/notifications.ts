import apiClient from './client';

export interface NotificationData {
  id: string;
  title: string;
  message: string;
  type: string;
  userId: string;
  isRead: boolean;
  createdAt: string;
}

export async function getNotifications(): Promise<NotificationData[]> {
  const { data } = await apiClient.get<NotificationData[]>('/notifications');
  return data;
}

export async function getUnreadNotifications(): Promise<NotificationData[]> {
  const { data } = await apiClient.get<NotificationData[]>('/notifications/unread');
  return data;
}

export async function getUnreadCount(): Promise<number> {
  const { data } = await apiClient.get<{ count: number }>('/notifications/unread-count');
  return data.count;
}

export async function markAsRead(id: string): Promise<void> {
  await apiClient.put(`/notifications/${id}/read`);
}

export async function markAllAsRead(): Promise<void> {
  await apiClient.post('/notifications/mark-all-read');
}

export async function sendNotification(workerId: number, title: string, message: string, type: string): Promise<NotificationData> {
  const { data } = await apiClient.post<NotificationData>('/notifications/send', {
    workerId, title, message, type,
  });
  return data;
}

export async function broadcastNotification(title: string, message: string): Promise<{ sent: number }> {
  const { data } = await apiClient.post<{ sent: number }>('/notifications/broadcast', {
    title, message, type: 'SYSTEM',
  });
  return data;
}
