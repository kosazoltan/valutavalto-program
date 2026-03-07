import apiClient from './client';

// ============================================================
// Closing Wizard API — igazítva a ClosingWizardController-hez
// ============================================================

export async function startClosingWizard(
  branchId: string,
  closingType: string,
  workerId: number,
  cashDeskId?: string,
) {
  const { data } = await apiClient.post('/closing-wizard/start', null, {
    params: { branchId, closingType, workerId, cashDeskId },
  });
  return data;
}

export async function navigateClosingWizard(wizardId: string, targetStep: number) {
  const { data } = await apiClient.post(`/closing-wizard/${wizardId}/navigate`, null, {
    params: { targetStep },
  });
  return data;
}

export async function completeClosingWizard(wizardId: string, workerId: number) {
  const { data } = await apiClient.post(`/closing-wizard/${wizardId}/complete`, null, {
    params: { workerId },
  });
  return data;
}

export async function cancelClosingWizard(wizardId: string) {
  const { data } = await apiClient.post(`/closing-wizard/${wizardId}/cancel`);
  return data;
}

export async function submitDenominations(
  wizardId: string,
  denominations: Record<string, Record<number, number>>,
) {
  const { data } = await apiClient.post(
    `/closing-wizard/${wizardId}/denominations`,
    denominations,
  );
  return data;
}

export async function submitDifferences(
  wizardId: string,
  differences: Record<string, number>,
) {
  const { data } = await apiClient.post(
    `/closing-wizard/${wizardId}/differences`,
    differences,
  );
  return data;
}

export async function finalizeClosingWizard(wizardId: string, workerId: number) {
  const { data } = await apiClient.post(`/closing-wizard/${wizardId}/finalize`, null, {
    params: { workerId },
  });
  return data;
}

export async function getWizard(wizardId: string) {
  const { data } = await apiClient.get(`/closing-wizard/${wizardId}`);
  return data;
}

export async function getWizardStep(wizardId: string, stepNumber: number) {
  const { data } = await apiClient.get(
    `/closing-wizard/${wizardId}/step/${stepNumber}`,
  );
  return data;
}

export async function getWizardReport(wizardId: string) {
  const { data } = await apiClient.get(`/closing-wizard/${wizardId}/report`);
  return data;
}

export async function validateTransactions(branchId: string) {
  const { data } = await apiClient.get(
    `/closing-wizard/validate-transactions/${branchId}`,
  );
  return data;
}
