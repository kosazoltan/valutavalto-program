export type DecimalLike = string | number

export interface LocalRateEntry {
  currencyId: number
  buyRate: DecimalLike
  sellRate: DecimalLike
  officialRate?: DecimalLike | null
  limit1Amount?: DecimalLike | null
  limit1BuyRate?: DecimalLike | null
  limit1SellRate?: DecimalLike | null
  limit2Amount?: DecimalLike | null
  limit2BuyRate?: DecimalLike | null
  limit2SellRate?: DecimalLike | null
  limit3Amount?: DecimalLike | null
  limit3BuyRate?: DecimalLike | null
  limit3SellRate?: DecimalLike | null
}

export interface BuildRatePackageInput {
  groupId: string
  clientDeviceId: string
  clientVersion: string
  operatorNote?: string
  rates: LocalRateEntry[]
}

export interface LocalRatePackage {
  clientPackageId: string
  clientDeviceId: string
  clientVersion: string
  createdAt: string
  groupId: string
  clientPackageHash: string
  operatorNote?: string
  rates: LocalRateEntry[]
}

export interface LocalRateMakerBootstrap {
  generatedAt: string
  mode: 'LOCAL_RATE_MAKER'
  publishEndpoint: string
  idempotencyRequired: boolean
  overview: unknown
  workgroups: unknown[]
}

export interface LocalRatePublishResponse {
  publicationId: string
  workgroupId: string
  publishedAt: string
  acceptedRates: number
  affectedBranches: number
  status: 'ACCEPTED_AND_DISTRIBUTION_QUEUED'
  serverPackageHash: string
  branchCodes: string[]
}
