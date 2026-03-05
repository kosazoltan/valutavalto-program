import apiClient from './client';
import type {
  Reservation,
  CreateReservationRequest,
  RedeemReservationResponse,
  ReservationStatus,
} from '@/types';

export async function createReservation(
  request: CreateReservationRequest,
): Promise<Reservation> {
  const response = await apiClient.post<Reservation>(
    '/reservations',
    request,
  );
  return response.data;
}

export async function getReservations(
  status?: ReservationStatus,
  date?: string,
): Promise<Reservation[]> {
  const response = await apiClient.get<Reservation[]>('/reservations', {
    params: { status, date },
  });
  return response.data;
}

export async function redeemReservation(
  id: number,
): Promise<RedeemReservationResponse> {
  const response = await apiClient.post<RedeemReservationResponse>(
    `/reservations/${id}/redeem`,
  );
  return response.data;
}

export async function cancelReservation(
  id: number,
  reason: string,
): Promise<Reservation> {
  const response = await apiClient.post<Reservation>(
    `/reservations/${id}/cancel`,
    { reason },
  );
  return response.data;
}
