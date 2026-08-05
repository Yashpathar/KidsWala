import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { CurrencyPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';
import { asArray, asRecord, normalizeRow, normalizeRows, pickField } from '../../core/models/api.models';

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
  whatsappPhone = '';
  whatsappMsg = '';

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
          this.buildWhatsApp();
        }
      });
    }
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
    this.whatsappMsg = `Hello ${name},\n\nYour Booking Details:\nBooking No: ${bookingNo}\nRental Days: ${rentDays}\nDelivery: ${delivery ? new Date(delivery).toLocaleDateString('en-IN') : ''}\nReturn: ${ret ? new Date(ret).toLocaleDateString('en-IN') : ''}\nAdvance Paid: ₹${advance}\nPending: ₹${pending}\n\nThank You\nKids Fashion Rental Wear`;
  }

  print() { window.print(); }

  sendWhatsApp() {
    const url = `https://wa.me/91${this.whatsappPhone}?text=${encodeURIComponent(this.whatsappMsg)}`;
    window.open(url, '_blank');
  }
}
