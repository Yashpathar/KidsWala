import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CurrencyPipe } from '@angular/common';
import { forkJoin } from 'rxjs';
import { ProductApiService, CategoryApiService, SizeApiService, ColorApiService } from '../../../core/services/masters.service';
import { AuthService } from '../../../core/services/auth.service';
import { asArray, pickId } from '../../../core/models/api.models';
import { environment } from '../../../../environments/environment';

import { RouterLink } from '@angular/router';

export interface BatchItem {
  productCode: string;
  topCode: string;
  bottomCode: string;
  topSize: string;
  bottomSize: string;
  sizeID: number | null;
  colorID: number | null;
}

export interface ProductGroup {
  groupCode: string;
  productName: string;
  categoryName: string;
  colorName: string;
  colorCode: string;
  productImage: string;
  isFullSet: boolean;
  ageGroup: string;
  rentAmount: number;
  depositAmount: number;
  totalQuantity: number;
  items: any[];
}

@Component({
  selector: 'app-product-master',
  standalone: true,
  imports: [FormsModule, CurrencyPipe, RouterLink],
  templateUrl: './product-master.component.html',
  styleUrl: './product-master.component.scss'
})
export class ProductMasterComponent implements OnInit {
  private productApi = inject(ProductApiService);
  private categoryApi = inject(CategoryApiService);
  private sizeApi = inject(SizeApiService);
  private colorApi = inject(ColorApiService);
  auth = inject(AuthService);

  products: any[] = [];
  categories: any[] = [];
  sizes: any[] = [];
  colors: any[] = [];
  search = '';
  viewType: 'grouped' | 'flat' = 'grouped';
  expandedGroupCodes: Set<string> = new Set();
  showModal = false;
  viewMode = false;
  addTab: 'single' | 'batch' = 'single';
  message = '';
  messageType: 'success' | 'error' = 'success';
  loading = false;
  saving = false;

  form: any = {};

  getGroupCode(p: any): string {
    const code = (p.productCode || p.topCode || '').trim();
    if (!code) return 'OTHER';
    const parts = code.split('-');
    if (parts.length >= 3) {
      return `${parts[0]}-${parts[1]}`;
    } else if (parts.length === 2) {
      return code;
    }
    return code;
  }

  get groupedProducts(): ProductGroup[] {
    const map = new Map<string, ProductGroup>();

    for (const p of this.filtered) {
      const gCode = this.getGroupCode(p);
      let g = map.get(gCode);

      if (!g) {
        g = {
          groupCode: gCode,
          productName: p.productName || 'Product',
          categoryName: this.getCategoryName(p),
          colorName: this.getColorName(p),
          colorCode: this.getColorCode(p),
          productImage: p.productImage || '',
          isFullSet: !!(p.isFullSet ?? p.IsFullSet),
          ageGroup: p.ageGroup || '',
          rentAmount: Number(p.rentAmount || 0),
          depositAmount: Number(p.depositAmount || 0),
          totalQuantity: 0,
          items: []
        };
        map.set(gCode, g);
      }

      g.items.push(p);
      g.totalQuantity += Number(p.availableQuantity || 1);
      if (!g.productImage && p.productImage) g.productImage = p.productImage;
    }

    return Array.from(map.values());
  }

  toggleGroup(gCode: string) {
    if (this.expandedGroupCodes.has(gCode)) {
      this.expandedGroupCodes.delete(gCode);
    } else {
      this.expandedGroupCodes.add(gCode);
    }
  }

  isGroupExpanded(gCode: string): boolean {
    return this.expandedGroupCodes.has(gCode);
  }

