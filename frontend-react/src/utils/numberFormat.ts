/**
 * Számformázási utility függvények
 * Minden szám 1000-es elválasztóval, magyar formátumban, font-mono osztállyal
 */

/**
 * Egész szám formázása 1000-es elválasztóval (pl. 1234567 -> "1 234 567")
 */
export function formatInteger(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === '') {
    return '0'
  }
  
  const num = typeof value === 'string' ? parseFloat(value) : value
  if (isNaN(num)) {
    return '0'
  }
  
  return Math.floor(num).toLocaleString('hu-HU')
}

/**
 * Tizedes szám formázása 1000-es elválasztóval és tizedesjegyekkel
 * @param value - A formázandó érték
 * @param minDecimals - Minimális tizedesjegyek száma (alapértelmezett: 0)
 * @param maxDecimals - Maximális tizedesjegyek száma (alapértelmezett: 2)
 */
export function formatDecimal(
  value: number | string | null | undefined,
  minDecimals: number = 0,
  maxDecimals: number = 2
): string {
  if (value === null || value === undefined || value === '') {
    return '0'
  }
  
  const num = typeof value === 'string' ? parseFloat(value) : value
  if (isNaN(num)) {
    return '0'
  }
  
  return num.toLocaleString('hu-HU', {
    minimumFractionDigits: minDecimals,
    maximumFractionDigits: maxDecimals
  })
}

/**
 * Pénzösszeg formázása 1000-es elválasztóval és 2 tizedesjeggyel (pl. 1234.56 -> "1 234,56")
 */
export function formatCurrency(value: number | string | null | undefined): string {
  return formatDecimal(value, 2, 2)
}

/**
 * Szám megjelenítése span elemben font-mono osztállyal
 * Használat: <span className={getNumberClassName()}>{formatInteger(value)}</span>
 */
export function getNumberClassName(additionalClasses: string = ''): string {
  return `font-mono ${additionalClasses}`.trim()
}

