const ERRORLOG_HEADER = "X-Error-Signature";

function getApiUrl(): string {
  const base = import.meta.env.VITE_API_URL ?? "";
  return base.replace(/\/$/, "");
}

function getAppVersion(): string {
  return import.meta.env.VITE_APP_VERSION || "unknown";
}

async function hmacSha256(message: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message));
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export async function sendErrorReport(error: Error, context?: string): Promise<void> {
  try {
    const secret = import.meta.env.VITE_ERRORLOG_HMAC_SECRET as string | undefined;
    if (!secret || !window.crypto?.subtle) return;

    const payload = {
      errorType: error.name || "Error",
      message: context ? `${context}: ${error.message}` : error.message,
      stack: error.stack,
      appVersion: getAppVersion(),
      timestamp: new Date().toISOString(),
    };

    const body = JSON.stringify(payload);
    const signature = await hmacSha256(body, secret);

    await fetch(`${getApiUrl()}/error-report`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        [ERRORLOG_HEADER]: signature,
      },
      body,
    });
  } catch {
    // Never throw from error reporter
  }
}

let initialized = false;

export function initErrorReporter(): void {
  if (initialized || typeof window === "undefined") return;
  initialized = true;

  window.addEventListener("error", (event) => {
    const err = event.error instanceof Error ? event.error : new Error(event.message);
    void sendErrorReport(err, "window.onerror");
  });

  window.addEventListener("unhandledrejection", (event) => {
    const reason = event.reason instanceof Error ? event.reason : new Error(String(event.reason));
    void sendErrorReport(reason, "unhandledrejection");
  });
}
