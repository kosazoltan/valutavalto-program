// Gmail integráció — TypeScript típusok

export interface EmailSummary {
  id: string;
  subject: string;
  sender: string;
  snippet: string;
  receivedAt: string;
  isRead: boolean;
  hasAttachments: boolean;
}

export interface EmailAttachment {
  id: string;
  filename: string;
  mimeType: string;
  size: number;
}

export interface EmailDetail {
  id: string;
  threadId: string;
  subject: string;
  from: string;
  to: string[];
  cc: string[];
  body: string;
  htmlBody: string;
  receivedAt: string;
  isRead: boolean;
  hasAttachments: boolean;
  attachments: EmailAttachment[];
  labelIds: string[];
}

export interface EmailAccount {
  id: string;
  branchId?: string;
  vaultTerritoryId?: number;
  ownCompanyId?: string;
  workerId?: number;
  gmailAddress: string;
  displayName?: string;
  isActive: boolean;
}

export interface ComposeEmailDto {
  to: string;
  cc?: string;
  bcc?: string;
  subject: string;
  body: string;
}
