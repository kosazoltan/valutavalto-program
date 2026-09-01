const subscribers = new Set<() => void>()

export function requestShiftStateRefresh(): void {
  for (const cb of subscribers) {
    try {
      cb()
    } catch (error) {
      // A subscriber throw must not block the rest of the fan-out.
      console.warn('suiteUpdateSignal subscriber failed', error)
    }
  }
}

export function subscribeShiftStateRefresh(cb: () => void): () => void {
  subscribers.add(cb)
  return () => {
    subscribers.delete(cb)
  }
}
