// Type-only contract assertions — X4 read/util folytatás (X4-REMAINDER-READ).
// npm run typecheck látja, a vitest nem futtatja.
import type { IpcRequest, IpcResponse } from '@valuta/shared-ipc';

type Expect<T extends true> = T;
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;

// 1) get-pending-transaction-ref-by-id: nyers pozicionális id → nyugta-ref vagy null (SPEND-RETID).
export type _R1 = Expect<Equal<IpcRequest<'get-pending-transaction-ref-by-id'>, number>>;
export type _R2 = Expect<Equal<IpcResponse<'get-pending-transaction-ref-by-id'>, string | null>>;

// 2) get-pending-transfer-ref-by-id: nyers pozicionális id → transfer-ref vagy null.
export type _R3 = Expect<Equal<IpcRequest<'get-pending-transfer-ref-by-id'>, number>>;
export type _R4 = Expect<Equal<IpcResponse<'get-pending-transfer-ref-by-id'>, string | null>>;

// 3) get-pending-transaction-count: argumentum nélküli invoke → darabszám.
export type _R5 = Expect<Equal<IpcRequest<'get-pending-transaction-count'>, void>>;
export type _R6 = Expect<Equal<IpcResponse<'get-pending-transaction-count'>, number>>;

// Negatív: a request NEM objektum — wire-alak-őr (version-skew, pitfall #36).
// @ts-expect-error — { id } objektum nem felel meg a nyers number requestnek.
const _bad: IpcRequest<'get-pending-transaction-ref-by-id'> = { id: 1 };
void _bad;
