/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["class"],
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // CSS variables from :root
        border: "hsl(var(--border))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        
        // PROFESSZIONÁLIS Pénzügyi Color Palette
        primary: {
          DEFAULT: "#1E3A8A", // Sötétkék (Trust & Authority)
          foreground: "#FFFFFF",
          50: "#EFF6FF",
          100: "#DBEAFE",
          200: "#BFDBFE",
          300: "#93C5FD",
          400: "#60A5FA",
          500: "#3B82F6",
          600: "#2563EB",
          700: "#1D4ED8",
          800: "#1E3A8A", // DEFAULT
          900: "#1E293B",
        },
        secondary: {
          DEFAULT: "#64748B", // Slate (Professional Gray)
          foreground: "#FFFFFF",
          50: "#F8FAFC",
          100: "#F1F5F9",
          200: "#E2E8F0",
          300: "#CBD5E1",
          400: "#94A3B8",
          500: "#64748B", // DEFAULT
          600: "#475569",
          700: "#334155",
          800: "#1E293B",
          900: "#0F172A",
        },
        accent: {
          DEFAULT: "#D97706", // Amber (Action & Highlight)
          foreground: "#FFFFFF",
          50: "#FFFBEB",
          100: "#FEF3C7",
          200: "#FDE68A",
          300: "#FCD34D",
          400: "#FBBF24",
          500: "#F59E0B",
          600: "#D97706", // DEFAULT
          700: "#B45309",
          800: "#92400E",
          900: "#78350F",
        },
        success: {
          DEFAULT: "#059669", // Emerald (Approved, Success)
          foreground: "#FFFFFF",
          50: "#ECFDF5",
          100: "#D1FAE5",
          200: "#A7F3D0",
          300: "#6EE7B7",
          400: "#34D399",
          500: "#10B981",
          600: "#059669", // DEFAULT
          700: "#047857",
          800: "#065F46",
          900: "#064E3B",
        },
        danger: {
          DEFAULT: "#DC2626", // Red (Error, Warning)
          foreground: "#FFFFFF",
          50: "#FEF2F2",
          100: "#FEE2E2",
          200: "#FECACA",
          300: "#FCA5A5",
          400: "#F87171",
          500: "#EF4444",
          600: "#DC2626", // DEFAULT
          700: "#B91C1C",
          800: "#991B1B",
          900: "#7F1D1D",
        },
        warning: {
          DEFAULT: "#F59E0B", // Amber (Caution)
          foreground: "#000000",
          50: "#FFFBEB",
          100: "#FEF3C7",
          200: "#FDE68A",
          300: "#FCD34D",
          400: "#FBBF24",
          500: "#F59E0B", // DEFAULT
          600: "#D97706",
          700: "#B45309",
          800: "#92400E",
          900: "#78350F",
        },
        info: {
          DEFAULT: "#0284C7", // Cyan (Informational)
          foreground: "#FFFFFF",
          50: "#ECFEFF",
          100: "#CFFAFE",
          200: "#A5F3FC",
          300: "#67E8F9",
          400: "#22D3EE",
          500: "#06B6D4",
          600: "#0284C7", // DEFAULT
          700: "#0369A1",
          800: "#075985",
          900: "#0C4A6E",
        },
        
        // UI Theme Colors
        form: {
          bg: "#F8FAFC", // Lighter gray
          bgDark: "#1E293B", // Dark mode
          border: "#CBD5E1", // Softer border
          borderDark: "#334155",
          header: "#1E3A8A", // Primary blue
          headerText: "#FFFFFF",
          panel: "#FFFFFF",
          panelDark: "#0F172A",
        },
        
        // Brand colors — CSS variable hivatkozasok a design-tokens.css-bol
        // (P2-3 design token rendszer, 2026-05-06). Additiv: a meglevo `primary`,
        // `success`, `danger`, `warning` palettak valtozatlanul mukodnek.
        brand: {
          'primary': 'var(--color-primary-500)',
          'primary-50': 'var(--color-primary-50)',
          'primary-500': 'var(--color-primary-500)',
          'primary-600': 'var(--color-primary-600)',
          'primary-700': 'var(--color-primary-700)',
          'primary-900': 'var(--color-primary-900)',
          'success': 'var(--color-success-500)',
          'success-500': 'var(--color-success-500)',
          'success-700': 'var(--color-success-700)',
          'warning': 'var(--color-warning-500)',
          'warning-500': 'var(--color-warning-500)',
          'warning-700': 'var(--color-warning-700)',
          'danger': 'var(--color-danger-500)',
          'danger-500': 'var(--color-danger-500)',
          'danger-700': 'var(--color-danger-700)',
          'neutral-50': 'var(--color-neutral-50)',
          'neutral-100': 'var(--color-neutral-100)',
          'neutral-200': 'var(--color-neutral-200)',
          'neutral-500': 'var(--color-neutral-500)',
          'neutral-700': 'var(--color-neutral-700)',
          'neutral-900': 'var(--color-neutral-900)',
        },

        // Currency Specific Colors
        currency: {
          huf: "#1E40AF", // HUF blue
          eur: "#059669", // EUR green
          usd: "#DC2626", // USD red
          gbp: "#7C3AED", // GBP purple
          chf: "#D97706", // CHF orange
          czk: "#0891B2", // CZK cyan
          pln: "#C026D3", // PLN magenta
          ron: "#65A30D", // RON lime
        },
      },
      fontFamily: {
        // Inter elsodleges (P2-3, 2026-05-06), fontsource async tolti
        // Segoe UI/Tahoma/Verdana fallback Windows + Linux + iOS rendszereken
        sans: ['Inter', 'ui-sans-serif', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Tahoma', 'Geneva', 'Verdana', 'Roboto', 'sans-serif'],
        mono: ['JetBrains Mono', 'Consolas', 'Monaco', 'Courier New', 'monospace'],
      },
      fontSize: {
        'xs': '11px',
        'sm': '12px',
        'base': '13px',
        'lg': '14px',
        'xl': '16px',
        '2xl': '18px',
        '3xl': '20px',
      },
      borderRadius: {
        'none': '0',
        'sm': '2px',
        DEFAULT: '3px',
        'md': '4px',
        'lg': '6px',
      },
      spacing: {
        '0.5': '2px',
        '1': '4px',
        '1.5': '6px',
        '2': '8px',
        '2.5': '10px',
        '3': '12px',
        '4': '16px',
        '5': '20px',
        '6': '24px',
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
}
