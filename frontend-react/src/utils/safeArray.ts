export function safeArray<T>(data: unknown): T[] {
  if (Array.isArray(data)) return data as T[];
  if (data && typeof data === 'object' && 'content' in data && Array.isArray((data as any).content)) {
    return (data as any).content;
  }
  return [];
}
