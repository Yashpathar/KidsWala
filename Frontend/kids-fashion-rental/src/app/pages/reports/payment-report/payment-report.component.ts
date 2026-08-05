import { Component, OnInit, inject } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { asArray, normalizeRow, pickField } from '../../../core/models/api.models';

@Component({
  selector: 'app-payment-report',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, FormsModule],
  template: `
    <div class="page-header flex-between">
      <div><h2>Payment Report</h2><p class="breadcrumb">All payment transactions</p></div>
      <button type="button" class="btn-primary" (click)="load()">Refresh</button>
    </div>
    <div class="ui-card table-wrap">
      <table class="data-table">
        <thead><tr><th>Booking</th><th>Type</th><th>Mode</th><th>Amount</th><th>Date</th></tr></thead>
        <tbody>
          @for (r of rows; track $index) {
            <tr>
              <td>{{ r.bookingNo }}</td>
              <td>{{ r.paymentType }}</td>
              <td>{{ r.paymentMode }}</td>
              <td>{{ r.paymentAmount | currency:'INR' }}</td>
              <td>{{ r.paymentDate | date:'dd-MM-yyyy' }}</td>
            </tr>
          }
        </tbody>
        @if (rows.length) {
          <tfoot><tr><td colspan="3"><strong>Total</strong></td><td colspan="2"><strong>{{ total | currency:'INR' }}</strong></td></tr></tfoot>
        }
      </table>
    </div>
  `
})
export class PaymentReportComponent implements OnInit {
  private api = inject(ApiService);
  private auth = inject(AuthService);
  rows: { bookingNo: string; paymentType: string; paymentMode: string; paymentAmount: number; paymentDate: string }[] = [];

  get total() { return this.rows.reduce((s, r) => s + r.paymentAmount, 0); }

  ngOnInit() { this.load(); }

  load() {
    this.api.get<unknown>('/report/payments', { companyId: this.auth.currentUser()?.companyID }).subscribe(r => {
      if (r.success) {
        this.rows = asArray(r.data).map(x => {
          const row = normalizeRow(x);
          return {
            bookingNo: String(pickField(row, 'bookingNo', 'BookingNo') ?? ''),
            paymentType: String(pickField(row, 'paymentType', 'PaymentType') ?? ''),
            paymentMode: String(pickField(row, 'paymentMode', 'PaymentMode') ?? ''),
            paymentAmount: Number(pickField(row, 'paymentAmount', 'PaymentAmount') ?? 0),
            paymentDate: String(pickField(row, 'paymentDate', 'PaymentDate') ?? '')
          };
        });
      }
    });
  }
}
