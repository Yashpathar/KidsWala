import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UserService } from '../../../core/services/user.service';
import { ApiService } from '../../../core/services/api.service';
import { AuthService } from '../../../core/services/auth.service';
import { AlertService } from '../../../core/services/alert.service';
import { asArray, pickId } from '../../../core/models/api.models';

@Component({
  selector: 'app-user-master',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './user-master.component.html',
  styleUrl: './user-master.component.scss'
})
export class UserMasterComponent implements OnInit {
  private userApi = inject(UserService);
  private api = inject(ApiService);
  private alert = inject(AlertService);
  auth = inject(AuthService);

  users: any[] = [];
  companies: any[] = [];
  branches: any[] = [];
  roles: any[] = [];
  
  search = '';
  selectedBranchId: number | null = null;
  activeTab: number | 'all' = 'all';
  
  showModal = false;
  saving = false;
  loading = false;
  message = '';
  messageType: 'success' | 'error' = 'success';

  visiblePasswords: { [userID: number]: boolean } = {};
  showFormPassword = false;

  form: any = {};

  ngOnInit() {
    this.form = this.buildEmptyForm();
    this.loadLookups();
    this.load();
  }

  buildEmptyForm() {
    return {
      userID: 0,
      companyID: this.auth.currentUser()?.companyID || 1,
      branchID: this.auth.currentUser()?.branchID || null,
      roleID: 4, // Default to Staff
      username: '',
      password: '',
      fullName: '',
      email: '',
      mobileNo: '',
      isActive: true
    };
  }

  private showMsg(text: string, type: 'success' | 'error') {
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
    this.api.get<any>('/company').subscribe(r => { if (r.success) this.companies = asArray(r.data); });
    this.api.get<any>('/branch').subscribe(r => { if (r.success) this.branches = asArray(r.data); });
    this.api.get<any>('/master/roles').subscribe(r => { if (r.success) this.roles = asArray(r.data); });
  }

  load() {
    this.loading = true;
    this.userApi.list(this.auth.currentUser()?.companyID, this.selectedBranchId || undefined).subscribe({
      next: res => {
        this.loading = false;
        if (res.success) this.users = asArray(res.data);
        else {
          this.users = [];
          this.showMsg(res.message || 'Failed to load users', 'error');
        }
      },
      error: () => {
        this.loading = false;
        this.showMsg('Failed to load users', 'error');
      }
    });
  }

  get filtered() {
    const q = this.search.toLowerCase().trim();
    if (!q) return this.users;
    return this.users.filter(u =>
      u.username?.toLowerCase().includes(q) ||
      u.fullName?.toLowerCase().includes(q) ||
      u.roleName?.toLowerCase().includes(q) ||
      u.branchName?.toLowerCase().includes(q) ||
      u.mobileNo?.includes(q)
    );
  }

  onBranchFilterChange() {
    this.activeTab = this.selectedBranchId || 'all';
    this.load();
  }

  selectTab(branchId: number | 'all') {
    this.activeTab = branchId;
    this.selectedBranchId = branchId === 'all' ? null : branchId;
    this.load();
  }

  getUserCountByBranch(branchId: number | 'all'): number {
    if (branchId === 'all') return this.users.length;
    return this.users.filter(u => u.branchID === branchId).length;
  }

  openAdd() {
    this.form = this.buildEmptyForm();
    this.showModal = true;
  }

  openEdit(u: any) {
    this.form = {
      userID: pickId(u, 'userID', 'UserID'),
      companyID: u.companyID ?? u.CompanyID ?? 1,
      branchID: u.branchID ?? u.BranchID ?? null,
      roleID: u.roleID ?? u.RoleID ?? 4,
      username: u.username ?? u.UserName ?? '',
      password: '', // Blank unless changing password
      fullName: u.fullName ?? u.FullName ?? '',
      email: u.email ?? u.Email ?? '',
      mobileNo: u.mobileNo ?? u.MobileNo ?? '',
      isActive: u.isActive !== false && u.isActive !== 0
    };
    this.showModal = true;
  }

  save() {
    if (!this.form.username?.trim()) {
      this.showMsg('Username is required', 'error');
      return;
    }
    if (!this.form.userID && !this.form.password?.trim()) {
      this.showMsg('Password is required for new users', 'error');
      return;
    }
    if (!this.form.fullName?.trim()) {
      this.showMsg('Full Name is required', 'error');
      return;
    }
    if (!this.form.roleID) {
      this.showMsg('Role is required', 'error');
      return;
    }

    this.saving = true;
    const isUpdate = this.form.userID > 0;
    const req = isUpdate ? this.userApi.update(this.form) : this.userApi.create(this.form);

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

  async delete(u: any) {
    const id = pickId(u, 'userID', 'UserID');
    if (!id) return;
    const confirmed = await this.alert.confirmDelete(
      `Delete User '${u.username}'?`,
      `Are you sure you want to delete ${u.fullName || u.username}? This action cannot be undone.`
    );
    if (!confirmed) return;

    this.loading = true;
    this.userApi.delete(id).subscribe({
      next: res => {
        this.loading = false;
        if (res.success) {
          this.alert.toastSuccess(res.message || 'User deleted successfully');
          this.load();
        } else {
          const msg = res.message || 'Delete failed: User account is associated with active transactions or booking records.';
          this.alert.error('Cannot Delete User', msg);
        }
      },
      error: () => {
        this.loading = false;
        this.alert.error('Delete Failed', 'An error occurred while attempting to delete user.');
      }
    });
  }

  closeModal() {
    if (!this.saving) this.showModal = false;
  }

  togglePasswordVisibility(userID: number) {
    this.visiblePasswords[userID] = !this.visiblePasswords[userID];
  }

  toggleFormPassword() {
    this.showFormPassword = !this.showFormPassword;
  }

  getRoleBadgeClass(roleName: string): string {
    const r = (roleName || '').toLowerCase();
    if (r.includes('superadmin')) return 'badge-superadmin';
    if (r.includes('admin')) return 'badge-admin';
    if (r.includes('branch')) return 'badge-branch';
    return 'badge-staff';
  }
}
