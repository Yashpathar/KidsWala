import { Component, OnInit, inject } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { BookingReturnService } from '../../../core/services/booking-return.service';
import { AlertService } from '../../../core/services/alert.service';
import { computeReturnRefund } from '../../../core/utils/booking-return.util';
import { environment } from '../../../../environments/environment';
import { CustomDatePickerComponent } from '../../../shared/components/custom-date-picker/custom-date-picker.component';
import {
  asArray,
  extractErrorMessage,
  normalizeRow,
  pickField,
  pickId
} from '../../../core/models/api.models';

export interface BookingRow {
  bookingID: number;
  bookingNo: string;
  customerName: string;
  productCode?: string;
  productName?: string;
  bookingDate: string;
  deliveryDate: string;
  returnDate: string;
  totalRentAmount: number;
  depositAmount: number;
  extraChargePerDay: number;
  advanceAmount: number;
  remainingAmount: number;
  totalAmount: number;
  bookingStatus: string;
  paymentStatus: string;
  finalRefundAmount?: number;
  deliverySession?: string;
  returnSession?: string;
}

@Component({
  selector: 'app-booking-list',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, RouterLink, FormsModule, CustomDatePickerComponent],
  templateUrl: './booking-list.component.html',
  styleUrl: './booking-list.component.scss'
})
export class BookingListComponent implements OnInit {
  private api = inject(ApiService);
  private auth = inject(AuthService);
  private returnService = inject(BookingReturnService);
  private alert = inject(AlertService);

  bookings: BookingRow[] = [];
  search = '';
  status = '';
  fromDate = new Date().toISOString().substring(0, 10);
  toDate = new Date().toISOString().substring(0, 10);
  loading = false;
  message = '';
  messageType: 'success' | 'error' = 'success';

  deliveryOpen = false;
  returnOpen = false;
  productDetailsOpen = false;
  activeBooking: BookingRow | null = null;
  activeBookingDetails: any = null;
  productDetailsLoading = false;
  flowSaving = false;

  deliveryAmount = 0;
  deliveryRentPart = 0;
  deliveryDepositPart = 0;
  deliveryMode: 'Cash' | 'Online' = 'Cash';
  deliveryTxn = '';

  returnDate = '';
  scheduledReturnDate = '';
  refundAmount = 0;
  lateCharge = 0;
  extraDays = 0;
  damageDeduction = 0;
  returnNotes = '';
  returnIsEarly = false;
  returnIsLate = false;
  refundManual = false;
  returnMode: 'Cash' | 'Online' = 'Cash';
  returnTxn = '';

  get footerTotals() {
    return this.bookings.reduce(
      (a, b) => ({
        rent: a.rent + b.totalRentAmount,
        deposit: a.deposit + b.depositAmount,
        total: a.total + b.totalAmount,
        advance: a.advance + b.advanceAmount,
        due: a.due + b.remainingAmount
      }),
      { rent: 0, deposit: 0, total: 0, advance: 0, due: 0 }
    );
  }

  ngOnInit() {
    this.load();
    this.returnDate = this.today();
  }

  load() {
    this.loading = true;
    this.api.get<unknown>('/booking', {
      companyId: this.auth.currentUser()?.companyID,
      search: this.search,
      status: this.status || undefined,
      fromDate: this.fromDate || undefined,
      toDate: this.toDate || undefined
    }).subscribe({
      next: r => {
        this.loading = false;
        if (r.success) {
          this.bookings = asArray<unknown>(r.data).map(row => this.mapRow(row));
        } else {
          this.bookings = [];
          this.showMsg(r.message || 'Failed to load bookings', 'error');
        }
      },
      error: () => {
        this.loading = false;
        this.showMsg('Failed to load bookings', 'error');
      }
    });
  }

  clearDates() {
    this.fromDate = '';
    this.toDate = '';
    this.load();
  }

