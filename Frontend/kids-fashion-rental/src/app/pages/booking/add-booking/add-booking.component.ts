import { Component, OnDestroy, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { ProductApiService, SizeApiService } from '../../../core/services/masters.service';
import {
  AvailabilityResult,
  BookingItem,
  Product,
  asArray,
  extractErrorMessage,
  normalizeRow,
  parseAvailability,
  pickField,
  pickId
} from '../../../core/models/api.models';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-add-booking',
  standalone: true,
  imports: [ReactiveFormsModule, FormsModule, CurrencyPipe, DatePipe, RouterLink],
  templateUrl: './add-booking.component.html',
  styleUrl: './add-booking.component.scss',
  host: { class: 'add-booking-host' }
})
export class AddBookingComponent implements OnInit, OnDestroy {
  private fb = inject(FormBuilder);
  private api = inject(ApiService);
  private productApi = inject(ProductApiService);
  private sizeApi = inject(SizeApiService);
  private router = inject(Router);
  private destroy$ = new Subject<void>();
  private productSearch$ = new Subject<string>();
  private mobileLookup$ = new Subject<string>();
  auth = inject(AuthService);

  customerFound = false;
  showNewCustomer = false;
  customerLookupLoading = false;
  allProducts: Product[] = [];
  productSuggestions: Product[] = [];
  selectedProduct: (Product & { productImage?: string; availableQuantity?: number }) | null = null;
  availability: AvailabilityResult | null = null;
  items: BookingItem[] = [];
  saving = false;
  message = '';
  messageType: 'success' | 'error' = 'success';

  productSearch = '';
  showSuggestions = false;
  discountPercent = 0;
  itemQty = 1;
  duplicateProductMsg = '';
  /** Highlights row/card briefly after add */
  lastAddedProductId: number | null = null;

  selectedIsFullSet = false;
  selectedTopCode = '';
  selectedTopSize = '';
  selectedBottomCode = '';
  selectedBottomSize = '';

  sizesMasterList: any[] = [];
  sizeValidationError = '';

  /** partial = 50% rent advance; full = pay all rent at booking */
  payMode: 'partial' | 'full' = 'partial';
  advanceAmount = 0;
  advanceManual = false;
  bookingPaymentMode: 'Cash' | 'Online' = 'Cash';
  extraChargePerDay = 150;

  customerForm = this.fb.group({
    customerID: [null as number | null],
    fullName: ['', Validators.required],
    contactNo1: ['', [Validators.required, Validators.minLength(10)]],
    contactNo2: [''],
    address: [''],
    city: ['Ahmedabad'],
    notes: ['']
  });

  bookingForm = this.fb.group({
    bookingDate: [this.today(), Validators.required],
    deliveryDate: [this.today(), Validators.required],
    returnDate: [this.addDays(4), Validators.required],
    bookingStatus: ['Booked'],
    paymentStatus: ['Partial'],
    notes: ['']
  });

