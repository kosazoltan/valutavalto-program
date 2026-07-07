import { api } from './client'

export interface IncomeProofRequiredDto { required: boolean; thresholdHuf: number }

export interface IncomeProofRecipientsResponse {
  recipients: string[]
}

export interface IncomeProofRecipientsUpdateResponse {
  recipients: string[]
  count: number
}

export const incomeSourceDocApi = {
  checkRequired: async (hufAmount: number, customerId?: string, currencyCode?: string):
    Promise<IncomeProofRequiredDto> =>
    (await api.get<IncomeProofRequiredDto>('/income-source-docs/required',
      { params: { hufAmount, customerId, currencyCode } })).data,
  sendEmail: async (payload: { imageBase64: string; mimeType: string; transactionRef?: string;
    customerName?: string; hufAmount?: number }): Promise<{ sentTo: number }> =>
    (await api.post<{ sentTo: number }>('/income-source-docs/email', payload)).data,
  getRecipients: async (): Promise<IncomeProofRecipientsResponse> =>
    (await api.get<IncomeProofRecipientsResponse>('/income-source-docs/recipients')).data,
  putRecipients: async (recipients: string[]): Promise<IncomeProofRecipientsUpdateResponse> =>
    (await api.put<IncomeProofRecipientsUpdateResponse>('/income-source-docs/recipients', { recipients })).data,
}