  private mapRow(row: unknown): BookingRow {
    const r = normalizeRow(row);
    return {
      bookingID: pickId(r, 'bookingID', 'BookingID'),
      bookingNo: String(pickField<string>(r, 'bookingNo', 'BookingNo') ?? ''),
      customerName: String(pickField<string>(r, 'customerName', 'CustomerName') ?? ''),
      productCode: String(pickField<string>(r, 'productCode', 'ProductCode') ?? ''),
      productName: String(pickField<string>(r, 'productName', 'ProductName') ?? ''),
      bookingDate: String(pickField(r, 'bookingDate', 'BookingDate') ?? ''),
      deliveryDate: String(pickField(r, 'deliveryDate', 'DeliveryDate') ?? ''),
      returnDate: String(pickField(r, 'returnDate', 'ReturnDate') ?? ''),
      totalRentAmount: Number(pickField(r, 'totalRentAmount', 'TotalRentAmount') ?? 0),
      depositAmount: Number(pickField(r, 'depositAmount', 'DepositAmount') ?? 0),
      extraChargePerDay: Number(pickField(r, 'extraChargePerDay', 'ExtraChargePerDay') ?? 150),
      advanceAmount: Number(pickField(r, 'advanceAmount', 'AdvanceAmount') ?? 0),
      remainingAmount: Number(pickField(r, 'remainingAmount', 'RemainingAmount') ?? 0),
      totalAmount: Number(pickField(r, 'totalAmount', 'TotalAmount') ?? 0),
      bookingStatus: String(pickField<string>(r, 'bookingStatus', 'BookingStatus') ?? ''),
      paymentStatus: String(pickField<string>(r, 'paymentStatus', 'PaymentStatus') ?? ''),
      finalRefundAmount: Number(pickField(r, 'finalRefundAmount', 'FinalRefundAmount') ?? 0) || undefined,
      deliverySession: String(pickField<string>(r, 'deliverySession', 'DeliverySession') ?? ''),
      returnSession: String(pickField<string>(r, 'returnSession', 'ReturnSession') ?? '')
    };
  }

  openProductDetails(b: BookingRow) {
    this.activeBooking = b;
    this.productDetailsOpen = true;
    this.productDetailsLoading = true;
    this.activeBookingDetails = null;

    this.api.get<any>(`/booking/${b.bookingID}`).subscribe({
      next: r => {
        this.productDetailsLoading = false;
        if (r.success && r.data) {
          this.activeBookingDetails = r.data;
        }
      },
      error: () => {
        this.productDetailsLoading = false;
      }
    });
  }

