import { Component, OnInit, inject } from '@angular/core';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { BookingReturnService } from '../../../core/services/booking-return.service';
import { AlertService } from '../../../core/services/alert.service';
import { computeReturnRefund } from '../../../core/utils/booking-return.util';
import { normalizeRow, normalizeRows, pickField, pickId } from '../../../core/models/api.models';
import { environment } from '../../../../environments/environment';
import { CustomDatePickerComponent } from '../../../shared/components/custom-date-picker/custom-date-picker.component';

export interface ReturnReportRow {
  bookingID: number;
  bookingNo: string;
  customerName: string;
  productCode?: string;
  productName: string;
  returnDate: string;
  depositAmount: number;
  extraChargePerDay: number;
  extraDays: number;
  extraChargeAmount: number;
  damageDeductionAmount: number;
  finalRefundAmount: number;
  finalProfitAmount: number;
  bookingStatus: string;
  actualReturnDate?: string;
  deliverySession?: string;
  returnSession?: string;
}

@Component({
  selector: 'app-return-report',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, FormsModule, CustomDatePickerComponent],
  templateUrl: './return-report.component.html',
  styleUrl: './return-report.component.scss'
})
export class ReturnReportComponent implements OnInit {
  private api = inject(ApiService);
  private auth = inject(AuthService);
  private returnService = inject(BookingReturnService);
  private alert = inject(AlertService);

  rows: ReturnReportRow[] = [];
  fromDate = new Date().toISOString().substring(0, 10);
  toDate = new Date().toISOString().substring(0, 10);
  loading = false;
  message = '';
  messageType: 'success' | 'error' = 'success';

  returnOpen = false;
  productDetailsOpen = false;
  activeRow: ReturnReportRow | null = null;
  activeBookingDetails: any = null;
  productDetailsLoading = false;
  flowSaving = false;
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

  ngOnInit() {
    this.load();
    this.returnDate = this.today();
  }

  get pendingCount(): number {
    return this.rows.filter(r => this.canProcess(r)).length;
  }

  get completedCount(): number {
    return this.rows.filter(r => !this.canProcess(r)).length;
  }

  get pendingDepositTotal(): number {
    return this.rows.filter(r => this.canProcess(r)).reduce((s, r) => s + r.depositAmount, 0);
  }

  load() {
    this.loading = true;
    this.api.get<unknown>('/report/today-return', {
      companyId: this.auth.currentUser()?.companyID,
      fromDate: this.fromDate,
      toDate: this.toDate
    }).subscribe({
      next: r => {
        this.loading = false;
        if (r.success) {
          this.rows = normalizeRows(r.data).map(row => this.mapRow(row));
        } else {
          this.rows = [];
        }
      },
      error: () => {
        this.loading = false;
        this.rows = [];
        this.showMsg('Failed to load report', 'error');
      }
    });
  }

  private mapRow(row: Record<string, unknown>): ReturnReportRow {
    const r = normalizeRow(row);
    return {
      bookingID: pickId(r, 'bookingID', 'BookingID'),
      bookingNo: String(pickField<string>(r, 'bookingNo', 'BookingNo') ?? ''),
      customerName: String(pickField<string>(r, 'customerName', 'CustomerName') ?? ''),
      productCode: String(pickField<string>(r, 'productCode', 'ProductCode') ?? ''),
      productName: String(pickField<string>(r, 'productName', 'ProductName') ?? ''),
      returnDate: String(pickField(r, 'returnDate', 'ReturnDate') ?? ''),
      depositAmount: Number(
        pickField(r, 'depositAmount', 'DepositAmount', 'lineDepositAmount', 'LineDepositAmount') ?? 0
      ),
      extraChargePerDay: Number(pickField(r, 'extraChargePerDay', 'ExtraChargePerDay') ?? 150),
      extraDays: Number(pickField(r, 'extraDays', 'ExtraDays') ?? 0),
      extraChargeAmount: Number(pickField(r, 'extraChargeAmount', 'ExtraChargeAmount') ?? 0),
      damageDeductionAmount: Number(pickField(r, 'damageDeductionAmount', 'DamageDeductionAmount') ?? 0),
      finalRefundAmount: Number(pickField(r, 'finalRefundAmount', 'FinalRefundAmount') ?? 0),
      finalProfitAmount: Number(pickField(r, 'finalProfitAmount', 'FinalProfitAmount') ?? 0),
      bookingStatus: String(pickField<string>(r, 'bookingStatus', 'BookingStatus') ?? ''),
      actualReturnDate: pickField<string>(r, 'actualReturnDate', 'ActualReturnDate'),
      deliverySession: String(pickField<string>(r, 'deliverySession', 'DeliverySession') ?? ''),
      returnSession: String(pickField<string>(r, 'returnSession', 'ReturnSession') ?? '')
    };
  }

  canProcess(r: ReturnReportRow) {
    return r.bookingStatus === 'Delivered';
  }

  openProductDetails(r: ReturnReportRow) {
    this.activeRow = r;
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

  openReturn(r: ReturnReportRow) {
    this.activeRow = r;
    this.scheduledReturnDate = r.returnDate.substring(0, 10);
    this.returnDate = this.today();
    this.damageDeduction = 0;
    this.returnNotes = '';
    this.refundManual = false;
    this.returnMode = 'Cash';
    this.returnTxn = '';
    this.returnOpen = true;
    this.activeBookingDetails = null;
    this.recalcReturn();
    this.loadReturnDetail(r.bookingID);
  }

  private loadReturnDetail(bookingId: number) {
    this.api.get<any>(`/booking/${bookingId}`).subscribe({
      next: res => {
        if (res.success && res.data) {
          this.activeBookingDetails = res.data;
        }
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
    const r = this.activeRow;
    if (!r) return;
    const calc = computeReturnRefund(
      r.depositAmount,
      this.scheduledReturnDate,
      this.returnDate,
      r.extraChargePerDay,
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

  closeReturn() {
    this.returnOpen = false;
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

  confirmReturn() {
    const r = this.activeRow;
    if (!r) return;

    const notes = this.returnNotes.trim()
      ? `Return: ${this.returnNotes.trim()}${this.damageDeduction > 0 ? ` | Damage: ₹${this.damageDeduction}` : ''}`
      : this.damageDeduction > 0
        ? `Product damage deduction: ₹${this.damageDeduction}`
        : undefined;

    this.flowSaving = true;
    this.returnService
      .processReturn({
        bookingID: r.bookingID,
        actualReturnDate: this.returnDate,
        damageDeductionAmount: this.damageDeduction,
        returnNotes: notes,
        refundAmount: this.refundAmount,
        paymentMode: this.returnMode,
        transactionNo: this.returnTxn
      })
      .subscribe({
        next: res => {
          this.flowSaving = false;
          if (res.success) {
            this.showMsg(res.message || 'Return processed', 'success');
            this.closeReturn();
            this.load();
          } else {
            this.showMsg(res.message || 'Failed', 'error');
          }
        },
        error: err => {
          this.flowSaving = false;
          this.showMsg(err?.message || 'Return failed', 'error');
        }
      });
  }

  print() {
    window.print();
  }

  statusClass(s: string) {
    return {
      Delivered: 'delivered',
      Returned: 'returned',
      'Late Returned': 'late'
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
}
