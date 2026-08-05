import { Component, OnInit, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { ApiService } from '../../core/services/api.service';
import { asArray, normalizeRow, pickField, pickId } from '../../core/models/api.models';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './main-layout.component.html',
  styleUrl: './main-layout.component.scss'
})
export class MainLayoutComponent implements OnInit {
  sidebarOpen = true;
  auth = inject(AuthService);
  private api = inject(ApiService);
  notifications: { notificationID: number; title: string; message: string; isRead: boolean }[] = [];
  notifOpen = false;

  ngOnInit() {
    this.loadNotifications();
    if (this.auth.isLoggedIn() && !this.auth.hasMenuRights()) {
      this.auth.loadMenuRights().subscribe();
    }
  }

  loadNotifications() {
    this.api.get<unknown>('/notification', {
      companyId: this.auth.currentUser()?.companyID,
      top: 10
    }).subscribe(r => {
      if (r.success) {
        this.notifications = asArray(r.data).map(x => {
          const row = normalizeRow(x);
          return {
            notificationID: pickId(row, 'notificationID', 'NotificationID'),
            title: String(pickField(row, 'title', 'Title') ?? ''),
            message: String(pickField(row, 'message', 'Message') ?? ''),
            isRead: !!(row['isRead'] ?? row['IsRead'])
          };
        });
      }
    });
  }

  unreadCount() {
    return this.notifications.filter(n => !n.isRead).length;
  }

  markRead(n: { notificationID: number }) {
    this.api.post(`/notification/${n.notificationID}/read`, {}).subscribe(() => this.loadNotifications());
  }

  toggleSidebar() { this.sidebarOpen = !this.sidebarOpen; }
}