  // Batch / Multi-Add Form
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
    this.load();
  }

  buildEmptyForm() {
    return {
      productID: 0,
      companyID: this.auth.currentUser()?.companyID || 1,
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

  buildEmptyBatchForm() {
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
      codePrefix: 'BL-01',
      items: [
        { productCode: 'BL-01-01', topCode: 'BL-01-01', bottomCode: 'BL-01P-01', topSize: '', bottomSize: '', sizeID: null, colorID: null },
        { productCode: 'BL-01-02', topCode: 'BL-01-02', bottomCode: 'BL-01P-02', topSize: '', bottomSize: '', sizeID: null, colorID: null }
      ]
    };
  }

  private showMsg(text: string, type: 'success' | 'error') {
    this.message = text;
    this.messageType = type;
    if (type === 'success') setTimeout(() => { if (this.message === text) this.message = ''; }, 4000);
  }

  loadLookups() {
    const cid = this.auth.currentUser()?.companyID;
    this.categoryApi.list(cid).subscribe(r => { if (r.success) this.categories = asArray(r.data); });
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
    this.colorApi.list(cid).subscribe(r => { if (r.success) this.colors = asArray(r.data); });
  }

  get filtered() {
    const q = this.search.toLowerCase().trim();
    if (!q) return this.products;
    return this.products.filter(p =>
      p.productCode?.toLowerCase().includes(q) ||
      p.productName?.toLowerCase().includes(q) ||
      this.getCategoryName(p).toLowerCase().includes(q) ||
      this.getColorName(p).toLowerCase().includes(q) ||
      this.getSizeName(p).toLowerCase().includes(q)
    );
  }

  getCategoryName(p: any): string {
    if (p.categoryName || p.CategoryName) return p.categoryName || p.CategoryName;
    const catId = p.categoryID ?? p.CategoryID;
    if (catId && this.categories.length) {
      const found = this.categories.find(c => (c.categoryID ?? c.CategoryID) === catId);
      if (found) return found.categoryName || found.CategoryName || '';
    }
    return '-';
  }

  getSizeName(p: any): string {
    if (p.size || p.Size || p.sizeName || p.SizeName) return p.size || p.Size || p.sizeName || p.SizeName;
    const sizeId = p.sizeID ?? p.SizeID;
    if (sizeId && this.sizes.length) {
      const found = this.sizes.find(s => (s.sizeID ?? s.SizeID) === sizeId);
      if (found) return found.sizeName || found.SizeName || '';
    }
    return '-';
  }

  getColorName(p: any): string {
    if (p.color || p.Color || p.colorName || p.ColorName) return p.color || p.Color || p.colorName || p.ColorName;
    const colorId = p.colorID ?? p.ColorID;
    if (colorId && this.colors.length) {
      const found = this.colors.find(c => (c.colorID ?? c.ColorID) === colorId);
      if (found) return found.colorName || found.ColorName || '';
    }
    return '-';
  }

  getColorCode(p: any): string {
    if (p.colorCode || p.ColorCode) return p.colorCode || p.ColorCode;
    const colorId = p.colorID ?? p.ColorID;
    if (colorId && this.colors.length) {
      const found = this.colors.find(c => (c.colorID ?? c.ColorID) === colorId);
      if (found) return found.colorCode || found.ColorCode || '';
    }
    return '';
  }

  load() {
    this.loading = true;
    this.productApi.list(this.auth.currentUser()?.companyID).subscribe({
      next: res => {
        this.loading = false;
        if (res.success) this.products = asArray(res.data);
        else {
          this.products = [];
          this.showMsg(res.message || 'Failed to load products', 'error');
        }
      },
      error: () => {
        this.loading = false;
        this.showMsg('Failed to load products', 'error');
      }
    });
  }

  // Multi-Size Selection State
  selectedSizeIds: number[] = [];

  openAdd() {
    this.viewMode = false;
    this.addTab = 'single';
    this.selectedSizeIds = [];
    this.form = this.buildEmptyForm();
    this.batchForm = this.buildEmptyBatchForm();
    this.showModal = true;
  }

  openEdit(p: any, view = false) {
    this.viewMode = view;
    this.addTab = 'single';
    this.selectedSizeIds = p.sizeID ? [p.sizeID] : [];
    this.form = {
      productID: pickId(p, 'productID', 'ProductID'),
      companyID: p.companyID ?? p.CompanyID ?? 1,
      productCode: p.productCode ?? '',
      productName: p.productName ?? '',
      categoryID: p.categoryID ?? p.CategoryID ?? null,
      sizeID: p.sizeID ?? p.SizeID ?? null,
      colorID: p.colorID ?? p.ColorID ?? null,
      ageGroup: p.ageGroup ?? '',
      rentAmount: Number(p.rentAmount ?? 0),
      depositAmount: Number(p.depositAmount ?? 0),
      discountPercent: Number(p.discountPercent ?? 0),
      standardRentalDays: Number(p.standardRentalDays ?? 4),
      extraChargePerDay: Number(p.extraChargePerDay ?? 150),
      availableQuantity: Number(p.availableQuantity ?? 1),
      description: p.description ?? '',
      productImage: p.productImage ?? '',
      isAvailable: p.isAvailable !== false && p.isAvailable !== 0,
      isFullSet: !!(p.isFullSet ?? p.IsFullSet),
      topCode: p.topCode ?? p.TopCode ?? '',
      topSize: p.topSize ?? p.TopSize ?? '',
      bottomCode: p.bottomCode ?? p.BottomCode ?? '',
      bottomSize: p.bottomSize ?? p.BottomSize ?? ''
    };
    this.showModal = true;
  }

  switchToEditMode() {
    this.viewMode = false;
  }

  // --- MULTI-SIZE SELECTION & GENERATION ---
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
    
    // Switch to batch mode automatically when multiple sizes are selected
    if (this.selectedSizeIds.length > 1 && this.addTab === 'single') {
      this.addTab = 'batch';
    }

    const rawPrefix = (this.form.productCode || this.batchForm.codePrefix || 'BL-01').trim().toUpperCase();
    const prefix = rawPrefix || 'BL-01';

    this.batchForm.items = this.selectedSizeIds.map(sizeId => {
      const sObj = this.sizes.find(sz => sz.sizeID === sizeId);
      const sName = sObj ? sObj.sizeName : String(sizeId);
      
      return {
        productCode: `${prefix}-${sName}`,
        topCode: `${prefix}-${sName}`,
        bottomCode: `${prefix}P-${sName}`,
        topSize: sName,
        bottomSize: sName,
        sizeID: sizeId,
        colorID: this.batchForm.colorID || this.form.colorID || null
      };
    });
  }

  // --- BATCH MULTI-ITEM METHODS ---
  addBatchRow() {
    const count = this.batchForm.items.length + 1;
    const seq = count < 10 ? `0${count}` : `${count}`;
    const prefix = (this.batchForm.codePrefix || 'BL-01').trim().toUpperCase();

    this.batchForm.items.push({
      productCode: `${prefix}-${seq}`,
      topCode: `${prefix}-${seq}`,
      bottomCode: `${prefix}P-${seq}`,
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
    const prefix = (this.batchForm.codePrefix || 'BL-01').trim().toUpperCase();
    this.batchForm.items.forEach((item, idx) => {
      const sObj = this.sizes.find(s => s.sizeID === item.sizeID);
      const tag = sObj ? sObj.sizeName : (idx + 1 < 10 ? `0${idx + 1}` : `${idx + 1}`);
      item.productCode = `${prefix}-${tag}`;
      item.topCode = `${prefix}-${tag}`;
      item.bottomCode = `${prefix}P-${tag}`;
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
          this.showModal = false;
          this.load();
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
        if (successCount > 0) {
          this.showMsg(`Successfully added ${successCount} product sizes!`, 'success');
          this.showModal = false;
          this.load();
        } else {
          this.showMsg('Batch add failed', 'error');
        }
      },
      error: () => {
        this.saving = false;
        this.showMsg('Failed to save batch products', 'error');
      }
    });
  }

  delete(p: any) {
    const id = pickId(p, 'productID', 'ProductID');
    if (!id) return;
    if (!confirm('Delete product ' + (p.productCode || '') + '?')) return;

    this.loading = true;
    this.productApi.delete(id).subscribe({
      next: res => {
        this.loading = false;
        if (res.success) {
          this.showMsg(res.message || 'Deleted successfully', 'success');
          this.load();
        } else {
          this.showMsg(res.message || 'Delete failed', 'error');
        }
      },
      error: () => {
        this.loading = false;
        this.showMsg('Delete request failed', 'error');
      }
    });
  }

  closeModal() {
    if (!this.saving) this.showModal = false;
  }

  imageUrl(path?: string): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = environment.apiUrl.replace(/\/api\/?$/, '');
    return `${base}${path.startsWith('/') ? path : '/' + path}`;
  }
}
