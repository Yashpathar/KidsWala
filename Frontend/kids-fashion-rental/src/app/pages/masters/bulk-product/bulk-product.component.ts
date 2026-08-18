import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { ProductApiService, CategoryApiService, SizeApiService, ColorApiService } from '../../../core/services/masters.service';
import { AlertService } from '../../../core/services/alert.service';
import { asArray, pickId } from '../../../core/models/api.models';

export interface ValidatedRow {
  rowNum: number;
  productCode: string;
  productName: string;
  categoryName: string;
  categoryID: number | null;
  sizeName: string;
  sizeID: number | null;
  colorName: string;
  colorID: number | null;
  ageGroup: string;
  rentAmount: number;
  depositAmount: number;
  discountPercent: number;
  standardRentalDays: number;
  extraChargePerDay: number;
  availableQuantity: number;
  description: string;
  isFullSet: boolean;
  topCode: string;
  topSize: string;
  bottomCode: string;
  bottomSize: string;
  status: 'Pending' | 'Valid' | 'Invalid' | 'Importing' | 'Success' | 'Failed';
  errors: string[];
  apiError?: string;
}

@Component({
  selector: 'app-bulk-product',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './bulk-product.component.html',
  styleUrl: './bulk-product.component.scss'
})
export class BulkProductComponent implements OnInit {
  private api = inject(ApiService);
  private productApi = inject(ProductApiService);
  private categoryApi = inject(CategoryApiService);
  private sizeApi = inject(SizeApiService);
  private colorApi = inject(ColorApiService);
  private alert = inject(AlertService);
  auth = inject(AuthService);

  companies: any[] = [];
  branches: any[] = [];
  categories: any[] = [];
  sizes: any[] = [];
  colors: any[] = [];

  selectedCompanyID: number | null = null;
  selectedBranchID: number | null = null;

  loading: boolean = false;
  validating: boolean = false;
  importing: boolean = false;
  importProgress: number = 0;
  importTotal: number = 0;

  fileInputLabel: string = 'Choose an Excel file or drag & drop here';
  parsedRows: ValidatedRow[] = [];
  validationSummary = { total: 0, valid: 0, invalid: 0 };
  currentStatusText: string = '';

  ngOnInit() {
    const curUser = this.auth.currentUser();
    this.selectedCompanyID = curUser?.companyID || null;
    this.selectedBranchID = curUser?.branchID || null;

    this.loadLookups();
  }

  loadLookups() {
    this.loading = true;

    // Load Companies (if Super Admin)
    if (this.auth.isPlatformAdmin()) {
      this.api.get<any>('/company').subscribe(r => {
        if (r.success) this.companies = asArray(r.data);
      });
    }

    // Load all branches
    this.api.get<any>('/branch').subscribe(r => {
      if (r.success) this.branches = asArray(r.data);
    });

    const cid = this.selectedCompanyID || this.auth.currentUser()?.companyID || undefined;

    // Load Categories, Sizes, Colors
    this.categoryApi.list(cid).subscribe(r => {
      if (r.success) this.categories = asArray(r.data);
    });

    this.sizeApi.list(cid).subscribe(r => {
      if (r.success) this.sizes = asArray(r.data);
    });

    this.colorApi.list(cid).subscribe(r => {
      if (r.success) {
        this.colors = asArray(r.data);
        this.loading = false;
      } else {
        this.loading = false;
      }
    }, () => {
      this.loading = false;
    });
  }

  getFilteredBranches(): any[] {
    if (!this.selectedCompanyID) return this.branches;
    return this.branches.filter(b => b.companyID === this.selectedCompanyID || b.CompanyID === this.selectedCompanyID);
  }

  onCompanyChange() {
    this.selectedBranchID = null;
    this.parsedRows = [];
    this.resetSummary();
    this.loadLookups();
  }

  onBranchChange() {
    this.parsedRows = [];
    this.resetSummary();
  }

  resetSummary() {
    this.validationSummary = { total: 0, valid: 0, invalid: 0 };
  }

