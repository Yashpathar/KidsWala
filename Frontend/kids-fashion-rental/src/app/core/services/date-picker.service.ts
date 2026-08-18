import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class DatePickerService {
  private activePickerSubject = new Subject<any>();
  activePicker$ = this.activePickerSubject.asObservable();

  registerOpen(pickerInstance: any): void {
    this.activePickerSubject.next(pickerInstance);
  }
}
