/**
 * v2.4.0 (F: Sourcery #320 P3) — i18next setup.
 *
 * Felhasznáo-direktíva (2026-04-30 06:15 CEST):
 *   - F-1: Yes (i18next library setup)
 *   - F-2: Csak HU (single locale, no EN/DE)
 *
 * Iparági pattern:
 * - Centralized translation resource (src/i18n/hu.json)
 * - useTranslation() hook (NEM hard-coded JSX strings)
 * - Future-proof: ha később multi-locale kell, csak új JSON fájl + i18next
 *   detector
 *
 * Migration plan (incremental, NEM blocking):
 * - v2.4.0: setup + ~20 most-used common string (Mentés, Mégse, Vétel, Eladás stb.)
 * - v2.4.X: progressive migration of new components
 * - v2.5.0+: full sweep ~50 fájl (linter rule + CI gate)
 *
 * NEM blocking: a v2.3.X-es i18n batch-fix-ek (5 batch / ~50 string) MARADNAK,
 * de az új komponensek mostantól useTranslation()-t kell használjanak.
 */
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import hu from './hu.json';

i18n
  .use(initReactI18next)
  .init({
    resources: {
      hu: { translation: hu },
    },
    lng: 'hu',
    fallbackLng: 'hu',
    interpolation: {
      escapeValue: false, // React mar XSS-protect-tel rendert
    },
    // Production-ban NEM ad warning ha hiányzó key — fallback a key-szöveg
    // (NEM tör ke a UI-t)
    returnNull: false,
    saveMissing: false,
  });

export default i18n;
