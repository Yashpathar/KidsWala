import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../core/services/api.service';
import { APP_MENUS } from '../../../core/config/menu-keys';
import { asArray, pickId } from '../../../core/models/api.models';

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

        for (const row of asArray<any>(r.data)) {

          const key = row.menuKey ?? row.MenuKey;

          this.rights[key] = {

            menuKey: key,

            isView: !!(row.isView ?? row.IsView ?? row.canAccess ?? row.CanAccess),

            isCreate: !!(row.isCreate ?? row.IsCreate ?? row.canAccess ?? row.CanAccess),

            isUpdate: !!(row.isUpdate ?? row.IsUpdate ?? row.canAccess ?? row.CanAccess),

            isDelete: !!(row.isDelete ?? row.IsDelete ?? row.canAccess ?? row.CanAccess)

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

      rights: this.menus.map(m => ({

        menuKey: m.key,

        isView: !!this.rights[m.key]?.isView,

        isCreate: !!this.rights[m.key]?.isCreate,

        isUpdate: !!this.rights[m.key]?.isUpdate,

        isDelete: !!this.rights[m.key]?.isDelete,

        canAccess: !!(this.rights[m.key]?.isView || this.rights[m.key]?.isCreate ||

          this.rights[m.key]?.isUpdate || this.rights[m.key]?.isDelete)

      }))

    };

    this.api.post('/master/role-rights', payload).subscribe(r => {
      this.message = r.success
        ? (r.message || 'Rights saved') + ' — users must log out and log in again to refresh menu.'
        : (r.message || 'Failed');
    });

  }



  addRole() {

    if (!this.newRoleName.trim()) return;

    this.savingRole = true;

    this.api.post('/master/roles', { roleName: this.newRoleName.trim(), description: this.newRoleDesc }).subscribe(r => {

      this.savingRole = false;

      if (r.success) {

        this.showAddRole = false;

        this.newRoleName = '';

        this.newRoleDesc = '';

        this.message = r.message || 'Role added';

        this.loadRoles(true);

      } else {

        this.message = r.message || 'Could not add role';

      }

    });

  }

}

