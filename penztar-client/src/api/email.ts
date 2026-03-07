import apiClient from './client';
import type {
  EmailAccount,
  EmailSummary,
  EmailDetail,
  ComposeEmailDto,
} from '@/types/email';

// --- Fiókok ---

export async function getEmailAccounts(): Promise<EmailAccount[]> {
  const { data } = await apiClient.get<EmailAccount[]>('/email/accounts');
  return data;
}

export async function createEmailAccount(
  dto: Partial<EmailAccount>,
): Promise<EmailAccount> {
  const { data } = await apiClient.post<EmailAccount>('/email/accounts', dto);
  return data;
}

export async function updateEmailAccount(
  accountId: string,
  dto: Partial<EmailAccount>,
): Promise<EmailAccount> {
  const { data } = await apiClient.put<EmailAccount>(
    `/email/accounts/${accountId}`,
    dto,
  );
  return data;
}

export async function deleteEmailAccount(accountId: string): Promise<void> {
  await apiClient.delete(`/email/accounts/${accountId}`);
}

export async function startOAuthFlow(
  accountId: string,
): Promise<{ authUrl: string }> {
  const { data } = await apiClient.get<{ authUrl: string }>(
    `/email/accounts/${accountId}/auth`,
  );
  return data;
}

// --- Keresés ---

export async function searchMessages(
  query: string,
  accountId?: string,
): Promise<EmailSummary[]> {
  const params: Record<string, string> = { query };
  if (accountId) params.accountId = accountId;
  const { data } = await apiClient.get<EmailSummary[]>('/email/search', {
    params,
  });
  return data;
}

// --- Üzenetek ---

export async function getMessages(
  folder: string = 'INBOX',
  maxResults: number = 50,
  accountId?: string,
): Promise<{
  messages: EmailSummary[];
  nextPageToken?: string;
  source?: 'gmail' | 'cache';
}> {
  const { data } = await apiClient.get<{
    messages: EmailSummary[];
    nextPageToken?: string;
    source?: 'gmail' | 'cache';
  }>('/email/messages', { params: { folder, maxResults, accountId } });
  return data;
}

export async function getUnreadCount(): Promise<number> {
  const res = await apiClient.get<{ unreadCount: number }>('/email/unread-count');
  return res.data.unreadCount;
}

export async function getMessage(messageId: string): Promise<EmailDetail> {
  const { data } = await apiClient.get<EmailDetail>(
    `/email/messages/${messageId}`,
  );
  return data;
}

export async function sendMessage(dto: ComposeEmailDto): Promise<void> {
  await apiClient.post('/email/messages', dto);
}

export async function replyToMessage(
  messageId: string,
  body: string,
): Promise<void> {
  await apiClient.post(`/email/messages/${messageId}/reply`, { body });
}

export async function forwardMessage(
  messageId: string,
  to: string,
): Promise<void> {
  await apiClient.post(`/email/messages/${messageId}/forward`, { to });
}

export async function deleteMessage(messageId: string): Promise<void> {
  await apiClient.delete(`/email/messages/${messageId}`);
}

export async function markAsRead(messageId: string): Promise<void> {
  await apiClient.post(`/email/messages/${messageId}/read`);
}

export function getAttachmentUrl(
  messageId: string,
  attachmentId: string,
): string {
  const baseURL = apiClient.defaults.baseURL ?? '';
  return `${baseURL}/email/attachments/${messageId}/${attachmentId}`;
}