  ngOnInit() {
    const companyId = this.auth.currentUser()?.companyID;
    this.productApi.list(companyId).subscribe(r => {
      if (r.success) {
        this.allProducts = asArray<unknown>(r.data).map(p => this.mapProduct(p));
      }
    });

    this.sizeApi.list(companyId).subscribe(r => {
      if (r.success) {
        this.sizesMasterList = asArray(r.data);
      }
    });

    this.bookingForm.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(() => {
      this.checkAvailabilityIfReady();
      this.recalcAdvance();
    });

    this.productSearch$.pipe(debounceTime(350), distinctUntilChanged(), takeUntil(this.destroy$)).subscribe(q => {
      this.onProductQuery(q);
    });

    this.mobileLookup$.pipe(debounceTime(400), distinctUntilChanged(), takeUntil(this.destroy$)).subscribe(mobile => {
      if (mobile.length === 10) this.lookupCustomerByPhone(mobile);
    });

    this.recalcAdvance();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onProductInput() {
    this.productSearch$.next(this.productSearch.trim());
  }

  private onProductQuery(q: string) {
    this.duplicateProductMsg = '';
    if (!q) {
      this.productSuggestions = [];
      this.showSuggestions = false;
      this.selectedProduct = null;
      this.availability = null;
      return;
    }
    const lower = q.toLowerCase();
    const matches = this.allProducts.filter(
      p =>
        p.productCode?.toLowerCase().includes(lower) ||
        p.productName?.toLowerCase().includes(lower)
    );
    this.productSuggestions = matches.filter(p => !this.isProductInBooking(p)).slice(0, 8);
    this.showSuggestions = matches.length > 0;

    const exact = this.allProducts.find(
      p => p.productCode?.toLowerCase() === lower || p.productName?.toLowerCase() === lower
    );
    if (exact) {
      if (this.isProductInBooking(exact)) {
        this.duplicateProductMsg = `${exact.productCode} is already in this booking.`;
        this.selectedProduct = null;
        this.availability = null;
        return;
      }
      this.selectProduct(exact);
    }
  }

  isProductInBooking(p: Product | BookingItem): boolean {
    const id = pickId(p, 'productID', 'ProductID');
    if (!id) return false;
    return this.items.some(i => i.productID === id);
  }

  selectProduct(p: Product) {
    if (this.isProductInBooking(p)) {
      this.duplicateProductMsg = `${p.productCode} is already added — each product once per booking.`;
      this.selectedProduct = null;
      this.availability = null;
      return;
    }
    this.duplicateProductMsg = '';
    this.selectedProduct = this.mapProduct(p);
    this.productSearch = p.productCode;
    this.showSuggestions = false;
    this.discountPercent = Number(p.discountPercent) || 0;
    this.extraChargePerDay = Number(p.extraChargePerDay) || 150;

    this.selectedIsFullSet = !!(p.isFullSet ?? (p as any).IsFullSet);
    this.selectedTopCode = p.topCode || p.productCode || '';
    this.selectedTopSize = p.topSize || p.size || '';
    this.selectedBottomCode = p.bottomCode || (p.productCode ? `${p.productCode}-PNT` : '');
    this.selectedBottomSize = p.bottomSize || p.size || '';

    this.onPairSizeChange();
    this.checkAvailability();
  }

  get computedTopCode(): string {
    if (!this.selectedProduct) return '';
    if (this.selectedTopCode && this.selectedTopCode !== this.selectedProduct.productCode) {
      return this.selectedTopCode;
    }
    const base = this.selectedProduct.productCode;
    const sz = (this.selectedTopSize || this.selectedProduct.size || '12').trim();
    return `${base}-${sz}`;
  }

  get computedBottomCode(): string {
    if (!this.selectedProduct) return '';
    if (this.selectedBottomCode && !this.selectedBottomCode.endsWith('-PNT')) {
      return this.selectedBottomCode;
    }
    const base = this.selectedProduct.productCode;
    const sz = (this.selectedBottomSize || this.selectedProduct.size || '12').trim();
    return `${base}P-${sz}`;
  }

  get isPantInStock(): boolean {
    if (!this.selectedProduct || !this.selectedIsFullSet) return true;
    const btmSz = (this.selectedBottomSize || '').trim();
    if (!btmSz) return true;

    const prodBtmSz = (this.selectedProduct.bottomSize || this.selectedProduct.size || '').trim();
    if (prodBtmSz && prodBtmSz.toLowerCase() === btmSz.toLowerCase()) return true;

    return this.allProducts.some(ap =>
      (ap.productCode === this.selectedProduct?.productCode || ap.productName === this.selectedProduct?.productName) &&
      (ap.size?.toLowerCase() === btmSz.toLowerCase() || ap.bottomSize?.toLowerCase() === btmSz.toLowerCase())
    );
  }

  onPairSizeChange() {
    this.sizeValidationError = '';
    if (this.selectedIsFullSet && !this.isPantInStock) {
      const btmSz = (this.selectedBottomSize || '').trim();
      this.sizeValidationError = `⚠️ Warning: Pant Size "${btmSz}" (${this.computedBottomCode}) is NOT added in product stock for this item!`;
    }
  }

  private mapProduct(row: unknown): Product & { productImage?: string; availableQuantity?: number } {
    const r = normalizeRow(row);
    return {
      productID: pickId(r, 'productID', 'ProductID'),
      productCode: String(pickField<string>(r, 'productCode', 'ProductCode') ?? ''),
      productName: String(pickField<string>(r, 'productName', 'ProductName') ?? ''),
      categoryName: String(pickField<string>(r, 'categoryName', 'CategoryName') ?? ''),
      size: String(pickField<string>(r, 'size', 'Size') ?? ''),
      color: String(pickField<string>(r, 'color', 'Color') ?? ''),
      rentAmount: Number(pickField(r, 'rentAmount', 'RentAmount') ?? 0),
      depositAmount: Number(pickField(r, 'depositAmount', 'DepositAmount') ?? 0),
      discountPercent: Number(pickField(r, 'discountPercent', 'DiscountPercent') ?? 0),
      standardRentalDays: Number(pickField(r, 'standardRentalDays', 'StandardRentalDays') ?? 4),
      extraChargePerDay: Number(pickField(r, 'extraChargePerDay', 'ExtraChargePerDay') ?? 150),
      productImage: String(pickField<string>(r, 'productImage', 'ProductImage') ?? ''),
      availableQuantity: Number(pickField(r, 'availableQuantity', 'AvailableQuantity') ?? 1),
      isFullSet: !!(pickField(r, 'isFullSet', 'IsFullSet') ?? false),
      topCode: String(pickField<string>(r, 'topCode', 'TopCode') ?? ''),
      topSize: String(pickField<string>(r, 'topSize', 'TopSize') ?? ''),
      bottomCode: String(pickField<string>(r, 'bottomCode', 'BottomCode') ?? ''),
      bottomSize: String(pickField<string>(r, 'bottomSize', 'BottomSize') ?? '')
    };
  }

  productImageUrl(path?: string): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = environment.apiUrl.replace(/\/api\/?$/, '');
    return `${base}${path.startsWith('/') ? path : '/' + path}`;
  }

