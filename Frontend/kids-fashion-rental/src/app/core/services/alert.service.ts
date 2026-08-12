import { Injectable } from '@angular/core';
import Swal, { SweetAlertIcon } from 'sweetalert2';

@Injectable({
  providedIn: 'root'
})
export class AlertService {

  /**
   * Confirm deletion dialog with luxury modern styling
   */
  async confirmDelete(
    title: string = 'Are you sure?',
    text: string = 'You won\'t be able to revert this!'
  ): Promise<boolean> {
    const result = await Swal.fire({
      title: title,
      text: text,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Yes, delete it',
      cancelButtonText: 'Cancel',
      reverseButtons: true,
      allowOutsideClick: true,
      allowEscapeKey: true,
      customClass: {
        popup: 'kfr-swal-popup',
        title: 'kfr-swal-title',
        htmlContainer: 'kfr-swal-text',
        confirmButton: 'kfr-swal-btn kfr-swal-btn-danger',
        cancelButton: 'kfr-swal-btn kfr-swal-btn-cancel'
      }
    });
    return result.isConfirmed === true;
  }

  /**
   * General confirm dialog
   */
  async confirm(options: {
    title: string;
    text?: string;
    icon?: SweetAlertIcon;
    confirmButtonText?: string;
    cancelButtonText?: string;
    isDanger?: boolean;
  }): Promise<boolean> {
    const result = await Swal.fire({
      title: options.title,
      text: options.text || '',
      icon: options.icon || 'question',
      showCancelButton: true,
      confirmButtonText: options.confirmButtonText || 'Confirm',
      cancelButtonText: options.cancelButtonText || 'Cancel',
      reverseButtons: true,
      allowOutsideClick: true,
      allowEscapeKey: true,
      customClass: {
        popup: 'kfr-swal-popup',
        title: 'kfr-swal-title',
        htmlContainer: 'kfr-swal-text',
        confirmButton: `kfr-swal-btn ${options.isDanger ? 'kfr-swal-btn-danger' : 'kfr-swal-btn-primary'}`,
        cancelButton: 'kfr-swal-btn kfr-swal-btn-cancel'
      }
    });
    return result.isConfirmed === true;
  }

  /**
   * Success Modal Popup
   */
  success(title: string, text?: string) {
    return Swal.fire({
      title,
      text,
      icon: 'success',
      confirmButtonText: 'OK',
      allowOutsideClick: true,
      allowEscapeKey: true,
      customClass: {
        popup: 'kfr-swal-popup',
        title: 'kfr-swal-title',
        htmlContainer: 'kfr-swal-text',
        confirmButton: 'kfr-swal-btn kfr-swal-btn-primary'
      }
    });
  }

  /**
   * Error Modal Popup
   */
  error(title: string, text?: string) {
    return Swal.fire({
      title,
      text,
      icon: 'error',
      confirmButtonText: 'OK',
      allowOutsideClick: true,
      allowEscapeKey: true,
      customClass: {
        popup: 'kfr-swal-popup',
        title: 'kfr-swal-title',
        htmlContainer: 'kfr-swal-text',
        confirmButton: 'kfr-swal-btn kfr-swal-btn-danger'
      }
    });
  }

  /**
   * Warning Modal Popup
   */
  warning(title: string, text?: string) {
    return Swal.fire({
      title,
      text,
      icon: 'warning',
      confirmButtonText: 'OK',
      allowOutsideClick: true,
      allowEscapeKey: true,
      customClass: {
        popup: 'kfr-swal-popup',
        title: 'kfr-swal-title',
        htmlContainer: 'kfr-swal-text',
        confirmButton: 'kfr-swal-btn kfr-swal-btn-warning'
      }
    });
  }

  /**
   * Info Modal Popup
   */
  info(title: string, text?: string) {
    return Swal.fire({
      title,
      text,
      icon: 'info',
      confirmButtonText: 'OK',
      allowOutsideClick: true,
      allowEscapeKey: true,
      customClass: {
        popup: 'kfr-swal-popup',
        title: 'kfr-swal-title',
        htmlContainer: 'kfr-swal-text',
        confirmButton: 'kfr-swal-btn kfr-swal-btn-primary'
      }
    });
  }

  /**
   * Success Toast (Top-Right Floating)
   */
  toastSuccess(message: string) {
    const Toast = Swal.mixin({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 3500,
      timerProgressBar: true,
      customClass: {
        popup: 'kfr-toast-popup kfr-toast-success'
      },
      didOpen: (toast) => {
        toast.onmouseenter = Swal.stopTimer;
        toast.onmouseleave = Swal.resumeTimer;
      }
    });
    Toast.fire({
      icon: 'success',
      title: message
    });
  }

  /**
   * Error Toast (Top-Right Floating)
   */
  toastError(message: string) {
    const Toast = Swal.mixin({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 4500,
      timerProgressBar: true,
      customClass: {
        popup: 'kfr-toast-popup kfr-toast-error'
      },
      didOpen: (toast) => {
        toast.onmouseenter = Swal.stopTimer;
        toast.onmouseleave = Swal.resumeTimer;
      }
    });
    Toast.fire({
      icon: 'error',
      title: message
    });
  }

  /**
   * Warning Toast (Top-Right Floating)
   */
  toastWarning(message: string) {
    const Toast = Swal.mixin({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 4000,
      timerProgressBar: true,
      customClass: {
        popup: 'kfr-toast-popup kfr-toast-warning'
      },
      didOpen: (toast) => {
        toast.onmouseenter = Swal.stopTimer;
        toast.onmouseleave = Swal.resumeTimer;
      }
    });
    Toast.fire({
      icon: 'warning',
      title: message
    });
  }

  /**
   * Info Toast (Top-Right Floating)
   */
  toastInfo(message: string) {
    const Toast = Swal.mixin({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 3500,
      timerProgressBar: true,
      customClass: {
        popup: 'kfr-toast-popup kfr-toast-info'
      },
      didOpen: (toast) => {
        toast.onmouseenter = Swal.stopTimer;
        toast.onmouseleave = Swal.resumeTimer;
      }
    });
    Toast.fire({
      icon: 'info',
      title: message
    });
  }
}
