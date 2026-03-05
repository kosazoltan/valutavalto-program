/**
 * Szankciós szűrés API — ENSZ/EU/OFAC terrorlista ellenőrzés.
 *
 * Jogszabályi kötelezettség: Pmt. 2017. évi LIII. tv.
 * Minden tranzakció előtt KÖTELEZŐ lefuttatni!
 */

import apiClient from './client';
import type {
  SanctionScreeningRequest,
  SanctionScreeningResult,
  SanctionStatusResponse,
} from '@/types';

/**
 * Ügyfél szűrés szankciós listákon — POST /api/v1/sanctions/screen
 */
export async function screenCustomer(
  request: SanctionScreeningRequest,
): Promise<SanctionScreeningResult> {
  const response = await apiClient.post<SanctionScreeningResult>(
    '/sanctions/screen',
    request,
  );
  return response.data;
}

/**
 * Szankciós lista státusz — GET /api/v1/sanctions/status
 */
export async function getSanctionStatus(): Promise<SanctionStatusResponse> {
  const response = await apiClient.get<SanctionStatusResponse>('/sanctions/status');
  return response.data;
}
