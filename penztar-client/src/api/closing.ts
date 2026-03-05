import apiClient from './client';
import type { ClosingWizardState } from '@/types';

export async function startClosingWizard(): Promise<ClosingWizardState> {
  const response = await apiClient.post<ClosingWizardState>(
    '/closing-wizard/start',
  );
  return response.data;
}

export async function navigateClosingWizard(
  sessionId: string,
  step: number,
  data?: Record<string, unknown>,
): Promise<ClosingWizardState> {
  const response = await apiClient.post<ClosingWizardState>(
    '/closing-wizard/navigate',
    { sessionId, step, data },
  );
  return response.data;
}

export async function completeClosingWizard(
  sessionId: string,
): Promise<ClosingWizardState> {
  const response = await apiClient.post<ClosingWizardState>(
    '/closing-wizard/complete',
    { sessionId },
  );
  return response.data;
}
