import { createHash, randomUUID } from 'node:crypto'
import type { BuildRatePackageInput, DecimalLike, LocalRateEntry, LocalRatePackage } from './types.js'

function decimalToString(value: DecimalLike | null | undefined): string | null {
  if (value === null || value === undefined || value === '') return null
  const text = String(value).trim().replace(',', '.')
  if (!/^-?\d+(\.\d+)?$/.test(text)) {
    throw new Error(`Ervenytelen szamformatum: ${value}`)
  }
  return text
}

function positiveDecimal(value: DecimalLike, field: string): string {
  const text = decimalToString(value)
  if (text === null) throw new Error(`${field} kotelezo`)
  if (Number(text) <= 0) throw new Error(`${field} pozitiv kell legyen`)
  return text
}

function normalizeRate(rate: LocalRateEntry): LocalRateEntry {
  const buyRate = positiveDecimal(rate.buyRate, 'buyRate')
  const sellRate = positiveDecimal(rate.sellRate, 'sellRate')
  if (Number(sellRate) <= Number(buyRate)) {
    throw new Error(`Eladasi arfolyam nagyobb kell legyen a vetelinal: currencyId=${rate.currencyId}`)
  }

  return {
    currencyId: rate.currencyId,
    buyRate,
    sellRate,
    officialRate: decimalToString(rate.officialRate),
    limit1Amount: decimalToString(rate.limit1Amount),
    limit1BuyRate: decimalToString(rate.limit1BuyRate),
    limit1SellRate: decimalToString(rate.limit1SellRate),
    limit2Amount: decimalToString(rate.limit2Amount),
    limit2BuyRate: decimalToString(rate.limit2BuyRate),
    limit2SellRate: decimalToString(rate.limit2SellRate),
    limit3Amount: decimalToString(rate.limit3Amount),
    limit3BuyRate: decimalToString(rate.limit3BuyRate),
    limit3SellRate: decimalToString(rate.limit3SellRate),
  }
}

function hashPackage(packageWithoutHash: Omit<LocalRatePackage, 'clientPackageHash'>): string {
  return createHash('sha256')
    .update(JSON.stringify(packageWithoutHash), 'utf8')
    .digest('hex')
}

export function buildRatePackage(input: BuildRatePackageInput): LocalRatePackage {
  if (!input.groupId) throw new Error('groupId kotelezo')
  if (!input.clientDeviceId) throw new Error('clientDeviceId kotelezo')
  if (!input.clientVersion) throw new Error('clientVersion kotelezo')
  if (!Array.isArray(input.rates) || input.rates.length === 0) {
    throw new Error('Legalabb egy arfolyam bejegyzes szukseges')
  }

  const packageWithoutHash: Omit<LocalRatePackage, 'clientPackageHash'> = {
    clientPackageId: randomUUID(),
    clientDeviceId: input.clientDeviceId.trim(),
    clientVersion: input.clientVersion.trim(),
    createdAt: new Date().toISOString(),
    groupId: input.groupId,
    operatorNote: input.operatorNote?.trim() || undefined,
    rates: input.rates.map(normalizeRate),
  }

  return {
    ...packageWithoutHash,
    clientPackageHash: hashPackage(packageWithoutHash),
  }
}
