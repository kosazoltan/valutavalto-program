import { api } from './client'

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

  close: (id: string) =>
    api.post<DecadeReportDto>(`/decade-reports/${id}/close`),

  list: (branchId: string, year: number, page = 0, size = 36) =>
    api.get<{ content: DecadeReportDto[]; totalElements: number }>('/decade-reports', {
      params: { branchId, year, page, size }
    }),
}
