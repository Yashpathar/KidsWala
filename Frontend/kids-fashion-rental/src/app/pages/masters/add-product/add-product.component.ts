import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { ProductApiService, CategoryApiService, SizeApiService, ColorApiService } from '../../../core/services/masters.service';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { AlertService } from '../../../core/services/alert.service';
import { asArray, pickId } from '../../../core/models/api.models';
import { environment } from '../../../../environments/environment';

export interface BatchItem {
  productCode: string;
  topCode: string;
  bottomCode: string;
  topSize: string;
  bottomSize: string;
  sizeID: number | null;
  colorID: number | null;
}

@Component({
  selector: 'app-add-product',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './add-product.component.html',
  styleUrl: './add-product.component.scss'
})
export class AddProductComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private productApi = inject(ProductApiService);
  private categoryApi = inject(CategoryApiService);
  private sizeApi = inject(SizeApiService);
  private colorApi = inject(ColorApiService);
  private api = inject(ApiService);
  private alert = inject(AlertService);
  auth = inject(AuthService);

  productId: number = 0;
  isEditMode: boolean = false;
  viewOnly: boolean = false;
  addTab: 'single' | 'batch' = 'single';

  categories: any[] = [];
  sizes: any[] = [];
  colors: any[] = [];
  branches: any[] = [];

  message: string = '';
  messageType: 'success' | 'error' = 'success';
  loading: boolean = false;
  saving: boolean = false;

  form: any = {};
  selectedSizeIds: number[] = [];

  batchForm: {
    productName: string;
    categoryID: number | null;
    colorID: number | null;
    ageGroup: string;
    rentAmount: number;
    depositAmount: number;
    discountPercent: number;
    standardRentalDays: number;
    extraChargePerDay: number;
    availableQuantity: number;
    description: string;
    productImage: string;
    isFullSet: boolean;
    codePrefix: string;
    items: BatchItem[];
  } = this.buildEmptyBatchForm();

  ngOnInit() {
    this.form = this.buildEmptyForm();
    this.batchForm = this.buildEmptyBatchForm();
    this.loadLookups();

    const paramId = this.route.snapshot.params['id'];
    const queryView = this.route.snapshot.queryParams['view'];
    if (paramId) {
      this.productId = Number(paramId);
      this.isEditMode = true;
      this.viewOnly = queryView === 'true';
      this.loadProductDetails(this.productId);
    }
  }

  buildEmptyForm() {
    return {
      productID: 0,
      companyID: this.auth.currentUser()?.companyID || 1,
      branchID: this.auth.currentUser()?.branchID || null,
      productCode: '',
      productName: '',
      categoryID: null as number | null,
      sizeID: null as number | null,
      colorID: null as number | null,
      ageGroup: '',
      rentAmount: 1400,
      depositAmount: 2000,
      discountPercent: 0,
      standardRentalDays: 4,
      extraChargePerDay: 150,
      availableQuantity: 1,
      description: '',
      productImage: '',
      isAvailable: true,
      isFullSet: true,
      topCode: '',
      topSize: '',
      bottomCode: '',
      bottomSize: ''
    };
  }

  formatCodePair(rawPrefix: string, sizeName: string) {
    let clean = (rawPrefix || 'BL-12').trim().toUpperCase().replace(/[-P]+$/g, '');
    if (!clean) clean = 'BL-12';
    const sz = String(sizeName || '02').trim();

    return {
      topCode: `${clean}-${sz}`,
      bottomCode: `${clean}P-${sz}`
    };
  }

  buildEmptyBatchForm() {
    const pair1 = this.formatCodePair('BL-12', '02');
    const pair2 = this.formatCodePair('BL-12', '04');

    return {
      productName: '',
      categoryID: null as number | null,
      colorID: null as number | null,
      ageGroup: '',
      rentAmount: 1400,
      depositAmount: 2000,
      discountPercent: 0,
      standardRentalDays: 4,
      extraChargePerDay: 150,
      availableQuantity: 1,
      description: '',
      productImage: '',
      isFullSet: true,
      codePrefix: 'BL-12',
      items: [
        { productCode: pair1.topCode, topCode: pair1.topCode, bottomCode: pair1.bottomCode, topSize: '02', bottomSize: '02', sizeID: null, colorID: null },
        { productCode: pair2.topCode, topCode: pair2.topCode, bottomCode: pair2.bottomCode, topSize: '04', bottomSize: '04', sizeID: null, colorID: null }
      ]
    };
  }

  showMsg(text: string, type: 'success' | 'error') {
    this.message = text;
    this.messageType = type;
    if (type === 'success') {
      this.alert.toastSuccess(text);
      setTimeout(() => { if (this.message === text) this.message = ''; }, 4000);
    } else {
      this.alert.toastError(text);
    }
  }

  loadLookups() {
    const cid = this.auth.currentUser()?.companyID;
    this.api.get<any>('/branch').subscribe(r => { if (r.success) this.branches = asArray(r.data); });
    this.categoryApi.list(cid).subscribe(r => {
      if (r.success) {
        this.categories = asArray(r.data);
        if (this.categories.length > 0) {
          if (!this.form.categoryID) this.form.categoryID = this.categories[0].categoryID;
          if (!this.batchForm.categoryID) this.batchForm.categoryID = this.categories[0].categoryID;
        }
      }
    });
    this.sizeApi.list(cid).subscribe(r => {
      if (r.success) {
        this.sizes = asArray(r.data).sort((a: any, b: any) => {
          const sA = String(a.sizeName ?? a.SizeName ?? '');
          const sB = String(b.sizeName ?? b.SizeName ?? '');
          const numA = parseFloat(sA);
          const numB = parseFloat(sB);
          if (!isNaN(numA) && !isNaN(numB)) return numA - numB;
          return sA.localeCompare(sB, undefined, { numeric: true, sensitivity: 'base' });
        });
      }
    });
    this.colorApi.list(cid).subscribe(r => {
      if (r.success) {
        this.colors = asArray(r.data);
        if (this.colors.length > 0) {
          if (!this.form.colorID) this.form.colorID = this.colors[0].colorID;
          if (!this.batchForm.colorID) this.batchForm.colorID = this.colors[0].colorID;
        }
      }
    });
    // Fetch products to compute next available prefix automatically
    this.productApi.list(cid, this.auth.currentUser()?.branchID).subscribe((r: any) => {
      if (r && r.success && r.data) {
        const prods = asArray(r.data);
        this.computeNextCodePrefix(prods);
      }
    });
  }

  computeNextCodePrefix(existingProducts: any[]) {
    let maxNum = 13;
    existingProducts.forEach(p => {
      const code = p.productCode || p.ProductCode || '';
      const match = code.match(/BL-(\d+)/i);
      if (match && match[1]) {
        const val = parseInt(match[1], 10);
        if (!isNaN(val) && val > maxNum) {
          maxNum = val;
        }
      }
    });
    this.batchForm.codePrefix = `BL-${maxNum + 1}`;
    this.autoGenerateBatchCodes();
  }

  generateNextAutoPrefix() {
    let currentPrefix = this.batchForm.codePrefix || 'BL-12';
    const match = currentPrefix.match(/(.*?)-(\d+)$/);
    if (match) {
      const prefixText = match[1];
      const nextVal = parseInt(match[2], 10) + 1;
      this.batchForm.codePrefix = `${prefixText}-${nextVal}`;
    } else {
      this.batchForm.codePrefix = `${currentPrefix}-01`;
    }
    this.autoGenerateBatchCodes();
    this.showMsg(`Generated Code Prefix: ${this.batchForm.codePrefix}`, 'success');
  }

  loadProductDetails(id: number) {
    this.loading = true;
    this.productApi.getById(id).subscribe({
      next: res => {
        this.loading = false;
        if (res.success && res.data) {
          const p = res.data;
          this.form = {
            productID: pickId(p, 'productID', 'ProductID'),
            companyID: p.companyID ?? p.CompanyID ?? 1,
            branchID: p.branchID ?? p.BranchID ?? null,
            productCode: p.productCode ?? p.ProductCode ?? '',
            productName: p.productName ?? p.ProductName ?? '',
            categoryID: p.categoryID ?? p.CategoryID ?? null,
            sizeID: p.sizeID ?? p.SizeID ?? null,
            colorID: p.colorID ?? p.ColorID ?? null,
            ageGroup: p.ageGroup ?? p.AgeGroup ?? '',
            rentAmount: Number(p.rentAmount ?? p.RentAmount ?? 0),
            depositAmount: Number(p.depositAmount ?? p.DepositAmount ?? 0),
            discountPercent: Number(p.discountPercent ?? p.DiscountPercent ?? 0),
            standardRentalDays: Number(p.standardRentalDays ?? p.StandardRentalDays ?? 4),
            extraChargePerDay: Number(p.extraChargePerDay ?? p.ExtraChargePerDay ?? 150),
            availableQuantity: Number(p.availableQuantity ?? p.AvailableQuantity ?? 1),
            description: p.description ?? p.Description ?? '',
            productImage: p.productImage ?? p.ProductImage ?? '',
            isAvailable: p.isAvailable !== false && p.isAvailable !== 0,
            isFullSet: !!(p.isFullSet ?? p.IsFullSet),
            topCode: p.topCode ?? p.TopCode ?? '',
            topSize: p.topSize ?? p.TopSize ?? '',
            bottomCode: p.bottomCode ?? p.BottomCode ?? '',
            bottomSize: p.bottomSize ?? p.BottomSize ?? ''
          };
          if (this.form.sizeID) {
            this.selectedSizeIds = [this.form.sizeID];
          }
        } else {
          this.showMsg('Failed to load product details', 'error');
        }
      },
      error: () => {
        this.loading = false;
        this.showMsg('Failed to load product details', 'error');
      }
    });
  }

  // Multi-Size Selection Logic
  isSizeSelected(sizeId: number): boolean {
    return this.selectedSizeIds.includes(sizeId);
  }

  toggleSizeSelection(s: any) {
    const sizeId = s.sizeID;
    const idx = this.selectedSizeIds.indexOf(sizeId);
    if (idx > -1) {
      this.selectedSizeIds.splice(idx, 1);
    } else {
      this.selectedSizeIds.push(sizeId);
    }
    this.generateItemsFromSelectedSizes();
  }

  selectAllSizes() {
    if (this.selectedSizeIds.length === this.sizes.length) {
      this.selectedSizeIds = [];
    } else {
      this.selectedSizeIds = this.sizes.map(s => s.sizeID);
    }
    this.generateItemsFromSelectedSizes();
  }

  generateItemsFromSelectedSizes() {
    if (!this.selectedSizeIds.length) return;

    if (this.selectedSizeIds.length > 1 && this.addTab === 'single') {
      this.addTab = 'batch';
    }

    const prefix = this.batchForm.codePrefix || this.form.productCode || 'BL-12';

    this.batchForm.items = this.selectedSizeIds.map(sizeId => {
      const sObj = this.sizes.find(sz => sz.sizeID === sizeId);
      const sName = sObj ? sObj.sizeName : String(sizeId);
      const codes = this.formatCodePair(prefix, sName);

      return {
        productCode: codes.topCode,
        topCode: codes.topCode,
        bottomCode: codes.bottomCode,
        topSize: sName,
        bottomSize: sName,
        sizeID: sizeId,
        colorID: this.batchForm.colorID || this.form.colorID || null
      };
    });
  }

  addBatchRow() {
    const count = this.batchForm.items.length + 1;
    const seq = count < 10 ? `0${count}` : `${count}`;
    const prefix = this.batchForm.codePrefix || 'BL-12';
    const codes = this.formatCodePair(prefix, seq);

    this.batchForm.items.push({
      productCode: codes.topCode,
      topCode: codes.topCode,
      bottomCode: codes.bottomCode,
      topSize: '',
      bottomSize: '',
      sizeID: null,
      colorID: null
    });
  }

  removeBatchRow(index: number) {
    if (this.batchForm.items.length > 1) {
      this.batchForm.items.splice(index, 1);
    }
  }

  autoGenerateBatchCodes() {
    const prefix = this.batchForm.codePrefix || 'BL-12';
    this.batchForm.items.forEach((item, idx) => {
      const sObj = this.sizes.find(s => s.sizeID === item.sizeID);
      const tag = sObj ? sObj.sizeName : (idx + 1 < 10 ? `0${idx + 1}` : `${idx + 1}`);
      const codes = this.formatCodePair(prefix, tag);

      item.productCode = codes.topCode;
      item.topCode = codes.topCode;
      item.bottomCode = codes.bottomCode;
    });
  }

  onFullSetToggle() {
    if (this.form.isFullSet) {
      const code = (this.form.productCode || 'ITEM').toUpperCase();
      const selectedSizeObj = this.sizes.find(s => s.sizeID === this.form.sizeID);
      const szName = selectedSizeObj ? selectedSizeObj.sizeName : (this.form.topSize || '12');

      if (!this.form.topCode) this.form.topCode = `${code}-TOP`;
      if (!this.form.topSize) this.form.topSize = szName;
      if (!this.form.bottomCode) this.form.bottomCode = `${code}-PNT`;
      if (!this.form.bottomSize) this.form.bottomSize = szName;
    }
  }

  onImageSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length) return;
    this.productApi.uploadImage(input.files[0]).subscribe(res => {
      if (res.success) {
        if (this.addTab === 'batch') {
          this.batchForm.productImage = res.data;
        } else {
          this.form.productImage = res.data;
        }
      } else {
        this.showMsg(res.message || 'Image upload failed', 'error');
      }
    });
  }

  private validate(): string | null {
    if (!String(this.form.productCode || '').trim()) return 'Product code is required';
    if (!String(this.form.productName || '').trim()) return 'Product name is required';
    if (!this.form.categoryID) return 'Category is required';
    if (!this.form.sizeID) return 'Size is required';
    if (!this.form.colorID) return 'Color is required';
    return null;
  }

  private preparePayload() {
    return {
      productID: Number(this.form.productID || 0),
      companyID: Number(this.auth.currentUser()?.companyID || 1),
      branchID: this.form.branchID ? Number(this.form.branchID) : (this.auth.currentUser()?.branchID || null),
      productCode: String(this.form.productCode).trim(),
      productName: String(this.form.productName).trim(),
      categoryID: Number(this.form.categoryID),
      sizeID: Number(this.form.sizeID),
      colorID: Number(this.form.colorID),
      ageGroup: this.form.ageGroup || '',
      rentAmount: Number(this.form.rentAmount || 0),
      depositAmount: Number(this.form.depositAmount || 0),
      discountPercent: Number(this.form.discountPercent || 0),
      standardRentalDays: Number(this.form.standardRentalDays || 4),
      extraChargePerDay: Number(this.form.extraChargePerDay || 150),
      availableQuantity: Number(this.form.availableQuantity || 1),
      description: this.form.description || '',
      productImage: this.form.productImage || '',
      isAvailable: !!this.form.isAvailable,
      isFullSet: !!this.form.isFullSet,
      topCode: this.form.topCode || '',
      topSize: this.form.topSize || '',
      bottomCode: this.form.bottomCode || '',
      bottomSize: this.form.bottomSize || ''
    };
  }

  save() {
    if (this.addTab === 'batch' && !this.form.productID) {
      this.saveBatch();
      return;
    }

    const err = this.validate();
    if (err) {
      this.showMsg(err, 'error');
      return;
    }
    const payload = this.preparePayload();
    const isUpdate = payload.productID > 0;
    this.saving = true;

    const req = isUpdate ? this.productApi.update(payload) : this.productApi.create(payload);
    req.subscribe({
      next: res => {
        this.saving = false;
        if (res.success) {
          this.showMsg(res.message || 'Saved successfully', 'success');
          setTimeout(() => this.router.navigate(['/masters/product']), 1000);
        } else {
          this.showMsg(res.message || 'Save failed', 'error');
        }
      },
      error: () => {
        this.saving = false;
        this.showMsg('Save request failed', 'error');
      }
    });
  }

  saveBatch() {
    const prodName = (this.batchForm.productName || this.form.productName || '').trim();
    if (!prodName) {
      this.showMsg('Product Name is required', 'error');
      return;
    }
    const catID = this.batchForm.categoryID || this.form.categoryID;
    if (!catID) {
      this.showMsg('Category is required', 'error');
      return;
    }
    if (!this.batchForm.items.length) {
      this.showMsg('Please select at least one size or add an item row', 'error');
      return;
    }

    const companyID = Number(this.auth.currentUser()?.companyID || 1);
    const defaultColorID = this.batchForm.colorID || this.form.colorID || (this.colors[0]?.colorID ?? 1);
    const defaultSizeID = this.sizes[0]?.sizeID ?? 1;

    const payloads = this.batchForm.items.map(item => {
      const pCode = (item.productCode || item.topCode || 'ITEM').trim();
      const szObj = this.sizes.find(s => s.sizeID === item.sizeID);
      const szName = szObj ? szObj.sizeName : (item.topSize || '12');

      return {
        productID: 0,
        companyID: companyID,
        branchID: this.form.branchID ? Number(this.form.branchID) : (this.auth.currentUser()?.branchID || null),
        productCode: pCode,
        productName: prodName,
        categoryID: Number(catID),
        sizeID: Number(item.sizeID || defaultSizeID),
        colorID: Number(item.colorID || defaultColorID),
        ageGroup: this.batchForm.ageGroup || this.form.ageGroup || '',
        rentAmount: Number(this.batchForm.rentAmount || this.form.rentAmount || 0),
        depositAmount: Number(this.batchForm.depositAmount || this.form.depositAmount || 0),
        discountPercent: Number(this.batchForm.discountPercent || this.form.discountPercent || 0),
        standardRentalDays: Number(this.batchForm.standardRentalDays || 4),
        extraChargePerDay: Number(this.batchForm.extraChargePerDay || 150),
        availableQuantity: Number(this.batchForm.availableQuantity || 1),
        description: this.batchForm.description || this.form.description || '',
        productImage: this.batchForm.productImage || this.form.productImage || '',
        isAvailable: true,
        isFullSet: !!this.batchForm.isFullSet,
        topCode: item.topCode || pCode,
        topSize: item.topSize || szName,
        bottomCode: item.bottomCode || `${pCode}-P`,
        bottomSize: item.bottomSize || szName
      };
    });

    this.saving = true;
    const reqs = payloads.map(p => this.productApi.create(p));

    forkJoin(reqs).subscribe({
      next: (results) => {
        this.saving = false;
        const successCount = results.filter(r => r.success).length;
        const failedResults = results.filter(r => !r.success);

        if (successCount > 0 && failedResults.length === 0) {
          this.showMsg(`Successfully created all ${successCount} batch products!`, 'success');
          setTimeout(() => this.router.navigate(['/masters/product']), 1000);
        } else if (successCount > 0) {
          const firstErr = failedResults[0]?.message || 'Some items failed';
          this.showMsg(`Created ${successCount} products. ${failedResults.length} failed (${firstErr})`, 'error');
        } else {
          const firstErr = failedResults[0]?.message || 'Product code already exists in database. Please click Auto-Code to generate new codes.';
          this.showMsg(`Batch creation failed: ${firstErr}`, 'error');
        }
      },
      error: (err) => {
        this.saving = false;
        const msg = err?.error?.message || err?.message || 'Failed to save batch products';
        this.showMsg(`Batch creation error: ${msg}`, 'error');
      }
    });
  }

  imageUrl(path?: string): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = environment.apiUrl.replace(/\/api\/?$/, '');
    return `${base}${path.startsWith('/') ? path : '/' + path}`;
  }
}
