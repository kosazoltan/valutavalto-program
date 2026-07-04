// Type-only contract assertions — npm run typecheck látja, a vitest nem futtatja.
import type { IpcRequest, IpcResponse, IpcRoutes } from '@valuta/shared-ipc';

type Expect<T extends true> = T;
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2)
  ? true
  : false;

// 1) savePendingTransactionV2: request = V235 kanonikus input, response = SQLite rowid.
export type _T1 = Expect<Equal<IpcResponse<'save-pending-transaction-v2'>, number>>;
declare const txInput: IpcRequest<'save-pending-transaction-v2'>;
const _txType: 'SELL' | 'BUY' = txInput.type;
const _txHuf: number = txInput.hufAmount;
// @ts-expect-error — nem létező mező nem érhető el.
export type _MissingTxField = typeof txInput.hufAmout;

// 2) savePendingConversionV2: request = V235/V236 kanonikus input, response = SQLite rowid.
export type _T2 = Expect<Equal<IpcResponse<'save-pending-conversion-v2'>, number>>;
declare const convInput: IpcRequest<'save-pending-conversion-v2'>;
const _convFrom: string = convInput.fromCurrencyCode;
// @ts-expect-error — nem létező mező nem érhető el.
export type _MissingConvField = typeof convInput.fromCurrencyCod;

// 3) save-pending-transfer: pozicionális tuple, utolsó 4 elem opcionális.
type TransferArgs = IpcRequest<'save-pending-transfer'>;
export type _T3 = Expect<Equal<IpcResponse<'save-pending-transfer'>, number>>;
const _okMin: TransferArgs = ['b-1', '105', 3, 'EUR', 100, 41000, 'VAULT', null, null];
const _okFull: TransferArgs = [
  'b-1',
  '105',
  3,
  'EUR',
  100,
  41000,
  'VAULT',
  null,
  null,
  'carrier',
  'seal',
  'F',
  '[{"currencyCode":"EUR"}]',
];
// @ts-expect-error — amount (number) helyére string nem mehet (sorrendhiba-fogás).
const _swap: TransferArgs = ['b-1', '105', 3, 'EUR', 'EUR', 41000, 'VAULT', null, null];

// 4) sync-offline: request void, response number (handler: syncAll().synced).
export type _T4 = Expect<Equal<IpcRoutes['sync-offline']['request'], void>>;
export type _T5 = Expect<Equal<IpcResponse<'sync-offline'>, number>>;

void _txType;
void _txHuf;
void _convFrom;
void _okMin;
void _okFull;
void _swap;