  openDelivery(b: BookingRow) {
    this.activeBooking = b;
    const rentDue = Math.max(0, b.totalRentAmount - b.advanceAmount);
    this.deliveryRentPart = rentDue;
    this.deliveryDepositPart = b.depositAmount;
    this.deliveryAmount = b.remainingAmount || rentDue + b.depositAmount;
    this.deliveryMode = 'Cash';
    this.deliveryTxn = '';
    this.deliveryOpen = true;
    this.activeBookingDetails = null;

    this.api.get<any>(`/booking/${b.bookingID}`).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.activeBookingDetails = r.data;
        }
      }
    });
  }

  openReturn(b: BookingRow) {
    this.activeBooking = b;
    this.scheduledReturnDate = (b.returnDate || '').substring(0, 10);
    this.returnDate = this.today();
    this.damageDeduction = 0;
    this.returnNotes = '';
    this.refundManual = false;
    this.returnMode = 'Cash';
    this.returnTxn = '';
    this.returnOpen = true;
    this.loadReturnDetail(b.bookingID);
  }

  private loadReturnDetail(bookingId: number) {
    this.api.get<{ header: unknown }>(`/booking/${bookingId}`).subscribe({
      next: r => {
        if (!r.success || !r.data?.header) return;
        const row = normalizeRow(r.data.header);
        if (this.activeBooking) {
          this.activeBooking.depositAmount = Number(
            pickField(row, 'depositAmount', 'DepositAmount') ?? this.activeBooking.depositAmount
          );
          this.activeBooking.extraChargePerDay = Number(
            pickField(row, 'extraChargePerDay', 'ExtraChargePerDay') ?? this.activeBooking.extraChargePerDay
          );
          this.activeBooking.returnDate = String(
            pickField(row, 'returnDate', 'ReturnDate') ?? this.activeBooking.returnDate
          );
          this.scheduledReturnDate = this.activeBooking.returnDate.substring(0, 10);
        }
        this.recalcReturn();
      }
    });
  }

  onReturnDateChange() {
    this.recalcReturn();
  }

  onDamageChange() {
    this.recalcReturn();
  }

  recalcReturn() {
    const b = this.activeBooking;
    if (!b) return;
    const calc = computeReturnRefund(
      b.depositAmount,
      this.scheduledReturnDate || b.returnDate.substring(0, 10),
      this.returnDate,
      b.extraChargePerDay,
      this.damageDeduction
    );
    this.lateCharge = calc.lateCharge;
    this.extraDays = calc.extraDays;
    this.returnIsEarly = calc.isEarly;
    this.returnIsLate = calc.isLate;
    this.damageDeduction = calc.damageDeduction;
    if (!this.refundManual) {
      this.refundAmount = calc.refundAmount;
    }
  }

  adjustDamage(delta: number) {
    this.damageDeduction = Math.max(0, this.damageDeduction + delta);
    this.refundManual = false;
    this.recalcReturn();
  }

  adjustRefund(delta: number) {
    this.refundManual = true;
    this.refundAmount = Math.max(0, this.refundAmount + delta);
  }

  closeModals() {
    this.deliveryOpen = false;
    this.returnOpen = false;
    this.activeBooking = null;
  }

  adjustDelivery(delta: number) {
    this.deliveryAmount = Math.max(0, this.deliveryAmount + delta);
  }

  confirmDelivery() {
    const b = this.activeBooking;
    const user = this.auth.currentUser();
    if (!b || !user?.userID) return;

    this.flowSaving = true;
    const update = {
      bookingID: b.bookingID,
      deliveryDate: b.deliveryDate,
      returnDate: b.returnDate,
      rentDays: 1,
      totalRentAmount: b.totalRentAmount,
      depositAmount: b.depositAmount,
      advanceAmount: b.advanceAmount + this.deliveryRentPart,
      remainingAmount: 0,
      totalAmount: b.totalAmount,
      bookingStatus: 'Delivered',
      paymentStatus: 'Paid',
      notes: ''
    };

    this.api.put('/booking', update).subscribe({
      next: r => {
        if (!r.success) {
          this.flowSaving = false;
          this.showMsg(r.message || 'Update failed', 'error');
          return;
        }
        this.api.post('/booking/payment', {
          companyID: user.companyID || 1,
          bookingID: b.bookingID,
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
              this.showMsg('Delivery payment recorded', 'success');
              this.closeModals();
              this.load();
            } else {
              this.showMsg(pr.message || 'Payment failed', 'error');
            }
          },
          error: () => {
            this.flowSaving = false;
            this.showMsg('Payment request failed', 'error');
          }
        });
      },
      error: () => {
        this.flowSaving = false;
        this.showMsg('Update request failed', 'error');
      }
    });
  }

  confirmReturn() {
    const b = this.activeBooking;
    if (!b) return;

    const notes = this.returnNotes.trim()
      ? `Return: ${this.returnNotes.trim()}${this.damageDeduction > 0 ? ` | Damage cut: ₹${this.damageDeduction}` : ''}`
      : this.damageDeduction > 0
        ? `Product damage deduction: ₹${this.damageDeduction}`
        : undefined;

    this.flowSaving = true;
    this.returnService
      .processReturn({
        bookingID: b.bookingID,
        actualReturnDate: this.returnDate,
        damageDeductionAmount: this.damageDeduction,
        returnNotes: notes,
        refundAmount: this.refundAmount,
        paymentMode: this.returnMode,
        transactionNo: this.returnTxn
      })
      .subscribe({
        next: r => {
          this.flowSaving = false;
          if (r.success) {
            this.showMsg(r.message || 'Return processed', 'success');
            this.closeModals();
            this.load();
          } else {
            this.showMsg(r.message || 'Refund payment failed', 'error');
          }
        },
        error: err => {
          this.flowSaving = false;
          this.showMsg(err?.message || 'Return failed', 'error');
        }
      });
  }

  async delete(row: BookingRow) {
    if (!row.bookingID) return;
    const confirmed = await this.alert.confirmDelete(
      `Delete Booking '${row.bookingNo}'?`,
      `Are you sure you want to delete booking ${row.bookingNo} for ${row.customerName}? This action cannot be undone.`
    );
    if (!confirmed) return;
    this.loading = true;
    this.api.delete(`/booking/${row.bookingID}`).subscribe({
      next: r => {
        this.loading = false;
        if (r.success) {
          this.alert.toastSuccess(r.message || 'Deleted successfully');
          this.load();
        } else {
          const msg = r.message || 'Delete failed: Booking is currently active or delivered.';
          this.alert.error('Cannot Delete Booking', msg);
        }
      },
      error: () => {
        this.loading = false;
        this.alert.error('Delete Failed', 'An error occurred while attempting to delete booking.');
      }
    });
  }

  canDeliver(b: BookingRow) {
    return b.bookingStatus === 'Booked';
  }

  canReturn(b: BookingRow) {
    return b.bookingStatus === 'Delivered';
  }

  private today() {
    return new Date().toISOString().substring(0, 10);
  }

  private showMsg(text: string, type: 'success' | 'error') {
    this.message = text;
    this.messageType = type;
    if (type === 'success') {
      this.alert.toastSuccess(text);
      setTimeout(() => { if (this.message === text) this.message = ''; }, 4000);
    } else {
      this.alert.toastError(text);
    }
  }

  statusClass(s: string) {
    return {
      Booked: 'booked',
      Delivered: 'delivered',
      Returned: 'returned',
      'Late Returned': 'late',
      Completed: 'completed',
      Cancelled: 'cancelled'
    }[s] || 'booked';
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

  productImageUrl(path?: string): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = environment.apiUrl.replace(/\/api\/?$/, '');
    return `${base}${path.startsWith('/') ? path : '/' + path}`;
  }
}
