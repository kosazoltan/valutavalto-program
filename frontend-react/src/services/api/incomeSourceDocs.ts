import { api } from './client'

export interface IncomeProofRequiredDto { required: boolean; thresholdHuf: number }

export const incomeSourceDocApi = {
  checkRequired: async (hufAmount: number, customerId?: string, currencyCode?: string):
    Promise<IncomeProofRequiredDto> =>
    (await api.get<IncomeProofRequiredDto>('/income-source-docs/required',
      { params: { hufAmount, customerId, currencyCode } })).data,
  sendEmail: async (payload: { imageBase64: string; mimeType: string; transactionRef?: string;
    customerName?: string; hufAmount?: number }): Promise<{ sentTo: number }> =>
    (await api.post<{ sentTo: number }>('/income-source-docs/email', payload)).data,
}
