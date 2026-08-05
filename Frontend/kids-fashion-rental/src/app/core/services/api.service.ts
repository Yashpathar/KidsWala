import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, catchError, map, of } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ApiResult, normalizeApiResult } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class ApiService {
  constructor(private http: HttpClient) {}

  private headers() {
    const token = localStorage.getItem('token');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    });
  }

  private handleError(err: unknown): ApiResult {
    const e = err as { error?: Record<string, unknown>; message?: string; status?: number };
    const body = e?.error;
    if (body) return normalizeApiResult(body);
    if (e?.status === 401) return { success: false, message: 'Session expired. Please login again.', data: null };
    return { success: false, message: e?.message || 'Network error. Check API is running.', data: null };
  }

  private wrap<T>(obs: Observable<unknown>): Observable<ApiResult<T>> {
    return obs.pipe(
      map(body => normalizeApiResult<T>(body)),
      catchError(err => of(this.handleError(err) as ApiResult<T>))
    );
  }

  get<T>(url: string, params?: Record<string, unknown>) {
    let hp = new HttpParams();
    if (params) {
      Object.entries(params).forEach(([k, v]) => {
        if (v !== null && v !== undefined && v !== '') hp = hp.set(k, String(v));
      });
    }
    return this.wrap<T>(this.http.get(`${environment.apiUrl}${url}`, { headers: this.headers(), params: hp }));
  }

  post<T>(url: string, body: unknown) {
    return this.wrap<T>(this.http.post(`${environment.apiUrl}${url}`, body, { headers: this.headers() }));
  }

  put<T>(url: string, body: unknown) {
    return this.wrap<T>(this.http.put(`${environment.apiUrl}${url}`, body, { headers: this.headers() }));
  }

  delete<T>(url: string) {
    return this.wrap<T>(this.http.delete(`${environment.apiUrl}${url}`, { headers: this.headers() }));
  }

  uploadFile<T>(url: string, file: File) {
    const fd = new FormData();
    fd.append('file', file);
    const token = localStorage.getItem('token');
    const headers = new HttpHeaders(token ? { Authorization: `Bearer ${token}` } : {});
    return this.wrap<T>(this.http.post(`${environment.apiUrl}${url}`, fd, { headers }));
  }
}
