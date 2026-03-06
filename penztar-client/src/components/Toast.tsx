import { useToast, type ToastType } from '@/hooks/useToast';

const typeStyles: Record<ToastType, { bg: string; icon: string; border: string }> = {
  success: { bg: 'bg-green-50', icon: '✅', border: 'border-green-400' },
  error: { bg: 'bg-red-50', icon: '❌', border: 'border-red-400' },
  warning: { bg: 'bg-yellow-50', icon: '⚠️', border: 'border-yellow-400' },
  info: { bg: 'bg-blue-50', icon: 'ℹ️', border: 'border-blue-400' },
};

/**
 * Toast konténer — az App gyökérbe kell betenni egyszer.
 * Automatikusan megjeleníti a globális toast üzeneteket.
 */
export default function ToastContainer() {
  const { toasts, dismissToast } = useToast();

  if (toasts.length === 0) return null;

  return (
    <div className="fixed top-4 right-4 z-[9999] flex flex-col gap-2 max-w-sm">
      {toasts.map((t) => {
        const style = typeStyles[t.type];
        return (
          <div
            key={t.id}
            className={`${style.bg} ${style.border} border-l-4 p-3 rounded shadow-lg flex items-start gap-2 animate-slide-in`}
            role="alert"
          >
            <span className="text-lg flex-shrink-0">{style.icon}</span>
            <p className="text-sm text-gray-800 flex-1">{t.message}</p>
            <button
              onClick={() => dismissToast(t.id)}
              className="text-gray-400 hover:text-gray-600 text-sm flex-shrink-0 ml-2"
              aria-label="Bezárás"
            >
              ✕
            </button>
          </div>
        );
      })}
    </div>
  );
}
