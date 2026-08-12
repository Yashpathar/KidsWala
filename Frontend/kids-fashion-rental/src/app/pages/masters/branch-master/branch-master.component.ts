import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../../core/services/auth.service';
import { ApiService } from '../../../core/services/api.service';
import { AlertService } from '../../../core/services/alert.service';
import { asArray, pickId } from '../../../core/models/api.models';

@Component({
  selector: 'app-branch-master',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './branch-master.component.html',
  styleUrl: './branch-master.component.scss'
})
export class BranchMasterComponent implements OnInit {
  auth = inject(AuthService);
  private api = inject(ApiService);
  private alert = inject(AlertService);
  rows: any[] = [];
  companies: any[] = [];
  showModal = false;
  saving = false;
  message = '';

  form: any = {};

  ngOnInit() {
    this.api.get<any>('/company').subscribe(r => {
      if (r.success) this.companies = asArray(r.data);
    });
    this.load();
  }

  load() {
    this.api.get<any>('/branch').subscribe(r => {
      if (r.success) this.rows = asArray(r.data);
    });
  }

  openAdd() {
    this.form = { branchID: 0, companyID: this.companies[0]?.companyID ?? 0, branchName: '', branchCode: '', address: '', mobileNo: '', email: '', isActive: true };
    this.showModal = true;
  }

  openEdit(b: any) {
    this.form = { ...b, branchID: pickId(b, 'branchID', 'BranchID'), companyID: pickId(b, 'companyID', 'CompanyID') };
    this.showModal = true;
  }

  save() {
    if (!this.form.branchName?.trim()) {
      this.alert.toastError('Branch Name is required');
      return;
    }
    this.saving = true;
    const req = this.form.branchID
      ? this.api.put('/branch', this.form)
      : this.api.post('/branch', this.form);
    req.subscribe({
      next: r => {
        this.saving = false;
        this.message = r.message || '';
        if (r.success) {
          this.alert.toastSuccess(r.message || 'Branch saved successfully');
          this.showModal = false;
          this.load();
        } else {
          this.alert.toastError(r.message || 'Could not save branch');
        }
      },
      error: () => {
        this.saving = false;
        this.alert.toastError('Save request failed');
      }
    });
  }

  async deleteBranch(b: any) {
    const id = pickId(b, 'branchID', 'BranchID');
    const name = b.branchName || b.BranchName || 'Branch';
    if (!id) return;

    const confirmed = await this.alert.confirmDelete(
      'Delete Branch?',
      `Are you sure you want to delete branch "${name}"?`
    );
    if (!confirmed) return;

    this.api.delete<any>(`/branch/${id}`).subscribe({
      next: r => {
        if (r.success) {
          this.alert.toastSuccess(r.message || 'Branch deleted successfully');
          this.load();
        } else {
          const msg = r.message || 'Delete failed: Branch has active users, products, or bookings.';
          this.alert.error('Cannot Delete Branch', msg);
        }
      },
      error: () => {
        this.alert.error('Delete Failed', 'An error occurred while attempting to delete branch.');
      }
    });
  }
}
