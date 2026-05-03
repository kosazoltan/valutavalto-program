import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import reactHooks from 'eslint-plugin-react-hooks';
import i18next from 'eslint-plugin-i18next';
import globals from 'globals';

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
      // Egy kovetkezo sprintben fokozatosan lecsereljuk a szovegeket -> szigoritas 'error'-ra.
      'i18next/no-literal-string': ['warn', {
        markupOnly: true,                          // csak JSX szoveget flag-eli, NEM minden string-et
        ignoreAttribute: [
          'data-testid', 'data-cy', 'data-test', // teszt selectorok
          'aria-controls', 'aria-describedby', 'aria-labelledby',
          'className', 'class', 'id', 'name', 'type', 'role',
          'href', 'src', 'alt', 'rel', 'target', 'method',
          'key', 'ref', 'style', 'placeholder',  // placeholder-eket kulon szabalyozzuk
          'lang', 'xmlns', 'viewBox', 'fill', 'stroke',
        ],
      }],
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
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      'no-console': 'off',
    },
  },
  {
    files: ['**/*.test.{ts,tsx}', '**/*.spec.{ts,tsx}'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
    },
  }
);