  get rentDays(): number {
    const d = this.bookingForm.value.deliveryDate;
    const r = this.bookingForm.value.returnDate;
    if (!d || !r) return 0;
    return Math.max(1, Math.ceil((new Date(r).getTime() - new Date(d).getTime()) / 86400000) + 1);
  }

  /** Standard rental days from added products (default 4) */
  get standardDays(): number {
    if (!this.items.length) {
      return this.selectedProduct?.standardRentalDays ?? 4;
    }
    const days = this.items.map(i => {
      const p = this.allProducts.find(
        ap => ap.productCode === i.productCode || pickId(ap, 'productID', 'ProductID') === i.productID
      );
      return Number(p?.standardRentalDays) || 4;
    });
    return Math.max(...days, 4);
  }

  /** Days beyond product standard package */
  get extraDays(): number {
    return Math.max(0, this.rentDays - this.standardDays);
  }

  get effectiveExtraChargePerDay(): number {
    if (!this.items.length) {
      return this.selectedProduct?.extraChargePerDay ?? this.extraChargePerDay;
    }
    const rates = this.items.map(i => {
      const p = this.allProducts.find(
        ap => ap.productCode === i.productCode || pickId(ap, 'productID', 'ProductID') === i.productID
      );
      return Number(p?.extraChargePerDay) || this.extraChargePerDay;
    });
    return Math.max(...rates, this.extraChargePerDay);
  }

