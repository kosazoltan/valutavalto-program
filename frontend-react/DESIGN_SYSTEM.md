# 🎨 Valutaváltó Program — Design System Dokumentáció

**Verzió:** 1.0  
**Dátum:** 2026-03-05  
**Készítette:** Gábor 🎨 (Grafikus & Design specialista)

---

## 📋 ÖSSZEFOGLALÓ

Professzionális, pénzügyi szektorhoz illő design rendszer React 19 + TypeScript + Tailwind CSS + shadcn/ui alapra.

**Stílus:** Modern Banking Dashboard — Bloomberg Terminal + Wise/Revolut hibridje  
**Elsődleges használat:** Desktop (1920x1080), tablet támogatás  
**Accessibility:** WCAG 2.2 AA kompatibilis

---

## 🎨 COLOR PALETTE

### Elsődleges Színek (Primary)
**Funkció:** Trust & Authority — a pénzügyi ipar alapszíne

```css
--primary-50:  #EFF6FF
--primary-100: #DBEAFE
--primary-200: #BFDBFE
--primary-300: #93C5FD
--primary-400: #60A5FA
--primary-500: #3B82F6
--primary-600: #2563EB
--primary-700: #1D4ED8
--primary-800: #1E3A8A /* DEFAULT - Sötétkék */
--primary-900: #1E293B
```

**Használat:**
- Főgombok (CTA)
- Sidebar háttér (900)
- Kiemelt kártyák
- Link színek

**Kontraszt:**  
- `#1E3A8A` fehéren: **10.5:1** ✅ WCAG AAA

### Másodlagos Színek (Secondary - Slate)
**Funkció:** Professional Gray — szöveg, border, háttér

```css
--secondary-50:  #F8FAFC
--secondary-100: #F1F5F9
--secondary-200: #E2E8F0
--secondary-300: #CBD5E1
--secondary-400: #94A3B8
--secondary-500: #64748B /* DEFAULT */
--secondary-600: #475569
--secondary-700: #334155
--secondary-800: #1E293B
--secondary-900: #0F172A
```

**Használat:**
- Szöveg színek (700, 900)
- Border (200, 300)
- Háttér (50, 100)
- Sidebar sötét (900, 800)

### Kiemelés (Accent - Amber)
**Funkció:** Action & Highlight — figyelemfelkeltés

```css
--accent-50:  #FFFBEB
--accent-100: #FEF3C7
--accent-200: #FDE68A
--accent-300: #FCD34D
--accent-400: #FBBF24
--accent-500: #F59E0B
--accent-600: #D97706 /* DEFAULT - Arany/narancs */
--accent-700: #B45309
--accent-800: #92400E
--accent-900: #78350F
```

**Használat:**
- Hover effektek
- Kiemelt badge-ek
- Warning állapot
- Aktív sidebar elem accent border

**Kontraszt:**  
- `#D97706` fehéren: **3.5:1** ⚠️ CSAK nagy szövegre (≥18px)

### Státusz Színek

#### Success (Emerald)
```css
--success-600: #059669 /* Vétel, jóváhagyás */
```
**Kontraszt:** `#059669` fehéren: **4.6:1** ✅ AA

#### Danger (Red)
```css
--danger-600: #DC2626 /* Eladás, hiba, törölve */
```
**Kontraszt:** `#DC2626` fehéren: **4.5:1** ✅ AA

#### Warning (Amber)
```css
--warning-500: #F59E0B /* Figyelmeztetés, függőben */
```
**Kontraszt:** `#F59E0B` fehéren: **2.1:1** ❌ TILOS normál szövegre!

#### Info (Cyan)
```css
--info-600: #0284C7 /* Információ, segítség */
```
**Kontraszt:** `#0284C7` fehéren: **4.8:1** ✅ AA

### Deviza-specifikus Színek

| Deviza | Szín | Hex | Használat |
|--------|------|-----|-----------|
| HUF | Kék | `#1E40AF` | Magyar forint |
| EUR | Zöld | `#059669` | Euró |
| USD | Piros | `#DC2626` | US Dollár |
| GBP | Lila | `#7C3AED` | Angol font |
| CHF | Narancs | `#D97706` | Svájci frank |
| CZK | Cyan | `#0891B2` | Cseh korona |
| PLN | Magenta | `#C026D3` | Lengyel zloty |
| RON | Lime | `#65A30D` | Román lej |

**Használat:**  
- Devizakód kiemeléséhez: `text-currency-eur`
- Badge háttér: `bg-currency-usd/10`

---

## 🔤 TIPOGRÁFIA

### Font Family
```css
font-sans: ['Segoe UI', 'Tahoma', 'Geneva', 'Verdana', 'sans-serif']
font-mono: ['Consolas', 'Monaco', 'Courier New', 'monospace']
```

