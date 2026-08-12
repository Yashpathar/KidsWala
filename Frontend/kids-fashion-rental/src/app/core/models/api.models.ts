export interface ApiResult<T = unknown> {
  success: boolean;
  message: string;
  data: T;
}

export interface Customer {
  customerID: number;
  fullName: string;
  contactNo1: string;
  contactNo2?: string;
  address?: string;
  city?: string;
  notes?: string;
}

export interface Product {
  productID: number;
  productCode: string;
  productName: string;
  categoryName?: string;
  size: string;
  color: string;
  rentAmount: number;
  depositAmount: number;
  discountPercent: number;
  standardRentalDays?: number;
  extraChargePerDay?: number;
  productImage?: string;
  availableQuantity?: number;
  isFullSet?: boolean;
  topCode?: string;
  topSize?: string;
  bottomCode?: string;
  bottomSize?: string;
}

export interface BookingItem {
  productID: number;
  productCode: string;
  productName: string;
  size: string;
  color: string;
  rentAmount: number;
  depositAmount: number;
  discountPercent: number;
  finalRentAmount: number;
  productImage?: string;
  isFullSet?: boolean;
  topCode?: string;
  topSize?: string;
  bottomCode?: string;
  bottomSize?: string;
}

export interface AvailabilityResult {
  success: number;
  message: string;
  customerName?: string;
  deliveryDate?: string;
  returnDate?: string;
  nextAvailableDate?: string;
}

export function asRecord(data: unknown): Record<string, unknown> {
  return data && typeof data === 'object' && !Array.isArray(data)
    ? (data as Record<string, unknown>)
    : {};
}

/** Pull human-readable text from API / ASP.NET validation responses */
export function extractErrorMessage(body: unknown): string {
  if (!body || typeof body !== 'object') return '';
  const b = body as Record<string, unknown>;

  const direct = String(b['message'] ?? b['Message'] ?? '').trim();
  if (direct) return direct;

  const data = asRecord(b['data'] ?? b['Data']);
  const nested = String(data['message'] ?? data['Message'] ?? '').trim();
  if (nested) return nested;

  const errors = b['errors'] ?? b['Errors'];
  if (errors && typeof errors === 'object' && !Array.isArray(errors)) {
    const lines: string[] = [];
    for (const val of Object.values(errors as Record<string, unknown>)) {
      if (Array.isArray(val)) lines.push(...val.map(String));
      else if (val) lines.push(String(val));
    }
    if (lines.length) return lines.join(' ');
  }

  const title = String(b['title'] ?? b['Title'] ?? '').trim();
  if (title) return title;

  return '';
}

/** Normalize API body (handles Success/Message/Data or success/message/data) */
export function normalizeApiResult<T = unknown>(body: unknown): ApiResult<T> {
  if (!body || typeof body !== 'object') {
    return { success: false, message: 'Invalid server response', data: null as T };
  }
  const b = body as Record<string, unknown>;
  const data = (b['data'] ?? b['Data'] ?? null) as T;
  const dataRec = asRecord(data);
  const successFlag = b['success'] ?? b['Success'] ?? dataRec['success'] ?? dataRec['Success'];
  return {
    success: successFlag === true || successFlag === 1 || successFlag === '1',
    message: extractErrorMessage(b),
    data
  };
}

export function asArray<T = any>(data: unknown): T[] {
  return Array.isArray(data) ? (data as T[]) : [];
}

export function pickId(row: unknown, ...keys: string[]): number {
  if (typeof row === 'number' && row > 0) return row;
  if (typeof row === 'string' && row.trim() !== '') {
    const n = Number(row);
    if (n > 0) return n;
  }
  const r = asRecord(row);
  for (const k of keys) {
    const v = r[k];
    if (v !== null && v !== undefined && v !== '') return Number(v);
  }
  return 0;
}

/** Normalize a DB row to camelCase-friendly keys for templates */
export function normalizeRow(row: unknown): Record<string, unknown> {
  const r = asRecord(row);
  const out: Record<string, unknown> = { ...r };
  for (const [key, val] of Object.entries(r)) {
    if (!key) continue;
    const camel = key.charAt(0).toLowerCase() + key.slice(1);
    if (!(camel in out)) out[camel] = val;
  }
  return out;
}

export function normalizeRows(rows: unknown): Record<string, unknown>[] {
  return asArray<unknown>(rows).map(normalizeRow);
}

export function pickField<T>(row: unknown, ...keys: string[]): T | undefined {
  const r = asRecord(row);
  for (const k of keys) {
    const v = r[k];
    if (v !== null && v !== undefined) return v as T;
  }
  return undefined;
}

/** Map availability SP row to a consistent shape */
export function parseAvailability(data: unknown): AvailabilityResult | null {
  const r = asRecord(data);
  if (!Object.keys(r).length) return null;
  return {
    success: Number(r['success'] ?? r['Success'] ?? 0),
    message: String(r['message'] ?? r['Message'] ?? ''),
    customerName: pickField<string>(r, 'customerName', 'CustomerName'),
    deliveryDate: pickField<string>(r, 'deliveryDate', 'DeliveryDate'),
    returnDate: pickField<string>(r, 'returnDate', 'ReturnDate'),
    nextAvailableDate: pickField<string>(r, 'nextAvailableDate', 'NextAvailableDate')
  };
}
