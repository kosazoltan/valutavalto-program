const VOWELS = new Set(['A', 'E', 'I', 'O', 'U'])

function letterValue(ch: string): number {
  const upper = ch.toUpperCase()
  if (VOWELS.has(upper)) return 0
  if (upper >= 'A' && upper <= 'K') return 1
  if (upper >= 'L' && upper <= 'Z') return 2
  return 0
}

export function generateChallenge(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  const randomBytes = new Uint8Array(4)
  crypto.getRandomValues(randomBytes)
  let code = ''
  for (let i = 0; i < 4; i++) {
    code += chars[randomBytes[i]! % chars.length]
  }
  return code
}

export function computeResponse(challenge: string, date: Date = new Date()): number {
  if (challenge.length < 4) return 0
  const mid1 = letterValue(challenge[1]!)
  const mid2 = letterValue(challenge[2]!)
  const baseNumber = mid1 * 10 + mid2
  const doubled = baseNumber * 2
  const dayOfWeek = date.getDay() === 0 ? 7 : date.getDay()
  const dayOfMonth = date.getDate()
  return doubled + dayOfWeek + dayOfMonth
}

export function validateResponse(
  challenge: string,
  userResponse: number,
  date: Date = new Date(),
): boolean {
  return computeResponse(challenge, date) === userResponse
}