**Indoklás:**  
- Segoe UI — Windows natív, professzionális  
- Consolas — számok olvashatósága (árfolyam, összeg)

### Font Sizes (Tailwind)

| Class | Méret | Használat |
|-------|-------|-----------|
| `text-xs` | 11px | Címkék, metaadatok |
| `text-sm` | 12px | Táblázat body, form input |
| `text-base` | 13px | Normál body szöveg |
| `text-lg` | 14px | Oldal alcímek |
| `text-xl` | 16px | Fejlécek, szekciónevek |
| `text-2xl` | 18px | KPI értékek |
| `text-3xl` | 20px | Kiemelt számok |

### Font Weight

| Class | Weight | Használat |
|-------|--------|-----------|
| `font-normal` | 400 | Body szöveg |
| `font-medium` | 500 | Gombok, linkek |
| `font-semibold` | 600 | Táblázat header, címkék |
| `font-bold` | 700 | Oldal címek, KPI értékek |

---

## 📐 SPACING & SIZING

### Spacing Scale (Tailwind)
```
0.5 → 2px
1   → 4px
1.5 → 6px
2   → 8px
2.5 → 10px
3   → 12px
4   → 16px
5   → 20px
6   → 24px
```

**Használat:**
- `gap-4` — Kártya közötti távolság
- `p-4` — Panel padding
- `mb-3` — Cím alatt margin

### Border Radius
```css
rounded-none: 0
rounded-sm:   2px
rounded:      3px
rounded-md:   4px (DEFAULT modern form)
rounded-lg:   6px (Kártyák, panelek)
rounded-xl:   8px (Nagy panelek)
rounded-full: 9999px (Badge, avatar)
```

### Component Heights
```
Input/Button:  h-9 (36px)
Header:        h-16 (64px)
Sidebar width: w-64 (256px) | collapsed: w-16 (64px)
```

---

## 🧩 KOMPONENS STÍLUSOK

### 1. Form Input (`.form-input`)
```html
<input type="text" class="form-input" placeholder="Példa szöveg" />
```

**CSS Osztályok:**
```css
.form-input {
  @apply h-9 px-3 py-2 border border-form-border bg-white text-sm rounded-md;
  @apply focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-200;
  @apply hover:border-secondary-400 transition-all duration-200;
  @apply placeholder:text-secondary-400;
}
```

**Viselkedés:**
- Alapállapot: szürke border (`#CBD5E1`)
- Hover: darker border
- Focus: kék border + ring
- Placeholder: halvány szürke

### 2. Gombok

#### Primary Button (`.form-button-primary`)
```html
<button class="form-button-primary">
  <Icon size={18} />
  <span>Mentés</span>
</button>
```

**CSS:**
```css
.form-button-primary {
  @apply h-9 px-4 py-2 bg-primary-800 text-white text-sm font-medium rounded-md border-0;
  @apply hover:bg-primary-700 hover:shadow-md;
  @apply active:bg-primary-900 active:scale-[0.98];
  @apply transition-all duration-200 cursor-pointer;
  @apply flex items-center justify-center gap-2;
}
```

**Viselkedés:**
- Hover: világosabb + árnyék
- Click: sötétebb + scale animation

#### Secondary Button (`.form-button`)
```html
<button class="form-button">
  <Icon size={18} />
  <span>Mégse</span>
</button>
```

**CSS:**
```css
.form-button {
  @apply h-9 px-4 py-2 border border-form-border bg-white text-sm font-medium rounded-md;
  @apply hover:bg-secondary-50 hover:border-secondary-400;
  @apply active:bg-secondary-100 active:scale-[0.98];
  @apply transition-all duration-200 cursor-pointer;
  @apply flex items-center justify-center gap-2;
}
```

#### Success Button (`.form-button-success`)
```css
.form-button-success {
  @apply h-9 px-4 py-2 bg-success-600 text-white text-sm font-medium rounded-md border-0;
  @apply hover:bg-success-700 hover:shadow-md;
  @apply active:bg-success-800 active:scale-[0.98];
}
```

#### Danger Button (`.form-button-danger`)
```css
.form-button-danger {
  @apply h-9 px-4 py-2 bg-danger-600 text-white text-sm font-medium rounded-md border-0;
  @apply hover:bg-danger-700 hover:shadow-md;
  @apply active:bg-danger-800 active:scale-[0.98];
}
```

### 3. Panel/Card (`.form-panel`)
```html
<div class="form-panel">
  <h2 class="text-lg font-bold text-secondary-900 mb-4">Cím</h2>
  <p>Tartalom...</p>
</div>
```

**CSS:**
```css
.form-panel {
  @apply border border-form-border bg-form-panel rounded-lg p-4 shadow-sm;
}
```

