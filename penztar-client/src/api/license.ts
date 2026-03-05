import apiClient from './client';
import type { LicenseData, LicenseStatusData } from '@/types';

/**
 * Licenc kezelés API
 */

/** Licenc státusz lekérdezés */
export async function getLicenseStatus(): Promise<LicenseStatusData> {
  const { data } = await apiClient.get<LicenseStatusData>('/license/status');
  return data;
}

/** Aktuális licenc lekérdezés */
export async function getCurrentLicense(): Promise<LicenseData> {
  const { data } = await apiClient.get<LicenseData>('/license/current');
  return data;
}

/** Licenc aktiválás */
export async function activateLicense(licenseKey: string): Promise<LicenseData> {
  const { data } = await apiClient.post<LicenseData>('/license/activate', { licenseKey });
  return data;
}
