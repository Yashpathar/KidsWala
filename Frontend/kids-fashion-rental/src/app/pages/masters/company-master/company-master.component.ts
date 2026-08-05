import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { asArray, pickId } from '../../../core/models/api.models';

@Component({
  selector: 'app-company-master',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './company-master.component.html',
  styleUrl: './company-master.component.scss'
})
export class CompanyMasterComponent implements OnInit {
  private api = inject(ApiService);
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
        }
      },
      error: () => {
        this.rows = [];
        this.error = 'Could not load companies. Restart API and log in as Super Admin.';
      }
    });
  }

  openAdd() {
    this.form = { companyID: 0, companyName: '', companyCode: '', businessType: '', address: '', mobileNo: '', email: '', gstNo: '', isActive: true };
    this.showModal = true;
  }

  openEdit(c: any) {
    this.form = { ...c, companyID: pickId(c, 'companyID', 'CompanyID') };
    this.showModal = true;
  }

  save() {
    if (!this.form.companyName?.trim()) {
      this.error = 'Company name is required';
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
          this.showModal = false;
          this.load();
        } else {
          this.error = r.message || 'Could not save company';
        }
      },
      error: () => {
        this.saving = false;
        this.error = 'Save failed. Check API is running on port 5001.';
      }
    });
  }
}
