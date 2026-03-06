import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useToast, toast, type ToastMessage } from '@/hooks/useToast';

describe('Toast system', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('toast.success creates a success toast', () => {
    const { result } = renderHook(() => useToast());

    act(() => {
      toast.success('Művelet sikeres!');
    });

    expect(result.current.toasts).toHaveLength(1);
    const first = result.current.toasts[0];
    expect(first).toBeDefined();
    expect(first?.type).toBe('success');
    expect(first?.message).toBe('Művelet sikeres!');
  });

  it('toast.error creates an error toast', () => {
    const { result } = renderHook(() => useToast());

    act(() => {
      toast.error('Hiba történt!');
    });

    const toasts = result.current.toasts;
    const errorToast = toasts.find(
      (t) => t.message === 'Hiba történt!',
    );
    expect(errorToast).toBeDefined();
    if (errorToast) {
      expect(errorToast.type).toBe('error');
    }
  });

  it('toast.warning creates a warning toast', () => {
    const { result } = renderHook(() => useToast());

    act(() => {
      toast.warning('Figyelmeztetés!');
    });

    const toasts = result.current.toasts;
    const warnToast = toasts.find(
      (t) => t.message === 'Figyelmeztetés!',
    );
    expect(warnToast).toBeDefined();
    if (warnToast) {
      expect(warnToast.type).toBe('warning');
    }
  });

  it('toast.info creates an info toast', () => {
    const { result } = renderHook(() => useToast());

    act(() => {
      toast.info('Információ.');
    });

    const toasts = result.current.toasts;
    const infoToast = toasts.find(
      (t) => t.message === 'Információ.',
    );
    expect(infoToast).toBeDefined();
    if (infoToast) {
      expect(infoToast.type).toBe('info');
    }
  });

  it('toast auto-dismisses after duration', () => {
    const { result } = renderHook(() => useToast());

    act(() => {
      toast.success('Teszt üzenet', 3000);
    });

    expect(result.current.toasts.length).toBeGreaterThanOrEqual(1);

    // Advance time past the duration
    act(() => {
      vi.advanceTimersByTime(3500);
    });

    // The auto-dismissed toast should be gone
    const remaining = result.current.toasts.filter(
      (t: ToastMessage) => t.message === 'Teszt üzenet',
    );
    expect(remaining).toHaveLength(0);
  });

  it('dismissToast removes a specific toast', () => {
    const { result } = renderHook(() => useToast());

    act(() => {
      toast.success('Maradó üzenet', 0); // duration=0 → no auto-dismiss
      toast.error('Törlendő üzenet', 0);
    });

    const toDelete = result.current.toasts.find(
      (t: ToastMessage) => t.message === 'Törlendő üzenet',
    );
    expect(toDelete).toBeDefined();

    act(() => {
      result.current.dismissToast(toDelete?.id ?? '');
    });

    const afterDismiss = result.current.toasts.filter(
      (t: ToastMessage) => t.message === 'Törlendő üzenet',
    );
    expect(afterDismiss).toHaveLength(0);
  });

  it('multiple toasts can coexist', () => {
    const { result } = renderHook(() => useToast());
    const initialLength = result.current.toasts.length;

    act(() => {
      toast.success('Üzenet 1', 0);
      toast.warning('Üzenet 2', 0);
      toast.info('Üzenet 3', 0);
    });

    expect(result.current.toasts.length).toBeGreaterThanOrEqual(initialLength + 3);
  });

  it('toast id is unique', () => {
    const { result } = renderHook(() => useToast());

    act(() => {
      toast.success('A', 0);
      toast.success('B', 0);
    });

    const ids = result.current.toasts.map((t: ToastMessage) => t.id);
    const uniqueIds = new Set(ids);
    expect(uniqueIds.size).toBe(ids.length);
  });
});

describe('ToastContainer component', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../Toast');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../Toast');
    expect(typeof mod.default).toBe('function');
  });
});
