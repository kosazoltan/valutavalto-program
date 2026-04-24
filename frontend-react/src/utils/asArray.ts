/**
 * asArray - defensive unwrap a shared client.ts interceptor mar-unwrapped response-jaihoz.
 *
 * Sourcery PR #187 visszajelzes: a tobb helyen ismetelt `Array.isArray(data) ? data : []`
 * pattern-t kozponti helyen kezeljuk. Igy egyetlen helyen maradhat, ha a unwrap-logika
 * valtozik.
 *
 * @example
 *   const shipments = asArray<ShipmentRequest>(response.data)
 *
 * @param data - barmilyen tipusu response.data, potencialisan null/undefined/nem-array
 * @returns tiszta tipusolt tomb (ures ha nem array)
 */
export function asArray<T>(data: unknown): T[] {
    return Array.isArray(data) ? (data as T[]) : []
}
