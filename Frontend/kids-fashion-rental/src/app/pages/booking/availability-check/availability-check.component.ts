import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../core/services/api.service';
import { ProductApiService } from '../../../core/services/masters.service';
import { AuthService } from '../../../core/services/auth.service';
import { asArray, normalizeRow, pickField } from '../../../core/models/api.models';
import { getImageUrl, handleImageError } from '../../../core/utils/image.utils';
import { CustomDatePickerComponent } from '../../../shared/components/custom-date-picker/custom-date-picker.component';

export interface CodeSuggestion {
  code: string;
  type: string;
  name: string;
}

@Component({
  selector: 'app-availability-check',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, CustomDatePickerComponent],
  templateUrl: './availability-check.component.html',
  styleUrl: './availability-check.component.scss'
})
export class AvailabilityCheckComponent implements OnInit {
  private api = inject(ApiService);
  private productApi = inject(ProductApiService);
  private auth = inject(AuthService);

  productCode = '';
  deliveryDate = new Date().toISOString().split('T')[0];
  returnDate = new Date(Date.now() + 4 * 86400000).toISOString().split('T')[0];

  loading = false;
  searched = false;
  productData: any = null;
  errorMessage = '';

  // Suggestions state
  allCodeSuggestions: CodeSuggestion[] = [];
  filteredSuggestions: CodeSuggestion[] = [];
  showSuggestions = false;

  ngOnInit() {
    this.loadProductSuggestions();
  }

  loadProductSuggestions() {
    const companyId = this.auth.currentUser()?.companyID;
    this.productApi.list(companyId).subscribe(r => {
      if (r.success) {
        const rows = asArray(r.data);
        const map = new Map<string, CodeSuggestion>();

        rows.forEach(x => {
          const row = normalizeRow(x);
          const pCode = String(pickField(row, 'productCode', 'ProductCode') ?? '').trim();
          const pName = String(pickField(row, 'productName', 'ProductName') ?? '').trim();
          const tCode = String(pickField(row, 'topCode', 'TopCode') ?? '').trim();
          const bCode = String(pickField(row, 'bottomCode', 'BottomCode') ?? '').trim();

          if (pCode && !map.has(pCode.toLowerCase())) {
            map.set(pCode.toLowerCase(), { code: pCode, type: 'Product Code', name: pName });
          }
          if (tCode && !map.has(tCode.toLowerCase())) {
            map.set(tCode.toLowerCase(), { code: tCode, type: 'Blazer Code', name: pName });
          }
          if (bCode && !map.has(bCode.toLowerCase())) {
            map.set(bCode.toLowerCase(), { code: bCode, type: 'Pant Code', name: pName });
          }
        });

        this.allCodeSuggestions = Array.from(map.values());
      }
    });
  }

  onCodeInput() {
    this.errorMessage = '';
    const q = (this.productCode || '').trim().toLowerCase();
    if (!q) {
      this.filteredSuggestions = [];
      this.showSuggestions = false;
      return;
    }

    this.filteredSuggestions = this.allCodeSuggestions.filter(
      s => s.code.toLowerCase().includes(q) || s.name.toLowerCase().includes(q)
    ).slice(0, 10);

    this.showSuggestions = this.filteredSuggestions.length > 0;
  }

  selectSuggestion(item: CodeSuggestion) {
    this.productCode = item.code;
    this.showSuggestions = false;
    this.checkAvailability();
  }

  hideSuggestionsWithDelay() {
    setTimeout(() => {
      this.showSuggestions = false;
    }, 200);
  }

  productImageUrl(path?: string): string {
    return getImageUrl(path, 'product');
  }

  onImgError(event: Event) {
    handleImageError(event, 'product');
  }

  checkAvailability() {
    this.showSuggestions = false;
    const code = (this.productCode || '').trim();
    if (!code) {
      this.errorMessage = 'Please enter a valid Product Code (e.g. BL-04-6 or BL-04P-1).';
      return;
    }

    this.loading = true;
    this.searched = true;
    this.errorMessage = '';
    this.productData = null;

    let url = `/booking/product-status/${encodeURIComponent(code)}`;
    if (this.deliveryDate && this.returnDate) {
      url += `?deliveryDate=${this.deliveryDate}&returnDate=${this.returnDate}`;
    }

    this.api.get<any>(url).subscribe({
      next: r => {
        this.loading = false;
        if (r.success && r.data && r.data.product) {
          this.productData = r.data;
        } else {
          this.errorMessage = r.message || `No product found matching code '${code}'. Please check spelling or select from suggestions.`;
        }
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Failed to check product availability. Please check server connection.';
      }
    });
  }

  clearSearch() {
    this.productCode = '';
    this.searched = false;
    this.productData = null;
    this.errorMessage = '';
    this.showSuggestions = false;
  }
}
