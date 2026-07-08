interface PagedResponse {
  content: unknown[]
}

function isPagedResponse(data: unknown): data is PagedResponse {
  return (
    data !== null &&
    typeof data === 'object' &&
    'content' in data &&
    Array.isArray((data as PagedResponse).content)
  )
}

export function safeArray<T>(data: unknown): T[] {
  if (Array.isArray(data)) return data as T[]
  if (isPagedResponse(data)) {
    return data.content as T[]
  }
  return []
}