  get calc() {
    const totalRent = this.items.reduce((s, i) => s + i.finalRentAmount, 0);
    const totalDeposit = this.items.reduce((s, i) => s + i.depositAmount, 0);
    const discountAmt = this.items.reduce(
      (s, i) => s + (i.rentAmount * i.discountPercent) / 100,
      0
    );
    const extraCharge = this.extraDays * this.effectiveExtraChargePerDay;
    const rentWithExtra = totalRent + extraCharge;
    const grandTotal = rentWithExtra + totalDeposit;
    const defaultAdvance = this.payMode === 'full' ? rentWithExtra : rentWithExtra * 0.5;
    const advance = this.advanceManual ? this.advanceAmount : defaultAdvance;
    const dueAtDelivery = Math.max(0, rentWithExtra - advance) + totalDeposit;
    return {
      totalRent,
      totalDeposit,
      discountAmt,
      extraCharge,
      rentWithExtra,
      grandTotal,
      advance,
      dueAtDelivery,
      bookingPayNow: advance
    };
  }

  get totals() {
    return this.calc;
  }

  recalcAdvance() {
    if (!this.advanceManual) {
      this.advanceAmount = this.calc.advance;
    }
  }

  setPayMode(mode: 'partial' | 'full') {
    this.payMode = mode;
    this.advanceManual = false;
    this.recalcAdvance();
    this.bookingForm.patchValue({
      paymentStatus: mode === 'full' ? 'Paid' : 'Partial'
    });
  }

  adjustAdvance(delta: number) {
    this.advanceManual = true;
    this.advanceAmount = Math.max(0, (this.advanceAmount || this.calc.advance) + delta);
    this.bookingForm.patchValue({
      paymentStatus: this.advanceAmount >= this.calc.rentWithExtra ? 'Paid' : 'Partial'
    });
  }

  /** Keep digits only; use last 10 for Indian mobile */
  normalizeMobile(value: string): string {
    const digits = (value || '').replace(/\D/g, '');
    return digits.length > 10 ? digits.slice(-10) : digits;
  }

  onMobileInput() {
    const raw = String(this.customerForm.get('contactNo1')?.value ?? '');
    const mobile = this.normalizeMobile(raw);
    if (mobile !== raw) {
      this.customerForm.patchValue({ contactNo1: mobile }, { emitEvent: false });
    }
    if (mobile.length < 10) {
      this.customerFound = false;
      this.showNewCustomer = mobile.length > 0;
      if (mobile.length === 0) {
        this.showNewCustomer = false;
        this.customerForm.patchValue({ customerID: null }, { emitEvent: false });
      }
      return;
    }
    this.mobileLookup$.next(mobile);
  }

  lookupCustomerByPhone(mobileArg?: string) {
    const mobile = mobileArg ?? this.normalizeMobile(String(this.customerForm.value.contactNo1 ?? ''));
    if (mobile.length < 10) {
      this.customerFound = false;
      this.showNewCustomer = false;
      this.customerLookupLoading = false;
      return;
    }
    const companyId = this.auth.currentUser()?.companyID;
    this.customerLookupLoading = true;
    this.api.get<unknown>('/master/customers/by-mobile', { mobile, companyId }).subscribe({
      next: r => {
        this.customerLookupLoading = false;
        if (r.success && r.data) {
          const row = normalizeRow(r.data);
          this.customerFound = true;
          this.showNewCustomer = false;
          this.customerForm.patchValue(
            {
              customerID: pickId(row, 'customerID', 'CustomerID'),
              fullName: String(pickField<string>(row, 'fullName', 'FullName') ?? ''),
              contactNo1: this.normalizeMobile(String(pickField<string>(row, 'contactNo1', 'ContactNo1') ?? mobile)),
              contactNo2: String(pickField<string>(row, 'contactNo2', 'ContactNo2') ?? ''),
              address: String(pickField<string>(row, 'address', 'Address') ?? ''),
              city: String(pickField<string>(row, 'city', 'City') ?? 'Ahmedabad'),
              notes: String(pickField<string>(row, 'notes', 'Notes') ?? '')
            },
            { emitEvent: false }
          );
        } else {
          this.customerFound = false;
          this.showNewCustomer = true;
          this.customerForm.patchValue({ customerID: null }, { emitEvent: false });
        }
      },
      error: () => {
        this.customerLookupLoading = false;
        this.customerFound = false;
        this.showNewCustomer = true;
      }
    });
  }

