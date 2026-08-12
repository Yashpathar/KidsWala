import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../../core/services/auth.service';
import { ApiService } from '../../../core/services/api.service';
import { AlertService } from '../../../core/services/alert.service';
import { asArray, pickId } from '../../../core/models/api.models';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-company-master',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './company-master.component.html',
  styleUrl: './company-master.component.scss'
})
export class CompanyMasterComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);
  private alert = inject(AlertService);
  rows: any[] = [];
  showModal = false;
  saving = false;
  message = '';
  error = '';
  form: any = {};

  ngOnInit() { this.load(); }

  load() {
    this.api.get<any>('/company').subscribe({
      next: r => {
        if (r.success) {
          this.rows = asArray(r.data);
          this.error = '';
        } else {
          this.rows = [];
          this.error = r.message || 'Could not load companies';
          this.alert.toastError(this.error);
        }
      },
      error: () => {
        this.rows = [];
        this.error = 'Could not load companies. Restart API and log in as Super Admin.';
        this.alert.toastError(this.error);
      }
    });
  }

  openAdd() {
    this.form = { companyID: 0, companyName: '', companyCode: '', businessType: '', address: '', mobileNo: '', email: '', gstNo: '', logoImage: '', isActive: true };
    this.showModal = true;
  }

  openEdit(c: any) {
    this.form = {
      ...c,
      companyID: pickId(c, 'companyID', 'CompanyID'),
      logoImage: c.logoImage || c.LogoImage || ''
    };
    this.showModal = true;
  }

  onLogoSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length) return;
    this.api.uploadFile<any>('/upload/image', input.files[0]).subscribe(res => {
      if (res.success) {
        this.form.logoImage = res.data;
        this.alert.toastSuccess('Logo uploaded successfully');
      } else {
        this.alert.toastError(res.message || 'Logo upload failed');
      }
    });
  }

  imageUrl(path?: string): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = environment.apiUrl.replace(/\/api\/?$/, '');
    return `${base}${path.startsWith('/') ? path : '/' + path}`;
  }

  save() {
    if (!this.form.companyName?.trim()) {
      this.error = 'Company name is required';
      this.alert.toastError(this.error);
      return;
    }
    this.saving = true;
    this.error = '';
    this.message = '';
    const req = this.form.companyID
      ? this.api.put('/company', this.form)
      : this.api.post('/company', this.form);
    req.subscribe({
      next: r => {
        this.saving = false;
        if (r.success) {
          this.message = r.message || 'Company saved';
          this.alert.toastSuccess(this.message);
          this.showModal = false;
          this.load();
        } else {
          this.error = r.message || 'Could not save company';
          this.alert.toastError(this.error);
        }
      },
      error: () => {
        this.saving = false;
        this.error = 'Save failed. Check API is running.';
        this.alert.toastError(this.error);
      }
    });
  }

  async deleteCompany(c: any) {
    const id = pickId(c, 'companyID', 'CompanyID');
    const name = c.companyName || c.CompanyName || 'Company';
    if (!id) return;

    const confirmed = await this.alert.confirmDelete(
      'Delete Company?',
      `Are you sure you want to delete company "${name}"?`
    );
    if (!confirmed) return;

    this.api.delete<any>(`/company/${id}`).subscribe({
      next: r => {
        if (r.success) {
          this.alert.toastSuccess(r.message || 'Company deleted successfully');
          this.load();
        } else {
          const msg = r.message || 'Delete failed: Company has active branches, users, or products.';
          this.alert.error('Cannot Delete Company', msg);
        }
      },
      error: () => {
        this.alert.error('Delete Failed', 'An error occurred while attempting to delete company.');
      }
    });
  }
}
