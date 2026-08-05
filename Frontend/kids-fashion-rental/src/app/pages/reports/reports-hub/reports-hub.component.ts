import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-reports-hub',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="page-header"><h2>Reports</h2><p class="breadcrumb">All reports</p></div>
    <div class="report-grid">
      <a routerLink="/reports/delivery" class="ui-card report-card"><i class="bi bi-truck"></i><h4>Today Delivery</h4></a>
      <a routerLink="/reports/return" class="ui-card report-card"><i class="bi bi-arrow-return-left"></i><h4>Today Return</h4></a>
      <a routerLink="/booking/list" class="ui-card report-card"><i class="bi bi-journal-text"></i><h4>Booking Report</h4></a>
      <a routerLink="/reports/payments" class="ui-card report-card"><i class="bi bi-credit-card"></i><h4>Payment Report</h4></a>
    </div>
  `,
  styles: [`
    .report-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; }
    .report-card {
      padding: 1.5rem; text-decoration: none; color: inherit; text-align: center;
      transition: transform 0.2s, box-shadow 0.2s;
      i { font-size: 2rem; color: var(--primary); display: block; margin-bottom: 0.5rem; }
      h4 { margin: 0; font-size: 1rem; }
      &:hover { transform: translateY(-4px); box-shadow: var(--shadow); }
    }
  `]
})
export class ReportsHubComponent {}