  checkAvailability() {
    if (!this.selectedProduct) return;
    const { deliveryDate, returnDate } = this.bookingForm.value;
    this.api.get<AvailabilityResult>('/booking/check-availability', {
      productCode: this.selectedProduct.productCode,
      deliveryDate,
      returnDate
    }).subscribe(r => {
      this.availability = parseAvailability(r.data) ?? {
        success: 0,
        message: r.message || 'Could not check availability'
      };
    });
  }

  checkAvailabilityIfReady() {
    if (this.selectedProduct) this.checkAvailability();
  }

  addItem() {
    if (!this.selectedProduct || this.availability?.success === 0) return;
    if (this.selectedIsFullSet && this.sizeValidationError.startsWith('⚠️ Validation Error:')) {
      this.showMsg(this.sizeValidationError, 'error');
      return;
    }
    const p = this.selectedProduct;
    const productId = pickId(p, 'productID', 'ProductID');
    if (!productId) {
      this.showMsg('Invalid product', 'error');
      return;
    }
    if (this.isProductInBooking(p)) {
      this.showMsg(`${p.productCode} is already in this booking`, 'error');
      return;
    }
    const finalRent =
      (p.rentAmount - (p.rentAmount * this.discountPercent) / 100) * this.itemQty;
    const deposit = p.depositAmount * this.itemQty;

    if (this.selectedIsFullSet && !this.isPantInStock) {
      this.showMsg(`Pant Code ${this.computedBottomCode} (Size ${this.selectedBottomSize}) is not added in product stock!`, 'error');
      return;
    }

    const displaySize = this.selectedIsFullSet
      ? `Blazer: ${this.selectedTopSize || p.size || '-'} (${this.computedTopCode}) | Pant: ${this.selectedBottomSize || p.size || '-'} (${this.computedBottomCode})`
      : p.size;

    this.items.push({
      productID: productId,
      productCode: p.productCode,
      productName: p.productName,
      size: displaySize,
      color: p.color,
      rentAmount: p.rentAmount * this.itemQty,
      depositAmount: deposit,
      discountPercent: this.discountPercent,
      finalRentAmount: finalRent,
      productImage: p.productImage || '',
      isFullSet: this.selectedIsFullSet,
      topCode: this.computedTopCode,
      topSize: this.selectedTopSize || p.size,
      bottomCode: this.computedBottomCode,
      bottomSize: this.selectedBottomSize || p.size
    });
    this.lastAddedProductId = productId;
    setTimeout(() => {
      if (this.lastAddedProductId === productId) this.lastAddedProductId = null;
    }, 700);
    this.selectedProduct = null;
    this.productSearch = '';
    this.availability = null;
    this.duplicateProductMsg = '';
    this.discountPercent = 0;
    this.itemQty = 1;
    this.advanceManual = false;
    this.recalcAdvance();
  }

  removeItem(i: number) {
    this.items.splice(i, 1);
    this.duplicateProductMsg = '';
    this.recalcAdvance();
  }

  itemLineTotal(item: BookingItem): number {
    return item.finalRentAmount + item.depositAmount;
  }

