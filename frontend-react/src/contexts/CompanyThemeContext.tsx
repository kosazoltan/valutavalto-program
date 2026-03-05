import { createContext, useContext, useEffect, useState, ReactNode } from 'react'

/**
 * Ceg szerinti szinezes.
 * Legacy: _homePenztarSzam < 151 -> Exclusive Best Change ZRT. (piros)
 *         _homePenztarSzam >= 181 -> Expressz Ekszerhaz Kft. (narancs)
 */

export type CompanyBrand = 'ebc' | 'eex'

interface CompanyTheme {
  brand: CompanyBrand
  name: string
  primary: string
  primaryDark: string
  primaryLight: string
  accent: string
}

const THEMES: Record<CompanyBrand, CompanyTheme> = {
  ebc: {
    brand: 'ebc',
    name: 'Exclusive Best Change ZRT.',
    primary: '#C62828',
    primaryDark: '#8E0000',
    primaryLight: '#FF5F52',
    accent: '#EF5350',
  },
  eex: {
    brand: 'eex',
    name: 'Expressz Ekszerhaz Kft.',
    primary: '#E65100',
    primaryDark: '#BF360C',
    primaryLight: '#FF6F00',
    accent: '#FF6F00',
  },
}

interface CompanyThemeContextType {
  theme: CompanyTheme
  setBrand: (brand: CompanyBrand) => void
}

const CompanyThemeContext = createContext<CompanyThemeContextType>({
  theme: THEMES.ebc,
  setBrand: () => {},
})

export function useCompanyTheme() {
  return useContext(CompanyThemeContext)
}

export function CompanyThemeProvider({ children }: { children: ReactNode }) {
  const [brand, setBrand] = useState<CompanyBrand>('ebc')

  useEffect(() => {
    // Penztar kodbol ceg meghatarozasa (login utan)
    const branchCode = localStorage.getItem('branchCode')
    if (branchCode) {
      const code = parseInt(branchCode, 10)
      setBrand(code >= 181 ? 'eex' : 'ebc')
    }
  }, [])

  useEffect(() => {
    const theme = THEMES[brand]
    const root = document.documentElement
    root.style.setProperty('--primary', theme.primary)
    root.style.setProperty('--primary-dark', theme.primaryDark)
    root.style.setProperty('--primary-light', theme.primaryLight)
    root.style.setProperty('--accent', theme.accent)
  }, [brand])

  return (
    <CompanyThemeContext.Provider value={{ theme: THEMES[brand], setBrand }}>
      {children}
    </CompanyThemeContext.Provider>
  )
}
