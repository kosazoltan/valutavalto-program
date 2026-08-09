import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import reactHooks from 'eslint-plugin-react-hooks'
import i18next from 'eslint-plugin-i18next'
import globals from 'globals'

export default tseslint.config(
  {
    ignores: ['dist/**', 'coverage/**', 'playwright-report/**', 'test-results/**'],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{js,mjs,cjs}'],
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
    rules: {
      '@typescript-eslint/no-require-imports': 'off',
    },
  },
  {
    files: ['**/*.{ts,tsx,jsx}'],
    languageOptions: {
      globals: {
        ...globals.browser,
      },
    },
    plugins: { 'react-hooks': reactHooks, i18next },
    rules: {
      ...reactHooks.configs.recommended.rules,
      // i18next no-literal-string: JSX szovegek + JSX attributumok t() fuggvenyen
      // keresztul lokalizalando ahelyett, hogy hardcoded magyar szoveg lenne.
      // Bevezetes: 'warn' szint, hogy a CI ne torjon meg a meglevo violations-okre.
      //
      // Codex P1 PR #374 fix: a v6 plugin a `mode` + `'jsx-attributes'` opciokat hasznalja,
      // NEM `markupOnly` + `ignoreAttribute`. A korabbi config csendben ignoralva volt
      // (a default `jsx-text-only` mode + default exclude list ervenyesult).
      //
      // Copilot P3 PR #374 fix: az `alt`, `placeholder`, `aria-label` user-facing
      // accessibility text-ek -> a kovetkezo i18n migration sprint-ben lokalizalandok,
      // ezert NEM exclude-oljuk most (flag-eljuk warningkent, baseline-be szamolva).
      'i18next/no-literal-string': [
        'warn',
        {
          // mode 'jsx-text-only': csak JSX text content (NEM minden string literal,
          // NEM JSX attribute strings) — pontosan ami kell az UI lokalizaciohoz.
          mode: 'jsx-text-only',
          // jsx-attributes.exclude: ezeket az attributumokat NEM flag-eljuk
          // (technikai ertekek vagy nem-szoveg payload). Az `alt`, `placeholder`,
          // `aria-label` SZANDEKOSAN nincs benne — azok lokalizalando user-facing text.
          'jsx-attributes': {
            exclude: [
              // default plugin excludes (stay)
              'className',
              'styleName',
              'style',
              'type',
              'key',
              'id',
              'width',
              'height',
              // additionalisak - test selectorok, technikai ARIA, URL-ek, SVG attr
              'data-testid',
              'data-cy',
              'data-test',
              'aria-controls',
              'aria-describedby',
              'aria-labelledby',
              'class',
              'name',
              'role',
              'href',
              'src',
              'rel',
              'target',
              'method',
              'ref',
              'lang',
              'xmlns',
              'viewBox',
              'fill',
              'stroke',
            ],
          },
        },
      ],
      // Audit-iter3 P1 (eslint-plugin-react-hooks v7 upgrade, 2026-04-27):
      // a v7 7 uj szabalyt vezetett be a `recommended`-be. Ezeket OPT-IN modon
      // kezeljuk - a `recommended` csak v5-tel ekvivalens magot tartja
      // (rules-of-hooks, exhaustive-deps). Egy kovetkezo PR-ben a kodot lehet
      // adaptalni az uj szabalyokhoz.
      'react-hooks/set-state-in-effect': 'off',
      'react-hooks/immutability': 'off',
      'react-hooks/refs': 'off',
      'react-hooks/static-components': 'off',
      'react-hooks/preserve-manual-memoization': 'off',
      'react-hooks/purity': 'off',
      'react-hooks/component-hook-factories': 'off',
      // Lint-audit 2026-08-09: ERROR szint. A hook-fuggosegek hianya nem
      // kozmetikai kerdes — penzugyi kepernyokon stale closure-t okoz (a
      // CashierTransactionPage submit-callbackje regi dij-felulbiralast es
      // kartyaszamot vitt volna fel, a CustomerPanel regi AML/Pmt. adatot mentett
      // volna). A 2503 i18n-warning kozott az ilyen jelzes elveszett, ezert ez a
      // szabaly kulon, blokkolo szinten fut. Indokolt kivetelt inline
      // `eslint-disable-next-line` + magyarazo komment ad (lasd ShipmentNewPage).
      'react-hooks/exhaustive-deps': 'error',
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      'no-console': 'off',
    },
  },
  {
    files: ['**/*.test.{ts,tsx}', '**/*.spec.{ts,tsx}'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      // Teszt-fixture szovegek (pl. "Custom error fallback") NEM felhasznalo-felé
      // jelennek meg, nincs ertelme i18n-elni. False-positive warning-ok elhagyasa.
      'i18next/no-literal-string': 'off',
    },
  },
  {
    // NAV bizonylat sablon — a fajlokban minden literal jogszabalyi vagy NAV
    // mintaszerusegbol KOTELEZO (2007. evi CXVII. tv. 86. § e), MNB Pmt. cimke-
    // mintaszeruseg). A fajlok JSDoc-jaban reszletes indoklas.
    //
    // Sourcery PR #669 inline-disable javaslat: a `/* eslint-disable */` direktiva
    // a jelenlegi ESLint flat-config + eslint-plugin-i18next verzioval NEM aktivalodik
    // (a direktiva "Unused"-kent flag-elodik, mig a warning-ok megis kiirodnak).
    // Ezert config-szintu override + in-file JSDoc dokumentacio a kompromisszum.
    files: ['src/components/ReceiptPrint.tsx', 'src/components/electron/ReceiptPreviewModal.tsx'],
    rules: {
      'i18next/no-literal-string': 'off',
    },
  },
)
