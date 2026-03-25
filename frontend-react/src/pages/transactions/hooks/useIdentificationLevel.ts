import { useState, useEffect } from 'react'

export type IdentificationLevel = 'SIMPLE' | 'SIMPLIFIED' | 'FULL'

export function useIdentificationLevel(hufAmount: string) {
  const [identificationLevel, setIdentificationLevel] = useState<IdentificationLevel>('SIMPLE')
  const [requiresSourceVerification, setRequiresSourceVerification] = useState(false)

  useEffect(() => {
    const huf = parseFloat(hufAmount.replace(/\s/g, '').replace(',', '.')) || 0

    if (huf <= 100000) {
      setIdentificationLevel('SIMPLE')
    } else if (huf <= 300000) {
      setIdentificationLevel('SIMPLIFIED')
    } else {
      setIdentificationLevel('FULL')
    }

    setRequiresSourceVerification(huf >= 3500000)
  }, [hufAmount])

  return { identificationLevel, requiresSourceVerification }
}
