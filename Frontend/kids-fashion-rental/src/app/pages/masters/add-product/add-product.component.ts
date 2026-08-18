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
  uploadingImage: boolean = false;
  showImageLightbox: boolean = false;

  applyImageToGroup: boolean = false;
  applyPriceToGroup: boolean = false;

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
      isFullSet: false,
      topCode: '',
      topSize: '',
      bottomCode: '',
      bottomSize: ''
    };
  }

  formatCode(rawPrefix: string, sizeName: string): string {
    let clean = (rawPrefix || 'BL-12').trim().toUpperCase().replace(/[-P]+$/g, '');
    if (!clean) clean = 'BL-12';
    const sz = String(sizeName || '02').trim();
    return `${clean}-${sz}`;
  }

  buildEmptyBatchForm() {
    const code1 = this.formatCode('BL-12', '02');
    const code2 = this.formatCode('BL-12', '04');

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
      isFullSet: false,
      codePrefix: 'BL-12',
      items: [
        { productCode: code1, sizeID: null, colorID: null },
        { productCode: code2, sizeID: null, colorID: null }
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

      return {
        productCode: this.formatCode(prefix, sName),
        sizeID: sizeId,
        colorID: this.batchForm.colorID || this.form.colorID || null
      };
    });
  }

  addBatchRow() {
    const count = this.batchForm.items.length + 1;
    const seq = count < 10 ? `0${count}` : `${count}`;
    const prefix = this.batchForm.codePrefix || 'BL-12';

    this.batchForm.items.push({
      productCode: this.formatCode(prefix, seq),
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
      item.productCode = this.formatCode(prefix, tag);
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
    const file = input.files[0];
    this.uploadingImage = true;
    this.productApi.uploadImage(file).subscribe({
      next: res => {
        this.uploadingImage = false;
        if (res.success) {
          if (this.addTab === 'batch' && !this.isEditMode) {
            this.batchForm.productImage = res.data;
          } else {
            this.form.productImage = res.data;
          }
          this.showMsg('Image uploaded successfully', 'success');
        } else {
          this.showMsg(res.message || 'Image upload failed', 'error');
        }
      },
      error: (err) => {
        this.uploadingImage = false;
        this.showMsg('Image upload failed: ' + (err?.error?.message || err?.message || 'Server error'), 'error');
      }
    });
    input.value = '';
  }

  removeImage() {
    if (this.addTab === 'batch' && !this.isEditMode) {
      this.batchForm.productImage = '';
    } else {
      this.form.productImage = '';
    }
    this.showMsg('Product image removed', 'success');
  }

  openImageLightbox() {
    if (this.form.productImage || this.batchForm.productImage) {
      this.showImageLightbox = true;
    }
  }

  closeImageLightbox() {
    this.showImageLightbox = false;
  }

  getGroupCode(productCode: string): string {
    if (!productCode) return '';
    const clean = productCode.trim().toUpperCase();
    const parts = clean.split('-');
    if (parts.length >= 3) {
      return `${parts[0]}-${parts[1]}`;
    }
    return clean;
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

  formatProductError(rawMsg?: string): string {
    if (!rawMsg) return 'Product code already exists in database.';
    if (rawMsg.includes('UNIQUE KEY') || rawMsg.includes('duplicate key')) {
      const match = rawMsg.match(/\(([^)]+)\)/);
      const code = match ? match[1] : '';
      if (code) {
        return `Product Code '${code}' already exists. Please click Auto-Code to generate new codes.`;
      }
      return 'Product Code already exists in database. Please enter or generate a unique code.';
    }
    return rawMsg;
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
        if (res.success) {
          if (isUpdate && (this.applyImageToGroup || this.applyPriceToGroup)) {
            this.syncGroupVariants(payload);
          } else {
            this.saving = false;
            this.showMsg(res.message || 'Saved successfully', 'success');
            setTimeout(() => this.router.navigate(['/masters/product']), 1000);
          }
        } else {
          this.saving = false;
          this.showMsg(this.formatProductError(res.message), 'error');
        }
      },
      error: (err) => {
        this.saving = false;
        const msg = err?.error?.message || err?.message;
        this.showMsg(this.formatProductError(msg || 'Save request failed'), 'error');
      }
    });
  }

  syncGroupVariants(updatedPayload: any) {
    const groupCode = this.getGroupCode(updatedPayload.productCode);
    const cid = updatedPayload.companyID;

    this.productApi.list(cid).subscribe({
      next: res => {
        if (res.success && Array.isArray(res.data)) {
          const siblings = asArray(res.data).filter(p => {
            const pId = pickId(p, 'productID', 'ProductID');
            const code = p.productCode || p.ProductCode || '';
            return pId !== updatedPayload.productID && this.getGroupCode(code) === groupCode;
          });

          if (!siblings.length) {
            this.saving = false;
            this.showMsg('Saved successfully!', 'success');
            setTimeout(() => this.router.navigate(['/masters/product']), 1000);
            return;
          }

          const syncReqs = siblings.map(sib => {
            const sibPayload = {
              productID: pickId(sib, 'productID', 'ProductID'),
              companyID: sib.companyID ?? sib.CompanyID ?? cid,
              branchID: sib.branchID ?? sib.BranchID ?? updatedPayload.branchID,
              productCode: sib.productCode ?? sib.ProductCode,
              productName: sib.productName ?? sib.ProductName,
              categoryID: sib.categoryID ?? sib.CategoryID,
              sizeID: sib.sizeID ?? sib.SizeID,
              colorID: sib.colorID ?? sib.ColorID,
              ageGroup: sib.ageGroup ?? sib.AgeGroup ?? '',
              rentAmount: this.applyPriceToGroup ? updatedPayload.rentAmount : Number(sib.rentAmount ?? sib.RentAmount ?? 0),
              depositAmount: this.applyPriceToGroup ? updatedPayload.depositAmount : Number(sib.depositAmount ?? sib.DepositAmount ?? 0),
              discountPercent: this.applyPriceToGroup ? updatedPayload.discountPercent : Number(sib.discountPercent ?? sib.DiscountPercent ?? 0),
              standardRentalDays: updatedPayload.standardRentalDays,
              extraChargePerDay: updatedPayload.extraChargePerDay,
              availableQuantity: sib.availableQuantity ?? sib.AvailableQuantity ?? 1,
              description: sib.description ?? sib.Description ?? '',
              productImage: this.applyImageToGroup ? updatedPayload.productImage : (sib.productImage ?? sib.ProductImage ?? ''),
              isAvailable: sib.isAvailable !== false && sib.isAvailable !== 0,
              isFullSet: !!(sib.isFullSet ?? sib.IsFullSet),
              topCode: sib.topCode ?? sib.TopCode ?? '',
              topSize: sib.topSize ?? sib.TopSize ?? '',
              bottomCode: sib.bottomCode ?? sib.BottomCode ?? '',
              bottomSize: sib.bottomSize ?? sib.BottomSize ?? ''
            };
            return this.productApi.update(sibPayload);
          });

          forkJoin(syncReqs).subscribe({
            next: () => {
              this.saving = false;
              this.showMsg(`Saved & synced updates to all ${siblings.length + 1} size variants in ${groupCode}!`, 'success');
              setTimeout(() => this.router.navigate(['/masters/product']), 1200);
            },
            error: () => {
              this.saving = false;
              this.showMsg('Main product saved, but failed to sync group variants', 'error');
              setTimeout(() => this.router.navigate(['/masters/product']), 1500);
            }
          });
        } else {
          this.saving = false;
          this.showMsg('Saved product successfully', 'success');
          setTimeout(() => this.router.navigate(['/masters/product']), 1000);
        }
      },
      error: () => {
        this.saving = false;
        this.showMsg('Saved product successfully', 'success');
        setTimeout(() => this.router.navigate(['/masters/product']), 1000);
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
      const pCode = (item.productCode || 'ITEM').trim();
      const szObj = this.sizes.find(s => s.sizeID === item.sizeID);
      const szName = szObj ? szObj.sizeName : '12';

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
        isFullSet: false,
        topCode: pCode,
        topSize: szName,
        bottomCode: '',
        bottomSize: ''
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
          const firstErr = this.formatProductError(failedResults[0]?.message);
          this.showMsg(`Created ${successCount} products. ${failedResults.length} failed (${firstErr})`, 'error');
        } else {
          const firstErr = this.formatProductError(failedResults[0]?.message);
          this.showMsg(`Batch creation failed: ${firstErr}`, 'error');
        }
      },
      error: (err) => {
        this.saving = false;
        const msg = err?.error?.message || err?.message;
        this.showMsg(`Batch creation error: ${this.formatProductError(msg)}`, 'error');
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