  saveBooking() {
    this.customerForm.markAllAsTouched();
    if (!this.customerForm.value.contactNo1 || !this.customerForm.value.fullName) {
      this.showMsg('Enter mobile number and customer name', 'error');
      return;
    }
    if (!this.items.length) {
      this.showMsg('Add at least one product', 'error');
      return;
    }
    const user = this.auth.currentUser();
    if (!user?.userID) {
      this.showMsg('Session expired. Please login again.', 'error');
      return;
    }

    this.saving = true;
    const saveBookingData = (customerId: number) => {
    const b = this.bookingForm.value;
    const c = this.calc;
    const payload = {
      companyID: user.companyID || 1,
      customerID: customerId,
      bookingCreatedBy: user.userID,
      bookingDate: b.bookingDate,
      startDate: b.deliveryDate,
      endDate: b.returnDate,
      deliveryDate: b.deliveryDate,
      returnDate: b.returnDate,
      rentDays: this.rentDays,
      totalRentAmount: c.rentWithExtra,
      discountAmount: c.discountAmt,
      depositAmount: c.totalDeposit,
      advanceAmount: c.advance,
      remainingAmount: c.dueAtDelivery,
      totalAmount: c.grandTotal,
      extraChargePerDay: this.effectiveExtraChargePerDay,
      extraDays: this.extraDays,
      extraChargeAmount: c.extraCharge,
      bookingStatus: b.bookingStatus || 'Booked',
      paymentStatus: b.paymentStatus || 'Partial',
      notes: this.customerForm.value.notes || b.notes,
      items: this.items
    };

    this.api.post<{ id?: number; bookingNo?: string }>('/booking', payload).subscribe({
      next: r => {
        if (r.success) {
          const data = normalizeRow(r.data);
          const bookingId = pickId(data, 'id', 'ID', 'bookingID', 'BookingID');
          const payPayload = {
            companyID: user.companyID || 1,
            bookingID: bookingId,
            paymentType: 'Booking Advance',
            paymentMode: this.bookingPaymentMode,
            paymentAmount: c.advance,
            transactionNo: '',
            notes: `Booking payment (${this.payMode})`,
            createdBy: user.userID
          };
          if (bookingId && c.advance > 0) {
            this.api.post('/booking/payment', payPayload).subscribe({
              complete: () => this.afterSave(r.message)
            });
          } else {
            this.afterSave(r.message);
          }
        } else {
          this.saving = false;
          this.showMsg(r.message?.trim() || extractErrorMessage(r.data) || 'Save failed', 'error');
        }
      },
      error: () => {
        this.saving = false;
        this.showMsg('Save request failed', 'error');
      }
    });
    };

    const existingId = Number(this.customerForm.value.customerID);
    if (existingId) {
      saveBookingData(existingId);
      return;
    }
    const cf = this.customerForm.value;
    this.api.post<{ id?: number }>('/master/customers', {
      companyID: user.companyID || 1,
      fullName: cf.fullName,
      contactNo1: cf.contactNo1,
      contactNo2: cf.contactNo2,
      address: cf.address,
      city: cf.city,
      notes: cf.notes
    }).subscribe({
      next: cr => {
        if (!cr.success) {
          this.saving = false;
          this.showMsg(cr.message || 'Could not create customer', 'error');
          return;
        }
        const newId = pickId(cr.data, 'id', 'ID', 'customerID', 'CustomerID');
        if (!newId) {
          this.saving = false;
          this.showMsg('Customer saved but ID missing. Contact support.', 'error');
          return;
        }
        this.customerForm.patchValue({ customerID: newId }, { emitEvent: false });
        saveBookingData(newId);
      },
      error: () => {
        this.saving = false;
        this.showMsg('Customer save failed', 'error');
      }
    });
  }

  private afterSave(msg?: string) {
    this.saving = false;
    this.showMsg(msg || 'Booking saved successfully', 'success');
    setTimeout(() => this.router.navigate(['/booking/list']), 1200);
  }

  private showMsg(text: string, type: 'success' | 'error') {
    this.message = text;
    this.messageType = type;
  }

  private today() {
    return new Date().toISOString().substring(0, 10);
  }

  private addDays(n: number) {
    const d = new Date();
    d.setDate(d.getDate() + n);
    return d.toISOString().substring(0, 10);
  }
}
