import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private auth = inject(AuthService);
  private router = inject(Router);

  error = '';
  loading = false;
  showPassword = false;

  form = this.fb.group({
    userName: ['', Validators.required],
    password: ['', Validators.required]
  });

  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.loading = true;
    this.error = '';
    const { userName, password } = this.form.value;

    this.auth.login(userName!, password!).subscribe({
      next: res => {
        this.loading = false;
        if (res.success) {
          this.router.navigate([this.auth.getDashboardRoute()]);
        } else {
          this.error = res.message || 'Invalid User ID or password';
        }
      },
      error: () => {
        this.loading = false;
        this.error = 'Cannot connect to API. Start backend on port 5001.';
      }
    });
  }
}
