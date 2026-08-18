import { Component, OnInit, inject } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { AlertService } from '../../../core/services/alert.service';
import { normalizeRows, pickField, pickId } from '../../../core/models/api.models';
import { environment } from '../../../../environments/environment';
import { CustomDatePickerComponent } from '../../../shared/components/custom-date-picker/custom-date-picker.component';

export interface DeliveryReportRow {
  bookingID: number;
  bookingNo: string;
  customerName: string;
  productCode?: string;
  productName: string;
  deliveryDate: string;
  pendingAmount: number;
  paymentStatus: string;
  deliveryStatus: string;
  deliverySession?: string;
  returnSession?: string;
}

@Component({
  selector: 'app-delivery-report',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, FormsModule, CustomDatePickerComponent],
  templateUrl: './delivery-report.component.html',
  styleUrl: './delivery-report.component.scss'
})
export class DeliveryReportComponent implements OnInit {
  private api = inject(ApiService);
  private auth = inject(AuthService);
  private alert = inject(AlertService);

  rows: DeliveryReportRow[] = [];
  fromDate = new Date().toISOString().substring(0, 10);
  toDate = new Date().toISOString().substring(0, 10);
  loading = false;

  productDetailsOpen = false;
  deliveryOpen = false;
  flowSaving = false;
  activeRow: DeliveryReportRow | null = null;
  activeBookingDetails: any = null;
  productDetailsLoading = false;

  deliveryAmount = 0;
  deliveryRentPart = 0;
  deliveryDepositPart = 0;
  deliveryMode: 'Cash' | 'Online' = 'Cash';
  deliveryTxn = '';

  ngOnInit() { this.load(); }

