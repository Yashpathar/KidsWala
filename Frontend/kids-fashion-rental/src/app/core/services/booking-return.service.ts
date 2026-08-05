import { inject, Injectable } from '@angular/core';
import { Observable, of, switchMap, throwError } from 'rxjs';
import { ApiService } from './api.service';
import { AuthService } from './auth.service';
import { ApiResult, extractErrorMessage, normalizeRow, pickField } from '../models/api.models';

export interface ProcessReturnPayload {
  bookingID: number;
  actualReturnDate: string;
  damageDeductionAmount: number;
  returnNotes?: string;
  refundAmount: number;
  paymentMode: 'Cash' | 'Online';
  transactionNo?: string;
}

@Injectable({ providedIn: 'root' })
export class BookingReturnService {
  private api = inject(ApiService);
  private auth = inject(AuthService);

  processReturn(payload: ProcessReturnPayload): Observable<ApiResult<unknown>> {
    const user = this.auth.currentUser();
    if (!user?.userID) {
      throw new Error('Not logged in');
    }

    return this.api
      .post<unknown>('/booking/process-return', {
        bookingID: payload.bookingID,
        actualReturnDate: payload.actualReturnDate,
        damageDeductionAmount: payload.damageDeductionAmount,
        returnNotes: payload.returnNotes
      })
      .pipe(
        switchMap(r => {
          if (!r.success) {
            return throwError(() => new Error(r.message || extractErrorMessage(r.data) || 'Return failed'));
          }
          const data = normalizeRow(r.data);
          const refund =
            payload.refundAmount ||
            Number(pickField(data, 'finalRefundAmount', 'FinalRefundAmount') ?? 0);

          if (refund <= 0) {
            return of({ ...r, message: r.message || 'Return processed (no refund)' } as ApiResult<unknown>);
          }

          return this.api.post('/booking/payment', {
            companyID: user.companyID || 1,
            bookingID: payload.bookingID,
            paymentType: 'Deposit Refund',
            paymentMode: payload.paymentMode,
            paymentAmount: refund,
            transactionNo: payload.transactionNo || '',
            notes: payload.returnNotes || 'Deposit refund after return',
            createdBy: user.userID
          });
        })
      );
  }
}
