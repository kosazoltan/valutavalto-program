import { api } from './client'

export type TranslationMap = Record<string, string>

export interface TranslationDto {
  id?: number
  languageCode: string
  messageKey: string
  messageValue: string
  module: string
}

export interface TranslationImportResult {
  imported: number
  languageCode: string
}

export const translationApi = {
  getLanguage: async (languageCode: string): Promise<TranslationMap> => {
    const response = await api.get<TranslationMap>(`/translations/${languageCode}`)
    return response.data
  },
  getModule: async (languageCode: string, module: string): Promise<TranslationMap> => {
    const response = await api.get<TranslationMap>(`/translations/${languageCode}/${module}`)
    return response.data
  },
  save: async (translation: TranslationDto): Promise<TranslationDto> => {
    const response = await api.post<TranslationDto>('/translations', {
      languageCode: translation.languageCode.trim(),
      messageKey: translation.messageKey.trim(),
      messageValue: translation.messageValue,
      module: translation.module.trim(),
    })
    return response.data
  },
  importMany: async (languageCode: string, translations: TranslationMap): Promise<TranslationImportResult> => {
    const response = await api.post<TranslationImportResult>('/translations/import', {
      languageCode: languageCode.trim(),
      translations,
    })
    return response.data
  },
}
