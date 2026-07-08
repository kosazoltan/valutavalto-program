import { api, type PagedResponse } from './client'

export interface DecadeReportLineDto {
  currencyCode: string
  currencyName: string
  buyCount: number
  buyAmount: number
  buyHuf: number
  sellCount: number
  sellAmount: number
  sellHuf: number
  openingStock: number
  closingStock: number
  mnbRate: number
  openingValueHuf: number
  closingValueHuf: number
}

export interface DecadeReportDto {
  id: string
  branchId: string
  year: number
  decade: number
  totalBuyHuf: number
  totalSellHuf: number
  totalHandlingFee: number
  transactionCount: number
  openingInventoryValueHuf: number
  closingInventoryValueHuf: number
  decadeProfitHuf: number
  lines: DecadeReportLineDto[]
  forintOpening: number
  forintTotalIncome: number
  forintTotalExpense: number
  forintClosing: number
  forintControlValid: boolean
  forintControlDiff: number
  firstReceiptNumber: string
  lastReceiptNumber: string
  cardPaymentTotal: number
  printControlFlag: boolean
  status: string
  closedAt: string | null
  closedBy: number | null
  createdAt: string
}

export interface GenerateDecadeDto {
  branchId: string
  year: number
  decade: number
}

export const decadeReportApi = {
  generate: (data: GenerateDecadeDto) =>
    api.post<DecadeReportDto>('/decade-reports/generate', data),

  close: (id: string) => api.post<DecadeReportDto>(`/decade-reports/${id}/close`),

  list: (branchId: string, year: number, page = 0, size = 36) =>
    // _preservePaged: a backend Page<DecadeReportDto>-t ad; e flag nélkül az axios
    // interceptor content-tömbbé bontaná → a DecadeReportPage `res.data.content`
    // undefined, a lista MINDIG üresnek látszana. Lásd client.ts unwrap (Page<T> → T[]).
    api.get<PagedResponse<DecadeReportDto>>('/decade-reports', {
      params: { branchId, year, page, size },
      _preservePaged: true,
    }),
}
