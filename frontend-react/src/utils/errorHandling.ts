import { AxiosError } from 'axios';

export interface ApiError {
  message: string;
  status?: number;
  code?: string;
  details?: unknown;
}

export class ApplicationError extends Error {
  public readonly status?: number;
  public readonly code?: string;
  public readonly details?: unknown;

  constructor(message: string, status?: number, code?: string, details?: unknown) {
    super(message);
    this.name = 'ApplicationError';
    this.status = status;
    this.code = code;
    this.details = details;
    Object.setPrototypeOf(this, ApplicationError.prototype);
  }
}

function humanizeRawMessage(msg: string): string {
  if (msg === 'Network Error' || msg === 'Failed to fetch' || msg === 'Load failed') {
    return 'A szerver nem érhető el. Ellenőrizze a hálózati kapcsolatot.';
  }
  if (msg.includes('ECONNREFUSED') || msg.includes('ERR_CONNECTION_REFUSED')) {
    return 'A szerver nem fogadja a kapcsolatot.';
  }
  if (msg.includes('ENOTFOUND') || msg.includes('ERR_NAME_NOT_RESOLVED')) {
    return 'A szerver címe nem található.';
  }
  if (msg.includes('ETIMEDOUT') || msg.includes('timeout')) {
    return 'A szerver nem válaszolt időben.';
  }
  return msg;
}

export function handleApiError(error: unknown): ApplicationError {
  if (error instanceof ApplicationError) {
    return error;
  }

  if (error instanceof AxiosError) {
    const status = error.response?.status;
    const serverMessage = error.response?.data?.message;
    const message = serverMessage || humanizeRawMessage(error.message || 'Ismeretlen hiba történt');
    const code = error.response?.data?.code || error.code;
    const details = error.response?.data;

    return new ApplicationError(message, status, code, details);
  }

  if (error instanceof Error) {
    return new ApplicationError(humanizeRawMessage(error.message));
  }

  return new ApplicationError('Ismeretlen hiba történt');
}

export function getErrorMessage(error: unknown): string {
  const appError = handleApiError(error);
  return appError.message;
}

export function isNetworkError(error: unknown): boolean {
  if (error instanceof AxiosError) {
    return !error.response && error.code === 'ERR_NETWORK';
  }
  return false;
}

export function isUnauthorizedError(error: unknown): boolean {
  if (error instanceof AxiosError) {
    return error.response?.status === 401;
  }
  if (error instanceof ApplicationError) {
    return error.status === 401;
  }
  return false;
}

export function isForbiddenError(error: unknown): boolean {
  if (error instanceof AxiosError) {
    return error.response?.status === 403;
  }
  if (error instanceof ApplicationError) {
    return error.status === 403;
  }
  return false;
}

export function isNotFoundError(error: unknown): boolean {
  if (error instanceof AxiosError) {
    return error.response?.status === 404;
  }
  if (error instanceof ApplicationError) {
    return error.status === 404;
  }
  return false;
}
