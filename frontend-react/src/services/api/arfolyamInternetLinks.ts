import { api } from './index'

/** Árfolyamkészítő internet-link (legacy ARFOLYAM / TINTERNETTMKFORM). */
export interface ArfolyamInternetLink {
  id: string
  buttonNumber: number
  label: string
  url: string
}

export const arfolyamInternetLinkApi = {
  list: async (): Promise<ArfolyamInternetLink[]> => {
    const res = await api.get<ArfolyamInternetLink[]>('/arfolyam-internet-links')
    return res.data
  },
  create: async (
    buttonNumber: number,
    label: string,
    url: string,
  ): Promise<ArfolyamInternetLink> => {
    const res = await api.post<ArfolyamInternetLink>('/arfolyam-internet-links', {
      buttonNumber,
      label,
      url,
    })
    return res.data
  },
  remove: async (id: string): Promise<void> => {
    await api.delete(`/arfolyam-internet-links/${id}`)
  },
}
