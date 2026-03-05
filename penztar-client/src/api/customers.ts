import apiClient from './client';
import type { Customer, CustomerSearchRequest } from '@/types';

export async function searchCustomers(
  request: CustomerSearchRequest,
): Promise<Customer[]> {
  const response = await apiClient.get<Customer[]>('/customers', {
    params: request,
  });
  return response.data;
}

export async function getCustomerById(id: number): Promise<Customer> {
  const response = await apiClient.get<Customer>(`/customers/${id}`);
  return response.data;
}

export async function createCustomer(
  customer: Omit<Customer, 'id'>,
): Promise<Customer> {
  const response = await apiClient.post<Customer>('/customers', customer);
  return response.data;
}
