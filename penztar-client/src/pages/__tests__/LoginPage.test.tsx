import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import LoginPage from '../LoginPage';

vi.mock('@/stores/authStore', () => ({
  useAuthStore: () => ({
    login: vi.fn(),
    isAuthenticated: false,
    isLoading: false,
    error: null,
  }),
}));

vi.mock('@/hooks/useAppMode', () => ({
  useAppMode: () => ({
    mode: 'penztar',
    isPenztar: true,
    isErtektar: false,
    companyName: 'Best Change',
  }),
}));

describe('LoginPage', () => {
  it('rendereli a bejelentkezés formot', () => {
    render(
      <MemoryRouter>
        <LoginPage />
      </MemoryRouter>,
    );
    // A login form biztosan tartalmaz input mezőket
    const inputs = document.querySelectorAll('input');
    expect(inputs.length).toBeGreaterThan(0);
  });

  it('tartalmaz jelszó mezőt', () => {
    render(
      <MemoryRouter>
        <LoginPage />
      </MemoryRouter>,
    );
    const passwordInput = document.querySelector('input[type="password"]');
    expect(passwordInput).toBeTruthy();
  });
});
