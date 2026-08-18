import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { asArray, asRecord, normalizeRow, normalizeRows, pickField } from '../../core/models/api.models';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-invoice',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, FormsModule],
  templateUrl: './invoice.component.html',
  styleUrl: './invoice.component.scss'
})
export class InvoiceComponent implements OnInit {
  booking: any = null;
  items: any[] = [];
  company: any = null;
  whatsappPhone = '';
  whatsappMsg = '';
  auth = inject(AuthService);

  constructor(private route: ActivatedRoute, private api: ApiService) {}

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.api.get<any>(`/booking/${id}`).subscribe(r => {
        if (r.success) {
          const d = asRecord(r.data);
          const header = d['header'] ?? d['Header'];
          this.booking = normalizeRow(header);
          this.items = normalizeRows(d['items'] ?? d['Items']);
          this.loadCompany(this.booking.companyID || this.auth.currentUser()?.companyID);
          this.buildWhatsApp();
        }
      });
    }
  }

  loadCompany(companyId?: number) {
    this.api.get<any>('/company').subscribe(r => {
      if (r.success) {
        const rows = asArray<any>(r.data);
        if (companyId) {
          this.company = rows.find((c: any) => (c.companyID ?? c.CompanyID) === companyId) || rows[0];
        } else if (rows.length) {
          this.company = rows[0];
        }
      }
    });
  }

  imageUrl(path?: string): string {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const base = environment.apiUrl.replace(/\/api\/?$/, '');
    return `${base}${path.startsWith('/') ? path : '/' + path}`;
  }

  buildWhatsApp() {
    const b = this.booking;
    if (!b) return;
    this.whatsappPhone = String(pickField(b, 'contactNo1', 'ContactNo1') ?? '');
    const name = pickField<string>(b, 'customerName', 'CustomerName') ?? '';
    const bookingNo = pickField<string>(b, 'bookingNo', 'BookingNo') ?? '';
    const rentDays = pickField(b, 'rentDays', 'RentDays');
    const delivery = pickField<string>(b, 'deliveryDate', 'DeliveryDate');
    const ret = pickField<string>(b, 'returnDate', 'ReturnDate');
    const advance = pickField(b, 'advanceAmount', 'AdvanceAmount');
    const pending = pickField(b, 'remainingAmount', 'RemainingAmount');
    const cName = this.company?.companyName || this.auth.currentUser()?.companyName || 'RentRiwaaz Fashion Rental';
    this.whatsappMsg = `Hello ${name},\n\nYour Booking Details:\nBooking No: ${bookingNo}\nRental Days: ${rentDays}\nDelivery: ${delivery ? new Date(delivery).toLocaleDateString('en-IN') : ''}\nReturn: ${ret ? new Date(ret).toLocaleDateString('en-IN') : ''}\nAdvance Paid: ₹${advance}\nPending: ₹${pending}\n\nThank You\n${cName}`;
  }

  print() { window.print(); }

  sendWhatsApp() {
    const url = `https://wa.me/91${this.whatsappPhone}?text=${encodeURIComponent(this.whatsappMsg)}`;
    window.open(url, '_blank');
  }
}
