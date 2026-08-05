import { Component, OnInit } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { normalizeRows, pickField, pickId } from '../../../core/models/api.models';

export interface DeliveryReportRow {
  bookingID: number;
  bookingNo: string;
  customerName: string;
  productName: string;
  deliveryDate: string;
  pendingAmount: number;
  paymentStatus: string;
  deliveryStatus: string;
}

@Component({
  selector: 'app-delivery-report',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, FormsModule],
  templateUrl: './delivery-report.component.html',
  styleUrl: './delivery-report.component.scss'
})
export class DeliveryReportComponent implements OnInit {
  rows: DeliveryReportRow[] = [];
  reportDate = new Date().toISOString().substring(0, 10);
  loading = false;

  constructor(private api: ApiService, private auth: AuthService) {}

  ngOnInit() { this.load(); }

  load() {
    this.loading = true;
    this.api.get<unknown>('/report/today-delivery', {
      companyId: this.auth.currentUser()?.companyID,
      reportDate: this.reportDate
    }).subscribe({
      next: r => {
        this.loading = false;
        if (!r.success) {
          this.rows = [];
          return;
        }
        this.rows = normalizeRows(r.data).map(row => ({
          bookingID: pickId(row, 'bookingID', 'BookingID'),
          bookingNo: String(pickField(row, 'bookingNo', 'BookingNo') ?? ''),
          customerName: String(pickField(row, 'customerName', 'CustomerName') ?? ''),
          productName: String(pickField(row, 'productName', 'ProductName') ?? '—'),
          deliveryDate: String(pickField(row, 'deliveryDate', 'DeliveryDate') ?? ''),
          pendingAmount: Number(
            pickField(row, 'pendingAmount', 'PendingAmount', 'remainingAmount', 'RemainingAmount') ?? 0
          ),
          paymentStatus: String(pickField(row, 'paymentStatus', 'PaymentStatus') ?? '—'),
          deliveryStatus: String(
            pickField(row, 'deliveryStatus', 'DeliveryStatus', 'bookingStatus', 'BookingStatus') ?? 'Booked'
          )
        }));
      },
      error: () => {
        this.loading = false;
        this.rows = [];
      }
    });
  }

  statusClass(status: string): string {
    const s = (status || '').toLowerCase();
    if (s.includes('deliver')) return 'delivered';
    if (s.includes('book')) return 'booked';
    if (s.includes('return')) return 'returned';
    return 'booked';
  }

  print() { window.print(); }
}
