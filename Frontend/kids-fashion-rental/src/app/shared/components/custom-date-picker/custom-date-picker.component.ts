import { Component, Input, Output, EventEmitter, forwardRef, ElementRef, HostListener, OnInit, OnDestroy, inject } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { Subject, takeUntil } from 'rxjs';
import { DatePickerService } from '../../../core/services/date-picker.service';

interface CalendarDay {
  date: Date;
  dateStr: string;
  dayNum: number;
  isCurrentMonth: boolean;
  isToday: boolean;
  isSelected: boolean;
}

@Component({
  selector: 'app-custom-datepicker',
  standalone: true,
  imports: [DatePipe],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => CustomDatePickerComponent),
      multi: true
    }
  ],
  template: `
    <div class="custom-date-picker-wrap pos-rel">
      @if (label) {
        <label class="picker-label">{{ label }}</label>
      }
      <div
        class="custom-date-trigger"
        [class.active]="isOpen"
        [class.disabled]="disabled"
        (click)="onTriggerClick($event)"
      >
        <span>
          <i class="bi bi-calendar-event me-2 text-gold"></i>
          {{ (value | date:'dd-MM-yyyy') || placeholder || 'Select Date' }}
        </span>
        <i class="bi bi-calendar3 icon-btn"></i>
      </div>

      @if (isOpen) {
        <div class="custom-calendar-dropdown ui-card anim-pop" [class.drop-up]="dropUp" (click)="$event.stopPropagation()">
          <div class="calendar-header">
            <button type="button" class="btn-nav" (click)="prevMonth($event)"><i class="bi bi-chevron-left"></i></button>
            <span class="month-title">{{ calendarCurrentMonth | date:'MMMM yyyy' }}</span>
            <button type="button" class="btn-nav" (click)="nextMonth($event)"><i class="bi bi-chevron-right"></i></button>
          </div>

          <div class="calendar-weekdays">
            <span>Mo</span><span>Tu</span><span>We</span><span>Th</span><span>Fr</span><span>Sa</span><span>Su</span>
          </div>

          <div class="calendar-days-grid">
            @for (day of calendarDays; track day.dateStr) {
              <button
                type="button"
                class="day-cell"
                [class.other-month]="!day.isCurrentMonth"
                [class.today]="day.isToday"
                [class.selected]="day.isSelected"
                (click)="selectDate(day.dateStr, $event)"
              >
                {{ day.dayNum }}
              </button>
            }
          </div>

          <div class="calendar-footer">
            <button type="button" class="btn-today" (click)="selectDate(todayStr(), $event)"><i class="bi bi-geo-alt-fill"></i> Today</button>
            <button type="button" class="btn-close-cal" (click)="close()"><i class="bi bi-x-lg"></i> Close</button>
          </div>
        </div>
      }
    </div>
  `
})
export class CustomDatePickerComponent implements ControlValueAccessor, OnInit, OnDestroy {
  @Input() label = '';
  @Input() placeholder = 'Select Date';
  @Input() disabled = false;
  @Input() dropUp = false;

  @Output() dateChange = new EventEmitter<string>();

  value = '';
  isOpen = false;
  calendarCurrentMonth: Date = new Date();
  calendarDays: CalendarDay[] = [];

  private elementRef = inject(ElementRef);
  private datePickerService = inject(DatePickerService);
  private destroy$ = new Subject<void>();

  private onChange: (val: string) => void = () => {};
  private onTouched: () => void = () => {};

  ngOnInit(): void {
    this.datePickerService.activePicker$
      .pipe(takeUntil(this.destroy$))
      .subscribe(activePicker => {
        if (activePicker !== this && this.isOpen) {
          this.isOpen = false;
        }
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    if (this.isOpen && !this.elementRef.nativeElement.contains(event.target)) {
      this.close();
    }
  }

  writeValue(val: string): void {
    this.value = val || '';
    if (this.isOpen) {
      this.buildCalendarGrid();
    }
  }

  registerOnChange(fn: (val: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  onTriggerClick(event: MouseEvent): void {
    if (this.disabled) return;
    const willOpen = !this.isOpen;
    if (willOpen) {
      this.datePickerService.registerOpen(this);
      this.calendarCurrentMonth = this.value ? new Date(this.value) : new Date();
      this.buildCalendarGrid();
    } else {
      this.onTouched();
    }
    this.isOpen = willOpen;
  }

  close(): void {
    this.isOpen = false;
    this.onTouched();
  }

  prevMonth(event?: MouseEvent): void {
    if (event) event.stopPropagation();
    this.calendarCurrentMonth = new Date(this.calendarCurrentMonth.getFullYear(), this.calendarCurrentMonth.getMonth() - 1, 1);
    this.buildCalendarGrid();
  }

  nextMonth(event?: MouseEvent): void {
    if (event) event.stopPropagation();
    this.calendarCurrentMonth = new Date(this.calendarCurrentMonth.getFullYear(), this.calendarCurrentMonth.getMonth() + 1, 1);
    this.buildCalendarGrid();
  }

  selectDate(dateStr: string, event?: MouseEvent): void {
    if (event) event.stopPropagation();
    this.value = dateStr;
    this.onChange(dateStr);
    this.dateChange.emit(dateStr);
    this.buildCalendarGrid();
    this.close();
  }

  todayStr(): string {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  buildCalendarGrid(): void {
    const year = this.calendarCurrentMonth.getFullYear();
    const month = this.calendarCurrentMonth.getMonth();

    const firstDayOfMonth = new Date(year, month, 1);
    const lastDayOfMonth = new Date(year, month + 1, 0);

    let startDay = firstDayOfMonth.getDay() - 1;
    if (startDay === -1) startDay = 6;

    const days: CalendarDay[] = [];

    const prevMonthLastDay = new Date(year, month, 0).getDate();
    for (let i = startDay - 1; i >= 0; i--) {
      const pDate = new Date(year, month - 1, prevMonthLastDay - i);
      const yyyy = pDate.getFullYear();
      const mm = String(pDate.getMonth() + 1).padStart(2, '0');
      const dd = String(pDate.getDate()).padStart(2, '0');
      const dStr = `${yyyy}-${mm}-${dd}`;
      days.push({
        date: pDate,
        dateStr: dStr,
        dayNum: pDate.getDate(),
        isCurrentMonth: false,
        isToday: dStr === this.todayStr(),
        isSelected: this.value === dStr
      });
    }

    for (let d = 1; d <= lastDayOfMonth.getDate(); d++) {
      const cDate = new Date(year, month, d);
      const yyyy = cDate.getFullYear();
      const mm = String(cDate.getMonth() + 1).padStart(2, '0');
      const dd = String(cDate.getDate()).padStart(2, '0');
      const dStr = `${yyyy}-${mm}-${dd}`;
      days.push({
        date: cDate,
        dateStr: dStr,
        dayNum: d,
        isCurrentMonth: true,
        isToday: dStr === this.todayStr(),
        isSelected: this.value === dStr
      });
    }

    const remaining = 42 - days.length;
    for (let i = 1; i <= remaining; i++) {
      const nDate = new Date(year, month + 1, i);
      const yyyy = nDate.getFullYear();
      const mm = String(nDate.getMonth() + 1).padStart(2, '0');
      const dd = String(nDate.getDate()).padStart(2, '0');
      const dStr = `${yyyy}-${mm}-${dd}`;
      days.push({
        date: nDate,
        dateStr: dStr,
        dayNum: i,
        isCurrentMonth: false,
        isToday: dStr === this.todayStr(),
        isSelected: this.value === dStr
      });
    }

    this.calendarDays = days;
  }
}
