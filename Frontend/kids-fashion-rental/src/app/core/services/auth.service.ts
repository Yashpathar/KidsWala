import { Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { ApiService } from './api.service';
import { tap } from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ApiResult, asArray, normalizeRow, pickField } from '../models/api.models';

export interface UserInfo {
  userID: number;
  roleID?: number;
  fullName: string;
  userName: string;
  roleName: string;
  companyID?: number;
  companyName?: string;
  companyLogo?: string;
  branchID?: number;
  branchName?: string;
  dataScope?: string;
}

export interface MenuRight {
  menuKey: string;
  canAccess?: boolean;
  isView?: boolean;
  isCreate?: boolean;
  isUpdate?: boolean;
  isDelete?: boolean;
}

const SESSION_MS = 24 * 60 * 60 * 1000;
const RIGHTS_KEY = 'menuRights';

@Injectable({ providedIn: 'root' })
export class AuthService {
  currentUser = signal<UserInfo | null>(null);
  menuRights = signal<MenuRight[]>([]);
  private sessionTimer?: ReturnType<typeof setTimeout>;

  constructor(private api: ApiService, private router: Router) {
    const u = localStorage.getItem('user');
    const rights = localStorage.getItem(RIGHTS_KEY);
    if (u && this.isSessionValid()) {
      this.currentUser.set(JSON.parse(u));
      if (rights) {
        try {
          this.menuRights.set(JSON.parse(rights));
        } catch {
          this.menuRights.set([]);
        }
      }
      this.scheduleAutoLogout();
    } else if (localStorage.getItem('token')) {
      this.clearSession();
    }
  }

  login(userName: string, password: string): Observable<ApiResult> {
    return this.api.post<unknown>('/auth/login', { userName, password }).pipe(
      tap(res => this.applyLoginResponse(res))
    );
  }

  loadMenuRights(): Observable<ApiResult> {
    return this.api.get<unknown>('/auth/menu-rights').pipe(
      tap(res => {
        if (res.success) this.setMenuRights(asArray(res.data));
      })
    );
  }

  hasMenuRights(): boolean {
    return this.menuRights().length > 0;
  }

  canViewMenu(menuKey: string): boolean {
    if (this.isPlatformAdmin()) return true;

    const rights = this.menuRights();
    if (rights.length) {
      const row = rights.find(r => r.menuKey === menuKey);
      if (!row) return false;
      return !!(
        row.isView ||
        row.isCreate ||
        row.isUpdate ||
        row.isDelete ||
        row.canAccess
      );
    }

    return this.defaultMenuAccess(menuKey);
  }

  canViewAnyMenu(keys: string[]): boolean {
    return keys.some(k => this.canViewMenu(k));
  }

  canCreateMenu(menuKey: string): boolean {
    const row = this.menuRights().find(r => r.menuKey === menuKey);
    return !!(row?.isCreate);
  }

  canUpdateMenu(menuKey: string): boolean {
    const row = this.menuRights().find(r => r.menuKey === menuKey);
    return !!(row?.isUpdate);
  }

  canDeleteMenu(menuKey: string): boolean {
    const row = this.menuRights().find(r => r.menuKey === menuKey);
    return !!(row?.isDelete);
  }

  private defaultMenuAccess(menuKey: string): boolean {
    if (this.isCompanyAdmin()) {
      return !['company', 'roleRights'].includes(menuKey);
    }
    if (this.isBranchAdmin()) {
      return [
        'dashboard',
        'category',
        'size',
        'color',
        'product',
        'bookingAdd',
        'bookingList',
        'availabilityCheck',
        'reportDelivery',
        'reportReturn'
      ].includes(menuKey);
    }
    if (this.isBranchStaff()) {
      return ['dashboard', 'bookingAdd', 'bookingList', 'availabilityCheck', 'reportDelivery', 'reportReturn'].includes(menuKey);
    }
    return menuKey === 'dashboard';
  }