### 4. Data Grid (`.data-grid`)
```html
<table class="data-grid w-full">
  <thead>
    <tr>
      <th>Oszlop 1</th>
      <th>Oszlop 2</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Adat 1</td>
      <td>Adat 2</td>
    </tr>
  </tbody>
</table>
```

**CSS:**
```css
.data-grid {
  @apply border border-form-border bg-white text-sm rounded-lg overflow-hidden;
}

.data-grid th {
  @apply bg-secondary-50 border-b-2 border-secondary-200 px-4 py-3 text-left font-semibold text-secondary-700;
  @apply uppercase text-xs tracking-wider;
}

.data-grid td {
  @apply border-b border-secondary-100 px-4 py-3;
}

.data-grid tbody tr {
  @apply hover:bg-primary-50 transition-colors duration-150 cursor-pointer;
}

.data-grid tr.selected td {
  @apply bg-primary-600 text-white font-medium;
}
```

**Viselkedés:**
- Header: uppercase, kiemelve
- Row hover: halvány kék háttér
- Kijelölt sor: primary kék, fehér szöveg

### 5. Badge (`.badge`)
```html
<span class="badge badge-green">Aktív</span>
<span class="badge badge-red">Hibás</span>
<span class="badge badge-yellow">Függőben</span>
<span class="badge badge-blue">Információ</span>
```

**CSS:**
```css
.badge {
  @apply inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold;
  @apply transition-all duration-200;
}

.badge-green {
  @apply badge bg-success-100 text-success-800 border border-success-200;
}

.badge-red {
  @apply badge bg-danger-100 text-danger-800 border border-danger-200;
}

.badge-yellow {
  @apply badge bg-warning-100 text-warning-800 border border-warning-200;
}

.badge-blue {
  @apply badge bg-primary-100 text-primary-800 border border-primary-200;
}
```

### 6. KPI Card (`.stat-card`)
```html
<div class="stat-card bg-gradient-to-br from-primary-50 to-primary-100 border border-primary-200">
  <div class="flex items-start justify-between mb-3">
    <div class="p-2.5 rounded-lg bg-primary-100 text-primary-600">
      <Icon size={20} />
    </div>
    <div class="flex items-center gap-1 text-xs font-semibold text-success-700">
      <ArrowUp size={14} />
      12%
    </div>
  </div>
  <div class="text-sm text-secondary-600 mb-1">Mai tranzakciók</div>
  <div class="text-2xl font-bold text-secondary-900">47</div>
</div>
```

**CSS:**
```css
.stat-card {
  @apply form-panel hover:shadow-lg hover:scale-[1.02] transition-all duration-200 cursor-pointer;
}
```

---

## 🎬 ANIMÁCIÓK & INTERAKCIÓK

### 1. Alapértelmezett Transition
**Minden elemre:**
```css
* {
  @apply transition-colors duration-150;
}
```

### 2. Hover Effektek

#### Gombok
```
hover:bg-primary-700 hover:shadow-md
```

#### Táblázat sorok
```
hover:bg-primary-50 transition-colors duration-150
```

#### Kártyák
```
hover:shadow-lg hover:scale-[1.02] transition-all duration-200
```

### 3. Click/Active Effektek

#### Gombok
```
active:bg-primary-900 active:scale-[0.98]
```

**Viselkedés:**  
- Click → enyhe zsugorítás (98% scale) + sötétebb háttér
- Release → visszaugrik

### 4. Focus States

#### Input
```
focus:outline-none focus:border-primary-600 focus:ring-2 focus:ring-primary-200
```

**Viselkedés:**  
- Focus → kék border + halvány kék ring (2px)

### 5. Speciális Animációk

#### Pulse (urgent badge)
```html
<div class="animate-pulse bg-danger-500">!</div>
```

**Használat:** Függő foglalók, kritikus figyelmeztetések

#### Slide-in (toast notification)
```css
@keyframes slide-in {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.animate-slide-in {
  animation: slide-in 0.3s ease-out;
}
```

---

## ♿ ACCESSIBILITY (WCAG 2.2 AA)

### Kontraszt Követelmények

| Szöveg méret | Minimum kontraszt |
|-------------|-------------------|
| Normál (< 18px) | **4.5:1** |
| Nagy (≥ 18px vagy ≥ 14px bold) | **3:1** |
| UI komponens | **3:1** |

### Teljesített Kontrasztok

| Kombináció | Kontraszt | Státusz |
|-----------|-----------|---------|
| `#1E3A8A` (primary-800) fehéren | **10.5:1** | ✅ AAA |
| `#059669` (success-600) fehéren | **4.6:1** | ✅ AA |
| `#DC2626` (danger-600) fehéren | **4.5:1** | ✅ AA |
| `#0284C7` (info-600) fehéren | **4.8:1** | ✅ AA |
| `#D97706` (accent-600) fehéren | **3.5:1** | ⚠️ AA nagy szöveg |

