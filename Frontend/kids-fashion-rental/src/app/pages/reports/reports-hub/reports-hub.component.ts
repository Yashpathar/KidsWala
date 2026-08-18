import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-reports-hub',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="reports-hub slide-up">
      <!-- Hero Section -->
      <div class="reports-hero ui-card">
        <div class="hero-content">
          <div class="welcome-badge">
            <i class="bi bi-file-earmark-bar-graph-fill"></i>
            <span>Management Hub</span>
          </div>
          <h2>Analytics & Reports</h2>
          <p class="hero-sub">Monitor store performance, track booking lifecycles, and audit payment flows.</p>
        </div>
      </div>

      <!-- Reports Grid -->
      <div class="report-grid">
        <a routerLink="/reports/delivery" class="ui-card report-card">
          <div class="card-icon-wrap delivery">
            <i class="bi bi-truck"></i>
          </div>
          <div class="card-body">
            <h4>Today Delivery</h4>
            <p>Monitor pending deliveries, print shipping slips, and track dispatch status for today.</p>
          </div>
          <div class="card-footer">
            <span>Open Report</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </a>

        <a routerLink="/reports/return" class="ui-card report-card">
          <div class="card-icon-wrap return">
            <i class="bi bi-arrow-return-left"></i>
          </div>
          <div class="card-body">
            <h4>Today Return</h4>
            <p>Track customer returns, check deposit refunds, and handle late fee audits for today.</p>
          </div>
          <div class="card-footer">
            <span>Open Report</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </a>

        <a routerLink="/booking/list" class="ui-card report-card">
          <div class="card-icon-wrap bookings">
            <i class="bi bi-journal-text"></i>
          </div>
          <div class="card-body">
            <h4>Booking Report</h4>
            <p>Search all historical orders, analyze seasonal rentals, and view detailed customer statements.</p>
          </div>
          <div class="card-footer">
            <span>Open Report</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </a>

        <a routerLink="/reports/payments" class="ui-card report-card">
          <div class="card-icon-wrap payments">
            <i class="bi bi-credit-card-2-front"></i>
          </div>
          <div class="card-body">
            <h4>Payment Report</h4>
            <p>Audit rental earnings, review pending deposit holds, and reconcile expense refunds.</p>
          </div>
          <div class="card-footer">
            <span>Open Report</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </a>
      </div>
    </div>
  `,
  styles: [`
    .reports-hub {
      max-width: 1560px;
      margin: 0 auto;
    }

    .reports-hero {
      padding: 1.5rem 1.75rem;
      margin-bottom: 1.5rem;
      background: linear-gradient(135deg, #ffffff 0%, #fdfcfd 50%, var(--primary-soft) 100%);
      border: 1px solid rgba(220, 151, 80, 0.15);
      position: relative;
      overflow: hidden;
      border-radius: var(--radius-lg);

      &::before {
        content: '';
        position: absolute;
        top: -50px;
        right: -50px;
        width: 220px;
        height: 220px;
        border-radius: 50%;
        background: radial-gradient(circle, rgba(220, 151, 80, 0.1) 0%, rgba(30, 38, 64, 0) 70%);
        pointer-events: none;
      }

      .hero-content {
        .welcome-badge {
          display: inline-flex;
          align-items: center;
          gap: 0.45rem;
          padding: 0.25rem 0.75rem;
          background: var(--primary-light);
          color: var(--primary-dark);
          border-radius: 99px;
          font-size: 0.78rem;
          font-weight: 700;
          margin-bottom: 0.5rem;
        }

        h2 {
          margin: 0;
          font-size: 1.75rem;
          font-weight: 800;
          color: var(--text);
          letter-spacing: -0.03em;
        }

        .hero-sub {
          margin: 0.35rem 0 0;
          color: var(--text-muted);
          font-size: 0.9rem;
        }
      }
    }

    .report-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 1.25rem;
    }

    .report-card {
      padding: 1.5rem;
      text-decoration: none;
      color: inherit;
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      background: #ffffff;
      border-radius: var(--radius-lg);
      border: 1px solid var(--border-light);
      transition: all var(--transition);
      position: relative;
      overflow: hidden;

      &::before {
        content: '';
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        width: 4px;
        background: var(--secondary);
        transition: all var(--transition);
      }

      &:hover {
        transform: translateY(-4px);
        border-color: rgba(220, 151, 80, 0.2);
        box-shadow: 0 12px 20px -8px rgba(220, 151, 80, 0.12), 0 4px 12px rgba(15, 23, 42, 0.03);

        &::before {
          background: var(--primary);
        }

        .card-footer {
          color: var(--primary-dark);
          i { transform: translateX(4px); }
        }
      }
    }

    .card-icon-wrap {
      width: 52px;
      height: 52px;
      border-radius: 14px;
      display: grid;
      place-items: center;
      font-size: 1.35rem;
      margin-bottom: 1.25rem;
      box-shadow: 0 4px 10px rgba(15, 23, 42, 0.02);

      &.delivery { background: rgba(30, 38, 64, 0.05); color: var(--secondary); }
      &.return { background: rgba(220, 151, 80, 0.08); color: var(--primary); }
      &.bookings { background: rgba(16, 185, 129, 0.06); color: #10b981; }
      &.payments { background: rgba(234, 88, 12, 0.06); color: #ea580c; }
    }

    .card-body {
      flex: 1;
      h4 {
        margin: 0 0 0.5rem;
        font-size: 1.1rem;
        font-weight: 700;
        color: var(--text);
      }
      p {
        margin: 0;
        font-size: 0.85rem;
        color: var(--text-muted);
        line-height: 1.45;
      }
    }

    .card-footer {
      margin-top: 1.5rem;
      width: 100%;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 0.82rem;
      font-weight: 700;
      color: var(--text-muted);
      border-top: 1px solid var(--border-light);
      padding-top: 0.85rem;
      transition: color var(--transition);

      i {
        transition: transform var(--transition);
      }
    }
  `]
})
export class ReportsHubComponent {}
