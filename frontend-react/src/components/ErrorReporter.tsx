// ErrorReporter — breadcrumb ring buffer + error report sender

const MAX_BREADCRUMBS = 50;

interface Breadcrumb {
  type: string;
  message: string;
  timestamp: string;
  data?: unknown;
}

const breadcrumbs: Breadcrumb[] = [];

export function addBreadcrumb(type: string, message: string, data?: unknown) {
  breadcrumbs.push({ type, message, timestamp: new Date().toISOString(), data });
  if (breadcrumbs.length > MAX_BREADCRUMBS) {
    breadcrumbs.shift();
  }
}

export async function sendErrorReport(params: {
  errorType?: string;
  message?: string;
  stack?: string;
  url?: string;
  severity?: string;
}) {
  try {
    const body = {
      errorType: params.errorType ?? 'frontend_error',
      message: params.message ?? 'Unknown error',
      stack: params.stack,
      url: params.url ?? window.location.href,
      browser: navigator.userAgent,
      severity: params.severity ?? 'ERROR',
      breadcrumbs: [...breadcrumbs],
      timestamp: new Date().toISOString(),
    };

    await fetch('/api/error-report', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
  } catch {
    // Silently fail — error reporter must not crash
  }
}

// Auto-track clicks and navigations
if (typeof window !== 'undefined') {
  window.addEventListener('click', (e) => {
    const target = e.target as HTMLElement;
    addBreadcrumb('click', target?.tagName ?? 'unknown', { id: target?.id });
  });

  window.addEventListener('unhandledrejection', (e) => {
    sendErrorReport({
      errorType: 'unhandled_promise_rejection',
      message: String(e.reason),
      stack: e.reason?.stack,
    });
  });

  window.addEventListener('error', (e) => {
    sendErrorReport({
      errorType: 'window_error',
      message: e.message,
      stack: e.error?.stack,
    });
  });
}
