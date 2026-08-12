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
      <div><h2>Payment Report</h2><p class="breadcrumb">REPORTS / <strong>Payment Report</strong></p></div>
      <div class="actions no-print">
        <div class="date-group">
          <label>From:</label>
          <input type="date" [(ngModel)]="fromDate" (change)="load()" />
        </div>
        <div class="date-group">
          <label>To:</label>
          <input type="date" [(ngModel)]="toDate" (change)="load()" />
        </div>
        <button type="button" class="btn-primary" (click)="load()" [disabled]="loading">Refresh</button>
        <button type="button" class="btn-outline" (click)="print()">Print</button>
      </div>
    </div>
    <div class="ui-card table-wrap">
      <table class="data-table">
        <thead><tr><th>Booking</th><th>Type</th><th>Mode</th><th>Amount</th><th>Date</th></tr></thead>
        <tbody>
          @if (loading) {
            <tr><td colspan="5" class="empty-row">Loading...</td></tr>
          } @else if (!rows.length) {
            <tr><td colspan="5" class="empty-row">No payments found for selected date range</td></tr>
          }
          @for (r of rows; track $index) {
            <tr>
              <td><strong>{{ r.bookingNo }}</strong></td>
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
  `,
  styles: [`
    .actions { display: flex; gap: 0.5rem; align-items: center; }
    .date-group { display: flex; align-items: center; gap: 0.35rem; label { font-size: 0.85rem; font-weight: 500; color: #555; } }
    .btn-outline { border: 1px solid var(--primary); background: #fff; color: var(--primary); padding: 0.5rem 1rem; border-radius: 10px; cursor: pointer; }
    .table-wrap { padding: 1rem; overflow-x: auto; }
    .empty-row { text-align: center; padding: 2rem; color: #888; }
    @media print { .no-print { display: none; } }
  `]
})
export class PaymentReportComponent implements OnInit {
  private api = inject(ApiService);
  private auth = inject(AuthService);

  fromDate = new Date().toISOString().substring(0, 10);
  toDate = new Date().toISOString().substring(0, 10);
  loading = false;
  rows: { bookingNo: string; paymentType: string; paymentMode: string; paymentAmount: number; paymentDate: string }[] = [];

  get total() { return this.rows.reduce((s, r) => s + r.paymentAmount, 0); }

  ngOnInit() { this.load(); }

  load() {
    this.loading = true;
    this.api.get<unknown>('/report/payments', {
      companyId: this.auth.currentUser()?.companyID,
      fromDate: this.fromDate,
      toDate: this.toDate
    }).subscribe({
      next: r => {
        this.loading = false;
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
        } else {
          this.rows = [];
        }
      },
      error: () => {
        this.loading = false;
        this.rows = [];
      }
    });
  }

  print() { window.print(); }
}