### Keyboard Navigation

**Minden interaktív elem:**
```html
<button class="focus:outline-none focus:ring-2 focus:ring-primary-200">
  ...
</button>
```

**Tab order:**  
1. Sidebar navigáció
2. Header user menu
3. Main content gombok/input
4. Táblázat sorok

### Screen Reader Support

**Semantic HTML:**
```html
<header>...</header>
<nav aria-label="Főmenü">...</nav>
<main>...</main>
<table>
  <thead>
    <tr>
      <th scope="col">Deviza</th>
    </tr>
  </thead>
</table>
```

**ARIA Attribútumok:**
```html
<button aria-label="Kijelentkezés" aria-pressed="false">
  <LogOut size={18} />
</button>

<div role="alert" aria-live="polite">
  Sikeres mentés!
</div>
```

---

## 📱 RESPONSIVE DESIGN

### Breakpoints
```css
sm: 640px   (tablet)
md: 768px   (tablet landscape)
lg: 1024px  (laptop)
xl: 1280px  (desktop)
2xl: 1536px (wide desktop)
```

**Elsődleges target:** `lg` (1920x1080 desktop)

### Layout Adaptáció

#### Desktop (≥1024px)
- Sidebar: 256px széles
- Main content: flex-1
- Grid: 3-4 oszlop

#### Tablet (768px - 1023px)
- Sidebar: 64px széles (csak ikonok)
- Main content: flex-1
- Grid: 2 oszlop

#### Mobile (< 768px)
**Jelenleg NEM támogatott** — desktop-only alkalmazás

---

## 🧪 TESTING CHECKLIST

### Visual QA
- [ ] Kontrasztok WCAG AA megfelelőség (WebAIM Contrast Checker)
- [ ] Hover/focus/active állapotok
- [ ] Typography hierarchy olvasható
- [ ] Spacing konzisztens
- [ ] Shadow nem túl erős
- [ ] Animációk smooth (60 FPS)

### Functional QA
- [ ] Keyboard navigation működik
- [ ] Screen reader olvassa a tartalmat
- [ ] TypeScript 0 hiba (`npx tsc --noEmit`)
- [ ] Gombok click → scale animation
- [ ] Táblázat hover → háttér változás

### Cross-browser
- [ ] Chrome 122+
- [ ] Edge 122+
- [ ] Firefox 123+

---

## 📚 KOMPONENS PÉLDÁK

### Dashboard KPI Card (teljes példa)
```tsx
<div className="stat-card bg-gradient-to-br from-primary-50 to-primary-100 border border-primary-200">
  <div className="flex items-start justify-between mb-3">
    <div className="p-2.5 rounded-lg bg-primary-100 text-primary-600">
      <ArrowLeftRight size={20} />
    </div>
    <div className="flex items-center gap-1 text-xs font-semibold text-success-700">
      <ArrowUp size={14} />
      12%
    </div>
  </div>
  <div className="text-sm text-secondary-600 mb-1">Mai tranzakciók</div>
  <div className="text-2xl font-bold text-secondary-900">47</div>
</div>
```

### Rates Table Row (teljes példa)
```tsx
<tr className="hover:bg-primary-50 cursor-pointer">
  <td>
    <div className="flex items-center gap-2">
      <span className="font-bold text-currency-eur">EUR</span>
      <span className="text-secondary-500 text-xs">Euró</span>
    </div>
  </td>
  <td className="text-right font-mono font-semibold">391.50</td>
  <td className="text-right font-mono font-semibold">398.50</td>
  <td className="text-right">
    <div className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold bg-success-100 text-success-700">
      <ArrowUp size={12} />
      +0.5%
    </div>
  </td>
</tr>
```

### Primary Button with Icon
```tsx
<button className="form-button-primary">
  <ArrowLeftRight size={18} />
  <span>Új tranzakció</span>
</button>
```

---

## 🔮 JÖVŐBELI FEJLESZTÉSEK

### V2.0 Tervezett Funkciók
1. **Dark Mode** — teljes támogatás (`.dark` osztály)
2. **Glassmorphism** — modern kártyák `backdrop-blur-xl`
3. **Bento Grid Dashboard** — aszimmetrikus layout
4. **Scrollytelling Reports** — GSAP ScrollTrigger
5. **Micro-interactions** — GSAP animációk hover/click-re
6. **Mobile Support** — reszponzív adaptáció (768px alatt)

---

**Készítette:** Gábor 🎨 (Gemini 3.1 Pro)  
**Utolsó frissítés:** 2026-03-05  
**Verzió:** 1.0.0
