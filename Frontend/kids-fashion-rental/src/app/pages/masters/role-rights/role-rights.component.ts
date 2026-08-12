import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { AlertService } from '../../../core/services/alert.service';
import { APP_MENUS } from '../../../core/config/menu-keys';
import { asArray, normalizeRow, pickField, pickId } from '../../../core/models/api.models';

export interface MenuRight {
  menuKey: string;
  isView: boolean;
  isCreate: boolean;
  isUpdate: boolean;
  isDelete: boolean;
}

@Component({
  selector: 'app-role-rights',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './role-rights.component.html',
  styleUrl: './role-rights.component.scss'
})
export class RoleRightsComponent implements OnInit {
  private api = inject(ApiService);
  private alert = inject(AlertService);

  roles: any[] = [];

  selectedRoleId = 1;

  rights: Record<string, MenuRight> = {};

  menus = APP_MENUS.map(m => ({ key: m.key, label: m.label }));

  message = '';

  showAddRole = false;

  newRoleName = '';

  newRoleDesc = '';

  savingRole = false;



  ngOnInit() {

    this.loadRoles();

  }



  loadRoles(selectLast = false) {

    this.api.get<any>('/master/roles').subscribe(r => {

      if (r.success) {

        this.roles = asArray(r.data);

        if (this.roles.length) {

          if (selectLast) {

            const last = this.roles[this.roles.length - 1];

            this.selectedRoleId = pickId(last, 'roleID', 'RoleID');

          } else if (!this.roles.some(x => pickId(x, 'roleID', 'RoleID') === this.selectedRoleId)) {

            this.selectedRoleId = pickId(this.roles[0], 'roleID', 'RoleID');

          }

          this.loadRights();

        }

      }

    });

  }



  loadRights() {

    this.api.get<any>(`/master/role-rights/${this.selectedRoleId}`).subscribe(r => {

      this.rights = {};

      if (r.success) {

        for (const rowData of asArray<any>(r.data)) {

          const row = normalizeRow(rowData);

          const key = String(pickField(row, 'menuKey', 'MenuKey') ?? '').trim();

          if (!key) continue;

          this.rights[key] = {

            menuKey: key,

            isView: !!(pickField(row, 'isView', 'IsView') ?? pickField(row, 'canAccess', 'CanAccess')),

            isCreate: !!pickField(row, 'isCreate', 'IsCreate'),

            isUpdate: !!pickField(row, 'isUpdate', 'IsUpdate'),

            isDelete: !!pickField(row, 'isDelete', 'IsDelete')

          };

        }

      }

      for (const m of this.menus) {

        if (!this.rights[m.key]) {

          this.rights[m.key] = { menuKey: m.key, isView: false, isCreate: false, isUpdate: false, isDelete: false };

        }

      }

    });

  }



  toggleRow(menuKey: string, on: boolean) {

    const r = this.rights[menuKey];

    if (!r) return;

    r.isView = r.isCreate = r.isUpdate = r.isDelete = on;

  }



  rowAllOn(menuKey: string): boolean {

    const r = this.rights[menuKey];

    return !!(r?.isView && r?.isCreate && r?.isUpdate && r?.isDelete);

  }



  save() {
    const payload = {
      roleID: this.selectedRoleId,
      RoleID: this.selectedRoleId,
      rights: this.menus.map(m => ({
        menuKey: m.key,
        MenuKey: m.key,
        isView: !!this.rights[m.key]?.isView,
        IsView: !!this.rights[m.key]?.isView,
        isCreate: !!this.rights[m.key]?.isCreate,
        IsCreate: !!this.rights[m.key]?.isCreate,
        isUpdate: !!this.rights[m.key]?.isUpdate,
        IsUpdate: !!this.rights[m.key]?.isUpdate,
        isDelete: !!this.rights[m.key]?.isDelete,
        IsDelete: !!this.rights[m.key]?.isDelete,
        canAccess: !!(this.rights[m.key]?.isView || this.rights[m.key]?.isCreate ||
          this.rights[m.key]?.isUpdate || this.rights[m.key]?.isDelete),
        CanAccess: !!(this.rights[m.key]?.isView || this.rights[m.key]?.isCreate ||
          this.rights[m.key]?.isUpdate || this.rights[m.key]?.isDelete)
      }))
    };

    this.api.post('/master/role-rights', payload).subscribe(r => {
      if (r.success) {
        this.message = (r.message || 'Rights saved') + ' — users must log out and log in again to refresh menu.';
        this.alert.toastSuccess('Rights saved successfully');
      } else {
        this.message = r.message || 'Failed';
        this.alert.toastError(this.message);
      }
    });
  }

  addRole() {
    if (!this.newRoleName.trim()) {
      this.alert.toastError('Role name is required');
      return;
    }

    this.savingRole = true;
    this.api.post('/master/roles', { roleName: this.newRoleName.trim(), description: this.newRoleDesc }).subscribe(r => {
      this.savingRole = false;
      if (r.success) {
        this.showAddRole = false;
        this.newRoleName = '';
        this.newRoleDesc = '';
        this.message = r.message || 'Role added';
        this.alert.toastSuccess(this.message);
        this.loadRoles(true);
      } else {
        this.message = r.message || 'Could not add role';
        this.alert.toastError(this.message);
      }
    });
  }
}

