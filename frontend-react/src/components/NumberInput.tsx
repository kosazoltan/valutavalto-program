import { ChangeEvent, KeyboardEvent, forwardRef } from 'react'

interface NumberInputProps {
  value: string | number
  onChange: (value: string) => void
  onKeyDown?: (e: KeyboardEvent<HTMLInputElement>) => void
  className?: string
  placeholder?: string
  min?: number
  max?: number
  step?: number | string
  allowDecimals?: boolean
  allowNegative?: boolean
  autoFocus?: boolean
  title?: string
  id?: string
  name?: string
  disabled?: boolean
}

/**
 * Csak számokat engedő bemeneti mező komponens
 * Nem enged beírni semmit, ami miatt a szám szöveggé válna
 */
export const NumberInput = forwardRef<HTMLInputElement, NumberInputProps>(
  (
    {
      value,
      onChange,
      onKeyDown,
      className = '',
      placeholder,
      min,
      max,
      step,
      allowDecimals = false,
      allowNegative = false,
      autoFocus,
      title,
      id,
      name,
      disabled
    },
    ref
  ) => {
    const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
      const inputValue = e.target.value

      // Üres string engedélyezése (a felhasználó törölhet)
      if (inputValue === '') {
        onChange('')
        return
      }

      // Csak számokat, tizedesvesszőt/vesszőt és mínuszt engedünk
      // Az 'e', 'E', '+' karaktereket eltávolítjuk
      let cleaned = inputValue
        .replace(/[^0-9,.\\-]/g, '') // Csak számok, tizedesvessző, mínusz
        .replace(/[eE+]/g, '') // Az 'e', 'E', '+' eltávolítása

      // Negatív számok kezelése
      if (!allowNegative) {
        cleaned = cleaned.replace(/-/g, '')
      } else {
        // Csak az elején lehet mínusz
        if (cleaned.includes('-')) {
          const minusIndex = cleaned.indexOf('-')
          if (minusIndex !== 0) {
            cleaned = cleaned.replace(/-/g, '')
            if (allowNegative && !cleaned.startsWith('-')) {
              cleaned = '-' + cleaned
            }
          }
        }
      }

      // Tizedesjegyek kezelése
      if (!allowDecimals) {
        // Tizedesvessző/vessző eltávolítása, ha nem engedélyezett
        cleaned = cleaned.replace(/[,.]/g, '')
      } else {
        // Csak egy tizedesvessző/vessző engedélyezése
        // Magyar formátum: vessző, angol: pont
        const hasComma = cleaned.includes(',')
        const hasDot = cleaned.includes('.')
        
        if (hasComma && hasDot) {
          // Ha mindkettő van, a vesszőt használjuk (magyar formátum)
          cleaned = cleaned.replace(/\./g, '')
        }
        
        // Tizedesvessző/vessző csak szám után lehet
        const parts = cleaned.split(/[,.]/)
        if (parts.length > 2) {
          // Több mint egy tizedesjel, csak az elsőt hagyjuk
          cleaned = parts[0] + (parts[1] !== undefined ? ',' + parts.slice(1).join('') : '')
        }
      }

      // Minimum és maximum ellenőrzés (csak ha már van érték)
      if (cleaned !== '' && cleaned !== '-') {
        const numValue = parseFloat(cleaned.replace(',', '.'))
        if (!isNaN(numValue)) {
          if (min !== undefined && numValue < min) {
            cleaned = min.toString()
          }
          if (max !== undefined && numValue > max) {
            cleaned = max.toString()
          }
        }
      }

      onChange(cleaned)
    }

    const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
      // Blokkoljuk az 'e', 'E', '+', '=' billentyűket
      if (e.key === 'e' || e.key === 'E' || e.key === '+' || e.key === '=') {
        e.preventDefault()
        return
      }

      // Ha nem engedélyezett a tizedes, akkor a tizedesvessző/vessző billentyűket is blokkoljuk
      if (!allowDecimals && (e.key === '.' || e.key === ',')) {
        e.preventDefault()
        return
      }

      // Ha nem engedélyezett a negatív, akkor a mínusz billentyűt is blokkoljuk
      if (!allowNegative && e.key === '-') {
        e.preventDefault()
        return
      }

      // Egyéb billentyű események átadása
      onKeyDown?.(e)
    }

    // Az érték megjelenítésekor tizedesvesszőt vesszőre cseréljük magyar formátumhoz
    const displayValue = typeof value === 'number' 
      ? value.toString().replace('.', ',')
      : value.toString()

    return (
      <input
        ref={ref}
        type="text"
        inputMode="decimal"
        value={displayValue}
        onChange={handleChange}
        onKeyDown={handleKeyDown}
        className={`font-mono ${className}`}
        placeholder={placeholder}
        autoFocus={autoFocus}
        title={title}
        id={id}
        name={name}
        disabled={disabled}
        min={min}
        max={max}
        step={step}
      />
    )
  }
)

NumberInput.displayName = 'NumberInput'