  load() {
    this.loading = true;
    this.api.get<unknown>('/report/today-delivery', {
      companyId: this.auth.currentUser()?.companyID,
      fromDate: this.fromDate,
      toDate: this.toDate
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
          productCode: String(pickField(row, 'productCode', 'ProductCode') ?? ''),
          productName: String(pickField(row, 'productName', 'ProductName') ?? '—'),
          deliveryDate: String(pickField(row, 'deliveryDate', 'DeliveryDate') ?? ''),
          pendingAmount: Number(
            pickField(row, 'pendingAmount', 'PendingAmount', 'remainingAmount', 'RemainingAmount') ?? 0
          ),
          paymentStatus: String(pickField(row, 'paymentStatus', 'PaymentStatus') ?? '—'),
          deliveryStatus: String(
            pickField(row, 'deliveryStatus', 'DeliveryStatus', 'bookingStatus', 'BookingStatus') ?? 'Booked'
          ),
          deliverySession: String(pickField(row, 'deliverySession', 'DeliverySession') ?? ''),
          returnSession: String(pickField(row, 'returnSession', 'ReturnSession') ?? '')
        }));
      },
      error: () => {
        this.loading = false;
        this.rows = [];
      }
    });
  }

  canDeliver(r: DeliveryReportRow): boolean {
    return r.deliveryStatus === 'Booked';
  }

  openDelivery(r: DeliveryReportRow) {
    this.activeRow = r;
    this.productDetailsOpen = false;
    this.activeBookingDetails = null;
    this.api.get<any>(`/booking/${r.bookingID}`).subscribe({
      next: res => {
        if (res.success && res.data) {
          this.activeBookingDetails = res.data;
          const b = res.data.header || res.data;
          const totalRent = Number(b.totalRentAmount || b.TotalRentAmount || 0);
          const advance = Number(b.advanceAmount || b.AdvanceAmount || 0);
          const deposit = Number(b.depositAmount || b.DepositAmount || 0);
          const remaining = Number(b.remainingAmount || b.RemainingAmount || 0);
          const rentDue = Math.max(0, totalRent - advance);

          this.deliveryRentPart = rentDue;
          this.deliveryDepositPart = deposit;
          this.deliveryAmount = remaining || (rentDue + deposit);
          this.deliveryMode = 'Cash';
          this.deliveryTxn = '';
          this.deliveryOpen = true;
        }
      }
    });
  }

  adjustDelivery(delta: number) {
    this.deliveryAmount = Math.max(0, this.deliveryAmount + delta);
  }

  confirmDelivery() {
    const r = this.activeRow;
    const user = this.auth.currentUser();
    if (!r || !user?.userID) return;

    this.flowSaving = true;

    this.api.get<any>(`/booking/${r.bookingID}`).subscribe({
      next: bRes => {
        if (!bRes.success || !bRes.data) {
          this.flowSaving = false;
          this.alert.toastError('Failed to fetch booking details');
          return;
        }
        const b = bRes.data.header || bRes.data;
        const totalRent = Number(b.totalRentAmount || b.TotalRentAmount || 0);
        const deposit = Number(b.depositAmount || b.DepositAmount || 0);
        const advance = Number(b.advanceAmount || b.AdvanceAmount || 0);

        const deliveryDateStr = String(pickField(b, 'deliveryDate', 'DeliveryDate') || r.deliveryDate || new Date().toISOString().substring(0, 10));
        const returnDateStr = String(pickField(b, 'returnDate', 'ReturnDate') || deliveryDateStr);

        const update = {
          bookingID: r.bookingID,
          deliveryDate: deliveryDateStr,
          returnDate: returnDateStr,
          rentDays: Number(pickField(b, 'rentDays', 'RentDays') ?? 1),
          totalRentAmount: totalRent,
          depositAmount: deposit,
          advanceAmount: advance + this.deliveryRentPart,
          remainingAmount: 0,
          totalAmount: Number(pickField(b, 'totalAmount', 'TotalAmount') ?? 0),
          bookingStatus: 'Delivered',
          paymentStatus: 'Paid',
          notes: 'Delivered via Delivery Report'
        };

        this.api.put('/booking', update).subscribe({
          next: upRes => {
            if (!upRes.success) {
              this.flowSaving = false;
              this.alert.toastError(upRes.message || 'Update failed');
              return;
            }
            this.api.post('/booking/payment', {
              companyID: user.companyID || 1,
              bookingID: r.bookingID,
              paymentType: 'Delivery Payment',
              paymentMode: this.deliveryMode,
              paymentAmount: this.deliveryAmount,
              transactionNo: this.deliveryTxn,
              notes: `Rent ${this.deliveryRentPart} + Deposit ${this.deliveryDepositPart}`,
              createdBy: user.userID
            }).subscribe({
              next: pr => {
                this.flowSaving = false;
                if (pr.success) {
                  this.alert.toastSuccess('Delivery payment recorded & product delivered!');
                  this.closeModal();
                  this.load();
                } else {
                  this.alert.toastError(pr.message || 'Payment failed');
                }
              },
              error: () => {
                this.flowSaving = false;
                this.alert.toastError('Payment request failed');
              }
            });
          },
          error: () => {
            this.flowSaving = false;
            this.alert.toastError('Delivery update failed');
          }
        });
      },
      error: () => {
        this.flowSaving = false;
        this.alert.toastError('Request failed');
      }
    });
  }

  openProductDetails(r: DeliveryReportRow) {
    this.activeRow = r;
    this.deliveryOpen = false;
    this.productDetailsOpen = true;
    this.productDetailsLoading = true;
    this.activeBookingDetails = null;

    this.api.get<any>(`/booking/${r.bookingID}`).subscribe({
      next: res => {
        this.productDetailsLoading = false;
        if (res.success && res.data) {
          this.activeBookingDetails = res.data;
        }
      },
      error: () => {
        this.productDetailsLoading = false;
      }
    });
  }

  closeModal() {
    this.deliveryOpen = false;
    this.productDetailsOpen = false;
    this.activeRow = null;
    this.activeBookingDetails = null;
  }

  productImageUrl(path?: string): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = environment.apiUrl.replace(/\/api\/?$/, '');
    return `${base}${path.startsWith('/') ? path : '/' + path}`;
  }

  formatProductNames(nameStr?: string): string {
    if (!nameStr) return '—';
    const names = nameStr.split(',').map(s => s.trim()).filter(Boolean);
    const unique = Array.from(new Set(names));
    return unique.join(', ');
  }

  getProductCodesList(codeStr?: string): string[] {
    if (!codeStr) return [];
    return codeStr.split(',').map(s => s.trim()).filter(Boolean);
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
