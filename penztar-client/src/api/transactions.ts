import apiClient from './client';
import type { TransactionRequest, TransactionResponse } from '@/types';

// ============================================================
// Transaction API — igazítva a TransactionController-hez
// Frontend TransactionRequest → Backend BuyRequestDto / SellRequestDto mapping
// ============================================================

export async function sellCurrency(
  request: TransactionRequest,
): Promise<TransactionResponse> {
  const dto = {
    currencyId: request.currencyId,
    currencyAmount: request.currencyAmount,
    discountPercent: request.discountPercent ?? null,
    handlingFee: request.handlingFee ?? null,
    customerId: request.customerId?.toString() ?? null,
    customerName: request.customerName ?? null,
    customerAddress: request.customerAddress ?? null,
    customerDocumentNumber: request.customerDocumentNumber ?? null,
    customerNationality: request.customerNationality ?? null,
    notes: request.notes ?? null,
  };
  const { data } = await apiClient.post<TransactionResponse>(
    '/transactions/sell',
    dto,
  );
  return data;
}

export async function buyCurrency(
  request: TransactionRequest,
): Promise<TransactionResponse> {
  const dto = {
    currencyId: request.currencyId,
    currencyAmount: request.currencyAmount,
    discountPercent: request.discountPercent ?? null,
    handlingFee: request.handlingFee ?? null,
    customerId: request.customerId?.toString() ?? null,
    customerName: request.customerName ?? null,
    customerAddress: request.customerAddress ?? null,
    customerDocumentNumber: request.customerDocumentNumber ?? null,
    customerNationality: request.customerNationality ?? null,
    notes: request.notes ?? null,
  };
  const { data } = await apiClient.post<TransactionResponse>(
    '/transactions/buy',
    dto,
  );
  return data;
}

export async function reversalTransaction(
  originalTransactionId: number,
  reason: string,
  approvedBy?: string,
): Promise<TransactionResponse> {
  const dto = {
    originalTransactionId,
    reason,
    approvedBy: approvedBy ?? null,
  };
  const { data } = await apiClient.post<TransactionResponse>(
    '/transactions/reversal',
    dto,
  );
  return data;
}
