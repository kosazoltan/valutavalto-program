import apiClient from './client';
import type { PrintTemplateData, PrintTemplateCreateRequest } from '@/types';

/**
 * Nyomtatási sablonok API
 */

/** Sablonok lekérdezése típus szerint */
export async function getTemplates(type?: string): Promise<PrintTemplateData[]> {
  const params = type ? { type } : {};
  const { data } = await apiClient.get<PrintTemplateData[]>('/print-templates', { params });
  return data;
}

/** Sablon lekérdezés ID alapján */
export async function getTemplateById(id: string): Promise<PrintTemplateData> {
  const { data } = await apiClient.get<PrintTemplateData>(`/print-templates/${id}`);
  return data;
}

/** Új sablon létrehozás */
export async function createTemplate(req: PrintTemplateCreateRequest): Promise<PrintTemplateData> {
  const { data } = await apiClient.post<PrintTemplateData>('/print-templates', req);
  return data;
}

/** Sablon frissítés */
export async function updateTemplate(id: string, req: PrintTemplateCreateRequest): Promise<PrintTemplateData> {
  const { data } = await apiClient.put<PrintTemplateData>(`/print-templates/${id}`, req);
  return data;
}

/** Sablon előnézet */
export async function previewTemplate(
  id: string,
  templateData: Record<string, unknown>
): Promise<string> {
  const { data } = await apiClient.post<string>(`/print-templates/${id}/preview`, { data: templateData });
  return data;
}
