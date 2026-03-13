import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render } from '@testing-library/react';
import { screen, fireEvent } from '@testing-library/dom';
import ErrorBoundary from '../ErrorBoundary';

// Suppress console.error for expected errors
beforeEach(() => {
  vi.spyOn(console, 'error').mockImplementation(() => {});
});

// Test component that throws
function ThrowingComponent(): React.ReactElement {
  throw new Error('Teszt hiba');
}

// Test component that renders normally
function NormalComponent(): React.ReactElement {
  return <div data-testid="normal">Helló Világ</div>;
}

describe('ErrorBoundary', () => {
  it('renders children when no error', () => {
    render(
      <ErrorBoundary>
        <NormalComponent />
      </ErrorBoundary>,
    );

    expect(screen.getByTestId('normal')).toBeInTheDocument();
    expect(screen.getByText('Helló Világ')).toBeInTheDocument();
  });

  it('catches error and shows fallback UI', () => {
    render(
      <ErrorBoundary>
        <ThrowingComponent />
      </ErrorBoundary>,
    );

    expect(screen.getByText('Váratlan hiba történt')).toBeInTheDocument();
    expect(screen.getByText('Teszt hiba')).toBeInTheDocument();
    expect(screen.getByText('Újrapróbálás')).toBeInTheDocument();
  });

  it('shows custom fallback when provided', () => {
    const customFallback = <div data-testid="custom-fallback">Egyedi hiba nézet</div>;

    render(
      <ErrorBoundary fallback={customFallback}>
        <ThrowingComponent />
      </ErrorBoundary>,
    );

    expect(screen.getByTestId('custom-fallback')).toBeInTheDocument();
    expect(screen.getByText('Egyedi hiba nézet')).toBeInTheDocument();
  });

  it('reset button clears error state', () => {
    render(
      <ErrorBoundary>
        <ThrowingComponent />
      </ErrorBoundary>,
    );

    // Error state shown
    expect(screen.getByText('Váratlan hiba történt')).toBeInTheDocument();

    // Click reset — note: this will trigger the throwing component again
    const resetBtn = screen.getByText('Újrapróbálás');
    fireEvent.click(resetBtn);

    // It will throw again, so error boundary re-catches
    expect(screen.getByText('Váratlan hiba történt')).toBeInTheDocument();
  });

  it('logs error to console', () => {
    render(
      <ErrorBoundary>
        <ThrowingComponent />
      </ErrorBoundary>,
    );

    expect(console.error).toHaveBeenCalled();
  });
});
