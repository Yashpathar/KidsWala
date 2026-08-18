import { Component, OnInit, inject } from '@angular/core';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration } from 'chart.js';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { asArray, asRecord, normalizeRow, pickField } from '../../core/models/api.models';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [BaseChartDirective, CurrencyPipe, DatePipe, RouterLink],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  private api = inject(ApiService);
  auth = inject(AuthService);

  loading = true;
  counts: Record<string, number> = {};
  dashboardTitle = 'Dashboard';
  dashboardSubtitle = 'Welcome back';
  todayDate = new Date();
  topProducts: { productName: string; total: number }[] = [];
  todayDeliveries: Record<string, unknown>[] = [];
  todayReturns: Record<string, unknown>[] = [];
  statusTotal = 0;

  incomeChart: ChartConfiguration<'line'> = {
    type: 'line',
    data: {
      labels: [],
      datasets: [{
        data: [],
        label: 'Income',
        borderColor: '#dc9750',
        backgroundColor: 'rgba(220, 151, 80, 0.12)',
        fill: true,
        tension: 0.4,
        borderWidth: 3,
        pointRadius: 6,
        pointBackgroundColor: '#fff',
        pointBorderColor: '#dc9750',
        pointBorderWidth: 3
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        y: {
          beginAtZero: true,
          grid: { color: '#f1f5f9' },
          border: { display: false },
          ticks: {
            callback: v => {
              const n = Number(v);
              return n >= 1000 ? `${n / 1000}K` : String(n);
            }
          }
        },
        x: { grid: { display: false }, border: { display: false } }
      }
    }
  };

  statusChart: ChartConfiguration<'bar'> = {
    type: 'bar',
    data: {
      labels: [],
      datasets: [{
        data: [],
        backgroundColor: [],
        borderWidth: 0,
        borderRadius: 6,
        barThickness: 18
      }]
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: {
          beginAtZero: true,
          grid: { color: '#f8fafc' },
          border: { display: false },
          ticks: { precision: 0 }
        },
        y: {
          grid: { display: false },
          border: { display: false },
          ticks: {
            font: { weight: 'bold' }
          }
        }
      }
    }
  };

  private readonly statusColors: Record<string, string> = {
    Booked: '#dc9750',
    Delivered: '#22C55E',
    Returned: '#F59E0B',
    'Late Returned': '#F97316',
    Cancelled: '#EF4444',
    Completed: '#10B981'
  };

  ngOnInit() {
    if (this.auth.isPlatformAdmin()) {
      this.dashboardTitle = 'System Dashboard';
      this.dashboardSubtitle = 'Super Admin · all companies';
    } else if (this.auth.isCompanyAdmin()) {
      this.dashboardTitle = 'Company Dashboard';
      this.dashboardSubtitle = this.auth.currentUser()?.companyName || 'Company';
    } else if (this.auth.isBranchAdmin()) {
      this.dashboardTitle = 'Branch Dashboard';
      this.dashboardSubtitle = this.auth.currentUser()?.branchName || 'Branch';
    } else if (this.auth.isBranchStaff()) {
      this.dashboardTitle = 'My Work';
      this.dashboardSubtitle = 'Staff · own entries';
    }

    const companyId = this.auth.currentUser()?.companyID;
    this.api.get<unknown>('/dashboard/summary', { companyId }).subscribe({
      next: r => {
        this.loading = false;
        if (!r.success || !r.data) return;
        const data = asRecord(r.data);
        const c = asRecord(data['counts'] ?? data['Counts']);
        this.counts = {
          totalCompanies: Number(c['totalCompanies'] ?? c['TotalCompanies'] ?? 0),
          totalBranches: Number(c['totalBranches'] ?? c['TotalBranches'] ?? 0),
          totalUsers: Number(c['totalUsers'] ?? c['TotalUsers'] ?? 0),
          totalBookings: Number(c['totalBookings'] ?? c['TotalBookings'] ?? 0),
          todayDeliveries: Number(c['todayDeliveries'] ?? c['TodayDeliveries'] ?? 0),
          todayReturns: Number(c['todayReturns'] ?? c['TodayReturns'] ?? 0),
          pendingPayments: Number(c['pendingPayments'] ?? c['PendingPayments'] ?? 0),
          pendingDeposit: Number(c['pendingDeposit'] ?? c['PendingDeposit'] ?? 0),
          refundDepositAmount: Number(c['refundDepositAmount'] ?? c['RefundDepositAmount'] ?? 0),
          availableProducts: Number(c['availableProducts'] ?? c['AvailableProducts'] ?? 0),
          totalIncome: Number(c['totalIncome'] ?? c['TotalIncome'] ?? 0),
          totalExpenses: Number(c['totalExpenses'] ?? c['TotalExpenses'] ?? 0),
          netProfit: Number(c['netProfit'] ?? c['NetProfit'] ?? 0)
        };

        const income = asArray<unknown>(data['monthlyIncome'] ?? data['MonthlyIncome']);
        this.incomeChart.data.labels = income.map(x => this.formatMonth(x));
        this.incomeChart.data.datasets[0].data = income.map(x =>
          Number(pickField(normalizeRow(x), 'income', 'Income') ?? 0)
        );

        const status = asArray<unknown>(data['bookingStatus'] ?? data['BookingStatus']);
        this.statusChart.data.labels = status.map(x =>
          String(pickField(normalizeRow(x), 'statusName', 'StatusName') ?? '')
        );
        this.statusChart.data.datasets[0].data = status.map(x =>
          Number(pickField(normalizeRow(x), 'total', 'Total') ?? 0)
        );
        this.statusChart.data.datasets[0].backgroundColor = this.statusChart.data.labels.map(
          l => this.statusColors[String(l)] || '#8E6BFF'
        );
        this.statusTotal = (this.statusChart.data.datasets[0].data as number[]).reduce((a, b) => a + b, 0);

        this.topProducts = asArray<unknown>(data['topProducts'] ?? data['TopProducts']).map(x => {
          const row = normalizeRow(x);
          return {
            productName: String(pickField(row, 'productName', 'ProductName') ?? ''),
            total: Number(pickField(row, 'total', 'Total') ?? 0)
          };
        });

        this.todayDeliveries = asArray(data['todayDeliveries'] ?? data['TodayDeliveries']).map(normalizeRow);
        this.todayReturns = asArray(data['todayReturns'] ?? data['TodayReturns']).map(normalizeRow);
      },
      error: () => (this.loading = false)
    });
  }

  private formatMonth(row: unknown): string {
    const label = String(pickField(normalizeRow(row), 'monthLabel', 'MonthLabel') ?? '');
    if (!label) return '';
    const [y, m] = label.split('-');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[Number(m) - 1] || label;
  }

  statusClass(status: string): string {
    const s = (status || '').toLowerCase();
    if (s.includes('deliver')) return 'delivered';
    if (s.includes('return')) return 'returned';
    if (s.includes('book')) return 'booked';
    if (s.includes('cancel')) return 'cancelled';
    return 'booked';
  }

  topProductWidth(total: number): string {
    const max = Math.max(...this.topProducts.map(p => p.total), 1);
    return `${Math.round((total / max) * 100)}%`;
  }

  asStr(v: unknown): string {
    return String(v ?? '');
  }
}
