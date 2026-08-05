import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { asArray, pickId } from '../../../core/models/api.models';

@Component({
  selector: 'app-branch-master',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './branch-master.component.html',
  styleUrl: './branch-master.component.scss'
})
export class BranchMasterComponent implements OnInit {
  private api = inject(ApiService);
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
    this.saving = true;
    const req = this.form.branchID
      ? this.api.put('/branch', this.form)
      : this.api.post('/branch', this.form);
    req.subscribe({
      next: r => {
        this.saving = false;
        this.message = r.message || '';
        if (r.success) { this.showModal = false; this.load(); }
      },
      error: () => { this.saving = false; }
    });
  }
}
