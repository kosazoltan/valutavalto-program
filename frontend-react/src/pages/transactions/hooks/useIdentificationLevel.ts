import { useState, useEffect, useCallback } from 'react'

export type IdentificationLevel = 'SIMPLE' | 'SIMPLIFIED' | 'FULL'

export function useIdentificationLevel(hufAmount: string) {
  const [minimumLevel, setMinimumLevel] = useState<IdentificationLevel>('SIMPLE')
  const [selectedLevel, setSelectedLevel] = useState<IdentificationLevel>('SIMPLE')
  const [requiresSourceVerification, setRequiresSourceVerification] = useState(false)

  useEffect(() => {
    const huf = parseFloat(hufAmount.replace(/\s/g, '').replace(',', '.')) || 0

    let minLevel: IdentificationLevel
    if (huf < 100_000) {
      minLevel = 'SIMPLE'
    } else if (huf < 300_000) {
      minLevel = 'SIMPLIFIED'
    } else {
      minLevel = 'FULL'
    }

    setMinimumLevel(minLevel)
    setSelectedLevel((prev) => {
      const levels: IdentificationLevel[] = ['SIMPLE', 'SIMPLIFIED', 'FULL']
      const minIdx = levels.indexOf(minLevel)
      const prevIdx = levels.indexOf(prev)
      return prevIdx < minIdx ? minLevel : prev
    })

    setRequiresSourceVerification(huf >= 3_500_000)
  }, [hufAmount])

  const setLevel = useCallback(
    (level: IdentificationLevel) => {
      const levels: IdentificationLevel[] = ['SIMPLE', 'SIMPLIFIED', 'FULL']
      const minIdx = levels.indexOf(minimumLevel)
      const reqIdx = levels.indexOf(level)
      if (reqIdx >= minIdx) {
        setSelectedLevel(level)
      }
    },
    [minimumLevel],
  )

  return {
    identificationLevel: selectedLevel,
    minimumLevel,
    setIdentificationLevel: setLevel,
    requiresSourceVerification,
  }
}