  // Load SheetJS dynamically from CDN
  loadSheetJS(): Promise<any> {
    const win = window as any;
    if (win.XLSX) return Promise.resolve(win.XLSX);

    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js';
      script.onload = () => resolve(win.XLSX);
      script.onerror = (err) => reject(err);
      document.head.appendChild(script);
    });
  }

  downloadSampleTemplate() {
    this.loading = true;
    this.loadSheetJS().then(XLSX => {
      this.loading = false;

      const headers = [
        'ProductCode',
        'ProductName',
        'CategoryName',
        'SizeName',
        'ColorName',
        'AgeGroup',
        'RentAmount',
        'DepositAmount',
        'DiscountPercent',
        'StandardRentalDays',
        'ExtraChargePerDay',
        'AvailableQuantity',
        'Description',
        'IsFullSet',
        'TopCode',
        'TopSize',
        'BottomCode',
        'BottomSize'
      ];

      const sampleRows = [
        [
          'PROD-BOY-01',
          'Designer Sherwani Set',
          this.categories[0]?.categoryName || 'Sherwani',
          this.sizes[0]?.sizeName || '24',
          this.colors[0]?.colorName || 'Navy Blue',
          '5-6 Years',
          1500,
          2000,
          0,
          4,
          150,
          1,
          'Premium silk sherwani with churidar bottom',
          'TRUE',
          'PROD-BOY-01-TOP',
          this.sizes[0]?.sizeName || '24',
          'PROD-BOY-01-BTM',
          this.sizes[0]?.sizeName || '24'
        ],
        [
          'PROD-GRL-02',
          'Floral Net Lehenga Choli',
          this.categories[1]?.categoryName || 'Lehenga',
          this.sizes[1]?.sizeName || '26',
          this.colors[1]?.colorName || 'Pink',
          '7-8 Years',
          1800,
          2500,
          5,
          4,
          200,
          1,
          'Traditional designer lehenga with net dupatta',
          'FALSE',
          '',
          '',
          '',
          ''
        ]
      ];

      const ws = XLSX.utils.aoa_to_sheet([headers, ...sampleRows]);
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, 'Products');

      XLSX.writeFile(wb, 'Bulk_Product_Import_Template.xlsx');
      this.alert.toastSuccess('Sample Excel downloaded successfully!');
    }).catch(() => {
      this.loading = false;
      this.alert.toastError('Failed to load excel export engine.');
    });
  }

  onFileDragOver(event: DragEvent) {
    event.preventDefault();
  }

  onFileDrop(event: DragEvent) {
    event.preventDefault();
    if (event.dataTransfer?.files.length) {
      this.processFile(event.dataTransfer.files[0]);
    }
  }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files?.length) {
      this.processFile(input.files[0]);
      input.value = ''; // Reset file input
    }
  }

  processFile(file: File) {
    if (!file.name.endsWith('.xlsx') && !file.name.endsWith('.xls')) {
      this.alert.toastError('Invalid file type. Please upload an Excel file (.xlsx or .xls)');
      return;
    }

    if (!this.selectedBranchID) {
      this.alert.toastError('Please select a Branch before uploading the file.');
      return;
    }

    this.fileInputLabel = file.name;
    this.validating = true;
    this.parsedRows = [];

    const reader = new FileReader();
    reader.onload = (e: any) => {
      const bstr = e.target.result;

      this.loadSheetJS().then(XLSX => {
        const wb = XLSX.read(bstr, { type: 'binary' });
        const wsname = wb.SheetNames[0];
        const ws = wb.Sheets[wsname];
        const rawJson = XLSX.utils.sheet_to_json(ws) as any[];

        this.validateAndMapRows(rawJson);
        this.validating = false;
      }).catch(() => {
        this.validating = false;
        this.alert.toastError('Failed to load excel parser.');
      });
    };
    reader.onerror = () => {
      this.validating = false;
      this.alert.toastError('Error reading file.');
    };
    reader.readAsBinaryString(file);
  }

  private cleanKey(key: string): string {
    return key.replace(/[\s_-]/g, '').toLowerCase();
  }

  private getVal(row: any, keyName: string): any {
    const matchKey = this.cleanKey(keyName);
    for (const k of Object.keys(row)) {
      if (this.cleanKey(k) === matchKey) {
        return row[k];
      }
    }
    return undefined;
  }

  validateAndMapRows(rawRows: any[]) {
    const mappedList: ValidatedRow[] = [];
    let validCount = 0;
    let invalidCount = 0;

    const existingCodes = new Set<string>();

    rawRows.forEach((row, index) => {
      const rowNum = index + 2; // header is row 1
      const errors: string[] = [];

      // Extract fields case-insensitively
      const rawCode = String(this.getVal(row, 'ProductCode') || '').trim();
      const rawName = String(this.getVal(row, 'ProductName') || '').trim();
      const rawCat = String(this.getVal(row, 'CategoryName') || '').trim();
      const rawSize = String(this.getVal(row, 'SizeName') || '').trim();
      const rawColor = String(this.getVal(row, 'ColorName') || '').trim();
      const ageGroup = String(this.getVal(row, 'AgeGroup') || '').trim();
      const rentVal = this.getVal(row, 'RentAmount');
      const depVal = this.getVal(row, 'DepositAmount');
      const discVal = this.getVal(row, 'DiscountPercent');
      const rentDaysVal = this.getVal(row, 'StandardRentalDays');
      const extraVal = this.getVal(row, 'ExtraChargePerDay');
      const qtyVal = this.getVal(row, 'AvailableQuantity');
      const desc = String(this.getVal(row, 'Description') || '').trim();
      const rawFullSet = String(this.getVal(row, 'IsFullSet') || '').trim().toLowerCase();

      const topCode = String(this.getVal(row, 'TopCode') || '').trim();
      const topSize = String(this.getVal(row, 'TopSize') || '').trim();
      const bottomCode = String(this.getVal(row, 'BottomCode') || '').trim();
      const bottomSize = String(this.getVal(row, 'BottomSize') || '').trim();

      // Field validation
      if (!rawCode) {
        errors.push('Product Code is required.');
      } else if (existingCodes.has(rawCode.toLowerCase())) {
        errors.push(`Duplicate Product Code '${rawCode}' in sheet.`);
      } else {
        existingCodes.add(rawCode.toLowerCase());
      }

      if (!rawName) errors.push('Product Name is required.');

      // Lookup mappings
      let categoryID: number | null = null;
      if (!rawCat) {
        errors.push('Category Name is required.');
      } else {
        const catObj = this.categories.find(c => String(c.categoryName || '').trim().toLowerCase() === rawCat.toLowerCase());
        if (catObj) {
          categoryID = pickId(catObj, 'categoryID', 'CategoryID');
        } else {
          errors.push(`Category '${rawCat}' not found in database.`);
        }
      }

      let sizeID: number | null = null;
      if (!rawSize) {
        errors.push('Size Name is required.');
      } else {
        const szObj = this.sizes.find(s => String(s.sizeName || '').trim().toLowerCase() === rawSize.toLowerCase());
        if (szObj) {
          sizeID = pickId(szObj, 'sizeID', 'SizeID');
        } else {
          errors.push(`Size '${rawSize}' not found in database.`);
        }
      }

      let colorID: number | null = null;
      if (!rawColor) {
        errors.push('Color Name is required.');
      } else {
        const clrObj = this.colors.find(c => String(c.colorName || '').trim().toLowerCase() === rawColor.toLowerCase());
        if (clrObj) {
          colorID = pickId(clrObj, 'colorID', 'ColorID');
        } else {
          errors.push(`Color '${rawColor}' not found in database.`);
        }
      }

      // Numerics checking
      const rentAmount = isNaN(Number(rentVal)) ? 0 : Number(rentVal);
      if (rentVal !== undefined && isNaN(Number(rentVal))) errors.push('Rent Amount must be numeric.');
      if (rentAmount < 0) errors.push('Rent Amount cannot be negative.');

      const depositAmount = isNaN(Number(depVal)) ? 0 : Number(depVal);
      if (depVal !== undefined && isNaN(Number(depVal))) errors.push('Deposit Amount must be numeric.');
      if (depositAmount < 0) errors.push('Deposit Amount cannot be negative.');

      const discountPercent = isNaN(Number(discVal)) ? 0 : Number(discVal);
      if (discVal !== undefined && isNaN(Number(discVal))) errors.push('Discount Percent must be numeric.');

      const standardRentalDays = isNaN(Number(rentDaysVal)) ? 4 : Number(rentDaysVal);
      if (rentDaysVal !== undefined && isNaN(Number(rentDaysVal))) errors.push('Standard Rental Days must be numeric.');

      const extraChargePerDay = isNaN(Number(extraVal)) ? 150 : Number(extraVal);
      if (extraVal !== undefined && isNaN(Number(extraVal))) errors.push('Extra Charge per Day must be numeric.');

      const availableQuantity = isNaN(Number(qtyVal)) ? 1 : Number(qtyVal);
      if (qtyVal !== undefined && isNaN(Number(qtyVal))) errors.push('Available Quantity must be numeric.');

      const isFullSet = rawFullSet === 'true' || rawFullSet === '1' || rawFullSet === 'yes';

      const isValid = errors.length === 0;
      if (isValid) validCount++; else invalidCount++;

      mappedList.push({
        rowNum,
        productCode: rawCode,
        productName: rawName,
        categoryName: rawCat,
        categoryID,
        sizeName: rawSize,
        sizeID,
        colorName: rawColor,
        colorID,
        ageGroup,
        rentAmount,
        depositAmount,
        discountPercent,
        standardRentalDays,
        extraChargePerDay,
        availableQuantity,
        description: desc,
        isFullSet,
        topCode: isFullSet ? (topCode || `${rawCode}-TOP`) : '',
        topSize: isFullSet ? (topSize || rawSize) : '',
        bottomCode: isFullSet ? (bottomCode || `${rawCode}-BTM`) : '',
        bottomSize: isFullSet ? (bottomSize || rawSize) : '',
        status: isValid ? 'Valid' : 'Invalid',
        errors
      });
    });

    this.parsedRows = mappedList;
    this.validationSummary = {
      total: mappedList.length,
      valid: validCount,
      invalid: invalidCount
    };

    if (validCount === 0 && mappedList.length > 0) {
      this.alert.toastError('No valid rows found in the sheet. Please fix errors and upload again.');
    } else if (invalidCount > 0) {
      this.alert.toastWarning(`Loaded ${mappedList.length} rows. Found ${invalidCount} invalid rows with errors.`);
    } else if (mappedList.length > 0) {
      this.alert.toastSuccess(`Excel parsed successfully! All ${validCount} rows are valid and ready to import.`);
    }
  }

  async importProducts() {
    const validRows = this.parsedRows.filter(r => r.status === 'Valid' || r.status === 'Failed');
    if (!validRows.length) return;

    this.importing = true;
    this.importProgress = 0;
    this.importTotal = validRows.length;
    this.currentStatusText = `Starting import of ${this.importTotal} products...`;

    const companyID = Number(this.selectedCompanyID || this.auth.currentUser()?.companyID || 1);
    const branchID = this.selectedBranchID ? Number(this.selectedBranchID) : null;

    for (let i = 0; i < validRows.length; i++) {
      const row = validRows[i];
      row.status = 'Importing';
      this.currentStatusText = `Importing ${row.productCode} (${i + 1}/${this.importTotal})...`;

      const payload = {
        productID: 0,
        companyID,
        branchID,
        productCode: row.productCode,
        productName: row.productName,
        categoryID: Number(row.categoryID),
        sizeID: Number(row.sizeID),
        colorID: Number(row.colorID),
        ageGroup: row.ageGroup,
        rentAmount: row.rentAmount,
        depositAmount: row.depositAmount,
        discountPercent: row.discountPercent,
        standardRentalDays: row.standardRentalDays,
        extraChargePerDay: row.extraChargePerDay,
        availableQuantity: row.availableQuantity,
        description: row.description,
        productImage: '', // Bulk insert defaults to no image, added later via edit
        isAvailable: true,
        isFullSet: row.isFullSet,
        topCode: row.topCode,
        topSize: row.topSize,
        bottomCode: row.bottomCode,
        bottomSize: row.bottomSize
      };

      try {
        const res = await this.productApi.create(payload).toPromise();
        if (res && res.success) {
          row.status = 'Success';
          row.apiError = undefined;
        } else {
          row.status = 'Failed';
          row.apiError = res?.message || 'Database insert failed.';
        }
      } catch (err: any) {
        row.status = 'Failed';
        row.apiError = err?.error?.message || err?.message || 'Server connection error.';
      }

      this.importProgress++;
      this.validationSummary.valid = this.parsedRows.filter(r => r.status === 'Valid').length;
    }

    this.importing = false;
    this.currentStatusText = '';

    const failures = validRows.filter(r => r.status === 'Failed').length;
    if (failures > 0) {
      this.alert.toastWarning(`Import completed. ${this.importTotal - failures} imported successfully, ${failures} failed.`);
    } else {
      this.alert.toastSuccess(`Successfully imported all ${this.importTotal} products!`);
      this.parsedRows = [];
      this.resetSummary();
      this.fileInputLabel = 'Choose an Excel file or drag & drop here';
    }
  }

  clearList() {
    this.parsedRows = [];
    this.resetSummary();
    this.fileInputLabel = 'Choose an Excel file or drag & drop here';
  }
}
