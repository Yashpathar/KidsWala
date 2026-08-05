import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { LowerCasePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MastersService } from '../../../core/services/masters.service';
import { AuthService } from '../../../core/services/auth.service';
import { asArray, pickId } from '../../../core/models/api.models';

export interface MasterConfig {
  type: string;
  title: string;
  idField: string;
  columns: { key: string; label: string }[];
  fields: { key: string; label: string; type?: string; required?: boolean }[];
}

@Component({
  selector: 'app-master-crud',
  standalone: true,
  imports: [FormsModule, LowerCasePipe],
  templateUrl: './master-crud.component.html',
  styleUrl: './master-crud.component.scss'
})
export class MasterCrudComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private masters = inject(MastersService);
  auth = inject(AuthService);

  config!: MasterConfig;
  rows: any[] = [];
  search = '';
  showModal = false;
  viewMode = false;
  modalTitle = '';
  form: Record<string, unknown> = {};
  message = '';
  messageType: 'success' | 'error' = 'success';
  loading = false;
  saving = false;

  ngOnInit() {
    this.config = this.route.snapshot.data['config'] as MasterConfig;
    if (!this.config?.type) {
      this.showMsg('Master configuration not found for this route', 'error');
      return;
    }
    this.load();
  }

  get filteredRows() {
    const q = this.search.toLowerCase().trim();
    let list = this.rows;
    if (q) {
      list = list.filter(r =>
        this.config.columns.some(c => String(r[c.key] ?? '').toLowerCase().includes(q))
      );
    }

    if (this.config?.type === 'size') {
      return [...list].sort((a, b) => {
        const orderA = Number(a.sortOrder ?? a.SortOrder);
        const orderB = Number(b.sortOrder ?? b.SortOrder);
        if (orderA !== 0 || orderB !== 0) {
          if (orderA !== orderB) return orderA - orderB;
        }

        const sA = String(a.sizeName ?? a.SizeName ?? a.size ?? a.Size ?? '');
        const sB = String(b.sizeName ?? b.SizeName ?? b.size ?? b.Size ?? '');
        const numA = parseFloat(sA);
        const numB = parseFloat(sB);

        if (!isNaN(numA) && !isNaN(numB)) {
          return numA - numB;
        }
        return sA.localeCompare(sB, undefined, { numeric: true, sensitivity: 'base' });
      });
    }

    return list;
  }

  private showMsg(text: string, type: 'success' | 'error') {
    this.message = text;
    this.messageType = type;
    if (type === 'success') {
      setTimeout(() => { if (this.message === text) this.message = ''; }, 4000);
    }
  }

  load() {
    this.loading = true;
    const companyId = this.auth.currentUser()?.companyID;
    this.masters.list(this.config.type, companyId).subscribe({
      next: res => {
        this.loading = false;
        if (res.success) {
          this.rows = asArray<any>(res.data);
        } else {
          this.rows = [];
          this.showMsg(res.message || 'Failed to load data', 'error');
        }
      },
      error: () => {
        this.loading = false;
        this.showMsg('Failed to load data', 'error');
      }
    });
  }

  openAdd() {
    this.viewMode = false;
    this.modalTitle = `Add ${this.config.title}`;
    this.form = {
      companyID: this.auth.currentUser()?.companyID || 1,
      isActive: true,
      sortOrder: 0
    };
    (this.form as Record<string, unknown>)[this.config.idField] = 0;
    this.config.fields.forEach(f => {
      if (!(f.key in this.form)) this.form[f.key] = f.type === 'checkbox' ? true : '';
    });
    this.showModal = true;
  }

  openEdit(row: any, view = false) {
    this.viewMode = view;
    this.modalTitle = view ? `View ${this.config.title}` : `Edit ${this.config.title}`;
    const id = pickId(row, this.config.idField, this.capitalize(this.config.idField));
    this.form = {
      ...row,
      companyID: row.companyID ?? row.CompanyID ?? this.auth.currentUser()?.companyID ?? 1,
      isActive: row.isActive === true || row.isActive === 1 || row.IsActive === true,
      [this.config.idField]: id
    };
    this.showModal = true;
  }

  private capitalize(s: string) {
    return s.charAt(0).toUpperCase() + s.slice(1);
  }

  private preparePayload(): Record<string, unknown> {
    const payload: Record<string, unknown> = {
      companyID: Number(this.auth.currentUser()?.companyID || 1)
    };
    this.config.fields.forEach(f => {
      let val = this.form[f.key];
      if (f.type === 'checkbox') val = val === true || val === 'true' || val === 1;
      if (f.type === 'number') val = val === '' || val === null ? 0 : Number(val);
      if (f.type !== 'checkbox' && f.type !== 'number' && typeof val === 'string') val = val.trim();
      payload[f.key] = val;
    });
    payload[this.config.idField] = Number(this.form[this.config.idField] || 0);
    return payload;
  }

  private validate(): string | null {
    for (const f of this.config.fields) {
      if (!f.required) continue;
      const v = this.form[f.key];
      if (v === null || v === undefined || String(v).trim() === '') {
        return `${f.label} is required`;
      }
    }
    return null;
  }

  save() {
    const err = this.validate();
    if (err) {
      this.showMsg(err, 'error');
      return;
    }
    const payload = this.preparePayload();
    const id = Number(payload[this.config.idField] || 0);
    const isUpdate = id > 0;

    this.saving = true;
    const req = isUpdate
      ? this.masters.update(this.config.type, payload)
      : this.masters.create(this.config.type, payload);

    req.subscribe({
      next: res => {
        this.saving = false;
        if (res.success) {
          this.showMsg(res.message || (isUpdate ? 'Updated successfully' : 'Saved successfully'), 'success');
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

  confirmDelete(row: any) {
    const id = pickId(row, this.config.idField, this.capitalize(this.config.idField));
    if (!id) {
      this.showMsg('Invalid record id', 'error');
      return;
    }
    if (!confirm('Delete this record?')) return;

    this.loading = true;
    this.masters.delete(this.config.type, id).subscribe({
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

  trackRow(_index: number, row: unknown) {
    return pickId(row, this.config.idField, this.capitalize(this.config.idField)) || _index;
  }
}