  private applyLoginResponse(res: ApiResult) {
    if (!res.success || !res.data) return;
    const d = res.data as Record<string, unknown>;
    const token = String(d['token'] ?? d['Token'] ?? '');
    const user = (d['user'] ?? d['User']) as Record<string, unknown>;
    if (!token || !user) return;

    const expiresAt = d['expiresAt'] ?? d['ExpiresAt'];
    const expiryMs = expiresAt ? new Date(String(expiresAt)).getTime() : Date.now() + SESSION_MS;

    localStorage.setItem('token', token);
    localStorage.setItem('loginExpiresAt', String(expiryMs));

    const mapped: UserInfo = {
      userID: Number(user['userID'] ?? user['UserID'] ?? 0),
      roleID: Number(user['roleID'] ?? user['RoleID'] ?? 0) || undefined,
      fullName: String(user['fullName'] ?? user['FullName'] ?? ''),
      userName: String(user['userName'] ?? user['UserName'] ?? ''),
      roleName: String(user['roleName'] ?? user['RoleName'] ?? ''),
      companyID: Number(user['companyID'] ?? user['CompanyID'] ?? 0) || undefined,
      companyName: String(user['companyName'] ?? user['CompanyName'] ?? ''),
      companyLogo: String(user['companyLogo'] ?? user['CompanyLogo'] ?? user['logoImage'] ?? user['LogoImage'] ?? ''),
      branchID: Number(user['branchID'] ?? user['BranchID'] ?? 0) || undefined,
      branchName: String(user['branchName'] ?? user['BranchName'] ?? ''),
      dataScope: String(user['dataScope'] ?? user['DataScope'] ?? 'CompanyAll')
    };
    localStorage.setItem('user', JSON.stringify(mapped));
    this.currentUser.set(mapped);

    const rightsRaw = d['menuRights'] ?? d['MenuRights'];
    if (rightsRaw) {
      this.setMenuRights(this.mapMenuRights(rightsRaw));
    }

    this.scheduleAutoLogout();
  }

  private mapMenuRights(raw: unknown): MenuRight[] {
    return asArray(raw).map(x => {
      const row = normalizeRow(x);
      return {
        menuKey: String(pickField(row, 'menuKey', 'MenuKey') ?? ''),
        canAccess: !!(row['canAccess'] ?? row['CanAccess']),
        isView: !!(row['isView'] ?? row['IsView']),
        isCreate: !!(row['isCreate'] ?? row['IsCreate']),
        isUpdate: !!(row['isUpdate'] ?? row['IsUpdate']),
        isDelete: !!(row['isDelete'] ?? row['IsDelete'])
      };
    });
  }

  private setMenuRights(rights: MenuRight[]) {
    this.menuRights.set(rights);
    localStorage.setItem(RIGHTS_KEY, JSON.stringify(rights));
  }

  getDashboardRoute(): string {
    return '/dashboard';
  }

  dataScope(): string {
    return this.currentUser()?.dataScope ?? 'CompanyAll';
  }

  isPlatformAdmin(): boolean {
    return this.dataScope() === 'Platform' || this.currentUser()?.roleID === 1;
  }

  isCompanyAdmin(): boolean {
    return this.dataScope() === 'CompanyAll' || this.currentUser()?.roleID === 2;
  }

  isBranchAdmin(): boolean {
    return this.dataScope() === 'BranchAll' || this.currentUser()?.roleID === 3;
  }

  isBranchStaff(): boolean {
    const s = this.dataScope();
    return s === 'BranchOwnOnly' || s === 'OwnBookingsOnly' || this.currentUser()?.roleID === 4;
  }

  /** @deprecated Use canViewMenu('category') etc. */
  canUseMasters(): boolean {
    return this.canViewAnyMenu(['category', 'size', 'color', 'product']);
  }

  canUseCompanyReports(): boolean {
    return this.canViewAnyMenu(['reportBooking', 'reportPayment']);
  }

  canUseBranchReports(): boolean {
    return this.canViewAnyMenu(['reportDelivery', 'reportReturn', 'reportBooking', 'reportPayment']);
  }

  isSessionValid(): boolean {
    const exp = localStorage.getItem('loginExpiresAt');
    if (!exp) return !!localStorage.getItem('token');
    return Date.now() < Number(exp);
  }

  private scheduleAutoLogout() {
    if (this.sessionTimer) clearTimeout(this.sessionTimer);
    const exp = localStorage.getItem('loginExpiresAt');
    if (!exp) return;
    const remaining = Number(exp) - Date.now();
    if (remaining <= 0) {
      this.logout();
      return;
    }
    this.sessionTimer = setTimeout(() => this.logout(), remaining);
  }

  logout() {
    if (this.sessionTimer) clearTimeout(this.sessionTimer);
    this.clearSession();
    this.router.navigate(['/login']);
  }

  private clearSession() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('loginExpiresAt');
    localStorage.removeItem(RIGHTS_KEY);
    this.currentUser.set(null);
    this.menuRights.set([]);
  }

  isLoggedIn() {
    return !!localStorage.getItem('token') && this.isSessionValid();
  }

  isSuperAdmin(): boolean {
    return this.isPlatformAdmin();
  }
}
