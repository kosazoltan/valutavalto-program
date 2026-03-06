import { useCallback, useSyncExternalStore } from 'react';

export type ToastType = 'success' | 'error' | 'warning' | 'info';

export interface ToastMessage {
  id: string;
  type: ToastType;
  message: string;
  duration?: number;
}

// --- Global toast store (singleton) ---
let toasts: ToastMessage[] = [];
const listeners = new Set<() => void>();

function emitChange(): void {
  for (const listener of listeners) {
    listener();
  }
}

function subscribe(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

function getSnapshot(): ToastMessage[] {
  return toasts;
}

function addToast(type: ToastType, message: string, duration = 5000): void {
  const id = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const toast: ToastMessage = { id, type, message, duration };
  toasts = [...toasts, toast];
  emitChange();

  if (duration > 0) {
    setTimeout(() => {
      removeToast(id);
    }, duration);
  }
}

function removeToast(id: string): void {
  toasts = toasts.filter((t) => t.id !== id);
  emitChange();
}

// --- Exported global functions (use from anywhere, no hook needed) ---
export const toast = {
  success: (message: string, duration?: number) => addToast('success', message, duration),
  error: (message: string, duration?: number) => addToast('error', message, duration),
  warning: (message: string, duration?: number) => addToast('warning', message, duration),
  info: (message: string, duration?: number) => addToast('info', message, duration),
};

// --- Hook ---
export function useToast() {
  const currentToasts = useSyncExternalStore(subscribe, getSnapshot, getSnapshot);

  const showToast = useCallback(
    (type: ToastType, message: string, duration?: number) => addToast(type, message, duration),
    [],
  );

  const dismissToast = useCallback((id: string) => removeToast(id), []);

  return {
    toasts: currentToasts,
    showToast,
    dismissToast,
    success: toast.success,
    error: toast.error,
    warning: toast.warning,
    info: toast.info,
  };
}
