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
        // RSL Valuta branding colors (Windows forms style)
        primary: {
          DEFAULT: "#0066CC",
          foreground: "#FFFFFF",
          50: "#E6F0FA",
          100: "#CCE0F5",
          200: "#99C2EB",
          300: "#66A3E0",
          400: "#3385D6",
          500: "#0066CC",
          600: "#0052A3",
          700: "#003D7A",
          800: "#002952",
          900: "#001429",
        },
        secondary: {
          DEFAULT: "#6C757D",
          foreground: "#FFFFFF",
        },
        success: {
          DEFAULT: "#28A745",
          foreground: "#FFFFFF",
        },
        danger: {
          DEFAULT: "#DC3545",
          foreground: "#FFFFFF",
        },
        warning: {
          DEFAULT: "#FFC107",
          foreground: "#000000",
        },
        info: {
          DEFAULT: "#17A2B8",
          foreground: "#FFFFFF",
        },
        // Windows forms style
        form: {
          bg: "#F0F0F0",
          border: "#ACACAC",
          header: "#003399",
          headerText: "#FFFFFF",
        },
        // Currency colors
        currency: {
          huf: "#1E40AF",
          eur: "#047857",
          usd: "#B91C1C",
          gbp: "#7C3AED",
          chf: "#C2410C",
        },
      },
      fontFamily: {
        sans: ['Segoe UI', 'Tahoma', 'Geneva', 'Verdana', 'sans-serif'],
        mono: ['Consolas', 'Monaco', 'Courier New', 'monospace'],
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
